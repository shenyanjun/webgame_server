
local misson_loader = require("mission_ex.mission_loader")

--Õ½³¡Ð­ÖúÖú¹¥
local Quest_assist_attack = oo.class(Quest_base, "Quest_assist_attack")

function Quest_assist_attack:__init(meta)
	Quest_base.__init(self, meta)
	self.assist_attack_times = 0
end

function Quest_assist_attack:register_event(con)
	assert(con)
	con:register_event(MISSION_EVENT_ASSIST_ATTACK, self.quest_id, self, self.attack_event)
	--print('Quest_assist_attack:register_event(con)')
end

function Quest_assist_attack:unregister_event(con)
	con:unregister_event(MISSION_EVENT_ASSIST_ATTACK, self.quest_id)
	--print('Quest_assist_attack:unregister_event(con)')
end

function Quest_assist_attack:load_fields(record)
	local obj, e_code = Quest_base.load_fields(self, record)
	
	obj.assist_attack_times = record.assist_attack_times
	--print('Quest_assist_attack:load_fields assist_attack_times:'..obj.assist_attack_times)
	return obj, E_SUCCESS
end

function Quest_assist_attack:serialize_to_net()
	local result = Quest_base.serialize_to_net(self)
	result.num = self.assist_attack_times or 0
	return result
end

function Quest_assist_attack:serialize_to_db()
	local result = Quest_base.serialize_to_db(self)
	result.assist_attack_times = self.assist_attack_times
	return result
end

function Quest_assist_attack:attack_event(con,count)
	assert(count == 1)
	local meta = misson_loader.get_meta(self.quest_id)
	if not meta then
		return
	end
	
	local assist_attack_times = meta.postcondition and meta.postcondition.total
	if not assist_attack_times then
		return
	end

	self.assist_attack_times = self.assist_attack_times + count
	if self.assist_attack_times < assist_attack_times then
		con:notity_update_quest(self.quest_id, true)
		return 
	end
	
	self:unregister_event(con)
	self.status = MISSION_STATUS_COMMIT
	con:notity_update_quest(self.quest_id, true)
end

Mission_mgr.register_class(MISSION_FLAG_ASSIST_ATTACK, Quest_assist_attack)