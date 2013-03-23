
--询问是否有雕像
Clt_commands[1][CMD_COLLECTION_ACTIVITY_BASE_B] = 
function(conn, pkt)
	if not g_activity_reward_mgr:get_swicth() then
		return
	end
	local s_pkt = {}
	s_pkt.id = g_activity_reward_mgr:get_id() or 0
	s_pkt.lvl = g_activity_reward_mgr:get_lvl() or 0

	g_cltsock_mgr:send_client(conn.char_id, CMD_COLLECTION_ACTIVITY_BASE_C, s_pkt)
	return
end

--打开基本界面
Clt_commands[1][CMD_COLLECTION_ACTIVITY_OPEN_BASE_B] = 
function(conn, pkt)
	if not g_activity_reward_mgr:get_swicth() then
		return
	end
	if not pkt then return end

	local player = g_obj_mgr:get_obj(conn.char_id)
	if not player then return end
	if player:get_level() < 40 then return end

	if not  g_activity_reward_mgr:get_id() then 
		return 
	end
	g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id, CMD_COLLECTION_ACTIVITY_OPEN_BASE_M, pkt)
	
	return
end

--实物捐赠
Clt_commands[1][CMD_COLLECTION_ACTIVITY_DONATE_B] = 
function(conn, pkt)
	if not g_activity_reward_mgr:get_swicth() then
		return
	end
	if not pkt or not pkt.id or not pkt.cnt then return end
	pkt.id = tonumber(pkt.id)

	local s_pkt = {}

	local player = g_obj_mgr:get_obj(conn.char_id)
	if not player then return end
	if player:get_level() < 40 then return end
	local ar_con = player:get_ar_con()
	if not ar_con then return end

	s_pkt.result = ar_con:donate_real(pkt.id, pkt.cnt)
	g_cltsock_mgr:send_client(conn.char_id, CMD_COLLECTION_ACTIVITY_DONATE_S, s_pkt)
	
	if s_pkt.result == 0 then
		g_svsock_mgr:send_server_ex(COMMON_ID, conn.char_id, CMD_COLLECTION_ACTIVITY_OPEN_BASE_M, pkt)
	end

	return
end

--灵气捐赠
Clt_commands[1][CMD_COLLECTION_ACTIVITY_DONATE_FREE_B] = 
function(conn, pkt)
	if not g_activity_reward_mgr:get_swicth() then
		return
	end
	if not pkt or not pkt.id then return end
	pkt.id = tonumber(pkt.id)

	local s_pkt = {}

	local player = g_obj_mgr:get_obj(conn.char_id)
	if not player then return end
	if player:get_level() < 40 then return end
	local ar_con = player:get_ar_con()
	if not ar_con then return end

	s_pkt.result = ar_con:donate_anima(pkt.id)
	g_cltsock_mgr:send_client(conn.char_id, CMD_COLLECTION_ACTIVITY_DONATE_FREE_S, s_pkt)
	
	if s_pkt.result == 0 then
		g_svsock_mgr:send_server_ex(COMMON_ID, conn.char_id, CMD_COLLECTION_ACTIVITY_OPEN_BASE_M, pkt)
	end

	return
end

--打开仙缘榜
Clt_commands[1][CMD_COLLECTION_ACTIVITY_OPEN_RECORD_B] = 
function(conn, pkt)
	if not g_activity_reward_mgr:get_swicth() then
		return
	end
	if not pkt then return end
	
	g_svsock_mgr:send_server_ex(COMMON_ID, conn.char_id, CMD_COLLECTION_ACTIVITY_GET_EXP_M, pkt)

end

--打开奖励面板
Clt_commands[1][CMD_COLLECTION_ACTIVITY_OPEN_REWARD_B] = 
function(conn, pkt)
	if not g_activity_reward_mgr:get_swicth() then
		return
	end
	if not pkt then return end

	local s_pkt = {}

	local player = g_obj_mgr:get_obj(conn.char_id)
	if not player then return end
	if player:get_level() < 40 then return end
	local ar_con = player:get_ar_con()
	if not ar_con then return end

	s_pkt = ar_con:get_player_reward_info()
	g_cltsock_mgr:send_client(conn.char_id, CMD_COLLECTION_ACTIVITY_OPEN_REWARD_S, s_pkt)
	
	return
end

--领取奖励
Clt_commands[1][CMD_COLLECTION_ACTIVITY_GET_REWARD_B] = 
function(conn, pkt)
	if not g_activity_reward_mgr:get_swicth() then
		return
	end
	if not pkt or not pkt.type then return end
	if pkt.type ==1 or (pkt.type == 2 and pkt.buf_id and pkt.time) then 

		local s_pkt = {}

		local player = g_obj_mgr:get_obj(conn.char_id)
		if not player then return end
		if player:get_level() < 40 then return end
		local ar_con = player:get_ar_con()
		if not ar_con then return end
		
		s_pkt.result = ar_con:get_player_reward(pkt)

		g_cltsock_mgr:send_client(conn.char_id, CMD_COLLECTION_ACTIVITY_GET_REWARD_S, s_pkt)
		
		if s_pkt.result == 0 then
			local t_pkt = ar_con:get_player_reward_info()
			g_cltsock_mgr:send_client(conn.char_id, CMD_COLLECTION_ACTIVITY_OPEN_REWARD_S, t_pkt)
		end

	end
end


-----------------公共服返回
--打开基本界面
Sv_commands[0][CMD_COLLECTION_ACTIVITY_OPEN_BASE_C] = 
	function(conn, char_id, pkt)
		if not g_activity_reward_mgr:get_swicth() then
			return
		end
		if char_id == nil then return end
		if not pkt then return end
		local player = g_obj_mgr:get_obj(char_id)
		if not player then return end
		local ar_con = player:get_ar_con()
		if not ar_con then return end

		pkt.id = g_activity_reward_mgr:get_id()
		pkt.lvl = g_activity_reward_mgr:get_lvl()
		pkt.result = 0
		pkt.donate = ar_con:get_donate_info()
		pkt.end_t = g_activity_reward_mgr:get_end_time()

		print("174 ~~~~~~~~ = ", j_e(pkt))
		g_cltsock_mgr:send_client(char_id, CMD_COLLECTION_ACTIVITY_OPEN_BASE_S, pkt)
	end

--获取公共服贵重物品列表
Sv_commands[0][CMD_COLLECTION_ACTIVITY_GET_EXP_C] = 
	function(conn, char_id, pkt)
		if not g_activity_reward_mgr:get_swicth() then
			return
		end
		if char_id == nil then return end
		if not pkt then return end

		local s_pkt = {}
		s_pkt.list = pkt
		s_pkt.result = 0

		g_cltsock_mgr:send_client(char_id, CMD_COLLECTION_ACTIVITY_OPEN_RECORD_S, s_pkt)
	end