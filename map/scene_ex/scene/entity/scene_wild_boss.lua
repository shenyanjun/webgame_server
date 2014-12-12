Scene_wild_boss = oo.class(Scene, "Scene_wild_boss")
local _boss_info_time = 2
local _create_boss_time = 0.5 * 60	--多久后刷boss
local _stay_time = 5 * 60			--杀完boss后停留的时间

local _config = require("scene_ex.config.wild_boss_config_loader")

function Scene_wild_boss:__init(map_id)
	Scene.__init(self, map_id)
	self.start_time = 0
	self.end_time = 0
	self.status = SCENE_STATUS.CLOSE
	
	-- 
	self.boss_index = nil
	self.boss_id = nil					-- 如果不空则已召唤boss
	self.info_list = {}			-- {{排名，玩家ID，玩家名字，伤害值，}}
	self.boss_info_time = ev.time
end

function Scene_wild_boss:instance()

	self.timer_queue = Timer_queue()
	self.obj_mgr:instance(self.map_obj:get_w(), self.map_obj:get_h())
	self:on_new_day()
end

function Scene_wild_boss:open_config(today)
	local config = _config.config[self.id]
	return config and config.summon
end

function Scene_wild_boss:load_config(today)
	local update_list = {}
	
	local today_time = os.time(today)
	
	local entity = self
	local exec =
		function (o, now)
			o.method(entity, o, o.args)
			return false
		end
	local timeout = function (o) end
	--
	local freq_list = self:open_config(today)
	if freq_list and freq_list.open_time then

		for _, time_span in pairs(freq_list.open_time) do
			local open_info = self:build_node(
								today_time + (time_span.hour or 0) * 3600 + (time_span.minu or 0) * 60
								, (time_span.interval or 0) * 60
								, self.boss_open
								, exec
								, timeout)
			--print("time_span", j_e(time_span))
			open_info.args = {["boss_index"] = time_span.boss_index}
			table.insert(update_list, open_info)
			
			local end_info = self:build_node(
				open_info.end_time
				, 5 * 60
				, self.boss_close
				, exec
				, timeout)
			table.insert(update_list, end_info)
			
		end
	end

	return update_list
end

function Scene_wild_boss:boss_open(info, args)
	--print("Scene_wild_boss:boss_open:", self.id, j_e(args))
	self.start_time = ev.time
	self.end_time = info.end_time
	self.status = SCENE_STATUS.OPEN
	self.boss_index = args.boss_index
	self.boss_id = nil
	self.info_list = {}	
end

function Scene_wild_boss:create_boss()
	local info = _config.config[self.id].boss[self.boss_index]
	local obj = g_obj_mgr:create_monster(info.occ, info.pos, self.key)
	if obj then
		self.boss_id = obj:get_id()
		self:enter_scene(obj)
	end
end

function Scene_wild_boss:boss_close()
	--print("Scene_wild_boss:boss_close", self.id)
	self.status = SCENE_STATUS.FREEZE
	self:broadcast_boss_info(true, false)

	local obj = self.boss_id and g_obj_mgr:get_obj(self.boss_id)
	local _ = obj and obj:leave()
	self.boss_id = nil
end

function Scene_wild_boss:can_carry(obj)
	return SCENE_ERROR.E_CARRY
end

function Scene_wild_boss:login_scene(obj, pos)
	return self:carry_scene(obj, _config.config[self.id].entry)
end

function Scene_wild_boss:carry_scene(obj, pos)
	local target_config = g_scene_config_mgr:get_config(self.id)
	if not target_config or ((self.status == SCENE_STATUS.FREEZE or self.status == SCENE_STATUS.CLOSE) and self.boss_id ~= nil) then
		return 21315
	end

	if self.status ~= SCENE_STATUS.OPEN and self.status ~= SCENE_STATUS.IDLE then
		return SCENE_ERROR.E_NOT_OPNE
	end
	
	if target_config.level > obj:get_level() then
		return SCENE_ERROR.E_LEVEL_DOWN
	end
	
	if self:get_human_count() >= target_config.limit then
		return 21314
	end
	
	local entry = _config.config[self.id].entry
	local e_code, e_desc = self:push_scene(obj, entry)
	
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

function Scene_wild_boss:get_last_time(obj)
	return math.max(self.end_time - ev.time, 0)
end

