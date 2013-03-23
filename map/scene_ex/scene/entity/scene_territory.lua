--local debug_print = print
local debug_print = function() end
local territory_config = require("scene_ex.config.territory_config_loader")
local _random = crypto.random

Scene_territory = oo.class(Scene_instance, "Scene_territory")

local KICK_OUT_ADD = 30
local NOTIFY_BOSS_TIME = 1
local _m_l = {[1529]=1, [1530]=1, [1527]=1, [1528]=1}

function Scene_territory:__init(territory_copy, territory_id, map_id, instance_id, map_obj)
	Scene_instance.__init(self, map_id, instance_id, map_obj)
	self.territory_copy = territory_copy
	self:reset_end_time(60)	--初始化时间
	self.is_end = nil		--是否已经结束战斗
	self.key = {territory_id, instance_id, map_id}
	self.wait_relive = {}	--等待复活列表
	self.relive_each_time = self:get_self_config().relive.time
	self.relive_timer = ev.time + self.relive_each_time
	self.relive_type = -1
	self.winner_side = 2	--胜利方，默认为防守方
	self.is_update = nil	--是否刷新怪物
	--怪物刷新
	self.boss_id = {}		--[1]进攻方，[2]为防御方
	self.update_boss = {}	--刷出boss时间
	self.notify_boss_time = ev.time + NOTIFY_BOSS_TIME
	self.notify_monster_l = {}
	self.sequence = {0, 0}	--[1]进攻方，[2]为防御方
	self.area_list = {{}, {}}
	self.area_monster = {{}, {}}
	
	self.repeat_create = {}	-- 循环刷的怪的配置
	local scene_c = self:get_self_scene_config()
	if scene_c.wild then
		self.repeat_monster = {}
		self.monster_id_to_area = {}
		for i = 1, 2 do
			self.repeat_create[i] = scene_c.wild[i] and scene_c.wild[i].repeat_create
			if self.repeat_create[i] then
				self.repeat_monster[i] = {}
				for k, v in pairs(self.repeat_create[i]) do
					self.repeat_monster[i][k] = {}
					self.repeat_monster[i][k].size = 0			--记录已经刷出多少只这种怪
					self.repeat_monster[i][k].time = ev.time	--记录下次要刷出的时间
					if self.repeat_create[i].area_t ~= nil then
						self.repeat_monster[i][k].area_t = 0			--记录下每个区域怪的个数
					end
				end
				self.monster_id_to_area[i] = {}	--每个怪的ID对应的区域
			end
		end		
	end

	self.belong = scene_c.belong
	--通知客户端出怪时间
	self.notify_update_list = {}

	--加经验相关
	local config = self:get_self_config()
	self.exp = config.exp
	self.exp_time = ev.time
end

function Scene_territory:instance()
	debug_print("Scene_territory:instance()")
	local config = self:get_self_config()
	self.end_time = ev.time + 100
	self.start_time = ev.time
	self.close_time = self.end_time
	self.kick_out_time = self.end_time + KICK_OUT_ADD
	self.next_time = {self.start_time, self.start_time}
	self.obj_mgr:instance(self.map_obj:get_w(), self.map_obj:get_h())

	--self.territory_copy:reset_end_time(scene_c.timeout)
end

function Scene_territory:set_winner(side)
	f_scene_info_log("attacker win, side:%d", side)
	self.winner_side = side
end

function Scene_territory:get_self_config()
	return territory_config.config[self.key[1]]
end

function Scene_territory:get_self_scene_config()
	if self.scene_config then return self.scene_config end
	local config = territory_config.config[self.key[1]]
	for k, v in ipairs(config.scene_layer) do
		if v.map == self.key[3] then
			self.scene_config = v
			return v
		end
	end
end

--副本出口
function Scene_territory:get_home_carry(obj)
	local config = self:get_self_config()
	local home_carry = config and config.home
	if not home_carry or not home_carry.id
		or not home_carry.pos or not home_carry.pos[1] or not home_carry.pos[2] then
		return nil, nil
	end
	return home_carry.id, home_carry.pos
end

