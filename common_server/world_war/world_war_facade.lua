local ww_config = require("config.world_war.config_loader")
local NAME_LIMIT = 9
local REQUEST_TIMEOUT = 5 * 60
local SYSTEM_TIMEOUT = 60

World_war_facade = oo.class(nil, "World_war_facade")

function World_war_facade:__init()
--[[
	k = obj_id
	v = {team_id, obj_id, attribute, exterior}
]]
	self.players_list = {}

--[[
	k = team_name
	v = team_id
]]
	self.name_to_team = {}

--[[
	k = team_id
	v = {team_id, team_name, members = [obj_id, ...]}
]]
	self.team_list = {}

--[[
	k = obj_id
	v = {type, obj_id, stamp, method, timeout, args}
]]
	self.confirm_list = {}

	self.key = nil
	self.ip = nil
	self.port = nil
	
	self.account_cache = Account_cache()
	
	self.prefix = AGENT_NAME.." "..SERVER_NAME
	
	self.status = CS.CS_NIL
	
	self.team_sort = {}
	self.match_sort = {}
	
	self.next_time = ev.time
	
	self.winner_info = {}
	
	self.battle_history = {}
	
	self.register_end_time = nil
end

------------------------------------------------------------------------------------------------

function World_war_facade:init()
	local level_limit = ww_config.config.register.limit.level
	self.account_cache:load(level_limit[1], level_limit[2])
	
	local row, e_code = f_get_db():select_one("world_war_config", "{_id:0, name:0}", "{name:'statue'}")
	if row and 0 == e_code then
		self.winner_info = row.info or {}
	end
end

function World_war_facade:reset_service(requset)
	self.key = nil
	self.ip = nil
	self.port = nil
	self:register_request()
end

function World_war_facade:get_entry_info(obj_id)
	local response = {}
	
	if (CS.CS_QUA ~= self.status) and (CS.CS_KNO ~= self.status) then
		response.result = WW_ERROR.E_OPEN
		return response
	end
	
	if not self.key or not self.ip or not self.port or not self.players_list[obj_id] then
		response.result = WW_ERROR.E_NOT_SIGNUP
		return response
	end
	
	local cache = self.account_cache:find(obj_id)
	if not cache then
		response.result = WW_ERROR.E_NOT_SIGNUP
		return response
	end
	
	local now = ev.time
	local sid = AGENT_ID.."#"..cache[2]
	local sign = crypto.md5(cache[1]..sid..self.key..now)
	response.result = 0
	response.sid = sid
	response.ip = self.ip
	response.port = self.port
	response.sign = sign
	response.time = now
	
	if not self.next_time or self.next_time < now then
		self.next_time = now
	end
	
	response.wait = math.min(self.next_time - now, 60)

	self.next_time = self.next_time + 1
	return response
end
------------------------------------------------------------------------------------------------

function World_war_facade:on_timer()
	local now = ev.time
	for k, v in pairs(self.confirm_list) do
		if v.timeout < now then
			local fun = self[v.method]
			if fun then
				fun(self, v)
			else
				print("Not method", v.method)
			end
		end
	end
end

function World_war_facade:build_request_record(type, obj_id, args)
	local record = {}
	record.type = type
	record.obj_id = obj_id
	record.stamp = ev.time
	record.timeout = REQUEST_TIMEOUT + ev.time
	record.args = args
	return record
end

function World_war_facade:extract_confirm_response(type, response)
	local obj_id = response.obj_id
	local record = self.confirm_list[obj_id]
	if not record or type ~= record.type then
		return WW_ERROR.E_INVALID_RESPONSE
	end
	
	if record.stamp ~= response.stamp then
		return WW_ERROR.E_RETRY, record
	end
	
	self.confirm_list[obj_id] = nil
	return WW_ERROR.E_SUCCESS, record
end

