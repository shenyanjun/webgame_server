



--玩家进入场景
Sv_commands[0][CMD_M2C_IDENTIFY_PLAYER_ENTER_C] = 
function(conn, char_id, pkt)
	if not char_id or not pkt.map_id then
		print("error:CMD_M2C_IDENTIFY_PLAYER_ENTER")
		return 
	end
	g_identify_mgr:enter(char_id,pkt.map_id)
end

--玩家离开场景
Sv_commands[0][CMD_M2C_IDENTIFY_PLAYER_LEAVE_C] = 
function(conn, char_id, pkt)
	if not char_id or not pkt then
		print("error:CMD_M2C_IDENTIFY_PLAYER_LEAVE_C")
		return 
	end
	g_identify_mgr:leave(char_id, pkt.map_id)
end

--玩家验证
Sv_commands[0][CMD_M2C_IDENTIFY_AUTH_C] = 
function(conn, char_id, pkt)
	if not char_id or not pkt then
		print("error:CMD_M2C_IDENTIFY_PLAYER_ENTER")
		return 
	end
	g_identify_mgr:authorize(char_id,pkt.map_id,pkt.answer)
end

--刷新
Sv_commands[0][CMD_M2C_IDENTIFY_REFRESH_C] = 
function(conn, char_id, pkt)
	if not char_id or not pkt then
		print("error:CMD_M2C_IDENTIFY_PLAYER_ENTER")
		return 
	end
	g_identify_mgr:refresh(char_id,pkt.map_id)
end