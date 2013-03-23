--2012-05-21
--zhengyg
--faction bag manager

-------------------------------------------
--[[
interface info:
	faction_bag_mgr:get_faction_bag(factionObj)
	faction_bag_mgr:get_faction_bag_by_faction_id(id)
	faction_bag_mgr:can_merge(a_id,b_id)
	faction_bag_mgr:merge(a_id,b_id)
]]
--faction bag manager , globle singleton
faction_bag_mgr = oo.class(nil,"faction_bag_mgr")

function faction_bag_mgr:__init()
	self.m_faction_bags={}
	self.m_modify_list = {}
	self.m_modify_record_list = {}
end
--private functions start
--add one bag
function faction_bag_mgr:add_bag(bag)
	self.m_faction_bags[bag:get_faction_id()] = bag
end
--create a new bag
function faction_bag_mgr:build_bag(max_cnt,faction_id)
	if faction_id then
		return faction_bag(max_cnt,faction_id)
	end
	return nil
end
-- private functions end
-- public functions start
-- get bag by faction id
function faction_bag_mgr:get_bag_by_fid(id)
	local faction = g_faction_mgr:get_faction_by_fid(id)--(factionObj:get_faction_id())
	--print('faction_bag_mgr:get_bag_by_fid faction..'..type(faction))
	if faction then
		local bag = self.m_faction_bags[faction:get_faction_id()]
		if nil == bag then
			bag = self:build_bag(nil,faction:get_faction_id())
			self:add_bag(bag)
		end
		if faction.get_warehouse_level and faction.get_grid_cnt then
			bag:update_lvl_grid_cnt(faction:get_warehouse_level(),faction:get_grid_cnt())
		end
		return bag
	end
	return nil
end
-- get bag by faction obj
function faction_bag_mgr:get_faction_bag(factionObj)
	return self:get_bag_by_fid(factionObj:get_faction_id())
end
--load all faction_bag from db
function faction_bag_mgr:db_load()
	local dbh = f_get_db()
	local rows, e_code = dbh:select('faction_bag')
	if 0 ~= e_code then
		print('faction_bag_mgr:db_load() error')
		assert(0)
	end
	if rows then
		for _,pack in pairs(rows) do
			local faction_id 	= pack.faction_id
			if faction_id then
				local bag = self:build_bag(nil,faction_id)  
				bag:unserialized(pack)
				self:add_bag(bag)
			end
		end
	end
	
	local rows, e_code = dbh:select('faction_bag_record')
	if 0 ~= e_code then
		print('faction_bag_mgr:db_load() record error')
		assert(0)
	end
	if rows then
		for _,pack in pairs(rows) do
			local faction_id 	= pack.faction_id
			if faction_id then
				bag = self:get_bag_by_fid(faction_id)
				if bag then
					bag:unserialized_record(pack)
					--print(j_e(pack))
				end
			end
		end
	end
end
--call when server down , save all bags
function faction_bag_mgr:db_save()
	self:on_timer(true)
end
--call by on_timer() , serialize one bag obj to db
function faction_bag_mgr:db_save_one(bag)
	local pack = bag:serialized()
	local condition = string.format("{faction_id:'%s'}", bag:get_faction_id())
	
	--print(Json.Encode(pack))
	
	local dbh = f_get_db()
	local e_code = dbh:update('faction_bag', condition, Json.Encode(pack), true)
	if e_code~=0 then
		print('faction_bag_mgr:save_one() error faction_id:'..bag:get_faction_id())
	else
		--print('faction_bag_mgr:save_one() suc   faction_id:'..bag:get_faction_id())
	end	
	return e_code
	
end
function faction_bag_mgr:db_save_one_record(bag)
	local record = bag:serialized_record()
	local dbh = f_get_db()
	local condition = string.format("{faction_id:'%s'}", bag:get_faction_id())
	local e_code = dbh:update('faction_bag_record', condition, Json.Encode(record), true)
	if e_code~=0 then
		print('faction_bag_mgr:save_one() record error faction_id:'..bag:get_faction_id())
	else
		--print('faction_bag_mgr:save_one() suc   faction_id:'..bag:get_faction_id())
	end
	return e_code
