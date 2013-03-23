

--打开约战面版	
Clt_commands[1][CMD_FACTION_BATTLE_OPEN_PANEL_C] =
function(conn,pkt)
	if conn.char_id == nil then return end
	local new_pkt = g_faction_battle_mgr:get_all_battle_info(conn.char_id)

	g_cltsock_mgr:send_client(conn.char_id, CMD_FACTION_BATTLE_OPEN_PANEL_S, new_pkt) 
end

--取我帮的战书	
Clt_commands[1][CMD_FACTION_BATTLE_GET_ALL_LETTERS_C] =
function(conn,pkt)
	if conn.char_id == nil then return end
	local new_pkt = g_faction_battle_mgr:get_our_battle_info(conn.char_id)

	g_cltsock_mgr:send_client(conn.char_id, CMD_FACTION_BATTLE_GET_ALL_LETTERS_S, new_pkt) 
end

--发出一个战书
Clt_commands[1][CMD_FACTION_BATTLE_APPLY_C] =
function(conn,pkt)
	--print("CMD_FACTION_BATTLE_APPLY_C", j_e(pkt))
	
	if conn.char_id == nil or pkt.f_id == nil or pkt.s_time == nil or FACTION_BATTLE_SCENE_ID_LIST[pkt.s_id] == nil then return end
	local os_time_h = tonumber(os.date("%H"))
	local os_time_m = tonumber(os.date("%M"))
	local time = f_faction_battle_t2n(pkt.s_time[1], pkt.s_time[2])
	local result = 0
	if time == nil or pkt.s_time[1] * 60 + pkt.s_time[2] < os_time_h * 60 + os_time_m + FACTION_BATTLE_EARLIER_TIME_M then
		result = 21080
	else
		result = g_faction_battle_mgr:can_apply_battle(conn.char_id, pkt.f_id, time, pkt.wager_type, pkt.wager)
	end
	if result ~= 0 then 
		if result ~= -1 then
			g_cltsock_mgr:send_client(conn.char_id,CMD_FACTION_BATTLE_APPLY_S, {['result'] = result})
		end
		return
	end

	pkt.s_time = time
	g_svsock_mgr:send_server_ex(COMMON_ID, conn.char_id, CMD_M2C_FACTION_BATTLE_APPLY_C, pkt)
end

--应战一个战书
Clt_commands[1][CMD_FACTION_BATTLE_ACCEPT_LETTER_C] =
function(conn,pkt)
	--print("CMD_FACTION_BATTLE_ACCEPT_LETTER_C", j_e(pkt))
	
	if conn.char_id == nil or pkt.id == nil then return end
	local result = g_faction_battle_mgr:can_accept_letter(conn.char_id, pkt.id)
	if result ~= 0 then 
		if result ~= -1 then
			g_cltsock_mgr:send_client(conn.char_id, CMD_FACTION_BATTLE_ACCEPT_LETTER_S, {['result'] = result}) 
		end
		return
	end

	g_svsock_mgr:send_server_ex(COMMON_ID, conn.char_id, CMD_M2C_FACTION_BATTLE_ACCEPT_C, pkt)
end

--拒绝一个战书
Clt_commands[1][CMD_FACTION_BATTLE_REJECT_LETTER_C] =
function(conn,pkt)
	--print("CMD_FACTION_BATTLE_REJECT_LETTER_C", j_e(pkt))
	
	if conn.char_id == nil or pkt.id == nil then return end
	local result = g_faction_battle_mgr:can_reject_letter(conn.char_id, pkt.id)
	if result ~= 0 then 
		return g_cltsock_mgr:send_client(conn.char_id, CMD_FACTION_BATTLE_REJECT_LETTER_S, {['result'] = result}) 
	end

	g_svsock_mgr:send_server_ex(COMMON_ID, conn.char_id, CMD_M2C_FACTION_BATTLE_REJECT_C, pkt)
end


--取消我帮发出的战书
Clt_commands[1][CMD_FACTION_BATTLE_CANCEL_LETTER_C] =
function(conn,pkt)
	--print("CMD_FACTION_BATTLE_CANCEL_LETTER_C", j_e(pkt))

	if conn.char_id == nil then return end
	local result = g_faction_battle_mgr:can_cancel_letter(conn.char_id, nil)
	if result ~= 0 then 
		return g_cltsock_mgr:send_client(conn.char_id, CMD_FACTION_BATTLE_CANCEL_LETTER_S, {['result'] = result}) 
	end

	g_svsock_mgr:send_server_ex(COMMON_ID, conn.char_id, CMD_M2C_FACTION_BATTLE_CANCEL_C, pkt)
