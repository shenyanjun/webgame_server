
--报名
Sv_commands[0][CMD_M2P_HUMAN_APPLICATION_C] =
function(conn, char_id, pkt)
	if char_id == nil then return end
	local container = g_human_vs_mgr:get_container(char_id)
	if not container then
		container = g_human_vs_mgr:create_container(char_id)
		container:update_player()
		local human_obj = container:get_human_obj()
		human_obj:set_fight(pkt.fight)
	end

	g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_HUMAN_APPLICATION_S, {["result"]=0})

	local str = string.format("insert log_char_battle set attack_id = %d,attack_name='%s',time=%d,type=%d",
				char_id, g_player_mgr.all_player_l[char_id].char_nm,ev.time,1)
		g_web_sql:write(str)
end


--查看排行榜
Sv_commands[0][CMD_M2P_HUMAN_RANK_C] =
function(conn, char_id, pkt)
	if char_id == nil then return end
	local container = g_human_vs_mgr:get_container(char_id)
	if not container then return end

	local ret = g_human_vs_mgr:get_all_info()
	g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_HUMAN_RANK_S, ret)
end

--上线取标志位
Sv_commands[0][CMD_M2P_HUMAN_LOGIN_C] =
function(conn, char_id, pkt)
	if char_id == nil then return end
	local container = g_human_vs_mgr:get_container(char_id)
	
	local ret = {}
	ret.flag = 0
	if container then
		ret.flag = 1
	end
	g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_HUMAN_LOGIN_S, ret)
end

--查看主面板信息
Sv_commands[0][CMD_M2P_HUMAN_MAIN_INFO_C] =
function(conn, char_id, pkt)
	if char_id == nil then return end
	local container = g_human_vs_mgr:get_container(char_id)
	if not container then return end

	container:is_other_day()
	local ret = container:get_net_info()

	g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_HUMAN_MAIN_INFO_S, ret)
end

--冷却时间
Sv_commands[0][CMD_M2P_HUMAN_SUB_TIME_C] =
function(conn, char_id, pkt)
	if char_id == nil then return end
	local container = g_human_vs_mgr:get_container(char_id)
	if not container then return end

	container:set_time_span(0)

	local ret = {}
	ret.result = 0
	ret.left_time = container:get_left_time()
	g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_HUMAN_SUB_TIME_S, ret)
end

--增加次数
Sv_commands[0][CMD_M2P_HUMAN_ADD_COUNT_C] =
function(conn, char_id, pkt)
	if char_id == nil then return end
	local container = g_human_vs_mgr:get_container(char_id)
	if not container then return end

	if container:is_full_add_count() then return g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_HUMAN_ADD_COUNT_S, {["result"] = 22653}) end
	
	local count = container:get_count()
	container:set_count(count + (pkt.count or 1))
	container:del_max_add_count()

	local ret = {}
	ret.result = 0
	ret.count = container:get_count()
	g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_HUMAN_ADD_COUNT_S, ret)
end

--挑战
Sv_commands[0][CMD_M2P_HUMAN_FIGHT_C] =
function(conn, char_id, pkt)
	if char_id == nil or pkt == nil then return end

	local char_id_d = pkt.char_id_d
	local syn_info = pkt.syn_info

	local container = g_human_vs_mgr:get_container(char_id)
	if not container then return end

	container:is_other_day()
	if container:is_fresh_all_time() then return end
	local result = container:can_be_fight()
	if result ~= 0 then return g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_HUMAN_FIGHT_S, {["result"] = result}) end

	g_human_vs_mgr:update_container_and_fight(char_id,char_id_d,syn_info)
end


--查看录像
Sv_commands[0][CMD_P2M_HUMAN_VEDIO_C] =
function(conn, char_id, pkt)
	if char_id == nil or pkt.vedio_id == nil then return end

	local container = g_human_vs_mgr:get_container(char_id)
	if not container then return end

	local vedio_container = container:get_vedio_con()
	if not vedio_container then return end

	local vedio = vedio_container:get_vedio(pkt.vedio_id)
	if not vedio then return end

	local ret = {}
	ret.vedio = {vedio:get_vedio_list()}
	g_server_mgr:send_to_server(conn.id,char_id, CMD_M2P_HUMAN_VEDIO_S, ret)
