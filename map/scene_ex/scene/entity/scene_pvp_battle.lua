local pvp_config = require("scene_ex.config.pvp_battle_loader")

local config = pvp_config.config

local _random = crypto.random

Scene_pvp_battle = oo.class(Scene_instance, "Scene_pvp_battle")

function Scene_pvp_battle:__init(map_id, instance_id, map_obj, copy_id, interval, end_time)
	Scene_instance.__init(self, map_id, instance_id, map_obj)

	self.wait_relive = {}
	self.human_count = 0
	self.all_human_count = 0
	self.all_human_list = {}
	self.max_human_count = config.limit.count or 50

	self.status = SCENE_STATUS.OPEN
	self.open_time = end_time - interval
	self.start_time = ev.time
	self.close_time = nil
	self.clear_time = end_time
	self.end_time = end_time
	self.boss_order = 1
	self.copy_id = copy_id
	self.area_list = {}
	self.area_monster = {}

	self.collect_area_list = {}
	self.area_collect = {}

	self.human_list = {}
	self.boss_id = nil
	self.kill_boss = 0
	self.check_boss_time = ev.time + 10
	self.wild_config = nil
end

function Scene_pvp_battle:instance()
	self.obj_mgr:instance(self.map_obj:get_w(), self.map_obj:get_h())

	self.world_lvl = g_world_lvl_mgr:get_average_level()
	if self.world_lvl == -1 then
		self.world_lvl = g_world_lvl_mgr:get_average_level()
		if self.world_lvl == -1 then
			print("Error: world level not init")
			self.world_lvl = 65 
		end
	end
	local lvl = math.floor(self.world_lvl/10) * 10
	
	self.world_lvl = lvl
	local wild_config = config.wild[lvl]
	self.boss_occ = wild_config.boss[1].id
	self.wild_config = wild_config
	local monster = wild_config.monster
	self.monster_time = ev.time
	for k, v in pairs(monster or {}) do
		local wild = {}
		wild.id = v.id
		wild.interval = v.interval
		wild.count = 0
		wild.max_count = v.number
		self.area_list[v.area] = wild
	end

	local collect = wild_config.collect
	self.collect_time = ev.time
	for k, v in pairs(collect or {}) do
		local wild = {}
		wild.id = v.id
		wild.interval = v.interval
		wild.count = 0
		wild.max_count = v.number
		self.collect_area_list[v.area] = wild
	end

	self.boss_list =  config.wild[lvl].boss 
	self.boss_count = config.wild[lvl].boss_count
	self.boss_order = self:get_boss_order()
	--刷出采集物
	--self:create_collect()
end

function Scene_pvp_battle:get_boss_order()
	for i = 1, self.boss_count do
		if self.boss_list[i].time + self.open_time > ev.time then
			return i
		end
	end
	return self.boss_count + 1
end

function Scene_pvp_battle:get_mode()
	if SCENE_STATUS.OPEN == self.status then
		local scene_config = g_scene_config_mgr:get_config(self.id)
		return scene_config and scene_config.mode
	end
	return SCENE_MODE.PEACE
end

--副本出口
function Scene_pvp_battle:get_home_carry(obj)
	local home_carry = config and config.home
	if not home_carry or not home_carry.id or not home_carry.pos 
			or not home_carry.pos[1] or not home_carry.pos[2] then
		return nil, nil
	end
	return home_carry.id, home_carry.pos
end

function Scene_pvp_battle:get_human_list()
	return self.human_list
end

function Scene_pvp_battle:on_obj_enter(obj)
	if not obj then 
		return 
	end
	if OBJ_TYPE_HUMAN == obj:get_type() then
		self.human_count = self.human_count + 1
		local char_id = obj:get_id()
		self.human_list[char_id] = char_id
		if not self.all_human_list[char_id] then
			self.all_human_count = self.all_human_count + 1
			self.all_human_list[char_id] = char_id
		end
		f_prop_god(obj, config.limit.god)
		f_prop_silence(obj, config.limit.god)
		local pkt = {}
		local copy_info = {}
		copy_info[self.copy_id] = self.human_count
		pkt.limit = config.limit.count
		pkt.copy_info = copy_info
		pkt.copy_id = self.copy_id
		g_cltsock_mgr:send_client(char_id, CMD_MAP_PVP_BATTLE_COPY_INFO_S , pkt)
	end
