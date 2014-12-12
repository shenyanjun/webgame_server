local manor_config = require("scene_ex.config.faction_manor_loader")
local _manor_config = require("config.faction_manor_config")
--local integral_func = require("mall.integral_func")

local _broadcast_time = 4 * 60		-- 庄园异兽剩余个数广播时间
local _summon_boss_info_time = 10	-- 庄园召唤boss战斗信息

Scene_faction_manor = oo.class(Scene_instance, "Scene_faction_manor")
function Scene_faction_manor:__init(map_id, instance_id, map_obj)
	Scene_instance.__init(self, map_id, instance_id, map_obj)

	self.refresh_type = 0
	self.close_time = nil
	self.start_time = ev.time
	self.is_success = false
	
	self.rob_npc = {} 		-- 强盗NPC，用于传送到庄园强盗副本
	self.rob_npc_size = 0
	self.rob_team = {}		-- 流水记录
	self.refurbish_count = 0
	if instance_id then
		self.f_id = string.sub(instance_id, 7, -1)
	end
	self.status = SCENE_STATUS.IDLE
	self.broadcast_time = ev.time

	-- 庄园召唤boss相关数据
	self.summon_boss_id = nil			-- 如果不空则已召唤boss
	self.summon_boss_time = nil			-- 召唤boss的时间
	self.summon_player_id = nil			-- 召唤的玩家ID
	self.summon_player_name = ""		-- 召唤的玩家名字
	self.summon_info_list = {}			-- {{排名，玩家ID，玩家名字，伤害值，奖励礼券数}}
	self.summon_boss_info_time = ev.time
	self.summon_boss_times = 0			-- 已经召唤的次数

	-- 庄园召唤神兽相关数据
	self.summon_dogz_id = nil
	self.summon_dogz_time = nil
	self.summon_dogz_times = 0
	self.summon_dogz_entry = nil
	self.summon_dogz_leave_time = nil
	self.collected_info = nil
end


function Scene_faction_manor:get_self_config()
	return manor_config.config[self.id]
end

--副本出口
function Scene_faction_manor:get_home_carry(obj)
	local config = self:get_self_config()
	local home_carry = config and config.home
	if not home_carry or not home_carry.id
		or not home_carry.pos or not home_carry.pos[1] or not home_carry.pos[2] then
		return nil, nil
	end
	return home_carry.id, home_carry.pos
end

function Scene_faction_manor:carry_scene(obj, pos)
	if not obj then
		return SCENE_ERROR.E_NOT_ON_SCENE, nil
	end

	local config = self:get_self_config()
	if not config then
		return SCENE_ERROR.E_SCENE_CLOSE, nil
	end
	
	local obj_id = obj:get_id()
	
	if not self.owner_list[obj_id] then
		self.owner_list[obj_id] = true
	end
	
	return self:push_scene(obj, pos)
end


function Scene_faction_manor:check_success()

	for k, v in ipairs(self.rob_npc) do
		local npc_obj = g_obj_mgr:get_obj(v)
		if npc_obj ~= nil then
			npc_obj:leave()
		end
	end
	self.rob_npc = {}

	if self.refurbish_count > 0 then
		local rob_size = table.size(self.rob_team)
		local faction = g_faction_mgr:get_faction_by_fid(self.f_id)
		local faction_name = faction and faction:get_faction_name() or ""
		--后台流水
		local str = string.format("insert into log_faction_monster set faction_id='%s', faction_name='%s', refurbish_time=%d, refurbish_count=%d, keep_count=%d, item_count=%d, create_time=%d",
									self.f_id, faction_name, self.refurbish_time, self.refurbish_count, self.rob_npc_size, rob_size, ev.time)
		f_multi_web_sql(str)
	end
	self.refurbish_count = 0
	self.rob_team = {}

	if self.rob_npc_size <= 0 then
		--f_scene_info_log("manor rob succeed f_id:%s", self.f_id)
	else
		local new_pkt = {}
		new_pkt.f_id = self.f_id
		g_svsock_mgr:send_server_ex(COMMON_ID, 0, CMD_M2C_FACTION_MANOR_ROBBER_C, new_pkt)
		--f_scene_info_log("manor rob fail f_id:%s", self.f_id)
		local new_pkt2 = {}
		new_pkt2.type = 29
		new_pkt2.f_id = self.f_id
		new_pkt2.fail = 1
		g_svsock_mgr:send_server_ex(COMMON_ID, 0, CMD_M2C_FACTION_MANOR_SET_HISTORY_C, new_pkt2)
	end
	return self.rob_npc_size <= 0
