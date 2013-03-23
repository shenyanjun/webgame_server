-----------------------------------------------GATE----------------------------------------------

Sv_commands[1][CMD_A2C_WORLD_WAR_RESET_SYN] =
function(conn, char_id, pkt)
	print(Json.Encode(pkt))
	print("CMD_A2C_WORLD_WAR_RESET_SYN", g_ww_mgr:reset_service(pkt))
end

Sv_commands[1][CMD_A2C_WORLD_WAR_REGISTER_REP] =
function(conn, char_id, pkt)
	print("CMD_A2C_WORLD_WAR_REGISTER_REP", g_ww_mgr:register_response(pkt))
end

Sv_commands[1][CMD_A2C_WORLD_WAR_SIGNUP_REP] =
function(conn, char_id, pkt)
	print("CMD_A2C_WORLD_WAR_SIGNUP_REP", g_ww_mgr:signup_response(pkt))
end

Sv_commands[1][CMD_A2C_WORLD_WAR_REFRESH_REP] =
function(conn, char_id, pkt)
	print("CMD_A2C_WORLD_WAR_REFRESH_REP", g_ww_mgr:refresh_player_response(pkt))
end

Sv_commands[1][CMD_A2C_WORLD_WAR_SYNC_REP] =
function(conn, char_id, pkt)
	print("CMD_A2C_WORLD_WAR_SYNC_REP", g_ww_mgr:sync_response(pkt))
end

Sv_commands[1][CMD_A2C_WORLD_WAR_CHANGE_SYN] =
function(conn, char_id, pkt)
	print("CMD_A2C_WORLD_WAR_CHANGE_SYN", g_ww_mgr:change_sync(pkt))
end

-----------------------------------------------MAP----------------------------------------------

Sv_commands[0][CMD_M2C_WORLD_WAR_SIGNUP_REQ] =
function(conn, char_id, pkt)
	local response = {}
	response.result = g_ww_mgr:signup_request(pkt)
	g_svsock_mgr:send_server_ex(WORLD_ID, pkt.obj_id, CMD_MAP_WORLD_WAR_SIGNUP_S, response)
end

Sv_commands[0][CMD_M2C_WORLD_WAR_REFRESH_REQ] =
function(conn, char_id, pkt)
	local response = {}
	response.result = g_ww_mgr:refresh_player_request(pkt)
	g_svsock_mgr:send_server_ex(WORLD_ID, pkt.obj_id, CMD_MAP_WORLD_WAR_REFRESH_S, response)
end

Sv_commands[0][CMD_M2C_WORLD_WAR_ENTRY_REQ] =
function(conn, char_id, pkt)
	local response = g_ww_mgr:get_entry_info(pkt.obj_id)
	g_svsock_mgr:send_server_ex(WORLD_ID, pkt.obj_id, CMD_MAP_WORLD_WAR_ENTRY_S, response)
end

--[[
Sv_commands[0][CMD_M2C_WORLD_WAR_GET_LIST_REQ] =
function(conn, char_id, pkt)
	g_ww_mgr:all_team_sync(conn.id)
	g_ww_mgr:team_sort_sync(conn.id)
	g_ww_mgr:match_sort_sync(conn.id)
end
]]