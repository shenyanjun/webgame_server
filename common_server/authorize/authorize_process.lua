--local debug_print=print
local debug_print=function() end

---------------------------------委托与map交互---------------------

--打开进行委托面板
Sv_commands[0][CMD_C2W_AUTHORIZE_PRE_M] =
function(conn,char_id,pkt)
	if char_id ~= nil then
		s_pkt = {}
		s_pkt = g_authorize:get_player_today_authorize(char_id)	or {}
		g_server_mgr:send_to_server(conn.id,char_id, CMD_C2W_AUTHORIZE_PRE_C,s_pkt)
	end
	return
end
--打开我的委托面板
Sv_commands[0][CMD_C2W_AUTHORIZE_MINE_M] =
function(conn,char_id,pkt)
	if char_id ~= nil then
		s_pkt = {}
		s_pkt = g_authorize:get_player_authorize(char_id) or {}
		g_server_mgr:send_to_server(conn.id,char_id, CMD_C2W_AUTHORIZE_MINE_C,s_pkt)
	end
	return
end

--打开所有委托
Sv_commands[0][CMD_C2W_AUTHORIZE_ALL_M] =
function(conn,char_id,pkt)
	if char_id ~= nil then
		s_pkt = {}
		s_pkt = g_authorize:get_all_authorize(char_id) or {}
		g_server_mgr:send_to_server(conn.id,char_id, CMD_C2W_AUTHORIZE_ALL_C,s_pkt)	
	end
	return
end

--领取奖励
Sv_commands[0][CMD_C2W_AUTHORIZE_MY_REWARD_M] =
function(conn,char_id,pkt)
	if char_id ~= nil then	
		local s_pkt = g_authorize:get_reward(char_id,pkt.authorize_id) or {}
		g_server_mgr:send_to_server(conn.id,char_id, CMD_C2W_AUTHORIZE_MY_REWARD_C,s_pkt)	
	end
	return
end

--进行委托
Sv_commands[0][CMD_C2W_AUTHORIZE_ENTRUST_M] =
function(conn,char_id,pkt)
	if char_id ~= nil then	
		local s_pkt = g_authorize:entrust_authorize(char_id,pkt) or {}
		if pkt.type == 1 then
			g_server_mgr:send_to_server(conn.id,char_id, CMD_C2W_AUTHORIZE_ENTRUST_C,s_pkt)	
		end
	end
	return
end

--领取委托
Sv_commands[0][CMD_C2W_AUTHORIZE_GET_MISSION_M] =
function(conn,char_id,pkt)
	if char_id ~= nil then	
		local s_pkt = g_authorize:get_authorize_mission(char_id,pkt.authorize_id) or {}
		g_server_mgr:send_to_server(conn.id,char_id, CMD_C2W_AUTHORIZE_GET_MISSION_C,s_pkt)	
	end
	return
end

--扣错补回
Sv_commands[0][CMD_C2W_AUTHORIZE_GET_MISSION2_M] =
function(conn,char_id,pkt)
	if char_id and pkt and pkt.authorize_id and pkt.authorizer then	
		local s_pkt = g_authorize:authorize_compensation(pkt) or {}
	end
	return
end

--完成一次委托
Sv_commands[0][CMD_C2W_AUTHORIZE_COMPLETE_M] =
function(conn,char_id,pkt)
	if char_id and pkt and pkt.authorize_id then	
		g_authorize:complete_authorize(pkt.authorize_id)
	end
	return
end

--领取所有奖励
Sv_commands[0][CMD_C2W_AUTHORIZE_GET_ALL_REWARD_M] =
function(conn,char_id,pkt)
	if char_id ~= nil then	
		local s_pkt = g_authorize:get_all_reward(pkt.char_id) or {}
		g_server_mgr:send_to_server(conn.id,char_id, CMD_C2W_AUTHORIZE_GET_ALL_REWARD_C,s_pkt)	
	end
	return
end

