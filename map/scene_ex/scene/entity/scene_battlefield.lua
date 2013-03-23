local battlefield_config = require("scene_ex.config.battlefield_config_loader")

local LAST_TIME = 10  --最后几秒开始倒数
local PREPARE_TIME = 100  --开始前的准备时间
local LEAVE_WAIT_TIME = 60	--离开后再次进入时间
local LEAVE_WAIT_CD_TIME = 120	--离开后1分钟内不回来的CD时间
local _random = crypto.random
local contraband_list = {
	[101030000021] = true
	, [101030000020] = true
	
	, [101030000121] = true
	, [101030000120] = true
	
	, [101030000221] = true
	, [101030000220] = true
	
	, [101030000321] = true
	, [101030000320] = true
	
	, [101030000421] = true
	, [101030000420] = true
	
	, [101030000521] = true
	, [101030000520] = true
	
	, [101030000621] = true
	, [101030000620] = true
	
	, [101030000721] = true
	, [101030000720] = true
	
	, [101030000821] = true
	, [101030000820] = true
	
	, [101030000921] = true
	, [101030000920] = true
	
	, [101030001021] = true
	, [101030001020] = true
}

Scene_battlefield = oo.class(Scene_instance, "Scene_battlefield")

function Scene_battlefield:__init(map_id, instance_id, map_obj, interval_time, map_config, is_level_break, player_record, final_end_time)
	Scene_instance.__init(self, map_id, instance_id, map_obj)

	self.is_level_break = is_level_break
	self.final_end_time = final_end_time
	self.side_list = {}
	self.side_count = {0, 0}
	self.wait_relive = {}
	self.rank = {}				--身份：0:正常，1:矿车，2:指挥官
	self.commander_id = {}		--指挥官的ID
	self.leave_player = {}		--已离开场景的玩家，等待他再次进入

	self.kill_record = {}		--连续杀人数，杀普通人数，杀指挥官数，助功数
	self.collect_record = {}	--收集小晶石数，收集神石数，占据点数
	self.collect_type = {}		--玩家收集在身上的资源类型
	self.exploit = {}			--玩家功勋值
	self.score = {0, 0}			--势力资源分
	self.player_record = player_record
	self.battlefield_record = {0,0,0,0,0,0}--战场流水，1采集神石的数量，2采集小晶矿的数量，3占据据点次数，4杀人数量，5助攻数量，6变矿车的次数

	self.status = SCENE_STATUS.IDLE
	self.open_time = ev.time
	self.freeze_time = self.open_time + interval_time
	local config = battlefield_config.config[self.id]
	self.close_time = self.freeze_time + config.limit.wait
	self.limit = config.limit
	self.npc_pos = {config.side[1].npc[2], config.side[2].npc[2]}
	self.stronghold_point = config.wild.stronghold_point.point
	self.stronghold_exploit_base = config.wild.stronghold_point.exploit_base
	self.stronghold_point_interval = config.wild.stronghold_point.interval
	self.exploit_factor = config.wild.exploit_factor
	self.stronghold_point_time = self.stronghold_point_interval + ev.time + PREPARE_TIME
	self.max_exploit = config.reward.max
	--
	self.is_last_time = false
	PREPARE_TIME = math.max(1, self.limit.prepare - LAST_TIME)
	LEAVE_WAIT_TIME = self.limit.hold
	LEAVE_WAIT_CD_TIME = self.limit.cd
	self.general_broadcast = ev.time + 200
	self.general_broadcast_type = 0

	local config = g_scene_config_mgr:get_config(self.id)
	self.scene_name = string.format("%s%s", tostring(config and config.name), tostring(map_config.name_id))
	
	self.side_channal = {
		g_chat_channal_mgr:new_channal()
		, g_chat_channal_mgr:new_channal()
	}
	
end

function Scene_battlefield:instance()

	self.obj_mgr:instance(self.map_obj:get_w(), self.map_obj:get_h())
	--
	-- 刷新水晶石
	local config = battlefield_config.config[self.id]
	self.crystal = config.wild.crystal
	self.crystal_occ_list = {}
	self.crystal_list = {}
	for k, v in ipairs(self.crystal or {}) do
		if self.crystal_occ_list[v.occ] == nil then
			self.crystal_occ_list[v.occ] = {}
		end
		self.crystal_occ_list[v.occ][v.area] = {0, ev.time + PREPARE_TIME}
	end
	self.crystal_update_time = ev.time + PREPARE_TIME
	-- 刷新神石
	self.diamond = config.wild.diamond
	self.diamond_occ_list = {}
	self.diamond_list = {}
	self.diamond_switch = {}	-- 开关，控制神石的刷新
	for k, v in ipairs(self.diamond or {}) do
		self.diamond_switch[k] = 0
		if self.diamond_occ_list[v.occ] == nil then
			self.diamond_occ_list[v.occ] = {}
		end
		self.diamond_occ_list[v.occ][v.area] = {0, ev.time + PREPARE_TIME}
	end
	self.diamond_update_time = ev.time + PREPARE_TIME
	-- 刷据点
	self.stronghold_list = {}
	self.stronghold_list_side = {0, 0, 0, 0, 0}
	self.stronghold_count = {0, 0}
	self.stronghold = config.wild.stronghold
	for k, v in ipairs(self.stronghold) do
		local pos = v.pos
		local obj = g_obj_mgr:create_npc(self.stronghold.occ, "", pos, self.key, nil)
		self.stronghold_list[obj:get_id()] = 0
		self:enter_scene(obj)
		obj:set_stronghold_type(k)
	end
	--守卫
	self:build_Heart()
end

--清除某个玩家的信息
function Scene_battlefield:clear_player(char_id)
	local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
	if self.side_list[char_id] ~= nil and not con:is_member(char_id) then
		local side = self.side_list[char_id]
		self.side_list[char_id] = nil
		self.side_count[side] = self.side_count[side] - 1
		self.rank[char_id] = nil
		self.kill_record[char_id] = nil
		self.collect_record[char_id] = nil
		self.collect_type[char_id] = nil
		self.exploit[char_id] = nil
		self.player_record[char_id][2] = ev.time + LEAVE_WAIT_CD_TIME
		if self.commander_id[side] == char_id then
			self.commander_id[side] = nil
		end
		--print("clear_player", char_id, self.side_count[1], self.side_count[2])
	end