function Scene_territory:carry_scene(obj, pos)
	debug_print("Scene_territory:carry_scene:pos")
	if not obj then
		return SCENE_ERROR.E_NOT_ON_SCENE, nil
	end

	local human = config and config.limit and config.limit.human
	if human and human.max and human.max < self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN):get_obj_count() + 1 then
		return SCENE_ERROR.E_FACTION_HUMAN_MAX, nil
	end
	-- 加其它判断条件

	return self:push_scene(obj, pos)
end

function Scene_territory:reset_end_time(time)
	debug_print("Scene_territory:reset_end_time", time)
	self.start_time = ev.time
	self.end_time = self.start_time + time
	self.close_time = self.end_time
	self.kick_out_time = self.end_time + KICK_OUT_ADD
end

function Scene_territory:the_end(time)
--[[
	local pkt = {}
	pkt.faction_id = self.instance_id
	pkt.switch_flag = 0
	pkt.scene_id = self.id
	g_faction_mgr:switch_fb(pkt)
]]
	self:add_remain_exp()
	self.is_end = true
	self:do_relive(true)
	self.kick_out_time = ev.time + time--KICK_OUT_ADD
	self.close_time = self.kick_out_time
	self:set_update_wild(false)
	if self.obj_mgr then

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

function Scene_territory:next_sequence(side)
	debug_print("===> Scene_territory:next_sequence:", side)

	self.sequence[side] = self.sequence[side] + 1

	local config = self:get_self_config()
	local scene_c = self:get_self_scene_config()
	local wild = scene_c.wild

	local freq = wild and wild[side] and wild[side][self.sequence[side]]
	if not freq or not freq.interval then
		self.next_time[side] = ev.time + 1000000000
		return
	end
	self.next_time[side] = ev.time + freq.interval
	
	if freq.sequence then
		local new_list = {}
		for _, item in pairs(freq.sequence) do
			local area = item.area
			local info = self.area_list[side][area]
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
			sequence.path = scene_c.born and scene_c.born[item.path]
			sequence.target = item.target
			new_list[area] = sequence
		end
		self.area_list[side] = new_list
	end
end

function Scene_territory:update_wild(side)
	local obj_mgr = g_obj_mgr
	local now = ev.time
	
	for area, sequence in pairs(self.area_list[side] or {}) do
		if sequence.timeout <= now then
			local config = self:get_self_config()
			while sequence.count < sequence.max do 
				local pos = self.map_obj:find_space(area, 20)
				if pos then
					local obj_monster = self:create_monster(side, sequence.id, pos, sequence.path, sequence.target)
					if not obj_monster then break end
					self.area_monster[side][obj_monster:get_id()] = area
					sequence.count = sequence.count + 1
				else
					break
				end
			end
			sequence.timeout = sequence.timeout + sequence.interval
		end
	end
end

function Scene_territory:update_repeat_monster(side)
	if not self.repeat_create[side] then return end
	local is_update_notify_list = nil
	for k, v in ipairs(self.repeat_monster[side]) do
		if v.time < ev.time then
			local entry = self.repeat_create[side][k]
			for i = 1, entry.number do
				local pos = self.map_obj:find_space(entry.area, 20)
				if pos and v.size < (self.repeat_create[side][k].total or 10000000)
				and ( v.area_t == nil or v.area_t < (self.repeat_create[side][k].area_t or 10000000)) then
					v.size = v.size + 1
					local path = nil
					if entry.path then
						local born = self:get_self_scene_config().born
						path = born and born[entry.path]
					end
					local monster_obj = self:create_monster(side, entry.id, pos, path, entry.target)
					if monster_obj == nil then break end

					if entry.area_t ~= nil then
						v.area_t = (v.area_t or 0) + 1
						self.monster_id_to_area[side][monster_obj:get_id()] = k
					end
				end
			end
			v.time = ev.time + entry.interval
			--通知更新列表
			if entry.notify and entry.notify == 1 then
				if v.size < (self.repeat_create[side][k].total or 10000000) then
					is_update_notify_list = true
					self:set_notify_update_list(entry.id, entry.interval, side)
				--else
					--self:set_notify_update_list(entry.id, 0, side)
				end
			end
		end
	end

	if is_update_notify_list then
		self:monster_notify_update_time(nil)
	end
