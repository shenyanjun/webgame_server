
local misson_loader = require("mission_ex.mission_loader")

--收集任务
local Quest_steal = oo.class(Quest_base, "Quest_steall")

function Quest_steal:__init(meta)
	Quest_base.__init(self, meta)
	self.collect_list = {}
	self.option_collect_list = {}
end

--on_accept成功后处理
function Quest_steal:instance(con)
	local meta = misson_loader.get_meta(self.quest_id)
	if not meta then
		return
	end
	
	local char_id = con:get_owner()
	local player = char_id and g_obj_mgr:get_obj(char_id)
	local pack_con = player and player:get_pack_con()
	if not pack_con then 
		return
	end
	
	local item_list, option_item_list = self:get_meta_collect_list()
	
	if not item_list and not option_item_list then
		return
	end
	
	self.status = MISSION_STATUS_COMMIT

	if option_item_list then
		local is_empty = true
		self.status = MISSION_STATUS_INCOMPLETE
		for k, v in pairs(option_item_list) do
			is_empty = false
			self.option_collect_list[k] = pack_con:get_item_count(k)
			if self.option_collect_list[k] and v.number <= self.option_collect_list[k] then
				self.status = MISSION_STATUS_COMMIT
			end
		end
		if is_empty then
			self.status = MISSION_STATUS_COMMIT
		end
	end
	
	if item_list then
		for k, v in pairs(item_list) do
			self.collect_list[k] = pack_con:get_item_count(k)
			if not self.collect_list[k] or self.collect_list[k] < v.number then
				self.status = MISSION_STATUS_INCOMPLETE
			end
		end
	end
	
	--限制的完成时间
	self.limit_time = (meta.complete_time or 1800) + ev.time
	self.char_id = char_id 

	self:register_event(con)
end

--已接受任务load_fields之后
function Quest_steal:construct(con)
	self:check_limit_time()

	if self.complete_flag then
		self.status = MISSION_STATUS_COMMIT
		return
	end

	local item_list, option_item_list = self:get_meta_collect_list()
	
	local char_id = con:get_owner()
	local player = char_id and g_obj_mgr:get_obj(char_id)
	local pack_con = player and player:get_pack_con()
	local flags = true

	local meta = misson_loader.get_meta(self.quest_id)
	self.scene_name = g_scene_config_mgr:get_scene_name(meta.scene_id)

	if pack_con then
		if option_item_list then
			flags = false
			for k, v in pairs(option_item_list) do
				self.option_collect_list[k] = pack_con:get_item_count(k)
			end
			for k, v in pairs(option_item_list) do
				if self.option_collect_list[k] and self.option_collect_list[k] >= v.number then
					flags = true
					break
				end
			end
		end

		if item_list then
			for k, v in pairs(item_list) do
				self.collect_list[k] = pack_con:get_item_count(k)
			end
			for k, v in pairs(item_list) do
				if not self.collect_list[k] or self.collect_list[k] < v.number then
					flags = false
					break
				end
			end
		end
	end

	if flags then
		self.status = MISSION_STATUS_COMMIT
	end

	self:register_event(con)
end

function Quest_steal:register_event(con)
	assert(con)
	if self.complete_flag then
		g_scene_mgr_ex:unregister_instance(self.char_id)
		return
	end
	if  MISSION_STATUS_COMMIT ~= self.status then
		con:register_event(MISSION_EVENT_KILL, self.quest_id, self, self.kill_event)
		con:register_event(MISSION_EVENT_ADD_ITEM, self.quest_id, self, self.update_item_event)
	end
	con:register_event(MISSION_EVENT_DEL_ITEM, self.quest_id, self, self.update_item_event)
end

function Quest_steal:unregister_event(con)
	con:unregister_event(MISSION_EVENT_KILL, self.quest_id)
	con:unregister_event(MISSION_EVENT_ADD_ITEM, self.quest_id)
	con:unregister_event(MISSION_EVENT_DEL_ITEM, self.quest_id)

	g_scene_mgr_ex:unregister_instance(self.char_id)