function World_war_facade:update(response)
	self.status = response.status
	
	if response.team_list then
		self.team_list = {}
		self.players_list = {}
		self.name_to_team = {}
		
		for _, team_list in ipairs(response.team_list) do
			for team_id, team in pairs(team_list) do
				local info = {
					["team_id"] = team_id
					, ["team_name"] = team.team_name
					, ["logo"] = team.logo
					, ["members"] = {}}
				for _, v in ipairs(team.members) do
					local obj_id = self.account_cache:find_of_account(v.server_id, v.account_name)
					if obj_id then
						self.players_list[obj_id] = {
							["team_id"] = team_id
							, ["obj_id"] = obj_id
							, ["exterior"] = v.exterior
							, ["sample"] = {obj_id, v.sample[1], v.sample[2], v.sample[3], v.sample[4], v.sample[5]}
						}
					
						table.insert(info.members, obj_id)
					else
						print("Error: World_war_facade:sync_response(", v.server_id, v.account_name, ")")
					end
				end
				self.team_list[team_id] = info
				self.name_to_team[team.team_name] = team_id
			end
		end
		
		self:all_team_sync()
	end
	
	if response.team_sort then
		self.team_sort = response.team_sort
		self:team_sort_sync()
	end
	
	if response.history then
		self.battle_history = response.history
		self:battle_history_sync()
	end
	
	if response.match_sort then
		self.match_sort = response.match_sort
		self:match_sort_sync()
		if self.match_sort.winner then
			self.winner_info = {['members'] = {}}
		
			local team = self.match_sort.team[self.match_sort.winner]
			local prefix = string.match(team[3], ".+%s")
			
			for _, member in ipairs(team[4]) do
				table.insert(self.winner_info.members, {prefix..member[1], member[3], member[5]})
			end
			
			self.winner_info.info = {team[3], team[4]}
			
			f_get_db():update("world_war_config", "{name:'statue'}", Json.Encode({["info"] = self.winner_info}), true)
		end

	end
end

function World_war_facade:send_reward(server_id, account_name, content, box_title, reward)
	local email = {}
	email.sender = -1
	email.recevier = self.account_cache:find_of_account(server_id, account_name)
	email.title = f_get_string(2400)
	email.content = content
	email.box_title = box_title
	email.money_list = {}
	
	email.item_list = {}
	for _, v in ipairs(reward) do
		local item = {}
		item.id = v[1]
		item.name = v[3]
		item.count = v[2]
		table.insert(email.item_list, item)
	end
	
	g_email_mgr:send_email_interface(email)
end

function World_war_facade:change_sync(response)
	if not response.type or 1 == response.type then
		self.status = response.status
		self.register_end_time = response.register_end_time
		self:update(response)
		self:status_sync()
	elseif 2 == response.type then
		local content = response.ranking and string.format(f_get_string(2411) , response.ranking) or f_get_string(2410)
		self:send_reward(
			response.server_id
			, response.account_name
			, content
			, content
			, response.reward)
	elseif 3 == response.type then
		local lv = math.pow(2, response.ranking)
		local content = (1 == lv) and f_get_string(2413) or string.format(f_get_string(2412), lv)
		self:send_reward(
			response.server_id
			, response.account_name
			, content
			, content
			, response.reward)
	elseif 4 == response.type then
		local pkt = {}
		pkt.type = 3
		pkt.msg = response.msg
		g_server_mgr:send_to_all_map(0, CMD_C2M_WORLD_WAR_UPDATE_SYN, pkt)
	elseif 5 == response.type then
		local pkt = {}
		pkt.type = 4
		pkt.buff = response.buff
		g_server_mgr:send_to_all_map(0, CMD_C2M_WORLD_WAR_UPDATE_SYN, pkt)	
	end
end
------------------------------------------------------------------------------------------------

function World_war_facade:send_register_request(record)
	record.method = "send_register_request"
	record.timeout = SYSTEM_TIMEOUT + ev.time

	local pkt = {}
	pkt.stamp = record.stamp
	pkt.obj_id = record.obj_id
	pkt.agent_id = AGENT_ID
	pkt.server_id = SERVER_ID
	pkt.prefix = self.prefix
	pkt.server_list = self.account_cache:get_server_list()
	pkt.key = crypto.md5(GATE_KEY)
	
	g_svsock_mgr:send_server_ex(GATE_ID, 0, CMD_C2A_WORLD_WAR_REGISTER_REQ, pkt)
end

function World_war_facade:register_request(request)
	local record = self:build_request_record(WW_SERVICE.WW_REGISTER, 0, {})
	self.confirm_list[0] = record
	self:send_register_request(record)
	return WW_ERROR.E_SUCCESS
end

