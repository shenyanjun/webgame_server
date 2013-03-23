Scene_desert = oo.class(Scene_entity, "Scene_desert")

local _max_mon_area = 30

function Scene_desert:__init(map_id)
	Scene_entity.__init(self, map_id)
	self.tomorrow = 0
	self.timer_heap = Timer_heap()
	self.monster_list = {}
	self.npc_list = {}
	self.wait_relive = {}
end

function Scene_desert:instance()
	self.obj_mgr:instance(self.map_obj:get_w(), self.map_obj:get_h())
	self:on_new_day()
end

function Scene_desert:on_new_day()
	local today = os.date("*t")
	today.hour = 0
	today.min = 0
	today.sec = 0
	local today_time = os.time(today)
	self.tomorrow = today_time + 86400
	self:build_timer_queue(today)
	self.timer_heap:push(self.tomorrow, nil, self, "on_new_day", nil)
end

function Scene_desert:build_timer_queue(today)
	--print("build_timer_queue")

	local config = g_all_scene_config[self.id]
	if not config or not config.day_list then
		return
	end

	local day_list = config.day_list[today.wday]
	if not day_list then
		return
	end
	
	local today_time = os.time(today)
	
	for _, freq in pairs(day_list) do
		--print("--->freq", j_e(freq))
		local start_time = today_time + (freq.hour or 0) * 3600 + (freq.minu or 0) * 60
		local interval = (freq.interval or 0)
		
		for i = 1, freq.count do
			self.timer_heap:push(
				start_time + interval * (i - 1)
				, start_time + interval * i
				, self
				, "update_object"
				, {["world_level"] = freq.world_level})
		end
	end
end

function Scene_desert:on_timer(tm)
	Scene_entity.on_timer(self, tm)
	self.timer_heap:exec(ev.time)
	self:clean_object(ev.time)
	self:do_relive(ev.time)
end

function Scene_desert:update_object(args)
	if not args or not args.world_level then
		return
	end
	
	local object_list = nil
	local world_level = g_world_lvl_mgr:get_average_level()
	for k, v in ipairs(args.world_level) do
		if world_level <= v[1] then
			object_list = v[2]
			break
		end
	end
	if object_list == nil then
		object_list = args.world_level[#args.world_level][2]
	end

	local map_obj = self:get_map_obj()
	local now = ev.time
	
	for _, o in pairs(object_list) do
		for i = 1, o.per do
			local obj = nil
			local pos = map_obj:find_space(o.area, 20)
			if o.area <= _max_mon_area then
				obj = g_obj_mgr:create_monster(o.occ, pos, self.key, nil)
				self.monster_list[obj:get_id()] = o.live + now
			else
				obj = g_obj_mgr:create_npc(o.occ, "", pos, self.key, nil)
				self.npc_list[obj:get_id()] = o.live + now
			end
			self:enter_scene(obj)
		end
	end
end

function Scene_desert:clean_object(now_time)
	for obj_id, dead_time in pairs(self.monster_list) do
		if dead_time <= now_time then
			local obj = g_obj_mgr:get_obj(obj_id)
			if not obj then
				self.monster_list[obj_id] = nil
			elseif not obj:is_combat() then
				self.monster_list[obj_id] = nil
				obj:leave()
			end
		end
	end

	for obj_id, dead_time in pairs(self.npc_list) do
		if dead_time <= now_time then
			local obj = g_obj_mgr:get_obj(obj_id)
			if obj then
				obj:leave()
			end
			self.npc_list[obj_id] = nil
		end
	end
end

function Scene_desert:do_relive(now_time)
	local obj_mgr = g_obj_mgr
	for char_id, time in pairs(self.wait_relive) do
		local config = g_all_scene_config[self.id]
		if time < now_time then
			local obj = obj_mgr:get_obj(char_id)
			if obj then
				self.wait_relive[char_id] = nil
				if not obj:is_alive() then
					local relive_list = config.relive
					local i = math.random(1, #relive_list)
					local pos = relive_list[i]
					obj:do_relive(1, true)	--复活
					obj:send_relive(3)
					self:transport(obj, pos)
				end
			end
		end
	end
end

function Scene_desert:die_event(args)
	local killer_id = args.killer_id
	local obj_id = args.char_id
	local obj = self:get_obj(obj_id)
	if obj then
		self.wait_relive[obj_id] = ev.time + 5			--加入等待复活列表
		
		args.mode = 1
		args.is_notify = false
		args.is_evil = false
		args.relive_time = math.max(self.wait_relive[obj_id] - ev.time, 0)
	end
end

function Scene_desert:on_obj_enter(obj)
	if OBJ_TYPE_HUMAN == obj:get_type() then
		local obj_id = obj:get_id()
		self.wait_relive[obj_id] = nil
	end
end

function Scene_desert:on_obj_leave(obj)
	if OBJ_TYPE_HUMAN == obj:get_type() then
		local obj_id = obj:get_id()
		if not obj:is_alive() then
			self.wait_relive[obj_id] = nil
			obj:do_relive(1, true)
		end
	end
end

function Scene_desert:login_scene(obj, pos)
	return self:carry_scene(obj, pos)
end

function Scene_desert:carry_scene(obj, pos)
	local target_config = g_scene_config_mgr:get_config(self.id)
	if not target_config then
		return SCENE_ERROR.E_SCENE_CLOSE
	end
	
	if target_config.level > obj:get_level() then
		return SCENE_ERROR.E_LEVEL_DOWN
	end
	
	if self:get_human_count() >= self:get_limit() then
		return SCENE_ERROR.E_HUMAN_FULL
	end
	
	local config = g_all_scene_config[self.id]
	local entry_list = config.entry
	local i = math.random(1, #entry_list)
	
	local e_code, e_desc = self:push_scene(obj, entry_list[i])
	
	local obj_id = obj:get_id()
	if SCENE_ERROR.E_SUCCESS == e_code then
		f_multi_web_sql(string.format("insert into copy_into set copy_id=%d, char_id=%d, time=%d, char_name='%s', type=1"
					, self.id
					, obj_id
					, ev.time
					, obj:get_name()))
	end
	return e_code, e_desc
end