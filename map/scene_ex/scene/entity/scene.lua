Scene = oo.class(Scene_entity, "Scene")

function Scene:__init(map_id)
	Scene_entity.__init(self, map_id)
	self.tomorrow = 0
	self.buff_type = 2
	self.vip_type = HUMAN_ADDITION.spirit_polymer
	self.exp_factor = 10
	self.reward_level_limit = 35
end

function Scene:instance()
	self.broadcast_timer = Broadcast_timer()
	self.exp_reward = Exp_reward()
	self.timer_queue = Timer_queue()
	self.summon_mgr = Summon_mgr(self)
	self.obj_mgr = Scene_obj_mgr_ex(Scene_monster_layout({self.id}, true), Scene_monster_common_mgr())
	self.obj_mgr:instance(self.map_obj:get_w(), self.map_obj:get_h())
	self:on_new_day()
end

function Scene:can_carry(obj)
	if not obj then
		return SCENE_ERROR.E_CARRY
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

function Scene:on_timer(tm)
	local now_time = ev.time
	
	self.obj_mgr:on_timer(tm)
	
	if self.tomorrow <= now_time then
		self:on_new_day()
	end
	
	self.timer_queue:exec(now_time)
	
	self.broadcast_timer:on_timer()
	self.exp_reward:try_reward(now_time, self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN):get_obj_list())
	self.summon_mgr:doing(now_time)
end

function Scene:exp_reward_config(today)
	local config = g_scene_config_mgr:get_extend_config(self.id)
	return config and config.exp_reward and config.exp_reward.day_list[today.wday]
end

function Scene:summon_config(today)
	local config = g_scene_config_mgr:get_extend_config(self.id)
	return config and config.summon and config.summon.day_list[today.wday]
end

function Scene:notify_config(today)
	local config = g_scene_config_mgr:get_extend_config(self.id)
	return config and config.exp_reward and config.exp_reward.notify
end

function Scene:notify_open(info, args)
	local config = 	{}

	config.exp_base = args.base
	config.addition_limit = args.limit
	config.exp_interval = args.interval
	config.buff_type = self.buff_type
	config.vip_type = self.vip_type
	config.exp_factor = self.exp_factor
	config.level_limit = self.reward_level_limit
	self.exp_reward:reset_config(config)
	self.exp_reward:start()
end

function Scene:notify_close()
	self.exp_reward:stop()
	self.exp_reward:clear_addition()
end

function Scene:collect_open(info, args)
	--print("Scene:collect_open:", self.id, j_e(args))
	self.summon_mgr:reset_config(args)
	self.summon_mgr:start()
end

function Scene:collect_close()
	--print("Scene:collect_close", self.id)
	self.summon_mgr:clear()
	self.summon_mgr:stop()
end

function Scene:load_config(today)
	local update_list = {}
	
	local today_time = os.time(today)
	
	local entity = self
	local exec =
		function (o, now)
			o.method(entity, o, o.args)
			return false
		end
	local timeout = function (o) end
	
	local freq_list = self:exp_reward_config(today)
	if freq_list and freq_list.open_time then

		local notify_list = self:notify_config(today)

		local exp = freq_list.exp
		for _, time_span in pairs(freq_list.open_time) do
			local open_info = self:build_node(
								today_time + (time_span.hour or 0) * 3600 + (time_span.minu or 0) * 60
								, (time_span.interval or 0) * 60
								, self.notify_open
								, exec
								, timeout)
			open_info.args = exp
			table.insert(update_list, open_info)
			
			local end_info = self:build_node(
				open_info.end_time
				, 5 * 60
				, self.notify_close
				, exec
				, timeout)
			table.insert(update_list, end_info)
			
			
			local now = ev.time
			for _, desc in pairs(notify_list or {}) do
				local desc_info = {}
				if desc.offset and desc.text then
					local timeout = desc.offset >= 0 and (open_info.start_time - (desc.offset * 60))
						or (open_info.end_time + (desc.offset * 60))
					if timeout > now then
						self.broadcast_timer:add_broadcast(timeout, desc.text, desc.type)
					end
				end
			end
		end
	end
	--
	local freq_list = self:summon_config(today)
	if freq_list and freq_list.open_time then

		for _, time_span in pairs(freq_list.open_time) do
			local open_info = self:build_node(
								today_time + (time_span.hour or 0) * 3600 + (time_span.minu or 0) * 60
								, (time_span.interval or 0) * 60
								, self.collect_open
								, exec
								, timeout)
			--print("time_span", j_e(time_span))
			open_info.args = time_span.collect
			table.insert(update_list, open_info)
			
			local end_info = self:build_node(
				open_info.end_time
				, 5 * 60
				, self.collect_close
				, exec
				, timeout)
			table.insert(update_list, end_info)
			
		end
	end

	return update_list
end

function Scene:on_new_day()
	local today = os.date("*t")
	today.hour = 0
	today.min = 0
	today.sec = 0
	local today_time = os.time(today)
	self.tomorrow = today_time + 86400
	self.timer_queue:reset(self:load_config(today))
end

function Scene:exp_reward_config(today)
	local config = g_scene_config_mgr:get_extend_config(self.id)
	return config and config.exp_reward and config.exp_reward.day_list[today.wday]
end

function Scene:notify_config(today)
	local config = g_scene_config_mgr:get_extend_config(self.id)
	return config and config.exp_reward and config.exp_reward.notify
end

function Scene:build_node(start, interval, method, exec, timeout)
	local info = {}
	info.start_time = start
	info.interval = interval
	info.end_time = start + interval
	info.method = method
	info.exec = exec
	info.timeout = timeout
	return info
end

function Scene:on_obj_leave(obj)
	Scene_entity.on_obj_leave(self, obj)
	if obj:get_type() == OBJ_TYPE_NPC then
		self.summon_mgr:coll_leave(obj:get_occ(), obj:get_id())
	end
end
--²É¼¯Îï
function Scene:create_collect_obj(obj, collect_id, pos_size)
	--print("Scene:create_collect_obj(obj, )", collect_id, pos_size)
	local pos = nil
	if pos_size == nil or pos_size <= 0 then
		pos = obj:get_pos()
		local collect_obj = g_obj_mgr:create_npc(collect_id, "", pos, self.key)
		if collect_obj and SCENE_ERROR.E_SUCCESS == self:enter_scene(collect_obj) then
			return true
		end
	else 
		local count = 0
		local map_o = self:get_map_obj()
		local cur_pos = obj:get_pos()
		local pos_m = {cur_pos[1]-5,cur_pos[1]+5,cur_pos[2]-5,cur_pos[2]+5}
		for i = 0, 80 do
			pos = map_o:find_pos(pos_m) or cur_pos
			local collect_obj = g_obj_mgr:create_npc(collect_id, "", pos, self.key)
			if collect_obj and SCENE_ERROR.E_SUCCESS == self:enter_scene(collect_obj) then
				count = count + 1
			end
			if count >= pos_size then
				return true
			end
		end
		if count >= 1 then
			return true
		end
	end
	
	return false
end