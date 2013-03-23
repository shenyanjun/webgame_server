local ww_config = require("config.world_war.config_loader")
local NAME_LIMIT = 9

World_war_mgr = oo.class(nil, "World_war_mgr")

function World_war_mgr:__init()
	self.players_list = {}
	self.team_name_list = {}
	self.signup_cache = {["count"] = 0, ["list"] = {}}
	
	self.team_list = {}
	self.team_sort = {}
	self.match_sort = {}
	
	self.history = {}
	self.history_size = 0
	
	self.status = CS.CS_NIL
end

function World_war_mgr:on_timer()
end

function World_war_mgr:extract_exterior(obj)
	local exterior = {}
	exterior.obj_id = obj:get_id()
	exterior.info = obj:net_get_info()
	exterior.attribute = obj:net_get_self_att_info(1)
	local pack_con = obj:get_pack_con()
	exterior.equip = pack_con:get_equip_ex()
	return exterior
end

function World_war_mgr:extract_signup_info(obj)
	local info = {}
	info.obj_id = obj:get_id()
	local obj_info = obj:get_db():get_save_info()
	
	obj_info.hp = obj:get_max_hp()
	obj_info.mp = obj:get_max_mp()
	obj_info.exp = 0
	obj_info.evil = 0

	obj_info.map_id = nil
	obj_info.pos_x = nil
	obj_info.pos_y = nil

	obj_info.last_login_time = 0
				
	obj_info.frenzy_param = {}
	obj_info.scene_args = {}
	obj_info.quest_param = {}
	
	info.player = obj_info
	
	info.bags = {}
	
	local bag_list = {EQUIPMENT_BAG, MOUNTS_BAG}
	for _, bag_id in ipairs(bag_list) do
		local e_code, bag = obj:get_pack_con():get_bag(bag_id)
		if e_code == 0 and bag then
			local record = {}
			record.bag = bag_id
			record.size = bag:get_size()
			record.item_l = bag:db_get_bag_all_log()
			record.attribute = bag:db_get_bag_attribute()
			table.insert(info.bags, record)
		end
	end
	
	local skill_con = obj:get_skill_con()
	info.skill = skill_con:extract_skill_list_info()

	local action_con = obj:get_action_con()
	info.action = action_con:extract_action_info()
	local action_list = {}
	for k, v in pairs(info.action.item_list) do
		if v.btn_type == 1 then
			action_list[k] = v
		end
	end
	info.action.item_list = action_list
	--渡劫 提取注册信息 chendong 120925
	--info.kalpa = g_kalpa_mgr:get_db_info(info.obj_id)
	info.soul = obj:get_soul():get_con_info()
	info.reigns = obj:get_reigns():get_reigns_db_list()
	info.ride_study = obj:get_ride_con():get_ride_data()
	info.magickey = obj:get_magickey_con():get_all_info()
	
	info.pet_list = {}
	local pet_con = obj:get_pet_con()
	for pet_id, pet_obj in pairs(pet_con.pet_l) do
		local record = {}
		record.attribute = pet_obj.db:extract_pet_info()
		record.skill = pet_obj:get_skill_con():extract_skill_list_info()
		record.equipment = pet_obj.db.pack_con:serialize_to_db()
		pet_obj:set_lock_time(self.register_end_time)
		table.insert(info.pet_list, record)
	end
	
	return info
end

-----------------------------------------------------------------------------------------------------------------------------------

