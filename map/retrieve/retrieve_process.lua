local err_fun = function(char_id, cmd, err)
	local new_pkt = {}
	new_pkt.result = err
	g_cltsock_mgr:send_client(char_id, cmd, new_pkt)
end

----打开基本面板
Clt_commands[1][CMD_RETRIEVE_OPEN_BASE_B] = 
function(conn, pkt)
	local char_id = conn.char_id

	local player = g_obj_mgr:get_obj(char_id)
	if not player then return end

	local r_con = player:get_retrieve_con()
	if not r_con then return end

	local s_pkt = r_con:get_all_info_net()
	g_cltsock_mgr:send_client_ex(conn, CMD_RETRIEVE_OPEN_BASE_S, s_pkt)
end

----领取
Clt_commands[1][CMD_RETRIEVE_GET_REWARD_B] = 
function(conn, pkt)
	local char_id = conn.char_id
	if not pkt or not pkt.id or not pkt.type or
		pkt.type < 1 or pkt.type > 3 then
		return
	end
	local player = g_obj_mgr:get_obj(char_id)
	if not player then return end

	local r_con = player:get_retrieve_con()
	if not r_con then return end

	local s_pkt = r_con:get_retrieve_reward(pkt.id, pkt.type)
	if s_pkt.result == 0 then
		local t_pkt = r_con:get_all_info_net()
	
		g_cltsock_mgr:send_client_ex(conn, CMD_RETRIEVE_OPEN_BASE_S, t_pkt)
	end

	g_cltsock_mgr:send_client_ex(conn, CMD_RETRIEVE_GET_REWARD_S, s_pkt)
end

-- 离线 全部找回
Clt_commands[1][CMD_RETRIEVE_GET_ALL_REWARD_B] = 
function(conn, pkt)
	local char_id = conn.char_id
	if not pkt or not pkt.type or
		pkt.type < 1 or pkt.type > 3 then
		return
	end

	local player = g_obj_mgr:get_obj(char_id)
	if not player then return end

	local r_con = player:get_retrieve_con()
	if not r_con then return end

	local need_money = 0
	local all_money	 = 0
	local exp		 = 0
	local all_exp	 = 0
	local log		 = {}

	need_money,exp = r_con:get_all_retrieve_reward(pkt.type)   --副本补偿
	all_money = all_money + need_money
	all_exp   = all_exp + exp
	if need_money ~= 0 or exp ~= 0 then
		log[1] = {}
		log[1].type 	  = 1
		log[1].need_money = need_money
		log[1].exp		  = exp
		need_money,exp = 0,0
	end

	local regression = player:get_regression()					-- 离线补偿
	if regression then  
		need_money,exp = regression:get_all_activity_reward(pkt.type)
		all_money = all_money + need_money
		all_exp   = all_exp + exp
		
		if need_money ~= 0 or exp ~= 0 then
			log[2] = {}
			log[2].type 	  = 2
			log[2].need_money = need_money
			log[2].exp		  = exp
			need_money,exp = 0,0
		end
	end

	local obj = g_off_mgr:get_obj(conn.char_id)				--修炼经验
	if obj then 
		exp = obj:get_expr() * obj:get_expmu(pkt.type)
		need_money = obj:get_monye(pkt.type)
		all_money = all_money + need_money
		all_exp   = all_exp + exp
		all_exp   = all_exp + (exp * player:get_addition(HUMAN_ADDITION.offline_exp))  --vip 加成
		if need_money ~= 0 or exp ~= 0 then
			log[3] = {}
			log[3].type 	  = 3
			log[3].need_money = need_money
			log[3].exp		  = exp
		end
	end

	local ret = {}
	ret.result = 0
	if all_exp == 0 or all_money == 0 then
		ret.result = 22704
		g_cltsock_mgr:send_client(conn.char_id, CMD_RETRIEVE_GET_ALL_REWARD_S, ret)
		return
	end
	--if not player:is_add_exp(exp) then
		--return 20774
	--end
	local pack_con = player:get_pack_con()
	local money_list = {}
	local succeed
	local money_type 
	all_exp = math.floor(all_exp)
	if pkt.type == 2 then
		if pack_con:check_money_lock(MoneyType.GOLD) then
			return
		end
		money_list[MoneyType.GOLD] = all_money
		ret.result = pack_con:dec_money_l_inter_face(money_list, {['type']=MONEY_SOURCE.GET_ALL_OFFLINEEXP})
		if ret.result == 0 then
			succeed = 1
		end
		money_type = MoneyType.GOLD
	elseif pkt.type == 3 then
		if pkt.check ~= nil then
			pkt.all_exp = all_exp
			pkt.all_money = all_money
			g_cltsock_mgr:send_client(conn.char_id, CMD_RETRIEVE_GET_ALL_REWARD_S, pkt)
			--print("CMD_RETRIEVE_GET_ALL_REWARD_S pkt", j_e(pkt))
			return
		end
		local ret = {}
		for k, v in pairs(pkt) do
			ret[k] = v
		end
	
		ret.all_exp = all_exp
		ret.all_money = all_money

		g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id, CMD_M2C_QQ_OFFLINE_M, ret)
		
		return
	end

	if succeed == 1 then
		player:add_exp(all_exp)
		local sql_str
		for i,v in pairs(log) do
			sql_str = string.format("insert log_free set char_id = %d, char_name='%s', project=%d, type=%d, money=%d, num=%d, exp=%d, time=%d",
					conn.char_id, player:get_name(), v.type, 5, money_type, v.need_money, v.exp, os.time())
			f_multi_web_sql(sql_str)
		end
	else 
		g_cltsock_mgr:send_client(conn.char_id, CMD_RETRIEVE_GET_ALL_REWARD_S, ret)
		return
	end
	r_con:updaete_alldata()
	regression:updatedb_days()
	obj:set_point(0)
	g_cltsock_mgr:send_client(conn.char_id, CMD_RETRIEVE_GET_ALL_REWARD_S, ret)
