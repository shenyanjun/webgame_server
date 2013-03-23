
--0 非vip；1 周卡；2 月卡；3 季卡；4 半年卡；5 体验卡
local vip_add = {3, 4, 5, 6, 3}

Scene_vip = oo.class(Scene_instance, "Scene_vip")

function Scene_vip:__init(map_id, instance_id, map_obj)
	Scene_instance.__init(self, map_id, instance_id, map_obj)
	
	self.check_time	= ev.time + 10
	self.enter_list = {}
	self.wait_relive = {}	--等待复活列表
	self.vip_add_list = {}	--vip加成列表
end

function Scene_vip:carry_scene(obj, pos)

	local bang_time = obj:get_vip_bang_time()
	if bang_time <= 0 then
		return 21311
	end

	if not obj then
		return SCENE_ERROR.E_NOT_ON_SCENE
	end
	
	local obj_id = obj:get_id()
	if not self.owner_list[obj_id] then
		--[[
		local config = self:get_self_limit_config()
		local cycle_limit = config.cycle
		local con = obj:get_copy_con()
		if cycle_limit and con:get_count_copy(self.id) >= cycle_limit then
			return SCENE_ERROR.E_CYCLE_LIMIT
		end
		con:add_count_copy(self.id)
		]]
		self.owner_list[obj_id] = true
		
		f_multi_web_sql(string.format("insert into copy_into set copy_id=%d, char_id=%d, time=%d, char_name='%s'"
					, self.id
					, obj_id
					, ev.time
					, obj:get_name()))
	end
	
	return self:push_scene(obj, pos)
end

function Scene_vip:on_timer(tm)

	self.obj_mgr:on_timer(tm)

	if ev.time >= self.check_time and self.obj_mgr then
		local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
		if con then
			local can_close = true
			for obj_id, _ in pairs(con:get_obj_list()) do
				local obj = g_obj_mgr:get_obj(obj_id)
				if obj then
					can_close = false
					local entry = self.enter_list[obj_id] or {ev.time, obj:get_vip_bang_time()}
					local bang_time = entry[2] - (ev.time - entry[1])
					if bang_time <= 0 then
						self:kickout(obj_id)
					--[[
					elseif bang_time < 180 and bang_time >= 170 then
						local pkt = {}
						self:send_human(obj_id, CMD_MAP_SCENE_VIP_END_NOTIFY, pkt)
					]]
					end
				end
			end
			if can_close then
				self:close()
			end
		else
			self:close()
		end
		self.check_time	= ev.time + 10
	end

	self:do_relive(ev.time)
end

function Scene_vip:on_obj_enter(obj)
	Scene_instance.on_obj_enter(self, obj)
	if obj:get_type() == OBJ_TYPE_HUMAN then
		local obj_id = obj:get_id()
		self.enter_list[obj_id] = {ev.time, obj:get_vip_bang_time()}
		local pkt = {}
		pkt.time = obj:get_vip_bang_time()
		self:send_human(obj_id, CMD_MAP_SCENE_RESET_END_TIME_S, pkt)
		self.wait_relive[obj_id] = nil
		--
		local vip_type = g_vip_mgr:get_vip_info(obj_id)
		local vip_v = vip_add[vip_type] or 0
		self.vip_add_list[obj_id] = vip_v
		obj:add_double_exp(vip_v)
	end
end

function Scene_vip:on_obj_leave(obj)
	Scene_instance.on_obj_leave(self, obj)

	if obj:get_type() == OBJ_TYPE_HUMAN then
		local obj_id = obj:get_id()
		local enter_time = self.enter_list[obj_id]
		if enter_time then
			local enter_day = os.date("*t", enter_time[1])
			local leave_day = os.date("*t", ev.time)
			if enter_day.wday == leave_day.wday then
				obj:add_vip_bang_time(ev.time - enter_time[1])
			end
		end
		self.wait_relive[obj_id] = nil
		--
		local vip_v = self.vip_add_list[obj_id] or 0
		obj:add_double_exp(-vip_v)
		self.vip_add_list[obj_id] = nil
	end
end

function Scene_vip:do_relive(now_time)
	local obj_mgr = g_obj_mgr
	for char_id, time in pairs(self.wait_relive) do
		if time <= now_time then
			local obj = obj_mgr:get_obj(char_id)
			if obj then
				self.wait_relive[char_id] = nil
				if not obj:is_alive() then
					--obj:relive_and_convey(1, self.id, pos)
					obj:do_relive(1, true)	--复活
					obj:send_relive(3)
					--self:transport(obj, pos)
				end
			end
		end
	end
end

function Scene_vip:die_event(args)

	args.mode = 1
	args.is_notify = false
	args.is_evil = false
	args.relive_time = 5
	
	self.wait_relive[args.char_id] = args.relive_time + ev.time
end

function Scene_vip:instance()
	local config = self:get_self_config()
	self.end_time = ev.time + config.time
	
	self.obj_mgr = Scene_obj_mgr_ex(Scene_monster_layout(self.key, true), Scene_monster_copy_mgr())
	self.obj_mgr:instance(self.map_obj:get_w(), self.map_obj:get_h())
end