function World_war_mgr:signup_impl(obj_id, team_name, logo)
	if CS.CS_REG ~= self.status then
		return WW_ERROR.E_NOT_READY
	end

	local obj = g_obj_mgr:get_obj(obj_id)
	local team_id = obj:get_team()
	local team_obj = team_id and g_team_mgr:get_team_obj(team_id)
	if not team_obj then
		return WW_ERROR.E_INVALID_TEAM
	end
	
	if team_obj:get_teamer_id() ~= obj_id then									--检查是否是队长
		return WW_ERROR.E_INVALID_CAPTION
	end
	
	local team_l, team_count = team_obj:get_team_l()
	local human = ww_config.config.register.limit.human
	if (human[1] and human[1] > team_count) or (human[2] and human[2] < team_count) then
		return WW_ERROR.E_MEMBER_LIMIT
	end
	
	if not team_name or NAME_LIMIT < string.len(team_name) then
		return WW_ERROR.E_NAME_LIMIT
	end
	
	if self.team_name_list[team_name] then
		return WW_ERROR.E_NAME_EXISTS
	end
	
	local request = {}
	request.obj_id = obj_id
	request.team_name = team_name
	request.logo = logo
	request.members = {}
	local obj_mgr = g_obj_mgr
	local team_l, team_count = team_obj:get_team_l()
	
	local level_limit = ww_config.config.register.limit.level
	for k, _ in pairs(team_l) do
		if self.players_list[k] then
			return WW_ERROR.E_ALREADY_SIGNUP
		end	
	
		local obj = obj_mgr:get_obj(k)
		if obj then
			local level = obj:get_level()
			if (level_limit[1] and level_limit[1] > level) or (level_limit[2] and level_limit[2] < level) then
				return WW_ERROR.E_LEVEL_LIMIT
			end
			
			local record = {}
			record.obj_id = obj:get_id()
			record.attribute = self:extract_signup_info(obj)
			record.exterior = self:extract_exterior(obj)
			record.sample = {obj:get_name(), obj:get_level(), obj:get_occ(), obj:get_fighting(), obj:get_sex()}
			table.insert(request.members, record)
		else
			return WW_ERROR.E_NOT_ONLINE
		end
	end

	g_svsock_mgr:send_server_ex(COMMON_ID, 0, CMD_M2C_WORLD_WAR_SIGNUP_REQ, request)
	
	return WW_ERROR.E_SUCCESS
end

function World_war_mgr:signup(obj_id, team_name, logo)
	if CS.CS_REG ~= self.status then
		return WW_ERROR.E_NOT_READY
	end

	local obj = g_obj_mgr:get_obj(obj_id)
	local team_id = obj:get_team()
	local team_obj = team_id and g_team_mgr:get_team_obj(team_id)
	if not team_obj then
		return WW_ERROR.E_INVALID_TEAM
	end
	
	if team_obj:get_teamer_id() ~= obj_id then									--检查是否是队长
		return WW_ERROR.E_INVALID_CAPTION
	end
	
	local team_l, team_count = team_obj:get_team_l()
	local human = ww_config.config.register.limit.human
	if (human[1] and human[1] > team_count) or (human[2] and human[2] < team_count) then
		return WW_ERROR.E_MEMBER_LIMIT
	end
	
	if not team_name or NAME_LIMIT < string.len(team_name) then
		return WW_ERROR.E_NAME_LIMIT
	end
	
	if self.team_name_list[team_name] then
		return WW_ERROR.E_NAME_EXISTS
	end
	
	local obj_mgr = g_obj_mgr
	local team_l, team_count = team_obj:get_team_l()
	
	local level_limit = ww_config.config.register.limit.level
	for k, _ in pairs(team_l) do
		if self.players_list[k] then
			return WW_ERROR.E_ALREADY_SIGNUP
		end
	
		local obj = obj_mgr:get_obj(k)
		if obj then
			local level = obj:get_level()
			if (level_limit[1] and level_limit[1] > level) or (level_limit[2] and level_limit[2] < level) then
				return WW_ERROR.E_LEVEL_LIMIT
			end
		else
			return WW_ERROR.E_NOT_ONLINE
		end
	end
	
	local this = self
	f_team_fun_ack(
		team_id
		, obj_id
		, 1
		, 20
		, function()
			local response = {}
			response.result = this:signup_impl(obj_id, team_name, logo)
			if WW_ERROR.E_SUCCESS ~= response.result then
				g_cltsock_mgr:send_client(obj_id, CMD_MAP_WORLD_WAR_SIGNUP_S, response)
			end
		end
		, function(team_obj, obj_id)
			local obj = g_obj_mgr:get_obj(obj_id)
		
			local email = {}
			email.sender = -1
			email.title = f_get_string(2400)
			email.content = string.format(f_get_string(2417), obj and obj:get_name() or "")
			
			local team_l, team_count = team_obj:get_team_l()
			for k, _ in pairs(team_l) do
				if k ~= obj_id then
					email.recevier = k
					g_svsock_mgr:send_server_ex(COMMON_ID, 0, CMD_M2P_SEND_EMAIL_NO_BOX_S, email)
				end
			end
		end)

	return WW_ERROR.E_WAIT_ACK