end

--已接受任务，登录初始化时克隆
function Quest_steal:load_fields(record)
	local obj, e_code = Quest_base.load_fields(self, record)
	obj.collect_list  = {}
	obj.option_collect_list = {}
	obj.limit_time 	  = record.limit_time
	obj.complete_time = record.complete_time
	obj.complete_flag = record.complete_flag
	obj.faction_id 	  = record.faction_id
	obj.char_id 	  = record.char_id

	return obj, E_SUCCESS
end

--特殊的保存
function Quest_steal:serialize_to_db()
	local result = Quest_base.serialize_to_db(self)
	
	result.limit_time 	 = self.limit_time		--限制完成时间
	result.complete_time = self.complete_time	--完成该任务的时间（可能没有）
	result.complete_flag = self.complete_flag	--是否提前判断完成（可能没有）
	result.faction_id 	 = self.faction_id		--记录对应的帮派ID（接上就有）
	result.char_id		 = self.char_id

	return result
end

function Quest_steal:serialize_to_net()
	self:check_limit_time(1)

	local result = {}
	local f_name 
	if self.faction_id then
		local faction_obj = g_faction_mgr:get_faction_by_fid(self:get_f_id())
		if not faction_obj then
			self:set_complete(1)
		else
			f_name = faction_obj:get_faction_name()
		end
	end

	result = Quest_base.serialize_to_net(self)
	result.faction_name = f_name
	local collect_list = {}
	for k, v in pairs(self.collect_list) do
		local item = {}
		table.insert(item, k)
		table.insert(item, v)
		table.insert(collect_list, item)
	end
	result.collect_list = collect_list
	result.base[3] = math.max(self.limit_time - ev.time, 0)
	result.complete_flag = self.complete_flag

	return result
end

function Quest_steal:on_accept(char_id)
	--随机帮派，没有则直接置成必完成
	local faction_obj = g_faction_mgr:get_faction_by_cid(char_id)
	if not faction_obj then
		return 200101
	end
	local other_f_id = g_faction_mgr:random_hostility_manor(faction_obj:get_faction_id())
	if not other_f_id then
		return 25020
	end

	local e_code = Quest_base.on_accept(self, char_id)
	--满足条件接上任务和帮派
	if E_SUCCESS == e_code then
		self.faction_id = other_f_id
	end
	return e_code
end

function Quest_steal:set_complete(flags)
	local player = g_obj_mgr:get_obj(self.char_id)
	if not player then
		return
	end

	local con = player:get_mission_mgr()
	if not con then return end

	self.complete_flag = 1

	g_scene_mgr_ex:unregister_instance(self.char_id)
	self.status = MISSION_STATUS_COMMIT
	self:unregister_event(con)

	if not self.complete_time then
		self.complete_time = ev.time
	end

	--需要通知客户端
	if con and not flags then
		con:notity_update_quest(self.quest_id, 1)
	end

	return true
end

--被强制设完成则返回true
--flags则不更新客户端
function Quest_steal:check_limit_time(flags)
	if self.limit_time <= ev.time and not self.complete_flag then
		return self:set_complete(flags)
	end
end

function Quest_steal:get_quest_bonus()
	self:check_limit_time(1)
	if self.complete_flag then 
		return 0
	else
		return 1
	end
end

---------------------------------------------------完成判断
function Quest_steal:get_meta_collect_list()
	local meta = misson_loader.get_meta(self.quest_id)
	local postcondition = meta and meta.postcondition
	if postcondition then
		return postcondition.collect_list and postcondition.collect_list.item_list
				, postcondition.option_collect_list and postcondition.option_collect_list.item_list
	end
	return nil, nil
end