end

function Scene_faction_manor:check_close()
	local con_human = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
	local con_monster = self.obj_mgr:get_obj_con(OBJ_TYPE_MONSTER)
	if (con_human == nil or table.is_empty(con_human:get_obj_list()) )
		and (con_monster == nil or table.is_empty(con_monster:get_obj_list()) ) then
		self:close()
	end
end

function Scene_faction_manor:the_end()
--[[
	local pkt = {}
	pkt.faction_id = self.instance_id
	pkt.switch_flag = 0
	pkt.scene_id = self.id
	g_faction_mgr:switch_fb(pkt)
]]
	self:check_success()
--[[
	self.close_time = ev.time + 30
	
	--local result = self:do_reward()
	if self.obj_mgr then
	
		if result then
			local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
			if con then
				for obj_id, _ in pairs(con:get_obj_list()) do
					self:send_human(obj_id, CMD_MAP_INVASION_SETTLEMENT_NOTIFY, result)
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
	]]
end

function Scene_faction_manor:on_timer(tm)
	local now = ev.time

	if self.status == SCENE_STATUS.OPEN then
		if ev.time >= self.broadcast_time + _broadcast_time then
			self.broadcast_time = ev.time
			self:broadcast(self.rob_npc_size)
		end
	end

	--
	if self.summon_boss_id ~= nil then
		if ev.time > self.summon_boss_time + _manor_config.SUMMON_BOSS_FIGHTING_TIME then
			local monster_o = g_obj_mgr:get_obj(self.summon_boss_id)
			local _ = monster_o and monster_o:leave()
		elseif ev.time >= self.summon_boss_info_time + _summon_boss_info_time then
			self:broadcast_summon_boss_info(false, false)
			self.summon_boss_info_time = ev.time + _summon_boss_info_time
		end
	end

	if self.summon_dogz_id ~= nil then
		if ev.time > self.summon_dogz_leave_time then
			local monster_o = g_obj_mgr:get_obj(self.summon_dogz_id)
			local _ = monster_o and monster_o:leave()
		end
	end

	self.obj_mgr:on_timer(tm)
end


function Scene_faction_manor:can_summon_boss(obj, boss_id)
	
	if self.summon_boss_id ~= nil or _manor_config._summon_boss[boss_id] == nil then
		return 22265
	end

	if self.summon_boss_time ~= nil then
		local last_day = os.date("*t", self.summon_boss_time)
		local now_day = os.date("*t", ev.time)
		if last_day.day ~= now_day.day then
			self.summon_boss_times = 0
		end
	end

	if self.summon_boss_times >= _manor_config.FACTION_SUMMON_BOSS_TIMES then
		return 22260
	end

	local con = obj:get_copy_con()
	if con:get_count_copy(self.id) >= _manor_config.PLAYER_SUMMON_BOSS_TIMES then
		return 22261
	end

	local entry = _manor_config._summon_boss[boss_id]
	if g_faction_manor_mgr:get_level(self.f_id) < entry[5] then
		return 22262
	end
	if obj:get_level() < entry[4] then
		return 22263
	end
	local pack_con = obj:get_pack_con()
	--if pack_con:check_money_lock(MoneyType.JADE) then return -1 end
	--local money = pack_con:get_money()
	--if money.jade < entry[1] then 
		--return 22264 
	--end

	return 0
end

function Scene_faction_manor:pre_summon_boss(obj, boss_id)
	local r = self:can_summon_boss(obj, boss_id)
	if r ~= 0 then return r end

	local ret = {}
	ret.price = _manor_config._summon_boss[boss_id][1]

	return 0, ret
end

