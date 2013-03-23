Scene_war = oo.class(Scene, "Scene_war")

local war_config = require("scene_ex.config.war_config_loader")

function Scene_war:__init(map_id)
	Scene.__init(self, map_id)
	self.mode = MAP_MODE_PEACE
	
	self.monster_list = {}
	self.npc_list = {}
	self.wait_relive = {}
	self.die_record = {}
	
	self.buff_type = 4
	self.vip_type = HUMAN_ADDITION.war_reward
	self.exp_factor = 40
	
	self.end_time = 0
	self.status = SCENE_STATUS.CLOSE
end

function Scene_war:get_mode()
	return self.mode
end

function Scene_war:can_carry(obj)
	return SCENE_ERROR.E_CARRY
end

function Scene_war:get_limit()
	return war_config.config[self.id].limit
end

function Scene_war:exp_reward_config(today)
	local config = war_config.config[self.id]
	return config and config.day_list and config.day_list[today.wday]
end

function Scene_war:notify_config(today)
	local config = war_config.config[self.id]
	return config and config.notify
end

function Scene_war:login_scene(obj, pos)
	local config = war_config.config[self.id]
	local entry_list = config.entry
	local i = math.random(1, #entry_list)
	return self:push_scene(obj, entry_list[i])
end

function Scene_war:get_last_time(obj)
	return math.max(self.end_time - ev.time, 0)
end

function Scene_war:build_update_node(now, start, interval, count, method, exec, timeout)
	local info = {}
	info.start_time = start
	info.interval = interval
	info.end_time = start + (interval * count)
	info.cur_count = start < now and math.floor((now - start) / interval) or 0
	info.count = count
	info.method = method
	info.exec = exec
	info.timeout = timeout
	return info
end

function Scene_war:load_config(today)
	local update_list = Scene.load_config(self, today)

	local freq_list = self:exp_reward_config(today)
	
	if not freq_list or not freq_list.open_time then
		return update_list
	end
	
	local today_time = os.time(today)
	
	local entity = self
	
	local exec =
		function (o, now)
			if o.cur_count < o.count then
				if (o.cur_count * o.interval + o.start_time) <= now then
					o.cur_count = o.cur_count + 1
					o.method(entity, o, o.args)
				end
			end
			return o.cur_count < o.count 
		end
		
	local timeout = function (o) end
	
	local now = os.time()

	for _, time_span in pairs(freq_list.open_time) do
		local start_time = today_time + (time_span.hour or 0) * 3600 + (time_span.minu or 0) * 60
		
		for _, item in pairs(freq_list.update_list or {}) do
			for _, freq in pairs(item.update) do
				local info = self:build_update_node(
					now
					, start_time + (freq.offset or 0) * 60								--刷新开始时间
					, freq.interval														--刷新间隔
					, freq.count														--刷新次数
					, self.update_event
					, exec
					, timeout)

				local args = {}
				args.per = freq.per	or 0												--刷新的数量
				args.occ = item.occ														--刷新的NPC的OCC
				args.type = item.type													--刷新的NPC的类型
				args.area = item.area													--刷新的区域
				args.desc = item.desc													--刷新的广播
				args.item_list = item.item_list
				
				info.args = args
				table.insert(update_list, info)
			end
		end
	end
	
	return update_list
end

function Scene_war:update_event(info, args)
	self:update(info, args)
end

function Scene_war:update(info, args)

	local area = args.area
	if not area then
		return
	end
	
	local length = #area
	local i = math.random(1, length)
	local map_obj = self:get_map_obj()
	
	local count = math.floor(self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN):get_obj_count() * args.per)
	if 1 == args.type then
		for j = 1, count do
			self:build_box(args, map_obj.id, map_obj:find_pos(area[i]))
		end
	elseif 2 == args.type then
		for j = 1, count do
			self:build_monster(args, map_obj.id, map_obj:find_pos(area[i]), info.cur_count * info.interval + info.start_time)
		end
	elseif 3 == args.type then
		for j = 1, count do
			self:build_npc(args, map_obj.id, map_obj:find_pos(area[i]), info.cur_count * info.interval + info.start_time)
		end
	end
	
	if args.desc and count > 0 then
		f_cmd_linebd(f_create_sysbd_format(args.desc, 16))
	end
end

function Scene_war:build_npc(info, map_id, pos, dead_time)
	local obj = g_obj_mgr:create_npc(info.occ, "", pos, {map_id, nil}, nil)
	local obj_id = obj:get_id()
	self:enter_scene(obj)
	self.npc_list[obj_id] = dead_time
	return obj
end

