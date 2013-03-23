

local proto_mgr = require("item.proto_mgr")
local INFORM_OP = {
	ADD = 1,
	DEL = 2,
	USE = 3
}

local _bag_start = 1


--************背包结构*****************

Base_bag = oo.class(nil, "Base_bag")

--bag_size为背包初始化大小， each_size为一次开多少格, slot_max为背包最大格子数
function Base_bag:__init(char_id, bag_id, bag_size, bag_mgr)
	self.bag_mgr = bag_mgr
	self.bag_id = bag_id
	self.char_id = char_id
	self.bag_size = bag_size
	self.item_cnt = 0   --格子个数

	--下标为格子编号，内容包括：uuid,item_id,number,item
	self.slot_list = {}

	--下标为uuid,内容为slot
	self.uuid_list = {}

	--下标为item_id, 内容为一个表，uuid:slot
	self.item_id_list = {}
end

--通知其他模块
function Base_bag:inform_other_modual(flag, slot, item_id, uuid, grid)
	local args = {}
	args.item_id = item_id
	if INFORM_OP.ADD == flag then
		args.slot = self.slot_list[slot]
		g_event_mgr:notify_event(EVENT_SET.EVENT_ADD_ITEM, self.char_id, args)
	elseif INFORM_OP.DEL == flag then
		args.slot = grid
		g_event_mgr:notify_event(EVENT_SET.EVENT_DEL_ITEM, self.char_id, args)
	elseif INFORM_OP.USE == flag then
		args.item = self.slot_list[slot] and self.slot_list[slot].item
		g_event_mgr:notify_event(EVENT_SET.EVENT_USE_ITEM, self.char_id, args)
	end

	--通知快捷栏
	--if INFORM_OP.DEL == flag then
		local item = self.slot_list[slot] and self.slot_list[slot].item
		f_action_item_change(self.char_id, flag, item_id, item, uuid)
	--end
end

--***************设置、获取背包基本信息*******************
--返回物品个数
function Base_bag:get_item_cnt()
	return self.item_cnt
end

function Base_bag:get_bag_start()
	return _bag_start
end

--设置背包大小
function Base_bag:set_size(size)
	if size > self:get_max_size() then
		return E_INVALID_PARAMETER
	end

	self.bag_size = size
	return 0
end

--获取背包大小
function Base_bag:get_size()
	return self.bag_size
end

--背包是否满了
function Base_bag:is_full()
	return self.item_cnt >= self.bag_size
end

--子类实现该两个方法
function Base_bag:get_each_size()
	return 0
end
function Base_bag:get_max_size()
	return self.bag_size
end

--开格
function Base_bag:expand_size()
	local each_size = self:get_each_size()
	if each_size <= 0 or self.bag_size >= self:get_max_size() or self.bag_size + each_size > self:get_max_size() then
		return E_MAX_BAG_SIZE
	end

	self.bag_size = self.bag_size + each_size
	return 0
end

--获取背包信息，用户登录的时候需要取得该信息
--只用到数组前3位  第四位是特殊属性，降妖背包有
function Base_bag:get_bag_info()
	local info = {}
	info[1] = self.bag_id
	info[2] = self.bag_size
	info[3] = {}
	local cnt = 0
	local item_info
	for i = _bag_start, self.bag_size do
		if self.slot_list[i] then
			item_info = {}
			item_info[1] = self.slot_list[i].uuid
			item_info[2] = nil  --映射源
			item_info[3] = self.bag_id
			item_info[4] = i
			item_info[5] = self.slot_list[i].number
			item_info[6] = self.slot_list[i].item:serialize_to_net()
			item_info[7] = nil  --来源
			cnt = cnt + 1
			info[3][cnt] = item_info
		end
	end

	return info
end


--根据item_id获取格子数
function Base_bag:get_slot_by_item_id(item_id)
	if self.item_id_list[item_id] then
		for uuid,slot in pairs(self.item_id_list[item_id]) do
			return slot
		end
	end
	return nil
end

--根据item_id获取格子
function Base_bag:get_item_by_item_id(item_id)
	if self.item_id_list[item_id] then
		for uuid,slot in pairs(self.item_id_list[item_id]) do
			return self.slot_list[slot]
		end
	end
	return nil
end