end	

Sv_commands[0][CMD_M2C_QQ_OFFLINE_C]=
function(conn, char_id, pkt)
	if pkt.result and pkt.result ~= 0 then
		g_cltsock_mgr:send_client(char_id, CMD_RETRIEVE_GET_ALL_REWARD_S, {result = pkt.result})
		return
	end

	local player = g_obj_mgr:get_obj(char_id)
	local r_con = player and player:get_retrieve_con()
	if not r_con then 
		pkt.result = 321
		g_svsock_mgr:send_server_ex(COMMON_ID,char_id, CMD_M2C_QQ_OFFLINE_REQ, pkt)
		return 
	end

	local all_money	 = 0
	local exp		 = 0
	local all_exp	 = 0
	local log		 = {}

	need_money,exp = r_con:get_all_retrieve_reward(pkt.type)   --副本补偿

	all_money = all_money + need_money
	all_exp   = all_exp + exp
	if need_money ~= 0 or exp ~= 0 then
		log[1] = {}
		log[1].type 	  = 1
		log[1].need_money = need_money
		log[1].exp		  = exp
		need_money,exp = 0,0
	end

	local regression = player:get_regression()					-- 离线补偿
	if regression then  
		need_money,exp = regression:get_all_activity_reward(pkt.type)
		all_money = all_money + need_money
		all_exp   = all_exp + exp
		if need_money ~= 0 or exp ~= 0 then
			log[2] = {}
			log[2].type 	  = 2
			log[2].need_money = need_money
			log[2].exp		  = exp
			need_money,exp = 0,0
		end
	end

	local obj = g_off_mgr:get_obj(char_id)				--修炼经验
	if obj then 
		exp = obj:get_expr() * obj:get_expmu(pkt.type)
		need_money = obj:get_monye(pkt.type)
		all_money = all_money + need_money
		all_exp   = all_exp + exp
		if need_money ~= 0 or exp ~= 0 then
			log[3] = {}
			log[3].type 	  = 3
			log[3].need_money = need_money
			log[3].exp		  = exp
		end
	end

	player:add_exp(pkt.all_exp)

	pkt.result = 0
	g_svsock_mgr:send_server_ex(COMMON_ID,char_id, CMD_M2C_QQ_OFFLINE_REQ, pkt)

	local sql_str
	for i,v in pairs(log) do
		sql_str = string.format("insert log_free set char_id = %d, char_name='%s', project=%d, type=%d, money=%d, num=%d, exp=%d, time=%d",
				conn.char_id, player:get_name(), v.type, 5, 3, v.need_money, v.exp, os.time())
		f_multi_web_sql(sql_str)
	end

	r_con:updaete_alldata()
	regression:updatedb_days()
	obj:set_point(0)
	g_cltsock_mgr:send_client(char_id, CMD_RETRIEVE_GET_ALL_REWARD_S, ret)
	

end