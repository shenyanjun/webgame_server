local battlefield_config = require("scene_ex.config.battlefield_config_loader")

Scene_battlefield_entry = oo.class(Scene_copy, "Scene_battlefield_entry")

local LEVEL_BREAK = 60

function Scene_battlefield_entry:__init(map_id)
	Scene_copy.__init(self, map_id, SCENE_STATUS.CLOSE)
	
	self.player_record = {}

	self.obj_instance = {}
	self.end_time = ev.time
	self.interval = 1800
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
function Scene_battlefield_entry:get_home_carry(obj)
	local config = battlefield_config.config[self.id]
	local home_carry = config and config.home
	if not home_carry or not home_carry.id or not home_carry.pos or not home_carry.pos[1] or not home_carry.pos[2] then
		return nil, nil
	end
	return home_carry.id, home_carry.pos
end

--获取副本实例ID
function Scene_battlefield_entry:get_instance_id(obj)
	local obj_id = obj:get_id()
	local instance_id = self.obj_instance[obj_id]
	
	local limit = battlefield_config.config[self.id].limit.count
	
	if instance_id then
		local instance = self.instance_list[instance_id]
		if (not instance) or (SCENE_STATUS.OPEN ~= instance:get_status() and SCENE_STATUS.IDLE ~= instance:get_status())
			or instance:get_human_count() >= limit then
			instance_id = nil
		end
	end
	
	if not instance_id then
		local is_level_break = obj:get_level() > LEVEL_BREAK and true or false
		for id, instance in pairs(self.instance_list) do
			if (SCENE_STATUS.OPEN == instance:get_status() or SCENE_STATUS.IDLE == instance:get_status())
				and instance:check_in(obj_id, limit)
				and (is_level_break == instance.is_level_break) then
				instance_id = id
				break
			end
		end

		if not instance_id then
			if self.instance_count >= battlefield_config.config[self.id].limit.copy then
				return nil, SCENE_ERROR.E_INSTANCE_LIMIT
			end
			if ev.time >= self.freeze_time then
				return nil, 31071
			end
		end
		
	 	instance_id = instance_id or crypto.uuid()
	end
	self.obj_instance[obj_id] = instance_id
	return instance_id, SCENE_ERROR.E_SUCCESS
end

--副本创建权限检查
function Scene_battlefield_entry:check_create_access(obj)
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
function Scene_battlefield_entry:check_entry_access(obj)
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
function Scene_battlefield_entry:create_instance(instance_id, obj)
	self.instance_count = self.instance_count + 1
	local map_config = {}
	map_config.exp_config = self.exp_config
	map_config.name_id = self.instance_count
	local is_level_break = obj:get_level() > LEVEL_BREAK and true or false
	return Scene_battlefield(
				self.id
				, instance_id
				, self.map_obj:clone(self.id)
				, self.interval
				, map_config
				, is_level_break
				, self.player_record
				, self.end_time)
end

function Scene_battlefield_entry:unregister_instance(instance_id, args)
	local instance = self.instance_list[instance_id]
	if instance then
		self.close_count = self.close_count + 1
		if self.instance_count == self.close_count then
			
		end
		instance:close()
		self.instance_list[instance_id] = nil
	end
end

-----------------------------------------------场景实例化---------------------------------------------

function Scene_battlefield_entry:instance()
	self.map_obj = g_scene_config_mgr:load_map(self.id)
end

function Scene_battlefield_entry:get_status_info()
	local total = 0
	local total_limit = 0
	local limit = battlefield_config.config[self.id].limit.count
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

function Scene_battlefield_entry:login_scene(obj, pos)
	local e_code, error_list = self:carry_scene(obj, pos)
	if SCENE_ERROR.E_SUCCESS ~= e_code then
		return Scene_copy.login_scene(self, obj, pos)
	end
	return e_code, error_list
end

function Scene_battlefield_entry:carry_scene(obj, pos)
	if self.status == SCENE_STATUS.CLOSE then
		return SCENE_ERROR.E_NOT_OPNE
	end
	
	if obj:get_level() < 30 then
		return SCENE_ERROR.E_LEVEL_DOWN
	end

	local obj_id = obj:get_id()
	
	local record = self.player_record[obj_id]
	if not record then
		self.player_record[obj_id] = {0, 0}
	elseif record[2] > ev.time then
		return 31070, nil
	end
	
	return Scene_copy.carry_scene(self, obj, pos)
end

---------------------------------------------------------------------------------------------------------------

function Scene_battlefield_entry:load_today_event(today)
	local config = battlefield_config.config[self.id]

	local freq_list = config.day_list[today.wday]
	if not freq_list or not freq_list.open_time then
		return
	end
	
	local today_time = os.time(today)

	local exp = freq_list.exp
	for _, time_span in pairs(freq_list.open_time) do
		local start_time = today_time + (time_span.hour or 0) * 3600 + (time_span.minu or 0) * 60
		local end_time = start_time + (time_span.interval or 0) * 60
		
		local args = {}
		args.start_time = start_time
		args.end_time = end_time
		args.interval = (time_span.interval or 0) * 60
		args.exp = exp
		args.list = {}
		
		if end_time > start_time then
			self.timer_heap:push(start_time, end_time, self, "open_event", args)
			self.timer_heap:push(end_time, end_time + 5 * 60, self, "close_event", nil)
		end
	end
end

function Scene_battlefield_entry:open_event(args)
	self.end_time = args.end_time
	self.interval = args.interval
	self.freeze_time = args.start_time + battlefield_config.config[self.id].limit.freeze
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