--根据m_class获取所有格子对象
function Base_bag:get_all_item_by_m_class(m_class)
	local ret ={}
	for k, v in pairs(self.slot_list) do
		if v.item:get_m_class() == m_class then
			table.insert(ret, v)
		end
	end
	return ret
end

--根据uuid获取某个格子
function Base_bag:get_item_by_uuid(uuid)
	if self.uuid_list[uuid] then
		return self.slot_list[self.uuid_list[uuid]]
	end
	return nil
end

--根据slot获取格子
function Base_bag:get_item_by_slot(slot)
	return self.slot_list[slot]
end

--还有多少个空格
function Base_bag:get_ept_cnt()
	return self.bag_size - self.item_cnt
end


--获取一个空格位置，如果st为空，那么从slot_start开始找，否则从st开始找，直到slot_end为止
function Base_bag:get_ept_slot(st)
	local start = st or _bag_start
	for i = start, self.bag_size do
		if not self.slot_list[i] then
			return i
		end
	end
	return nil
end

--获取某种物品的总个数
function Base_bag:get_cnt_by_item_id(item_id)
	if not self.item_id_list[item_id] then
		return 0
	else
		local cnt = 0
		for uuid, slot in pairs(self.item_id_list[item_id]) do
			if self.slot_list[slot] == nil then
				local debug = Debug(g_debug_log)
				debug:trace("Base_bag:get_cnt_by_item_id:" .. tostring(item_id))
			end

			cnt = cnt + self.slot_list[slot].number
		end
		return cnt
	end
end


------------------------------------------------------------------背包中的物品操作----------------------------------------------------------------------

--加载数据库中的一条物品记录
function Base_bag:load_grid(slot, uuid, number, item)
	if not slot or not uuid or not number or not item or slot < _bag_start or slot > self.bag_size then
		return E_INVALID_PARAMETER
	end

	--if not type then 
		--[[local s_id = self.slot_list[slot] and self.slot_list[slot].item_id
		if s_id and self.item_id_list[s_id] then
			print(">>>>", s_id, self.slot_list[slot].uuid, slot, self.item_id_list[s_id][self.slot_list[slot].uuid])
			self.item_id_list[s_id][self.slot_list[slot].uuid] = nil
			--debug:trace("Base_bag:load_grid:" .. tostring(s_id))
		end]]
	--end

	local item_id = item:get_item_id()
	if self.slot_list[slot] == nil then
		self.item_cnt = self.item_cnt + 1
	end

	self.slot_list[slot] = {}
	self.slot_list[slot].uuid = uuid
	self.slot_list[slot].number = number
	self.slot_list[slot].item = item
	self.slot_list[slot].item_id = item_id
	self.slot_list[slot].slot = slot
	self.slot_list[slot].bag = self.bag_id

	--self.uuid_list[uuid] = {}
	self.uuid_list[uuid] = slot

	if not self.item_id_list[item_id] then
		self.item_id_list[item_id] = {}
	end
	self.item_id_list[item_id][uuid] = slot
	
	--[[if flag == nil then
		self.item_cnt = self.item_cnt + 1
	end]]
	return 0
end

--删除一个格子
function Base_bag:erase_grid(slot)
	if self.slot_list[slot] ~= nil then
		if self.item_id_list[self.slot_list[slot].item_id][self.slot_list[slot].uuid] == slot then
			self.item_id_list[self.slot_list[slot].item_id][self.slot_list[slot].uuid] = nil
		end
		self.uuid_list[self.slot_list[slot].uuid] = nil
		self.slot_list[slot] = nil
		self.item_cnt = self.item_cnt - 1
	end
	return 0
end

--获取slot当前的情况，以便通知客户端或则跟新数据库的时候可以获取相应的信息
function Base_bag:get_update_log(op, slot, change_num)
	if slot == nil or self.slot_list[slot] == nil then
		if slot ~= EQUIPMENT_SLOT_OUTLOOK then
			local debug = Debug(g_debug_log)
			debug:trace("Base_bag:get_update_log:" .. tostring(slot or -1))
		end
		return
	end

	local tmp = {}
	tmp.op = op
	tmp.bag = self.bag_id
	tmp.slot = slot
	tmp.item = self.slot_list[slot].item
	tmp.uuid = self.slot_list[slot].uuid
	tmp.number = self.slot_list[slot].number
	tmp.item_id = self.slot_list[slot].item_id
	if op == ItemSyncFlag.ITEM_SYNC_REMOVE then
		tmp.number = 0
	end
	tmp.change_num = change_num or 0

	--有变动  需要存盘  存完后置为false
	self.update_flags = true

	return tmp