function World_war_facade:register_response(response)
	local e_code, record = self:extract_confirm_response(WW_SERVICE.WW_REGISTER, response)
	if WW_ERROR.E_SUCCESS ~= e_code then
		return e_code
	end
	
	self.key = response.key
	self.ip = response.ip
	self.port = response.port
	self.status = response.status
	
	self:sync_request()
	return WW_ERROR.E_SUCCESS
end

-----------------------------------------------------------------------------------------------

function World_war_facade:send_sync_request(record)
	record.method = "send_sync_request"
	record.timeout = SYSTEM_TIMEOUT + ev.time

	local pkt = {}
	pkt.stamp = record.stamp
	pkt.obj_id = record.obj_id
	
	g_svsock_mgr:send_server_ex(GATE_ID, 0, CMD_C2A_WORLD_WAR_SYNC_REQ, pkt)
end

function World_war_facade:sync_request(request)
	local record = self:build_request_record(WW_SERVICE.WW_SYNC, 0, {})
	self.confirm_list[0] = record
	self:send_sync_request(record)
	return WW_ERROR.E_SUCCESS
end

function World_war_facade:sync_response(response)
	local e_code, record = self:extract_confirm_response(WW_SERVICE.WW_SYNC, response)
	if WW_ERROR.E_SUCCESS ~= e_code then
		return e_code
	end
	
	self.register_end_time = response.register_end_time
	self:update(response)
	self:status_sync()
	return WW_ERROR.E_SUCCESS
end

-----------------------------------------------------------------------------------------------

function World_war_facade:send_signup_request(record)
	print("send_signup_request")
	record.method = "send_signup_request"
	record.timeout = REQUEST_TIMEOUT + ev.time

	local members = {}
	for _, v in ipairs(record.args.members) do
		local member = {}
		member.obj_id = v.obj_id
		member.attribute = v.attribute
		member.exterior = v.exterior
		member.sample = v.sample
		member.account_name = v.account_name
		member.server_id = v.server_id
		table.insert(members, member)
	end
	
	local pkt = {}
	pkt.stamp = record.stamp
	pkt.obj_id = record.obj_id
	pkt.team_name = self.prefix.." "..record.args.team_name
	pkt.logo = record.args.logo
	pkt.members = members
	
	g_svsock_mgr:send_server_ex(GATE_ID, 0, CMD_C2A_WORLD_WAR_SIGNUP_REQ, pkt)
end

function World_war_facade:signup_request(request)
	if CS.CS_REG ~= self.status then
		return WW_ERROR.E_STATUS
	end

	local team_name = request.team_name

	if not team_name or NAME_LIMIT < string.len(team_name) then
		return WW_ERROR.E_NAME_LIMIT
	end
	
	--如果前缀存在则加上前缀去测试名字是否重复,否则放入发送队列,直到前缀存在为止才进行真正的发送
	if self.name_to_team[self.prefix.." "..team_name] then
		return WW_ERROR.E_NAME_EXISTS
	end

	local owner_id = request.obj_id
	
	if self.players_list[owner_id] then
		return WW_ERROR.E_ALREADY_SIGNUP
	end
	
	if self.confirm_list[owner_id] then
		return WW_ERROR.E_ALREADY_CONFIRM
	end
	
	local members = {}
	local has_teamer = false
	
	local count = 0
	for _, v in ipairs(request.members) do
		local obj_id = v.obj_id
		if self.players_list[obj_id] then
			return WW_ERROR.E_ALREADY_SIGNUP
		end
		
		if owner_id == obj_id then
			if has_teamer then
				return WW_ERROR.E_DUP_MEMBER
			end
			has_teamer = true
		end
		
		count = count + 1
		
		local cache = self.account_cache:find(obj_id)
		
		local member = {}
		member.obj_id = obj_id
		member.attribute = v.attribute
		member.exterior = v.exterior
		member.sample = v.sample
		member.account_name = cache[1]
		member.server_id = cache[2]
		table.insert(members, member)
	end
	
	if not has_teamer then
		return WW_ERROR.E_NOT_TEAMER
	end
	
	local human = ww_config.config.register.limit.human
	if (human[1] and human[1] > count) or (human[2] and human[2] < count) then
		return WW_ERROR.E_MEMBER_LIMIT
	end
	
	local record = self:build_request_record(
						WW_SERVICE.WW_SIGNUP
						, owner_id
						, {
							["team_name"] = team_name
							, ["logo"] = request.logo
							, ["members"] = members
						})
	
	self.confirm_list[owner_id] = record
	
	self:send_signup_request(record)
	
	return WW_ERROR.E_SUCCESS
