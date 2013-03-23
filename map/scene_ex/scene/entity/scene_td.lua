local td_config = require("scene_ex.config.td_config_loader")
local copy_config = require("scene_ex.config.copy_bale_loader")

local close_timeout = 10
local _max_mon_area = 30    --怪区最大值

Scene_td = oo.class(Scene_instance, "Scene_td")

function Scene_td:__init(map_id, instance_id, map_obj)
	Scene_instance.__init(self, map_id, instance_id, map_obj)
	
	self.heart_id = nil
	self.sequence = 0
	self.counter = {}
	self.next_time = ev.time
	
	self.is_success = false
	self.end_time = nil
	
	self.area_monster = {}
	self.total_mana = 0
	
	self.guard_list = {}

	self.update_over = false
	self.update_obj = Scene_obj_container()
end

function Scene_td:instance(args)
	local config = td_config.config[self.id]
	if _DEBUG then
		self.total_mana = (config.test and config.test.mana) or 0
	end
	
	self.obj_mgr:instance(self.map_obj:get_w(), self.map_obj:get_h())
	
	local heart = config.heart
	local obj = g_obj_mgr:create_monster(heart.id, heart.pos, self.key)
	self.heart_id = obj:get_id()
	self:enter_scene(obj)
	
	local helper = config.helper
	local guard_list = helper and helper.guard
	local guard = guard_list and guard_list[heart.id]
	self.guard_list[heart.id] = {
		["id"] = self.heart_id
		, ["lv"] = 1
		, ["name"] = guard and guard.name
	}
	
	if args and args.target then
		self.sequence = math.max(args.target - 1, 0)
		self.total_mana = args.mana or 0
		for obj_id, obj in pairs(args.members or {}) do
			local con = obj:get_copy_con()
			con:add_count_copy(self.id)
			self.owner_list[obj_id] = true
			
			f_multi_web_sql(string.format("insert into copy_into set copy_id=%d, char_id=%d, time=%d, char_name='%s'"
						, self.id
						, obj_id
						, ev.time
						, obj:get_name()))
		end
		--self.not_human = false
	end
	
	self.area_list = {}
	local wild = td_config.config[self.id].wild
	if wild then
		for area, sequence in pairs(wild) do
			local item = sequence[1]
			if item then
				self.area_list[area] = {
					["timeout"] = item.interval + ev.time
					, ["sequence"] = 1
					, ["number"] = 0
				}
			end
		end
	end
end

function Scene_td:get_self_limit_config()
	return copy_config.config_list.value[self.id]
end

function Scene_td:get_last_time(obj)
	return nil
end

function Scene_td:get_owner()
	local team_obj = g_team_mgr:get_team_obj(self.instance_id)
	return team_obj and  team_obj:get_teamer_id()
end

function Scene_td:update_guard_notify(obj_id)
	local helper = td_config.config[self.id].helper
	local guard_list = helper and helper.guard
	
	if not guard_list then
		return
	end
	
	local guard_l = {}
	for id, info in pairs(guard_list) do
		local guard = {}
		guard.id = id
		guard.name = info.name
		
		local lv = self.guard_list[id] and self.guard_list[id].lv
		if lv then
			guard.item_id = info.level_list[lv + 1] and info.level_list[lv + 1].desc_id or info.level_list[lv].desc_id
			guard.type = info.level_list[lv + 1] and 2 or 3
		else
			guard.item_id = info.level_list[1].desc_id
			guard.type = 1
		end
		table.insert(guard_l, guard)
	end
	local pkt = {}
	pkt.guard_l = guard_l
	self:send_human(obj_id, CMD_MAP_TD_HELPER_GUARD_NOTIFY, pkt)
end

function Scene_td:update_buff_notify(obj_id)
	local helper = td_config.config[self.id].helper
	local buff_list = helper and helper.buff
	
	if not buff_list then
		return
	end
	
	local buff_l = {}
	for id, info in pairs(buff_list) do
		local buff = {}
		buff.id = id
		buff.name = info.name
		buff.item_id = info.desc_id
		table.insert(buff_l, buff)
	end
	local pkt = {}
	pkt.buff_l = buff_l
	self:send_human(obj_id, CMD_MAP_TD_HELPER_BUFF_NOTIFY, pkt)
end

