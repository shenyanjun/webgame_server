
local misson_loader = require("mission_ex.mission_loader")

--收集任务
local Quest_collect_visit = oo.class(Quest_base, "Quest_collect_visit")

function Quest_collect_visit:__init(meta)
	Quest_base.__init(self, meta)
end

--on_accept成功后处理
function Quest_collect_visit:instance(con)
	local meta = misson_loader.get_meta(self.quest_id)
	if not meta then
		return
	end
	
	self.status = MISSION_STATUS_INCOMPLETE
	
	--限制的完成时间
	self.limit_time = (meta.complete_time or 1800) + ev.time

	self.char_id = con:get_owner()

end

--已接受任务load_fields之后
function Quest_collect_visit:construct(con)
	if self.complete_flag then
		self.status = MISSION_STATUS_COMMIT
		return
	end

	self.char_id = con:get_owner()
end

--已接受任务，登录初始化时克隆
function Quest_collect_visit:load_fields(record)
	local obj, e_code = Quest_base.load_fields(self, record)
	obj.collect_list  = {}
	obj.option_collect_list = {}
	obj.limit_time 	  = record.limit_time
	obj.complete_time = record.complete_time
	obj.faction_id 	  = record.faction_id
	obj.char_id 	  = record.char_id

	return obj, E_SUCCESS
end

--特殊的保存
function Quest_collect_visit:serialize_to_db()
	local result = Quest_base.serialize_to_db(self)
	
	result.limit_time 	 = self.limit_time		--限制完成时间
	result.complete_time = self.complete_time	--完成该任务的时间（可能没有）
	result.faction_id 	 = self.faction_id		--记录对应的帮派ID（接上就有）
	result.complete_flag = self.complete_flag
	result.char_id 		 = self.char_id

	return result
end

function Quest_collect_visit:serialize_to_net()
	self:check_limit_time(1)
	local f_name
	if self.faction_id then
		local faction_obj = g_faction_mgr:get_faction_by_fid(self:get_f_id())
		if not faction_obj then
			self:set_complete(1)
		else
			f_name = faction_obj:get_faction_name()
		end
	end

	local result = Quest_base.serialize_to_net(self)
	result.faction_name = f_name
	result.base[3] = math.max(self.limit_time - ev.time, 0)
	result.faction_id = self.faction_id
	result.complete_flag = self.complete_flag

	return result
end

function Quest_collect_visit:on_accept(char_id)
	--随机帮派，没有则直接置成必完成
	local faction_obj = g_faction_mgr:get_faction_by_cid(char_id)
	if not faction_obj then
		return 200101
	end
	local other_f_id = g_faction_mgr:random_friend_manor(faction_obj:get_faction_id())
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

--function Quest_collect_visit:set_complete(con)
	--self.complete_flag = 1
	--self.status = MISSION_STATUS_COMMIT
--
	--if not self.complete_time then
		--self.complete_time = ev.time
	--end
--
	--con:notity_update_quest(self.quest_id, 1)
--end

function Quest_collect_visit:set_complete(flags)
	local player = g_obj_mgr:get_obj(self.char_id)
	if not player then
		return
	end

	local con = player:get_mission_mgr()
	if not con then return end

	self.complete_flag = 1
	self.status = MISSION_STATUS_COMMIT
	--self:unregister_event(con)

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
function Quest_collect_visit:check_limit_time(flags)
	if self.limit_time <= ev.time and not self.complete_flag then
		return self:set_complete(flags)
	end
end

function Quest_collect_visit:get_quest_bonus()
	self:check_limit_time(1)
	if self.complete_flag then 
		return 0
	else
		return 1
	end
end

---------------------------------------------------完成判断
function Quest_collect_visit:on_complete(char_id, select_list, bonus, param_l)
	local get_rate = self:get_quest_bonus()

	--超时完成 不扣任何东西
	if self.complete_flag then
		local e_code, next_quest_chain = Quest_base.on_complete(self, char_id, select_list, (bonus or 1) * get_rate)
		return e_code, next_quest_chain
	end

	local player = char_id and g_obj_mgr:get_obj(char_id)
	local pack_con = player and player:get_pack_con()
	if not pack_con or not param_l or not param_l.slot_l then 
		return 1
	end

	local item_list, option_item_list = self:get_meta_collect_list()
	local item_tmp = {}

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
		if pack_con:check_item_lock_by_bag_slot(SYSTEM_BAG, slot_l[i]) then return 1 end
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

	local meta = misson_loader.get_meta(self.quest_id)
	if not meta then
		return E_MISSION_INVALID_ID, nil
	end
	
	self:set_status(MISSION_STATUS_FINISH)
	
	local next_quest_chain = nil
	if meta.reward then
		local e_code = self:do_reward(player, meta.reward, select_list, (bonus or 1) * get_rate)
		if E_SUCCESS ~= e_code then
			self:set_status(MISSION_STATUS_COMMIT)
			return e_code, nil
		end
		
		next_quest_chain = meta.reward.next_quest_chain
	end

	if E_SUCCESS == e_code then	
		for k, v in pairs(item_tmp) do
			pack_con:del_item_by_bag_slot(SYSTEM_BAG, v.slot, v.cnt, {['type'] = ITEM_SOURCE.TASK})
		end
	end
	return e_code, next_quest_chain
end

function Quest_collect_visit:get_meta_collect_list()
	local meta = misson_loader.get_meta(self.quest_id)
	local postcondition = meta and meta.postcondition
	if postcondition then
		return postcondition.collect_list and postcondition.collect_list.item_list
				, postcondition.option_collect_list and postcondition.option_collect_list.item_list
	end
	return nil, nil
end

Mission_mgr.register_class(MISSION_FLAG_COLLECT_VISIT, Quest_collect_visit)