end

function Scene_territory:create_monster(side, monster_id, pos, path, target)
	local args = nil
	if path then
		args = {path.path}
	end
	local level = g_faction_territory:get_monster_level(side, monster_id)
	if level then
		args = args or {}
		args.level = level
	end

	local obj = g_obj_mgr:create_monster(monster_id, pos, self.key, args)
	--if self.is_end then
		--local temp_side = (self.winner_side == 1) and 2 or 1
		--obj:set_side(temp_side)
	--else
		obj:set_side(side)
	--end
	if self.boss_id[2] and side == 1 then
		local _ = obj.set_des_obj_id and obj:set_des_obj_id(self.boss_id[2])
	end
	if target then--搜索优先
		local _ = obj.set_prior_l and obj:set_prior_l({target})
	end
	if obj and SCENE_ERROR.E_SUCCESS == self:enter_scene(obj) then
		if _m_l[monster_id] then
			--table.insert(self.notify_monster_l, obj:get_id())
			self.notify_monster_l[obj:get_id()] = 1
		end
		--print("===>create monster: SCENE_ERROR.E_SUCCESS:")
		--广播
		--[[local bd = config.broadcast.occ[sequence.id]
		if bd and bd.enter then
			local msg = {}
			local bd_str = bd.enter
			f_construct_content(msg, bd_str, 13)
			f_cmd_sysbd(msg)
		end]]
		if monster_id == 1527 then
			self.relive_type = 1
		elseif monster_id == 1528 then
			self.relive_type = 2
		end
		return obj
	end
	
end

function Scene_territory:create_boss()
	for k, v in pairs(self.update_boss or {}) do
		if v <= ev.time then
			local scene_c = self:get_self_scene_config()
			local boss = scene_c.boss[k]
			if boss then
				f_scene_info_log("key:%s,%s,%d create boss, boss_id:%d, pos:%d,%d", 
							self.key[1], self.key[2], self.key[3], boss[1], boss[2][1], boss[2][2])
				local args = nil
				local level = g_faction_territory:get_monster_level(k, boss[1])
				if level then
					args = {}
					args.level = level
				end
				local obj = g_obj_mgr:create_monster(boss[1], boss[2], self.key, args)
				self.boss_id[k] = obj:get_id()
				obj:set_side(k)
				self:enter_scene(obj)
				self.update_boss[k] = nil
			end
		end
	end
	-- 如果双方都有boss,则先攻击boss
	if self.boss_id[1] and self.boss_id[2] then
		local boss1 = g_obj_mgr:get_obj(self.boss_id[1])
		local boss2 = g_obj_mgr:get_obj(self.boss_id[2])
		if boss1 and boss2 then
			boss1:set_des_obj_id(self.boss_id[2])
			boss2:set_des_obj_id(self.boss_id[1])
		end
	end
end

function Scene_territory:on_timer(tm)

	local now = ev.time
	if self.end_time and self.end_time < now and not self.is_end then
		self.territory_copy:to_end()
	end

	if self.kick_out_time and self.kick_out_time < now then
		self.territory_copy:to_kick_out()
	end

	if self.is_end and self.close_time < now then
		self.territory_copy:to_close()
	end

	if not self.is_end and self.exp and self.exp_time + self.exp.time <= ev.time then
		self.exp_time = ev.time
		self:add_exp()
	end

	if self.is_update then
		self:create_boss()
		if not self.is_end or self.winner_side == 2 then
			if self.next_time[1] <= now then
				self:next_sequence(1)
			end
			self:update_wild(1)
			self:update_repeat_monster(1)
		end

		if not self.is_end or self.winner_side == 1 then
			if self.next_time[2] <= now then
				self:next_sequence(2)
			end
			self:update_wild(2)
			self:update_repeat_monster(2)
		end

		if self.notify_boss_time < ev.time then
			self.notify_boss_time = ev.time + NOTIFY_BOSS_TIME
			local _ = self.notify_boss_hp and self:notify_boss_hp()
		end
	end
 
 	-- 玩家复活
	if self.relive_timer <= now then
		self:do_relive()
		self.relive_timer = now + self.relive_each_time
	end

	self.obj_mgr:on_timer(tm)

	--通知更新列表
	local _ = self.territory_copy.update_enter_list and self.territory_copy:update_enter_list()
