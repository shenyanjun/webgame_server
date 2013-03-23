--2012-05-21
--zhengyg
--class bag_base

-------------------------------------------
--[[
interface info:
	bag_base:check_can_delete(item_t,mode)
	bag_base:del_item_bat(item_t)
	bag_base:check_can_add(item_t,mode)
	bag_base:add_item_bat(item_t)
	bag_base:del_item_by_uuid(uuid,cnt)
	bag_base:get_item_by_uuid(uuid)
]]
--[[items stored in bag_grid , grids stored in bag , 
bag knows details about item as less as possible]]

--record item change when excu add or del operation , notice client
bag_notice = oo.class(nil,"bag_notice")
function bag_notice:__init()
	self.change_grids={}
	self.new_grid_ids={}
	self.old_num = {}
end
function bag_notice:add_notice(grid,oldNum)
	table.insert(self.change_grids,grid)
	if oldNum then
		self.old_num[grid:get_grid_id()] = oldNum
	end
end
function bag_notice:add_notice_new(grid)
	self.new_grid_ids[grid:get_grid_id()] = true
	self:add_notice(grid)
end
function bag_notice:get_grids()
	return self.change_grids
end
function bag_notice:is_new_add(grid)
	return self.new_grid_ids[grid:get_grid_id()]
end
function bag_notice:get_old_num(grid)
	return self.old_num[grid:get_grid_id()]
end
--class bag
bag_base = oo.class(nil,"bag_base")

function bag_base:__init(max_grid_cnt,owner_id,grid_builder)
	--grid info
	self.m_grid_list = {}
	--bag size
	self.m_max_grid_cnt = max_grid_cnt 
	--grid index for faster searched
	self.m_grid_index = bag_grid_index()
	--owner_id , such as faction_id ...
	assert(owner_id)
	self.m_owner_id = owner_id
	--number of grids in bag
	self.m_used_grid_cnt = 0
	--need save flag (when m_last_save_time~=0)
	self.m_last_save_time = 0
end
function bag_base:set_earliest_save_time()
	if self.m_last_save_time == 0 then
		self.m_last_save_time = ev.time
	end
end
function bag_base:get_earliest_save_time()
	return self.m_last_save_time
end
function bag_base:reset_earliest_save_time()
	self.m_last_save_time = 0
