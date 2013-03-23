local frenzy_config = require("scene_ex.config.frenzy_config_loader")

Scene_frenzy_entry = oo.class(Scene_copy, "Scene_frenzy_entry")

function Scene_frenzy_entry:__init(map_id)
	Scene_copy.__init(self, map_id, SCENE_STATUS.CLOSE)
	
	self.player_record = {}

	self.obj_instance = {}
	self.end_time = ev.time
	self.freeze_time = ev.time
	self.instance_count = 0
	
	self.args_list = {}
	self.exp_config = {}
	self.exp_config.buff_type = 4
	self.exp_config.vip_type = HUMAN_ADDITION.war_reward
	self.exp_config.exp_factor = 40
	
	self.close_count = 0
	self.reward_list = {}
end

-----------------------------------------------子类实现--------------------------------------------

--副本出口
function Scene_frenzy_entry:get_home_carry(obj)
	local config = frenzy_config.config[self.id]
	local home_carry = config and config.home
	if not home_carry or not home_carry.id or not home_carry.pos or not home_carry.pos[1] or not home_carry.pos[2] then
		return nil, nil
	end
	return home_carry.id, home_carry.pos
end

--获取副本实例ID
function Scene_frenzy_entry:get_instance_id(obj)
	local obj_id = obj:get_id()
	local instance_id = self.obj_instance[obj_id]
	
	local limit = frenzy_config.config[self.id].limit.count
	
	if instance_id then
		local instance = self.instance_list[instance_id]
		if (not instance) or (SCENE_STATUS.OPEN ~= instance:get_status())
			or instance:get_human_count() >= limit then
			instance_id = nil
		end
	end
	
	if not instance_id then
		for id, instance in pairs(self.instance_list) do
			if SCENE_STATUS.OPEN == instance:get_status()
				and instance:get_human_count() < limit then
				instance_id = id
				break
			end
		end

		if not instance_id 
			and (self.instance_count >= frenzy_config.config[self.id].limit.copy 
					or ev.time >= self.freeze_time)then
			return nil, SCENE_ERROR.E_INSTANCE_LIMIT
		end
		
	 	instance_id = instance_id or crypto.uuid()
	end
	self.obj_instance[obj_id] = instance_id
	return instance_id, SCENE_ERROR.E_SUCCESS
end

--副本创建权限检查
function Scene_frenzy_entry:check_create_access(obj)
	local team_id = obj:get_team()
	local team_obj = team_id and g_team_mgr:get_team_obj(team_id)
	if team_obj then
		return SCENE_ERROR.E_HAS_TEAM
	end

	local target_config = g_scene_config_mgr:get_config(self.id)
	if not target_config then
		return SCENE_ERROR.E_SCENE_CLOSE
	end
	
	if target_config.level > obj:get_level() then
		return SCENE_ERROR.E_LEVEL_DOWN
	end
	return SCENE_ERROR.E_SUCCESS
end

--副本进入权限检查
function Scene_frenzy_entry:check_entry_access(obj)
	local team_id = obj:get_team()
	local team_obj = team_id and g_team_mgr:get_team_obj(team_id)
	if team_obj then
		return SCENE_ERROR.E_HAS_TEAM
	end

	local target_config = g_scene_config_mgr:get_config(self.id)
	if not target_config then
		return SCENE_ERROR.E_SCENE_CLOSE
	end
	
	if target_config.level > obj:get_level() then
		return SCENE_ERROR.E_LEVEL_DOWN
	end
	
	return SCENE_ERROR.E_SUCCESS
end

--创建副本实例
function Scene_frenzy_entry:create_instance(instance_id, obj)
	self.instance_count = self.instance_count + 1
	local map_config = {}
	map_config.exp_config = self.exp_config
	map_config.name_id = self.instance_count
	return Scene_frenzy(
				self.id
				, instance_id
				, self.map_obj:clone(self.id)
				, self.end_time
				, map_config
				, table.copy(self.args_list)
				, self.player_record)
end