end

-- 开始更新（刷怪）
function Scene_territory:set_update_wild(is_update)
	--print("Scene_territory:set_update_wild()", is_update)
	self.is_update = is_update

	if self.is_update then
		local scene_c = self:get_self_scene_config()
		if scene_c.boss then   --刷出boss
			self.update_boss[1] = scene_c.boss[1] and (scene_c.boss[1][3] + ev.time)
			self.update_boss[2] = scene_c.boss[2] and (scene_c.boss[2][3] + ev.time)
		end
		--杀死后有归属的怪
		if self.belong then
			for k, v in pairs(self.belong.begin or {}) do
				local obj = self:create_monster(v[4], v[1], {v[2], v[3]})
				if obj then
					if _m_l[v[1]] then
						--table.insert(self.notify_monster_l, obj_m2:get_id())
						self.notify_monster_l[obj:get_id()] = 1
					end
				end
			end
		end
	end

	local _ = self.clear_notify_update_list and self:clear_notify_update_list()
	if self.is_update and self.clear_notify_update_list then
		
		local scene_c = self:get_self_scene_config()
		for k, v in pairs(scene_c.boss or {}) do
			if v[4] == 1 then
				self:set_notify_update_list(v[1], v[3], k)
			end
		end

		--
		for i = 1, 2 do
			for k, v in pairs(self.repeat_create[i] or {}) do
				if v.notify and v.notify == 1 then
					self:set_notify_update_list(v.id, v.interval, i)
				end
			end
		end

	end
end

function Scene_territory:get_last_time(obj)
	return math.max(self.end_time - ev.time, 0)
end

function Scene_territory:on_obj_enter(obj)
	if obj:get_type() == OBJ_TYPE_HUMAN then
		if self.territory_copy:is_attacker(obj) then
			obj:set_side(1)
		else
			obj:set_side(2)
		end
		local obj_id = obj:get_id()
		g_scene_mgr_ex:register_event(EVENT_SET.EVENT_OUT_FACTION, obj_id, self, self.out_faction_event)
		g_scene_mgr_ex:register_event(EVENT_SET.EVENT_KILL_MONSTER, obj_id, self, self.kill_monster_event)
		self.wait_relive[obj_id] = nil
		local _ = self.monster_notify_update_time and self:monster_notify_update_time(obj_id)
	end
end

function Scene_territory:on_obj_leave(obj)
	local obj_id = obj:get_id()
	-- 消灭防方boss,可以进入下一层
	if obj_id == self.boss_id[2] and not self.is_end then
		f_scene_info_log("key:%s,%s,%d boss %d leave",
							self.key[1], self.key[2], self.key[3], obj_id)
		self.boss_id[2] = nil
		self.territory_copy:attack_layer_increase()
		return
	end
	if obj:get_type() == OBJ_TYPE_HUMAN then
		local _ = self.territory_copy.obj_leave and self.territory_copy:obj_leave(obj_id)
		g_scene_mgr_ex:unregister_event(EVENT_SET.EVENT_OUT_FACTION, obj_id)
		g_scene_mgr_ex:unregister_event(EVENT_SET.EVENT_KILL_MONSTER, obj_id)
		obj:set_side(0)
		self.wait_relive[obj_id] = nil
	elseif obj:get_type() == OBJ_TYPE_MONSTER then
		if obj_id == self.boss_id[1] then
			self.boss_id[1] = nil
		end
		local side = obj:get_side()
		local area = self.area_monster[side][obj_id]
		if area then
			local sequence = self.area_list[side][area]
			if sequence then
				sequence.count = math.max(sequence.count - 1, 0)
			end
		end

		local area_to_k = self.monster_id_to_area and self.monster_id_to_area[side] and self.monster_id_to_area[side][obj_id]
		if area_to_k then 
			self.repeat_monster[side][area_to_k].area_t = (self.repeat_monster[side][area_to_k].area_t or 0) - 1
		end
		
		--是否有归属的怪
		local belong_m = self.belong and self.belong.m_list[obj:get_occ()]
		if belong_m and not self.is_end then
			local oth_side = obj:get_side() == 1 and 2 or 1
			local obj_m2 = self:create_monster(oth_side, belong_m[1], belong_m[2])
			if obj_m2 then
				if _m_l[belong_m[1]] then
					--table.insert(self.notify_monster_l, obj_m2:get_id())
					self.notify_monster_l[obj_m2:get_id()] = 1
				end
			end
		end
		obj:set_side(0)
	end
