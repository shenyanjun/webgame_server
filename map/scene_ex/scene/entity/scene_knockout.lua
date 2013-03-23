local config = require("config.world_war.config_loader")

Scene_knockout = oo.class(Scene_qualify, "Scene_knockout")

function Scene_knockout:__init(map_id, instance_id, map_obj, entry, first_id, second_id)
	Scene_qualify.__init(self, map_id, instance_id, map_obj, entry, first_id, second_id)
	self.win_side = 1
	self.wait_relive = {}
	self.relive_count = {}
	
	self.first_relive = 0
	self.second_relive = 0
end

function Scene_knockout:get_config()
	return config.config.knockout
end

function Scene_knockout:adjudge()
	if not self.lost_team and self.score[1] ~= self.score[2] then
		if self.score[1] > self.score[2] then
			return 1
		else
			return 2
		end
	elseif self.first_id == self.lost_team then
		return 2
	elseif self.second_id == self.lost_team then
		return 1
	end
	
	if self.first_relive == self.second_relive then
		return math.random(1, 2)
	elseif self.first_relive < self.second_relive then
		return 1
	end
	
	return 2
end

function Scene_knockout:get_win()
	return self.win_side
end

function Scene_knockout:do_reward()
	self.win_side = self:adjudge()
	
	local first_cache = self.entry.team_cache:get_cache(self.first_id)
	local second_cache = self.entry.team_cache:get_cache(self.second_id)
	
	local pkt = {}
	pkt.type = 1
	pkt.wait = math.max(self.close_time - ev.time, 0)
	pkt.left = {first_cache.name, (1 == self.win_side) and 1 or -1, self.score[1]}
	pkt.right = {second_cache.name, (2 == self.win_side) and 1 or -1, self.score[2]}
	local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
	if con then
		for obj_id, _ in pairs(con:get_obj_list()) do
			g_cltsock_mgr:send_client(obj_id, CMD_MAP_WORLD_WAR_RESULT_S, pkt)
		end
	end
end

function Scene_knockout:notify_change()
	local config = self:get_config()
	if config.game.relive then
		local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
		for obj_id, _ in pairs(con:get_obj_list()) do
			local self_team = self.owner_list[obj_id]
			local rival_team = (self_team == self.first_id) and self.second_id or self.first_id 
			
			local pkt = {}
			pkt.type = 5
			pkt.relive = {{}, {}}
			
			for obj_id, name in pairs(self.team_member_list[self_team]) do
				table.insert(
					pkt.relive[1]
					, {name, math.max(config.game.relive.count - (self.relive_count[obj_id] or 0), 0)})
			end
			
			for obj_id, name in pairs(self.team_member_list[rival_team]) do
				table.insert(
					pkt.relive[2]
					, {name, math.max(config.game.relive.count - (self.relive_count[obj_id] or 0), 0)})
			end

			g_cltsock_mgr:send_client(obj_id, CMD_MAP_WORLD_WAR_STATE_S, pkt)
		end
	end
end

function Scene_knockout:on_obj_enter(obj)
	Scene_qualify.on_obj_enter(self, obj)

	if self.status == SCENE_STATUS.OPEN then
		self:notify_change()
	end
end

function Scene_knockout:relive_human(obj)
	if obj:is_alive() then
		return
	end
	
	obj:do_relive(1, true)	--复活
	obj:send_relive(3)
	
	local obj_id = obj:get_id()
	self.relive_count[obj_id] = (self.relive_count[obj_id] or 0) + 1
	local config = self:get_config()
	local entry_list = config.game.relive and config.game.relive.entry
	if entry_list and #entry_list > 0 then
		local i = math.random(1, #entry_list)
		local pos = entry_list[i]
		self:transport(obj, pos)
	end
	
	local team_id = self.owner_list[obj_id]
	if team_id == self.first_id then
		self.first_relive = self.first_relive + 1
	else
		self.second_relive = self.second_relive + 1
	end
	self:notify_change()
end

function Scene_knockout:on_timer(tm)
	Scene_qualify.on_timer(self, tm)
	
	local now_time = ev.time
	local obj_mgr = g_obj_mgr
	for char_id, time in pairs(self.wait_relive) do
		if time < now_time then
			self.wait_relive[char_id] = nil
			local obj = obj_mgr:get_obj(char_id)
			if obj then
				self:relive_human(obj)
			end
		end
	end
end

function Scene_knockout:die_event(args)
	local killer_id = args.killer_id
	local obj_id = args.char_id
	local obj = self:get_obj(obj_id)
	if obj then
		local rc = self.relive_count[obj_id] or 0
		local config = self:get_config()
		if config.game.relive and rc < config.game.relive.count then
			args.mode = 1
			args.is_notify = false
			args.is_evil = false
			args.relive_time = config.game.relive.interval
			
			self.wait_relive[obj_id] = ev.time + config.game.relive.interval			--加入等待复活列表
		else
			args.mode = 2
			args.is_notify = false
			args.is_evil = false
			args.relive_time = 5
		end
	
		local killer = self:get_obj(killer_id)
		if killer then
			local team_id = self.owner_list[killer_id]
			if team_id == self.first_id then
				self.score[1] = self.score[1] + 1
			elseif team_id == self.second_id then
				self.score[2] = self.score[2] + 1
			end
		end
		
		local obj_team_id = self.owner_list[obj_id]
		local has_alive = false
		for obj_id, _ in pairs(self.team_member_list[obj_team_id]) do
			local obj = self:get_obj(obj_id)
			if obj and obj:is_alive() then
				has_alive = true
				break
			end
			
			local rc = self.relive_count[obj_id] or 0
			if config.game.relive and rc < config.game.relive.count then
				has_alive = true
				break
			end
		end
		
		if not has_alive then
			self.lost_team = obj_team_id
		end
	end
end