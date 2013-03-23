

--渡劫 
Clt_commands[1][CMD_KALPA_C]=
function(conn,pkt)
	if conn.char_id == nil or pkt.size == nil then return end
	
	local ret = g_kalpa_mgr:kalpa(conn.char_id, pkt.size, pkt.slot)
	--print("kalpa:", ret)
	local new_pkt = {}
	new_pkt.result = ret
	if new_pkt.result == 0 then
		new_pkt.attr = g_kalpa_mgr:get_kalpa_attr(conn.char_id)
		new_pkt.name = g_kalpa_mgr:get_kalpa_name(conn.char_id)
	else
		new_pkt.attr = {}
		new_pkt.name = ""
	end
	g_cltsock_mgr:send_client(conn.char_id, CMD_KALPA_S, new_pkt)
end

--打开面板 
Clt_commands[1][CMD_OPEN_KALPA_C]=
function(conn,pkt)
	if conn.char_id == nil then return end
	
	local new_pkt = g_kalpa_mgr:open_kalpa(conn.char_id)
	if new_pkt ~= nil then
		g_cltsock_mgr:send_client(conn.char_id, CMD_OPEN_KALPA_S, new_pkt)
	end
end

--祈天(刷新基本概率)
Clt_commands[1][CMD_KALPA_REFRESH_C]=
function(conn,pkt)
	if conn.char_id == nil then return end

	local code, new_pkt = g_kalpa_mgr:refresh_kalpa(conn.char_id, pkt.type)
	if code == 0 then
		g_cltsock_mgr:send_client(conn.char_id, CMD_KALPA_REFRESH_S, new_pkt)
	end
end

--判断能否渡劫
Clt_commands[1][CMD_KALPA_TEST_C]=
function(conn,pkt)
	if conn.char_id == nil or pkt.size == nil then return end
	
	local ret = g_kalpa_mgr:can_kalpa(conn.char_id, pkt.size, pkt.slot)

	local new_pkt = {}
	new_pkt.result = ret
	new_pkt.size = pkt.size
	new_pkt.slot = pkt.slot
	g_cltsock_mgr:send_client(conn.char_id, CMD_KALPA_TEST_S, new_pkt)
end

--消除渡劫冷劫时间
Clt_commands[1][CMD_KALPA_RESET_CD_C]=
function(conn,pkt)
	if conn.char_id == nil then return end
	
	local ret = g_kalpa_mgr:reset_cd_time(conn.char_id)
	local new_pkt = {}
	new_pkt.result = ret
	g_cltsock_mgr:send_client(conn.char_id, CMD_KALPA_RESET_CD_S, new_pkt)
end

--取得渡劫等级
Clt_commands[1][CMD_KALPA_GET_LEVEL_C]=
function(conn,pkt)
	if conn.char_id == nil then return end

	local new_pkt = {}
	new_pkt.level, new_pkt.max_level = g_kalpa_mgr:get_kalpa_level(conn.char_id)
	g_cltsock_mgr:send_client(conn.char_id, CMD_KALPA_GET_LEVEL_S, new_pkt)
end