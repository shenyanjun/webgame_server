
local misson_loader = require("mission_ex.mission_loader")

--使用物品任务，包括穿装备等
local Quest_use_item = oo.class(Quest_base, "Quest_use_item")

function Quest_use_item:__init(meta)
	Quest_base.__init(self, meta)
	self.use_item_list = {}
end

function Quest_use_item:register_event(con)
	assert(con)
	con:register_event(MISSION_EVENT_USE_ITEM, self.quest_id, self, self.use_item_event)
end

function Quest_use_item:unregister_event(con)
	con:unregister_event(MISSION_EVENT_USE_ITEM, self.quest_id)
end

function Quest_use_item:use_item_event(con, item)
	local meta = misson_loader.get_meta(self.quest_id)
	if not meta then
		return
	end
	
	local item_id = item:get_item_id()

	local item_list = meta.postcondition and meta.postcondition.trigger_list
	if not item_list or not item_id or not item_list[item_id] then
		return
	end

	self.use_item_list[item_id] = (self.use_item_list[item_id] or 0) + 1 
	
	for k, v in pairs(item_list) do
		if self.use_item_list[k] then
			self:unregister_event(con)
			self.status = MISSION_STATUS_COMMIT
			con:notity_update_quest(self.quest_id, true)
			return
		end
	end
end

function Quest_use_item:load_fields(record)
	local obj, e_code = Quest_base.load_fields(self, record)
	if record.use_item_list then
		obj.use_item_list = table.copy(record.use_item_list)
	else
		obj.use_item_list = {}
	end
	return obj, E_SUCCESS
end

function Quest_use_item:serialize_to_db()
	local result = Quest_base.serialize_to_db(self)
	result.use_item_list = {}
	for k, v in pairs(self.use_item_list) do
		result.use_item_list[tostring(k)] = v
	end
	return result
end

Mission_mgr.register_class(MISSION_FLAG_USE_ITEM, Quest_use_item)