function Scene_faction_manor:summon_boss(obj, boss_id)
	local r = self:can_summon_boss(obj, boss_id)
	if r ~= 0 then return r end

	local pos = _manor_config.SUMMON_BOSS_POS
	local monster_o = g_obj_mgr:create_monster(boss_id, pos, self.key)
	if monster_o and SCENE_ERROR.E_SUCCESS == self:enter_scene(monster_o) then
		self.summon_boss_id = monster_o:get_id()
		self.summon_boss_time = ev.time
		self.summon_player_id = obj:get_id()
		self.summon_player_name = obj:get_name()
		self.summon_boss_info_time = ev.time - 5
		self.summon_boss_times = self.summon_boss_times + 1
		--扣元宝
		local pack_con = obj:get_pack_con()
		--pack_con:dec_money(MoneyType.JADE, _manor_config._summon_boss[boss_id][1], {['type']=MONEY_SOURCE.SUMMON_BOSS})
		--integral_func.add_bonus(obj:get_id(), _manor_config._summon_boss[boss_id][1], {['type']=MONEY_SOURCE.SUMMON_BOSS})
		--加召唤奖励
		local money_list = {}
		money_list[MoneyType.GIFT_JADE] = _manor_config._summon_boss[boss_id][6]						
		pack_con:add_money_l(money_list, {["type"] = MONEY_SOURCE.SUMMON_BOSS})

		local con = obj:get_copy_con()
		con:add_count_copy(self.id)
		--帮派广播
		local msg = {}
		f_construct_content(msg, obj and obj:get_name() or f_get_string(2363), 53)
		f_construct_content(msg, f_get_string(2392), 12)
		f_construct_content(msg, f_get_string(boss_id-2837), 53)
		f_construct_content(msg, f_get_string(2393), 12)
		local pkt = {}
		pkt.msg = msg
		pkt.bdc_type = 4
		pkt.msg_type = 5
		pkt.f_id = self.f_id
		g_svsock_mgr:send_server_ex(WORLD_ID, 0, CMD_C2W_FACTION_BROADCAST_S, pkt)

		f_scene_info_log("manor summon boss f_id:%s char_id:%d boss_id:%d", self.f_id, obj:get_id(), boss_id)
	end
	return 0, _manor_config._summon_boss[boss_id][6]
end

function Scene_faction_manor:instance()
	local config = self:get_self_config()
	self.end_time = 0
	self.obj_mgr:instance(self.map_obj:get_w(), self.map_obj:get_h())
end

function Scene_faction_manor:get_last_time(obj)
	return math.max(self.end_time - ev.time, 0)
end

function Scene_faction_manor:on_obj_enter(obj)
	if obj:get_type() == OBJ_TYPE_HUMAN then
		local obj_id = obj:get_id()
		g_scene_mgr_ex:register_event(EVENT_SET.EVENT_OUT_FACTION, obj_id, self, self.out_faction_event)
		g_scene_mgr_ex:register_event(EVENT_SET.EVENT_KILL_MONSTER, obj_id, self, self.kill_monster_event)
	end
end

function Scene_faction_manor:kill_monster_event(monster_id, obj_id)
	if self.summon_boss_id ~= nil then
		local obj = g_obj_mgr:get_obj(self.summon_boss_id)
		if obj and obj:get_occ() == monster_id then
			self:kill_summon_boss_succeed(obj)

			self.summon_boss_id = nil	
			self.summon_player_id = nil	
			self.summon_info_list = {}
		end
	end
	if self.summon_dogz_id ~= nil then
		local obj = g_obj_mgr:get_obj(self.summon_dogz_id)
		if obj and obj:get_occ() == monster_id then
			self:kill_summon_dogz_succeed(obj)
			self.summon_dogz_id = nil
		end
	end
end

function Scene_faction_manor:out_faction_event(obj_id)
	if obj_id then
		self:kickout(obj_id)
	end
end

function Scene_faction_manor:on_obj_leave(obj)
	local obj_id = obj:get_id()
	local obj_type = obj:get_type()
	if obj_type == OBJ_TYPE_HUMAN then
		g_scene_mgr_ex:unregister_event(EVENT_SET.EVENT_OUT_FACTION, obj_id)
		g_scene_mgr_ex:unregister_event(EVENT_SET.EVENT_KILL_MONSTER, obj_id)
	elseif obj_type == OBJ_TYPE_MONSTER then
		if self.summon_boss_id == obj_id then
			if ev.time <= self.summon_boss_time + _manor_config.SUMMON_BOSS_FIGHTING_TIME then
				self:kill_summon_boss_succeed(obj)
			else
				self:kill_summon_boss_faild(obj)
			end
			self.summon_boss_id = nil	
			self.summon_player_id = nil	
			self.summon_info_list = {}
		elseif self.summon_dogz_id == obj_id then
			self.summon_dogz_id = nil
			--
			local pkt = {}
			pkt.faction_id = self.f_id
			pkt.switch_flag = 0
			pkt.scene_id = self.id
			g_faction_mgr:switch_fb(pkt)
		end
	end
