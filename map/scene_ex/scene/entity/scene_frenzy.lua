local frenzy_config = require("scene_ex.config.frenzy_config_loader")

--local min_reward = 20
--local max_reward = 300

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

Scene_frenzy = oo.class(Scene_instance, "Scene_frenzy")

function Scene_frenzy:__init(map_id, instance_id, map_obj, end_time, map_config, args_list, player_record)
	Scene_instance.__init(self, map_id, instance_id, map_obj)
	self.side_list = {}
	self.side_human_list = {{}, {}}
	self.side_human_count = {0, 0}
	self.side_fighting = {0, 0}
	self.side_buff = {}
	self.score = {0, 0}
	self.reward = {}
	self.kill_record = {}
	self.player_record = player_record

	self.status = SCENE_STATUS.OPEN
	self.freeze_time = end_time

	self.close_time = end_time + frenzy_config.config[self.id].limit.wait

	self.exp_reward = Exp_reward(map_config.exp_config)
	
	self.monster_list = {}
	self.npc_list = {}
	self.wait_relive = {}
	self.args_list = args_list
	
	self.human_count = 0
	
	self.lost_side = nil
	
	self.heart = {}
	
	
	self.req_notify = false
	self.balance_count = 0
	self.heart_hp = {{0, 0}, {0, 0}}
	self.notify_count = 0
	
	local config = g_scene_config_mgr:get_config(self.id)
	self.scene_name = string.format("%s%s", tostring(config and config.name), tostring(map_config.name_id))
	
	self.side_channal = {
		g_chat_channal_mgr:new_channal()
		, g_chat_channal_mgr:new_channal()
	}
	
	self.reward_list = nil
end

function Scene_frenzy:get_name()
	return self.scene_name
end

function Scene_frenzy:get_mode()
	if SCENE_STATUS.OPEN == self.status then
		local config = g_scene_config_mgr:get_config(self.id)
		return config and config.mode
	end
	return SCENE_MODE.PEACE
end

function Scene_frenzy:can_use(item_id)
	if contraband_list[item_id] then
		return false
	end
	return true
end

--副本出口
function Scene_frenzy:get_home_carry(obj)
	local config = frenzy_config.config[self.id]
	local home_carry = config and config.home
	if not home_carry or not home_carry.id or not home_carry.pos or not home_carry.pos[1] or not home_carry.pos[2] then
		return nil, nil
	end
	return home_carry.id, home_carry.pos
end

function Scene_frenzy:build_update_node(now, start, interval, count, method, exec, timeout)
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

function Scene_frenzy:init_side()
	local side_config = frenzy_config.config[self.id].side
	for side, config in ipairs(side_config) do
		local heart = config.heart
		local obj = g_obj_mgr:create_monster(heart[1], heart[2], self.key, nil)
		self.heart[obj:get_id()] = side
		obj:set_side(side)
		self:enter_scene(obj)
		
		for _, info in ipairs(config.guard) do
			local obj = g_obj_mgr:create_monster(info[1], info[2], self.key, nil)
			obj:set_side(side)
			self:enter_scene(obj)
			self.heart_hp[side] = {obj:get_hp(), obj:get_max_hp()}
		end
	end
	
end

function Scene_frenzy:instance()
	self:init_side()

	self.timer_queue = Timer_queue()
	self.obj_mgr:instance(self.map_obj:get_w(), self.map_obj:get_h())
	self.exp_reward:start()
	
	self:balance_side()

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

	local update_list = {}
	for _, info in pairs(self.args_list) do
		local node = self:build_update_node(
			now
			, info.start_time													--刷新开始时间
			, info.interval														--刷新间隔
			, info.count														--刷新次数
			, self.update_event
			, exec
			, timeout)

		node.args = info.args
		table.insert(update_list, node)
	end
	
	self.timer_queue:reset(update_list)
end