end

function Scene_territory:get_mode()
	local config = g_scene_config_mgr:get_config(self.key[1])
	return config and config.mode
end


function Scene_territory:relive_human(obj)
	if obj:is_alive() then
		return
	end
	local relive_type = 0
	if obj:get_side() == self.relive_type then
		relive_type = 2
	end 
	local relive_pos_l = self.territory_copy:get_relive_pos(obj, relive_type)
	local pos = relive_pos_l[self.id]
	obj:do_relive(1, true)	--复活
	obj:send_relive(3)
	if self.is_end then
		return
	elseif pos[1] == self.id then
		local map_o = self:get_map_obj()
		local cur_pos = pos[2]
		local pos_m = {cur_pos[1]-5,cur_pos[1]+5,cur_pos[2]-5,cur_pos[2]+5}
		local new_pos = map_o:find_pos(pos_m)
		self:transport(obj, new_pos)
	else
		self.territory_copy:carry_scene(obj, pos)
	end

	--self:init_side_state(obj)
end

function Scene_territory:do_relive(is_force)
	--debug_print("Scene_territory:do_relive")
	local obj_mgr = g_obj_mgr
	local now_time = ev.time
	for char_id, r_time in pairs(self.wait_relive) do
		if is_force or now_time >= r_time then
			self.wait_relive[char_id] = nil
			local obj = obj_mgr:get_obj(char_id)
			if obj then
				self:relive_human(obj)
			end
		end
	end
end

function Scene_territory:die_event(args)
	--debug_print("Scene_territory:die_event:")

	args.mode = 1
	args.is_notify = false
	args.is_evil = false
	args.relive_time = self.relive_timer - ev.time + self.relive_each_time
	
	self.wait_relive[args.char_id] = self.relive_timer + self.relive_each_time
	--计分
	--self.territory_copy:build_score(args.killer_id, args.char_id, 2)
end

function Scene_territory:kill_monster_event(monster_id, obj_id)
	--计分
	--self.territory_copy:build_score(obj_id, monster_id, 1)
	--广播
--[[	local config = self:get_self_config()
	local bd = config.broadcast.occ[monster_id]
	if bd and bd.leave then
		local msg = {}
		local bd_str = bd.leave
		f_construct_content(msg, bd_str, 13)
		f_cmd_sysbd(msg)
	end
]]
end

function Scene_territory:out_faction_event(obj_id)
	if obj_id then
		self:kickout(obj_id)
	end
end

function Scene_territory:kick_out()
	debug_print("Scene_territory_battle_entity:kick_out()", self.id)
	self.kick_out_time = ev.time + 9999999
	self.territory_copy:open_reward_scene(self.id)
	local config = self:get_self_config()
	if self.obj_mgr then
		local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
		if con then
			
			local pos = {config.scene_layer[3].map, config.scene_layer[3].entry}
			for obj_id, _ in pairs(con:get_obj_list()) do
				local obj = g_obj_mgr:get_obj(obj_id)
				local side = obj:get_side()
				if self.winner_side ~= side then
					self:kickout(obj_id)
				else
					f_scene_info_log("key:%s,%s,%d carry %d to scene:%d",
							self.key[1], self.key[2], self.key[3], obj_id, pos[1])
					self.territory_copy:push_scene(obj, pos)
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