end

function Scene_battlefield:get_name()
	return self.scene_name
end

function Scene_battlefield:get_mode()
	if SCENE_STATUS.OPEN == self.status then
		local config = g_scene_config_mgr:get_config(self.id)
		return config and config.mode
	end
	return SCENE_MODE.PEACE
end

function Scene_battlefield:can_use(item_id)
	if contraband_list[item_id] then
		return false
	end
	return true
end

--副本出口
function Scene_battlefield:get_home_carry(obj)
	local config = battlefield_config.config[self.id]
	local home_carry = config and config.home
	if not home_carry or not home_carry.id or not home_carry.pos or not home_carry.pos[1] or not home_carry.pos[2] then
		return nil, nil
	end
	return home_carry.id, home_carry.pos
end

function Scene_battlefield:get_last_time(obj)
	return math.max(self.freeze_time - ev.time, 0)
end

function Scene_battlefield:get_limit()
	return battlefield_config.config[self.id].limit.count
end

function Scene_battlefield:get_side_pos(obj)
	local config = battlefield_config.config[self.id]
	local side = obj:get_side()
	local list = config.entry[side]
	local i = math.random(1, #list)
	return list[i]
end

function Scene_battlefield:alloc_side(obj)
	local obj_id = obj:get_id()
	local side = self.side_list[obj_id]
	if side == nil or (side ~= 1 and side ~= 2) then
		if self.side_count[1] < self.side_count[2] then
			side = 1
		elseif self.side_count[1] > self.side_count[2] then
			side = 2
		else
			side = _random(1, 3)
		end
		self.side_list[obj_id] = side
		self.side_count[side] = self.side_count[side] + 1
	end

	obj:set_side(side)
	
	local channal_id = self.side_channal[side]
	g_chat_channal_mgr:add_member(obj_id, channal_id)
	
	if not self.owner_list[obj_id] then
		self.owner_list[obj_id] = true

		local sql = string.format(
				"insert into log_battlefield set char_id=%d, scene_id=%d, time=%d, level=%d"
				, obj_id
				, self.id
				, ev.time
				, obj:get_level())
				
		f_multi_web_sql(sql)
	end
	
	return SCENE_ERROR.E_SUCCESS
end

function Scene_battlefield:on_obj_enter(obj)
	--print("Scene_battlefield:on_obj_enter(obj)")
	if OBJ_TYPE_HUMAN == obj:get_type() then
		local obj_id = obj:get_id()
		if self.side_list[obj_id] ~= 1 and self.side_list[obj_id] ~= 2 then
			print("error: Scene_battlefield player dimness side:", obj_id, obj:get_side())
			local obj_side = obj:get_side()
			if obj_side == 1 or obj_side == 2 then
				self.side_list[obj_id] = obj_side
			else
				self:alloc_side(obj)
			end
		end
		
		obj:set_open_damage_record(true)
		self.wait_relive[obj_id] = nil
		self.leave_player[obj_id] = nil
		self.rank[obj_id] = self.rank[obj_id] or 0
		self.collect_record[obj_id] = self.collect_record[obj_id] or {0, 0, 0}
		self.exploit[obj_id] = self.exploit[obj_id] or 0
		self.kill_record[obj_id] = self.kill_record[obj_id] or {0, 0, 0, 0}
		if self.rank[obj_id] == 1 then --矿车
			obj:set_battlefield_rank(1)
			self:add_buff(obj_id)
		elseif self.rank[obj_id] == 2 then	--指挥官
			obj:set_battlefield_rank(2)

		end
		if self.freeze_time - ev.time > 5 then
			local val = self.is_level_break and 400 or 200
			f_prop_add_buff(1466, obj_id, self.freeze_time - ev.time, 0, val, 1)
		end
		self:update_stronghold_info(obj_id)
		--
		if SCENE_STATUS.IDLE == self.status then
			local pkt = {}
			if self.is_last_time then
				pkt.type = 1
				pkt.time = self.open_time + LAST_TIME - ev.time
			else
				pkt.type = 0
				pkt.time = self.open_time + PREPARE_TIME + LAST_TIME - ev.time
				--
				if self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN):get_obj_count() >= self.limit.min_size then
					self.open_time = ev.time - PREPARE_TIME
				end
			end
			self:send_human(obj_id, CMD_BATTLEFIELD_BEGIN_TIME_S , pkt)
			self:update_human_count(obj_id)
		elseif SCENE_STATUS.OPEN == self.status then
			self:get_score_info(obj_id)
			self:update_score_info({[obj_id] = 1})
		end
		--
		if self.check_obj_team == nil then
			self.check_obj_team = {}
			self.check_obj_team_time = ev.time + 1
		end
		self.check_obj_team[obj_id] = 1
	end
end

function Scene_battlefield:on_obj_leave(obj)
	local obj_id = obj:get_id()
	if OBJ_TYPE_HUMAN == obj:get_type() then
		self.collect_type[obj_id] = nil
		obj:set_open_damage_record(nil)
		obj:set_side(0)
		if not obj:is_alive() then
			self.wait_relive[obj_id] = nil
			obj:do_relive(1, true)
		end

		local side = self.side_list[obj_id]
		local channal_id = self.side_channal[side]
		g_chat_channal_mgr:del_member(obj_id, channal_id)
		
		self.leave_player[obj_id] = ev.time
		obj:set_kill_status(0)
		obj:set_battlefield_rank(0)
		f_del_impact(obj, 1508)
		f_del_impact(obj, 1466)
	else
		if self.crystal_list[obj_id] ~= nil then
			local v = self.crystal_list[obj_id]
			local item = self.crystal_occ_list[v[1]][v[2]]
			item[1] = item[1] - 1
			self.crystal_list[obj_id] = nil
		elseif self.diamond_list[obj_id] ~= nil then
			local v = self.diamond_list[obj_id]
			local item = self.diamond_occ_list[v[1]][v[2]]
			item[1] = item[1] - 1
			self.diamond_list[obj_id] = nil
		end
	end