function Quest_steal:on_complete(char_id, select_list, bonus, param_l)
	local get_rate = self:get_quest_bonus()

	--超时完成 不扣任何东西
	if self.complete_flag then
		local e_code, next_quest_chain = Quest_base.on_complete(self, char_id, select_list, (bonus or 1) * get_rate)
		g_scene_mgr_ex:unregister_instance(self.char_id)
		return e_code, next_quest_chain
	end

	local player = char_id and g_obj_mgr:get_obj(char_id)
	local pack_con = player and player:get_pack_con()
	if not pack_con then 
		return
	end

	local item_list, option_item_list = self:get_meta_collect_list()
	local item_tmp = {}
	if param_l then
		local slot_l = param_l.slot_l
		local item_l = {}
		local flags = false
		local bag
		e_code , bag = pack_con:get_bag(SYSTEM_BAG)
		if e_code ~= 0 then
			return e_code
		end

		for i = 1, table.getn(slot_l) do
			
			local slot = bag:get_item_by_slot(slot_l[i])
			if pack_con:check_item_lock_by_bag_slot(SYSTEM_BAG, slot_l[i]) then return end
			if not slot or item_l[slot.item_id] then
				return 25015
			end
			item_l[slot.item_id] = slot.number
			item_tmp[slot.item_id] = {}
			item_tmp[slot.item_id].slot = slot_l[i]
			item_tmp[slot.item_id].cnt = 0
		end

		if item_list then
			for k, v in pairs(item_list) do
				if not item_l[k] or item_l[k] < v.number then
					return 25015
				else
					item_l[k] = item_l[k] - v.number
					item_tmp[k].cnt = item_tmp[k].cnt + v.number
				end
			end
		end
		if option_item_list then
			for k, v in pairs(option_item_list) do
				if item_l[k] and item_l[k] >= v.number then
					flags = true
					item_tmp[k].cnt = item_tmp[k].cnt + v.number
					break
				end
			end
		end
		if not flags then return 25015 end

		for k, v in pairs(item_tmp) do
			local slot = bag:get_item_by_slot(v.slot)
			if slot.number < v.cnt then return 25015 end
		end
	end

	local e_code, next_quest_chain = Quest_base.on_complete(self, char_id, select_list, (bonus or 1) * get_rate)
	if E_SUCCESS == e_code then	
		if not param_l then
			if pack_con then
				if item_list then
					for k, v in pairs(item_list) do
						pack_con:del_item_by_item_id(k, v.number, {['type'] = ITEM_SOURCE.TASK})
					end
				end
				
				if option_item_list then
					for k, v in pairs(option_item_list) do
						if v.number <= self.option_collect_list[k] then
							pack_con:del_item_by_item_id(k, v.number, {['type'] = ITEM_SOURCE.TASK})
							break
						end
					end
				end
			end
		else
			for k, v in pairs(item_tmp) do
				pack_con:del_item_by_bag_slot(SYSTEM_BAG, v.slot, v.cnt, {['type'] = ITEM_SOURCE.TASK})
			end
		end

	end
	return e_code, next_quest_chain
end

function Quest_steal:must_collect_lost(postcondition, monster_id, lost_list)
	local monster_info = postcondition.collect_list and postcondition.collect_list.monster_list
							and postcondition.collect_list.monster_list[monster_id]
	if not monster_info or not monster_info.probability then
		return false
	end
	
	local probability = math.random(1, 100)
	if probability > monster_info.probability then
		return false
	end
	
	local item_id = monster_info.item_id
	local item_info = postcondition.collect_list.item_list
						and (item_id and postcondition.collect_list.item_list[item_id])
	if not item_info then
		return false
	end
	
	local number = self.collect_list[item_id]
	if not number or number >= item_info.number then
		return false
	end

	table.insert(lost_list, item_id)
	return true
end