end

-- 取某时段剩余场次
Clt_commands[1][CMD_FACTION_BATTLE_GET_REMAINDER_TIMES_C] =
function(conn,pkt)
	if conn.char_id == nil or pkt.time == nil then return end

	local time_s = f_faction_battle_t2n(pkt.time[1], pkt.time[2])
	if time_s == nil then return end
	local new_pkt = {}
	new_pkt.times = g_faction_battle_mgr:get_remainder_times(time_s)
	g_cltsock_mgr:send_client(conn.char_id, CMD_FACTION_BATTLE_GET_REMAINDER_TIMES_S, new_pkt)
end


------------------ 公共服通讯

--公共服发过来的申请回复包
Sv_commands[0][CMD_C2M_FACTION_BATTLE_APPLY_S]=
function(conn,char_id,pkt)
	--print("CMD_C2M_FACTION_BATTLE_APPLY_S", j_e(pkt))
	if pkt.result == 0 then
		local wager_type = pkt.wager_type
		local wager = pkt.wager
		local obj = g_obj_mgr:get_obj(char_id)
		if wager_type == 1 then
			local pack_con = obj:get_pack_con()
			pack_con:dec_money(MoneyType.JADE, wager, {['type']=MONEY_SOURCE.FACTION_BATTLE})

		elseif wager_type == 2 then
			local pack_con = obj:get_pack_con()
			pack_con:dec_money(MoneyType.GOLD, wager, {['type']=MONEY_SOURCE.FACTION_BATTLE})
		end
	end

	g_cltsock_mgr:send_client(char_id, CMD_FACTION_BATTLE_APPLY_S, pkt)
	--print("send:", j_e(pkt))

end

--公共服发过来的应战回复包
Sv_commands[0][CMD_C2M_FACTION_BATTLE_ACCEPT_S]=
function(conn,char_id,pkt)
	--print("CMD_C2M_FACTION_BATTLE_ACCEPT_S", j_e(pkt))
	if pkt.result == 0 then
		local wager_type = pkt.wager_type
		local wager = pkt.wager
		local obj = g_obj_mgr:get_obj(char_id)
		if wager_type == 1 then
			local pack_con = obj:get_pack_con()
			pack_con:dec_money(MoneyType.JADE, wager, {['type']=MONEY_SOURCE.FACTION_BATTLE})

		elseif wager_type == 2 then
			local pack_con = obj:get_pack_con()
			pack_con:dec_money(MoneyType.GOLD, wager, {['type']=MONEY_SOURCE.FACTION_BATTLE})
		end
	end
	g_cltsock_mgr:send_client(char_id, CMD_FACTION_BATTLE_ACCEPT_LETTER_S, pkt)
	--print("send:", j_e(pkt))

end

--公共服发过来的拒绝战书的回复包
Sv_commands[0][CMD_C2M_FACTION_BATTLE_REJECT_S]=
function(conn,char_id,pkt)
	--print("CMD_C2M_FACTION_BATTLE_REJECT_S", j_e(pkt))
	
	g_cltsock_mgr:send_client(char_id, CMD_FACTION_BATTLE_REJECT_LETTER_S, pkt)
	--print("send:", j_e(pkt))

end

--公共服发过来的取消战书的回复包
Sv_commands[0][CMD_C2M_FACTION_BATTLE_CANCEL_S]=
function(conn,char_id,pkt)
	--print("CMD_C2M_FACTION_BATTLE_CANCEL_S", j_e(pkt))
	
	g_cltsock_mgr:send_client(char_id, CMD_FACTION_BATTLE_CANCEL_LETTER_S, pkt)
	--print("send:", j_e(pkt))

end

--公共服发过来的同步包
Sv_commands[0][CMD_C2M_FACTION_BATTLE_SYN_S]=
function(conn,char_id,pkt)
	--print("CMD_C2M_FACTION_BATTLE_SYN_S", j_e(pkt))
	
	g_faction_battle_mgr:set_syn_info(pkt)

	--g_faction_battle_mgr:debug_print()
end