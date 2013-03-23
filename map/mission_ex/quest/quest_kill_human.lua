
local misson_loader = require("mission_ex.mission_loader")

--Õ½³¡É±µÐ
local Quest_kill_human = oo.class(Quest_base, "Quest_kill_human")

function Quest_kill_human:__init(meta)
	Quest_base.__init(self, meta)
	self.kill_human_num = 0
end

function Quest_kill_human:register_event(con)
	assert(con)
	--print('Quest_kill_human:register_event')
	con:register_event(MISSION_EVENT_KILL_HUMAN, self.quest_id, self, self.kill_event)
end

function Quest_kill_human:unregister_event(con)
	con:unregister_event(MISSION_EVENT_KILL_HUMAN, self.quest_id)
end

function Quest_kill_human:load_fields(record)
	local obj, e_code = Quest_base.load_fields(self, record)
	
	obj.kill_human_num = record.kill_human_num
	--print('Quest_kill_human:load_fields , kill_human_num :'..obj.kill_human_num)
	return obj, E_SUCCESS
end

function Quest_kill_human:serialize_to_net()
	local result = Quest_base.serialize_to_net(self)
	result.num = self.kill_human_num or 0
	
	return result
end

function Quest_kill_human:serialize_to_db()
	local result = Quest_base.serialize_to_db(self)
	result.kill_human_num = self.kill_human_num
	--print('serialize_to_db****************')
	--print(j_e(result))
	return result
end

function Quest_kill_human:kill_event(con, count)
	--print('Quest_kill_human:kill_event')
	assert(count==1)
	local meta = misson_loader.get_meta(self.quest_id)
	if not meta then
		return
	end
	
	local kill_human_num = meta.postcondition and meta.postcondition.total
	if not kill_human_num then
		return
	end

	self.kill_human_num = self.kill_human_num + count
	if self.kill_human_num < kill_human_num then
		con:notity_update_quest(self.quest_id, true)
		return 
	end
	
	self:unregister_event(con)
	self.status = MISSION_STATUS_COMMIT
	con:notity_update_quest(self.quest_id, true)
end

Mission_mgr.register_class(MISSION_FLAG_KILL_HUMAN, Quest_kill_human)