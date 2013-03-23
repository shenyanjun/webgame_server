--2011-10-26
--chenxidu
--婚姻系统公共服传送协议处理

----------------------处理COMM信息，并发送给web---------------------------

--发布征婚信息
Sv_commands[0][CMD_MARRY_SEND_C] = 
	function(conn, char_id, pkt)
		if not pkt then return end
		local player = g_obj_mgr:get_obj(conn.char_id)
		if not player then return end

		local t_pkt = {}
		t_pkt.result = pkt.result
		g_cltsock_mgr:send_client(char_id, CMD_MARRY_SEND_S, t_pkt)
	end

--请求和搜索列表信息
Sv_commands[0][CMD_MARRY_SEARCH_C] = 
	function(conn, char_id, pkt)
		if not pkt then return end
		g_cltsock_mgr:send_client(char_id, CMD_MARRY_SEARCH_S, pkt)
	end

--删除或者更新结婚信息
Sv_commands[0][CMD_MARRY_UPDATE_C] = 
	function(conn, char_id, pkt)
		if not pkt then return end
		local player = g_obj_mgr:get_obj(conn.char_id)
		if not player then return end
		g_cltsock_mgr:send_client(char_id, CMD_MARRY_UPDATE_S, pkt)
	end
