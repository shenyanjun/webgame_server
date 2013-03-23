
Sv_commands[0][CMD_M2C_UPDATE_RANK_INFO_REQ] =
function(conn,char_id,pkt)
	g_activity_rank_mgr:update_rank_info(pkt)
end

Sv_commands[0][CMD_M2C_GET_ACTIVITY_RANK_DATA] =
function(conn,char_id,pkt)
	g_activity_rank_mgr:syn_map_rank_data(conn.id)
end