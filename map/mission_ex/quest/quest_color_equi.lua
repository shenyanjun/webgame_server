
local misson_loader = require("mission_ex.mission_loader")

--收集任务
local Quest_color_equi = oo.class(Quest_base, "Quest_color_equi")

function Quest_color_equi:__init(meta)
	Quest_base.__init(self, meta)
	self.counts = 0
	self.collect_condition = {}
end

function Quest_color_equi:instance(con)
	local meta = misson_loader.get_meta(self.quest_id)
	if not meta then
		return
	end

	self.status = MISSION_STATUS_INCOMPLETE

	self.collect_condition = meta.postcondition.collect_condition
	self.counts = meta.postcondition.collect_condition.count

	local char_id = con:get_owner()
	local player = char_id and g_obj_mgr:get_obj(char_id)
	local pack_con = player and player:get_pack_con()
	if not pack_con then 
		return
	end
	
	local e_code, cnt = pack_con:check_item_conditions(self.collect_condition)
	self.counts = cnt
	if cnt >= meta.postcondition.collect_condition.count then
		self.status = MISSION_STATUS_COMMIT
	end

	self:register_event(con)
end

function Quest_color_equi:construct(con)
	local meta = misson_loader.get_meta(self.quest_id)
	if not meta then
		return
	end

	self.status = MISSION_STATUS_INCOMPLETE

	self.collect_condition = meta.postcondition.collect_condition

	local char_id = con:get_owner()
	local player = char_id and g_obj_mgr:get_obj(char_id)
	local pack_con = player and player:get_pack_con()
	if not pack_con then 
		return
	end
	
	local e_code, cnt = pack_con:check_item_conditions(self.collect_condition)

	self.counts = cnt
	if cnt >= meta.postcondition.collect_condition.count then
		self.status = MISSION_STATUS_COMMIT
	end

	self:register_event(con)
end

function Quest_color_equi:register_event(con)
	assert(con)

	con:register_event(MISSION_EVENT_ADD_ITEM, self.quest_id, self, self.update_add_item_event)
	con:register_event(MISSION_EVENT_DEL_ITEM, self.quest_id, self, self.update_sub_item_event)
end

function Quest_color_equi:unregister_event(con)
	con:unregister_event(MISSION_EVENT_ADD_ITEM, self.quest_id)
	con:unregister_event(MISSION_EVENT_DEL_ITEM, self.quest_id)
end

--function Quest_color_equi:load_fields(record)
	--local obj, e_code = Quest_base.load_fields(self, record)
	--return obj, E_SUCCESS
--end

function Quest_color_equi:serialize_to_net()
	local result = Quest_base.serialize_to_net(self)
	result.item_count = self.counts
	return result
end

---------------------------------------------------完成判断
function Quest_color_equi:on_complete(char_id, select_list, bonus, param_l)
	local get_rate = self:get_quest_bonus()

	local player = char_id and g_obj_mgr:get_obj(char_id)
	local pack_con = player and player:get_pack_con()
	if not pack_con or not param_l or not param_l.slot_l then 
		return 1
	end

	local item_tmp = {}

	local slot_l = param_l.slot_l
	local item_l = {}
	local cnt = 0
	local e_code , bag = pack_con:get_bag(SYSTEM_BAG)
	if e_code ~= 0 then
		return e_code
	end

	for i = 1, table.getn(slot_l) do	
		local slot = bag:get_item_by_slot(slot_l[i])
		if pack_con:check_item_lock_by_bag_slot(SYSTEM_BAG, slot_l[i]) then return 1 end
		if not slot or not self:check_item(slot.item) then
			return 25015
		end

		cnt = slot.number + cnt
	end

	if cnt < self.collect_condition.count then return 25015 end

	local meta = misson_loader.get_meta(self.quest_id)
	if not meta then
		return E_MISSION_INVALID_ID, nil
	end
	
	self:set_status(MISSION_STATUS_FINISH)
	
	local next_quest_chain = nil
	if meta.reward then
		local e_code = self:do_reward(player, meta.reward, select_list, bonus)
		if E_SUCCESS ~= e_code then
			self:set_status(MISSION_STATUS_COMMIT)
			return e_code, nil
		end
		
		next_quest_chain = meta.reward.next_quest_chain
	end

	if E_SUCCESS == e_code then	
		cnt = self.collect_condition.count
		for i = 1, table.getn(slot_l) do	
			local slot = bag:get_item_by_slot(slot_l[i])
			if slot.number >= cnt then
				pack_con:del_item_by_bag_slot(SYSTEM_BAG, slot_l[i], cnt, {['type'] = ITEM_SOURCE.TASK})
				break
			else
				pack_con:del_item_by_bag_slot(SYSTEM_BAG, slot_l[i], slot.number, {['type'] = ITEM_SOURCE.TASK})
				cnt = cnt - slot.number
			end
		end
	end
	return e_code, next_quest_chain
end

function Quest_color_equi:update_add_item_event(con, item_id, char_id, slot)
	if not slot or not slot.item or not slot.number then
		return 
	end
	local item = slot.item
	local char_id = con:get_owner()
	local player = char_id and g_obj_mgr:get_obj(char_id)
	local pack_con = player and player:get_pack_con()
	if not pack_con then 
		return
	end
	
	if self:check_item(item) then
		self.counts = self.counts + slot.number
	end

	if self.status == MISSION_STATUS_INCOMPLETE and self.counts >= self.collect_condition.count then
		self.status = MISSION_STATUS_COMMIT
		con:notity_update_quest(self.quest_id, 1)
		return
	end
	
end

function Quest_color_equi:update_sub_item_event(con, item_id, char_id, slot)
	if not slot or not slot.item or not slot.number then
		return 
	end
	local item = slot.item
	local char_id = con:get_owner()
	local player = char_id and g_obj_mgr:get_obj(char_id)
	local pack_con = player and player:get_pack_con()
	if not pack_con then 
		return
	end
	
	if self:check_item(item) then
		self.counts = self.counts - slot.number
	end

	if self.status == MISSION_STATUS_COMMIT and self.counts < self.collect_condition.count then
		self.status = MISSION_STATUS_INCOMPLETE
		con:notity_update_quest(self.quest_id, 1)
		return
	end
	
end

function Quest_color_equi:check_item(item)
	local req_lvl = item:get_req_lvl()
	if (self.collect_condition['min_level'] and (not req_lvl or self.collect_condition['min_level'] >= req_lvl) )
		or (self.collect_condition['max_level'] and (not req_lvl or self.collect_condition['max_level'] < req_lvl))	then
		return false
	end

	local req_color = item:get_color()
	if not req_color then return false end
	if self.collect_condition['color'] and self.collect_condition['color'] ~= req_color then
		return false
	end

	local req_m_class = item:get_m_class()
	if not req_m_class then return false end
	if self.collect_condition['m_class'] and self.collect_condition['m_class'] ~= req_m_class then
		return false
	end

	local req_t_class = item:get_t_class()
	if not req_t_class then return false end
	if self.collect_condition['t_class'] and self.collect_condition['t_class'] ~= req_t_class then
		return false
	end

	local req_s_class = item:get_s_class()
	if not req_s_class then return false end
	if self.collect_condition['s_class'] and self.collect_condition['s_class'] ~= req_s_class then
		return false
	end

	if not self.collect_condition.req_class then return true end
	local req_class= item:get_req_class()
	if not req_class then return false end
	for k, v in pairs(self.collect_condition.req_class) do
		if v == req_class then
			return true
		end
	end

	return false
end

Mission_mgr.register_class(MISSION_FLAG_COLOR_EQUI, Quest_color_equi)