end

--插入新item，以便跟新数据库的时候可以获取相应的信息
function Base_bag:get_insert_log(slot,number,item_id,item)
	if item == nil then
		print("Error:Base_bag:get_insert_log", item_id)
	end

	local tmp = {}
	tmp.op = ItemSyncFlag.ITEM_SYNC_ADD
	tmp.bag = self.bag_id
	tmp.slot = slot
	tmp.uuid = crypto.uuid()
	tmp.number = number
	tmp.item = item
	tmp.item_id = item_id
	tmp.change_num = number
	return tmp
end


--添加一个格子，与load_grid的区别在与要入库
function Base_bag:set_grid(slot, uuid, number, item)
	self:erase_grid(slot)
	self:load_grid(slot, uuid, number, item)
	local item_log	= self:get_update_log(ItemSyncFlag.ITEM_SYNC_UPDATE, slot)
	return 0, {item_log}
end

--获取格子
function Base_bag:get_grid(slot)
	return self.slot_list[slot]
end


--{{[type]=1,[item_id]=,[number]=,[item]},}
function Base_bag:pri_add(item_list)
	if not item_list then
		return E_EPT_PARAMETER
	end

	--统计所有物品的个数
	local tmp_list = {}  --记录可以堆叠的物品item_id:{number,item}
	local grid_list = {} --记录type=2 不可堆叠的物品(因为相同的item_id，item不同)
	local grid_cnt = 0
	local item_id, stk_num, e_code

	for _,v in pairs(item_list) do
		if v.type == 1 then	--根据item_id加入
			local overlap_flag = true
			local err_code,item = Item_factory.create(v.item_id)
			if err_code ~= 0 then return err_code end
			if item:get_stk_num() == 1 then      --不可堆叠
				overlap_flag = false
			end
			
			if overlap_flag  then			
				if not v.item_id or not v.number or tonumber(v.number)<= 0 then
					return E_INVALID_PARAMETER
				end
				if not tmp_list[v.item_id] then
					tmp_list[v.item_id] = {}
					tmp_list[v.item_id].number = v.number
					e_code,tmp_list[v.item_id].item = Item_factory.create(v.item_id)
					if e_code ~= 0 then
						return e_code
					end
				else
					tmp_list[v.item_id].number = tmp_list[v.item_id].number + v.number
				end
			else
				for i = 1, v.number do
					grid_cnt = grid_cnt  +  1
					grid_list[grid_cnt] = {}
					e_code,grid_list[grid_cnt].item = Item_factory.create(v.item_id)--  此处可能引起bug 
					if e_code ~= 0 then
						return e_code
					end 
				end
			end
		elseif v.type == 2 then	--根据item加入
			if not v.item or not v.number or v.number<= 0 then
				return E_INVALID_PARAMETER
			end

			item_id = v.item:get_item_id()
			stk_num = v.item:get_stk_num()

			--如果叠加数不为1，那么就当做type=1来处理，即先找叠加，再找空格
			if stk_num == 1 then
				local item_db = v.item:serialize_to_db()
				local item_id = v.item:get_item_id()
				for i = 1, v.number do
					grid_cnt = grid_cnt  +  1
					grid_list[grid_cnt] = {}
					local err_code,item_obj
					if not item_db then
						err_code,item_obj = Item_factory.create(item_id)
					else
						err_code,item_obj = Item_factory.clone(item_id,item_db)
					end
					if err_code ~= 0 then
						return err_code
					end
					grid_list[grid_cnt].item = item_obj--v.item --v.item:create()  此处可能引起bug  
				end
			else
				if not tmp_list[item_id] then
					tmp_list[item_id] = {}
					tmp_list[item_id].number = v.number
					tmp_list[item_id].item = v.item
				else
					tmp_list[item_id].number = tmp_list[item_id].number + v.number
				end
			end
		end
	end

	local tmp_item,stk_space
	local log_list = {}
	local log_pnt = 0
	--判断叠加
	for item_id,it_o in pairs(tmp_list) do
		for _,slt in pairs(self.item_id_list[item_id] or {}) do
			if self.slot_list[slt] == nil then
				local debug = Debug(g_debug_log)
				debug:trace("Base_bag:pri_add:" .. tostring(item_id))
			end

			stk_space = self.slot_list[slt].item:get_stk_num() - self.slot_list[slt].number
			if stk_space > 0 then
				--计算增加数目
				local add_num
				if it_o.number >= stk_space then
					add_num = stk_space
				else
					add_num = it_o.number
				end
				log_pnt = log_pnt + 1
				log_list[log_pnt] = self:get_update_log(ItemSyncFlag.ITEM_SYNC_UPDATE, slt, add_num)
				log_list[log_pnt].number = self.slot_list[slt].number + add_num
				it_o.number = it_o.number - add_num

				if it_o.number <= 0 then
					tmp_list[item_id] = nil
				end
			end
		end
	end

	--判断空格
	local ept_slot = nil
	local add_slot = 0
	for k,v in pairs(tmp_list) do
		if v.number > 0 then
			tmp_item = v.item   --Item_factory.create(k)
			stk_num = tmp_item:get_stk_num()
			while v.number > 0 do
				ept_slot = self:get_ept_slot(ept_slot)
				if not ept_slot then
					return E_BAG_FULL
				end

				log_pnt = log_pnt + 1
				if v.number >= stk_num then
					log_list[log_pnt] = self:get_insert_log(ept_slot,stk_num, k, tmp_item)
				else
					log_list[log_pnt] = self:get_insert_log(ept_slot, v.number, k, tmp_item)
				end
				if not log_list[log_pnt] then
					return E_INVALID_PARAMETER
				end

				v.number = v.number - stk_num
				add_slot = add_slot + 1
				ept_slot = ept_slot + 1
			end
		end
	end

	--空格够不够放入type为2的物品
	if grid_cnt > self.bag_size - self.item_cnt - add_slot then
		return E_BAG_FULL
	end

	--加入type=2的物品
	for k,v in pairs(grid_list) do
		ept_slot = self:get_ept_slot(ept_slot)
		if not ept_slot then
			return E_BAG_FULL
		end

		log_pnt = log_pnt + 1
		log_list[log_pnt] = self:get_insert_log(ept_slot, 1, v.item:get_item_id(), v.item)
		ept_slot = ept_slot + 1
	end

	--执行操作
	for k,v in pairs(log_list) do
		if v.op == ItemSyncFlag.ITEM_SYNC_ADD then
			self:load_grid(v.slot, v.uuid, v.number, v.item)
		elseif v.op == ItemSyncFlag.ITEM_SYNC_UPDATE then
			self.slot_list[v.slot].number = v.number
		end
		self:inform_other_modual(INFORM_OP.ADD, v.slot, v.item_id, v.uuid)
	end

	return 0, log_list
