
local _bag_size = 4
local _bag_start = 1
local pet_bag_table = "pet_bag"

Pet_bag = oo.class(nil, "Pet_equipment_bag")

function Pet_bag:__init(obj_id, owner_id)
	self.obj_id = obj_id      --pet id
	self.owner_id = owner_id  --human id
	self.bag_size = _bag_size
	self.item_cnt = 4 		  --格子个数,最少为4

	--下标为格子编号，内容包括：uuid,item_id,number,item
	self.slot_list = {}

	self.cur_practice = 0		--当前在修炼的装备
end

function Pet_bag:get_max_skill_level()
	local player = g_obj_mgr:get_obj(self.owner_id)
	if not player then return end

	local pet_con = player:get_pet_con()
	if not pet_con then return end

	local pet_obj = pet_con:get_pet_obj(self.obj_id)
	if not pet_obj then return end

	local skill_con = pet_obj:get_skill_con()
	if not skill_con then return end

	return skill_con:get_max_skill_level()
end

function Pet_bag:get_size()
	return self.item_cnt
end

function Pet_bag:get_max_size()
	return self.bag_size
end

function Pet_bag:get_equip_count()
	local count = 0
	for i = _bag_start, self.bag_size do
		if self.slot_list[i] then
			count = count + 1
		end
	end
	return count
end

function Pet_bag:is_empty()
	for i = _bag_start, self.bag_size do
		if self.slot_list[i] then
			return false
		end
	end
	return true
end

function Pet_bag:is_on_practice(exp)
	if self.cur_practice == 0 then
		return false
	end
	local level = self.slot_list[self.cur_practice].item:get_level()	
	local player = g_obj_mgr:get_obj(self.owner_id)
	local pet_con = player:get_pet_con()
	local pet_obj = pet_con:get_pet_obj(self.obj_id)
	local pet_level = pet_obj:get_level()

	if level >= pet_level then 
		return false
	end

	return self.slot_list[self.cur_practice].item:check_add_exp(math.floor(exp * 0.9))

end
--装备修炼
function Pet_bag:set_cur_practice(slot)
	if slot == 0 or (self.slot_list[slot] and slot ~= 0) then			
		self.cur_practice = slot
		self:update_list()				
		self:update_pet_equip()
		return 0
	end
	return 20574
end

--为修炼的装备增加经验
function Pet_bag:add_exp_to_practice(exp)
	if self.cur_practice == 0 then return end
	local level = self.slot_list[self.cur_practice].item:get_level()	
	local player = g_obj_mgr:get_obj(self.owner_id)
	local pet_con = player:get_pet_con()
	local pet_obj = pet_con:get_pet_obj(self.obj_id)
	local pet_level = pet_obj:get_level()

	if level >= pet_level then 
		return 
	end

	if self.slot_list[self.cur_practice] and self.cur_practice ~= 0 then
		exp = 0.9 * exp
		self.slot_list[self.cur_practice].item:add_exp(exp,self.owner_id)
		self:update_list()				
		self:update_pet_equip()
	end
end

--加载一条物品记录
function Pet_bag:add_grid(slot, uuid, number, item)
	if not slot or not uuid or not number or not item or slot < _bag_start or slot > self.bag_size then
		return -1
	end

	local item_id = item:get_item_id()
	if self.slot_list[slot] == nil then
		self.item_cnt = self.item_cnt + 1
	end

	self.slot_list[slot] = {}
	self.slot_list[slot].uuid = uuid
	self.slot_list[slot].number = number
	self.slot_list[slot].item = item
	self.slot_list[slot].item_id = item_id

	return 0
end

--删除一个格子
function Pet_bag:erase_grid(slot)
	if self.slot_list[slot] ~= nil then
		self.slot_list[slot] = nil
		self.item_cnt = self.item_cnt - 1
	end
end

--重置一个格子
function Pet_bag:set_grid(slot, uuid, number, item)
	self:erase_grid(slot)
	self:add_grid(slot, uuid, number, item)
end

--获取格子
function Pet_bag:get_grid(slot)
	return self.slot_list[slot]
end