function Scene_territory:add_exp()
	if self.obj_mgr then
		local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
		if con then
			for obj_id, _ in pairs(con:get_obj_list()) do
				local obj = g_obj_mgr:get_obj(obj_id)
				local power = math.min(self.territory_copy:get_score(obj), 300) * self.exp.factor * (obj:get_level() / 30)^2
				obj:add_exp(math.floor(self.exp.base * (1 + power + (obj:get_addition(HUMAN_ADDITION.other_exp) or 0) )))
			end
		end
	end
end

function Scene_territory:add_remain_exp()
	if self.exp and self.obj_mgr then
		local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
		if con then
			local s = math.floor(self:get_last_time() / self.exp.time)
			for obj_id, _ in pairs(con:get_obj_list()) do
				local obj = g_obj_mgr:get_obj(obj_id)
				local power = math.min(self.territory_copy:get_score(obj), 300) * self.exp.factor * (obj:get_level() / 30)^2
				obj:add_exp(math.floor(self.exp.base * (1 + power + (obj:get_addition(HUMAN_ADDITION.other_exp) or 0) )) * s)
			end
		end
	end
end

--------------------------------------------------------------------------------

--帮派领地攻防战实例
Scene_territory_battle_entity = oo.class(Scene_territory, "Scene_territory_battle_entity")


function Scene_territory_battle_entity:__init(territory_copy, territory_id, map_id, instance_id, map_obj)
	Scene_territory.__init(self, territory_copy, territory_id, map_id, instance_id, map_obj)
	
	debug_print("====> Scene_territory_battle_entity:__init")
end


function Scene_territory_battle_entity:die_event(args)
	--debug_print("Scene_territory:die_event:")

	args.mode = 1
	args.is_notify = false
	args.is_evil = false
	args.relive_time = self.relive_timer - ev.time + self.relive_each_time
	
	self.wait_relive[args.char_id] = self.relive_timer + self.relive_each_time
	if Obj_mgr.obj_type(args.killer_id) == OBJ_TYPE_HUMAN	then
		--
		local event_args = {}
		event_args.count = 1
		g_event_mgr:notify_event(EVENT_SET.EVENT_MANOR_KILL, args.killer_id, event_args)
		--计分
		self.territory_copy:build_score(args.killer_id, args.char_id, 2)
		local obj = g_obj_mgr:get_obj(args.killer_id)
		local scene_o = obj:get_scene_obj()
		local map_obj = scene_o:get_map_obj()
		local oth_side = obj:get_side() == 1 and 2 or 1
		local obj_list = map_obj:monster_scan_obj_side(obj:get_pos(), 15, 50, oth_side)
		local obj_len = table.size(obj_list)
		for k,v in pairs(obj_list) do
			if Obj_mgr.obj_type(k) == OBJ_TYPE_HUMAN then
				self.territory_copy:build_score(k, args.char_id, 4, obj_len)
			end
		end
	end
end

function Scene_territory_battle_entity:kill_monster_event(monster_id, obj_id)
	--print("Scene_territory_battle_entity:kill_monster_event()", monster_id, obj_id)
	local config = self:get_self_config()
	--加buff
	local buff = config.buff_monster and config.buff_monster[monster_id]
	local obj = g_obj_mgr:get_obj(obj_id)
	if buff and obj then
		local side = obj:get_side()
		self.territory_copy:add_buff_to_side(side, buff[1], buff[2], buff[3], buff[4])
	end
	--计分
	self.territory_copy:build_score(obj_id, monster_id, 1)
	local scene_o = obj:get_scene_obj()
	local map_obj = scene_o:get_map_obj()
	local oth_side = obj:get_side() == 1 and 2 or 1
	local obj_list = map_obj:monster_scan_obj_side(obj:get_pos(), 15, 50, oth_side)
	local obj_len = table.size(obj_list)
	for k,v in pairs(obj_list) do
		if Obj_mgr.obj_type(k) == OBJ_TYPE_HUMAN then
			self.territory_copy:build_score(k, monster_id, 3, obj_len)
		end
	end