end

function Scene_pvp_battle:on_obj_leave(obj)
	local type = obj:get_type()
	local obj_id = obj:get_id()
	if OBJ_TYPE_HUMAN == type then
		self.human_count = math.max(self.human_count - 1, 0)
		self.human_list[obj_id] = nil
		if not obj:is_alive() then
			self.wait_relive[obj_id] = nil
			obj:do_relive(1, true)
		end
		f_del_impact(obj, 1401)
	elseif OBJ_TYPE_MONSTER == type then
		if self.boss_id == obj_id then
			self.kill_boss = self.kill_boss + 1
			self.boss_id = nil
		end
		local area = self.area_monster[obj_id]
		if area then
			local sequence = self.area_list[area]
			if sequence then
				sequence.count = math.max(sequence.count - 1, 0)
			end
		end
	elseif OBJ_TYPE_NPC == type then
		local area = self.area_collect[obj_id]
		if area then
			local sequence = self.collect_area_list[area]
			if sequence then
				sequence.count = math.max(sequence.count - 1, 0)
			end
		end
	end
end

function Scene_pvp_battle:can_carry(obj)
	local obj_id = obj:get_id()
	local level_limit = config.limit.level
	if level_limit then
		local level = obj:get_level()
		if level_limit.min > level or level_limit.max < level then
			return SCENE_ERROR.E_LEVEL_LIMIT, nil
		end
	end
	return SCENE_ERROR.E_SUCCESS
end


