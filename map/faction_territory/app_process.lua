

--打开面板
Clt_commands[1][CMD_B2M_APPLICATION_OPEN_C]=
function(conn,pkt)
	if conn.char_id == nil then return end
	g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id,CMD_M2P_APPLICATION_OPEN_C,{})
end

Sv_commands[0][CMD_P2M_APPLICATION_OPEN_S]=
function(conn,char_id,pkt)
	g_cltsock_mgr:send_client(char_id,CMD_M2B_APPLICATION_OPEN_S,pkt)
end

--报名
Clt_commands[1][CMD_B2M_APPLICATION_FILTER_C]=
function(conn,pkt)
	if conn.char_id == nil then return end
	local result = App_filter:is_application_ok(conn.char_id)
	if result ~= 0 then 
		return g_cltsock_mgr:send_client(conn.char_id,CMD_M2B_APPLICATION_FILTER_S,{['result'] = result}) 
	end

	local ret = App_filter:get_application_info(conn.char_id)
	g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id,CMD_M2P_APPLICATION_FILTER_C,ret)
end

Sv_commands[0][CMD_P2M_APPLICATION_FILTER_S]=
function(conn,char_id,pkt)
	g_cltsock_mgr:send_client(char_id,CMD_M2B_APPLICATION_FILTER_S,pkt)
end

--查看信息
Clt_commands[1][CMD_B2M_APPLICATION_INFO_C]=
function(conn,pkt)
	if conn.char_id == nil then return end
	g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id,CMD_M2P_APPLICATION_INFO_C,{})
end

Sv_commands[0][CMD_P2M_APPLICATION_INFO_S]=
function(conn,char_id,pkt)
	g_cltsock_mgr:send_client(char_id,CMD_M2B_APPLICATION_INFO_S ,pkt)
end

--同步信息
Sv_commands[0][CMD_P2M_APPLICATION_SYN_S]=
function(conn,char_id,pkt)
	App_filter:syn_info(pkt[1], pkt[2])
end

--战场开始通知报名者
Sv_commands[0][CMD_P2M_APPLICATION_WAR_S] =
function(conn, char_id, pkt)
	if f_is_pvp() or f_is_line_faction() or f_is_line_ww() then return end

	if pkt == nil then return end

	if pkt.type == 1 then
		App_filter:war_begin_bdc()
	end
end