end

--需要检查是否能加
function Base_bag:pri_check_add(item_list)

	--统计所有物品的个数
	local tmp_list = {}  --记录可以堆叠的物品item_id:{number,item}
	local grid_list = {} --记录type=2 不可堆叠的物品(因为相同的item_id，item不同)
	local grid_cnt = 0
	local item_id, stk_num, e_code

	for _,v in pairs(item_list) do
		if v.type == 1 then	--根据item_id加入
			local overlap_flag = true
			local err_code,item = Item_factory.create(v.item_id)
			if err_code ~= 0 then return err_code end
			if item:get_stk_num() == 1 then      --不可堆叠
				overlap_flag = false
			end
			
			if overlap_flag  then			
				if not v.item_id or not v.number or tonumber(v.number)<= 0 then
					return E_INVALID_PARAMETER
				end
				if not tmp_list[v.item_id] then
					tmp_list[v.item_id] = {}
					tmp_list[v.item_id].number = v.number
					e_code,tmp_list[v.item_id].item = Item_factory.create(v.item_id)
					if e_code ~= 0 then
						return e_code
					end
				else
					tmp_list[v.item_id].number = tmp_list[v.item_id].number + v.number
				end
			else
				for i = 1, v.number do
					grid_cnt = grid_cnt  +  1
					grid_list[grid_cnt] = {}
					e_code,grid_list[grid_cnt].item = Item_factory.create(v.item_id)--  此处可能引起bug 
					if e_code ~= 0 then
						return e_code
					end 
				end
			end
		elseif v.type == 2 then	--根据item加入
			if not v.item or not v.number or v.number<= 0 then
				return E_INVALID_PARAMETER
			end

			item_id = v.item:get_item_id()
			stk_num = v.item:get_stk_num()

			--如果叠加数不为1，那么就当做type=1来处理，即先找叠加，再找空格
			if stk_num == 1 then
				for i = 1, v.number do
					grid_cnt = grid_cnt  +  1
					grid_list[grid_cnt] = {}
					grid_list[grid_cnt].item = v.item --v.item:create()  此处可能引起bug  
				end
			else
				if not tmp_list[item_id] then
					tmp_list[item_id] = {}
					tmp_list[item_id].number = v.number
					tmp_list[item_id].item = v.item
				else
					tmp_list[item_id].number = tmp_list[item_id].number + v.number
				end
			end
		end
	end

	--判断空格 


	local tmp_item,stk_space
	local log_list = {}
	--判断叠加
	for item_id,it_o in pairs(tmp_list) do
		for _,slt in pairs(self.item_id_list[item_id] or {}) do
			stk_space = self.slot_list[slt].item:get_stk_num() - self.slot_list[slt].number
			if stk_space > 0 then
				--计算增加数目
				local add_num
				if it_o.number >= stk_space then
					add_num = stk_space
				else
					add_num = it_o.number
				end
				it_o.number = it_o.number - add_num

				if it_o.number <= 0 then
					tmp_list[item_id] = nil
				end
			end
		end
	end

	--判断空格
	local ept_slot = nil
	local add_slot = 0
	for k,v in pairs(tmp_list) do	--剩下的不能加入原来格的叠加物品
		if v.number > 0 then
			tmp_item = v.item   --Item_factory.create(k)
			stk_num = tmp_item:get_stk_num()
			while v.number > 0 do
				ept_slot = self:get_ept_slot(ept_slot)
				if not ept_slot then
					return E_BAG_FULL
				end

				v.number = v.number - stk_num
				add_slot = add_slot + 1
				ept_slot = ept_slot + 1
			end
		end
	end

	--空格够不够放入type为2的物品
	if grid_cnt > self.bag_size - self.item_cnt - add_slot then
		return E_BAG_FULL
	end

	return 0