end

function Scene_faction_manor:notify_status(status, args)
	--print("Scene_faction_manor:notify_status()", status)
	
	self.status = status
	local config = self:get_self_config()
	if self.status == SCENE_STATUS.OPEN then
		self:reset_end_time(ev.time + config.limit.timeout.number)
		self.refresh_type = args.refresh_type
		if config.rob and self.refresh_type > 0 then
			self.rob_npc = {}
			self.rob_npc_size = 0
			for k, item in ipairs(config.rob) do
				local refresh_time = self.refresh_type == 1 and item.type1 or self.refresh_type == 2 and item.type2 or item.type3
				for i = 1, refresh_time do
					local pos = self.map_obj:find_space(item.area, 20)
					local obj = pos and g_dynamic_npc_mgr:create_dynamic_npc(item.id, item.name, self.key, 
						pos, config.limit.timeout.number, {['action_id'] = item.action_id} )
					if obj ~= nil then
						table.insert(self.rob_npc, obj:get_id())
						self.rob_npc_size = self.rob_npc_size + 1
					end
				end
			end
			self.refurbish_time = ev.time
			self.refurbish_count = self.rob_npc_size
			local pkt = {}
			pkt.type = 28
			pkt.size = self.rob_npc_size
			pkt.f_id = self.f_id
			g_svsock_mgr:send_server_ex(COMMON_ID, 0, CMD_M2C_FACTION_MANOR_SET_HISTORY_C, pkt)
			f_scene_info_log("manor rob open f_id:%s refresh_type:%d rob_npc_size:%d", self.f_id, self.refresh_type, self.rob_npc_size)
			self.broadcast_time = ev.time
		end

	elseif self.status == SCENE_STATUS.IDLE then
		self:the_end()
		self.rob_npc_size = 0
		self.refurbish_count = 0
		self.refresh_type = 0
	end
end


function Scene_faction_manor:notify_rob_succeed(char_id)
	--print("Scene_faction_manor:notify_rob_succeed()", char_id)
--[[
	self.rob_npc_size = self.rob_npc_size - 1
	f_scene_info_log("manor rob npc succeed f_id:%s teamer_id:%d rob_npc_size:%d", self.f_id, char_id, self.rob_npc_size)
	if self.rob_npc_size == 0 then
		local pkt = {}
		pkt.type = 29
		pkt.f_id = self.f_id
		g_svsock_mgr:send_server_ex(COMMON_ID, 0, CMD_M2C_FACTION_MANOR_SET_HISTORY_C, pkt)
	end	
]]
end

function Scene_faction_manor:notify_rob_start(char_id)
	--print("Scene_faction_manor:notify_rob_start()", char_id)
	local team_id = g_obj_mgr:get_obj(char_id):get_team()
	--local team_o = team_id and g_team_mgr:get_team_obj(team_id)
	if team_id ~= nil then
		self.rob_team[team_id] = 1
	end
	--
	self.rob_npc_size = self.rob_npc_size - 1
	f_scene_info_log("manor rob npc succeed f_id:%s teamer_id:%d rob_npc_size:%d", self.f_id, char_id, self.rob_npc_size)
	if self.rob_npc_size == 0 then
		local pkt = {}
		pkt.type = 29
		pkt.f_id = self.f_id
		g_svsock_mgr:send_server_ex(COMMON_ID, 0, CMD_M2C_FACTION_MANOR_SET_HISTORY_C, pkt)
	end
end

-- 判断此庄园是否是自己帮的
function Scene_faction_manor:is_own_manor(char_id)
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	local f_id = faction and faction:get_faction_id()
	return f_id == self.f_id
end

-- 得到此庄园所属的帮的ID
function Scene_faction_manor:get_manor_owner()
	return self.f_id
end

--广播
function Scene_faction_manor:broadcast(size)	
	if not size or size <= 0 then return end
	local msg = {}
	f_construct_content(msg, f_get_string(2361), 12)
	f_construct_content(msg, tostring(size), 53)
	f_construct_content(msg, f_get_string(2362), 12)

	local pkt = {}
	pkt.msg = msg
	pkt.bdc_type = 4
	pkt.msg_type = 5
	pkt.f_id = self.f_id
	g_svsock_mgr:send_server_ex(WORLD_ID, 0, CMD_C2W_FACTION_BROADCAST_S, pkt)