--[[	--广播
	local config = self:get_self_config()
	local bd = config.broadcast.occ[monster_id]
	if bd and bd.leave then
		local msg = {}
		local bd_str = bd.leave
		f_construct_content(msg, bd_str, 13)
		f_cmd_sysbd(msg)
	end
	]]
end

--[[
function Scene_territory_battle_entity:f_broadcast_faction(type)
	local pk = {}
	pk.type	= 31
	g_svsock_mgr:send_server_ex(WORLD_ID, 0, CMD_C2W_FACTION_TERRITORY_S, pk)
	return 0
end
]]


function Scene_territory_battle_entity:notify_boss_hp()
	if self.obj_mgr then
		local pkt = {}
		local boss_1 = self.boss_id[1] and g_obj_mgr:get_obj(self.boss_id[1])
		local entry1 =  boss_1 and {boss_1:get_occ(), boss_1:get_hp(), boss_1:get_max_hp(), 1}
		local boss_2 = self.boss_id[2] and g_obj_mgr:get_obj(self.boss_id[2])
		local entry2 =  boss_2 and {boss_2:get_occ(), boss_2:get_hp(), boss_2:get_max_hp(), 2}
		if entry1 == nil and entry2 == nil then return end
		local _ = entry1 and table.insert(pkt, entry1)
		local _ = entry2 and table.insert(pkt, entry2)

		for k, v in pairs(self.notify_monster_l or {}) do
			local obj_m = g_obj_mgr:get_obj(k)
			if obj_m == nil then
				--table.remove(self.notify_monster_l, k)
				self.notify_monster_l[k] = nil
			else
				local entry_m = {obj_m:get_occ(), obj_m:get_hp(), obj_m:get_max_hp(), obj_m:get_side()}
				table.insert(pkt, entry_m)
			end
		end

		local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
		if con then
			for obj_id, _ in pairs(con:get_obj_list()) do
				self:send_human(obj_id, CMD_TERRITORY_UPDATE_BOSS_HP_S, pkt)
			end
		end
	end
end

--设置要通知客户端要出现的怪物
function Scene_territory_battle_entity:set_notify_update_list(occ, time, side)
	debug_print("Scene_territory_battle_entity:set_notify_update_list()", occ, time, side)
	self.notify_update_list[occ] = {occ, side, ev.time + time}
end

function Scene_territory_battle_entity:clear_notify_update_list()
	self.notify_update_list = {}
end

--通知更新怪物出现时间
function Scene_territory_battle_entity:monster_notify_update_time(chat_id)
	debug_print("Scene_territory_battle_entity:monster_notify_update_time()")
	local pkt = {}
	for k, v in pairs(self.notify_update_list) do
		if v[3] < ev.time then
			self.notify_update_list[k] = nil
		else
			table.insert(pkt, {v[1], v[2], v[3] - ev.time})
		end
	end
	if char_id and #pkt > 0 then
		self:send_human(chat_id, CMD_TERRITORY_UPDATE_MONSTER_TIME_S, pkt)
		return
	end
	if self.obj_mgr and #pkt > 0 then
		local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
		if con then
			for obj_id, _ in pairs(con:get_obj_list()) do
				self:send_human(obj_id, CMD_TERRITORY_UPDATE_MONSTER_TIME_S, pkt)
			end
		end
	end
end

function Scene_territory_battle_entity:is_attack(attacker_id, defender_id)
	local scene_mode = g_scene_config_mgr:get_mode(self:get_mode())
	if not scene_mode then
		return SCENE_ERROR.E_INVALID_ID
	end
	
	local attacker = self:get_obj(attacker_id)
	if not attacker then
		return SCENE_ERROR.E_NOT_ON_SCENE
	end
	
	local defender = self:get_obj(defender_id)
	if not defender then
		return SCENE_ERROR.E_NOT_ON_SCENE
	end
	
	if Obj_mgr.obj_type(defender_id) == OBJ_TYPE_HUMAN and self.is_end then
		return SCENE_ERROR.E_ATTACK_BAN
	end

	return scene_mode:can_attack(attacker, defender)
end