end


--增加物品到指定的格，不做错误逻辑判断，用于新玩家登陆
function Base_bag:add_item_to_slot(slot, number, item)
	local log = self:get_insert_log(slot, number, item:get_item_id(), item)
	self:load_grid(log.slot, log.uuid, log.number, log.item)
	return log
end

--背包添加一个新物品,先合并，后找空格
function Base_bag:create_item_by_item_id(number, item_id)
	if not number or number <= 0 or not item_id or proto_mgr.exist(item_id)==false then
		return E_INVALID_PARAMETER
	end
	return self:pri_add({{['type']=1, ['number']=number, ['item_id']=item_id}})
end


--添加number个已经构造好的item,
--[[function Base_bag:create_item_by_item(number, item)
	if not number or number <= 0 or not item then
		return E_INVALID_PARAMETER
	end
	return self:pri_add({{['type']=2, ['number']=number, ['item']=item}})
end]]

--生成批量物品
function Base_bag:create_item_list(item_list)
	if not item_list then
		return E_EPT_PARAMETER
	end
	for k, v in pairs(item_list) do
		if v.type == 1 then
			v.number = tonumber(v.number)
		end
	end
	return self:pri_add(item_list)
end

--检查批量物品
function Base_bag:check_create_item_list(item_list)
	if not item_list then
		return E_EPT_PARAMETER
	end
	return self:pri_check_add(item_list)
end

--删除掉slot位置上的cnt个物品，如果cnt为nil，那么代表删除掉整个slot
function Base_bag:del_item_by_slot(slot, cnt)
	if not slot or not self.slot_list[slot] or (cnt and self.slot_list[slot].number<cnt) then
		return E_INVALID_PARAMETER
	end
	if not cnt then
		cnt = self.slot_list[slot].number
	end

	local log_list = {}
	local item_id = self.slot_list[slot].item_id
	local uuid = self.slot_list[slot].uuid
	local grid = {}
	grid.item = self.slot_list[slot].item
	if cnt >= self.slot_list[slot].number then
		--删除
		grid.number = self.slot_list[slot].number
		log_list[1] = self:get_update_log(ItemSyncFlag.ITEM_SYNC_REMOVE, slot, -self.slot_list[slot].number)
		self:erase_grid(slot)
	else
		--更新数目
		grid.number = cnt
		self.slot_list[slot].number = self.slot_list[slot].number - cnt
		log_list[1] = self:get_update_log(ItemSyncFlag.ITEM_SYNC_UPDATE, slot, -cnt)
	end

	self:inform_other_modual(INFORM_OP.DEL, slot, item_id, uuid, grid)

	return 0, log_list
