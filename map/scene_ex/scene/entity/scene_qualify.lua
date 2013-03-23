local config = require("config.world_war.config_loader")

Scene_qualify = oo.class(Scene_entity, "Scene_qualify")

function Scene_qualify:__init(map_id, instance_id, map_obj, entry, first_id, second_id)
	Scene_entity.__init(self, map_id, map_obj)
	self.entry = entry
	self.instance_id = instance_id
	self.entry_id = entry:get_id()
	self.key = {self.entry_id, instance_id, map_id}
	self.first_id = first_id
	self.first_count = 0
	self.second_id = second_id
	self.second_count = 0
	
	self.end_time = 0
	self.idle_time = 0

	self.score = {0, 0}
	
	self.status = SCENE_STATUS.IDLE
	
	self.owner_list = {}
	self.team_member_list = {}
	self.team_member_list[self.first_id] = {}
	self.team_member_list[self.second_id] = {}
end

function Scene_qualify:get_config()
	return config.config.qualify
end

function Scene_qualify:instance()
	self.end_time = ev.time + self:get_config().game.time
	self.idle_time = ev.time + self:get_config().game.idle
	self.status = SCENE_STATUS.IDLE
end

function Scene_qualify:carry_scene(obj, pos)
	local team_id = obj:get_team()
	if self.first_id == team_id then
		obj:set_side(1)
		pos = self:get_config().game.entry.blue
	elseif self.second_id == team_id then
		obj:set_side(2)
		pos = self:get_config().game.entry.red
	end
	local obj_id = obj:get_id()
	self.owner_list[obj_id] = team_id

	return self:push_scene(obj, pos)
end

function Scene_qualify:notify_change()
end

function Scene_qualify:on_timer(tm)
	local now_time = ev.time
	
	if SCENE_STATUS.OPEN == self.status then
		if self.lost_team or self.end_time < now_time then
			self.status = SCENE_STATUS.FREEZE
			self.close_time = ev.time + self:get_config().game.wait
			self:do_reward()
		end
	elseif SCENE_STATUS.IDLE == self.status then
		if self.lost_team then
			self.status = SCENE_STATUS.FREEZE
			self.close_time = ev.time + self:get_config().game.wait
			self:do_reward()
		elseif self.idle_time < now_time then
			self.status = SCENE_STATUS.OPEN
			self:notify_change()
			if self.first_count < 1 then
				self.lost_team = self.first_id
			elseif self.second_count < 1 then
				self.lost_team = self.second_id
			end
		end
	elseif SCENE_STATUS.FREEZE == self.status then
		if self.close_time < now_time then
			self.status = SCENE_STATUS.CLOSE
			self:close()	
		end
	end

	self.obj_mgr:on_timer(tm)
end

function Scene_qualify:adjudge()
	if not self.lost_team and self.score[1] ~= self.score[2] then
		if self.score[1] > self.score[2] then
			return {3, 0}, self.first_id
		else
			return {0, 3}, self.second_id
		end
	elseif self.first_id == self.lost_team then
		return {0, 3}, self.second_id
	elseif self.second_id == self.lost_team then
		return {3, 0}, self.first_id
	end
	
	return {1, 1}, nil
end

function Scene_qualify:do_reward()
	local score, team_id = self:adjudge()
	local result = {}
	result.winner = team_id
	result.score = {}
	result.score[self.first_id] = score[1]
	result.score[self.second_id] = score[2]
	g_svsock_mgr:send_server_ex(WORLD_ID, 0, CMD_C2W_QUALIFY_RESULT_C, result)
	
	local first_cache = self.entry.team_cache:get_cache(self.first_id)
	local second_cache = self.entry.team_cache:get_cache(self.second_id)
	
	local pkt = {}
	pkt.type = 1
	pkt.wait = math.max(self.close_time - ev.time, 0)
	pkt.left = {first_cache.name, team_id and (team_id == self.first_id and 1 or -1) or 0, score[1]}
	pkt.right = {second_cache.name, team_id and (team_id == self.second_id and 1 or -1) or 0, score[2]}
	local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
	if con then
		for obj_id, _ in pairs(con:get_obj_list()) do
			--print(obj_id, Json.Encode(pkt))
			g_cltsock_mgr:send_client(obj_id, CMD_MAP_WORLD_WAR_RESULT_S, pkt)
		end
	end
end

function Scene_qualify:get_mode()
	if SCENE_STATUS.OPEN == self.status then
		return SCENE_MODE.KILL
	end
	return SCENE_MODE.PEACE
end

function Scene_qualify:get_last_time(obj)
	return math.max(self.end_time - ev.time, 0)
end

function Scene_qualify:on_obj_enter(obj)
	if obj:get_type() == OBJ_TYPE_HUMAN then
		obj:do_relive(1, true)
		if not obj:is_alive() then
			obj:send_relive(3)	--复活
		end
	
		local obj_id = obj:get_id()
		
		g_scene_mgr_ex:register_event(EVENT_SET.EVENT_DEL_TEAM, obj_id, self, self.del_team_event)
		
		local team_id = self.owner_list[obj_id]
		self.team_member_list[team_id][obj_id] = obj:get_name()
		
		if team_id == self.first_id then
			self.first_count = self.first_count + 1
			obj:set_side(1)
		elseif team_id == self.second_id then
			self.second_count = self.second_count + 1
			obj:set_side(2)
		end
		
		if SCENE_STATUS.IDLE == self.status and self.idle_time > ev.time then
			local pkt = {}
			pkt.type = 4
			pkt.wait = self.idle_time - ev.time
			g_cltsock_mgr:send_client(obj_id, CMD_MAP_WORLD_WAR_STATE_S, pkt)
		end
	end
