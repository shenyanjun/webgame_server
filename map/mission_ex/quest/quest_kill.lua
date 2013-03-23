
local misson_loader = require("mission_ex.mission_loader")

--杀怪任务
local Quest_kill = oo.class(Quest_base, "Quest_kill")

function Quest_kill:__init(meta)
	Quest_base.__init(self, meta)
	self.kill_monster = {}
end

function Quest_kill:register_event(con)
	assert(con)
	con:register_event(MISSION_EVENT_KILL, self.quest_id, self, self.kill_event)
end

function Quest_kill:unregister_event(con)
	con:unregister_event(MISSION_EVENT_KILL, self.quest_id)
end

function Quest_kill:load_fields(record)
	local obj, e_code = Quest_base.load_fields(self, record)
	
	obj.kill_monster = {}
	if record.kill_monster then
		for k, v in pairs(record.kill_monster) do
			obj.kill_monster[tonumber(k)] = v
		end
	end

	--self:unregister_event(con)
	--self.status = MISSION_STATUS_COMMIT

	return obj, E_SUCCESS
end

function Quest_kill:serialize_to_net()
	local result = Quest_base.serialize_to_net(self)
	local kill_monster = {}
	for k, v in pairs(self.kill_monster) do
		local item = {}
		table.insert(item, k)
		table.insert(item, v)
		table.insert(kill_monster, item)
	end
	result.kill_monster = kill_monster
	return result
end

function Quest_kill:serialize_to_db()
	local result = Quest_base.serialize_to_db(self)
	result.kill_monster = {}
	for k, v in pairs(self.kill_monster) do
		result.kill_monster[tostring(k)] = v
	end
	return result
end

function Quest_kill:kill_event(con, monster_id)
	local meta = misson_loader.get_meta(self.quest_id)
	if not meta then
		return
	end
	
	local monster_list = meta.postcondition and meta.postcondition.monster_list
	if not monster_list or not monster_id or not monster_list[monster_id]then
		return
	end

	if not self.kill_monster[monster_id] then
		self.kill_monster[monster_id] = 1
	elseif self.kill_monster[monster_id] < monster_list[monster_id].number then
		self.kill_monster[monster_id] = self.kill_monster[monster_id] + 1 
	--else
		--之前已经达到目标上限
		--return
	end
	
	--未达到条件上限
	if self.kill_monster[monster_id] < monster_list[monster_id].number then
		con:notity_update_quest(self.quest_id, true)
		return
	end
	
	--检查是否全部完成
	for k, v in pairs(monster_list) do
		if not self.kill_monster[k] or self.kill_monster[k] < v.number then
			--没有全部完成则通知更新并返回
			con:notity_update_quest(self.quest_id, true)
			return
		end
	end
	
	self:unregister_event(con)
	self.status = MISSION_STATUS_COMMIT
	con:notity_update_quest(self.quest_id, true)
end

Mission_mgr.register_class(MISSION_FLAG_KILL, Quest_kill)