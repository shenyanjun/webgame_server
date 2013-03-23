--2011-10-26
--chenxidu
--婚姻系统通讯

---------------------------------与map交互---------------------

--玩家请求列表
Sv_commands[0][CMD_MARRY_SEARCH_M] =
function(conn,char_id,pkt)
	if not char_id then return end
	local s_pkt = g_marry:get_marry_list() or {}
	g_server_mgr:send_to_server(conn.id,char_id, CMD_MARRY_SEARCH_C, s_pkt)
	return
end


--发布征婚信息（个人征婚信息）
Sv_commands[0][CMD_MARRY_SEND_M] =
function(conn,char_id,pkt)
	if pkt==nil then return end
	if char_id ~= nil then
		local s_pkt = {}
		if g_marry:insert_send_db(char_id,pkt) == true then
			local pkt_new = {}
			pkt_new.result = 0 
			g_server_mgr:send_to_server(conn.id,char_id, CMD_MARRY_SEND_C,pkt_new)

			--发送最新的征婚列表给客户端
			local s_pkt = g_marry:get_marry_list() or {}
			g_server_mgr:send_to_server(conn.id,char_id, CMD_MARRY_SEARCH_C,s_pkt)
			return
		end
	end
end

--更新自己征婚信息
Sv_commands[0][CMD_MARRY_UPDATE_M] =
function(conn,char_id,pkt)
	if char_id ~= nil then	
		if g_marry:is_can_update(char_id,pkt) == true then	
			local s_pkt = {}
			s_pkt.result = 0 
			s_pkt.type   = pkt.type
			g_server_mgr:send_to_server(conn.id,char_id, CMD_MARRY_UPDATE_C,s_pkt)	

			--发布最新的征婚列表给客户端
			local s_pkt = g_marry:get_marry_list() or {}
			g_server_mgr:send_to_server(conn.id,char_id, CMD_MARRY_SEARCH_C,s_pkt)
		else
			local s_pkt = {}
			s_pkt.result = 22481   
			g_server_mgr:send_to_server(conn.id,char_id, CMD_MARRY_UPDATE_C,s_pkt)	
		end
	end
	return
end

--MAP创建婚姻
Sv_commands[0][CMD_M2P_MARRY_CREATE_REQ] =
function(conn,char_id,pkt)
	--在公共服还要做一次询问
	if g_marry:is_marry(char_id,pkt.mate_id) == false then
		--通知结婚的队长(类似弹出通知形式)
		if g_marry:create_marry(pkt) == true then
			local pk = {}
			pk.char_id = pkt.char_id
			pk.mate_id = pkt.mate_id
			pk.money   = pkt.money
			pk.result  = 0 
			g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_MARRY_CREATE_REP,pk)
		else
			local pk = {}
			pk.char_id = pkt.char_id
			pk.mate_id = pkt.mate_id
			pk.money = pkt.m_m
			pk.result  = 22482 
			g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_MARRY_CREATE_REP,pk)
		end
	else 
		local pk = {}
		pk.char_id = pkt.char_id
		pk.mate_id = pkt.mate_id
		pk.result  = 22482 
		g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_MARRY_CREATE_REP,pk)
	end
end

--接受聊天服的好友列表
Sv_commands[1][CMD_C2W_GET_FRIEND_LIST_S] = 
function (conn, char_id, pkt)
	if pkt == nil then return end
	g_marry:get_friend_list(pkt)
end

--接受map过来的同步信息
Sv_commands[0][CMD_M2P_MARRY_INFO] = 
function (conn, char_id, pkt)
	if pkt == nil then return end
	g_marry:receive_map_list(conn.id,char_id,pkt)
end

--接受map过来的广播信息
Sv_commands[0][CMD_M2P_MARRY_BROADCAST] = 
function (conn, char_id, pkt)
	if pkt == nil then return end
	--世界广播
	local pkts = Json.Encode(pkt)
	for k , v in pairs(g_player_mgr.online_player_l) do
		g_svsock_mgr:send_server_ex(WORLD_ID, k, CMD_C2W_NOTICE_MARRY_S, pkts, true)
	end
end

Sv_commands[0][CMD_P2M_BREAK_MARRY_EX_REQ] = 
function (conn, char_id, pkt)
	if pkt == nil then return end
	--离婚询问
	g_marry:break_marry_quest(pkt)
end

--另一方答应
Sv_commands[0][CMD_P2M_BREAK_MARRY_EN_REQ] = 
function (conn, char_id, pkt)
	if pkt == nil then return end
	--离婚询问
	g_marry:break_marry_answer(pkt)
end