function Pet_bag:can_enter(item, bag, slot)
	--判断是否为宠物装备
	if tonumber(item:get_m_class()) ~= ItemClass.ITEM_CLASS_EQUIP then
		return 43015
	end
	if tonumber(item:get_s_class()) ~= 91 then
		return 20564
	end

	local player = g_obj_mgr:get_obj(self.owner_id)
	local pet_con = player:get_pet_con()
	local pet_obj = pet_con:get_pet_obj(self.obj_id)
	--级别
	if not item:valid_level(pet_obj) then
		return 20575
	end
	--位置判断
	if slot ~= tonumber(item:get_t_class()) then
		return 20305
	end

	return 0
end

--宠物背包 to 人物背包
function Pet_bag:pet_to_bag(src_bag, src_slot, dst_bag, dst_slot)
	local player = g_obj_mgr:get_obj(self.owner_id)
	local pack_con = player and player:get_pack_con()
	if pack_con == nil then return end

	local grid_item = self:get_grid(src_slot)
	if grid_item == nil then
		return 43056
	end
	local e_code = pack_con:add_by_item(grid_item.item, {['type']=ITEM_SOURCE.PET_BAG})		--将宠物背包的物品插入到人物背包
	if e_code == 0 then	
		self:erase_grid(src_slot)															--同时，将宠物背包的格子删除
	end
	if self.cur_practice == src_slot then													--当前修炼为src_slot,则重置
		self.cur_practice = 0
	end

	local result = self:update_list()														--及时更新宠物装备属性
	self:update_pet_equip(1)

	return e_code
end

--人物背包 to 宠物背包
function Pet_bag:bag_to_pet(src_bag, src_slot, dst_bag, dst_slot)
	local player = g_obj_mgr:get_obj(self.owner_id)
	local pack_con = player and player:get_pack_con()
	assert(pack_con)
	local e_code , src_bag_ctn = pack_con:get_bag(src_bag)
	if e_code ~= 0 then
		return e_code
	end
	local pack_item = src_bag_ctn:get_grid(src_slot)
	if pack_item == nil then
		return 43056
	end

	if pack_con:check_item_lock_by_bag_slot(src_bag,src_slot) then		return	end

	dst_slot = pack_item.item:get_t_class()		
	e_code = self:can_enter(pack_item.item, dst_bag, dst_slot)
	if e_code ~= 0 then
		return e_code
	end
									
	local pet_item = self:get_grid(dst_slot)
	if pet_item then																			--宠物背包不为空，交换
		local e_code = pack_con:add_by_item(pet_item.item, {['type']=ITEM_SOURCE.PET_BAG})		--宠物背包的物品插入到人物背包
		if dst_slot == self.cur_practice and e_code == 0 then									--当前修炼为dst_slot,则重置
			self.cur_practice = 0
		end
		if e_code ~= 0 then
			return e_code
		end
	end			
	local dst_grid = src_bag_ctn:get_grid(src_slot)					
	self:set_grid(dst_slot, dst_grid.uuid, 1, pack_item.item)								--人物背包的物品插入到宠物背包
	pack_con:del_item_by_bag_slot(src_bag, src_slot, 1, {['type']=ITEM_SOURCE.PET_BAG})		--将物品从人物背包中删除掉

	local result = self:update_list()														--及时更新宠物装备属性
	self:update_pet_equip(1)

	local event_args = {}
	event_args.count = self:get_equip_count()
	g_event_mgr:notify_event(EVENT_SET.EVENT_ADDPET_JADE, self.owner_id, event_args)

	local event_args = {}
	event_args.level = self:get_max_skill_level()
	g_event_mgr:notify_event(EVENT_SET.EVENT_PET_STUDY_SKILL, self.owner_id, event_args)

	return e_code
end

function Pet_bag:update_pet_equip(flag)
	local player = g_obj_mgr:get_obj(self.owner_id)
	local pet_con = player:get_pet_con()
	local pet_obj = pet_con:get_pet_obj(self.obj_id)

	if flag ~= nil then
		local skill_con = pet_obj:get_skill_con()
		skill_con:equip_change_skill()
		if pet_obj:get_combat_status() == PET_STATUS_COMBAT then
			pet_obj:on_update_attribute(3)
			pet_obj:on_change_equip()
			pet_obj:pri_update_transfer_skill()
		else
			pet_obj:on_change_equip()
		end
	else
		pet_obj:on_change_equip()
	end