end


--根据uuid删除cnt个物品
function Base_bag:del_item_by_uuid(uuid, cnt)
	if not uuid  or  not self.uuid_list[uuid] then
		return E_INVALID_PARAMETER
	end
	local slot = self.uuid_list[uuid]
	return self:del_item_by_slot(slot, cnt)

end


--删除cnt个item_id的物品
function Base_bag:del_item_by_item_id(item_id, cnt)
	if not item_id or not cnt or self:get_cnt_by_item_id(item_id) < cnt then
		return E_INVALID_PARAMETER
	end

	local log_list = {}
	local log_pnt = 0

	if self.item_id_list[item_id] then
		for _,slot in pairs(self.item_id_list[item_id]) do
			local uuid = self.slot_list[slot].uuid
			local grid = {}
			grid.item = self.slot_list[slot].item
			if self.slot_list[slot].number == cnt then
				--完全删除
				log_pnt = log_pnt + 1
				log_list[log_pnt] = self:get_update_log(ItemSyncFlag.ITEM_SYNC_REMOVE, slot, -self.slot_list[slot].number)
				self:erase_grid(slot)
				grid.number = cnt
				self:inform_other_modual(INFORM_OP.DEL, slot, item_id, uuid, grid)
				break
			elseif self.slot_list[slot].number < cnt then
				local item_count = self.slot_list[slot].number
				log_pnt = log_pnt + 1
				log_list[log_pnt] = self:get_update_log(ItemSyncFlag.ITEM_SYNC_REMOVE, slot, -self.slot_list[slot].number)
				self:erase_grid(slot)
				grid.number = item_count
				self:inform_other_modual(INFORM_OP.DEL, slot, item_id, uuid, grid)
				cnt = cnt - item_count
			else
				--更新个数
				self.slot_list[slot].number = self.slot_list[slot].number - cnt
				log_pnt = log_pnt + 1
				log_list[log_pnt] = self:get_update_log(ItemSyncFlag.ITEM_SYNC_UPDATE, slot, -cnt)
				grid.number = cnt
				self:inform_other_modual(INFORM_OP.DEL, slot, item_id, uuid, grid)
				break
			end
			--self:inform_other_modual(INFORM_OP.DEL, slot, item_id, uuid)
		end
		return 0, log_list
	else
		return 0, nil
	end
end


--先删除绑定的，后删除不绑定的
function Base_bag:del_item_by_item_id_bind_first(item_id, cnt)
	if not item_id or not cnt then
		return E_INVALID_PARAMETER
	end
	local last_alpha = string.sub(item_id,-1,-1) == '1' and '0' or '1'
	local other_id = string.sub(item_id,1,-2) .. last_alpha

	item_id, other_id = tonumber(item_id), tonumber(other_id)

	local cnt0, cnt1
	if last_alpha == '1' then
		cnt0 = self:get_cnt_by_item_id(item_id)
		cnt1 = self:get_cnt_by_item_id(other_id)
	else
		cnt0 = self:get_cnt_by_item_id(other_id)
		cnt1 = self:get_cnt_by_item_id(item_id)
		item_id, other_id = other_id, item_id
	end
	if cnt0 + cnt1 < cnt then
		return E_INVALID_PARAMETER
	end
	

	if cnt <= cnt0 then
		local e_code, log_list0 = self:del_item_by_item_id(item_id, cnt)
		return e_code, log_list0, cnt
	else
		local e_code, log_list0 = self:del_item_by_item_id(item_id, cnt0)
		if e_code ~=0 then
			return e_code
		end

		local log_list1
		e_code, log_list1 = self:del_item_by_item_id(other_id, cnt - cnt0)
		if e_code ~=0 then
			return e_code
		end
		
		if not log_list0 then 
			return 0,log_list1
		end

		local st = table.getn(log_list0)
		if log_list1 then
			for k,v in pairs(log_list1) do
				st = st + 1
				log_list0[st] = v
			end
		end
		return 0, log_list0, cnt0
	end
