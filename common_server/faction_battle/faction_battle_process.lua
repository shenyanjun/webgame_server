


-- 收到map申请发出一个战书
Sv_commands[0][CMD_M2C_FACTION_BATTLE_APPLY_C] =
function(conn,char_id,pkt)
	--print("CMD_M2C_FACTION_BATTLE_APPLY_C", j_e(pkt))
	if char_id == nil or pkt.f_id == nil or pkt.s_time == nil or pkt.s_id == nil then return end
	local result = g_faction_battle_mgr:can_apply_battle(char_id, pkt.f_id, pkt.s_time)
	if result ~= 0 then 	
		g_server_mgr:send_to_server(conn.id, char_id, CMD_C2M_FACTION_BATTLE_APPLY_S, {["result"] = result})
		return
	end
	
	local f_id, l_id = g_faction_battle_mgr:build_battle_lettle(char_id, pkt.f_id, pkt.s_time, pkt.s_id, pkt.wager_type, pkt.wager)
	if f_id == nil or l_id == nil then 
		g_server_mgr:send_to_server(conn.id, char_id, CMD_C2M_FACTION_BATTLE_APPLY_S, {["result"] = 21072})
		return 
	end
	local new_pkt = {}
	new_pkt.result = 0
	new_pkt.wager_type = pkt.wager_type
	new_pkt.wager = pkt.wager
	new_pkt.list = g_faction_battle_mgr:get_battle_letter_info(f_id, l_id)

	g_server_mgr:send_to_server(conn.id, char_id, CMD_C2M_FACTION_BATTLE_APPLY_S, new_pkt)

	--g_faction_battle_mgr:debug_print()
end

-- 收到map申请应战一个战书
Sv_commands[0][CMD_M2C_FACTION_BATTLE_ACCEPT_C] =
function(conn,char_id,pkt)
	--print("CMD_M2C_FACTION_BATTLE_ACCEPT_C", j_e(pkt))
	
	if conn.char_id == nil or pkt.id == nil then return end
	local result = g_faction_battle_mgr:can_accept_letter(char_id, pkt.id)
	if result ~= 0 then 
		return g_server_mgr:send_to_server(conn.id, char_id, CMD_C2M_FACTION_BATTLE_ACCEPT_S, {["result"] = result})
	end
	
	local new_pkt = {}
	new_pkt.result, new_pkt.f_id = g_faction_battle_mgr:accept_letter(pkt.id, char_id)

	local b_l = g_faction_battle_mgr:get_battle_letter(pkt.id)
	if new_pkt.result == 0 and b_l ~= nil then
		new_pkt.wager_type = b_l.wager_type
		new_pkt.wager = b_l.wager
	end

	g_server_mgr:send_to_server(conn.id, char_id, CMD_C2M_FACTION_BATTLE_ACCEPT_S, new_pkt)
end

-- 收到map申请拒绝一个战书
Sv_commands[0][CMD_M2C_FACTION_BATTLE_REJECT_C] =
function(conn,char_id,pkt)
	--print("CMD_M2C_FACTION_BATTLE_REJECT_C", j_e(pkt))

	if conn.char_id == nil or pkt.id == nil then return end
	local result = g_faction_battle_mgr:can_reject_letter(char_id, pkt.id)
	if result ~= 0 then 
		return g_server_mgr:send_to_server(conn.id, char_id, CMD_C2M_FACTION_BATTLE_REJECT_S, {["result"] = result})
	end
	
	local new_pkt = {}
	new_pkt.result, new_pkt.f_id = g_faction_battle_mgr:reject_letter(pkt.id)

	g_server_mgr:send_to_server(conn.id, char_id, CMD_C2M_FACTION_BATTLE_REJECT_S, new_pkt)
end

-- 收到map申请取消一个战书
Sv_commands[0][CMD_M2C_FACTION_BATTLE_CANCEL_C] =
function(conn,char_id,pkt)
	--print("CMD_M2C_FACTION_BATTLE_CANCEL_C", j_e(pkt))
	
	if conn.char_id == nil then return end
	local result = g_faction_battle_mgr:can_cancel_letter(char_id, nil)
	if result ~= 0 then 
		return g_server_mgr:send_to_server(conn.id, char_id, CMD_C2M_FACTION_BATTLE_CANCEL_S, {["result"] = result})
	end
	
	local new_pkt = {}
	new_pkt.result, new_pkt.f_id = g_faction_battle_mgr:cancel_letter(char_id, nil)

	g_server_mgr:send_to_server(conn.id, char_id, CMD_C2M_FACTION_BATTLE_CANCEL_S, new_pkt)
end

-- 某场约战结束
Sv_commands[0][CMD_M2C_FACTION_BATTLE_OVER_C] =
function(conn,char_id,pkt)
	--print("CMD_M2C_FACTION_BATTLE_OVER_C", j_e(pkt))
	
	if conn.char_id == nil or pkt.win_side == nil or pkt.l_id == nil then return end
	g_faction_battle_mgr:achieve_faction_battle_over(pkt.l_id, pkt.win_side)

end