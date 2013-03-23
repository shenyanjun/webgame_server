




Sv_commands[0][CMD_C2M_TREASURE_BROADCAST_C]=
function(conn,char_id,pkt)
	g_cltsock_mgr:send_client(char_id,CMD_PUZZLE_MAP_BROADCAST_S,pkt)
end


