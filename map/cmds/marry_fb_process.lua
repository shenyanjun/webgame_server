--2011-10-26
--chenxidu
--婚姻系统客户端传送协议处理，并发送到公共服

--发布征婚信息
Clt_commands[1][CMD_MARRY_SEND_B] = 
	function(conn, pkt)
		if not pkt then return end
		if g_marry_mgr:is_send(conn.char_id) == false then
			local pkt_new = {}
			pkt_new.char_id = conn.char_id
			local player = g_obj_mgr:get_obj(conn.char_id)
			if player then 
				pkt_new.tz  = player:get_fighting()
			else
				pkt_new.tz  = 0
			end
			pkt_new.ts = pkt.m_s
			g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id, CMD_MARRY_SEND_M, pkt_new)
		else
			local t_pkt = {}
			t_pkt.result = 22480
			g_cltsock_mgr:send_client(conn.char_id, CMD_MARRY_SEND_S, t_pkt)
		end

	end

--请求列表信息
Clt_commands[1][CMD_MARRY_SEARCH_B] = 
	function(conn, pkt)
		if not pkt then return end
		local player = g_obj_mgr:get_obj(conn.char_id)
		if not player then return end
		g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id, CMD_MARRY_SEARCH_M, pkt)
	end

--删除或者更新结婚信息
Clt_commands[1][CMD_MARRY_UPDATE_B] = 
	function(conn, pkt)
		if not pkt then return end
		local player = g_obj_mgr:get_obj(conn.char_id)
		if not player then return end
		local pkt_new = {}
		if pkt.type == 0 then
			pkt_new.type = 0
			pkt_new.char_id = conn.char_id
			local player = g_obj_mgr:get_obj(conn.char_id)
			if player then 
				pkt_new.tz  = player:get_fighting()
			else
				pkt_new.tz  = 0
			end
			pkt_new.ts = pkt.m_s
			g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id, CMD_MARRY_UPDATE_M, pkt_new)
		else
			g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id, CMD_MARRY_UPDATE_M, pkt)
		end
	end