function Scene_frenzy:alloc_side(obj)
	local obj_id = obj:get_id()
	local fighting = obj:get_fighting()
	local side = 2
	local human_limit = frenzy_config.config[self.id].limit.human

	if self.side_fighting[1] < self.side_fighting[2] and self.side_human_count[1] < human_limit then
		side = 1
	elseif self.side_fighting[1] == self.side_fighting[2] then
		if self.side_human_count[1] == self.side_human_count[2] then
			side = self.side_list[obj_id] or math.random(1, 2)
		else
			side = (self.side_human_count[1] < self.side_human_count[2]) and 1 or 2
		end
	elseif self.side_human_count[2] >= human_limit then
		side = 1
	end

	obj:set_side(side)
	self.side_list[obj_id] = side
	self.side_human_count[side] = self.side_human_count[side] + 1
	self.side_fighting[side] = self.side_fighting[side] + fighting
	self.side_human_list[side][obj_id] = fighting

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

function Scene_frenzy:build_npc(info, map_id, pos, dead_time)
	local obj = g_obj_mgr:create_npc(info.occ, "", pos, self.key, nil)
	local obj_id = obj:get_id()
	self:enter_scene(obj)
	self.npc_list[obj_id] = dead_time
	return obj
end

function Scene_frenzy:build_monster(info, map_id, pos, dead_time)
	local obj = g_obj_mgr:create_monster(info.occ, pos, self.key, nil)
	local obj_id = obj:get_id()
	self:enter_scene(obj)
	self.monster_list[obj_id] = dead_time
	return obj
end

function Scene_frenzy:build_box(info, map_id, pos)
	local box_obj = g_obj_mgr:create_box(nil, nil, pos, self.key)
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

function Scene_frenzy:clean_object(now_time)
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

function Scene_frenzy:init_side_state(obj)
	local side = obj:get_side()
	local buff_level = self.side_buff[side]
	
	if buff_level then
		f_war_add_buff(obj, buff_level, self:get_last_time(obj))
	end
	
	local obj_id = obj:get_id()
	self:send_human(
		obj_id
		, CMD_MAP_FRENZY_SCOE_NOTIFY
		, {
			self.score[1]
			, self.score[2]
			, self.kill_record[obj_id] or 0
			, self.player_record[obj_id][1]
			, side
			, self.heart_hp[1]
			, self.heart_hp[2]
			, self:get_name()})
end

function Scene_frenzy:on_obj_enter(obj)
	if OBJ_TYPE_HUMAN == obj:get_type() then
		local obj_id = obj:get_id()
		self.wait_relive[obj_id] = nil
		self.exp_reward:del_addition(obj_id)
		
		local side = self.side_list[obj_id]
		if not side then
			self:alloc_side(obj)
			side = self.side_list[obj_id]
		end
		obj:set_side(side)
		self:init_side_state(obj)
		--
		if self.check_obj_team == nil then
			self.check_obj_team = {}
			self.check_obj_team_time = ev.time + 1
		end
		self.check_obj_team[obj_id] = 1
	end
end

function Scene_frenzy:on_obj_leave(obj)
	local obj_id = obj:get_id()
	if OBJ_TYPE_HUMAN == obj:get_type() then
		obj:set_side(0)
		f_del_impact(obj, 1503)
		if not obj:is_alive() then
			self.wait_relive[obj_id] = nil
			obj:do_relive(1, true)
		end
		self.player_record[obj_id][2] = ev.time + frenzy_config.config[self.id].limit.cd
		local side = self.side_list[obj_id]
		
		local channal_id = self.side_channal[side]
		g_chat_channal_mgr:del_member(obj_id, channal_id)
		
		local fighting = self.side_human_list[side][obj_id] or 0
		self.side_human_list[side][obj_id] = nil
		self.side_fighting[side] = math.max(self.side_fighting[side] - fighting, 0)
		self.side_human_count[side] = math.max(self.side_human_count[side] - 1, 0)
		obj:set_kill_status(0)
	else
		local side = self.heart[obj_id]
		if side then
			self.lost_side = side
		end
	end
end

function Scene_frenzy:update_notify()
	local is_change = false
	for obj_id, side in pairs(self.heart) do
		local obj = g_obj_mgr:get_obj(obj_id)
		if obj then
			local hp = self.heart_hp[side]
			local cur_hp = obj:get_hp()
			local max_hp = obj:get_max_hp()
			if hp[1] ~= cur_hp or hp[2] ~= max_hp then
				is_change = true
				hp[1] = cur_hp
				hp[2] = max_hp
			end
		end
	end

	if self.req_notify or is_change then
		if self.req_notify then
			self:balance_side()
		end
	
		self.notify_count = self.notify_count + 1
		self.req_notify = false
		for obj_id, _ in pairs(self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN):get_obj_list()) do
			self:send_human(
				obj_id
				, CMD_MAP_FRENZY_SCOE_NOTIFY
				, {
					self.score[1]
					, self.score[2]
					, self.kill_record[obj_id] or 0
					, self.player_record[obj_id][1]
					, self.side_list[obj_id]
					, self.heart_hp[1]
					, self.heart_hp[2]
					, self:get_name()})
		end
	end