end
--every kind of bag need defined it`s grid_builder
function bag_base:build_grid(...)
	return get_grid_builder(self:get_bag_type())(...)
end
--get used grid cnt
function bag_base:get_used_grid_cnt()
	return self.m_used_grid_cnt
end
function bag_base:increase_used_grid_cnt()
	self.m_used_grid_cnt = self.m_used_grid_cnt + 1
end
function bag_base:decrease_used_grid_cnt()
	self.m_used_grid_cnt = self.m_used_grid_cnt - 1
end
--get owner id
function bag_base:get_owner_id()
	return self.m_owner_id
end
--get grid obj by grid id
function bag_base:get_grid(grid_id)
	return self.m_grid_list[grid_id]
end
--find specified number of free grid ids
function bag_base:get_available_grid_id(cnt)
	if cnt<1 then return nil end
	local ept_id = {}
	local curr_cnt = 0
	for i = 1,self:get_bag_size() do
		if self:get_grid(i) == nil then
			table.insert(ept_id,i)
			curr_cnt = curr_cnt + 1
			if curr_cnt == cnt then return ept_id end
		end
	end
	return nil
end
--virtual functions start,subclass can redefine it if necessary
--get specification of bag kind
function bag_base:get_bag_type()
	return nil
end
function bag_base:set_bag_size(max_size)
	self.m_max_grid_cnt = max_size
end
--virtual functions end

--private functions start (do not call in any other place except current file)
--add one grid to bag
function bag_base:add(grid)
	assert(grid)
	assert(self.m_grid_list[grid:get_grid_id()] == nil)
	self.m_grid_list[grid:get_grid_id()] = grid
	self.m_grid_index:add(grid)
	self:increase_used_grid_cnt()
	self:on_add(grid)
	return 0
end
--del one grid from bag
function bag_base:del(grid)
	assert(self.m_grid_list[grid:get_grid_id()])
	self.m_grid_list[grid:get_grid_id()] = nil
	self.m_grid_index:del(grid)
	self:decrease_used_grid_cnt()
	self:on_del(grid)
end
--event add 
function bag_base:on_add(grid,cnt)
end
--event del 
function bag_base:on_del(grid,cnt)
end
--get needed count of grid for insering specified number(cnt) of item which stack number(stk_num) was specified
function bag_base:get_need_grid_nums(cnt,stk_num)
	return (math.floor(cnt/stk_num)*stk_num) < cnt and (math.floor(cnt/stk_num) + 1) or math.floor(cnt/stk_num)
end
--private functions end 

--public functions start 
--get bag max size
function bag_base:get_bag_size()
	return self.m_max_grid_cnt
end
--get free size
function bag_base:get_ept_grid_cnt()
	local ept_cnt = self:get_bag_size() - self:get_used_grid_cnt()
	return ept_cnt
end
--get grids containt items(item_id) and still have empty space
function bag_base:get_free_grid(item_id,stk_num,expect_num)
	local ret = {}
	if stk_num == 1 then return 0, ret end
	if stk_num > 1 then
		local stk_list = self.m_grid_index:search({['item_id']=item_id})
		local free_size = 0
		if stk_list then
			for grid_id,_ in pairs(stk_list) do
				local grid = self:get_grid(grid_id)
				local left = grid:can_add(item_id)
				if left > 0 then
					free_size = free_size + left
					ret[grid:get_grid_id()] = grid
					if expect_num <= free_size then 
						free_size = expect_num
						break 
					end
				end
			end
		end
		return free_size , ret
	end
	return 0 , ret
end
--get grids and new grid count for insering specified number(num) of items(item_id)
function bag_base:get_free_info(item_id,stk_num,expect_num)
	local grid_free_size , free_grids = self:get_free_grid(item_id,stk_num,expect_num)
	local grid_table={}
	grid_table.item_id = item_id
	grid_table.free_grids = free_grids
	grid_table.free_grid_cnt = 0
	if grid_free_size < expect_num then
		local need_grid_num = self:get_need_grid_nums(expect_num-grid_free_size,stk_num)
		grid_table.free_grid_cnt = need_grid_num
		return grid_table
	end
	return grid_table
end
--get itemobj and cnt
function bag_base:get_item_by_uuid(uuid)
	local grid_id = self.m_grid_index:search({['uuid']=uuid})
	if grid_id then
		local grid = self:get_grid(grid_id)
		if grid then
			return grid:get_item() , grid:get_item_cnt()
		end
	end
	return nil , nil
end
function bag_base:get_grid_by_uuid(uuid)
	local grid_id = self.m_grid_index:search({['uuid']=uuid})
	if grid_id then return self:get_grid(grid_id) end
	return nil
end
--del item by grid_id
function bag_base:del_item_by_grid_id(grid_id,cnt)
	local grid = self:get_grid(grid_id)
	local notice = bag_notice()
	if grid then
		local oldNum = grid:get_item_cnt()
		if oldNum>=cnt then
			grid:sub_item_cnt(cnt)
			if grid:get_item_cnt() == 0 then
				self:del(grid)
			end
			notice:add_notice(grid,oldNum)
			self:set_earliest_save_time()
			return 0 , notice --self:notice_grid_change_to_net(notice)
		else
			return 1
		end
	end	
	return 1
end
--del by uuid
function bag_base:del_item_by_uuid(uuid,cnt)
	local grid_id = self.m_grid_index:search({['uuid']=uuid})
	if grid_id == nil then return 31162 end
	if grid_id > 0 then
		local grid = self:get_grid(grid_id)
		if grid then
			return self:del_item_by_grid_id(grid_id,cnt)
		end
	end
	return 31162
end
--[[batch delete
item_t[1].item_id item_t[1].count
item_t[2].item_id item_t[2].count .....
do not deliver paramer 'mode']]
function bag_base:check_can_delete(item_t,mode)
	local item_s = {}
	for _,item_info in pairs(item_t) do
		if item_info.count < 1 then return 43002 end --count error
		item_s[item_info.item_id] = ( 0 or item_s[item_info.item_id] ) + item_info.count
	end
	--check enough
	for item_id , cnt in pairs(item_s) do
		assert(cnt>0)
		local grid_ids = self.m_grid_index:search({['item_id']=item_id})
		for grid_id , _ in pairs(grid_ids) do
			if self:get_grid(grid_id):get_item_cnt() >= cnt then
				cnt = 0
				break
			else
				cnt = cnt - self:get_grid(grid_id):get_item_cnt()
			end
		end
		if cnt~=0 then return 43002 end -- not enough
	end
	if mode == true then
		return 0 , item_s
	else
		return 0
	end
end
--[[batch delete
item_t[1].item_id item_t[1].count
item_t[2].item_id item_t[2].count .....]]
function bag_base:del_item_bat(item_t)
	local e_code , item_s = self:check_can_delete(item_t,true)
	if e_code~=0 then return e_code end
	--delete real
	local notice = bag_notice()
	for item_id , cnt in pairs(item_s) do
		assert(cnt>0)
		local grid_ids = self.m_grid_index:search({['item_id']=item_id})
		for grid_id , _ in pairs(grid_ids) do
			local grid = self:get_grid(grid_id)
			local oldNum = grid:get_item_cnt()
			if  oldNum>= cnt then
				grid:sub_item_cnt(cnt)
				if grid:get_item_cnt() == 0 then
					self:del(grid)
				end
				notice:add_notice(grid,oldNum)
				break
			else
				local oldNum = grid:get_item_cnt()
				cnt = cnt - oldNum
				grid:sub_item_cnt(grid:get_item_cnt())
				if grid:get_item_cnt() == 0 then
					self:del(grid)
				end
				notice:add_notice(grid,oldNum)
			end
		end
		self:set_earliest_save_time()
		return 0 , notice
	end
end
--[[batch insert
item_t[1].item_id item_t[1].item_db item_t[1].count
item_t[2].item_id item_t[2].item_db item_t[2].count .....
please don`t deliver paramer 'mode']]
function bag_base:check_can_add(item_t,mode)
	local item_s = {}
	item_s.multy_set={}
	item_s.single_set={}
	
	local free_grid_cnt = self:get_ept_grid_cnt()
	local need_free_grid_cnt = 0
	--merge item_ids and create items and check space enough
	for _,item_info in pairs(item_t) do
		if item_info.count<=0 then return 31161 end -- error count
		local need_new = true
		if item_s.multy_set[tonumber(item_info.item_id)] then
			item_s.multy_set[tonumber(item_info.item_id)].count = item_s[tonumber(item_info.item_id)].count + item_info.count
			need_new = false
		end
		if need_new then
			local e_code , item = nil , nil
			if item_info.item_db then
				e_code , item = Item_factory.clone(item_info.item_id,item_info.item_db)
			else
				e_code , item = Item_factory.create(item_info.item_id)
			end
			if e_code~=0 then return e_code end --error item id
			if item:get_stk_num()>1 then
				item_s.multy_set[tonumber(item_info.item_id)] = item_s.multy_set[tonumber(item_info.item_id)] or {}
				item_s.multy_set[tonumber(item_info.item_id)].count = item_info.count
				item_s.multy_set[tonumber(item_info.item_id)].item = item
			else
				for i = 1 , item_info.count do
					if nil == item then
						if item_info.item_db then
							e_code , item = Item_factory.clone(item_info.item_id,item_info.item_db)
						else
							e_code , item = Item_factory.create(item_info.item_id)
						end
						if e_code~=0 then return e_code end --error item id
					end
					item_s.single_set[tonumber(item_info.item_id)] = item_s.single_set[tonumber(item_info.item_id)] or {}
					table.insert(item_s.single_set[tonumber(item_info.item_id)],item)
					--check empty grids enough
					need_free_grid_cnt = need_free_grid_cnt + 1
					if need_free_grid_cnt >free_grid_cnt then return 31165 end --full
					item = nil
				end
			end
		end
	end
	--check empty grids enough
	local multy_free_info = {}
	for item_id , info in pairs(item_s.multy_set) do
		local free = self:get_free_info(item_id,info.item:get_stk_num(),info.count)
		if nil==free then return 31165 end -- full
		need_free_grid_cnt = need_free_grid_cnt + free.free_grid_cnt
		if need_free_grid_cnt > free_grid_cnt then return 31165 end --full
		multy_free_info[free.item_id] = free
	end
	if mode == true then -- call by self:add_item_bat
		return 0 , item_s , multy_free_info
	else
		return 0
	end