function Scene_td:on_obj_enter(obj)
	if obj:get_type() == OBJ_TYPE_HUMAN then
		local obj_id = obj:get_id()
		g_scene_mgr_ex:register_event(EVENT_SET.EVENT_DEL_TEAM, obj_id, self, self.del_team_event)
		g_scene_mgr_ex:register_event(EVENT_SET.EVENT_TEAM_CAPTAIN, obj_id, self, self.caption_event)
		if self.not_human then
			self.not_human = false
			f_team_gather(obj, 2)
		end
		
		if obj_id == self:get_owner() then
			self:update_guard_notify(obj_id)
			self:update_buff_notify(obj_id)
		end
		
		local args = obj:get_scene_args()
		local id = tostring(self.id)
		local max_layer = args[id] or 0
		if max_layer < self.sequence then
			args[id] = self.sequence
		end
	end
end

function Scene_td:on_failed()
	self.end_time = ev.time + close_timeout
	local pkt = string.format('{"time":%d}', close_timeout)
	for char_id, _ in pairs(self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN):get_obj_list()) do
		self:send_human(char_id, CMD_MAP_WAIT_TIMEOUT_NOTIFY, pkt, true)
	end
	
	local sql = "insert into copy_failed set char_id=%d, "..
			string.format(
				"copy_id=%d, run_num=%d, time=%d"
				, self.id
				, self.sequence
				, ev.time)
	
	local member_list = {}

	local team_obj = g_team_mgr:get_team_obj(self.instance_id)
	if team_obj then
		local team_l = team_obj:get_team_l()
		for k, _ in pairs(team_l) do
			f_multi_web_sql(string.format(sql, k))
			table.insert(member_list, k)
		end
	end

	local obj = g_obj_mgr:get_obj(self.heart_id)
	if obj then
		f_scene_info_log("Scene_td:on_failed(%d, %d, %d, %s, %s)", obj:get_hp(), obj:get_max_hp(), obj:get_occ(), tostring(obj:is_alive()), table.concat(member_list, ","))
	else
		f_scene_info_log("Scene_td:on_failed(not obj, %s)", table.concat(member_list, ","))
	end
end

function Scene_td:on_obj_leave(obj)
	local obj_id = obj:get_id()
	if obj:get_type() == OBJ_TYPE_HUMAN then
		g_scene_mgr_ex:unregister_event(EVENT_SET.EVENT_DEL_TEAM, obj_id)
		g_scene_mgr_ex:unregister_event(EVENT_SET.EVENT_TEAM_CAPTAIN, obj_id)
	elseif self.heart_id == obj_id and self.instance_id then
		self:on_failed()
	else
		local area = self.area_monster[obj_id]
		if area then
			local info = self.area_list[area]
			if info and info.number > 0 then
				info.number = info.number - 1
				if 0 == info.number then
					local wild = td_config.config[self.id].wild
					if wild then
						local sequence = wild[area]
						if sequence then
							local item = sequence[info.sequence]
							if item then
								info.timeout = item.interval + ev.time
							end
						end
					end
				end
			end
		end
		
		local occ = obj:get_occ()
		
		if self.guard_list[occ] then
			self.guard_list[occ] = nil
			self:update_guard_notify(self:get_owner())
		else
			local mana_list = td_config.config[self.id].mana_list
			if mana_list then
				self.total_mana = self.total_mana + (mana_list[occ] or 0)
			end
		end

		self.update_obj:pop_obj(obj_id)
	end
end

function Scene_td:carry_scene(obj, pos)
	if self.end_time then
		return SCENE_ERROR.E_SCENE_CLOSE
	end
	if not pos then
		pos = td_config.config[self.id].entry
	end
	local limit = self:get_self_limit_config()
	if self:get_human_count() >= limit.human[2] then
		return SCENE_ERROR.E_HUMAN_LIMIT
	end
	return Scene_instance.carry_scene(self, obj, pos)
end

function Scene_td:close()
	if self.instance_id then
		local team_obj = g_team_mgr:get_team_obj(self.instance_id)
		if team_obj then
			local team_l = team_obj:get_team_l()
			if team_l then
				local data = {}
				local obj_mgr = g_obj_mgr
				for k, _ in pairs(team_l) do
					local obj = obj_mgr:get_obj(k)
					if obj then
						table.insert(data, {["id"] = k, ["name"] = obj:get_name()})
					end
				end
				
				g_public_sort_mgr:update_record(
					PUBLIC_SORT_TYPE.SCENE
					, self.sequence
					, {["scene_id"] = self.id, ["id"] = 0, ["data"] = data}
					, PUBLIC_SORT_ORDER.DESC)
			end
		end
		
		Scene_instance.close(self)
	end
end