end

function Pet_bag:get_bag_start()
	return _bag_start
end

--获取背包里面的所有物品
function Pet_bag:get_equip()
	local ret = {}
	local pnt = 0
	local have = false
	for i = _bag_start, self.bag_size do
		local equip = self:get_grid(i)
		if equip then
			have = true
			pnt = pnt + 1
			ret[pnt] = equip
		end
	end

	if not have then
		return {}
	else
		return ret
	end
end

--获取背包信息
function Pet_bag:net_get_bag_info()
	local info = {}
	local cnt = 0
	local item_info
	for i = _bag_start, self.bag_size do
		if self.slot_list[i] then
			item_info = {}
			item_info[1] = self.slot_list[i].uuid
			item_info[2] = nil
			item_info[3] = PET_BAG
			item_info[4] = i
			item_info[5] = self.slot_list[i].number or 1
			item_info[6] = self.slot_list[i].item:serialize_to_net()
			item_info[7] = nil

			cnt = cnt + 1
			info[cnt] = item_info
		end
	end
	return info
end

--更新包 to client
function Pet_bag:update_list()
	local new_pkt = {}	
	new_pkt[1] = self:get_max_size()
	new_pkt[2] = self:net_get_bag_info()
	new_pkt[3] = self.obj_id
	new_pkt[4] = self.cur_practice

	--print("=======>>>>>CMD_MAP_PET_GET_BAG_S", j_e(new_pkt))
	g_cltsock_mgr:send_client(self.owner_id, CMD_MAP_PET_GET_BAG_S, new_pkt)
	return 0
end

--获取宠物背包中的技能全部
function Pet_bag:get_skill_list()
	local ret = {}
	for k,v in pairs(self.slot_list) do
		local skill_list = v.item:get_skill_list_ex()
		for m, n in pairs(skill_list or {}) do
			local skill_id = math.floor(n[1] / 10) * 10
			if ret[skill_id] == nil then
				ret[skill_id] = 0
			end
			ret[skill_id] = ret[skill_id] + n[3]
		end
	end
	return ret
end


--数据库操作
function Pet_bag:serialize_to_db()
	local log_l = {}
	local c = 0
	for slot,list in pairs(self.slot_list or {}) do
		c = c + 1
		log_l[c] = {slot,list.uuid,list.item_id,list.item:serialize_to_db()}
	end

	return log_l
end

function Pet_bag:serialize()
	local update = {}
	update.item_l = self:serialize_to_db()
	update.cur_practice = self.cur_practice

	local db = f_get_db()

	--print("@@@@@@@@@@@@@@@@@@@@serialize@@@@@@@@@@@@@@@@@@@@")
	--print("update:",j_e(update))
--
	local e_code = db:update(pet_bag_table, string.format("{char_id:%d,pet_id:%d}", self.owner_id, self.obj_id),Json.Encode(update), true)
end

function Pet_bag:unserialize()
	local dbh = f_get_db()
	local condition = string.format("{char_id:%d,pet_id:%d}", self.owner_id, self.obj_id)
	local db_items = dbh:select_one(pet_bag_table, nil, condition, nil, "{char_id:1,pet_id:1}")

	if db_items then
		for k,v in pairs(db_items.item_l or {}) do 
			local e_code, item = Item_factory.clone(v[3],v[4])
			if e_code ~= 0 then
				print("item clone error:",Json.Encode(v))
			else 
				self:add_grid(v[1],v[2],1,item)				--装备统统为1
			end
		end
		self.cur_practice = db_items.cur_practice or 0
	end

	--print("@@@@@@@@@@@@@@@@@@@@unserialize@@@@@@@@@@@@@@@@@@@@")
	--print("self.cur_practice:",self.cur_practice)
	--for k,item in pairs(self.slot_list) do
		--print(k,j_e(item))
	--end

end

function Pet_bag:get_common_syn_info()
	local log_l = {}
	local c = 0
	for slot,list in pairs(self.slot_list or {}) do
		c = c + 1
		log_l[c] = {slot,list.uuid,list.item_id,list.item:serialize_to_db()}
	end

	return log_l
end
