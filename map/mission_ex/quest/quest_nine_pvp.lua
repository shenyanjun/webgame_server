local misson_loader = require("mission_ex.mission_loader")

local Quest_nine_pvp = oo.class(Quest_base, "Quest_nine_pvp")

function Quest_nine_pvp:__init(meta, core)
	Quest_base.__init(self, meta)
	self.kill_monster = {}
	self.drop_id = 0
end

function Quest_nine_pvp:register_event(con)
	assert(con)
	con:register_event(EVENT_SET.EVENT_NINE_PVP_DIE, self.quest_id, self, self.nine_pvp_die)
	con:register_event(EVENT_SET.EVENT_NINE_PVP_COLL, self.quest_id, self, self.nine_pvp_coll)
end

function Quest_nine_pvp:unregister_event(con)
	assert(con)
	con:unregister_event(EVENT_SET.EVENT_NINE_PVP_DIE, self.quest_id, self, self.nine_pvp_die)
	con:unregister_event(EVENT_SET.EVENT_NINE_PVP_COLL, self.quest_id, self, self.nine_pvp_coll)
end

function Quest_nine_pvp:load_fields(record)
	local obj, e_code = Quest_base.load_fields(self, record)
	
	obj.kill_monster = {}
	obj.drop_id = 0
	if record.kill_monster then
		for k, v in pairs(record.kill_monster) do
			obj.kill_monster[tonumber(k)] = v
			obj.drop_id = tonumber(k)
		end
	end
	if obj.drop_id == 0 then 
		local meta = misson_loader.get_meta(record.quest_id)
		if not meta then return end
		local monster_list = meta.postcondition and meta.postcondition.monster_list
		if not monster_list then return end
		for i,v in pairs(monster_list) do
			obj.drop_id = tonumber(i)
		end
	end
	return obj, E_SUCCESS
end

function Quest_nine_pvp:construct(con)
	self:register_event(con)
end

function Quest_nine_pvp:serialize_to_net()
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

function Quest_nine_pvp:serialize_to_db()
	local result = Quest_base.serialize_to_db(self)
	result.kill_monster = {}
	for k, v in pairs(self.kill_monster) do
		result.kill_monster[tostring(k)] = v
	end
	return result
end

function Quest_nine_pvp:nine_pvp_coll(con, monster_id)
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
	end
	--未达到条件上限
	if self.kill_monster[monster_id] < monster_list[monster_id].number then
		con:notity_update_quest(self.quest_id, true)
		return
	end

	if self.status == MISSION_STATUS_COMMIT then return end
	--self:unregister_event(con)	
	self.status = MISSION_STATUS_COMMIT
	con:notity_update_quest(self.quest_id, true)
end

function Quest_nine_pvp:nine_pvp_die(con, killer_id, kill_num)

	if not killer_id then return end

	local meta = misson_loader.get_meta(self.quest_id)
	if not meta then
		return
	end
	local monster_list = meta.postcondition and meta.postcondition.monster_list
	if not monster_list or not monster_list[self.drop_id]then
		return
	end
	if not self.kill_monster[self.drop_id] then
		return
	elseif self.kill_monster[self.drop_id] <= 0 then
		return
	else
		self.kill_monster[self.drop_id] = self.kill_monster[self.drop_id] - kill_num		
	end

	if killer_id and kill_num == 1 then
		local args = {}
		args.collect_id = self.drop_id
		g_event_mgr:notify_event(EVENT_SET.EVENT_NINE_PVP_COLL, killer_id, args)
	end
	if self.kill_monster[self.drop_id] < monster_list[self.drop_id].number then
		self.status = MISSION_STATUS_INCOMPLETE
		con:notity_update_quest(self.quest_id, true)
		return
	end
end

Mission_mgr.register_class(MISSION_FLAG_NINE_PVP, Quest_nine_pvp)