function Scene_pvp_battle:carry_scene(obj, pos)
	
	if not pos then
		local entry = config.entry
		local rand = _random(1, #entry + 1)
		pos = config.entry[rand]
		--pos = {51, 61}
	end
	return self:push_scene(obj, pos)
end



function Scene_pvp_battle:get_name()
	local scene_config = g_scene_config_mgr:get_config(self.id)
	return string.format("%s%s", 
		tostring(scene_config and scene_config.name), tostring(copy_id))
end

function Scene_pvp_battle:get_human_count()
	return self.human_count, self.max_human_count
end

--判断能否进入
function Scene_pvp_battle:check_in()
	return self.human_count < self.max_human_count
end

function Scene_pvp_battle:update_wild()
	local obj_mgr = g_obj_mgr
	local now = ev.time
	self.monster_time = self.monster_time + self.wild_config.monster_interval
	for area, monster in pairs(self.area_list) do
		while monster.count < monster.max_count do
			local pos = self.map_obj:find_space(area, 20)
			if pos then
				local obj = obj_mgr:create_monster(monster.id, pos, self.key)
				if obj and SCENE_ERROR.E_SUCCESS == self:enter_scene(obj) then
					obj:set_last_kill(true)
					self.area_monster[obj:get_id()] = area
					monster.count = monster.count + 1
				else
					print("Error:not obj or enter scene error")
					break
				end
			else
				break
			end
		end
	end
end

function Scene_pvp_battle:update_collect()
	local obj_mgr = g_obj_mgr
	local now = ev.time
	self.collect_time = self.collect_time + self.wild_config.collect_interval
	for area, collect in pairs(self.collect_area_list) do
		while collect.count < collect.max_count do
			local pos = self.map_obj:find_space(area, 20)
			if pos then
				local obj = g_obj_mgr:create_npc(collect.id, "", pos, self.key, nil)
				if obj and SCENE_ERROR.E_SUCCESS == self:enter_scene(obj) then
					self.area_collect[obj:get_id()] = area
					collect.count = collect.count + 1
				else
					print("Error:not obj or enter scene error")
					break
				end
			else
				break
			end
		end
	end
end

function Scene_pvp_battle:create_collect()
	local obj_mgr = g_obj_mgr
	local wild = config.wild[self.world_lvl]
	local collect_info = wild.collect
	if not collect_info then 
		print("Error:config not exist collect_info")
		return 
	end
	local map_obj = self:get_map_obj()
	for _, collect in pairs(collect_info) do
		for i = 1, collect.number do
			local area = collect.area
			local pos = map_obj:find_space(collect.area, 20)
			if pos then
				local obj = g_obj_mgr:create_npc(collect.id, "", pos, self.key, nil)
				self:enter_scene(obj)
			end
		end
	end
end

--世界等级
function Scene_pvp_battle:create_boss(boss_info, order)
	local obj_mgr = g_obj_mgr
	local map_obj = self:get_map_obj()
	local area = boss_info.area
	if self.boss_id then 
		return
	end
	for i = 1, boss_info.number do
		local pos = map_obj:find_space(boss_info.area, 20)
		if pos then
			local obj = obj_mgr:create_monster(boss_info.id, pos, self.key)
			obj:set_last_kill(true)
			self:enter_scene(obj)
			self.boss_id = obj:get_id()
		end
	end
	self.boss_order = order + 1
end

function Scene_pvp_battle:check_boss()
	local now = ev.time
	if not self.boss_order or not self.boss_count or self.boss_order > self.boss_count then
		return 
	end
	for i = self.boss_order, self.boss_count do
		if self.boss_list[i].time + self.open_time < now then
			self:create_boss(self.boss_list[i], i)
			return
		end
	end
end



function Scene_pvp_battle:die_event(args)
	
	

	local killer_id = args.killer_id
	local obj_id = args.char_id
	local obj = self:get_obj(obj_id)
	local killer = self:get_obj(killer_id)
	if killer then
		local type = killer:get_type()
		if OBJ_TYPE_MONSTER ~= type then			
			if OBJ_TYPE_PET == type then
				killer_id = killer:get_owner_id()
			end
			local ret = {}
			ret.killer_id = killer_id
			g_event_mgr:notify_event(EVENT_SET.EVENT_NINE_PVP_DIE, obj_id, ret)
		end
	end
	
	local limit = config.limit
	if obj then
		self.wait_relive[obj_id] = ev.time + limit.rel_time			--加入等待复活列表
		obj:set_kill_status(0)
		
		args.mode = 5
		args.is_notify = false
		args.is_evil = false
		args.relive_time = limit.rel_time or 20
		
	end
end

function Scene_pvp_battle:on_timer(tm)
	
	local now = ev.time
	if self.clear_time <= now then
		if not self.close_time then
			self:clear_all_monster()
		elseif self.close_time <= now then
			self:close()
		end
		return
	
	elseif self.monster_time and self.monster_time <= now then
		self:update_wild()
	elseif self.collect_time and self.collect_time <= now then
		self:update_collect()
	end
	if self.check_boss_time <= now then
		self.check_boss_time = self.check_boss_time + 10
		self:check_boss()
	end
	self:do_relive(now)
	self.obj_mgr:on_timer(tm)

end

function Scene_pvp_battle:clear_all_monster()
	self.status = SCENE_STATUS.CLOSE
	self.close_time = self.clear_time + config.limit.clear
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
	local pkt = {}
	pkt.boss_id = self.boss_occ
	pkt.boss_count = self.kill_boss
	local new_pkt = Json.Encode(pkt)
	--
	local sql = string.format(
				"insert into log_jiuyou set start_time=%d, into_count=%d, time=%d, remark='%s'"
				, self.start_time
				, self.all_human_count
				, self.end_time
				, new_pkt)
	--]]--
	f_multi_web_sql(sql)
end

function Scene_pvp_battle:relive_human(obj)
	if obj:is_alive() then
		return
	end
	local limit = config.limit
	local r_pos = _random(1, limit.rel_pos_count + 1)
	local pos = limit.rel_pos[r_pos]
	obj:do_relive(1, true)	--复活
	obj:send_relive(config.limit.rel_time)
	
	self:transport(obj, pos)
	
	f_prop_god(obj, config.limit.god)
	f_prop_silence(obj, config.limit.god)
end

function Scene_pvp_battle:transport_ex(obj, pos)
	local limit = config.limit
	local r_pos = _random(1, limit.rel_pos_count + 1)
	local pos = limit.rel_pos[r_pos]
	self:transport(obj, pos)
	f_prop_god(obj, config.limit.god)
	f_prop_silence(obj, config.limit.god)
end

function Scene_pvp_battle:do_relive(now_time)
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

function Scene_pvp_battle:get_copy_id()
	return self.copy_id
end