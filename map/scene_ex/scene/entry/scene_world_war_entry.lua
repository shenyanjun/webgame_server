local config = require("config.world_war.config_loader")
local map_cmd = require("map_cmd_func")
Team_cache = oo.class(nil, "Team_cache")

function Team_cache:__init()
	self.obj_list = {}
	self.team_list = {}
	self.team_count = 0
end

function Team_cache:load()
	self.obj_list = {}
	self.team_list = {}
	self.team_count = 0
	
	local fields = "{_id:0}"
	local rows, e_code = f_get_db():select("world_war_team", fields, nil, nil, 0, 0, nil)
	if 0 == e_code and rows then
		for _, row in ipairs(rows) do
			local team_id = row.team_id
			self.team_list[team_id] = row
			for _, obj_id in ipairs(row.members) do
				self.obj_list[obj_id] = team_id
			end
			self.team_count = self.team_count + 1
		end
	end
	return 0 == e_code
end

function Team_cache:get_cache(team_id)
	return self.team_list[team_id]
end

function Team_cache:get_player_team(obj_id)
	return self.obj_list[obj_id]
end

function Team_cache:get_members(team_id)
	local info = self.team_list[team_id]
	return info and info.members
end

function Team_cache:update_score(team_id, score)
	local info = self.team_list[team_id]
	if info then
		info.score = score
	end
end

--------------------------------------------------------------------------------------------------

MATCH_STATUS = {
	READY = 1
	, RUNNING = 2
	, CLOSE = 3
	, FREEZE = 4
	, END = 5
}

TEAM_STATUS = {
	IDLE = 1
	, BUSY = 2
}

Match_state = oo.class(nil, "Match_state")

function Match_state:__init(open_time, entry)
	self.entry = entry
	self.instance_list = {}
	
	local config = self:get_config()
	self.map_obj = g_scene_config_mgr:load_map(config.game.entry.id, config.game.entry.path)
	self.open_time = open_time + config.ready * 60
	self.close_time = self.open_time + config.interval * 60
	self.end_time = self.close_time + config.clean * 60
	
	self.status = MATCH_STATUS.CLOSE
	local now = ev.time
	if now < self.open_time then
		self.status = MATCH_STATUS.READY
	elseif now < self.close_time then
		self.status = MATCH_STATUS.RUNNING
	end
	
	self.owner_list = {}
	
	self.team_cache = Team_cache()
	self.team_cache:load()
	
	self.team_channal = {}
	
	self.match_timeout = ev.time
	
	self.instance_team = {}
	self.team_info_list = {}
	self.idle_team = {}
	self.busy_team = {}
end

function Match_state:get_config()
	assert(false)
	return nil
end

function Match_state:get_id()
	return self.entry:get_id()
end

function Match_state:get_player_team(obj_id)
	assert(false)
end

function Match_state:on_timer(tm)	
	local now = ev.time
	if MATCH_STATUS.READY == self.status then
		if now >= self.open_time then
			self.status = MATCH_STATUS.RUNNING
		end
	elseif MATCH_STATUS.RUNNING == self.status then
		if now >= self.close_time then
			self.status = MATCH_STATUS.CLOSE
			f_cmd_linebd(f_create_sysbd_format(f_get_string(2405), 16))
		elseif self.match_timeout < now then
			self.match_timeout = now + 3
			self:to_match()
		end
	elseif MATCH_STATUS.CLOSE == self.status then
		if now >= self.end_time then
			self.status = MATCH_STATUS.FREEZE
			self.end_time = self.end_time + 60
			local list = g_obj_mgr:get_list(OBJ_TYPE_HUMAN)
			for obj_id, _ in pairs(list or {}) do
				g_cltsock_mgr:send_client(obj_id, CMD_MAP_WORLD_WAR_END_S, "{}", true)
			end
			
			for _, channal_id in pairs(self.team_channal) do
				g_chat_channal_mgr:remove_channal(channal_id)
			end
			self.team_channal = {}
		end
	elseif MATCH_STATUS.FREEZE == self.status then
		if now >= self.end_time then
			self.status = MATCH_STATUS.END
			map_cmd.f_kill_all_char()
		end
	end
	
	for _, instance in pairs(self.instance_list) do
		instance:on_timer(tm)
	end
