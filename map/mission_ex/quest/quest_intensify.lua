
local misson_loader = require("mission_ex.mission_loader")

--强化任务
local Quest_intensify = oo.class(Quest_base, "Quest_intensify")

function Quest_intensify:instance(con)
	local meta = misson_loader.get_meta(self.quest_id)
	if not meta then
		return
	end
	
	local intensify_item = meta.postcondition and meta.postcondition.intensify_item
	if not intensify_item then
		return
	end
	
	local class = intensify_item.class or 0
	local level = intensify_item.level
	if not level then
		return
	end
	
	local char_id = con:get_owner()
	local player = char_id and g_obj_mgr:get_obj(char_id)
	local pack_con = player and player:get_pack_con()
	if not pack_con then 
		return
	end
	
	local item_list = pack_con:get_all_item_by_m_class({EQUIPMENT_BAG, SYSTEM_BAG}, ItemClass.ITEM_CLASS_EQUIP)

	local ok = false
	for k, v in pairs(item_list or {}) do
		if (0 == class or class == v.item:get_t_class()) and (v.item.rank and level <= v.item.rank) then
			ok = true
			break
		end
	end
	
	if not ok then
		self:register_event(con)
		self.status = MISSION_STATUS_INCOMPLETE
	else
		self.status = MISSION_STATUS_COMMIT
	end
end

function Quest_intensify:register_event(con)
	assert(con)
	con:register_event(MISSION_EVENT_INTENSIFY, self.quest_id, self, self.intensify_event)
end

function Quest_intensify:unregister_event(con)
	con:unregister_event(MISSION_EVENT_INTENSIFY, self.quest_id)
end

function Quest_intensify:intensify_event(con, class, lv)
	local meta = misson_loader.get_meta(self.quest_id)
	if not meta then
		return
	end
	
	if not class or not lv then
		return
	end
	
	local intensify_item = meta.postcondition and meta.postcondition.intensify_item
	if not intensify_item then
		return
	end
	
	if intensify_item.class and 0 ~= intensify_item.class and class ~= intensify_item.class then
		return
	end
	
	if not intensify_item.level or lv < intensify_item.level then
		return
	end
	
	self.status = MISSION_STATUS_COMMIT
	self:unregister_event(con)
	con:notity_update_quest(self.quest_id, true)
end

Mission_mgr.register_class(MISSION_FLAG_INTENSIFY, Quest_intensify)