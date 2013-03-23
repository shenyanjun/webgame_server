--与其叫special还不如叫surprise
--会不断给开发惊喜的任务
local special_quest_class = {}

-------------------------------------------客户端通知完成类任务----------------------------------------------------------
local Quest_client = oo.class(Quest_base, "Quest_client")
--special_quest_class["BRANCH_0008"] = Quest_client

function Quest_client:register_event(con)
	assert(con)
	con:register_event(MISSION_EVENT_CLIENT, self.quest_id, self, self.client_event)
end

function Quest_client:unregister_event(con)
	con:unregister_event(MISSION_EVENT_CLIENT, self.quest_id)
end

function Quest_client:client_event(con)
	self:set_status(MISSION_STATUS_COMMIT)
	self:unregister_event(con)
	con:notity_update_quest(self.quest_id, true)
end

---------------------------------------------加入帮派任务-------------------------------------------

local Quest_faction = oo.class(Quest_client, "Quest_faction")
special_quest_class["MAIN_0128"] = Quest_faction

function Quest_faction:register_event(con)
	assert(con)
	con:register_event(MISSION_EVENT_FACTION, self.quest_id, self, self.add_faction_event)
	con:register_event(MISSION_EVENT_CLIENT, self.quest_id, self, self.client_event)
end

function Quest_faction:instance(con)
	local char_id = con:get_owner()
	local player = char_id and g_obj_mgr:get_obj(char_id)
	if not player then
		return
	end
	
	if not player:get_faction_id() then
		self:register_event(con)
	else
		self.status = MISSION_STATUS_COMMIT
	end
end


function Quest_faction:unregister_event(con)
	con:unregister_event(MISSION_EVENT_FACTION, self.quest_id)
	con:unregister_event(MISSION_EVENT_CLIENT, self.quest_id)
end

function Quest_faction:add_faction_event(con)
	local char_id = con:get_owner()
	local player = char_id and g_obj_mgr:get_obj(char_id)
	if not player then 
		return
	end

	if not player:get_faction_id() then
		return
	end
	
	self.status = MISSION_STATUS_COMMIT
	self:unregister_event(con)
	con:notity_update_quest(self.quest_id, true)
end

---------------------------------------------------------------------------------------------------------------------

local function build_special_quest(meta)
	local quest_id = meta and meta.id
	if not quest_id then
		return nil
	end
	local class = special_quest_class[quest_id]
	return class and class(meta) or Quest_client(meta)
end

Mission_mgr.register_class(MISSION_FLAG_SPECIAL, build_special_quest)