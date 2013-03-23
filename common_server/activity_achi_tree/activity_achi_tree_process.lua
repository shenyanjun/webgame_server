
Sv_commands[0][CMD_M2C_SUBMIT_ACHI_REQ] =
function(conn,char_id,pkt)
	g_achi_tree_mgr:update_one_info(pkt)
end