end

-- 召唤boss战斗信息
function Scene_faction_manor:broadcast_summon_boss_info(is_end, is_succeed)
	local boss_o = self.summon_boss_id and g_obj_mgr:get_obj(self.summon_boss_id)
	local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
	local human_l = con and con:get_obj_list()
	if boss_o == nil or human_l == nil or table.is_empty(human_l) then return end
	local result = {}

	local damage_l = {}
	for k, v in pairs(boss_o.damage_l) do
		table.insert(damage_l, {k, -v})
	end

	table.sort(damage_l, function(e1, e2) return e1[2] > e2[2] end)
	local damage_size = #damage_l + 1
	result.gold = 0
	result.hp = boss_o:get_max_hp()
	if is_end and is_succeed then
		result.hp = 0
		for k, v in ipairs(damage_l) do
			result.hp = result.hp + v[2]
		end
	end
	result.damage = math.floor((result.hp - boss_o:get_hp()) / result.hp * 100)
	for k, v in ipairs(damage_l) do
		if self.summon_info_list[v[1]] == nil then
			local obj = g_obj_mgr:get_obj(v[1])
			self.summon_info_list[v[1]] = {}
			self.summon_info_list[v[1]][2] = obj and obj:get_id() or 0
			self.summon_info_list[v[1]][3] = obj and obj:get_name() or f_get_string(2363)
		end
		self.summon_info_list[v[1]][1] = k
		self.summon_info_list[v[1]][4] = v[2]
		local dm = 0
		if not is_end or is_succeed then
			dm = math.floor(v[2] / result.hp * _manor_config._summon_boss[boss_o:get_occ()][2])  + _manor_config._f_get_foundation_award(boss_o:get_occ(), damage_size - 1)
		end
		self.summon_info_list[v[1]][5] = dm
		result.gold = result.gold + dm
	end
	
	if is_end then
		result.time = ev.time - self.summon_boss_time
		result.boss_id = boss_o:get_occ()
	end
	for obj_id, _ in pairs(human_l) do
		result.list = {}
		local index = 1
		local end_index = 1
		if self.summon_info_list[obj_id] == nil then
			local obj = g_obj_mgr:get_obj(obj_id)
			self.summon_info_list[obj_id] = {}
			self.summon_info_list[obj_id][1] = damage_size
			self.summon_info_list[obj_id][2] = obj and obj:get_id() or 0
			self.summon_info_list[obj_id][3] = obj and obj:get_name() or f_get_string(2363)
			self.summon_info_list[obj_id][4] = 0
			self.summon_info_list[obj_id][5] = 0
			index = math.max(1, damage_size - 5)
			end_index = damage_size - 1
		else
			index = math.max(1, self.summon_info_list[obj_id][1] - 5)
			if boss_o.damage_l[obj_id] == nil then
				self.summon_info_list[obj_id][1] = damage_size
				end_index = math.min(index + 4, damage_size - 1)
			else
				end_index = math.min(index + 5, damage_size - 1)
			end
		end
		if is_end then
			index = 1
			end_index = damage_size - 1
		end
		for i = index, end_index do 
			table.insert(result.list, self.summon_info_list[damage_l[i][1]])
		end
		if boss_o.damage_l[obj_id] == nil then
			table.insert(result.list, self.summon_info_list[obj_id])
		end
		--print("info:", j_e(result))
		if is_end then
			result.time = boss_o.attack_time_l[obj_id] and (ev.time - boss_o.attack_time_l[obj_id]) or result.time
			self:send_human(obj_id, CMD_FACTION_MANOR_BOSS_END_INFO_S, result)
		else
			self:send_human(obj_id, CMD_FACTION_MANOR_BOSS_FIGHTING_INFO_S, result)
		end
	end
	return damage_size - 1
end

