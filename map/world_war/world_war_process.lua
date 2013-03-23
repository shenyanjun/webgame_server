Clt_commands[1][CMD_MAP_WORLD_WAR_LIST_C] =
function(conn, pkt)
	print("CMD_MAP_WORLD_WAR_LIST_C")
	if 1 == pkt.type then
		local response = {}
		response.type = 1
		response.team = g_ww_mgr:get_player_team(conn.char_id)
		response.list = g_ww_mgr:get_signup_list()
		--print("-----1", j_e(response))
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_WORLD_WAR_LIST_S, response)
	elseif 2 == pkt.type then
		local response = {}
		response.type = 2
		response.list = g_ww_mgr:get_team_sort()
		--print("-----2", j_e(response))
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_WORLD_WAR_LIST_S, response)
	elseif 3 == pkt.type then
		local response = g_ww_mgr:get_match_sort(pkt.order)
		if response then
			response.type = 3
			--print("-----3", j_e(response))
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_WORLD_WAR_LIST_S, response)
		else
			print("Error: not order = ", pkt.order)
		end
	end
end

Clt_commands[1][CMD_MAP_WORLD_WAR_SIGNUP_C] =
function(conn, pkt)
	--print("CMD_MAP_WORLD_WAR_SIGNUP_C", j_e(pkt))
	local response = {}
	response.result = g_ww_mgr:signup(conn.char_id, pkt.name, pkt.icon)
	--print("-----", j_e(response))
	if WW_ERROR.E_SUCCESS ~= response.result then
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_WORLD_WAR_SIGNUP_S, response)
	end
end

Clt_commands[1][CMD_MAP_WORLD_WAR_REFRESH_C] =
function(conn, pkt)
	--print("CMD_MAP_WORLD_WAR_REFRESH_C", j_e(pkt))
	local response = {}
	response.result = g_ww_mgr:refresh_player_info(conn.char_id)
	--print("-----", j_e(response))
	if WW_ERROR.E_SUCCESS ~= response.result then
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_WORLD_WAR_REFRESH_S, response)
	end
end

Clt_commands[1][CMD_MAP_WORLD_WAR_ENTRY_C] =
function(conn, pkt)
	--print("CMD_MAP_WORLD_WAR_ENTRY_C", j_e(pkt))
	local response = {}
	response.obj_id = conn.char_id
	g_svsock_mgr:send_server_ex(COMMON_ID, 0, CMD_M2C_WORLD_WAR_ENTRY_REQ, response)
end

Clt_commands[1][CMD_MAP_WORLD_WAR_GET_INFO_C] =
function(conn, pkt)
	local response = {}
	response.result = 0
	response.obj_id = pkt.obj_id
		
	local exterior = g_ww_mgr:get_player_exterior(pkt.obj_id)
	if exterior then
		response.info = exterior.info
		response.attribute = exterior.attribute
		response.equip = exterior.equip
	else
		response.result = WW_ERROR.E_NOT_SIGNUP
	end
	g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_WORLD_WAR_GET_INFO_S, response)
end

---------------------------------------------------------------------------------------------------------------------------

Sv_commands[0][CMD_C2M_WORLD_WAR_UPDATE_SYN] =
function(conn, char_id, pkt)
	--print("CMD_C2M_WORLD_WAR_UPDATE_SYN", j_e(pkt))
	g_ww_mgr:update_syn(pkt)
end


