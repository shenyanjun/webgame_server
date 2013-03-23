
local misson_loader = require("mission_ex.mission_loader")

--战场上缴资源
local Quest_over_resources = oo.class(Quest_base, "Quest_over_resources")

function Quest_over_resources:__init(meta)
	Quest_base.__init(self, meta)
	self.resources_times = 0
end

function Quest_over_resources:register_event(con)
	assert(con)
	con:register_event(MISSION_EVENT_OVER_RESOURCES, self.quest_id, self, self.over_resources_event)
	--print('Quest_over_resources:register_event(con)')
end

function Quest_over_resources:unregister_event(con)
	con:unregister_event(MISSION_EVENT_OVER_RESOURCES, self.quest_id)
	--print('Quest_over_resources:unregister_event(con)')
end

function Quest_over_resources:load_fields(record)
	local obj, e_code = Quest_base.load_fields(self, record)
	
	obj.resources_times = record.resources_times
	
	return obj, E_SUCCESS
end

function Quest_over_resources:serialize_to_net()
	local result = Quest_base.serialize_to_net(self)
	result.num = self.resources_times or 0
	return result
end

function Quest_over_resources:serialize_to_db()
	local result = Quest_base.serialize_to_db(self)
	result.resources_times = self.resources_times
	--print('Quest_over_resources:serialize_to_db() resources_times : '..self.resources_times)
	return result
end

function Quest_over_resources:over_resources_event(con,item_id,item_cnt)
	--print('Quest_over_resources:over_resources_event(con,item_id,item_cnt)')
	assert(item_cnt == 1)
	local meta = misson_loader.get_meta(self.quest_id)
	if not meta then
		return
	end
	
	local resources_times = meta.postcondition and meta.postcondition.total
	--print('total'..meta.postcondition.total)
	if not resources_times then
		return
	end

	self.resources_times = self.resources_times + item_cnt
	--print(self.resources_times)
	if self.resources_times < resources_times then
		con:notity_update_quest(self.quest_id, true)
		return 
	end
	
	self:unregister_event(con)
	self.status = MISSION_STATUS_COMMIT
	con:notity_update_quest(self.quest_id, true)
end

Mission_mgr.register_class(MISSION_FLAG_OVER_RESOURCES, Quest_over_resources)