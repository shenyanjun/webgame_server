local faction_copy_config = require("scene_ex.config.faction_copy_loader")

local _random = crypto.random
local _boss_info_time = 2

Scene_faction = oo.class(Scene_instance, "Scene_faction")

function Scene_faction:__init(scene_id, map_id, instance_id, layer_id, map_obj)
	Scene_instance.__init(self, map_id, instance_id, map_obj)
	self.key = {scene_id, instance_id, map_id}
	self.scene_id = scene_id
	self.layer_id = layer_id

	self.human_count = 0
	self.start_time = ev.time
	-- 
	self.boss_id = nil					-- 如果不空则已召唤boss
	self.info_list = {}			-- {{排名，玩家ID，玩家名字，伤害值，}}
	self.boss_info_time = ev.time

	--
	self.buff = {}
	self.buff_config = faction_copy_config.config[self.scene_id].buff
	self.collect_config = faction_copy_config.config[self.scene_id].layer[self.layer_id].wild
	self.collect_config = self.collect_config and self.collect_config.collect
	self.collect_time = ev.time + 5
	self.collect_item = 1
end

--副本出口
function Scene_faction:get_home_carry(obj)
	local config = faction_copy_config.config[self.scene_id]
	local home_carry = config and config.home
	if not home_carry or not home_carry.id
		or not home_carry.pos or not home_carry.pos[1] or not home_carry.pos[2] then
		return nil, nil
	end
	return home_carry.id, home_carry.pos
end

function Scene_faction:get_limit_config()
	return faction_copy_config.config[self.scene_id].limit
end

function Scene_faction:get_self_config()
	return faction_copy_config.config[self.scene_id].layer[self.layer_id]
end

function Scene_faction:instance()
	local config = self:get_limit_config()
	self.end_time = ev.time + config.timeout.number
	self.close_time = self.end_time + 120
	self.start_time = ev.time
	self.pass_time = ev.time + self:get_self_config().pass_time
	self.obj_mgr:instance(self.map_obj:get_w(), self.map_obj:get_h())

	--
	self:summon_boss()
end