function Scene_war:build_monster(info, map_id, pos, dead_time)
	local obj = g_obj_mgr:create_monster(info.occ, pos, {map_id, nil}, nil)
	local obj_id = obj:get_id()
	self:enter_scene(obj)
	self.monster_list[obj_id] = dead_time
	return obj
end

function Scene_war:build_box(info, map_id, pos)
	local box_obj = g_obj_mgr:create_box(nil, nil, pos, {map_id, nil})
	for _, v in pairs(info.item_list) do
		for i = 1, v.count do
			local _, item_obj = Item_factory.create(v.id)
			if item_obj then
				box_obj:add_comm_item(item_obj)
			end
		end
	end
	self:enter_scene(box_obj)
	return box_obj
end

function Scene_war:clean_object(now_time)
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

function Scene_war:on_timer(tm)
	Scene.on_timer(self, tm)
	
	local now_time = ev.time
	if now_time < self.end_time then
		self:clean_object(now_time)
	end
	
	self:do_relive(now_time)
end

function Scene_war:do_relive(now_time)
	local obj_mgr = g_obj_mgr
	for char_id, time in pairs(self.wait_relive) do
		local config = war_config.config[self.id]
		if time < now_time then
			local obj = obj_mgr:get_obj(char_id)
			if obj then
				self.wait_relive[char_id] = nil
				if not obj:is_alive() then
					local relive_list = config.relive
					local i = math.random(1, #relive_list)
					local pos = relive_list[i]
					obj:relive_and_convey(1, self.id, pos)
				end
			end
		end
	end
end

function Scene_war:notify_open(info, args)
	Scene.notify_open(self, info, args)
	self.end_time = info.end_time
	self.status = SCENE_STATUS.OPEN
	
	local config = g_scene_config_mgr:get_config(self.id)
	self.mode = config and config.mode or MAP_MODE_WAR
end

function Scene_war:notify_close(info, args)
	Scene.notify_close(self, info, args)
	self.status = SCENE_STATUS.CLOSE
	self.mode = MAP_MODE_PEACE

	local obj_mgr = g_obj_mgr
	
	for char_id, _ in pairs(self.wait_relive) do
		local config = war_config.config[self.id]
		local obj = obj_mgr:get_obj(char_id)
		if obj then
			self.wait_relive[char_id] = nil
			local map_obj = self:get_map_obj()
			local relive_list = config.relive
			local i = math.random(1, #relive_list)
			local pos = relive_list[i]
			obj:relive_and_convey(1, map_obj.id, pos)
		end
	end
	
	for obj_id, _ in pairs(self.monster_list) do
		local obj = obj_mgr:get_obj(obj_id)
		if obj then
			obj:leave()
		end
	end
	
	for obj_id, _ in pairs(self.npc_list) do
		local obj = obj_mgr:get_obj(obj_id)
		if obj then
			obj:leave()
		end
	end
	
	self.monster_list = {}
	self.npc_list = {}
	self.wait_relive = {}
	self.die_record = {}
end

function Scene_war:on_obj_enter(obj)
	if OBJ_TYPE_HUMAN == obj:get_type() then
		local obj_id = obj:get_id()
		self.wait_relive[obj_id] = nil
		self.exp_reward:del_addition(obj_id)
	end
end

function Scene_war:on_obj_leave(obj)
	if OBJ_TYPE_HUMAN == obj:get_type() then
		local obj_id = obj:get_id()
		if not obj:is_alive() then
			self.wait_relive[obj_id] = nil
			obj:do_relive(1, true)
		end
	end
end

function Scene_war:die_event(args)
	local killer_id = args.killer_id
	local obj_id = args.char_id
	local obj = self:get_obj(obj_id)
	if obj then
		self.die_record[obj_id] = (self.die_record[obj_id] or 0) + 1
		self.wait_relive[obj_id] = ev.time + 5			--加入等待复活列表
		self.exp_reward:del_addition(obj_id)
		
		args.mode = 1
		args.is_notify = false
		args.is_evil = false
		args.relive_time = math.max(self.wait_relive[obj_id] - ev.time, 0)
		
		local killer = killer_id and self:get_obj(killer_id)
		if killer and OBJ_TYPE_HUMAN == killer:get_type() then					--被玩家杀死
			killer:add_war_kill()
			local killer_id = killer:get_id()
			self.exp_reward:add_addition(killer_id, 1)
			local kill_number = self.exp_reward:get_addition(killer_id)
			local honor = war_config.config[self.id].honor[kill_number]
			if honor and honor.text then
				local msg = {}
				f_construct_content(msg, string.format(honor.text, killer:get_name()), 16)
				f_cmd_sysbd(msg)
			end
		end
	end
end