function Scene_td:next_sequence()
	if self.is_success then
		return
	end

	self.sequence = self.sequence + 1
	self.counter = {}
	self.update_over = false

	local declare = td_config.config[self.id].declare
	
	local freq = declare[self.sequence]
	if not freq then
		self.is_success = true
		--self:close()
		return
	end
	
	local obj_mgr = g_obj_mgr
	
	for obj_id, _ in pairs(self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN):get_obj_list()) do
		local obj = obj_mgr:get_obj(obj_id)
		if obj then
			local args = obj:get_scene_args()
			local id = tostring(self.id)
			local max_layer = args[id] or 0
			if max_layer < self.sequence then
				args[id] = self.sequence
			end
		end
	end

	self.next_time = ev.time + freq.interval
	
	if freq.sequence then
		for _, item in pairs(freq.sequence) do
			local info = {}
			info.item = item
			info.count = 0
			info.timeout = ev.time
			table.insert(self.counter, info)
		end
	end
end

function Scene_td:update()
	local has_update = false
	
	local born = td_config.config[self.id].born
	local obj_mgr = g_obj_mgr
	local now = ev.time

	for k, info in pairs(self.counter) do
		if info.timeout <= now then
			local item = info.item
			if info.count < item.count then
				info.count = info.count + 1
				info.timeout = now + item.span
				
				local path = born[item.path]
				local args = {path.path, self.heart_id}
				for i = 1, item.number do
					local obj = obj_mgr:create_monster(item.id, path.pos, self.key, args)
					self:enter_scene(obj)
					self.update_obj:push_obj(obj:get_id())
				end
			else
				self.counter[k] = nil
			end
		end
		has_update = true
	end

	if not has_update then
		self.update_over = true
	end
end

function Scene_td:update_wild()
	local obj_mgr = g_obj_mgr
	local now = ev.time
	local wild = td_config.config[self.id].wild
	if not wild then
		return
	end
	
	local remove_list = {}
	for area, sequence in pairs(self.area_list) do
		local info = wild[area]
		if info and 0 == sequence.number and sequence.timeout <= now then
			local is_remove = true
			local item = info[sequence.sequence]
			if item then
				local num = 0
				for i = 1, item.number do
					local pos = self.map_obj:find_space(area, 20)
					if pos then
						local obj = obj_mgr:create_monster(item.id, pos, self.key)
						if obj and SCENE_ERROR.E_SUCCESS == self:enter_scene(obj) then
							self.area_monster[obj:get_id()] = area
							num = num + 1
						end
					end
				end
				
				sequence.number = num
				sequence.sequence = sequence.sequence + 1
				if info[sequence.sequence] then
					is_remove = false
				end
			end
			
			if is_remove then
				table.insert(remove_list, area)
			end
		end
	end
	
	for _, v in pairs(remove_list) do
		self.area_list[v] = nil
	end
end

function Scene_td:on_slow_timer(tm)
	self:update_wild()
	self.obj_mgr:on_slow_timer(tm)
end

function Scene_td:on_timer(tm)
	local now = ev.time
	if self.end_time and self.end_time <= now then
		self:close()
		return
	end
	
	if self.next_time <= now then
		self:next_sequence()
	end
	
	self:update()
	self.obj_mgr:on_timer(tm)
	
	if not self.end_time then
		local freq = td_config.config[self.id].declare[self.sequence]
		if freq then
			local obj_mgr = g_obj_mgr
			
			local heart = {0, 0}
			local obj = self.heart_id and obj_mgr:get_obj(self.heart_id)
			if obj then
				heart = {obj:is_alive() and obj:get_hp() or 0, obj:get_max_hp()}
			end
			
			
			local npc_list = {}
			for occ, info in pairs(self.guard_list) do
				if self.heart_id ~= info.id then
					local npc = {info.name, 0, 0}
					local obj = obj_mgr:get_obj(info.id)
					if obj then
						table.insert(npc_list, {info.name, obj:get_hp(), obj:get_max_hp()})
					else
						table.insert(npc_list, {info.name, 0, 0})
					end
				end
			end
		
			local pkt = {}
			pkt.type = 2
			pkt.param_l = {
				["mana"] = self.total_mana
				, ["heart"] = heart
				, ["time"] = math.max(self.next_time - now, 0)
				, ["desc"] = freq.text
				, ["name"] = freq.name
				, ["npc"] = npc_list
			}
			
			local json = Json.Encode(pkt)
			for obj_id, _ in pairs(self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN):get_obj_list()) do
				self:send_human(obj_id, CMD_MAP_PLAYER_OPERATE_SYN, json, true)
			end
		end
	end
end

function Scene_td:caption_event(char_id)
	if char_id then
		self:update_guard_notify(char_id)
		self:update_buff_notify(char_id)
	end
end