function Scene_wild_boss:get_limit()
	return _config.config[self.id].limit
end

function Scene_wild_boss:on_timer(tm)
	local now_time = ev.time
	
	if self.tomorrow <= now_time then
		self:on_new_day()
	end
	self.timer_queue:exec(now_time)

	if SCENE_STATUS.OPEN == self.status then --可以进入副本
		if now_time >= self.start_time  + _create_boss_time then
			self:create_boss()
			self.status = SCENE_STATUS.IDLE
		end

	elseif SCENE_STATUS.IDLE == self.status then --召唤出boss
		if now_time >= self.boss_info_time then
			self:broadcast_boss_info(false, nil)
			self.boss_info_time = now_time + _boss_info_time
		end
		self.obj_mgr:on_timer(tm)

	elseif SCENE_STATUS.FREEZE == self.status then --时间到或者杀死boss
		if now_time >= self.boss_info_time + _stay_time then
			self.status = SCENE_STATUS.CLOSE
			--
			local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
			if con then
				for obj_id, _ in pairs(con:get_obj_list()) do
					self:kickout(obj_id)
				end
			end
		end
	end	
end


function Scene_wild_boss:on_obj_enter(obj)
	local obj_id = obj:get_id()
	if obj:get_type() == OBJ_TYPE_HUMAN then
		g_scene_mgr_ex:register_event(EVENT_SET.EVENT_KILL_MONSTER, obj_id, self, self.kill_monster_event)
	end
end

function Scene_wild_boss:on_obj_leave(obj)
	local obj_id = obj:get_id()
	if obj:get_type() == OBJ_TYPE_HUMAN then
		g_scene_mgr_ex:unregister_event(EVENT_SET.EVENT_KILL_MONSTER, obj_id)
	end
end

function Scene_wild_boss:kill_monster_event(monster_id, obj_id)
	--print("Scene_wild_boss:kill_monster_event", monster_id, obj_id)
	if self.boss_id == nil then
		return
	end
	self:broadcast_boss_info(true, true)
	self.status = SCENE_STATUS.FREEZE
end

function Scene_wild_boss:get_home_carry(obj)
	return 37100, {59, 58}
end

function Scene_wild_boss:kickout(obj_id)
	local obj = self:get_obj(obj_id)
	--if not obj and self:is_door(obj_id) then
		--obj = g_obj_mgr:get_obj(obj_id)
	--end
	
	if obj then
		if not obj:is_alive() then
			obj:do_relive(nil, true)	--复活
			obj:send_relive(3)
		end
		
		local scene_id, pos = self:get_home_carry(obj)
		g_scene_mgr_ex:push_scene(scene_id, pos, obj)
	end
end

-- 战斗信息
function Scene_wild_boss:broadcast_boss_info(is_end, is_done)
	--print("Scene_wild_boss:broadcast_boss_info", is_end, is_done)
	if self.status == SCENE_STATUS.FREEZE then
		return
	end
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
	if is_end and is_done then
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
		if is_end and is_done then
			local config = _config.config[self.id]
			local info = config.boss[self.boss_index]
			local reward_index = info.reward_id
			local rewards = config.rewards[reward_index]
			local comments = config.comments
			local item_email_list = {}
			--
			local top_i_reward = rewards.top[k]
			if top_i_reward and rewards.number >= k then
				for k, v in pairs(top_i_reward or {}) do
					local item = {}
					item.name = v[3]
					item.id = v[1]
					item.count  = v[2]
					table.insert(item_email_list, item)
				end
			end
			--self.info_list[v[1]][5] = reward
			--发邮件奖励包
			if #item_email_list > 0 then
				local pkt = {}
				pkt.sender = -1
				pkt.recevier = v[1]
				pkt.title = comments[1]
				pkt.content = comments[3]
				pkt.box_title = comments[2]
				pkt.item_list = item_email_list
				pkt.money_list = {}
				g_svsock_mgr:send_server_ex(COMMON_ID, 0, CMD_M2P_SEND_EMAIL_S, pkt)
				--print("+++ email:", CMD_M2P_SEND_EMAIL_S)
			end
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
			self:send_human(obj_id, CMD_MAP_WILD_BOSS_INFO_S, result)
		else
			self:send_human(obj_id, CMD_MAP_WILD_BOSS_INFO_S, result)
		end
	end
	return damage_size - 1
end