-- 成功杀死召唤的boss
function Scene_faction_manor:kill_summon_boss_succeed(boss_o)
	--print("kill_summon_boss_succeed")
	local human_count = self:broadcast_summon_boss_info(true, true) or 0
	local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
	local human_l = con and con:get_obj_list()
	for char_id, v in pairs(self.summon_info_list) do
		if v[5] > 0 then
			local obj = g_obj_mgr:get_obj(char_id)
			if obj and human_l[char_id] then
				local pack_con = obj:get_pack_con()
				local money_list = {}
				money_list[MoneyType.GIFT_JADE] = v[5]						
				local src_log = {["type"] = MONEY_SOURCE.SUMMON_BOSS}
				pack_con:add_money_l(money_list, src_log)
			else
				--发邮件奖励包
				local pkt = {}
				pkt.sender = -1
				pkt.recevier = char_id
				pkt.title = f_get_string(2366)
				pkt.content = f_get_string(2367)
				pkt.box_title = f_get_string(2366)
				pkt.item_list = {}
				pkt.money_list = {}
				pkt.money_list[MoneyType.GIFT_JADE] = v[5]
				g_svsock_mgr:send_server_ex(COMMON_ID, 0, CMD_M2P_SEND_EMAIL_S, pkt)
			end
		end
	end
	-- 发召唤者额外奖励
	local pkt = {}
	pkt.sender = -1
	pkt.recevier = self.summon_player_id
	pkt.title = f_get_string(2368)
	pkt.content = f_get_string(2369)
	pkt.box_title = f_get_string(2368)
	pkt.item_list = {{id=_manor_config.EXTRA_PROP_ID, count=_manor_config._summon_boss[boss_o:get_occ()][3], name=f_get_string(2370)}}
	pkt.money_list = {}
	g_svsock_mgr:send_server_ex(COMMON_ID, 0, CMD_M2P_SEND_EMAIL_S, pkt)
	--帮派广播
	local msg = {}
	f_construct_content(msg, f_get_string(boss_o:get_occ()-2837), 53)
	f_construct_content(msg, f_get_string(2395), 12)
	local pkt = {}
	pkt.msg = msg
	pkt.bdc_type = 4
	pkt.msg_type = 5
	pkt.f_id = self.f_id
	g_svsock_mgr:send_server_ex(WORLD_ID, 0, CMD_C2W_FACTION_BROADCAST_S, pkt)

	--后台流水
	local faction = g_faction_mgr:get_faction_by_fid(self.f_id)
	local str = string.format("insert into log_summon set faction_id='%s', faction_name='%s', monster_id=%d, monster_name='%s', is_killed=%d, char_count=%d, create_time=%d, char_id=%d, char_name='%s' ",
								self.f_id, faction and faction:get_faction_name() or "", boss_o:get_occ(), f_get_string(boss_o:get_occ()-2837), 1, human_count, self.summon_boss_time, self.summon_player_id, self.summon_player_name)
	f_multi_web_sql(str)

	self.summon_boss_id = nil
end

-- 没有杀死召唤的boss
function Scene_faction_manor:kill_summon_boss_faild(boss_o)
	--print("kill_summon_boss_faild")
	local human_count = self:broadcast_summon_boss_info(true, false) or 0
--[[
	--发邮件奖励包
	local pkt = {}
	pkt.sender = -1
	pkt.recevier = self.summon_player_id
	pkt.title = f_get_string(2364)
	pkt.content = f_get_string(2365)
	pkt.box_title = f_get_string(2364)
	pkt.item_list = {}
	pkt.money_list = {}
	pkt.money_list[MoneyType.JADE] = math.floor(_manor_config._summon_boss[boss_o:get_occ()][1] / 2)
	g_svsock_mgr:send_server_ex(COMMON_ID, 0, CMD_M2P_SEND_EMAIL_S, pkt)
]]
	--帮派广播
	local msg = {}
	local obj = g_obj_mgr:get_obj(self.summon_player_id)
	f_construct_content(msg, f_get_string(2396), 12)
	f_construct_content(msg, obj and obj:get_name() or f_get_string(2363), 53)
	f_construct_content(msg, f_get_string(2397), 12)
	f_construct_content(msg, f_get_string(boss_o:get_occ()-2837), 53)
	f_construct_content(msg, f_get_string(2398), 12)
	local pkt = {}
	pkt.msg = msg
	pkt.bdc_type = 4
	pkt.msg_type = 5
	pkt.f_id = self.f_id
	g_svsock_mgr:send_server_ex(WORLD_ID, 0, CMD_C2W_FACTION_BROADCAST_S, pkt)
	--后台流水
	local faction = g_faction_mgr:get_faction_by_fid(self.f_id)
	local str = string.format("insert into log_summon set faction_id='%s', faction_name='%s', monster_id=%d, monster_name='%s', is_killed=%d, char_count=%d, create_time=%d, char_id=%d, char_name='%s' ",
								self.f_id, faction and faction:get_faction_name() or "", boss_o:get_occ(), f_get_string(boss_o:get_occ()-2837), 2, human_count, self.summon_boss_time, self.summon_player_id, self.summon_player_name)
	f_multi_web_sql(str)

	self.summon_boss_id = nil
