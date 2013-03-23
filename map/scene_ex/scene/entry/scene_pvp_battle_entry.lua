local pvp_config = require("scene_ex.config.pvp_battle_loader")


Scene_pvp_battle_entry = oo.class(Scene_copy, "Scene_pvp_battle_entry")


function Scene_pvp_battle_entry:__init(map_id)
	Scene_copy.__init(self, map_id, SCENE_STATUS.CLOSE)
	
	self.obj_instance = {}
	self.end_time = ev.time
	self.interval = 3600

	self.instance_count = 1
	self.copy_list = {}
	self.copy_index = {}
	self.send_human_time = ev.time
	
	self.args_list = {}
	
	self.close_count = 0

end

-----------------------------------------------子类实现--------------------------------------------

--副本出口
function Scene_pvp_battle_entry:get_home_carry(obj)
	local config = pvp_config.config[self.id]
	local home_carry = config and config.home
	if not home_carry or not home_carry.id or not home_carry.pos 
			or not home_carry.pos[1] or not home_carry.pos[2] then
		return nil, nil
	end
	return home_carry.id, home_carry.pos
end

--获取副本实例ID
function Scene_pvp_battle_entry:get_instance_id(obj)
	local obj_id = obj:get_id()
	local instance_id = self.obj_instance[obj_id]
	if instance_id then
		local instance = self.instance_list[instance_id]
		if (not instance) or (SCENE_STATUS.OPEN ~= instance:get_status() 
				and SCENE_STATUS.IDLE ~= instance:get_status()) or not instance:check_in() then
			
			instance_id = nil
		end
	end
	if not instance_id then
		local instance_id_e = nil
		for id, instance in pairs(self.instance_list) do
			if (SCENE_STATUS.OPEN == instance:get_status() or SCENE_STATUS.IDLE == instance:get_status())
				and instance:check_in() then
				instance_id_e = id
				break
			end
		end
		
	 	instance_id = instance_id_e or crypto.uuid()
		if not instance_id_e then
			self.copy_list[self.instance_count] = instance_id
			self.copy_index[instance_id] = self.instance_count
		end
	end
	self.obj_instance[obj_id] = instance_id
	return instance_id, SCENE_ERROR.E_SUCCESS
end

function Scene_pvp_battle_entry:obj_get_copy_id(obj_id)
	local instance_id = self.obj_instance[obj_id]
	return self.copy_index[instance_id]
end

--副本创建权限检查
function Scene_pvp_battle_entry:check_create_access(obj)
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
function Scene_pvp_battle_entry:check_entry_access(obj)
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
function Scene_pvp_battle_entry:create_instance(instance_id, obj)	
	local copy_id = self.instance_count
	self.instance_count = self.instance_count + 1
	return Scene_pvp_battle(
				self.id
				, instance_id
				, self.map_obj:clone(self.id)
				, copy_id
				, self.interval
				, self.end_time
				)
end

function Scene_pvp_battle_entry:unregister_instance(instance_id, args)
	local instance = self.instance_list[instance_id]
	if instance then
		self.close_count = self.close_count + 1
		local copy_id = self.copy_index[instance_id]
		self.copy_list[copy_id] = nil
		self.copy_index[instance_id] = nil
		if self.instance_count == self.close_count then
			
		end
		instance:close()
		self.instance_list[instance_id] = nil
	end
end

-----------------------------------------------场景实例化---------------------------------------------

function Scene_pvp_battle_entry:instance()
	self.map_obj = g_scene_config_mgr:load_map(self.id)
end

function Scene_pvp_battle_entry:pri_get_status_info()
	local copy_info = {}
	for k, instance_id in pairs(self.copy_list) do
		local instance = self.instance_list[instance_id]
		if instance then
			copy_info[k] = instance:get_human_count()
		end
	end
	return pvp_config.config.limit.count, copy_info
end

-----------------------------------------------场景入口----------------------------------------------

function Scene_pvp_battle_entry:login_scene(obj, pos)
	local e_code, error_list = self:carry_scene(obj, pos)
	if SCENE_ERROR.E_SUCCESS ~= e_code then
		return Scene_copy.login_scene(self, obj, pos)
	end
	return e_code, error_list
