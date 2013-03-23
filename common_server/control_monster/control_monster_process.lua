
-----------------------------------降妖记录-----------------------------

--贵重物品记录广播
Sv_commands[0][CMD_C2W_CONTROLMONSTER_RECORD_M] =
function(conn,char_id,pkt)
	if char_id ~= nil and pkt and pkt.name and pkt.id and pkt.item then
		g_control_monster:record_and_broadcast(pkt)
	end
	return
end

--贵重物品记录广播
Sv_commands[0][CMD_C2W_ALL_MONSTER_RECORD_M] =
function(conn,char_id,pkt)
	if char_id then
		local pkt = g_control_monster:send_all_record() or {}
		g_server_mgr:send_to_server(conn.id, char_id, CMD_C2W_ALL_MONSTER_RECORD_C, pkt)
	end
	return
end
