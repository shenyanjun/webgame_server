local invasion_config = require("scene_ex.config.invasion_config_loader")

Scene_invasion = oo.class(Scene_instance, "Scene_invasion")
function Scene_invasion:__init(map_id, instance_id, map_obj)
	Scene_instance.__init(self, map_id, instance_id, map_obj)
	
	self.human_count = 0
	self.sequence = 0
	self.next_time = ev.time
	self.is_success = false
	self.area_list = {}
	self.area_monster = {}
	self.score_list = {}
	self.score = {}
	self.close_time = nil
	self.start_time = ev.time
	self.total_score = 0
end

--副本出口
function Scene_invasion:get_home_carry(obj)
	local config = invasion_config.config[self.id]
	local home_carry = config and config.home
	if not home_carry or not home_carry.id
		or not home_carry.pos or not home_carry.pos[1] or not home_carry.pos[2] then
		return nil, nil
	end
	return home_carry.id, home_carry.pos
end

function Scene_invasion:carry_scene(obj, pos)
	if not obj then
		return SCENE_ERROR.E_NOT_ON_SCENE, nil
	end

	local config = invasion_config.config[self.id]
	if not config then
		return SCENE_ERROR.E_SCENE_CLOSE, nil
	end
	
	local obj_id = obj:get_id()
	
	local limit = config.limit
	if limit then
		local human = limit.human
		if human and human.max and human.max < self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN):get_obj_count() + 1 then
			return SCENE_ERROR.E_FACTION_HUMAN_MAX, nil
		end
		
		if not self.owner_list[obj_id] then
			local cycle_limit = limit.cycle and limit.cycle.number
			local con = obj:get_copy_con()
			if cycle_limit and ((not con) or con:get_count_copy(self.id) >= cycle_limit) then
				return SCENE_ERROR.E_CYCLE_LIMIT
			end
			
			con:add_count_copy(self.id)
			self.owner_list[obj_id] = true
		end
	else
		if not self.owner_list[obj_id] then
			con:add_count_copy(self.id)
			self.owner_list[obj_id] = true
		end
	end
	--
	local team_id = obj:get_team()
	local team_o = g_team_mgr:get_team_obj(team_id)
	if team_o ~= nil and team_o:get_teamer_id() ~= obj_id then
		if g_faction_mgr:get_faction_by_cid(team_o:get_teamer_id()) ~= g_faction_mgr:get_faction_by_cid(obj_id) then
			f_team_kickout(obj)
		end
	end

	local i = math.random(1, #config.entry)
	return self:push_scene(obj, config.entry[i])
end

function Scene_invasion:do_reward()
	local score_info = invasion_config.config[self.id].score

	local rate = score_info.rate
	local score_type1 = score_info.type1
	local score_type2 = score_info.type2
	local score_type3 = score_info.type3
	
	--local total_type1 = 0
	--local total_type2 = 0
	--local total_type3 = 0

	local has_boss = false
	
	local obj_mgr = g_obj_mgr
	local faction_mgr = g_faction_mgr
	local result = nil
	local type_score = {}
	local human_score_t = 0
	local faction = faction_mgr:get_faction_by_fid(self.instance_id)
	if faction then
		result = {}
		result.timeout = self.close_time - ev.time
		local list = {}
		result.list = list
		local count = 0
		for obj_id, score in pairs(self.score_list) do
			--self.score_list[obj_id] = nil
			
			local type1 = score[1] or 0
			local type2 = score[2] or 0
			local type3 = score[3] or 0
			type_score[obj_id] = type1 * score_type1 + type2 * score_type2 + type3 * score_type3
			human_score_t = human_score_t + type_score[obj_id]
			--total_type1 = total_type1 + type1
			--total_type2 = total_type2 + type2
			--total_type3 = total_type3 + type3
			if type3 > 0 then
				has_boss = true
			end
		end

		for obj_id, score in pairs(self.score_list) do
			local obj = obj_mgr:get_obj(obj_id)
			if obj then
				local score_plus = math.floor((self.total_score - type_score[obj_id]) / 5 + type_score[obj_id])
				score_plus = math.min(score_plus, 6000)
				local level = obj:get_level()
				count = count + 1
				local exp = math.floor(
								(level ^ rate) * score_plus
									* (1 + obj:get_addition(HUMAN_ADDITION.ultimate_exp)))

				local faction_score = math.floor((score_plus * (rate ^ 3) * (1 + obj:get_addition(HUMAN_ADDITION.ultimate_con))) / 100)
				obj:add_exp(exp)

				local pkt = {}
				pkt.flag = 6
				pkt.param = faction_score
				faction_mgr:update_faction_level(obj_id, pkt)

				table.insert(
					list
					, {obj_id, obj:get_name(), level, score[1] or 0, score[2] or 0, score[3] or 0, faction_score, exp})
			end
		end
	
		local pkt = {}
		pkt.construct_point = math.floor(human_score_t * (rate ^ 3) / 70)
		pkt.money = math.floor((faction:get_level() + 4) * human_score_t * (rate * 10 - 13) * 3)
		pkt.scene_id = self.id
		pkt.type = 14
		faction_mgr:add_content(self.instance_id, pkt)
		
		local sql = string.format(
				"insert into faction_copy set copy_id=%d, faction_id='%s', kill_boss=%d, into_count=%d, reward_count=%d, create_time=%d"
				, self.id
				, self.instance_id
				, has_boss and 1 or 0
				, self.human_count
				, count
				, self.start_time)
				
		f_multi_web_sql(sql)
	end
	
	return result
end

function Scene_invasion:the_end()
	local pkt = {}
	pkt.faction_id = self.instance_id
	pkt.switch_flag = 0
	pkt.scene_id = self.id
	g_faction_mgr:switch_fb(pkt)
	
	self.close_time = ev.time + 30
	local result = self:do_reward()
	if self.obj_mgr then
		if result then
			local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
			if con then
				for obj_id, _ in pairs(con:get_obj_list()) do
					self:send_human(obj_id, CMD_MAP_INVASION_SETTLEMENT_NOTIFY, result)
				end
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
	end
end

function Scene_invasion:next_sequence()
	if self.is_success then
		return
	end

	self.sequence = self.sequence + 1

	local config = invasion_config.config[self.id]
	local wild = config.wild
	if not wild then
		return
	end
	local freq = wild[self.sequence]
	if not freq then
		self.is_success = true
		return
	end
	self.next_time = ev.time + freq.interval
	
	if freq.sequence then
		local new_list = {}
		for _, item in pairs(freq.sequence) do
			local area = item.area
			local info = self.area_list[area]
			local sequence = {}
			
			if not info then
				sequence.count = 0
				sequence.timeout = ev.time
			else
				sequence.count = info.count
				sequence.timeout = info.timeout
			end
			
			sequence.id = item.id
			sequence.interval = item.interval
			sequence.max = item.number
			new_list[area] = sequence
		end
		self.area_list = new_list
	end
end

function Scene_invasion:update_wild()
	if self.is_success then
		return
	end
	local obj_mgr = g_obj_mgr
	local now = ev.time
	
	for area, sequence in pairs(self.area_list) do
		if sequence.timeout <= now then
			while sequence.count < sequence.max do 
				local pos = self.map_obj:find_space(area, 20)
				if pos then
					local obj = obj_mgr:create_monster(sequence.id, pos, self.key)
					if obj and SCENE_ERROR.E_SUCCESS == self:enter_scene(obj) then
						self.area_monster[obj:get_id()] = area
						sequence.count = sequence.count + 1
					else
						break
					end
				else
					break
				end
			end
			sequence.timeout = sequence.timeout + sequence.interval
		end
	end
end

function Scene_invasion:on_timer(tm)
	local now = ev.time
	if (self.end_time and self.end_time <= now) 
		or (self.success_time and self.success_time <= now) then
		if not self.close_time then
			self:the_end()
		elseif self.close_time <= now then
			self:close()
		end
		return
	end
	
	if self.next_time <= now then
		self:next_sequence()
	end
 
	self:update_wild()
	self.obj_mgr:on_timer(tm)
	if self.is_success then
		self:check_success()
	end
end

function Scene_invasion:instance()
	local config = invasion_config.config[self.id]
	self.score = (config.score and config.score.type_map) or {}
	self.end_time = ev.time + config.limit.timeout.number
	self.start_time = ev.time
	self.obj_mgr:instance(self.map_obj:get_w(), self.map_obj:get_h())
end

function Scene_invasion:get_last_time(obj)
	return math.max(self.end_time - ev.time, 0)
end

function Scene_invasion:on_obj_enter(obj)
	if obj:get_type() == OBJ_TYPE_HUMAN then
		local obj_id = obj:get_id()
		g_scene_mgr_ex:register_event(EVENT_SET.EVENT_OUT_FACTION, obj_id, self, self.out_faction_event)
		g_scene_mgr_ex:register_event(EVENT_SET.EVENT_KILL_MONSTER, obj_id, self, self.kill_monster_event)
		if not self.score_list[obj_id] then
			self.human_count = self.human_count + 1
			self.score_list[obj_id] = {}
		end
	end
end

function Scene_invasion:kill_monster_event(monster_id, obj_id)
	local info = self.score[monster_id]
	if info then
		local record = self.score_list[obj_id]
		if not record then
			record = {}
			self.score_list[obj_id] = record
		end
		record[info.type] = (record[info.type] or 0) + 1
	end
end

function Scene_invasion:out_faction_event(obj_id)
	if obj_id then
		self:kickout(obj_id)
		self.score_list[obj_id] = nil
	end
end

function Scene_invasion:on_obj_leave(obj)
	local obj_id = obj:get_id()
	if obj:get_type() == OBJ_TYPE_HUMAN then
		g_scene_mgr_ex:unregister_event(EVENT_SET.EVENT_OUT_FACTION, obj_id)
		g_scene_mgr_ex:unregister_event(EVENT_SET.EVENT_KILL_MONSTER, obj_id)
	elseif obj:get_type() == OBJ_TYPE_MONSTER then
		local area = self.area_monster[obj_id]
		if area then
			local sequence = self.area_list[area]
			if sequence then
				sequence.count = math.max(sequence.count - 1, 0)
			end
		end

		local info = self.score[obj:get_occ()]
		if info then
			local score_info = invasion_config.config[self.id].score
			local point = 0
			if info.type == 1 then
				point = score_info.type1
			elseif info.type == 2 then
				point = score_info.type2
			elseif info.type == 3 then
				point = score_info.type3
			end
			self.total_score = self.total_score + point 
		end
	end
end
function Scene_invasion:check_success()
	--print("Scene_invasion:check_success()")
	if self.success_time then return end
	local con = self.obj_mgr:get_obj_con(OBJ_TYPE_MONSTER)
	if con == nil or table.is_empty(con:get_obj_list()) then
		self.success_time = ev.time + 10
		if self.id == 2902000 then
			g_faction_manor_mgr:add_manor(self.instance_id)
		end			
	end
end