end

function World_war_facade:signup_response(response)
	local e_code, record = self:extract_confirm_response(WW_SERVICE.WW_SIGNUP, response)
	if WW_ERROR.E_SUCCESS ~= e_code then
		return e_code
	end
	
	if WW_ERROR.E_STATUS == response.result then
		self.status = response.status
	end
	
	if WW_ERROR.E_SUCCESS ~= response.result then
		print("World_war_facade:signup_response result = ", response.result)
		
		--发邮件
		for _, v in ipairs(record.args.members) do
			local email = {}
			email.sender = 0
			email.recevier = record.obj_id
			email.title = f_get_string(2400)
			email.content = f_get_string(2403)
			g_email_mgr:send_email_interface_no_box(email)
		end
		
		return WW_ERROR.E_SUCCESS
	end
	
	local team_name = response.team_name
	local team_id = response.team_id
	self.name_to_team[team_name] = team_id
	
	local team = {}
	team.team_id = team_id
	team.team_name = team_name
	team.logo = record.args.logo
	team.members = {}
	for _, v in ipairs(record.args.members) do
		local obj_id = v.obj_id
		self.players_list[obj_id] = {
			["team_id"] = team_id
			, ["obj_id"] = obj_id
			, ["sample"] = {obj_id, v.sample[1], v.sample[2], v.sample[3], v.sample[4], v.sample[5]}
			, ["exterior"] = v.exterior
		}
		
		table.insert(team.members, obj_id)
	end
	
	self.team_list[team_id] = team
	self:team_update_sync(team_id)
	
	--发邮件
	for _, v in ipairs(record.args.members) do
		local email = {}
		email.sender = 0
		email.recevier = v.obj_id
		email.title = f_get_string(2400)
		email.content = f_get_string(2401)
		g_email_mgr:send_email_interface_no_box(email)
	end
	
	return WW_ERROR.E_SUCCESS
end

----------------------------------------------------------------------------------------------------------

function World_war_facade:send_refresh_request(record)
	record.method = "send_refresh_request"
	record.timeout = REQUEST_TIMEOUT + ev.time
	
	local pkt = {}
	pkt.stamp = record.stamp
	pkt.obj_id = record.obj_id
	pkt.account_name = record.args.account_name
	pkt.server_id = record.args.server_id
	pkt.attribute = record.args.attribute
	pkt.exterior = record.args.exterior
	pkt.sample = record.args.sample
	
	g_svsock_mgr:send_server_ex(GATE_ID, 0, CMD_C2A_WORLD_WAR_REFRESH_REQ, pkt)
end

function World_war_facade:refresh_player_request(request)
	local obj_id = request.obj_id
	
	if not self.players_list[obj_id] then
		return WW_ERROR.E_NOT_SIGNUP
	end

	local cache = self.account_cache:find(obj_id)
	
	local record = self:build_request_record(
						WW_SERVICE.WW_REFRESH
						, obj_id
						, {
							["account_name"] = cache[1]
							, ["server_id"] = cache[2]
							, ["attribute"] = request.attribute
							, ["exterior"] = request.exterior
							, ["sample"] = request.sample
						})
	
	self.confirm_list[obj_id] = record
	
	self:send_refresh_request(record)
	
	return WW_ERROR.E_SUCCESS
end

function World_war_facade:refresh_player_response(response)
	local e_code, record = self:extract_confirm_response(WW_SERVICE.WW_REFRESH, response)
	if WW_ERROR.E_SUCCESS ~= e_code then
		return e_code
	end
	
	if WW_ERROR.E_STATUS == response.result then
		self.status = response.status
	end
	
	local obj_id = response.obj_id

	if WW_ERROR.E_SUCCESS ~= response.result then
		print("World_war_facade:refresh_player_response = ", response.result)
		
		--发邮件
		local email = {}
		email.sender = 0
		email.recevier = obj_id
		email.title = f_get_string(2400)
		email.content = f_get_string(2404)
		g_email_mgr:send_email_interface_no_box(email)
		
		return WW_ERROR.E_SUCCESS
	end
	
	
	local info = self.players_list[obj_id]
	local sample = record.args.sample

	info.sample = {obj_id, sample[1], sample[2], sample[3], sample[4], sample[5]}
	info.exterior = record.args.exterior
	
	self:team_update_sync(info.team_id)

	--发邮件
	local email = {}
	email.sender = 0
	email.recevier = obj_id
	email.title = f_get_string(2400)
	email.content = f_get_string(2402)
	g_email_mgr:send_email_interface_no_box(email)
	
	return WW_ERROR.E_SUCCESS