end
--timer info
function faction_bag_mgr:get_click_param()
	return self,self.on_timer,7*60,nil
end

function faction_bag_mgr:get_click_param2()
	return self,self.on_timer2,17*60,nil
end
--call by timer
function faction_bag_mgr:on_timer()
	self:timer_save()
end
function faction_bag_mgr:on_timer2()
	self:timer_save_record()
end
function faction_bag_mgr:timer_save(save_all_flag)	
	if save_all_flag == nil then
		for faction_id,_ in pairs(self.m_modify_list) do
			local bag = self:get_bag_by_fid(faction_id)
			if bag then
				if self:db_save_one(bag) == 0 then
					bag:reset_earliest_save_time()
					self.m_modify_list[faction_id] = nil
				end
			end
		end
	else
		for faction_id,bag in pairs(self.m_faction_bags) do
			if bag:get_earliest_save_time()~=0 or save_all_flag then
				if self:db_save_one(bag) == 0 then
					bag:reset_earliest_save_time()
				end
			end
		end
	end
end

function faction_bag_mgr:timer_save_record(save_all_flag)	
	if save_all_flag==nil then
		for faction_id,_ in pairs (self.m_modify_record_list) do
			local bag = self:get_bag_by_fid(faction_id)
			if bag then
				if self:db_save_one_record(bag) == 0 then
					bag:reset_record_modify_time()
					self.m_modify_record_list[faction_id] = nil
				end
			end
		end
	else
		for faction_id,bag in pairs(self.m_faction_bags) do
			if bag:get_record_modify_time()~=0 or save_all_flag then
				if self:db_save_one_record(bag) == 0 then
					bag:reset_record_modify_time()
				end
			end
		end
	end
end

function faction_bag_mgr:get_faction_by_fid_directly(fid)
	return self.m_faction_bags[fid]
end
function faction_bag_mgr:can_merge(faction_a_id,faction_b_id)
	local bag_a = self:get_faction_by_fid_directly(faction_a_id)
	local bag_b = self:get_faction_by_fid_directly(faction_b_id)
	if bag_b == nil then return 0 end
	if bag_a == nil then
		bag_a = self:get_bag_by_fid(faction_a_id)
		if bag_a == nil then return 1 end -- can not
	end
	local cnt , items_info_b = bag_b:items_info()
	if cnt == 0 then return 0 end -- no item
	if 0 == bag_a:check_can_add(items_info_b) then
		return 0
	end
	return 31166
end

function faction_bag_mgr:merge(faction_a_id,faction_b_id)
	local e_code = self:can_merge(faction_a_id,faction_b_id)
	if e_code~=0 then return e_code end

	local bag_a = self:get_faction_by_fid_directly(faction_a_id)
	local bag_b = self:get_faction_by_fid_directly(faction_b_id)
	if bag_b == nil then return 0 end
	if bag_a == nil then
		bag_a = self:get_bag_by_fid(faction_a_id)
		if bag_a == nil then return 1 end -- can not
	end
	local cnt , items_info_b = bag_b:items_info()
	if cnt == 0 then return 0 end
	local ret , notice1 =  bag_a:add_item_bat(items_info_b)
	if ret == 0 then
		bag_a:update_client2(faction_a_id,bag_a:notice_grid_change_to_net(notice1))
	end
	local ret2 ,notice2  =  bag_b:del_item_bat(items_info_b)
	if ret2 == 0 then
		bag_b:update_client2(faction_b_id,bag_b:notice_grid_change_to_net(notice2))
	end
	return ret
end

function faction_bag_mgr:add_modify_bag(bag)
	self.m_modify_list[bag:get_faction_id()] = true
end
function faction_bag_mgr:add_modify_record(bag)
	self.m_modify_record_list[bag:get_faction_id()] = true
end