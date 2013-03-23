

--建队
Sv_commands[0][CMD_M2P_PET_FIGHT_TEAM_C] =
function(conn, char_id, pkt)
	--print("CMD_M2P_PET_FIGHT_TEAM_C",j_e(pkt))
	if char_id == nil or pkt == nil then return end

	local container = g_pet_vs_mgr:get_container(char_id)
	if container then 
		return g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_PET_FIGHT_TEAM_S, {["result"] = 20910}) 
	end 
	if pkt.team_name == nil or pkt.team_name == "" then 
		return 
	end
	--if table.size(pkt.obj_id_list) == 0 then 
		--return
	--end
	if f_filter_world(pkt.team_name) then
		g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_PET_FIGHT_TEAM_S, {["result"]=30013})
		return
	end

	if not g_pet_vs_mgr:is_create_ok(pkt.team_name) then
		return g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_PET_FIGHT_TEAM_S, {["result"]=20911})
	end


	local container = g_pet_vs_mgr:create_container(char_id, pkt.team_name, pkt.syn or {})
	--local strategy_con = container:get_strategy_con()
	--if not strategy_con then
		--print("Error: CMD_M2P_PET_FIGHT_TEAM_C 1")
	--end
	--strategy_con:add_strategy(pkt.obj_id_list)

	local ret = {}
	ret.result = 0
	ret.team_name = container:get_team_name()

	local strategy_con = container:get_strategy_con()
	--local strategy_obj = strategy_con:get_strategy(1)
	--if not strategy_obj then 
		--ret.strategy_info = {0,0,0,0,0}
		--print("Error:CMD_M2P_PET_FIGHT_TEAM_C 2")
	--else
		ret.strategy_info = strategy_con:get_net_info()
	--end

	--local matrix_con = container:get_matrix_con()
	--if not matrix_con then
		--print("Error:CMD_M2P_PET_FIGHT_TEAM_C 3")
		--return 
	--end

	--ret.matrix_info = matrix_con:get_net_info()

	g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_PET_FIGHT_TEAM_S, ret)

	--流水
	local monday = f_get_sunday() + 24 * 3600 + 1
	local t_time = os.date("%y%m%d",monday,monday,monday)
	local str = string.format("insert log_pet_battle set date ='%s',attack_id = %d,attack_name='%s',time=%d,type=%d",
				t_time, char_id, g_player_mgr.all_player_l[char_id].char_nm,ev.time,1)
		g_web_sql:write(str)
end

--查看积分页面信息
Sv_commands[0][CMD_M2P_PET_FIGHT_INFO_C] =
function(conn, char_id, pkt)
	--print("CMD_M2P_PET_FIGHT_INFO_C",j_e(pkt))
	if char_id == nil then return end
	local container = g_pet_vs_mgr:get_container(char_id)
	if not container then return end

	container:is_other_day()

	local ret = container:get_net_info()
	g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_PET_FIGHT_INFO_S, ret)


	--local container_s = g_pet_vs_mgr:get_container(9) --char_id
	--local container_d = g_pet_vs_mgr:get_container(4076)--pkt.char_id
	--if not container_s or not container_d then return end
	--if char_id == pkt.char_id then return end
	--print("111")
	--container_s:is_other_day()
	--local result = container_s:can_challenge()
	--if result ~= 0 then
		--if result ~= nil then
			--g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_PET_FIGHT_CHALLENGE_S, {["result"]=result})
		--end
	--else
		--print("222")
		--g_pet_vs_mgr:syn_info(9, 4076)
	--end
end

--开始挑战
Sv_commands[0][CMD_M2P_PET_FIGHT_CHALLENGE_C] =
function(conn, char_id, pkt)
	--print("CMD_M2P_PET_FIGHT_CHALLENGE_C",j_e(pkt))
	if pkt == nil or char_id == nil or pkt.char_id == nil then return end
	local container_s = g_pet_vs_mgr:get_container(char_id) --char_id
	local container_d = g_pet_vs_mgr:get_container(pkt.char_id)--pkt.char_id
	if not container_s or not container_d then return end
	if char_id == pkt.char_id then return end

	container_s:is_other_day()
	local result = container_s:can_challenge()
	if result ~= 0 then
		if result ~= nil then
			g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_PET_FIGHT_CHALLENGE_S, {["result"]=result})
		end
	else
		g_pet_vs_mgr:syn_info(char_id, pkt.char_id)
	end
end

--查看录像
Sv_commands[0][CMD_M2P_PET_FIGHT_VEDIO_C] =
function(conn, char_id, pkt)
	if char_id == nil or pkt.vedio_id == nil then return end

	local container = g_pet_vs_mgr:get_container(char_id)
	if not container then return end

	local vedio_container = container:get_vedio_con()
	if not vedio_container then return end

	local vedio = vedio_container:get_vedio(pkt.vedio_id)
	if not vedio then return end

	local ret = {}
	ret.vedio = vedio:get_vedio_list()
	g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_PET_FIGHT_VEDIO_S, ret)
