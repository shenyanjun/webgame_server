

local level_limit = 34

--拿题目
Clt_commands[1][CMD_MAP_GET_SUBJECT_C]=
function(conn,pkt)
	if not conn.char_id then return end
	local player = g_obj_mgr:get_obj(conn.char_id)
	if player:get_level() < level_limit then 
		local ret = {}
		ret.result = 20751
		g_cltsock_mgr:send_client(conn.char_id,CMD_MAP_GET_SUBJECT_S,ret)
		return
	end		
	g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id,CMD_M2C_ANSWER_GET_SUBJECT_C,pkt)
end



Sv_commands[0][CMD_C2M_ANSWER_GET_SUBJECT_S]=
function(conn,char_id,pkt)
	g_cltsock_mgr:send_client(char_id,CMD_MAP_GET_SUBJECT_S,pkt)
end



--获取面板信息
Clt_commands[1][CMD_MAP_GET_SUBJECT_INFO_C] = 
function(conn,pkt)
	if not conn.char_id then return end

	local player = g_obj_mgr:get_obj(conn.char_id)
	if player:get_level() < level_limit then 
		local ret = {}
		ret.result = 20751
		g_cltsock_mgr:send_client(conn.char_id,CMD_MAP_GET_SUBJECT_INFO_S,ret)
		return
	end	
	g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id,CMD_M2C_ANSWER_GET_SUBJECT_INFO_C,pkt)
end



Sv_commands[0][CMD_C2M_ANSWER_GET_SUBJECT_INFO_S] = 
function(conn,char_id,pkt)
	g_cltsock_mgr:send_client(char_id,CMD_MAP_GET_SUBJECT_INFO_S,pkt)
end



--使用道具
Clt_commands[1][CMD_MAP_USE_VIP_PROPS_C] = 
function(conn,pkt)
	if not conn.char_id then return end
	local player = g_obj_mgr:get_obj(conn.char_id)
	if player:get_level()< level_limit then 
		local ret = {}
		ret.result = 20751
		g_cltsock_mgr:send_client(conn.char_id,CMD_MAP_USE_VIP_PROPS_S,ret)
		return
	end	
	g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id,CMD_M2C_ANSWER_USE_PROPS_C,pkt)
end



Sv_commands[0][CMD_C2M_ANSWER_USE_PROPS_S] = 
function(conn,char_id,pkt)
	g_cltsock_mgr:send_client(char_id,CMD_MAP_USE_VIP_PROPS_S,pkt)
end



--提交题目
Clt_commands[1][CMD_MAP_SUBMIT_SUBJECT_C] = 
function(conn,pkt)
	if not conn.char_id then return end
	local player = g_obj_mgr:get_obj(conn.char_id)
	if player:get_level()< level_limit then 
		local ret = {}
		ret.result = 20751
		g_cltsock_mgr:send_client(conn.char_id,CMD_MAP_SUBMIT_SUBJECT_S,ret)
		return
	end	
	g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id,CMD_M2C_ANSWER_SUBMIT_SUBJECT_C,pkt)
end



Sv_commands[0][CMD_C2M_ANSWER_SUBMIT_SUBJECT_S] = 
function(conn,char_id,pkt)
	g_cltsock_mgr:send_client(char_id,CMD_MAP_SUBMIT_SUBJECT_S,pkt)
end



--排行
Clt_commands[1][CMD_MAP_ANSWER_SORT_C] = 
function(conn,pkt)
	if not conn.char_id then return end
	g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id,CMD_M2C_ANSWER_SORT_C,pkt)
end



Sv_commands[0][CMD_C2M_ANSWER_SORT_S] = 
function(conn,char_id,pkt)
	g_cltsock_mgr:send_client(char_id,CMD_MAP_ANSWER_SORT_S,pkt)
end



--关闭面板
Clt_commands[1][CMD_MAP_ANSWER_CLOSE_C] = 
function(conn,pkt)
	if not conn.char_id then return end
	g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id,CMD_M2C_CLOSE_C,pkt)
end	

--弹出窗口
Sv_commands[0][CMD_M2C_ANSWER_SEND_WINDOW_S] = 
function(conn,char_id,pkt)
	if not conn.char_id then return end
	local pkt = {}
	g_cltsock_mgr:send_client(char_id, CMD_M2C_ANSWER_SEND_WINDOW_S, pkt)
end
