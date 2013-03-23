
local misson_loader = require("mission_ex.mission_loader")

--等级任务
local Quest_level = oo.class(Quest_base, "Quest_level")

function Quest_level:__init(meta)
	Quest_base.__init(self, meta)
	self.cur_level = 0
	self.complete_level = 0
end


function Quest_level:register_event(con)
	assert(con)
	con:register_event(MISSION_EVENT_LEVEL_UP, self.quest_id, self, self.level_up_event)
end


function Quest_level:instance(con)
	local meta = misson_loader.get_meta(self.quest_id)
	if not meta then
		return
	end
	
	self.complete_level = meta.postcondition and meta.postcondition.complete_level
	if not self.complete_level then
		return
	end

	local char_id = con:get_owner()
	local player = char_id and g_obj_mgr:get_obj(char_id)
	self.cur_level = player and player:get_level()
	
	if self.cur_level < self.complete_level then
		self:register_event(con)
		return
	end
	
	self.status = MISSION_STATUS_COMMIT
end

function Quest_level:construct(con)
	--if MISSION_STATUS_COMMIT ~= self.status then
	local meta = misson_loader.get_meta(self.quest_id)
	if meta then
		self.complete_level = meta.postcondition and meta.postcondition.complete_level
	
		local char_id = con:get_owner()
		local player = char_id and g_obj_mgr:get_obj(char_id)
		self.cur_level = player and player:get_level()
	end
	if MISSION_STATUS_COMMIT ~= self.status then
		self:register_event(con)
	end
end

function Quest_level:unregister_event(con)
	con:unregister_event(MISSION_EVENT_LEVEL_UP, self.quest_id)
end

function Quest_level:serialize_to_net()
	local result = Quest_base.serialize_to_net(self)
	result.level = {self.cur_level or 0, self.complete_level or 0}
	return result
end

function Quest_level:level_up_event(con, level)
	local meta = misson_loader.get_meta(self.quest_id)
	if not meta then
		return
	end
	
	local complete_level = meta.postcondition and meta.postcondition.complete_level
--[[	
	local char_id = con:get_owner()
	local player = char_id and g_obj_mgr:get_obj(char_id)
	local level = player and player:get_level()
]]	
	if not level or not complete_level then
		return
	end
	
	self.complete_level = complete_level
	self.cur_level = level
	
	if level < complete_level then
		con:notity_update_quest(self.quest_id, false)
		return
	end
	
	self:unregister_event(con)
	self.status = MISSION_STATUS_COMMIT
	con:notity_update_quest(self.quest_id, true)
end

Mission_mgr.register_class(MISSION_FLAG_LEVEL_FINISH, Quest_level)