end

--打开录像面板
Sv_commands[0][CMD_M2P_PET_FIGHT_OPEN_VEDIO_C] =
function(conn, char_id, pkt)
	--print("CMD_M2P_PET_FIGHT_OPEN_VEDIO_C",j_e(pkt))
	if char_id == nil then return end

	local container = g_pet_vs_mgr:get_container(char_id)
	if not container then return end

	local vedio_container = container:get_vedio_con()
	if not vedio_container then return end

	local ret = vedio_container:get_net_info()
	--print("===================",j_e(ret))
	g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_PET_FIGHT_OPEN_VEDIO_S, ret)
end


--上线打开报名面板
Sv_commands[0][CMD_M2P_PET_FIGHT_APP_OPEN_C] =
function(conn, char_id, pkt)
	--print("CMD_M2P_PET_FIGHT_APP_OPEN_C",j_e(pkt))
	if char_id == nil then return end

	local container = g_pet_vs_mgr:get_container(char_id)
	if not container then 
		return g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_PET_FIGHT_APP_OPEN_S, {["team_name"]=""})
	end

	local strategy_con = container:get_strategy_con()
	if not strategy_con then 
		print("Error:CMD_M2P_PET_FIGHT_APP_OPEN_C 1")
		return 
	end

	--local matrix_con = container:get_matrix_con()
	--if not matrix_con then
		--print("Error:CMD_M2P_PET_FIGHT_APP_OPEN_C 2")
		--return 
	--end

	local ret = {}
	ret.team_name = container:get_team_name()

	--local strategy_obj = strategy_con:get_strategy(1)
	--if not strategy_obj then 
		--ret.strategy_info = {0,0,0,0,0}
		--print("Error:CMD_M2P_PET_FIGHT_APP_OPEN_C 3")
	--else
		ret.strategy_info = strategy_con:get_net_info()
	--end

	--ret.matrix_info = matrix_con:get_net_info()
	--print("=====",j_e(ret))

	g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_PET_FIGHT_APP_OPEN_S, ret)


end

--修改策略
Sv_commands[0][CMD_M2P_PET_FIGHT_STRATEGY_C] =
function(conn, char_id, pkt)
	--print("CMD_M2P_PET_FIGHT_STRATEGY_C",j_e(pkt))
	if char_id == nil or pkt == nil then return end

	local container = g_pet_vs_mgr:get_container(char_id)
	if not container then return end

	local pet_con = container:get_pet_con()
	if not pet_con then return end

	local strategy_con = container:get_strategy_con()
	if not strategy_con then return end

	g_pet_vs_mgr:update_info(char_id, pkt.info)

	strategy_con:del_all_pet()
	strategy_con:add_all_pet(pkt.strategy)

	local ret = {}
	ret.strategy = strategy_con:get_net_info()
	ret.result = 0
	--print("4343434",j_e(ret))

	g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_PET_FIGHT_STRATEGY_S, ret)
end


--查看排行榜
Sv_commands[0][CMD_M2P_PET_FIGHT_RANK_C] =
function(conn, char_id, pkt)
	--print("CMD_M2P_PET_FIGHT_RANK_C",j_e(pkt))
	if char_id == nil then return end

	local ret = g_pet_vs_mgr:get_all_info()
	g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_PET_FIGHT_RANK_S, ret)

end


--添加阵法
Sv_commands[0][CMD_M2P_PET_FIGHT_MATRIX_C] =
function(conn, char_id, pkt)
	if char_id == nil then return end

	local container = g_pet_vs_mgr:get_container(char_id)
	if not container then 
		return g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_PET_FIGHT_MATRIX_S, {["result"]=20913})
	end

	local matrix_con = container:get_matrix_con()
	if not matrix_con then return end

	if matrix_con:get_matrx_obj(pkt.matrix_id) then
		return g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_PET_FIGHT_MATRIX_S, {["result"]=335532})
	end

	local matrix_obj = g_matrix_mgr:get_matrix(pkt.matrix_id)
	if not matrix_obj then 
		return g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_PET_FIGHT_MATRIX_S, {["result"]=335332})
	end
	
	matrix_con:add_matrix_obj(matrix_obj)
	local ret = {}
	ret.result = 0
	g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_PET_FIGHT_MATRIX_S, ret)

end

--删除宠物同步更新
Sv_commands[0][CMD_M2P_PET_FIGHT_PET_SYN_C] =
function(conn, char_id, pkt)
	if char_id == nil or pkt == nil then return end
	local container = g_pet_vs_mgr:get_container(char_id)
	if not container then return end

	g_pet_vs_mgr:update_info(char_id, pkt)

	local pet_adventure = g_pet_adventure_mgr:get_container(char_id)
	if not pet_adventure then return end

	local pet_con = pet_adventure:get_pet_con()
	if not pet_con then return end
	
	pet_con:update_pet_list(pkt)