function Scene_td:is_attack(attacker_id, defender_id)
	if self.end_time then
		return SCENE_ERROR.E_ATTACK_BAN
	end

	if self.heart_id == defender_id then
		local type = Obj_mgr.obj_type(attacker_id)
		if OBJ_TYPE_HUMAN == type or OBJ_TYPE_PET == type then
			return SCENE_ERROR.E_HEART
		end
	end
	
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
	
	if OBJ_TYPE_PET == attacker:get_type() then
		attacker = g_obj_mgr:get_obj(attacker:get_owner_id())
	end
	
	if OBJ_TYPE_HUMAN == attacker:get_type() and defender:get_occ() > MONSTER_GUARD then
		return SCENE_ERROR.E_HEART
	end
	
	if OBJ_TYPE_HUMAN == defender:get_type() and attacker:get_occ() > MONSTER_GUARD then
		return SCENE_ERROR.E_HEART
	end
		
	return scene_mode:can_attack(attacker, defender)
end

function Scene_td:summon_guard(obj_id, occ)
	if obj_id ~= self:get_owner() then
		return SCENE_ERROR.E_CAPTION_USE
	end
	
	local obj = self:get_obj(obj_id)
	if not obj then
		return SCENE_ERROR.E_NOT_ON_SCENE
	end
	
	local helper = td_config.config[self.id].helper
	local guard_list = helper and helper.guard
	local guard = guard_list and guard_list[occ]
	if not guard then
		return SCENE_ERROR.E_NOT_CONFIG
	end
	
	local npc = self.guard_list[occ]
	if npc then
		local lv = npc.lv + 1
		
		local info = guard.level_list[lv]
		if not info then
			return SCENE_ERROR.E_NOT_CONFIG
		end
		
		local monster = self:get_obj(npc.id)
		if not monster then
			return SCENE_ERROR.E_NOT_ON_SCENE
		end
		
		if self.total_mana < info.mana then
			return SCENE_ERROR.E_NOT_MANA
		end
		
		local pack_con = obj:get_pack_con()
		if info.item_id then
			if pack_con:get_item_count(info.item_id) < 1 then
				return SCENE_ERROR.E_NOT_ITEM
			end
			
			if 0 ~= pack_con:del_item_by_item_id(info.item_id, 1, {['type'] = ITEM_SOURCE.USE_ITEM}) then
				return SCENE_ERROR.E_NOT_ITEM
			end
		end
		
		self.total_mana = self.total_mana - info.mana
		
		npc.lv = lv
		monster:upgrade()
		
	else
		local info = guard.level_list[1]
		if self.total_mana < info.mana then
			return SCENE_ERROR.E_NOT_MANA
		end
		
		local pack_con = obj:get_pack_con()
		if info.item_id then
			if pack_con:get_item_count(info.item_id) < 1 then
				return SCENE_ERROR.E_NOT_ITEM
			end
			
			if 0 ~= pack_con:del_item_by_item_id(info.item_id, 1, {['type'] = ITEM_SOURCE.USE_ITEM}) then
				return SCENE_ERROR.E_NOT_ITEM
			end
		end
		
		self.total_mana = self.total_mana - info.mana
		local monster = g_obj_mgr:create_monster(occ, guard.pos, self.key, {self.instance_id})
		if occ == 9204 and monster ~= nil then
			monster:set_heart_id(self.heart_id)
		end
		self:enter_scene(monster)
		self.guard_list[occ] = {
			["id"] = monster:get_id()
			, ["lv"] = 1
			, ["name"] = guard.name
		}
	end
	
	self:update_guard_notify(obj_id)
	
	return SCENE_ERROR.E_SUCCESS
end

function Scene_td:use_buff(obj_id, buff_id)
	if obj_id ~= self:get_owner() then
		return SCENE_ERROR.E_CAPTION_USE
	end
	
	local helper = td_config.config[self.id].helper
	local buff_list = helper and helper.buff
	local buff = buff_list and buff_list[buff_id]
	if not buff then
		return SCENE_ERROR.E_NOT_CONFIG
	end
	
	if self.total_mana < buff.mana then
		return SCENE_ERROR.E_NOT_MANA
	end
	
	self.total_mana = self.total_mana - buff.mana
	for obj_id, _ in pairs(self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN):get_obj_list()) do
		f_td_add_impact(obj_id, buff_id)
	end
	
	return SCENE_ERROR.E_SUCCESS
end

function Scene_td:use_refresh(obj_id)
	if obj_id ~= self:get_owner() then
		return SCENE_ERROR.E_CAPTION_USE
	end

	print(self.update_over, self.update_obj:get_obj_count())

	if not self.update_over or 0 ~= self.update_obj:get_obj_count() then
		return SCENE_ERROR.E_UPDATE_OVER
	end
	
	self:next_sequence()

	return SCENE_ERROR.E_SUCCESS
end