function Scene_faction:carry_scene(obj, pos)
	if not obj then
		return SCENE_ERROR.E_NOT_ON_SCENE, nil
	end

	local config = self:get_self_config()
	if not config then
		return SCENE_ERROR.E_SCENE_CLOSE, nil
	end
	
	local obj_id = obj:get_id()
	
	local limit = self:get_limit_config()
	if limit then
		local human = limit.human
		if human and human.max and human.max < self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN):get_obj_count() + 1 then
			return SCENE_ERROR.E_FACTION_HUMAN_MAX, nil
		end
		
		if not self.owner_list[obj_id] then
			local cycle_limit = limit.cycle and limit.cycle.number
			local con = obj:get_copy_con()
			if cycle_limit and ((not con) or con:get_count_copy(self.scene_id) >= cycle_limit) then
				return SCENE_ERROR.E_CYCLE_LIMIT
			end
			
			con:add_count_copy(self.scene_id)
			self.owner_list[obj_id] = true
			f_scene_info_log("Scene_faction  instance_id:%s, char_id:%d, time:%d layer_id:%d", self.instance_id, obj_id, ev.time, self.layer_id)
		end
	else
		if not self.owner_list[obj_id] then
			con:add_count_copy(self.id)
			self.owner_list[obj_id] = true
		end
	end
	--
	local team_id = obj:get_team()
	local team_o = g_team_mgr:get_team_obj(team_id)
	if team_o ~= nil and team_o:get_teamer_id() ~= obj_id then
		if g_faction_mgr:get_faction_by_cid(team_o:get_teamer_id()) ~= g_faction_mgr:get_faction_by_cid(obj_id) then
			f_team_kickout(obj)
		end
	end

	local i = math.random(1, #config.entry)
	return self:push_scene(obj, config.entry[i])
end


function Scene_faction:on_timer(tm)
	local now = ev.time
	if self.close_time <= now then
		self:close()
		return
	end
	self.obj_mgr:on_timer(tm)

	--
	if self.boss_id ~= nil and not self.is_end then
		if self.end_time <= now then
			f_scene_info_log("Scene_faction  kill_boss_failed instance_id:%s, start_time:%d end_time:%d", self.instance_id, self.start_time, ev.time)				
			self:broadcast_boss_info(true, nil)
			local obj = g_obj_mgr:get_obj(self.boss_id)
			local _ = obj and obj:leave()
			self.is_end = true
			local pkt = {}
			pkt.faction_id = self.instance_id
			pkt.switch_flag = 0
			pkt.scene_id = self.scene_id
			g_faction_mgr:switch_fb(pkt)
		elseif ev.time >= self.boss_info_time then
			self:broadcast_boss_info(false, nil)
			self.boss_info_time = ev.time + _boss_info_time
		end
		--
		self:on_timer_refresh_collect()

	end

end

function Scene_faction:on_timer_refresh_collect()
	--print("Scene_faction:on_timer_refresh_collect")
	if ev.time >= self.collect_time and self.collect_config then
		self.collect_time = ev.time + 5
		local boss_o = g_obj_mgr:get_obj(self.boss_id)
		if boss_o and (boss_o:get_hp() / boss_o:get_max_hp() <= (self.collect_config[self.collect_item] and self.collect_config[self.collect_item][1] or -1)) then
			local collect_id = self.collect_config[self.collect_item][2]
			local count = self.collect_config[self.collect_item][3]
			
			local cur_pos = boss_o:get_pos()
			local pos_m = {cur_pos[1]-30,cur_pos[1]+30,cur_pos[2]-30,cur_pos[2]+30}
			local map_obj = self:get_map_obj()
			for i = 1, count do
				local pos = map_obj:find_pos(pos_m)
				if pos ~= nil then
					local obj = g_obj_mgr:create_npc(collect_id, "", pos, self.key, nil)
					if obj then
						obj:set_leave_time(ev.time + self.collect_config[self.collect_item][4])
						self:enter_scene(obj)
						--print("create collect: ", collect_id)
					end
				end
			end
			self.collect_item = self.collect_item + 1
		end
	end
end

function Scene_faction:get_last_time(obj)
	return math.max(self.end_time - ev.time, 0)
end

function Scene_faction:on_obj_enter(obj)
	if obj:get_type() == OBJ_TYPE_HUMAN then
		local obj_id = obj:get_id()
		g_scene_mgr_ex:register_event(EVENT_SET.EVENT_OUT_FACTION, obj_id, self, self.out_faction_event)
		g_scene_mgr_ex:register_event(EVENT_SET.EVENT_KILL_MONSTER, obj_id, self, self.kill_monster_event)

		if self.buff[obj_id] and self.end_time - ev.time > 1 then
			f_add_buff_impact(obj, 2010, 0, self.buff[obj_id][1], self.end_time - ev.time)
		end
	end
end

function Scene_faction:kill_monster_event(monster_id, obj_id)
	--print("Scene_faction:kill_monster_event", monster_id, obj_id)
	if self.boss_occ ~= monster_id then
		return
	end
	if self.is_end == true then
		return
	end
	self.is_end = true
	if ev.time <= self.pass_time and faction_copy_config.config[self.scene_id].layer[self.layer_id+1] then
		local r_layer = g_faction_mgr:get_fb_level(self.instance_id)
		if r_layer == self.layer_id then
			g_faction_mgr:set_fb_level(self.instance_id, self.layer_id+1)
		end
	end
	self:reset_end_time(ev.time)
	self.close_time = self.end_time + 120
	--
	local config = self:get_self_config()
	local comments = faction_copy_config.config[self.scene_id].comments.broadcast
	--local msg = {}
	--f_construct_content(msg, comments[3], 12)
	--f_construct_content(msg, config.boss.name, 53)
	--f_construct_content(msg, comments[4], 12)
	--self:broadcast(msg)

	if self.boss_id ~= nil then
		self:kill_boss_succeed(obj_id)
		self.boss_id = nil	
	end
	local obj = g_obj_mgr:get_obj(obj_id)
	local msg = {}
	f_construct_content(msg, obj and obj:get_name() or f_get_string(2363), 53)
	f_construct_content(msg, comments[1], 12)
	f_construct_content(msg, config.boss.name, 53)
	f_construct_content(msg, comments[2], 12)
	local killer_reward = config.rewards.killer[3]
	for k, v in pairs(killer_reward) do
		f_construct_content(msg, v[3].." ", 53)
	end
	self:broadcast(msg)
end

function Scene_faction:out_faction_event(obj_id)
	if obj_id then
		self:kickout(obj_id)
	end
end

function Scene_faction:kill_boss_succeed(char_id)
	f_scene_info_log("Scene_faction  kill_boss_succeed instance_id:%s, char_id:%d, start_time:%d end_time:%d", self.instance_id, char_id, self.start_time, ev.time)	
	local human_count = self:broadcast_boss_info(true, char_id) or 0
	local pkt = {}
	pkt.faction_id = self.instance_id
	pkt.switch_flag = 0
	pkt.scene_id = self.scene_id
	g_faction_mgr:switch_fb(pkt)
end

function Scene_faction:on_obj_leave(obj)
	local obj_id = obj:get_id()
	if obj:get_type() == OBJ_TYPE_HUMAN then
		g_scene_mgr_ex:unregister_event(EVENT_SET.EVENT_OUT_FACTION, obj_id)
		g_scene_mgr_ex:unregister_event(EVENT_SET.EVENT_KILL_MONSTER, obj_id)
		f_del_impact(obj, 2010)
	elseif obj:get_type() == OBJ_TYPE_MONSTER then
		if obj_id == self.boss_id then
			self.boss_id = nil
		end
	end
end


function Scene_faction:summon_boss()
	local config = self:get_self_config()
	local boss_id = config.boss.occ
	local pos = self.map_obj:find_space(10, 20)
	if pos == nil then
		print("error: pos is nil")
	end
	local monster_o = g_obj_mgr:create_monster(boss_id, pos, self.key)
	if monster_o and SCENE_ERROR.E_SUCCESS == self:enter_scene(monster_o) then
		self.boss_id = monster_o:get_id()
		self.boss_info_time = ev.time - 2
		self.boss_occ = boss_id
	end
end

-- 战斗信息
function Scene_faction:broadcast_boss_info(is_end, killer_id)
	--print("Scene_faction:broadcast_boss_info", is_end, killer_id)
	local boss_o = self.boss_id and g_obj_mgr:get_obj(self.boss_id)
	local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
	local human_l = con and con:get_obj_list()
	if boss_o == nil or human_l == nil then return end
	local result = {}

	local damage_l = {}
	for k, v in pairs(boss_o.damage_l) do
		table.insert(damage_l, {k, -v})
	end

	table.sort(damage_l, function(e1, e2) return e1[2] > e2[2] end)
	local damage_size = #damage_l + 1
	result.hp = boss_o:get_max_hp()
	if is_end and killer_id then
		result.hp = 0
		for k, v in ipairs(damage_l) do
			result.hp = result.hp + v[2]
		end
	end
	result.damage = math.floor((result.hp - boss_o:get_hp()) / result.hp * 100)
	for k, v in ipairs(damage_l) do
		local obj = g_obj_mgr:get_obj(v[1])
		if self.info_list[v[1]] == nil then
			self.info_list[v[1]] = {}
			self.info_list[v[1]][2] = obj and obj:get_id() or 0
			self.info_list[v[1]][3] = obj and obj:get_name() or f_get_string(2363)
		end
		self.info_list[v[1]][1] = k
		self.info_list[v[1]][4] = v[2]
		--奖励
		local reward = {0, 0}
		if is_end then
			local config = self:get_self_config()
			local rewards = config.rewards
			local comments = faction_copy_config.config[self.scene_id].comments
			local item_email_list = {}
			reward[1] = math.floor(math.min(rewards.common[1][3], v[2] / result.hp) * rewards.common[1][1]) 
			reward[2] = math.floor(math.min(rewards.common[1][3], v[2] / result.hp) * rewards.common[2][1]) 
			for k, v in pairs(rewards.common[3] or {}) do
				local item = {}
				item.name = v[3]
				item.id = v[1]
				item.count  = v[2]
				table.insert(item_email_list, item)
			end
			--
			if v[1] == killer_id then
				reward[1] = reward[1] + (rewards.killer[1] and rewards.killer[1][1] or 0)
				reward[2] = reward[2] + (rewards.killer[2] and rewards.killer[2][1] or 0)
				for k, v in pairs(rewards.killer[3] or {}) do
					local item = {}
					item.name = v[3]
					item.id = v[1]
					item.count  = v[2]
					table.insert(item_email_list, item)
				end
			end
			local top_i_reward = rewards.top[k]
			if top_i_reward then
				reward[1] = reward[1] + (top_i_reward[1] and top_i_reward[1][1] or 0)
				reward[2] = reward[2] + (top_i_reward[2] and top_i_reward[2][1] or 0)
				for k, v in pairs(top_i_reward[3] or {}) do
					local item = {}
					item.name = v[3]
					item.id = v[1]
					item.count  = v[2]
					table.insert(item_email_list, item)
				end
			end
			self.info_list[v[1]][5] = reward
			if obj ~= nil then
				obj:add_exp(reward[1])
				local faction = g_faction_mgr:get_faction_by_cid(v[1])
				if faction ~= nil then
					local pkt = {}
					pkt.contribution = {{v[1], reward[2]}}
					g_faction_mgr:add_content(faction:get_faction_id(), pkt)
				end
			end
			--发邮件奖励包
			if #item_email_list > 0 then
				local pkt = {}
				pkt.sender = -1
				pkt.recevier = v[1]
				pkt.title = comments.email[1]
				pkt.content = comments.email[3]
				pkt.box_title = comments.email[2]
				pkt.item_list = item_email_list
				pkt.money_list = {}
				g_svsock_mgr:send_server_ex(COMMON_ID, 0, CMD_M2P_SEND_EMAIL_S, pkt)
				--print("+++ email:", CMD_M2P_SEND_EMAIL_S)
			end
		end
	end
	
	if is_end then
		result.time = ev.time - self.start_time
		result.boss_id = boss_o:get_occ()
		result.killer_id = killer_id or 0
		--广播
		local config = self:get_self_config()
		local comments = faction_copy_config.config[self.scene_id].comments.broadcast
		local msg = {}
		if killer_id == nil then
			f_construct_content(msg, comments[8], 12)
		else
			f_construct_content(msg, comments[3], 12)
		end
		f_construct_content(msg, config.boss.name, 53)
		if killer_id == nil then
			f_construct_content(msg, comments[9], 12)
		else
			f_construct_content(msg, comments[4], 12)
		end
		self:broadcast(msg)

		local msg = {}
		f_construct_content(msg, comments[5], 12)
		local is_in = false
		for i = 1, 5 do
			local obj_id = damage_l[i] and damage_l[i][1]
			if obj_id == nil then
				break
			end
			is_in = true
			local obj = g_obj_mgr:get_obj(obj_id)
			local name = obj and obj:get_name() or (self.info_list[obj_id] and self.info_list[obj_id][3])
			f_construct_content(msg, string.format(comments[6], i), 12)
			f_construct_content(msg, name or " ", 53)
		end
		if is_in then
			if killer_id == nil then
				f_construct_content(msg, comments[10], 12)
			else
				f_construct_content(msg, comments[7], 12)
			end
			self:broadcast(msg)
		end
	end
	for obj_id, _ in pairs(human_l) do
		result.list = {}
		local index = 1
		local end_index = 1
		if self.info_list[obj_id] == nil then
			local obj = g_obj_mgr:get_obj(obj_id)
			self.info_list[obj_id] = {}
			self.info_list[obj_id][1] = damage_size
			self.info_list[obj_id][2] = obj and obj:get_id() or 0
			self.info_list[obj_id][3] = obj and obj:get_name() or f_get_string(2363)
			self.info_list[obj_id][4] = 0
			self.info_list[obj_id][5] = {0, 0}
			index = math.max(1, damage_size - 5)
			end_index = damage_size - 1
		else
			index = math.max(1, self.info_list[obj_id][1] - 5)
			if boss_o.damage_l[obj_id] == nil then
				self.info_list[obj_id][1] = damage_size
				end_index = math.min(index + 4, damage_size - 1)
			else
				end_index = math.min(index + 5, damage_size - 1)
			end
		end
		if is_end then
			index = 1
			end_index = math.min(50, damage_size - 1)
		end
		for i = index, end_index do 
			table.insert(result.list, self.info_list[damage_l[i][1]])
		end
		if boss_o.damage_l[obj_id] == nil then
			table.insert(result.list, self.info_list[obj_id])
		end
		--print("info:", j_e(result))
		if is_end then
			result.time = boss_o.attack_time_l[obj_id] and (ev.time - boss_o.attack_time_l[obj_id]) or result.time
			self:send_human(obj_id, CMD_FACTION_COPY_END_INFO_S, result)
		else
			self:send_human(obj_id, CMD_FACTION_COPY_FIGHTING_INFO_S, result)
		end
	end
	return damage_size - 1
end

--1为使用铜币/铜券，2为使用元宝/礼券
function Scene_faction:add_buff(char_id, type)
	--print("Scene_faction:add_buff", char_id, type)
	if type == 0 then
		local new_pkt = {}
		new_pkt.buff = self.buff[char_id] and self.buff[char_id][1] or 0
		g_cltsock_mgr:send_client(char_id, CMD_FACTION_COPY_ADD_BUFF_S, new_pkt)
		return -1
	end
	local obj = g_obj_mgr:get_obj(char_id)
	if self.buff[char_id] == nil then
		self.buff[char_id] = {0, 0}
	end
	if self.buff[char_id][2] >= math.ceil(math.max(1, obj:get_level() - 30) / 3) then
		return 31230, self.buff[char_id][1]
	end
	local probability = 0
	if type == 1 then
		local pack_con = obj:get_pack_con()
		local money_list = {}
		money_list[MoneyType.GIFT_GOLD] = self.buff_config.gold[1]
		local ret_code = pack_con:dec_money_l_inter_face(money_list, {["type"] = MONEY_SOURCE.FACTION_COPY}, 1)
		if ret_code ~= 0 then
			ret_code = ret_code == 43067 and -1 or ret_code
			return ret_code, self.buff[char_id][1]
		end
		probability = self.buff_config.gold[2]
	elseif type == 2 then
		local pack_con = obj:get_pack_con()
		local money_list = {}
		money_list[MoneyType.GIFT_JADE] = self.buff_config.jade[1]
		local ret_code = pack_con:dec_money_l_inter_face(money_list, {["type"] = MONEY_SOURCE.FACTION_COPY})
		if ret_code ~= 0 then
			ret_code = ret_code == 43067 and -1 or ret_code
			return ret_code, self.buff[char_id][1]
		end
		probability = self.buff_config.jade[2]
	else
		return 31231, self.buff[char_id][1]
	end

	if _random(0, 100) >= probability then
		return 31232, self.buff[char_id][1]
	end

	local level = g_faction_mgr:get_inspire_buff(self.instance_id)
	local point = self.buff_config.list[level] or 200
	self.buff[char_id][1] = self.buff[char_id][1] + point
	self.buff[char_id][2] = self.buff[char_id][2] + 1
	--
	f_add_buff_impact(obj, 2010, 0, self.buff[char_id][1], self.end_time - ev.time)

	return 0, self.buff[char_id][1]
end

--帮派广播
function Scene_faction:broadcast(msg)
	--print("Scene_faction:broadcast", Json_encode(msg))
	local pkt = {}
	pkt.msg = msg
	pkt.bdc_type = 4
	pkt.msg_type = 5
	pkt.f_id = self.instance_id
	g_svsock_mgr:send_server_ex(WORLD_ID, 0, CMD_C2W_FACTION_BROADCAST_S, pkt)
end

function Scene_faction:get_mode()
	local config = g_scene_config_mgr:get_config(self.scene_id)
	return config and config.mode
end

function Scene_faction:get_type()
	local config = g_scene_config_mgr:get_config(self.scene_id)
	return config and config.type
end

function Scene_faction:get_limit()
	local config = g_scene_config_mgr:get_config(self.scene_id)
	return (config and config.limit) or 0
end