end


function Scene_frenzy:on_timer(tm)
	local now_time = ev.time
	
	if SCENE_STATUS.OPEN == self.status then
		if self.lost_side or self.freeze_time < now_time then
			self.status = SCENE_STATUS.FREEZE
			
			self.close_time = ev.time + frenzy_config.config[self.id].limit.wait
			
			self:do_reward()
			self.timer_queue:reset({})	
		else
			self:clean_object(now_time)
			self:update_notify()			
			self.exp_reward:try_reward(now_time, self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN):get_obj_list())
		end
	elseif SCENE_STATUS.FREEZE == self.status then
		if self.close_time < now_time then
			self:close()
			self.status = SCENE_STATUS.CLOSE
		end
	end

	self.timer_queue:exec(now_time)
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
end

function Scene_frenzy:get_limit()
	return frenzy_config.config[self.id].limit.count
end

function Scene_frenzy:carry_scene(obj, pos)
	local e_code = self:alloc_side(obj)
	if SCENE_ERROR.E_SUCCESS ~= e_code then
		return e_code
	end
	
	return self:push_scene(obj, self:get_side_pos(obj))
end

function Scene_frenzy:get_last_time(obj)
	return math.max(self.freeze_time - ev.time, 0)
end

function Scene_frenzy:update_event(info, args)
	self:update(info, args)
end

function Scene_frenzy:update(info, args)
	local area = args.area
	if not area then
		return
	end
	
	local map_obj = self:get_map_obj()
	
	local count = math.floor(self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN):get_obj_count() * args.per)
	local pos = map_obj:find_space(area, 20)
	if pos then
		if 1 == args.type then
			for j = 1, count do
				self:build_box(args, map_obj.id, pos)
			end
		elseif 2 == args.type then
			for j = 1, count do
				self:build_monster(args, map_obj.id, pos, info.cur_count * info.interval + info.start_time)
			end
		elseif 3 == args.type then
			for j = 1, count do
				self:build_npc(args, map_obj.id, pos, info.cur_count * info.interval + info.start_time)
			end
		end
		
		if args.desc and count > 0 then
			f_cmd_linebd(f_create_sysbd_format(args.desc, 16))
		end
	else
		f_scene_info_log("Frenzy not pos %s %s", tostring(args.type), tostring(area))
	end
end

function Scene_frenzy:die_event(args)
	local killer_id = args.killer_id
	local obj_id = args.char_id
	local obj = self:get_obj(obj_id)
	if obj then
		self.wait_relive[obj_id] = ev.time + 5			--加入等待复活列表
		local kill_record = self.exp_reward:get_addition(obj_id) or 0
		self.exp_reward:del_addition(obj_id)
		obj:set_kill_status(0)
		
		args.mode = 1
		args.is_notify = false
		args.is_evil = false
		args.relive_time = math.max(self.wait_relive[obj_id] - ev.time, 0)
		
		local killer = killer_id and self:get_obj(killer_id)
		if killer and OBJ_TYPE_HUMAN == killer:get_type() then					--被玩家杀死
			self.exp_reward:add_addition(killer_id, 1)
			killer:add_frenzy_param(1, 0, 0)
			local kill_number = self.exp_reward:get_addition(killer_id)
			
			local win = 0
			local honor = 0
			local honor_kill = frenzy_config.config[self.id].limit.enemy.kill
			if kill_record >= honor_kill then
				win = frenzy_config.config[self.id].limit.enemy.win
				honor = frenzy_config.config[self.id].limit.enemy.honor
			else
				win = frenzy_config.config[self.id].limit.score.win
				honor = frenzy_config.config[self.id].limit.score.honor
			end

			if kill_number >= honor_kill then
				killer:set_kill_status(1)
			end
			
			local side = killer:get_side()
			self.score[side] = (self.score[side] or 0) + win
			self.kill_record[killer_id] = (self.kill_record[killer_id] or 0) + 1

			local max_reward = frenzy_config.config[self.id].limit.reward.max
			local total_reward = self.player_record[killer_id][1]
			if total_reward < max_reward then
				local diff = max_reward - total_reward
				local reward = math.min(honor, diff)
				self.player_record[killer_id][1] = total_reward + reward
				self.reward[killer_id] = (self.reward[killer_id] or 0) + reward
				
				local pack_con = killer:get_pack_con()
				pack_con:add_money(MoneyType.HONOR, reward, {['type'] = MONEY_SOURCE.FRENZY})
			end
			
			local terminator = frenzy_config.config[self.id].terminator[math.floor(kill_record / 10) * 10]
			if terminator and terminator.text then
				local msg = {}
				f_construct_content(msg, string.format(terminator.text, killer:get_name(), obj:get_name()), 16)
				f_cmd_sysbd(msg)
			end

			local honor = frenzy_config.config[self.id].honor[kill_number]
			if honor and honor.text then
				local msg = {}
				f_construct_content(msg, string.format(honor.text, killer:get_name()), 16)
				f_cmd_sysbd(msg)
			end
			
			self.req_notify = true
			
			local args = {}
			args.count = 1
			g_event_mgr:notify_event(EVENT_SET.EVENT_BATTLE_KILL, killer_id, args)				
		end
	end