end
--[[batch insert
item_t[1].item_id item_t[1].item_db item_t[1].count
item_t[2].item_id item_t[2].item_db item_t[2].count .....]]
function bag_base:add_item_bat(item_t)
	local notice = bag_notice()
	
	local e_can_add , item_s , multy_free_info = self:check_can_add(item_t,true)
	if e_can_add ~= 0 then return e_can_add end
	
	for item_id , info in pairs(item_s.multy_set) do
		local cnt = info.count
		local stk_num = info.item:get_stk_num()
		for _,grid in pairs(multy_free_info[item_id].free_grids) do --use free grids
			if cnt <= 0 then break end
			local oldNum = grid:get_item_cnt()
			local allow_cnt = stk_num - oldNum
			local to_add_cnt = allow_cnt
			if allow_cnt >= cnt then to_add_cnt = cnt end
			grid:add_item_cnt(to_add_cnt)
			notice:add_notice(grid,oldNum)
			cnt = cnt - to_add_cnt
		end
		if cnt > 0 then --too less free grid space , then new grid
			local grids = self:get_available_grid_id(self:get_need_grid_nums(cnt,stk_num))
			for _,grid_id in pairs(grids) do
				local e_code , item = Item_factory.create(item_id)
				if cnt >= 0 then
					if cnt > stk_num then
						local grid = self:build_grid(grid_id,item,stk_num)
						self:add(grid)
						notice:add_notice_new(grid)
						cnt = cnt - stk_num
					else
						local grid = self:build_grid(grid_id,item,cnt)
						self:add(grid)
						notice:add_notice_new(grid)
						cnt = 0
					end 
				end
			end 
		end
	end
	--insert single stk_num item
	for item_id , item_set in pairs(item_s.single_set) do
		for _,item in pairs(item_set) do
			assert(item)
			local grids = self:get_available_grid_id(self:get_need_grid_nums(1,1))
			local grid = self:build_grid(grids[1],item,1)
			self:add(grid)
			notice:add_notice_new(grid)
		end
	end
	self:set_earliest_save_time()
	return 0 , notice
