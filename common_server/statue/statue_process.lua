

--Ä¤°Ý
Sv_commands[0][CMD_M2C_WORSHIP_ACK] =
function(conn,char_id,pkt)
	local flag = pkt.type
	local statue_id = pkt.statue_id
	local statue = g_statue_mgr:get_statue(statue_id)
	if statue ~= nil then
		local new_pkt = {}
		new_pkt.result = statue:add_worship(char_id, flag)
		new_pkt.worship = statue:net_get_worship()
		
		g_server_mgr:send_to_server(conn.id, char_id, CMD_C2M_WORSHIP_REP, new_pkt)
		
		--¸üÐÂÄ¤°Ý
		new_pkt = {}
		new_pkt.id = pkt.statue_id
		new_pkt.worship_l = statue:net_get_worship()
		
		local s_pkt = Json.Encode(new_pkt)
		g_server_mgr:send_to_all_comm_map(0, CMD_C2M_UPDATE_WORSHIP_ACK, s_pkt, true)
		
		if new_pkt.result == 0 then
			local str = string.format("char_id: %d line: %d", char_id, conn.id)
			g_statue_log:write(str)
		end
	end
end

--Ç©Ãû
Sv_commands[0][CMD_M2C_AUTOGRAPH_ACK] =
function(conn,char_id,pkt)
	local statue = g_statue_mgr:get_statue(pkt.statue_id)
	statue:set_autograph(pkt.content)
	
	local new_pkt = {}
	new_pkt.id = pkt.statue_id
	new_pkt.content = statue:get_autograph()
	local s_pkt = Json.Encode(new_pkt)
	g_server_mgr:send_to_all_comm_map(0, CMD_C2M_AUTOGRAPH_REP, s_pkt, true)
end


