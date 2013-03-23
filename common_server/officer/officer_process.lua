--2012-4-24
--chenxidu
--战场官职系统通讯


--map服务器过来的官职竞拍请求
Sv_commands[0][CMD_BUCTION_OFFICER_REQUEST_M] =
function(conn,char_id,pkt)
	if not pkt.id then return end
		g_officer_mgr:request_officer(char_id,pkt)
	return
end

--官职效果使用
Sv_commands[0][CMD_OFFICER_BANNED_REQUEST_M] =
function(conn,char_id,pkt)
	if not pkt then return end
		g_officer_mgr:execute_officer(char_id,pkt)
	return
end

--取消竞投
Sv_commands[0][CMD_CANCEL_OFFICER_REQUEST_M] =
function(conn,char_id,pkt)
	if not pkt.id then return end
		g_officer_mgr:ret_request_officer(char_id)
	return
end

--获取竞投列表
Sv_commands[0][CMD_GET_OFFICER_LIST_M] =
function(conn,char_id,pkt)
	if not pkt then return end
		g_officer_mgr:send_bid_list(char_id,pkt)
	return
end

--被使用技能返回
Sv_commands[0][CMD_USE_OFFICER_SKILL_M] =
function(conn,char_id,pkt)
	if not pkt then return end
		g_officer_mgr:use_skill_return(char_id,pkt)
	return
end

--查看自己的竞投
Sv_commands[0][CMD_CLOSE_OFFICER_LIST_C] =
function(conn,char_id,pkt)
	if not pkt then return end
		g_officer_mgr:see_my_money(char_id)
	return
end

--天帝第一次上线
Sv_commands[0][CMD_OFFICER_TOP_ONLINE_M] =
function(conn,char_id,pkt)
	if not pkt then return end
		g_officer_mgr:officer_top_online(char_id)
	return
end

--查看官职排行榜
Sv_commands[0][CMD_SEE_OFFICER_LISR_M] =
function(conn,char_id,pkt)
	if not pkt then return end
		g_officer_mgr:see_officer_list(char_id)
	return
end

--参拜记录
Sv_commands[0][CMD_VISI_OFFICER_LISR_M] =
function(conn,char_id,pkt)
	if not pkt then return end
		g_officer_mgr:visi_officer_list(char_id)
	return
end

--参拜
Sv_commands[0][CMD_VISI_OFFICER_M] =
function(conn,char_id,pkt)
	if not pkt then return end
		g_officer_mgr:visi_officer(char_id)
	return
end