function Scene_frenzy_entry:unregister_instance(instance_id, args)
	local instance = self.instance_list[instance_id]
	if instance then
		local reward_list = instance:get_reward_list()
		if reward_list then
			--print(Json.Encode(reward_list))
			for k, v in ipairs(reward_list) do
				local info = self.reward_list[v.obj_id]
				if not info then
					self.reward_list[v.obj_id] = {v.obj_id, v.list[1], v.list[2], v.list[4], v.list[5]} 
				else
					info[3] = info[3] + v.list[2]
					info[4] = info[4] + v.list[4]
				end
			end
		end
		
		self.close_count = self.close_count + 1
		if self.instance_count == self.close_count then
			local detail = {}
			for k, info in pairs(self.reward_list) do
				local i = 1
				while i <= 20 do
					local record = detail[i]
					if not record then
						break
					else
						if record[3] == info[3] then
							if record[4] < info[4] then
								break
							end
						elseif record[3] < info[3] then
							break
						end
					end					
					i = i + 1
				end
				
				while i <= 20 and info do
					local record = detail[i]
					detail[i] = info
					info = record
					i = i + 1
				end
			end
			
			local query = string.format("{'date':0, 'scene_id':%d}", self.id)
			local value = {}
			value.date = 0
			value.scene_id = self.id
			value.detail = detail
			--print("--", Json.Encode(detail))
			f_get_db():update("result_record", query, Json.Encode(value), true)
		end
		instance:close()
		self.instance_list[instance_id] = nil
	end
end

-----------------------------------------------场景实例化---------------------------------------------

function Scene_frenzy_entry:instance()
	self.map_obj = g_scene_config_mgr:load_map(self.id)
end

function Scene_frenzy_entry:get_status_info()
	local total = 0
	local total_limit = 0
	local limit = frenzy_config.config[self.id].limit.count
	for _, instance in pairs(self.instance_list) do	
		total = total + instance.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN):get_obj_count()
		total_limit = limit + total_limit
	end
	return {self.id
			, self:get_name()
			, total
			, total_limit
			, self.status}
end

-----------------------------------------------场景入口----------------------------------------------

function Scene_frenzy_entry:login_scene(obj, pos)
	local e_code, error_list = self:carry_scene(obj, pos)
	if SCENE_ERROR.E_SUCCESS ~= e_code then
		return Scene_copy.login_scene(self, obj, pos)
	end
	return e_code, error_list
end

function Scene_frenzy_entry:carry_scene(obj, pos)
	if self.status == SCENE_STATUS.CLOSE then
		return SCENE_ERROR.E_NOT_OPNE
	end
	
	local obj_id = obj:get_id()
	
	local record = self.player_record[obj_id]
	if not record then
		self.player_record[obj_id] = {0, 0}
	elseif record[2] > ev.time then
		return SCENE_ERROR.E_WAIT_TIMEOUT, nil
	end
	
	return Scene_copy.carry_scene(self, obj, pos)
end

---------------------------------------------------------------------------------------------------------------

function Scene_frenzy_entry:load_today_event(today)
	local config = frenzy_config.config[self.id]

	local freq_list = config.day_list[today.wday]
	if not freq_list or not freq_list.open_time then
		return
	end
	
	local today_time = os.time(today)

	local exp = freq_list.exp
	for _, time_span in pairs(freq_list.open_time) do
		local start_time = today_time + (time_span.hour or 0) * 3600 + (time_span.minu or 0) * 60
		local end_time = start_time + (time_span.interval or 0) * 60
		
		local args_list = {}
		for _, item in pairs(freq_list.update_list or {}) do
			for _, freq in pairs(item.update) do
				local info = {}
				info.start_time = start_time + (freq.offset or 0) * 60
				info.interval = freq.interval
				info.count = freq.count

				local args = {}
				args.per = freq.per	or 0												--刷新的数量
				args.occ = item.occ														--刷新的NPC的OCC
				args.type = item.type													--刷新的NPC的类型
				args.area = item.area													--刷新的区域
				args.desc = item.desc													--刷新的广播
				args.item_list = item.item_list
				
				info.args = args
				table.insert(args_list, info)
			end
		end		
		
		local args = {}
		args.start_time = start_time
		args.end_time = end_time
		args.exp = exp
		args.list = args_list
		
		if end_time > start_time then
			self.timer_heap:push(start_time, end_time, self, "open_event", args)
			self.timer_heap:push(end_time, end_time + 5 * 60, self, "close_event", nil)
		end
	end
end

function Scene_frenzy_entry:open_event(args)
	self.end_time = args.end_time
	self.freeze_time = args.start_time + frenzy_config.config[self.id].limit.freeze
	self.status = SCENE_STATUS.OPEN
	
	self.exp_config.exp_base = args.exp.base
	self.exp_config.addition_limit = args.exp.limit
	self.exp_config.exp_interval = args.exp.interval
	self.args_list = args.list
	
	self.obj_instance = {}
	self.instance_list = {}
	self.player_record = {}
	self.instance_count = 0
	
	self.close_count = 0
	self.reward_list = {}
end