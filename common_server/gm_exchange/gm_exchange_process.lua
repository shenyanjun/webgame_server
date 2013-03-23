


--获取列表
Sv_commands[0][CMD_M2C_GM_EXC_GET_LIST_REQ] = 
function(conn,char_id,pkt)
	if not conn.id or not char_id or not pkt then print("-------------------") return end
	g_exchange_mgr:serialize_to_net(conn.id,char_id,pkt)
end


--兑换
Sv_commands[0][CMD_M2C_GM_EXC_ITEM_REQ] = 
function(conn,char_id,pkt)
	if not conn.id or not char_id or not pkt then print("================") return end
	g_exchange_mgr:exchange_item(conn.id,char_id,pkt)
end