end

function Scene_frenzy:update_buff(side, diff, buff_config)
	local lv = nil
	for k, v in ipairs(buff_config) do
		if not v or v.diff > diff then
			break
		end
		lv = v.level
	end

	if self.side_buff[side] ~= lv then
		self.side_buff[side] = lv
		if lv then
			local timeout = self:get_last_time(nil)
			for obj_id, _ in pairs(self.side_human_list[side]) do
				local obj = self:get_obj(obj_id)
				if obj then
					f_war_add_buff(obj, lv, timeout)
				end
			end
		else
			for obj_id, _ in pairs(self.side_human_list[side]) do
				local obj = self:get_obj(obj_id)
				if obj then
					f_del_impact(obj, 1503)
				end
			end
		end
	end
end

function Scene_frenzy:balance_side()
	local cheats_config = frenzy_config.config[self.id].cheats
	if not cheats_config or not cheats_config.buff then
		return
	end
	
	local diff = self.score[1] - self.score[2]
	
	if diff > 0 then
		self:update_buff(1, 0, cheats_config.buff)
		self:update_buff(2, diff, cheats_config.buff)
	else
		self:update_buff(1, math.abs(diff), cheats_config.buff)
		self:update_buff(2, 0, cheats_config.buff)
	end
	
	self.balance_count = (self.balance_count or 0) + 1
end