end
--serialized operate
function bag_base:serialized()
	local pack = {}
	local index = 1
	for grid_id , grid in pairs(self.m_grid_list) do
		pack[index] = grid:serialized()
		index = index + 1
	end
	return pack
end
function bag_base:unserialized(grids,max_grid_cnt)
	--assert(max_grid_cnt)
	self:set_bag_size(max_grid_cnt)
	if grids then
		for _,grid_info in pairs(grids) do
			local grid = self:build_grid()
			if grid:unserialized(grid_info) == 0 then
				self:add(grid)
			end
		end
	end
	return 0
end
function bag_base:serialized_to_net()
	local info = {}
	info[1] = self:get_bag_type()
	info[2] = self:get_bag_size()
	info[3] = {}
	local cnt = 0
	for grid_id , grid in pairs(self.m_grid_list) do
		cnt = cnt + 1
		info[3][cnt] = grid:serialized_to_net(self:get_bag_type(),1)--item_info
	end
	return info
end
--these grids may have been removed from bag
function bag_base:notice_grid_change_to_net(notice)
	local data = {}
	data.list = {}
	data.result = 0
	
	local pnt = 0
	for _, grid in pairs(notice:get_grids()) do
		pnt = pnt + 1
		if notice:is_new_add(grid) then
			data.list[pnt] = grid:serialized_to_net(self:get_bag_type(),3)
		else
			data.list[pnt] = grid:serialized_to_net(self:get_bag_type(),2)
		end
	end
	return data
end
--test functions start
function bag_base:toString()
	local log_str = '\n'
	for k,v in pairs(self.m_grid_list) do
		log_str = log_str..'\n'..v:toString()
	end
	return log_str
end
--test functions end
function bag_base:items_info()
	local items = {}
	local cnt = 1
	local num = 0
	for _,grid in pairs(self.m_grid_list) do
		items[cnt] = {}
		items[cnt].item_id = grid:get_item():get_item_id()
		items[cnt].item_db = grid:get_item():serialize_to_db()
		items[cnt].count   = grid:get_item_cnt()
		cnt = cnt + 1
		num = num + 1
	end
	return num , items
end
function bag_base:is_empty()
	for k,v in pairs(self.m_grid_list) do
		return false
	end
	return true
end