end

function Match_state:on_slow_timer(tm)
	for _, instance in pairs(self.instance_list) do
		instance:on_slow_timer(tm)
	end
end

function Match_state:on_serialize_timer(tm)
	for _, instance in pairs(self.instance_list) do
		instance:on_serialize_timer(tm)
	end
end

function Match_state:to_match()
end

function Match_state:enter_match(obj)
	local obj_id = obj:get_id()
	local team_id = self:get_player_team(obj_id)
	local info = self.team_info_list[team_id]
	if not info then
		info = {["member_count"] = 1}
		self.team_info_list[team_id] = info
		if not self.busy_team[tema_id] and not self.idle_team[team_id] then
			self.idle_team[team_id] = ev.time + 5 + math.random(1, 10)
		end
	else
		info.member_count = info.member_count + 1
	end

	if not self.owner_list[obj_id] then
		self.owner_list[obj_id] = true
		
		local item_list = {}
		local config = self:get_config()
		for _, v in pairs(config.game.supply or {}) do
			local item = {}
			item.type = 1
			item.number = v[2]
			item.item_id = v[1]
			table.insert(item_list, item)
		end
		
		local pack_con = obj:get_pack_con()
		local e_code = pack_con:add_item_l(item_list, {['type'] = ITEM_SOURCE.TASK})
	end
	
	local channal_id = self.team_channal[team_id]
	if not channal_id then
		channal_id = g_chat_channal_mgr:new_channal()
		self.team_channal[team_id] = channal_id
	end
	
	g_chat_channal_mgr:add_member(obj_id, channal_id)
	
	self:enter_match_event(obj, team_id)
end

function Match_state:enter_match_event(obj, team_id)
end

function Match_state:leave_match(obj)
	local obj_id = obj:get_id()
	local team_id = self.team_cache:get_player_team(obj_id)
	local info = self.team_info_list[team_id]
	
	if info.member_count > 1 then
		info.member_count = info.member_count - 1
	else
		self.team_info_list[team_id] = nil
		self.idle_team[team_id] = nil
	end
	
	self:leave_match_event(obj, team_id)
end

function Match_state:leave_match_event(obj, team_id)
end

function Match_state:get_instance(instance_id)
	return self.instance_list[instance_id]
end

function Match_state:unregister_instance(instance_id)
	local instance = self.instance_list[instance_id]
	if instance then
		instance:close()
		self.instance_list[instance_id] = nil
	end
end

function Match_state:push_team(team_id, instance)
	local members = self.team_cache:get_members(team_id)
	local team = nil
	local obj_mgr = g_obj_mgr
	for _, obj_id in ipairs(members) do
		local obj = obj_mgr:get_obj(obj_id)
		if obj then
			if not team then
				team = g_team_mgr:create_team(obj_id, team_id)
			else
				team:add_obj(obj_id)
			end
			instance:carry_scene(obj)
		end
	end
	
	if team then
		team:syn()
	end
end

function Match_state:update_sort(pkt)
end

function Match_state:update_score(team_id, score)
end

-------------------------------------------------------------------------------------------

Qualify_state = oo.class(Match_state, "Qualify_state")

function Qualify_state:__init(open_time, entry)
	Match_state.__init(self, open_time, entry)
	
	self.team_sort = {}
	self.team_sort_cache = {}
	
	self.human_total = 0
	self.human_list = {}
end

function Qualify_state:update_sort(pkt)
	local sort_list = pkt.sort
	self.team_sort = sort_list
	self.team_sort_cache = {}
	for k, info in ipairs(sort_list) do
		self.team_sort_cache[info.team_id] = k
	end
	if pkt.human then
		self.human_total = pkt.human
	end
end

function Qualify_state:update_score(team_id, score)
	self.team_cache:update_score(team_id, score)
end

function Qualify_state:get_config()
	return config.config.qualify
end

function Qualify_state:get_player_team(obj_id)
	return self.team_cache:get_player_team(obj_id)
end

