

-- 完成某个成就
Sv_commands[0][CMD_M2C_SET_ACHI_DONE] =
function(conn,char_id,pkt)
	--print("CMD_M2C_SET_ACHI_DONE")

	local new_pkt = {}
	new_pkt.achi_id = g_global_achi_mgr:set_achi_done(pkt)
	if new_pkt.achi_id then
		g_server_mgr:send_to_server(conn.id, char_id, CMD_C2M_GLOBAL_ACHI_SYNC, new_pkt)
	end
end