end


--查看属性
--Sv_commands[0][CMD_M2P_PET_MY_INFO_C] =
--function(conn, char_id, pkt)
	--
--end

--查看别人信息
Sv_commands[0][CMD_M2P_PET_FIGHT_OTHER_INFO_C] = 
function (conn, char_id, pkt)
	if char_id == nil or pkt == nil then return end
	local obj_id_d = pkt.char_id
	local container = g_pet_vs_mgr:get_container(obj_id_d)
	if not container then return end
	
	local pet_con = container:get_pet_con()
	if not pet_con then return end

	local ret = {}
	ret.pet_list = pet_con:get_pet_info()
	ret.char_id = obj_id_d
	g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_PET_FIGHT_OTHER_INFO_S, ret)
end

--减时间
Sv_commands[0][CMD_M2P_PET_FIGHT_SUB_TIME_C] = 
function (conn, char_id, pkt)
	if char_id == nil then return end

	local container = g_pet_vs_mgr:get_container(char_id)
	if not container then return end

	local time_t = container:get_left_time()
	if time_t == 0 then return g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_PET_FIGHT_SUB_TIME_S, {["result"] = 20915}) end

	local time_span = container:get_time_span()
	container:set_time_span(0)

	local ret = container:get_net_info()
	g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_PET_FIGHT_INFO_S, ret)

	g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_PET_FIGHT_SUB_TIME_S, {["result"] = 0})
end


--查看别人的宠物信息

Sv_commands[0][CMD_M2P_PET_FIGHT_OTHER_PET_C] = 
function (conn, char_id, pkt)
	if char_id == nil then return end

	local container = g_pet_vs_mgr:get_container(pkt.char_id)
	if not container then return end

	local pet_con = container:get_pet_con()
	if not pet_con then return end

	local pet_obj = pet_con:get_pet_obj(pkt.obj_id)
	if not pet_obj then return end

	local ret = pet_obj:get_pet_info()
	g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_PET_FIGHT_OTHER_PET_S, ret)
end


--排行榜查看宠物信息（包括离线）
Sv_commands[0][CMD_M2P_PET_SORT_INFO_C] = 
function (conn, char_id, pkt)
	if char_id == nil or pkt == nil or pkt.char_id == nil or pkt.obj_id == nil then return end
	if g_player_mgr:is_online_char(pkt.char_id) then
		g_pet_sort_mgr:syn(pkt.char_id, pkt.obj_id, char_id, conn.id)
	else
		g_pet_sort_mgr:db_load(pkt.obj_id)
		local info = g_pet_sort_mgr:get_pet_info(pkt.obj_id)
		g_server_mgr:send_to_server(conn.id, char_id, CMD_P2M_PET_SORT_INFO_S, info)
	end
end


--开启阵位

Sv_commands[0][CMD_M2P_PET_FIGHT_OPEN_MATRIX_C] = 
function (conn, char_id, pkt)
	--print("CMD_M2P_PET_FIGHT_OPEN_MATRIX_C",j_e(pkt))
	if char_id == nil or pkt.index == nil then return end

	if pkt.index > 9 or pkt.index < 1 then return end

	g_pet_vs_mgr:open_strategy(pkt.index, char_id)
end

--佩服和调戏
Sv_commands[0][CMD_M2P_PET_FIGHT_ADMIRE_C] = 
function (conn, char_id, pkt)
	--print("CMD_M2P_PET_FIGHT_ADMIRE_C",j_e(pkt))
	if char_id == nil or pkt == nil then return end

	local index = g_pet_vs_mgr:get_rank_by_id(char_id)
	if index == 1 then 
		return g_server_mgr:send_to_server(conn.id, char_id, CMD_P2M_PET_FIGHT_ADMIRE_S, {["result"] = 20918})
	end


	local container = g_pet_vs_mgr:get_container(char_id)
	if not container then return end

	container:is_other_worship_time()

	if container:get_worship_time() > 0 then 
		return g_server_mgr:send_to_server(conn.id, char_id, CMD_P2M_PET_FIGHT_ADMIRE_S, {["result"] = 20921})
	end

	container:set_point(100)
	container:set_worship_time(ev.time)

	g_pet_vs_mgr:del_char(char_id)
	g_pet_vs_mgr:insert_char(char_id)

	local ret = container:get_net_info()
	g_server_mgr:send_to_server(conn.id, char_id, CMD_P2M_PET_FIGHT_INFO_S, ret)

	local ret = {}
	ret.result = 0
	g_server_mgr:send_to_server(conn.id, char_id, CMD_P2M_PET_FIGHT_ADMIRE_S, ret)
end