end

--打开录像面板
Sv_commands[0][CMD_P2M_HUMAN_VEDIO_OPEN_C] =
function(conn, char_id, pkt)
	if char_id == nil then return end

	local container = g_human_vs_mgr:get_container(char_id)
	if not container then return end

	local vedio_container = container:get_vedio_con()
	if not vedio_container then return end

	local ret = vedio_container:get_net_info()
	g_server_mgr:send_to_server(conn.id,char_id, CMD_M2P_HUMAN_VEDIO_OPEN_S, ret)
end

--越级挑战
Sv_commands[0][CMD_M2P_HUMAN_JUMP_CHALLENGE_C] =
function(conn, char_id, pkt)
	if char_id == nil or pkt == nil then return end
	local index = pkt.index
	local rank = g_human_vs_mgr:get_rank_by_id(char_id)
	if rank <= index then 
		return g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_HUMAN_JUMP_CHALLENGE_S, {["result"] = 22658}) 
	end
	local char_id_d = g_human_vs_mgr:get_char_by_rank(index)

	local syn_info = pkt.syn_info

	local container = g_human_vs_mgr:get_container(char_id)
	if not container then return end

	container:is_other_day()
	if container:is_fresh_all_time() then return end
	local result = container:can_be_fight()
	if result ~= 0 then return g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_HUMAN_FIGHT_S, {["result"] = result}) end

	g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_HUMAN_JUMP_CHALLENGE_S, {["result"] = 0}) 
	g_human_vs_mgr:update_container_and_fight(char_id,char_id_d,syn_info)

end


---------------------------------------------------------------------------------------------------------------------------------

--查看奴隶等信息

Sv_commands[0][CMD_M2P_SLAVE_INFO_C] =
function(conn, char_id, pkt)
	if char_id == nil then return end

	local container = g_human_vs_mgr:get_container(char_id)
	if not container then return end

	local owner_id = container:get_slave_owner()
	if owner_id then
		local container_owner = g_human_vs_mgr:get_container(owner_id)
		if not container_owner then
			container:set_slave_owner()
			container:update_player()
		end
	end

	local type = pkt.type
	local ret = {}
	ret[1] = {}
	ret[1][1] = type
	if type == 1 then  --我的奴隶
		ret[1][2], ret[1][3] = container:get_slave_info()
	elseif type == 2 then --手下败将
		ret[1][2] = container:get_message_info(container:get_defeated_member())
	elseif type == 3 then --夺仆之敌
		ret[1][2] = container:get_message_info(container:get_slave_enemy())
	elseif type == 4 then --我的旧主
		ret[1][2] = container:get_message_info(container:get_old_owner())
	elseif type == 5 then --解放奴隶
		ret[1][2] = container:get_liberation_info()
	end

	g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_SLAVE_INFO_S, ret)
end

--调戏，抛弃，设置名称
Sv_commands[0][CMD_M2P_SLAVE_EFFECT_C] =
function(conn, char_id, pkt)
	if char_id == nil or pkt == nil then return end

	local container = g_human_vs_mgr:get_container(char_id)
	if not container then return end

	local type = pkt.type
	if type == 1 then  --调戏
		container:is_other_day()
		local s_count = container:get_s_count()
		if s_count > 0 then
			local container_d = g_human_vs_mgr:get_container(pkt.char_id)
			if container_d and container_d:get_be_s_count() > 0 and container:get_left_s_time() <= 0 then
				container:del_s_count(1)
				container_d:del_be_s_count(1)
				container:set_s_time(ev.time + 600)
				local pkt_t = {}
				pkt_t.type = pkt.type
				pkt_t.result = 0
				pkt_t.char_id = pkt.char_id
				pkt_t.count = container:get_s_count()
				pkt_t.reward = container:get_reward(pkt.char_id,pkt.flag)
				pkt_t.time = container:get_left_s_time()
				pkt_t.flag = pkt.flag
				pkt_t.flirt_count = container_d:get_be_s_count()
				g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_SLAVE_EFFECT_S,  pkt_t)
			else
				local pkt_t = {}
				pkt_t.type = pkt.type
				pkt_t.result = 22656
				pkt_t.char_id = pkt.char_id
				pkt_t.flag = pkt.flag
				g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_SLAVE_EFFECT_S,  pkt_t)
			end
		else
			pkt.result = 22655
			pkt.count = container:get_s_count()
			g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_SLAVE_EFFECT_S, pkt)
		end
		container:update_player()
	elseif type == 2 then  --抛弃
		local container_d = g_human_vs_mgr:get_container(pkt.char_id)
		if container_d then
			container_d:set_slave_owner()
		end
		container:del_slave(pkt.char_id)
		container:update_player()
		pkt.result = 0
		g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_SLAVE_EFFECT_S, pkt)
	elseif type == 3 then  --设置名称
		container:set_slave_name(pkt.char_id, pkt.char_nm)
		container:update_player()
		pkt.result = 0
		g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_SLAVE_EFFECT_S, pkt)
	end