end

function World_war_mgr:refresh_player_info(obj_id)
	if CS.CS_REG ~= self.status then
		return WW_ERROR.E_NOT_READY
	end
	
	local obj = g_obj_mgr:get_obj(obj_id)
	
	if not self.players_list[obj_id] then
		return WW_ERROR.E_NOT_SIGNUP
	end
	
	local request = {}
	request.obj_id = obj_id
	request.attribute = self:extract_signup_info(obj)
	request.exterior = self:extract_exterior(obj)
	request.sample = {obj:get_name(), obj:get_level(), obj:get_occ(), obj:get_fighting(), obj:get_sex()}
	g_svsock_mgr:send_server_ex(COMMON_ID, 0, CMD_M2C_WORLD_WAR_REFRESH_REQ, request)
	
	return WW_ERROR.E_SUCCESS
end

function World_war_mgr:get_player_exterior(obj_id)
	return self.players_list[obj_id] and self.players_list[obj_id].exterior
end

function World_war_mgr:get_player_team(obj_id)
	local info = self.players_list[obj_id]
	if info then
		local team_id = info.team_id
		return self.signup_cache.list[self.team_list[team_id]]
	end
end

function World_war_mgr:get_signup_list()
	return self.signup_cache.list
end

function World_war_mgr:get_team_sort()
	return self.team_sort
end

function World_war_mgr:get_match_sort(order)
	local result = {}
	local record = nil
	if not order or 0 == order then
		result.order = 0
		result.records = 1 + self.history_size
		record = self.match_sort
	else
		record = self.history[order]
		if not record then
			return nil
		end
		result.order = order
		result.records = 1 + self.history_size
	end
	
	for k, v in pairs(record) do
		result[k] = v
	end
	
	return result
end
------------------------------------------------------------------------------------------------------------------------------------

function World_war_mgr:update_syn(response)
	if 2 == response.type then
		self.players_list = {}
		self.team_name_list = {}
		self.team_list = {}
		self.signup_cache = {["count"] = 0, ["list"] = {}}
	elseif 3 == response.type then
		local pkt = Json.Encode(response.msg)
		local list = g_obj_mgr:get_list(OBJ_TYPE_HUMAN)
		for obj_id, _ in pairs(list or {}) do
			g_cltsock_mgr:send_client(obj_id, CMD_MAP_WORLD_WAR_MSG_S, pkt, true)
		end
	elseif 4 == response.type then
		g_buffer_reward_mgr:world_war_buffer(response.buff)
	elseif 5 == response.type then
		self.register_end_time = response.register_end_time
		self.status = response.status
	end
	
	if response.list then
		for _, v in ipairs(response.list) do
			local team_id = v.team_id
			self.team_name_list[v.team_name] = team_id
			
			local team = {}
			team[1] = v.team_name
			local members = {}
			for _, member in ipairs(v.members) do
				local info = member.exterior.info	
				local obj_id = member.obj_id
				
				self.players_list[obj_id] = {
					["team_id"] = team_id
					, ["obj_id"] = obj_id
					, ["exterior"] = member.exterior
				}
				
				table.insert(members, member.sample)
			end
			team[2] = members
			
			local index = self.team_list[team_id]
			
			if not index then
				index = self.signup_cache.count + 1
				self.signup_cache.count = index
				self.team_list[team_id] = index
			end
			
			self.signup_cache.list[index] = team
		end
	end
	
	if response.team_sort then
		self.team_sort = response.team_sort
	end
	
	if response.match_sort then
		self.match_sort = response.match_sort
	end
	
	if response.history then
		self.history = response.history
		self.history_size = #self.history
	end
end