end

function Scene_qualify:on_obj_leave(obj)
	if obj:get_type() == OBJ_TYPE_HUMAN then
		local obj_id = obj:get_id()
		
		g_scene_mgr_ex:unregister_event(EVENT_SET.EVENT_DEL_TEAM, obj_id)
		
		local team_id = self.owner_list[obj_id]
		local team_obj = g_team_mgr:get_team_obj(team_id)
		if team_obj then
			team_obj:del_obj(obj_id)
			g_team_mgr:del_char_id(obj_id)
			team_obj:syn()
			obj:set_team(nil)
			g_cltsock_mgr:send_client(obj_id, CMD_MAP_TEAM_LEAVE_SYN_S, {})
		end
		
		self.team_member_list[team_id][obj_id] = nil
		
		if team_id == self.first_id then
			if self.first_count > 1 then
				self.first_count = self.first_count - 1
			else
				self.lost_team = team_id
			end
		elseif team_id == self.second_id then
			if self.second_count > 1 then
				self.second_count = self.second_count - 1
			else
				self.lost_team = team_id
			end
		end
		
		obj:set_side(0)
	end
end

function Scene_qualify:del_team_event(team_id, char_id)
	if char_id then
		self:kickout(char_id)
	end
end

function Scene_qualify:die_event(args)
	local killer_id = args.killer_id
	local obj_id = args.char_id
	local obj = self:get_obj(obj_id)
	if obj then
		args.mode = 2
		args.is_notify = false
		args.is_evil = false
		args.relive_time = 10
	
		local killer = self:get_obj(killer_id)
		if killer then
			local team_id = self.owner_list[killer_id]
			if team_id == self.first_id then
				self.score[1] = self.score[1] + 1
			elseif team_id == self.second_id then
				self.score[2] = self.score[2] + 1
			end
			
			local obj_team_id = self.owner_list[obj_id]
			local has_alive = false
			for obj_id, _ in pairs(self.team_member_list[obj_team_id]) do
				local obj = self:get_obj(obj_id)
				if obj and obj:is_alive() then
					has_alive = true
					break
				end
			end
			
			if not has_alive then
				self.lost_team = obj_team_id
			end
			
			--table.print(self.score)
		end
	end
end

--副本出口
function Scene_qualify:get_home_carry(obj)
	local pos = config.config.ground[self.entry_id].entry
	if not pos then
		return nil, nil
	end
	return self.entry_id, pos
end

function Scene_qualify:kickout(obj_id)
	local obj = self:get_obj(obj_id)
	if not obj and self:is_door(obj_id) then
		obj = g_obj_mgr:get_obj(obj_id)
	end
	
	if obj then
		if not obj:is_alive() then
			obj:do_relive(1, true)	--复活
			obj:send_relive(3)
		end
		
		local scene_id, pos = self:get_home_carry(obj)
		g_scene_mgr_ex:push_scene(scene_id, pos, obj)
	end
end

function Scene_qualify:clean_scene_obj()
	if self.obj_mgr then
		local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
		if con then
			for obj_id, _ in pairs(con:get_obj_list()) do
				self:kickout(obj_id)
			end
		end
		
		local con = self.obj_mgr:get_obj_con(OBJ_TYPE_MONSTER)
		if con then
			local obj_mgr = g_obj_mgr
			for obj_id, _ in pairs(con:get_obj_list()) do
				local obj = obj_mgr:get_obj(obj_id)
				if obj then
					obj:leave()
				end
			end
		end
		
		local con = self.obj_mgr:get_obj_con(OBJ_TYPE_BOX)
		if con then
			local obj_mgr = g_obj_mgr
			for obj_id, _ in pairs(con:get_obj_list()) do
				local obj = obj_mgr:get_obj(obj_id)
				if obj and obj.leave then
					obj:leave()
				end
			end
		end
		
		local con = self.obj_mgr:get_obj_con(OBJ_TYPE_PET)
		if con then
			local obj_mgr = g_obj_mgr
			for obj_id, _ in pairs(con:get_obj_list()) do
				local obj = obj_mgr:get_obj(obj_id)
				if obj and obj.leave then
					obj:leave()
				end
			end
		end
		
		local con = self.obj_mgr:get_obj_con(OBJ_TYPE_NPC)
		if con then
			local obj_mgr = g_obj_mgr
			for obj_id, _ in pairs(con:get_obj_list()) do
				local obj = obj_mgr:get_obj(obj_id)
				if obj and obj.leave then
					obj:leave()
				end
			end
		end
	end
	
	if self.door_obj_mgr then
		for obj_id, _ in pairs(self.door_obj_mgr:get_obj_list()) do
			self:kickout(obj_id)
		end
	end
end

function Scene_qualify:close()
	if self.instance_id then
		local instance_id = self.instance_id
		self.instance_id = nil
		
		self:clean_scene_obj()
		g_scene_mgr_ex:unregister_instance(instance_id)
		
		local team_obj = g_team_mgr:get_team_obj(self.first_id)
		g_team_mgr:del_team(self.first_id)
		if team_obj then
			team_obj:remove()
		end
		
		team_obj = g_team_mgr:get_team_obj(self.second_id)
		g_team_mgr:del_team(self.second_id)
		if team_obj then
			team_obj:remove()
		end
	end
end