end




--slave challenge
Sv_commands[0][CMD_M2P_SLAVE_CHALLENGE_C] =
function(conn, char_id, pkt)
	if char_id == nil and pkt == nil then return end

	local container_s = g_human_vs_mgr:get_container(char_id)
	local container_d = g_human_vs_mgr:get_container(pkt.char_id)
	if not container_s or not container_d then return end

	local type = pkt.type
	if type == 1 then --挑战自己的主人
		local owner_id = container_s:get_slave_owner()
		if owner_id then  --挑战主人
			if owner_id == char_id then container_s:set_slave_owner() return end
			local container_owner = g_human_vs_mgr:get_container(owner_id)
			if container_owner then
				local slave_list = container_owner:get_slave_list()
				if container_owner:is_on_table_ex(slave_list, char_id) then
					local param = {}
					param.type = 6
					g_human_vs_mgr:update_container_and_slave_fight(char_id, owner_id, pkt.syn_info, param)
				else
					container_s:set_slave_owner()
					container_s:update_player()
				end
			else
				container_s:set_slave_owner()
				container_s:update_player()
			end
		end
	elseif type == 2 then --手下败将
		if container_s:is_on_table(container_s:get_defeated_member(), pkt.char_id) then
			local owner_id = container_d:get_slave_owner()
			if owner_id then  --挑战主人
				if owner_id ~= char_id_s then
					local container_owner = g_human_vs_mgr:get_container(owner_id)
					if container_owner then
						local slave_list = container_owner:get_slave_list()
						if container_owner:is_on_table_ex(slave_list, pkt.char_id) then
							local param = {}
							param.type = 1
							param.char_id = pkt.char_id
							g_human_vs_mgr:update_container_and_slave_fight(char_id, owner_id, pkt.syn_info, param)
						else
							container_d:set_slave_owner()
							container_d:update_player()
						end
					else
						container_d:set_slave_owner()
						container_d:update_player()
					end
				end
			else
				if container_s:is_slave_list_full() then
					return g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_SLAVE_CHALLENGE_S, {["result"] = 22657})
				end
				local param = {}
				param.type = 2
				g_human_vs_mgr:update_container_and_slave_fight(char_id, pkt.char_id, pkt.syn_info, param)
			end
		end
	elseif type == 3 then --夺仆之敌
		if container_s:is_on_table(container_s:get_slave_enemy(), pkt.char_id) then
			local param = {}
			param.type = 3
			g_human_vs_mgr:update_container_and_slave_fight(char_id, pkt.char_id, pkt.syn_info, param)
		end
	elseif type == 4 then --我的旧主
		if container_s:is_on_table(container_s:get_old_owner(), pkt.char_id) then
			local param = {}
			param.type = 4
			g_human_vs_mgr:update_container_and_slave_fight(char_id, pkt.char_id, pkt.syn_info, param)
		end
	elseif type == 5 then  --解放奴隶
		local owner_id = container_d:get_slave_owner()
		if owner_id and owner_id ~= char_id then  --挑战主人
			local param = {}
			param.type = 5
			param.char_id = pkt.char_id
			g_human_vs_mgr:update_container_and_slave_fight(char_id, owner_id, pkt.syn_info, param)
		end
	end
end


