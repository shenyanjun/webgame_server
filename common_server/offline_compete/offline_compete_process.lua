

--报名
Sv_commands[0][CMD_M2C_OFFLINE_COMPETE_SIGNUP_C] =
function(conn,char_id,pkt)
	--print("CMD_M2C_OFFLINE_COMPETE_SIGNUP_C", j_e(pkt))
	local new_pkt = {}
	new_pkt.result = g_offline_compete_mgr:sign_up(pkt.info)
	g_server_mgr:send_to_server(conn.id, char_id, CMD_C2M_OFFLINE_COMPETE_SIGNUP_S, new_pkt)
end

--更新
Sv_commands[0][CMD_M2C_OFFLINE_COMPETE_UPDATE_C] =
function(conn,char_id,pkt)
	g_offline_compete_mgr:update_info(pkt.info)
	--g_server_mgr:send_to_server(conn.id, char_id, CMD_C2M_OFFLINE_COMPETE_UPDATE_S, new_pkt)
end

--挑战
Sv_commands[0][CMD_M2C_OFFLINE_COMPETE_CHALLENGE_C] =
function(conn,char_id,pkt)
	local new_pkt = {}
	new_pkt.result, new_pkt.be_challenge_id = g_offline_compete_mgr:challenge(char_id, pkt.id)
	g_server_mgr:send_to_server(conn.id, char_id, CMD_C2M_OFFLINE_COMPETE_CHALLENGE_S, new_pkt)
end


--打开主面板
Sv_commands[0][CMD_M2C_OFFLINE_COMPETE_INFO_C] =
function(conn,char_id,pkt)
	local new_pkt = g_offline_compete_mgr:get_info(char_id)
	g_server_mgr:send_to_server(conn.id, char_id, CMD_C2M_OFFLINE_COMPETE_INFO_S, new_pkt)
end

--竞技排行榜
Sv_commands[0][CMD_M2C_OFFLINE_COMPETE_RANKING_C] =
function(conn,char_id,pkt)
	local new_pkt = g_offline_compete_mgr:get_sort_page(pkt.page)
	g_server_mgr:send_to_server(conn.id, char_id, CMD_C2M_OFFLINE_COMPETE_RANKING_S, new_pkt)
end

--领取奖励
Sv_commands[0][CMD_M2C_OFFLINE_COMPETE_REWARD_C] =
function(conn,char_id,pkt)
	--print("CMD_M2C_OFFLINE_COMPETE_REWARD_C", j_e(pkt))
	if pkt.rank and pkt.rank > 0 then
		g_offline_compete_mgr:set_reward(char_id, pkt.rank)
	else
		local new_pkt = g_offline_compete_mgr:get_reward(char_id)
		if new_pkt.rank > 0 then
			--print("CMD_M2C_OFFLINE_COMPETE_REWARD_C 2", j_e(new_pkt))
			g_server_mgr:send_to_server(conn.id, char_id, CMD_C2M_OFFLINE_COMPETE_REWARD_S, new_pkt)
		end
	end
end

--挑战结果通知
Sv_commands[0][CMD_M2C_OFFLINE_COMPETE_FINISH_C] =
function(conn,char_id,pkt)
	--print("CMD_M2C_OFFLINE_COMPETE_FINISH_C", j_e(pkt))
	g_offline_compete_mgr:challenge_finish(char_id, pkt.winner_id, pkt.loser_id)
	--g_server_mgr:send_to_server(conn.id, char_id, CMD_C2M_OFFLINE_COMPETE_REWARD_S, new_pkt)
end

--CD
Sv_commands[0][CMD_M2C_OFFLINE_COMPETE_CD_C] =
function(conn,char_id,pkt)
	local new_pkt = {}
	new_pkt.result = g_offline_compete_mgr:kill_cd(char_id)
	g_server_mgr:send_to_server(conn.id, char_id, CMD_C2M_OFFLINE_COMPETE_CD_S, new_pkt)
end