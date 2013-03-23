
--请求回归信息
Clt_commands[1][CMD_GET_REGRESSION_INFO_B] = 
function(conn, pkt)
	local s_pkt = {}

	local player = g_obj_mgr:get_obj(conn.char_id)
	if not player then return end

	local regression = player:get_regression()
	if not regression then return end

	local s_pkt = regression:get_regression_info()
	g_cltsock_mgr:send_client(conn.char_id, CMD_GET_REGRESSION_INFO_S, s_pkt)
	return
end

--领取副本补偿
Clt_commands[1][CMD_GET_REGRESSION_AUTHORIZE_B] = 
function(conn, pkt)
	local s_pkt = {}

	local player = g_obj_mgr:get_obj(conn.char_id)
	if not player then return end

	local regression = player:get_regression()
	if not regression then return end

	s_pkt.result = regression:get_authorize_reward(pkt)
	g_cltsock_mgr:send_client(conn.char_id, CMD_GET_REGRESSION_AUTHORIZE_S, s_pkt)
	if s_pkt.result == 0 then
		local tmp_pkt = regression:get_regression_info()
		g_cltsock_mgr:send_client(conn.char_id, CMD_GET_REGRESSION_INFO_S, tmp_pkt)
	end
	return
end

--领取活动补偿
Clt_commands[1][CMD_GET_REGRESSION_REWARD_B] = 
function(conn, pkt)
	if not pkt or not pkt.days or not pkt.type then return end
	local s_pkt = {}

	local player = g_obj_mgr:get_obj(conn.char_id)
	if not player then return end

	local regression = player:get_regression()
	if not regression then  return end

	s_pkt.result = regression:get_activity_reward(pkt)
	g_cltsock_mgr:send_client(conn.char_id, CMD_GET_REGRESSION_REWARD_S, s_pkt)
	if s_pkt.result == 0 then
		local tmp_pkt = regression:get_regression_info()
		g_cltsock_mgr:send_client(conn.char_id, CMD_GET_REGRESSION_INFO_S, tmp_pkt)
	end
	return
end

--[[--屏蔽回归拥抱
--回归拥抱
Clt_commands[1][CMD_REGRESSION_EMBRACE_B] = 
function(conn, pkt)
	if not pkt or not pkt.char_id then return end
	local player = g_obj_mgr:get_obj(conn.char_id)
	if not player then return end
	if player:get_level() < 35 then return end

	local t_pkt = {}
	t_pkt.char_id = conn.char_id
	t_pkt.embrace_id = pkt.char_id
	if t_pkt.char_id == t_pkt.embrace_id then return end

	g_svsock_mgr:send_server_ex(COMMON_ID,char_id, CMD_REGRESSION_EMBRACE_M, t_pkt)

	return
end

--成功拥抱,type:1被抱 2去拥抱
Sv_commands[0][CMD_REGRESSION_EMBRACE_C] = 
function(conn, char_id, pkt)
	if not pkt or not pkt.result or not pkt.char_id then return end
	local s_pkt = {}
	s_pkt.type = pkt.type

	if pkt.result == 0 then		--拥抱成功  加经验
		local player = g_obj_mgr:get_obj(pkt.char_id)
		if not player then return end
		local regression = player:get_regression()
		if not regression then  return end

		if pkt.type == 2 then
			s_pkt.result, s_pkt.exp = regression:get_embrace_exp()
		elseif pkt.type == 1 then
			s_pkt.result, s_pkt.exp = regression:get_embraced_exp()
		end
	else 
		s_pkt.result = pkt.result
	end
	g_cltsock_mgr:send_client(pkt.char_id, CMD_REGRESSION_EMBRACE_S, s_pkt)
end
]]

--不扣副本次数委托
Clt_commands[1][CMD_C2W_AUTHORIZE_ENTRUST_NOT_B] = 
function(conn, pkt)
	if not pkt or not pkt.count or not pkt.authorize_id then return end

	local s_pkt = {}

	local player = g_obj_mgr:get_obj(conn.char_id)
	if not player then return end

	local regression = player:get_regression()
	if not regression then  return end

	local e_code, s_pkt = regression:authorize_entrust(pkt)
	
	if e_code == 0 then
		pkt.type = 2
		g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id, CMD_C2W_AUTHORIZE_ENTRUST_M, pkt)

		s_pkt = regression:get_regression_info()
		g_cltsock_mgr:send_client(conn.char_id, CMD_GET_REGRESSION_INFO_S, s_pkt)
	else
		g_cltsock_mgr:send_client(conn.char_id, CMD_C2W_AUTHORIZE_ENTRUST_NOT_S, {['result'] = e_code})
	end
end