end

function Scene_battlefield:build_Heart()
	local Heart = battlefield_config.config[self.id].side
	for k, v in ipairs(Heart or {}) do
		local obj = g_obj_mgr:create_monster(v.heart[1], v.heart[2], self.key, nil)
		obj:set_side(k)
		self:enter_scene(obj)
	end
end

function Scene_battlefield:update_crystal()
	if ev.time < self.crystal_update_time then 
		return
	end
	self.crystal_update_time = ev.time + self.crystal.interval
	local map_obj = self:get_map_obj()
	for k, v in ipairs(self.crystal or {}) do
		local item = self.crystal_occ_list[v.occ][v.area]
		if item then --and ev.time > item[2] then
			if item[1] < v.total then
				local count = math.min(v.count, v.total - item[1])
				for i = 1, count do
					local pos = map_obj:find_space(v.area, 20)
					if pos ~= nil then
						local obj = g_obj_mgr:create_npc(v.occ, "", pos, self.key, nil)
						self:enter_scene(obj)
						self.crystal_list[obj:get_id()] = {v.occ, v.area}
						item[1] = item[1] + 1
						--print("create crystal: ", v.occ, v.area, item[1])
					end
				end
			end
			--item[2] = ev.time + v.interval
		end
	end
end

function Scene_battlefield:update_diamond()
	if ev.time < self.diamond_update_time then 
		return
	end
	self.diamond_update_time = ev.time + self.diamond.interval
	local is_broadcast = {false, false}
	local map_obj = self:get_map_obj()
	for k, v in ipairs(self.diamond or {}) do
		if self.diamond_switch[k] == 1 then
			local item = self.diamond_occ_list[v.occ][v.area]
			if item then --and ev.time > item[2] then
				local side = k % 2 == 0 and 2 or 1
				is_broadcast[side] = true
				if item[1] < v.total then
					local count = math.min(v.count, v.total - item[1])
					for i = 1, count do
						local pos = map_obj:find_space(v.area, 20)
						if pos ~= nil then
							local obj = g_obj_mgr:create_npc(v.occ, "", pos, self.key, nil)
							obj:set_side(side)
							self:enter_scene(obj)
							self.diamond_list[obj:get_id()] = {v.occ, v.area}
							item[1] = item[1] + 1
							--print("create diamond: ", v.occ, v.area, item[1])
						end
					end
				end
				--item[2] = ev.time + v.interval
			end
		end
	end
	-- 广播
	local broadcast = battlefield_config.config[self.id].broadcast
	if is_broadcast[1] then
		local msg = {}
		f_construct_content(msg, broadcast[7].text, 3)
		self:sysbd(msg, 1)
	end
	if is_broadcast[2] then
		local msg = {}
		f_construct_content(msg, broadcast[8].text, 3)
		self:sysbd(msg, 2)
	end
end

