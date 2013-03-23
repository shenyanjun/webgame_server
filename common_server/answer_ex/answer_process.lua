


--发题目
Sv_commands[0][CMD_M2C_ANSWER_GET_SUBJECT_C] = 
function(conn,char_id,pkt)
	g_answer_mgr:get_question(conn.id,char_id)
end



--获取面板信息
Sv_commands[0][CMD_M2C_ANSWER_GET_SUBJECT_INFO_C] = 
function(conn,char_id,pkt)
	local ret = {}
	ret = g_answer_mgr:get_all_info(char_id)
	g_server_mgr:send_to_server(conn.id,char_id,CMD_C2M_ANSWER_GET_SUBJECT_INFO_S,ret)
end



--使用道具
Sv_commands[0][CMD_M2C_ANSWER_USE_PROPS_C] = 
function(conn,char_id,pkt)
	local ret = {}
	ret = g_answer_mgr:use_vip_props(char_id,pkt)
	g_server_mgr:send_to_server(conn.id,char_id,CMD_C2M_ANSWER_USE_PROPS_S,ret)
end



--提交题目
Sv_commands[0][CMD_M2C_ANSWER_SUBMIT_SUBJECT_C] = 
function(conn, char_id, pkt)
	local ret = g_answer_mgr:submit_question(char_id, pkt)
	if not ret then return end
	g_server_mgr:send_to_server(conn.id,char_id,CMD_C2M_ANSWER_SUBMIT_SUBJECT_S,ret)
end



--排行
Sv_commands[0][CMD_M2C_ANSWER_SORT_C] = 
function(conn, char_id, pkt)
	local ret ={}
	ret = g_answer_mgr:get_ranklist()
	g_server_mgr:send_to_server(conn.id,char_id,CMD_C2M_ANSWER_SORT_S,ret)
end


--关闭答题
Sv_commands[0][CMD_M2C_CLOSE_C] = 
function(conn, char_id, pkt)
	g_answer_mgr:close_panel(char_id)
end