function Qualify_state:on_slow_timer(tm)
	for _, instance in pairs(self.instance_list) do
		instance:on_slow_timer(tm)
	end
	
	g_svsock_mgr:send_server_ex(WORLD_ID, 0, CMD_W2C_QUALIFY_SORT_REQ, [[{"type":1}]], true)
end

function Qualify_state:to_match()
	local last_team = nil
	local now = ev.time
	local change_team = {}
	for team_id, timeout in pairs(self.idle_team) do
		if timeout < now then
			if last_team then
				self:create_qualify(last_team, team_id)
				self.busy_team[last_team] = true
				table.insert(change_team, last_team)
				self.busy_team[team_id] = true
				table.insert(change_team, team_id)
				last_team = nil
			else
				last_team = team_id
			end
		end
	end
	
	for _, team_id in ipairs(change_team) do
		self.idle_team[team_id] = nil
	end
	
	for obj_id, team_id in pairs(self.human_list) do
		self:notify_state(obj_id, team_id)
	end
end

function Qualify_state:notify_state(obj_id, team_id)
	local ranking = self.team_sort_cache[team_id]
	if ranking then
		local info = self.team_sort[ranking]
		local result = {}
		result.type = 1
		result.ranking = ranking
		result.score = info.info[4][4]
		result.human = self.human_total
		g_cltsock_mgr:send_client(obj_id, CMD_MAP_WORLD_WAR_STATE_S, result)
	else
		local info = self.team_sort[#self.team_sort]
		if info then
			local result = {}
			result.type = 2
			result.score = self.team_cache:get_cache(team_id).score[4]
			result.rival = info.info[4][4]
			result.human = self.human_total
			g_cltsock_mgr:send_client(obj_id, CMD_MAP_WORLD_WAR_STATE_S, result)
		end
	end
end

function Qualify_state:enter_match_event(obj, team_id)
	local obj_id = obj:get_id()	
	
	local pkt = {}
	pkt.type = 1
	if MATCH_STATUS.READY == self.status then
		pkt.time = math.max(self.open_time - ev.time, 0)
	end
	g_cltsock_mgr:send_client(obj_id, CMD_MAP_WORLD_WAR_READY_S, pkt)

	if MATCH_STATUS.RUNNING == self.status then
		self:notify_state(obj_id, team_id)
	end
	
	self.human_list[obj_id] = team_id
end

function Qualify_state:leave_match_event(obj, team_id)
	local obj_id = obj:get_id()
	self.human_list[obj_id] = nil
end

function Qualify_state:unregister_instance(instance_id)
	local instance = self.instance_list[instance_id]
	if instance then
		instance:close()
		self.instance_list[instance_id] = nil
		local info = self.instance_team[instance_id]
		if info then
			local team_id = info[1]
			self.busy_team[team_id] = nil
			if self.team_info_list[team_id] then
				self.idle_team[team_id] = ev.time + 5 + math.random(1, 10)
			end
			
			team_id = info[2]
			self.busy_team[team_id] = nil
			if self.team_info_list[team_id] then
				self.idle_team[team_id] = ev.time + 5 + math.random(1, 10)
			end
		end
	end
end

function Qualify_state:create_qualify(first_id, second_id)
	local instance_id = crypto.uuid()
	
	local instance = Scene_qualify(
		self:get_config().game.entry.id
		, instance_id
		, self.map_obj:clone(self.map_obj.id)
		, self
		, first_id
		, second_id)
	self.instance_list[instance_id] = instance
	g_scene_mgr_ex:register_instance(instance_id, self.entry)
	instance:instance()
	
	self:push_team(first_id, instance)
	self:push_team(second_id, instance)

	self.instance_team[instance_id] = {first_id, second_id}
end

-------------------------------------------------------------------------------------------

Knockout_state = oo.class(Match_state, "Knockout_state")

function Knockout_state:__init(open_time, entry)
	Match_state.__init(self, open_time, entry)
	
	self.has_sort = false

	self.heap = {}
	self.height = 0
	self.list = {}
	self.size = 0
	self.count = 0
	self.battle_list_cache = {}
	
	self.match_list = {}
	self.wait_match = {}
end

function Knockout_state:get_config()
	return config.config.knockout
end

function Knockout_state:get_player_team(obj_id)
	return self.team_cache:get_player_team(obj_id)
end

function Knockout_state:update_sort(pkt)
	if self.has_sort then
		return 
	end
	
	local match_list = pkt.sort
	local size = #match_list
	
	local height = 1
	local limit = 2
	while limit < size do
		limit = limit * 2
		height = height + 1
	end
	
	local heap = {}
	for i = 1, height do
		heap[i] = {}
	end
	
	for i = 1, size do
		table.insert(heap[height], i)
	end

	self.heap = heap
	self.height = height
	self.list = match_list
	self.size = size
	
	local level = self.height
	local count = 0
	local i = 1
	while true do
		local info = match_list[i]
		if not info then
			break
		end	

		count = count + 1
		local match = {i, i + 1, level, count, ev.time + 30}
		table.insert(self.match_list, match)
		local team_id = info[1]
		self.battle_list_cache[team_id] = level + 1
		
		info = match_list[i + 1]
		if info then
			local team_id = info[1]
			self.battle_list_cache[team_id] = level + 1
		end
		
		i = i + 2
	end
	self.count = count
	
	self.has_sort = true
end

function Knockout_state:on_slow_timer(tm)
	for _, instance in pairs(self.instance_list) do
		instance:on_slow_timer(tm)
	end
	
	if not self.has_sort then
		g_svsock_mgr:send_server_ex(WORLD_ID, 0, CMD_W2C_QUALIFY_SORT_REQ, [[{"type":2}]], true)
	end
end

function Knockout_state:to_match()
	if not self.has_sort then
		return
	end
	
	local last_team = nil
	local now = ev.time
	local change_team = {}
	for k, match in pairs(self.match_list) do
		if now > match[5] then
			self:create_knockout(match)
			table.insert(change_team, k)
		end
	end
	
	for _, k in ipairs(change_team) do
		self.match_list[k] = nil
	end
end

function Knockout_state:insert_match(k, level, count)
	local list = self.heap[level]
	if not list then
		list = {}
		self.heap[level] = list
	end
	
	local c = math.ceil(count / 2)
	local pos = (1 == (count % 2)) and 1 or 2
	if not list[c] then
		--左半枝
		if 1 == pos and self.count <= (count * math.pow(2, self.height - level - 1)) then
			local match = {nil, nil, level, c, ev.time + 10}
			match[pos] = k
			table.insert(self.match_list, match)
			print("1-1", Json.Encode(match))
			print("x-x", self.count, count, math.pow(2, self.height - level - 1), self.height, level)
		else
			list[c] = {}
			list[c][pos] = k
		end
	else
		list[c][pos] = k
		local match = {list[c][1], list[c][2], level, c, ev.time + 10}
		table.insert(self.match_list, match)
		list[c] = nil
		print("2-2", Json.Encode(match))
	end
	
	local info = self.list[k]
	self.battle_list_cache[info[1]] = level + 1
end

function Knockout_state:balance_match(winner, loser, level, count)
	print(winner, loser, level, count)
	if level > 1 then
		self:insert_match(winner, level - 1, count)
	elseif 1 == level then
		local info = self.list[winner]
		self.battle_list_cache[info[1]] = 0
		if loser then
			local info = self.list[loser]
			self.battle_list_cache[info[1]] = 1
		end
	else
		return
	end
	
	local result = {}
	result.winner = winner
	result.loser = loser
	result.level = level
	result.count = count
	g_svsock_mgr:send_server_ex(WORLD_ID, 0, CMD_C2W_KNOCKOUT_RESULT_C, result)
	
	local pkt = {}
	pkt.type = 1
	pkt.msg = {{}, {}, level}
	
	local winner_team = self.list[winner]
	
	for _, info in ipairs(winner_team[4]) do
		table.insert(pkt.msg[1], info[1])
	end
	
	if loser then
		local loser_team = self.list[loser]
	
		for _, info in ipairs(loser_team[4]) do
			table.insert(pkt.msg[2], info[1])
		end
	end
	
	local msg = Json.Encode(pkt)
	local list = g_obj_mgr:get_list(OBJ_TYPE_HUMAN)
	for obj_id, _ in pairs(list or {}) do
		g_cltsock_mgr:send_client(obj_id, CMD_MAP_WORLD_WAR_MSG_S, msg, true)
	end
	
	if 1 == level then
		local config = self:get_config()
		self.end_time = ev.time + config.clean * 60
		self.status = MATCH_STATUS.CLOSE
		f_cmd_linebd(f_create_sysbd_format(f_get_string(2405), 16))
	end
end

function Knockout_state:create_knockout(match)
	local first_id = self.list[match[1]] and self.list[match[1]][1]
	local second_id = self.list[match[2]] and self.list[match[2]][1]
	
	local level = match[3]
	local count = match[4]

	if not first_id or not second_id then
		local i = first_id and 1 or 2
		print("3--", match[1], match[2], i)
		self:balance_match(match[i], nil, level, count)
		return
	end
	
	local instance_id = crypto.uuid()
	
	local instance = Scene_knockout(
		self:get_config().game.entry.id
		, instance_id
		, self.map_obj:clone(self.map_obj.id)
		, self
		, first_id
		, second_id)
	self.instance_list[instance_id] = instance
	g_scene_mgr_ex:register_instance(instance_id, self.entry)
	instance:instance()
	
	self:push_team(first_id, instance)
	self:push_team(second_id, instance)

	self.instance_team[instance_id] = match
end

function Knockout_state:enter_match_event(obj, team_id)
	local obj_id = obj:get_id()
	local pkt = {}
	pkt.type = 2
	if MATCH_STATUS.READY == self.status then
		pkt.time = math.max(self.open_time - ev.time, 0)
	end
	g_cltsock_mgr:send_client(obj_id, CMD_MAP_WORLD_WAR_READY_S, pkt)
	
	if MATCH_STATUS.RUNNING == self.status then
		local result = {}
		result.type = 3
		result.ranking = self.battle_list_cache[team_id]
		--table.print(result)
		g_cltsock_mgr:send_client(obj_id, CMD_MAP_WORLD_WAR_STATE_S, result)
	end
end

function Knockout_state:unregister_instance(instance_id)
	local instance = self.instance_list[instance_id]
	if instance then
		local win_id = instance:get_win()
		instance:close()
		self.instance_list[instance_id] = nil
		local match = self.instance_team[instance_id]
		if match then
			local level = match[3]
			local count = match[4]
			
			print("1--", match[1], match[2], win_id)
			
			local winner = (win_id == 1) and match[1] or match[2]
			local loser = (win_id == 1) and match[2] or match[1]
			
			self:balance_match(winner, loser, level, count)
		end
	end
end

--------------------------------------------------------------------------------------------------------

Scene_world_war_entry = oo.class(Scene_entry, "Scene_world_war_entry")

function Scene_world_war_entry:__init(map_id)
	Scene_entry.__init(self, map_id)
	self.instance_list = {}
	self.team_instance = {}
	self.team_count = {}
	self.tomorrow = 0
	self.status = nil
	self.timer_heap = Timer_heap()
	self.team_channal = {}
end

-----------------------------------------------场景实例化---------------------------------------------

function Scene_world_war_entry:update_score(team_id, score)
	if self.status then
		self.status:update_score(team_id, score)
	end
end

function Scene_world_war_entry:update_sort(pkt)
	if self.status then
		self.status:update_sort(pkt)
	end
end

function Scene_world_war_entry:instance(args)
	self.map_obj = g_scene_config_mgr:load_map(self.id)
	self:on_new_day()
end

function Scene_world_war_entry:get_instance(scene_id)
	local instance_id = scene_id and scene_id[2]
	local  instance = instance_id and self.instance_list[instance_id]
	if not instance and self.status then
		instance = self.status:get_instance(instance_id)
	end
	return instance
end

function Scene_world_war_entry:unregister_instance(instance_id, args)
	local instance = self.instance_list[instance_id]
	if instance then
		instance:close()
		self.instance_list[instance_id] = nil
	elseif self.status then
		self.status:unregister_instance(instance_id)
	end
end

-----------------------------------------------场景入口----------------------------------------------

--获取副本实例ID
function Scene_world_war_entry:get_instance_id(obj)
	local obj_id = obj:get_id()
	local team_id = self.status:get_player_team(obj_id)

	local instance_id = self.team_instance[team_id]
	
	local limit = config.config.ground[self.id].limit

	if instance_id then
		local instance = self.instance_list[instance_id]
		if not instance then
			instance_id = nil
		end
	end
	
	if not instance_id then
		for id, instance in pairs(self.instance_list) do
			print(self.team_count[id])
			if self.team_count[id] < limit then
				instance_id = id
				self.team_count[id] = self.team_count[id] + 1
				break
			end
		end
		
	 	instance_id = instance_id or crypto.uuid()
	 	self.team_instance[team_id] = instance_id
	end
	
	return instance_id, SCENE_ERROR.E_SUCCESS
end

--创建副本实例
function Scene_world_war_entry:create_instance(instance_id, obj)
	return Scene_match(self.id, instance_id, self.status)
end

function Scene_world_war_entry:carry_scene(obj, pos, args)
	if not obj or not self.status then
		return SCENE_ERROR.E_NOT_ON_SCENE, nil
	end
	
	local instance_id, e_code = self:get_instance_id(obj)
	if SCENE_ERROR.E_SUCCESS ~= e_code then
		return e_code, nil
	end
	
	local instance = self.instance_list[instance_id]
	if not instance then
		instance = self:create_instance(instance_id, obj)
		self.instance_list[instance_id] = instance
		self.team_count[instance_id] = 1
		g_scene_mgr_ex:register_instance(instance_id, self)
		instance:instance(args)
	end
	
	return instance:carry_scene(obj, pos)
end

function Scene_world_war_entry:login_scene(obj, pos)
	return self:carry_scene(obj, pos)
end

function Scene_world_war_entry:push_scene(obj, pos)
	return self:carry_scene(obj, pos)
end

--------------------------------------------------------------------------------------------------

function Scene_world_war_entry:on_new_day()
	local today_time, today = f_get_today()
	self.tomorrow = today_time + 86400
	self:load_timer_event(today, today_time)
end

function Scene_world_war_entry:load_timer_event(date, time)
	local wday = date.wday
	local event_list = config.config.day_list[wday]
	
	if not event_list then
		return
	end
	
	for _, v in ipairs(event_list) do
		local interval = v.interval
		local args = {}
		args.time = time + v.offset
		args.interval = interval
		if interval then
			interval = interval + args.time
		end
		if 2 == v.type then
			self.timer_heap:push(time + v.offset, interval, self, "open_qualify", args)
		elseif 3 == v.type then
			self.timer_heap:push(time + v.offset, interval, self, "open_knockout", args)
		end
	end
end

function Scene_world_war_entry:open_qualify(args)
	self.team_instance = {}
	self.team_count = {}
	local temp_list = table.copy(self.instance_list)
	for _, instance in pairs(temp_list) do
		instance:close()
	end
	self.instance_list = {}
	self.status = Qualify_state(args.time, self)
end

function Scene_world_war_entry:open_knockout(args)
	self.team_instance = {}
	self.team_count = {}
	local temp_list = table.copy(self.instance_list)
	for _, instance in pairs(temp_list) do
		instance:close()
	end
	self.instance_list = {}
	self.status = Knockout_state(args.time, self)
end

function Scene_world_war_entry:on_timer(tm)
	local now = ev.time
	
	if self.tomorrow < now then
		self:on_new_day()
	end
	
	for _, instance in pairs(self.instance_list) do
		instance:on_timer(tm)
	end
	
	if self.status then
		self.status:on_timer(tm)
	end
	
	self.timer_heap:exec(now)
end

function Scene_world_war_entry:on_slow_timer(tm)
	for _, instance in pairs(self.instance_list) do
		instance:on_slow_timer(tm)
	end

	if self.status then
		self.status:on_slow_timer(tm)
	end
end

function Scene_world_war_entry:on_serialize_timer(tm)
	for _, instance in pairs(self.instance_list) do
		instance:on_serialize_timer(tm)
	end
	
	if self.status then
		self.status:on_serialize_timer(tm)
	end
end