function Scene_frenzy:get_side_pos(obj)
	local config = frenzy_config.config[self.id]
	local side = obj:get_side()
	local list = config.entry[side]
	local i = math.random(1, #list)
	return list[i]
end

function Scene_frenzy:relive_human(obj)
	if obj:is_alive() then
		return
	end
	
	local pos = self:get_side_pos(obj)
	obj:do_relive(1, true)	--复活
	obj:send_relive(3)
	
	self:transport(obj, pos)
	
	f_prop_god(obj, 10)
	self:init_side_state(obj)
end

function Scene_frenzy:do_relive(now_time)
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

function Scene_frenzy:close()
	if self.instance_id then		
		Scene_instance.close(self)
	
		local obj_mgr = g_obj_mgr
		for obj_id, _ in pairs(self.npc_list) do
			local obj = obj_mgr:get_obj(obj_id)
			if obj then
				obj:leave()
			end
		end
		
		self.monster_list = {}
		self.npc_list = {}
		self.wait_relive = {}
		
		for _, id in ipairs(self.side_channal) do
			g_chat_channal_mgr:remove_channal(id)
		end
		
		self.side_channal = {}
	end
end

function Scene_frenzy:adjudge()
	local win_reward = {0.5, 1, 0, 0, self.lost_side and frenzy_config.config[self.id].limit.reward.heart or 0}
	local lost_reward = {0.1, 0, 1, 0, 0}
	local draw_reward = {0.1, 0, 0, 1, 0}

	local win_side = 0
	local win_record = {draw_reward, draw_reward}
	if not self.lost_side then
		if self.score[1] ~= self.score[2] then
			win_side = self.score[1] > self.score[2] and 1 or 2
		end
	elseif 2 == self.lost_side then
		win_side = 1
	elseif 1 == self.lost_side then
		win_side = 2
	end
	
	if 1 == win_side then
		win_record = {win_reward, lost_reward}
	elseif 2 == win_side then
		win_record = {lost_reward, win_reward}
	end
	
	return win_record, win_side
end

function Scene_frenzy:do_reward()
	local win_record, win_side = self:adjudge()
	
	local reward_list = {}
	local has_list = {0, 0}
	for obj_id, side in pairs(self.side_list) do
		local obj = self:get_obj(obj_id)
		if obj then
			local side_record = win_record[side]
			has_list[side] = has_list[side] + 1
			
			local max_reward = frenzy_config.config[self.id].limit.reward.max
			local total_reward = self.player_record[obj_id][1]
			local final_reward = self.reward[obj_id] or 0
			if total_reward < max_reward then
				local diff = max_reward - total_reward
				local cur_reward = final_reward
				local reward = math.min(
					side_record[5] + math.floor((cur_reward + side_record[5]) * side_record[1])
					, diff)
				
				total_reward = total_reward + reward
				
				local min_reward = frenzy_config.config[self.id].limit.reward.min
				if total_reward < min_reward then
					reward = reward + (min_reward - total_reward)
					total_reward = min_reward
				end
				
				final_reward = math.max(cur_reward + reward, min_reward)
				
				self.player_record[obj_id][1] = total_reward
				self.reward[obj_id] = final_reward
				
				local pack_con = obj:get_pack_con()
				pack_con:add_money(MoneyType.HONOR, reward, {['type'] = MONEY_SOURCE.FRENZY})
			end			
			
			local record = {}
			record.obj_id = obj_id
			record.list = {obj:get_name(), self.kill_record[obj_id] or 0, side, final_reward}
			table.insert(reward_list, record)
			
			if 1 == side_record[2] then
				g_event_mgr:notify_event(EVENT_SET.EVENT_BATTLE_WIN, obj_id, {['count'] = 1})
			end
			
			obj:add_frenzy_param(0, side_record[2], side_record[3], side_record[4])
		end
	end
	
	table.sort(
		reward_list
		, function (left, right)
			if left.list[2] == right.list[2] then
				return left.list[4] > left.list[4]
			end
			return left.list[2] > right.list[2]
		end)
	
	local has_elite = false
	local name_l = {}
	table.insert(name_l, self:get_name())
	local elite_list = {}
	for i = 1, 20 do
		local elite = reward_list[i]
		if not elite then
			break
		end
		table.insert(elite_list, elite.list)
		if i <= 5 then
			table.insert(name_l, {elite.list[1], elite.list[2]})
			has_elite = true
		end
	end
	
	if has_elite then
		local str_json = f_get_sysbd_format(10013, name_l)
		f_cmd_sysbd(str_json)
	end
	
	local score_record = {self.score[1], self.score[2], win_side}
	local timeout = math.max(self.close_time - ev.time, 0)
	for k, v in ipairs(reward_list) do
		local obj_id = v.obj_id
		local result = {}
		table.insert(result, timeout)
		table.insert(result, score_record)
		local r = table.copy(v.list)
		table.insert(r, k)
		table.insert(result, r)
		table.insert(result, elite_list)
		self:send_human(obj_id, CMD_MAP_FRENZY_SETTLEMENT_NOTIFY, result)
	end

	self.reward_list = reward_list
	
	for k, v in ipairs(self.reward_list) do
		local obj_id = v.obj_id
		local faction = g_faction_mgr:get_faction_by_cid(obj_id)
		local name = faction and faction:get_faction_name() or ""
		table.insert(v.list, name)
	end
	
	f_scene_info_log("Frenzy %s/%s, %s/%s %s"
			, tostring(has_list[1])
			, tostring(self.side_human_count[1])
			, tostring(has_list[2])
			, tostring(self.side_human_count[2])
			, tostring(self.balance_count))
end

function Scene_frenzy:get_reward_list()
	return self.reward_list
end