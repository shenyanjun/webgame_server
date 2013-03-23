
local misson_loader = require("mission_ex.mission_loader")

--场景 计数任务
local Quest_count = oo.class(Quest_base, "Quest_count")

function Quest_count:__init(meta)
	Quest_base.__init(self, meta)
	self.count = 0
end

function Quest_count:register_event(con)
	con:register_event(EVENT_SET.EVENT_ENTER_COPY, self.quest_id, self, self.count_event)
end

function Quest_count:unregister_event(con)
	con:unregister_event(EVENT_SET.EVENT_ENTER_COPY, self, self.quest_id)
end

function Quest_count:load_fields(record)
	local obj, e_code = Quest_base.load_fields(self, record)
	obj.count = record.count or 0
	return obj, E_SUCCESS
end

function Quest_count:serialize_to_net()
	local result = Quest_base.serialize_to_net(self)
	result.num = self.count or 0
	return result
end

function Quest_count:serialize_to_db()
	local result = Quest_base.serialize_to_db(self)
	result.count = self.count
	return result

end

function Quest_count:count_event(con, scene_id)
	local meta = misson_loader.get_meta(self.quest_id)
	if not meta then
		return
	end
	
	local t_count = meta.postcondition.count_scene[scene_id]
	if not t_count then
		return
	end
	
	if self.count < t_count then
		self.count = self.count + 1 
	end
	
	--未达到条件上限
	if self.count < t_count then
		con:notity_update_quest(self.quest_id, true)
		return
	end	
	
	self:unregister_event(con)
	self.status = MISSION_STATUS_COMMIT
	con:notity_update_quest(self.quest_id, true)
end

Mission_mgr.register_class(MISSION_FLAG_COUNT, Quest_count)