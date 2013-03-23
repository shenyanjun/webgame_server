



Clt_commands[1][CMD_MAP_GET_ONLINE_FUNCTION_C] = 
function(conn,pkt)
	if not conn and not conn.char_id then return end
	g_online_reward:login(conn.char_id)
end

