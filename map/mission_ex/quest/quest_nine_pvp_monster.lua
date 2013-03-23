
local misson_loader = require("mission_ex.mission_loader")

local Quest_nine_pvp_monster = oo.class(Quest_base, "Quest_nine_pvp_monster")

function Quest_nine_pvp_monster:__init(meta)
	Quest_base.__init(self, meta)
	self.kill_monster = {}
	self.mon_list = {}
end

function Quest_nine_pvp_monster:register_event(con)
	assert(con)
	con:register_event(EVENT_SET.EVENT_NINE_PVP_COLL, self.quest_id, self, self.kill_event)
end

function Quest_nine_pvp_monster:unregister_event(con)
	con:unregister_event(EVENT_SET.EVENT_NINE_PVP_COLL, self.quest_id)
end

function Quest_nine_pvp_monster:load_fields(record)
	local obj, e_code = Quest_base.load_fields(self, record)
	
	obj.kill_monster = {}
	obj.mon_list = {}
	if record.kill_monster then
		for k, v in pairs(record.kill_monster) do
			obj.kill_monster[tonumber(k)] = v
		end
	end
	local meta = misson_loader.get_meta(record.quest_id)
	if not meta then return end
	local monster_list = meta.postcondition and meta.postcondition.monster_list
	if not monster_list then return end
	for i,v in pairs(monster_list) do
		obj.mon_list[tonumber(i)] = 0
	end
	
	return obj, E_SUCCESS
end

function Quest_nine_pvp_monster:serialize_to_net()
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

function Quest_nine_pvp_monster:serialize_to_db()
	local result = Quest_base.serialize_to_db(self)
	result.kill_monster = {}
	for k, v in pairs(self.kill_monster) do
		result.kill_monster[tostring(k)] = v
	end
	return result
end


function Quest_nine_pvp_monster:check_complete(monster_list)
	for i,v in pairs(monster_list) do
		if not self.kill_monster[i] then
			return false
		end
		if v.number > self.kill_monster[i] then
			return false
		end
	end
	return true
end

function Quest_nine_pvp_monster:kill_event(con, monster_id)
	
	local meta = misson_loader.get_meta(self.quest_id)
	if not meta then
		return
	end

	local monster_list = meta.postcondition and meta.postcondition.monster_list

	if not monster_list or not monster_id then
		return
	end
	if not monster_list[monster_id] then 
		local t_monster_id
		for i,v in pairs(self.mon_list) do
			t_monster_id = meta.postcondition.option_kill_monster[self.quest_id][tonumber(i)]	
			if t_monster_id then t_monster_id = t_monster_id[monster_id] end
			if t_monster_id then monster_id = i break end			 
		end		
		if not t_monster_id then return end
	end

	if not self.kill_monster[monster_id] then
		self.kill_monster[monster_id] = 1
	elseif self.kill_monster[monster_id] < monster_list[monster_id].number then
		self.kill_monster[monster_id] = self.kill_monster[monster_id] + 1 
	end

	--未达到条件上限
	if self.kill_monster[monster_id] < monster_list[monster_id].number then
		con:notity_update_quest(self.quest_id, true)
		return
	end

	if not self:check_complete(monster_list) then  -- 检查所有所有任务都完成
		con:notity_update_quest(self.quest_id, true)
		return 
	end
	self:unregister_event(con)
	self.status = MISSION_STATUS_COMMIT
	con:notity_update_quest(self.quest_id, true)
end

Mission_mgr.register_class(MISSION_FLAG_NINE_PVP_MONSTER, Quest_nine_pvp_monster)