end

---------------------------------------------------------------------------------------------------------

function World_war_facade:extract_update_info(info)
	local team = {}
	team.team_id = info.team_id
	team.team_name = info.team_name
	team.members = {}
	for _, obj_id in ipairs(info.members) do
		table.insert(
			team.members
			, {
				["team_id"] = info.team_id
				, ["obj_id"] = obj_id
				, ["sample"] = self.players_list[obj_id].sample
				, ["exterior"] = self.players_list[obj_id].exterior
			})
	end
	
	return team
end

function World_war_facade:team_sort_sync(server_id)
	local response = {}
	response.type = 1
	response.team_sort = self.team_sort
	
	if server_id then
		g_server_mgr:send_to_server(server_id, 0, CMD_C2M_WORLD_WAR_UPDATE_SYN, response)
	else
		g_server_mgr:send_to_all_map(0, CMD_C2M_WORLD_WAR_UPDATE_SYN, response)
	end
end

function World_war_facade:battle_history_sync(server_id)		
	local response = {}
	response.type = 1
	response.history = self.battle_history
	
	if server_id then
		g_server_mgr:send_to_server(server_id, 0, CMD_C2M_WORLD_WAR_UPDATE_SYN, response)
	else
		g_server_mgr:send_to_all_map(0, CMD_C2M_WORLD_WAR_UPDATE_SYN, response)
	end
end

function World_war_facade:match_sort_sync(server_id)
	local response = {}
	response.type = 1
	response.match_sort = self.match_sort
	
	if server_id then
		g_server_mgr:send_to_server(server_id, 0, CMD_C2M_WORLD_WAR_UPDATE_SYN, response)
	else
		g_server_mgr:send_to_all_map(0, CMD_C2M_WORLD_WAR_UPDATE_SYN, response)
	end
end

function World_war_facade:team_update_sync(team_id, server_id)
	local info = self.team_list[team_id]
	if info then
		local list = {}
		table.insert(list, self:extract_update_info(info))
		local response = {}
		response.type = 1
		response.list = list
		
		if server_id then
			g_server_mgr:send_to_server(server_id, 0, CMD_C2M_WORLD_WAR_UPDATE_SYN, response)
		else
			g_server_mgr:send_to_all_map(0, CMD_C2M_WORLD_WAR_UPDATE_SYN, response)
		end
	end
end

function World_war_facade:all_team_sync(server_id)
	local list = {}
	for _, info in pairs(self.team_list) do
		table.insert(list, self:extract_update_info(info))
	end
	
	local response = {}
	response.type = 2
	response.list = list
	
	if server_id then
		g_server_mgr:send_to_server(server_id, 0, CMD_C2M_WORLD_WAR_UPDATE_SYN, response)
	else
		g_server_mgr:send_to_all_map(0, CMD_C2M_WORLD_WAR_UPDATE_SYN, response)
	end
end

function World_war_facade:status_sync(server_id)
	local response = {}
	response.type = 5
	response.status = self.status
	response.register_end_time = self.register_end_time
	
	if server_id then
		g_server_mgr:send_to_server(server_id, 0, CMD_C2M_WORLD_WAR_UPDATE_SYN, response)
	else
		g_server_mgr:send_to_all_map(0, CMD_C2M_WORLD_WAR_UPDATE_SYN, response)
	end
end

function World_war_facade:node_sync(server_id)
	self:all_team_sync(server_id)
	self:team_sort_sync(server_id)
	self:match_sort_sync(server_id)
	self:battle_history_sync(server_id)
	self:status_sync(server_id)
end

---------------------------------------------------------------------------------------------------------

function World_war_facade:get_winner_info()
	return self.winner_info
end