function Scene_battlefield:on_timer(tm)
	local now_time = ev.time
	
	if SCENE_STATUS.OPEN == self.status then
		if self.soon_to_end == nil and (self.score[1] >= self.limit.end_point - 1000 or self.score[2] >= self.limit.end_point - 1000) then
			self.soon_to_end = true
			-- 广播
			local broadcast = battlefield_config.config[self.id].broadcast
			local msg_to_win = {}
			f_construct_content(msg_to_win, broadcast[9].text, 3)
			local msg_to_lose = {}
			f_construct_content(msg_to_lose, broadcast[10].text, 3)
			if self.score[1] >= self.limit.end_point - 1000 then
				self:sysbd(msg_to_win, 1)
				self:sysbd(msg_to_lose, 2)			
			else
				self:sysbd(msg_to_lose, 1)
				self:sysbd(msg_to_win, 2)
			end
		end
		if self.freeze_time < now_time or self.score[1] >= self.limit.end_point or self.score[2] >= self.limit.end_point then
			self.status = SCENE_STATUS.FREEZE
			self.close_time = ev.time + battlefield_config.config[self.id].limit.wait
			--
			for k, v in pairs(self.leave_player) do
				self:clear_player(k)
				self.leave_player[k] = nil
			end
			self:final_score_info()
			self:do_reward()
		else
			self:update_crystal()
			self:update_diamond()
			if ev.time >= self.stronghold_point_time then
				self.stronghold_point_time = ev.time + self.stronghold_point_interval
				if self.stronghold_count[1] > 0 then
					self.score[1] = self.score[1] + self.stronghold_point[self.stronghold_count[1]]
				end
				if self.stronghold_count[2] > 0 then
					self.score[2] = self.score[2] + self.stronghold_point[self.stronghold_count[2]]
				end
				if self.stronghold_count[1] > 0 or self.stronghold_count[2] > 0 then
					self:update_score_info()
				end
				--
				local stronghold_exploit_base_side = {self.stronghold_exploit_base[self.stronghold_count[1]] or 0, self.stronghold_exploit_base[self.stronghold_count[2]] or 0}
				local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
				local min_exploit = self.exploit_factor[#self.exploit_factor][1]
				for k, v in pairs(self.side_list) do
					local exploit = self.exploit[k] or 0
					if exploit >= min_exploit and con:is_member(k) then
						local exploit_factor = 0
						for _, item in ipairs(self.exploit_factor) do
							if exploit >= item[1] then
								exploit_factor = item[2]
								break
							end
						end
						self:add_exploit(k, math.floor(stronghold_exploit_base_side[v] * exploit_factor), true)
						--print("====> add exploit", k, math.floor(stronghold_exploit_base_side[v] * exploit_factor), self.exploit[k])
					end
				end
				local human_list = con:get_obj_list()
				for k, v in pairs(human_list) do
					self:get_score_info(k)
				end
				self:appoint_commander()
				-- 
				if ev.time >= self.general_broadcast then
					self.general_broadcast = ev.time + 180
					local broadcast = battlefield_config.config[self.id].broadcast
					local msg = {}
					f_construct_content(msg, broadcast[11 + (self.general_broadcast_type % 2)].text, 14)
					self:sysbd(msg)
					self.general_broadcast_type = self.general_broadcast_type + 1
				end
			end
		end
	elseif SCENE_STATUS.IDLE == self.status then
		if not self.is_last_time and self.open_time + PREPARE_TIME <= ev.time then
			self.is_last_time = true
			self.open_time = ev.time
			-- 广播开始倒数
			local pkt = {}
			pkt.type = 1
			pkt.time = LAST_TIME
			pkt = Json.Encode(pkt)
			local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
			local human_list = con:get_obj_list()
			for k, v in pairs(human_list) do
				self:send_human(k, CMD_BATTLEFIELD_BEGIN_TIME_S , pkt, true)
			end
		elseif self.is_last_time and ev.time >= self.open_time + LAST_TIME then
			self.status = SCENE_STATUS.OPEN
			self:appoint_commander()
			self:find_weak_finghting()
			--
			local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
			local human_list = con:get_obj_list()
			for k, v in pairs(human_list) do
				self:get_score_info(k)
			end
		end
	elseif SCENE_STATUS.FREEZE == self.status then
		if self.close_time < now_time then
			self:close()
			self.status = SCENE_STATUS.CLOSE
		end
	end

	self:do_relive(now_time)
	self.obj_mgr:on_timer(tm)

	if self.check_obj_team ~= nil and ev.time >= self.check_obj_team_time then
		for k, v in pairs(self.check_obj_team) do
			local obj = g_obj_mgr:get_obj(k)
			local team_id = obj and obj:get_team()
			local team_o = team_id and g_team_mgr:get_team_obj(team_id)
			if team_o ~= nil then
				f_team_kickout(obj)
			end
		end
		self.check_obj_team = nil
	end

	for k, v in pairs(self.leave_player) do
		if v + LEAVE_WAIT_TIME < ev.time then
			self:clear_player(k)
			self.leave_player[k] = nil
		end
	end
end

function Scene_battlefield:carry_scene(obj, pos)
	--print("Scene_battlefield:carry_scene(obj, pos)")
	local e_code = self:alloc_side(obj)
	if SCENE_ERROR.E_SUCCESS ~= e_code then
		return e_code
	end
	
	return self:push_scene(obj, self:get_side_pos(obj))
end

function Scene_battlefield:die_event(args)
	local killer_id = args.killer_id
	local obj_id = args.char_id
	local obj = self:get_obj(obj_id)
	if obj then
		self:set_collect_type(obj_id, 0)
		self.wait_relive[obj_id] = ev.time + 3			--加入等待复活列表
		obj:set_kill_status(0)
		
		args.mode = 1
		args.is_notify = false
		args.is_evil = false
		args.is_battlefield = true
		args.relive_time = math.max(self.wait_relive[obj_id] - ev.time, 0)
		
		local killer = killer_id and self:get_obj(killer_id)
		if killer then					--被玩家杀死
			local killer_side = killer:get_side()
			local killer_record = self.kill_record[killer_id]
			local be_killer_record = self.kill_record[obj_id]
			if OBJ_TYPE_HUMAN == killer:get_type() then
				self.battlefield_record[4] = self.battlefield_record[4] + 1				
				killer_record[1] = killer_record[1] + 1
				be_killer_record[1] = 0
				if self:is_commander(obj_id) then
					killer_record[3] = killer_record[3] + 1
					self:add_exploit(killer_id, self.limit.exploit.kill_commander)
					self.score[killer_side] = self.score[killer_side] + self.limit.score.kill_commander
				else
					killer_record[2] = killer_record[2] + 1
					self:add_exploit(killer_id, self.limit.exploit.kill)
					self.score[killer_side] = self.score[killer_side] + self.limit.score.kill
				end
			end
			--计算助攻玩家
			local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
			local valid_damage_list = {}
			for k, v in pairs(args.damage_record_l or {}) do
				if v[2] + 5 >= ev.time and con:is_member(k) then
					table.insert(valid_damage_list, {k, v[1]})
					--local r = self.kill_record[k]
					--r[4] = r[4] + 1
				end
			end

			if #valid_damage_list >= 5 then
				table.sort(valid_damage_list, function(e1,e2) return e1[2] < e2[2] end)
			end
			local update_score_list = {}
			for i, v in ipairs(valid_damage_list) do
				if v[1] ~= killer_id then
					local assistant_id = v[1]
					local r = self.kill_record[assistant_id]
					r[4] = r[4] + 1
					update_score_list[assistant_id] = 1
					self.battlefield_record[5] = self.battlefield_record[5] + 1
					if i <= 4 then
						self:add_exploit(assistant_id, self.limit.exploit.assistant)
						self.score[killer_side] = self.score[killer_side] + self.limit.score.assistant
					else
						self:add_exploit(assistant_id, math.floor(self.limit.exploit.assistant * 0.6))
						self.score[killer_side] = self.score[killer_side] + math.floor(self.limit.score.assistant * 0.5)
					end
					--助攻事件
					local args = {}
					args.count = 1
					g_event_mgr:notify_event(EVENT_SET.EVENT_ASSIST_ATTACK, v[1], args)
				end
			end
			--更新数据
			if OBJ_TYPE_HUMAN == killer:get_type() then
				update_score_list = {[killer_id] = 1}
			end
			self:update_score_info(update_score_list)
			if OBJ_TYPE_HUMAN == killer:get_type() then
				killer:add_battlefield_param(1, 0, 0, 0)
				local killer_mk = killer_record[1]	-- 杀人者的连杀数
				local honor_kill = battlefield_config.config[self.id].limit.enemy.kill
				
				if killer_mk >= honor_kill then
					killer:set_kill_status(1)
				end

				-- 杀人数广播
				local honor = battlefield_config.config[self.id].honor[killer_mk]
				if honor and honor.text then
					local msg = {}
					f_construct_content(msg, string.format(honor.text, killer:get_name()), 16)
					self:sysbd(msg)
				end
			end
			if Obj_mgr.obj_type(killer_id) == OBJ_TYPE_HUMAN then
				local args = {}
				args.count = 1
				args.total = killer:get_all_kill()
				g_event_mgr:notify_event(EVENT_SET.EVENT_BATTLE_KILL, killer_id, args)
			end
		end
	end
end

function Scene_battlefield:relive_human(obj)
	if obj:is_alive() then
		return
	end
	
	local pos = self:get_side_pos(obj)
	obj:do_relive(1, true)	--复活
	obj:send_relive(3)
	
	self:transport(obj, pos)
	
	f_prop_god(obj, 10)
end

function Scene_battlefield:do_relive(now_time)
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

function Scene_battlefield:close()
	if self.instance_id then		
		Scene_instance.close(self)

		self.wait_relive = {}
		for _, id in ipairs(self.side_channal) do
			g_chat_channal_mgr:remove_channal(id)
		end
		
		self.side_channal = {}
	end
end

--查找战斗力最弱的几们成员
function Scene_battlefield:find_weak_finghting()
	if self.side_count[1] + self.side_count[2] < 16 then
		return
	end
	local fighting_1_l = {}
	local fighting_2_l = {}
	local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
	local human_list = con:get_obj_list()
	for k, v in pairs(human_list) do
		local obj = g_obj_mgr:get_obj(k)
		if obj:get_side() == 1 then
			table.insert(fighting_1_l, {k, obj:get_fighting()})
		end
		if obj:get_side() == 2 then
			table.insert(fighting_2_l, {k, obj:get_fighting()})
		end
	end

	if #fighting_1_l >= 8 then
		table.sort(fighting_1_l, function(e1,e2) 
					return e1[2] < e2[2] end)
		for i = 1, 4 do
			self:send_human(fighting_1_l[i][1], CMD_BATTLEFIELD_WEAK_FIGHTING_S , {})
		end
	end
	if #fighting_2_l >= 8 then
		table.sort(fighting_2_l, function(e1,e2) 
					return e1[2] < e2[2] end)
		for i = 1, 4 do
			self:send_human(fighting_2_l[i][1], CMD_BATTLEFIELD_WEAK_FIGHTING_S , {})
		end
	end

end

--任命指挥官
function Scene_battlefield:appoint_commander()
	if self.commander_id[1] == nil then
		local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
		local human_list = con:get_obj_list()
		local max_fighting = 0
		local max_fighting_er = nil
		for k, v in pairs(human_list) do
			local obj = g_obj_mgr:get_obj(k)
			if obj:get_side() == 1 and obj:get_fighting() > max_fighting then
				max_fighting = obj:get_fighting()
				max_fighting_er = k
			end
		end
		if max_fighting_er ~= nil then
			local obj = g_obj_mgr:get_obj(max_fighting_er)
			if obj ~= nil then
				f_del_impact(obj, 1508)
				obj:set_battlefield_rank(2)
				self.rank[max_fighting_er] = 2
				self.commander_id[1] = max_fighting_er
				local pkt = {}
				pkt.type = 2
				self:send_human(max_fighting_er, CMD_BATTLEFIELD_CHANGE_RANK_S , pkt)
				--
				local broadcast = battlefield_config.config[self.id].broadcast
				local msg = {}
				f_construct_content(msg, string.format(broadcast[5].text, obj:get_name()), 23)
				self:sysbd(msg, 1)
			end
		end
	end
	if self.commander_id[2] == nil then
		local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
		local human_list = con:get_obj_list()
		local max_fighting = 0
		local max_fighting_er = nil
		for k, v in pairs(human_list) do
			local obj = g_obj_mgr:get_obj(k)
			if obj:get_side() == 2 and obj:get_fighting() > max_fighting then
				max_fighting = obj:get_fighting()
				max_fighting_er = k
			end
		end
		if max_fighting_er ~= nil then
			local obj = g_obj_mgr:get_obj(max_fighting_er)
			if obj ~= nil then
				f_del_impact(obj, 1508)
				obj:set_battlefield_rank(2)
				self.rank[max_fighting_er] = 2
				self.commander_id[2] = max_fighting_er
				local pkt = {}
				pkt.type = 2
				self:send_human(max_fighting_er, CMD_BATTLEFIELD_CHANGE_RANK_S , pkt)
				--
				local broadcast = battlefield_config.config[self.id].broadcast
				local msg = {}
				f_construct_content(msg, string.format(broadcast[6].text, obj:get_name()), 23)
				self:sysbd(msg, 2)
			end
		end
	end
end

--两坐标距离
function Scene_battlefield:distance(cur_pos, des_pos)
	local d_x = math.pow(cur_pos[1] - des_pos[1], 2)
	local d_y = math.pow(cur_pos[2] - des_pos[2], 2)
	return math.floor(math.sqrt(d_x + d_y))
end

function Scene_battlefield:check_npc_distance(obj)
	local obj_pos = obj:get_pos()
	for k, v in pairs(self.npc_pos) do
		if self:distance(obj_pos, v) < 10 then
			return true
		end
	end
	return false
end

--判断是否指挥官
function Scene_battlefield:is_commander(char_id)
	return self.rank[char_id] == 2
end

--判断场景里的某个采集物能否被采
function Scene_battlefield:can_be_collected(char_id, obj_o)
	--print("Scene_battlefield:can_be_collected()", char_id, obj_o:get_occ(), obj_o:get_id())
	if SCENE_STATUS.OPEN ~= self.status then
		return 31067
	end
	local obj_id = obj_o:get_id()
	if self.stronghold_list[obj_id] ~= nil then
		if self.side_list[char_id] == self.stronghold_list[obj_id] then
			return 31065
		elseif self.rank[char_id] == 1 then
			return 31066
		end
		return 0
	end

	local old_type = self.collect_type[char_id] or 0
	if old_type == 1 then
		return 31060
	elseif old_type == 2 then
		return 31061
	end

	if self.diamond_list[obj_id] ~= nil then
		local side = self.side_list[char_id]
		if obj_o:get_side() ~= side then
			return 31062
		end
	end
	return 0
end

--场景里的某个采集物被采了
function Scene_battlefield:obj_be_collected(char_id, obj_o)
	--print("Scene_battlefield:obj_be_collected()", char_id, obj_o:get_occ(), obj_o:get_id())
	local obj_id = obj_o:get_id()
	if self.crystal_list[obj_id] ~= nil then
		self:set_collect_type(char_id, 1)
		self.battlefield_record[2] = self.battlefield_record[2] + 1

	elseif self.diamond_list[obj_id] ~= nil then
		self:set_collect_type(char_id, 2)
		self.battlefield_record[1] = self.battlefield_record[1] + 1

	elseif self.stronghold_list[obj_id] ~= nil then
		local stronghold_old_side = self.stronghold_list[obj_id]
		if stronghold_old_side ~= 0 then
			self.stronghold_count[stronghold_old_side] = self.stronghold_count[stronghold_old_side] - 1
		end
		local obj = g_obj_mgr:get_obj(char_id)
		local side = obj:get_side()
		local pos = obj_o:get_pos()
		local occ = self.stronghold.occ_1
		if side == 2 then
			occ = self.stronghold.occ_2
		end
		local obj_c = g_obj_mgr:create_npc(occ, "", pos, self.key, nil)
		obj_c:set_side(side)
		self.stronghold_list[obj_c:get_id()] = side
		self.stronghold_count[side] = self.stronghold_count[side] + 1
		self:enter_scene(obj_c)
		obj_c:set_stronghold_type(obj_o:get_stronghold_type())
		self.stronghold_list_side[obj_o:get_stronghold_type()] = side
		local switch = obj_c:get_stronghold_type() * 2
		if side == 1 then
			self.diamond_switch[switch] = 0
			self.diamond_switch[switch-1] = 1
		else
			self.diamond_switch[switch-1] = 0
			self.diamond_switch[switch] = 1
		end
		self:add_exploit(char_id, self.stronghold.exploit, true)
		local human_side = self.side_list[char_id] or obj:get_side()
		self.score[human_side] = self.score[human_side] + self.stronghold.point
		self.collect_record[char_id][3] = self.collect_record[char_id][3] + 1
		self:update_score_info({[char_id] = 1})
		self:update_stronghold_info()
		self.battlefield_record[3] = self.battlefield_record[3] + 1
		--广播
		local enemy_side = side == 1 and 2 or 1
		local broadcast = battlefield_config.config[self.id].broadcast
		if stronghold_old_side == 0 then
			local msg = {}
			local name = obj:get_name()
			f_construct_content(msg, string.format(broadcast[1].text, name), 23)
			self:sysbd(msg, side)
			local msg2 = {}
			f_construct_content(msg2, string.format(broadcast[2].text, name), 61)
			self:sysbd(msg2, enemy_side)
		else
			local msg = {}
			local name = obj:get_name()
			f_construct_content(msg, string.format(broadcast[3].text, name), 23)
			self:sysbd(msg, side)
			local msg2 = {}
			f_construct_content(msg2, string.format(broadcast[4].text, name), 61)
			self:sysbd(msg2, enemy_side)
		end
	end
end

--判断能否进入战场
function Scene_battlefield:check_in(char_id, size)
	if self.side_list[char_id] ~= nil then
		return true
	end
	return self.side_count[1] + self.side_count[2] < size
end

--玩家申请改变身份  type: 0:正常，1:矿车，2:指挥官
function Scene_battlefield:change_rank(char_id, type)
	--print("Scene_battlefield:change_rank()", type)
	local old_rank = self.rank[char_id]
	if old_rank == 2 or type == 2 then
		return 31064
	end
	local obj = g_obj_mgr:get_obj(char_id)
	if not self:check_npc_distance(obj) then
		return 31068
	end
	if old_rank ~= type and obj ~= nil then
		if type == 0 then
			f_del_impact(obj, 1508)
		elseif type == 1 then
			self:add_buff(char_id)
			self.battlefield_record[6] = self.battlefield_record[6] + 1
			--
			local pet_con = obj:get_pet_con()
			local pet_obj = pet_con:get_combat_pet()
			if pet_obj then 
				obj:on_pet_die(pet_obj:get_id(), pet_obj)
			end
		end
		obj:set_battlefield_rank(type)
		self.rank[char_id] = type
		local pkt = {}
		pkt.type = type
		self:send_human(char_id, CMD_BATTLEFIELD_CHANGE_RANK_S, pkt)
	end
	return 0
end

--玩家缴纳资源  type: 0:无资源，1:小晶石，2:神石
function Scene_battlefield:payment_resource(char_id)
	--print("Scene_battlefield:payment_resource()")
	if SCENE_STATUS.OPEN ~= self.status then
		return 31068
	end
	local obj = g_obj_mgr:get_obj(char_id)
	if not self:check_npc_distance(obj) then
		return 31068
	end
	local old_type = self.collect_type[char_id] or 0
	local exploit = nil
	local add_success = false
	if old_type == 1 or old_type == 2 then
		local human_side = self.side_list[char_id]
		local c_r = self.collect_record[char_id]
		c_r[old_type] = c_r[old_type] + 1
		self:set_collect_type(char_id, 0)
		if old_type == 1 then
			exploit = self.crystal.exploit
			--if self.rank[char_id] == 1 then
				--exploit = math.floor(exploit * 0.7)
			--end
			add_success = self:add_exploit(char_id, exploit)
			self.score[human_side] = self.score[human_side] + self.crystal.point
		else
			exploit = self.diamond.exploit
			--if self.rank[char_id] == 1 then
				--exploit = math.floor(exploit * 0.7)
			--end
			add_success = self:add_exploit(char_id, exploit)
			self.score[human_side] = self.score[human_side] + self.diamond.point
		end
		self:update_score_info({[char_id] = 1})
		--上缴资源事件
		local args = {}
		args.item_id = old_type
		args.item_cnt = 1
		g_event_mgr:notify_event(EVENT_SET.EVENT_OVER_RESOURCES, char_id, args)
		if not add_success then
			return 31073
		end
		return old_type, exploit
	end
	return 31063
end

--设置玩家身上收集的资源  type: 0:无资源，1:小晶石，2:神石
function Scene_battlefield:set_collect_type(char_id, type)
	local old_type = self.collect_type[char_id] or 0
	self.collect_type[char_id] = type
	if old_type ~= type then
		local pkt = {}
		pkt.type = type
		self:send_human(char_id, CMD_BATTLEFIELD_COLLECT_RESOURCE_S, pkt)
	end
end

--取得全部排名
function Scene_battlefield:get_score_info(char_id)
	
	if self.score_info == nil or ev.time >= self.score_info_time + 5 then
		self.score_info = {{}, {}}
		local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
		local human_list = con:get_obj_list()
		for k, v in pairs(human_list) do
			local obj = g_obj_mgr:get_obj(k)
			if obj:get_side() == 1 then
				table.insert(self.score_info[1], {k, obj:get_name(), self.kill_record[k][2] + self.kill_record[k][3], self.exploit[k]})
			end
			if obj:get_side() == 2 then
				table.insert(self.score_info[2], {k, obj:get_name(), self.kill_record[k][2] + self.kill_record[k][3], self.exploit[k]})
			end
		end

		table.sort(self.score_info[1], function(e1,e2) return e1[4] < e2[4] end)
		table.sort(self.score_info[2], function(e1,e2) return e1[4] < e2[4] end)

		self.score_info_time = ev.time
	end

	local obj = g_obj_mgr:get_obj(char_id)
	local my_side = obj:get_side()
	local enemy_side = my_side == 1 and 2 or 1
	local pkt = {}
	--
	local exploit = self.exploit[char_id]
	local exploit_factor = 0
	for _, item in ipairs(self.exploit_factor) do
		if exploit >= item[1] then
			exploit_factor = item[2]
			break
		end
	end
	local append = math.floor((self.stronghold_exploit_base[self.stronghold_count[my_side]] or 0)* exploit_factor)
	--
	pkt.side_home = self.score_info[my_side]
	pkt.side_enemy = self.score_info[enemy_side]
	pkt.score = {self.score[my_side], self.score[enemy_side]}
	pkt.info = {self.kill_record[char_id][2] + self.kill_record[char_id][3], self.kill_record[char_id][4], self.collect_record[char_id][2]
				, self.collect_record[char_id][1], self.collect_record[char_id][3], self.exploit[char_id], append}
	self:send_human(char_id, CMD_BATTLEFIELD_SCORE_INFO_S , pkt)

end

--更新排名信息
function Scene_battlefield:update_score_info(update_score_l)
	local score_list = nil
	if update_score_l ~= nil then
		score_list = {}
		for char_id, _ in pairs(update_score_l) do
			local obj = g_obj_mgr:get_obj(char_id)
			local my_side = obj:get_side()
			local enemy_side = my_side == 1 and 2 or 1
			table.insert(score_list, {char_id, obj:get_name(), self.kill_record[char_id][2] + self.kill_record[char_id][3], self.exploit[char_id], my_side})
		end

		for char_id, _ in pairs(update_score_l) do
			local obj = g_obj_mgr:get_obj(char_id)
			local my_side = obj:get_side()
			local enemy_side = my_side == 1 and 2 or 1
			local pkt = {}
			--
			local stronghold_exploit_base_side = {self.stronghold_exploit_base[self.stronghold_count[1]] or 0, self.stronghold_exploit_base[self.stronghold_count[2]] or 0}						
			local exploit = self.exploit[char_id]
			local exploit_factor = 0
			for _, item in ipairs(self.exploit_factor) do
				if exploit >= item[1] then
					exploit_factor = item[2]
					break
				end
			end
			--
			pkt.list = score_list
			pkt.score = {self.score[my_side], self.score[enemy_side]}
			pkt.info = {self.kill_record[char_id][2] + self.kill_record[char_id][3], self.kill_record[char_id][4], self.collect_record[char_id][2]
						, self.collect_record[char_id][1], self.collect_record[char_id][3], self.exploit[char_id],
						math.floor((stronghold_exploit_base_side[my_side] or 0)* exploit_factor)}
			self:send_human(char_id, CMD_BATTLEFIELD_SCORE_INFO_UPDATE_S , pkt)
		end
	end

	local new_pkt = {}
	new_pkt.list = score_list
	new_pkt.score = {self.score[1], self.score[2]}
	new_pkt_1 = Json.Encode(new_pkt)
	new_pkt.score = {self.score[2], self.score[1]}
	new_pkt_2 = Json.Encode(new_pkt)
	local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
	local human_list = con:get_obj_list()
	for k, v in pairs(human_list) do
		if update_score_l == nil or update_score_l[k] == nil then
			if self.side_list[k] == 1  then
				self:send_human(k, CMD_BATTLEFIELD_SCORE_INFO_UPDATE_S , new_pkt_1, true)
			else
				self:send_human(k, CMD_BATTLEFIELD_SCORE_INFO_UPDATE_S , new_pkt_2, true)
			end
		end
	end
end

--最终排名
function Scene_battlefield:final_score_info()
	self.final_score_list = {}
	local reward_config = battlefield_config.config[self.id].reward
	local win_side = self:adjudge()
	local side_reward = {reward_config.tie, reward_config.tie}
	if win_side == 1 then
		side_reward = {reward_config.win, reward_config.lose}
	elseif win_side == 2 then
		side_reward = {reward_config.lose, reward_config.win}		
	end
	--指挥官加成
	for k, c_id in pairs(self.commander_id) do
		if c_id ~= nil and self.exploit[c_id] ~= nil then
			self.exploit[c_id] = self.exploit[c_id] * (1 + reward_config.commander_add)
		end
	end
	self.final_score_list_append = {}
	local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
	local human_list = con:get_obj_list()
	for k, v in pairs(human_list) do
		local obj = g_obj_mgr:get_obj(k)
		if obj ~= nil then
			local factor = 0
			local total_exploit = self.exploit[k]
			for _, entry in ipairs(reward_config.list) do
				if total_exploit > entry[1] then
					factor = entry[2]
					break
				end
			end
			local k_side = self.side_list[k] or obj:get_side()
			if win_side ~= 0 and k_side ~= win_side and total_exploit >= self.limit.reward_line then
				self.final_score_list_append[k] = total_exploit
				total_exploit = total_exploit + self.limit.reward_exploit
			end
			total_exploit = math.floor(total_exploit + (side_reward[k_side] or 0) * factor)
			table.insert(self.final_score_list, {k, obj:get_name(), self.kill_record[k][2] + self.kill_record[k][3], total_exploit, obj:get_side()})
		end
	end
	table.sort(self.final_score_list, function(e1,e2) return e1[4] > e2[4] end)

	self.final_ranking_list = {}
	for k, v in ipairs(self.final_score_list) do
		self.final_ranking_list[v[1]] = k
	end

	local list = {}
	for i = 1, 10 do
		local entry = self.final_score_list[i]
		if entry ~= nil then
			list[i] = {entry[2], entry[3], entry[5], math.min(entry[4], self.max_exploit)}
		else
			break
		end
	end
	
	local is_again = self.final_end_time > ev.time + 60 and 1 or 0
	local pkt = {self.close_time - ev.time, {self.score[1], self.score[2], self:adjudge()}, {}, list, is_again}
	for k, v in ipairs(self.final_score_list) do
		local real_exploit = math.min(v[4], self.max_exploit)
		pkt[3] = {v[2], v[3], v[5], real_exploit, k}
		pkt[6] = self.final_score_list_append[v[1]] and self.limit.reward_exploit or -1
		self:send_human(v[1], CMD_BATTLEFIELD_END_INFO_S, pkt)
	end
	--流水
	local sql = string.format(
				"insert into log_new_battlefield set time=%d, type=%d, into_count=%d, score1=%d, score2=%d, shenshi=%d, jingkuang=%d, occupy_count=%d, kill_count=%d, assist_count=%d, change_count=%d"
				, ev.time
				, self.is_level_break and 2 or 1
				, self.side_count[1] + self.side_count[2]
				, self.score[1]
				, self.score[2]
				, self.battlefield_record[1]
				, self.battlefield_record[2]
				, self.battlefield_record[3]
				, self.battlefield_record[4]
				, self.battlefield_record[5]
				, self.battlefield_record[6])
	f_multi_web_sql(sql)
end

function Scene_battlefield:adjudge()
	local win_side = 0
	if self.score[1] > self.score[2] then
		win_side = 1
	elseif self.score[1] < self.score[2] then
		win_side = 2
	end
	return win_side
end

function Scene_battlefield:do_reward()
	local win_side = self:adjudge()
	for k, v in ipairs(self.final_score_list) do
		--
		local obj = g_obj_mgr:get_obj(v[1])
		if obj ~= nil then
			local pack_con = obj:get_pack_con()
			pack_con:add_money(MoneyType.HONOR, math.min(v[4], self.max_exploit), {['type'] = MONEY_SOURCE.BATTLEFIELD})
			local is_win = win_side == self.side_list[v[1]]
			local is_draw = win_side == 0
			obj:add_battlefield_param(0, is_win and 1 or 0, (is_win or is_draw) and 0 or 1, is_draw and 1 or 0)
			if is_win then
				g_event_mgr:notify_event(EVENT_SET.EVENT_BATTLE_WIN, v[1], {['count'] = 1})
			end
		end
	end

	
end

--战场加buff
function Scene_battlefield:add_buff(char_id)
	local impact_o = Impact_1508(char_id)
	local param = {}
	param.sel = 31
	if self.is_level_break then
		param.sel = 32
	end
	impact_o:set_count(self.freeze_time - ev.time)
	impact_o:effect(param)
end

--更新小地图据点信息
function Scene_battlefield:update_stronghold_info(char_id)
	local pkt = {}
	pkt.info = self.stronghold_list_side
	pkt = Json.Encode(pkt)
	local min_exploit = self.exploit_factor[#self.exploit_factor][1]
	if char_id == nil then
		local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
		local human_list = con:get_obj_list()
		for k, v in pairs(human_list) do
			self:send_human(k, CMD_BATTLEFIELD_STRONGHOLD_UPDATE_S , pkt, true)
		end
	else
		self:send_human(char_id, CMD_BATTLEFIELD_STRONGHOLD_UPDATE_S , pkt, true)
	end
end

--战场内广播
function Scene_battlefield:sysbd(str_json, side)
	local pkt ={}
	pkt.bdc_type = 8
	pkt.msg_type = 8
	pkt.content = str_json

	pkt = Json.Encode(pkt)
	local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
	local human_list = con:get_obj_list()
	for k,v in pairs(human_list) do
		if side == nil or self.side_list[k] == side then
			g_cltsock_mgr:send_client(k, CMD_C2B_SYS_BDC_S, pkt, true)
		end
	end
end

--新战场更新人数
function Scene_battlefield:update_human_count(char_id)
	local pkt = self.side_count
	pkt = Json.Encode(pkt)
	local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
	local human_list = con:get_obj_list()
	for k, v in pairs(human_list) do
		self:send_human(k, CMD_BATTLEFIELD_UPDATE_HUMAN_COUNT_S , pkt, true)
	end
end

--
function Scene_battlefield:is_attack(attacker_id, defender_id)
	if SCENE_STATUS.OPEN ~= self.status then
		return SCENE_ERROR.E_ATTACK_BAN
	end
	if self.rank[attacker_id] == 1 then
		return 31072
	end
	
	return Scene_entity.is_attack(self, attacker_id, defender_id)
end

function Scene_battlefield:add_exploit(char_id, exploit, is_force)
	if is_force or self.exploit[char_id] < self.limit.max_exploit then
		self.exploit[char_id] = self.exploit[char_id] + exploit
		return true
	end
	return false
end