end


--使用物品
function Base_bag:use_item(target, slot, param_l)
	if not self.slot_list[slot] then
		return E_INVALID_PARAMETER
	end

	local player = g_obj_mgr:get_obj(self.char_id)
	local scene_o = player:get_scene_obj()
	if scene_o and scene_o:can_use(self.slot_list[slot].item_id)~=true then
		return E_INVALID_SCENE
	end

	local item = self.slot_list[slot].item

	local lock = player:get_protect_lock()
	if not lock then return end
	if lock:check_lock_item(item) then return end

	local e_code = item:can_use(player, target, param_l)
	if e_code ~= 0 then
		return e_code
	end

	local item_id = self.slot_list[slot].item_id
	local uuid = self.slot_list[slot].uuid

	local log_list = {}
	log_list[1] = self:get_update_log(ItemSyncFlag.ITEM_SYNC_UPDATE, slot)

	e_code = item:use(player,target, param_l)
	if e_code ~= 0 then
		return e_code
	end

	self:inform_other_modual(INFORM_OP.USE, slot,item_id, uuid)
	
	local change_list
	if item:remain() == false then
		--self:inform_other_modual(INFORM_OP.USE, slot,item_id, uuid)
		--减去一个物品
		return self:del_item_by_slot(slot, 1)
	else
		--[[--跟新物品
		local log_list = {}
		log_list[1] = self:get_update_log(ItemSyncFlag.ITEM_SYNC_UPDATE, slot)
		return 0, log_list]]
		return 0, log_list
	end
end



--排序
function Base_bag:sort_item()
	local str_id, e_code, stk_num, item_id

	--按item_id排序
	local tmp_list = {}
	local cnt = 0
	for i = _bag_start, self.bag_size do
		if self.slot_list[i] then
			cnt = cnt + 1
			tmp_list[cnt] = self.slot_list[i]
			tmp_list[cnt].slot = i
			tmp_list[cnt].change_num = 0
		end
	end
	local sort_func = function (c1, c2)
		return (c1.item_id < c2.item_id)
	end
	table.sort(tmp_list, sort_func)

	--合并
	local del_list = {}
	local prev = 1
	for cur = 2, cnt do
		if tmp_list[prev].item_id == tmp_list[cur].item_id then
			stk_num =  tmp_list[cur].item:get_stk_num()
			if stk_num > tmp_list[prev].number then
				local space = stk_num - tmp_list[prev].number
				if space < tmp_list[cur].number then
					--叠加不删除
					tmp_list[prev].change_num = tmp_list[prev].change_num or 0
					tmp_list[prev].change_num = tmp_list[prev].change_num + stk_num - tmp_list[prev].number
					tmp_list[prev].number = stk_num
					
					tmp_list[cur].change_num = tmp_list[cur].change_num or 0
					tmp_list[cur].change_num = tmp_list[cur].change_num - space
					tmp_list[cur].number = tmp_list[cur].number - space

					prev = cur
				else
					--叠加并删除
					tmp_list[prev].change_num = tmp_list[prev].change_num or 0
					tmp_list[prev].change_num = tmp_list[prev].change_num +  tmp_list[cur].number
					tmp_list[prev].number = tmp_list[prev].number + tmp_list[cur].number
					
					del_list[cur] = 1
					tmp_list[cur].change_num = tmp_list[cur].change_num or 0
					tmp_list[cur].change_num = tmp_list[cur].change_num - tmp_list[cur].number
				end
			else
				prev = cur
			end
		else
			prev = cur
		end
	end

	--重新构造uuid_list, slot_list, item_id_list
	local log_list = {}
	local log_pnt = 0
	self.slot_list = {}
	self.uuid_list = {}
	self.item_id_list = {}
	self.item_cnt = 0
	local pnt = _bag_start - 1
	local e_code, tmp

	for k, v in pairs(tmp_list) do
		if del_list[k] then
			--删除
			log_pnt = log_pnt + 1
			log_list[log_pnt] = {}
			log_list[log_pnt].op = ItemSyncFlag.ITEM_SYNC_REMOVE
			log_list[log_pnt].bag = self.bag_id
			log_list[log_pnt].slot = v.slot
			log_list[log_pnt].item = v.item
			log_list[log_pnt].uuid = v.uuid
			log_list[log_pnt].item_id = v.item_id
			log_list[log_pnt].number = 0
			log_list[log_pnt].change_num = v.change_num
		else
			--跟新
			pnt = pnt + 1
			e_code, tmp = self:set_grid(pnt, v.uuid, v.number, v.item)
			if e_code~=0 then
				return e_code
			end
			log_pnt = log_pnt + 1
			log_list[log_pnt] = tmp[1]
			log_list[log_pnt].src_uuid = log_list[log_pnt].uuid
			log_list[log_pnt].change_num = v.change_num
		end
	end
	
	return 0, log_list
