
--引导完成任务 任务
local misson_loader = require("mission_ex.mission_loader")

local Quest_quest_type = oo.class(Quest_base, "Quest_quest_type")

function Quest_quest_type:__init(meta, core)
	Quest_base.__init(self, meta)
	self.quest_list = {}
end

function Quest_quest_type:register_event(con)
	con:register_event(EVENT_SET.EVENT_COMPLETE_QUEST, self.quest_id, self, self.complete_multiple_quest)
end

function Quest_quest_type:unregister_event(con)
	con:unregister_event(EVENT_SET.EVENT_COMPLETE_QUEST, self.quest_id)
end

function Quest_quest_type:load_fields(record)
	local obj, e_code = Quest_base.load_fields(self, record)
	obj.quest_list = {}
	if record.quest_list then
		for k, v in pairs(record.quest_list) do
			obj.quest_list[tonumber(k)] = v
		end
	end

	return obj, E_SUCCESS
end

function Quest_quest_type:construct(con)
	self:register_event(con)
end

function Quest_quest_type:complete_multiple_quest(con, id, char_id, type, count, flag)
	local meta = misson_loader.get_meta(self.quest_id)
	if not meta then
		return
	end
	
	local quest_list = meta.postcondition and meta.postcondition.quest_list
	if not quest_list or not type or not quest_list[type] then
		return
	end
	
	local limit_flag_list = meta.postcondition and meta.postcondition.quest_limit_flag
	if limit_flag_list and flag then
		if not limit_flag_list[flag] then
			return
		end
	end

	count = count or 1
	if not self.quest_list[type] then 
		self.quest_list[type] = count
	elseif self.quest_list[type] < quest_list[type] then
		self.quest_list[type] = self.quest_list[type] + count
	end

	--未达到条件上限
	if self.quest_list[type] < quest_list[type] then
		con:notity_update_quest(self.quest_id, true)
		return
	end

	self:unregister_event(con)
	self.status = MISSION_STATUS_COMMIT
	con:notity_update_quest(self.quest_id, true)
end

function Quest_quest_type:serialize_to_net()
	local result = Quest_base.serialize_to_net(self)
	local quest_list = {}
	result.num = 0
	for k, v in pairs(self.quest_list) do
		--local item = {}
		--table.insert(item, k)
		--table.insert(item, v)
		--table.insert(quest_list, item)
		result.num = v
	end
	return result
end

function Quest_quest_type:serialize_to_db()
	local result = Quest_base.serialize_to_db(self)

	result.quest_list = {}
	for k, v in pairs(self.quest_list) do
		result.quest_list[tostring(k)] = v
	end
	return result
end

Mission_mgr.register_class(MISSION_FLAG_QUEST_TYPE, Quest_quest_type)