function Quest_steal:option_collect_lost(postcondition, monster_id, lost_list)
	local monster_info = postcondition.option_collect_list and postcondition.option_collect_list.monster_list
							and postcondition.option_collect_list.monster_list[monster_id]
	if not monster_info or not monster_info.probability then
		return false
	end
	
	local probability = math.random(1, 100)
	if probability > monster_info.probability then
		return false
	end
	
	local item_id = monster_info.item_id
	local item_info = postcondition.option_collect_list.item_list
						and (item_id and postcondition.option_collect_list.item_list[item_id])
	
	if not item_info then
		return false
	end
	
	local number = self.option_collect_list[item_id]
	if not number or number >= item_info.number then
		return false
	end
	
	table.insert(lost_list, item_id)
	return true
end

function Quest_steal:kill_event(con, monster_id, lost_list)
	local meta = misson_loader.get_meta(self.quest_id)
	if not meta or not meta.postcondition or not monster_id then
		return
	end
	
	if not self:must_collect_lost(meta.postcondition, monster_id, lost_list) then
		self:option_collect_lost(meta.postcondition, monster_id, lost_list)
	end
end

--返回值一表示是否通过检查,　返回值二表示状态是否改变
function Quest_steal:check_collect_must(item_list, item_id)
	if self.collect_list[item_id] < item_list[item_id].number then
		return false, MISSION_STATUS_COMMIT == self.status
	end
	
	if MISSION_STATUS_COMMIT == self.status then
		return true, false
	end
	
	for k, v in pairs(item_list) do
		if not self.collect_list[k] or self.collect_list[k] < v.number then
			return false, false
		end
	end
	
	return true, true
end

--返回值一表示是否通过检查,　返回值二表示状态是否改变
function Quest_steal:check_collect_option(option_item_list, item_id)
	if self.option_collect_list[item_id] < option_item_list[item_id].number then
		for k, v in pairs(option_item_list) do
			if self.option_collect_list[k] and v.number <= self.option_collect_list[k] then
				return true, MISSION_STATUS_COMMIT ~= self.status
			end
		end
		return false, MISSION_STATUS_COMMIT == self.status
	end
	
	return true, MISSION_STATUS_COMMIT ~= self.status
end

function Quest_steal:update_item_event(con, item_id)
	if not item_id then
		return 
	end

	if self:check_limit_time() then return end

	local item_list, option_item_list = self:get_meta_collect_list()
	local must_item = item_list and item_list[item_id]
	local option_item = option_item_list and option_item_list[item_id]
	if not must_item and not option_item then
		return
	end

	local char_id = con:get_owner()
	local player = char_id and g_obj_mgr:get_obj(char_id)
	local pack_con = player and player:get_pack_con()
	if not pack_con then 
		return
	end
	
	local is_success, is_change = false, false
	if must_item and option_item then
		local item_number = pack_con:get_item_count(item_id)
		self.collect_list[item_id] = item_number
		self.option_collect_list[item_id] = item_number
		
		is_success, is_change = self:check_collect_must(item_list, item_id)
		if is_success then
			is_success, is_change = self:check_collect_option(option_item_list, item_id)
		end
	elseif must_item then
		self.collect_list[item_id] = pack_con:get_item_count(item_id)
		is_success, is_change = self:check_collect_must(item_list, item_id)
	elseif option_item then
		self.option_collect_list[item_id] = pack_con:get_item_count(item_id)
		is_success, is_change = self:check_collect_option(option_item_list, item_id)
	end
	
	if is_success and not is_change then --成功且状态没有改变的不用通知
		return
	end
	
	if is_success then	
		con:unregister_event(MISSION_EVENT_KILL, self.quest_id)
		con:unregister_event(MISSION_EVENT_ADD_ITEM, self.quest_id)
		self.status = MISSION_STATUS_COMMIT

		self.complete_time = ev.time

	elseif is_change then
		con:register_event(MISSION_EVENT_KILL, self.quest_id, self, self.kill_event)
		con:register_event(MISSION_EVENT_ADD_ITEM, self.quest_id, self, self.update_item_event)
		self.status = MISSION_STATUS_INCOMPLETE
	end
	
	con:notity_update_quest(self.quest_id, is_change)
end

Mission_mgr.register_class(MISSION_FLAG_STEAL, Quest_steal)