end


--拆分物品
function Base_bag:split_item(slot, count)
	if count <= 0 or not self.slot_list[slot] or self.slot_list[slot].number<=count or self.slot_list[slot].number==1 then
		return E_INVALID_PARAMETER
	end

	local ept_slot = self:get_ept_slot()
	if not ept_slot then
		return E_BAG_FULL
	end

	local log_list = {}
	local log_pnt = 0

	--更新原有数目
	self.slot_list[slot].number = self.slot_list[slot].number - count
	log_pnt = log_pnt + 1
	log_list[log_pnt] = self:get_update_log(ItemSyncFlag.ITEM_SYNC_UPDATE, slot, -count)

	--创建新的item
	log_pnt = log_pnt + 1
	log_list[log_pnt] = self:get_insert_log(ept_slot, count, self.slot_list[slot].item_id, self.slot_list[slot].item)
	self:load_grid(log_list[log_pnt].slot, log_list[log_pnt].uuid, log_list[log_pnt].number, log_list[log_pnt].item)

	return 0, log_list
end

--生成整个背包数据库日志
function Base_bag:db_get_bag_all_log()
	local log_l = {}
	local c = 0
	for slot,list in pairs(self.slot_list or {}) do
		c = c + 1
		log_l[c] = {slot,list.uuid,list.item_id,list.number,list.item:serialize_to_db()}
	end

	return log_l
end

--生成背包特殊入库属性类
function Base_bag:db_get_bag_attribute()
	return nil
end

function Base_bag:check_item(c_list, item)
	local req_lvl = item:get_req_lvl()
	if (c_list['min_level'] and (not req_lvl or c_list['min_level'] >= req_lvl) )
		or (c_list['max_level'] and (not req_lvl or c_list['max_level'] < req_lvl) )	then
		return false
	end

	local req_color = item:get_color()
	if not req_color then return false end
	if c_list['color'] and c_list['color'] ~= req_color then
		return false
	end

	local req_m_class = item:get_m_class()
	if not req_m_class then return false end
	if c_list['m_class'] and c_list['m_class'] ~= req_m_class then
		return false
	end

	local req_t_class = item:get_t_class()
	if not req_t_class then return false end
	if c_list['t_class'] and c_list['t_class'] ~= req_t_class then
		return false
	end

	local req_s_class = item:get_s_class()
	if not req_s_class then return false end
	if c_list['s_class'] and c_list['s_class'] ~= req_s_class then
		return false
	end

	if not c_list.req_class then return true end
	local req_class= item:get_req_class()
	if not req_class then return false end
	for k, v in pairs(c_list.req_class) do
		if v == req_class then
			return true
		end
	end

	return false
end

function Base_bag:check_item_conditions(c_list)
	local cnt = 0
	for k, v in pairs(self.slot_list) do
		if self:check_item(c_list, v.item) then
			cnt = cnt + v.number
		end
	end
	return 0, cnt
end


-----------------------------------------------------------重载----------------------------------------------------------------------------------------
--物品src_item能否放到dst_bag, dst_slot中
function Base_bag:can_enter(src_item, src_bag, src_slot, dst_bag, dst_slot)
	return 0
end


function Base_bag:test()
	local slot_c=0
	for k,v in pairs(self.slot_list) do
		slot_c = slot_c + 1
		print("s--", k, v.item_id)
	end

	local slot_c_2=0
	for k,v in pairs(self.item_id_list) do
		for h,j in pairs(v) do
			slot_c_2 = slot_c_2 + 1
			print("i--", j, k)
		end
	end

	print("LLLLLLLLLLLLLL", self.bag_id, slot_c, slot_c_2)
end

function Base_bag:get_slot_by_uuid(uuid)
	return self.uuid_list[uuid]
end