end


--神兽召唤
function Scene_faction_manor:can_summon_dogz(char_id, level, stage)
	
	if self.summon_dogz_id ~= nil or _manor_config._summon_dogz[level] == nil or _manor_config._summon_dogz[level][stage] == nil then
		return 22271
	end
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	local f_id = faction and faction:get_faction_id()
	if f_id ~= self.f_id then
		return 22275
	end

	local now_day = os.date("*t")
	if self.summon_dogz_time ~= nil then
		local last_day = os.date("*t", self.summon_dogz_time)
		if last_day.day ~= now_day.day then
			self.summon_dogz_times = 0
		end
	end
	if self.summon_dogz_times >= _manor_config.FACTION_SUMMON_DOGZ_TIMES then
		return 22260
	end

	if _manor_config.SUMMON_DOGZ_DAY[now_day.wday] == nil then
		return 22272
	end

	now_day.hour = _manor_config.SUMMON_DOGZ_END_TIME[1]
	now_day.min = _manor_config.SUMMON_DOGZ_END_TIME[2]
	now_day.sec = 0
	self.summon_dogz_leave_time = os.time(now_day)
	if ev.time >= self.summon_dogz_leave_time then
		return 22272
	end

	return 0
end

function Scene_faction_manor:summon_dogz(char_id, level, stage)
	local r = self:can_summon_dogz(char_id, level, stage)
	if r ~= 0 then return r end

	local pos = _manor_config.SUMMON_DOGZ_POS
	local entry = _manor_config._summon_dogz[level][stage]
	local monster_o = g_obj_mgr:create_monster(entry.boss_id, pos, self.key)
	if monster_o and SCENE_ERROR.E_SUCCESS == self:enter_scene(monster_o) then
		self.summon_dogz_id = monster_o:get_id()
		self.summon_dogz_time = ev.time
		self.summon_dogz_times = self.summon_dogz_times + 1
		self.summon_dogz_entry = entry

		f_scene_info_log("manor summon dogz f_id:%s level:%d stage:%d", self.f_id, level, stage)
		--
		local pkt = {}
		pkt.faction_id = self.f_id
		pkt.switch_flag = 1
		pkt.scene_id = self.id
		g_faction_mgr:switch_fb(pkt)
	end
	return 0
end

function Scene_faction_manor:kill_summon_dogz_succeed(obj)
	self.collected_info = {}	
	local map_obj = self:get_map_obj()
	local number = self.summon_dogz_entry.coll_number
	local collection_id = self.summon_dogz_entry.collection_id
	local area = _manor_config.COLLECTION_AREA
	local leave_time = ev.time + _manor_config.COLLECTION_LEAVE_TIME
	for i = 1, number do
		local pos = map_obj:find_space(area, 20)
		if pos ~= nil then
			local obj = g_obj_mgr:create_npc(collection_id, "", pos, self.key, nil)
			self:enter_scene(obj)
			obj:set_leave_time(leave_time)
			--print("create npc: ", collection_id, pos[1], pos[2], leave_time)
		end
	end
	--
	local pkt = {}
	pkt.faction_id = self.f_id
	pkt.switch_flag = 0
	pkt.scene_id = self.id
	g_faction_mgr:switch_fb(pkt)
end

function Scene_faction_manor:can_be_collected_dogz(char_id, coll_id)
	--print("Scene_faction_manor:can_be_collected_dogz()", char_id, coll_id)
	if self.collected_info == nil or (self.collected_info[char_id] or 0) >= self.summon_dogz_entry.coll_times then
		return 22273
	end

	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	local f_id = faction and faction:get_faction_id()
	if f_id ~= self.f_id then
		return 22274
	end
	return 0
end

function Scene_faction_manor:obj_be_collected_dogz(char_id, coll_id)
	--print("Scene_faction_manor:obj_be_collected_dogz()", char_id, coll_id)
	if self.collected_info ~= nil then
		self.collected_info[char_id] = (self.collected_info[char_id] or 0) + 1
	end
end