end

--//选择副本加多个参数
function Scene_pvp_battle_entry:carry_scene(obj, pos)
	if self.status == SCENE_STATUS.CLOSE then
		return SCENE_ERROR.E_NOT_OPNE
	end
	
	if obj:get_level() < 60 then
		return SCENE_ERROR.E_LEVEL_DOWN
	end
		
	return Scene_copy.carry_scene(self, obj, nil)
end

function Scene_pvp_battle_entry:select_instance(char_id, copy_id, pos)
	local old_instance_id = self.obj_instance[char_id]
	local obj = g_obj_mgr:get_obj(char_id)
	if not obj then return end
	if copy_id < 1 or copy_id > self.instance_count then
		return SCENE_ERROR.E_SCENE_CHANGE
	end
	
	--在同一场景中
	local scene_o = obj:get_scene_obj()
	if scene_o:get_type() == SCENE_TYPE.PVP_BATTLE and copy_id == scene_o:get_copy_id() then
		if pos then
			scene_o:transport(obj, pos)
			return 21313
		else 
			return 0
		end
		
	end

	local instance_id = self.copy_list[copy_id]
	local instance = self.instance_list[instance_id]
	if not (instance and instance:check_in()) then
		return SCENE_ERROR.E_HUMAN_FULL
	end

	self.obj_instance[char_id] = instance_id
	local err = self:push_scene(obj, pos)
	if err ~= 0 then
		self.obj_instance[char_id] = old_instance_id
		return err
	end	
end

---------------------------------------------------------------------------------------------------------------

function Scene_pvp_battle_entry:get_human_list()
	local human_list = {}
	for k, instance_id in pairs(self.copy_list) do
		local instance = self.instance_list[instance_id]
		if instance then
			human_list[k] = instance:get_human_list()
		end
	end
	return human_list
end

function Scene_pvp_battle_entry:check_copy_open()
	if self.end_time > ev.time then
		return 0
	end
	return SCENE_ERROR.E_NOT_OPNE
end

function Scene_pvp_battle_entry:on_timer(tm)
	for _, instance in pairs(self.instance_list) do
		instance:on_timer(tm)
	end
	self.timer_heap:exec(ev.time)

	local now = ev.time
	if self.end_time < now then
		return 
	end
	if self.send_human_time < now  then
		local pkt = {}
		local cltsock_mgr = g_cltsock_mgr
		pkt.limit, pkt.copy_info = self:pri_get_status_info()
		pkt = Json.Encode(pkt)
		local human_list = self:get_human_list()
		for k, list in pairs(human_list or {}) do
			for char_id, _ in pairs(list or {}) do
				cltsock_mgr:send_client(char_id, CMD_MAP_PVP_BATTLE_COPY_INFO_S, pkt, true)
			end
		end
		self.send_human_time = now + 3
	end

end


function Scene_pvp_battle_entry:load_today_event(today)
	local config = pvp_config.config

	local freq_list = config.day_list[today.wday]
	if not freq_list or not freq_list.open_time then
		return
	end
	
	local today_time = os.time(today)

	for _, time_span in pairs(freq_list.open_time) do
		local start_time = today_time + (time_span.hour or 0) * 3600 + (time_span.minu or 0) * 60
		local end_time = start_time + (time_span.interval or 0) * 60
		
		local args = {}
		args.start_time = start_time
		args.end_time = end_time
		args.interval = (time_span.interval or 0) * 60
		
		if end_time > start_time then
			self.timer_heap:push(start_time, end_time, self, "open_event", args)
			self.timer_heap:push(end_time, end_time + 5 * 60, self, "close_event", nil)
		end
	end
end

function Scene_pvp_battle_entry:open_event(args)
	self.end_time = args.end_time
	self.interval = args.interval
	self.status = SCENE_STATUS.OPEN
		
	self.obj_instance = {}
	self.instance_list = {}
	self.player_record = {}
	self.instance_count = 0
	
	self.close_count = 0
	self.reward_list = {}

	self.instance_count = 1
	self.copy_list = {}
	self.copy_index = {}
	self.send_human_time = ev.time

end