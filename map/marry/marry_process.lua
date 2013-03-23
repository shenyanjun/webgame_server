--2011-10-26
--chenxidu
--婚姻系统通讯

local MARRY_LEVEL = 45
--接受comm服务器过来的婚姻信息
Sv_commands[0][CMD_P2M_MARRY_INFO_S] =
function(conn,char_id,pkt)
	g_marry_mgr:serialize_from_common_server(pkt)
end

--玩家上线
Clt_commands[1][CMD_B2M_MARRY_PLAYER_INFO_C] =
function(conn,pkt)
	if conn.char_id == nil then return end
	g_marry_mgr:online(conn.char_id)
end

--申请结婚 愿意扣钱
Clt_commands[1][CMD_B2M_MARRY_CREATE_C] =
function(conn,pkt)
	if not conn.char_id  or not pkt.mate_id or not  pkt.char_id or pkt.money <=0 then return end

	local char_id = conn.char_id
	local player = g_obj_mgr:get_obj(char_id)
	if not player then return end
	local pack_con = player:get_pack_con()
	local lock_con = player:get_protect_lock()
	if pack_con then
		if pack_con:check_money_lock(MoneyType.JADE) then		
			return
		end
	end
	local money = pack_con:get_money()
	if money then
		if money.gold + money.gift_gold < 990000 then 
			g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_MARRY_CREATE_S, {["result"]=22503})
			return
		end
	end

	--先做等级判断
	local player_l = g_obj_mgr:get_obj(pkt.char_id)
	local player_l_l = player_l:get_level()

	local player_r = g_obj_mgr:get_obj(pkt.mate_id)
	local player_r_l = player_r:get_level()

	if player_l_l < MARRY_LEVEL or player_r_l < MARRY_LEVEL then
		g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_MARRY_CREATE_S, {["result"]=22495})
		return 
	end

	--发到公共服申请
	if g_marry_mgr:quest_create_marry(pkt) == false then
		g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_MARRY_CREATE_S, {["result"]=22485})
	end
end

--另一方同意结婚 完成结婚
Clt_commands[1][CMD_MARRY_QUEST_C] =
function(conn,pkt)
	if conn.char_id == nil then return end
	if pkt.type == 1 then
		--成功结婚 char_id mate_id money
		g_marry_mgr:answer_create_marry(pkt)
	else
		g_cltsock_mgr:send_client(pkt.char_id, CMD_M2B_MARRY_CREATE_S, {["result"]=22483})
	end
end

--队长在商城购买物品发送给服务器
Clt_commands[1][CMD_B2M_MARRY_MONEY_C] =
function(conn,pkt)
	if conn.char_id == nil then return end
	local player = g_obj_mgr:get_obj(conn.char_id)
	if not player then return end
	local team_id = player:get_team()
	local team_obj = g_team_mgr:get_team_obj(team_id)
	if team_obj then
		if team_obj:get_teamer_id() ~= conn.char_id then
			g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_MARRY_CREATE_S, {["result"]=22498})
			return
		end
	end

	--询问队长是否愿意扣钱
	if pkt.type == 0  then
		--先判断队长钱够不够
		local char_id = conn.char_id
		local player = g_obj_mgr:get_obj(char_id)
		if not player or pkt.id == 0 or pkt.id == nil then return end
		--[[ 不需要扣钱和给物品了
		local pack_con = player:get_pack_con()
		local lock_con = player:get_protect_lock()
		if pack_con then
			if pack_con:check_money_lock(MoneyType.JADE) then		
				return
			end
		end
		local money = pack_con:get_money()
		if money then
			if money.jade < pkt.money then 
				g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_MARRY_CREATE_S, {["result"]=22486})
				return
			end
		end
		--再判断格子数够不够
		local result = 0
		result = g_marry_mgr:give_item_list(pkt.list,conn.char_id,0) 
		if result == 0 then
			local all_price = g_marry_mgr:compute_item_price(pkt.list)
			all_price = all_price + g_marry_mgr:compute_item_price_ex(pkt.id)

			--先扣钱
			if money.jade < all_price then return end
			pack_con:dec_money(MoneyType.JADE, all_price, {['type']=MONEY_SOURCE.MARRY})
			g_marry_mgr:set_add_bonus(conn.char_id,all_price)

			--再同步公共服
			]]
			local marry_info = g_marry_mgr:get_marry_info(conn.char_id)
			--print("marry_info", j_e(marry_info))
			if marry_info.m_b ~= 0 --[[or marry_info.m_t + 300 < ev.time]] then
				g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_MARRY_CREATE_S, {["result"]=22482})
				return
			end
			local all_price = 0
			local m_q_add = 0
			if pkt.id == 3401001 then
				m_q_add = 99
			elseif pkt.id == 3401002 then
				m_q_add = 999
				local pack_con = player:get_pack_con()
				local err_code = pack_con:del_item_by_item_id_inter_face(202007903940, 1, {['type']=ITEM_SOURCE.MARRY}, 1)
				if err_code ~= 0 then 
					return g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_MARRY_CREATE_S, {["result"] = err_code})
				end
			end
			g_marry_mgr:syns_marry_info(conn.char_id,pkt.id ,3600 ,pkt.list,1,2,all_price, m_q_add)
		--[[
		else
			g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_MARRY_CREATE_S, {["result"]=result})	
		end
		]]
	else 
		g_cltsock_mgr:send_client(pkt.mate_id, CMD_M2B_MARRY_CREATE_S, {["result"]=22484})
	end
end

--公共服创建结婚并返回
Sv_commands[0][CMD_P2M_MARRY_CREATE_REP] =
function(conn,char_id,pkt)
	g_marry_mgr:create_marry(pkt)
end

--同步信息
Sv_commands[0][CMD_P2M_MARRY_UPDATE_S] = 
function(conn,char_id,pkt)
	g_marry_mgr:serialize_from_common_server(pkt)
end

Sv_commands[0][CMD_P2M_MARRY_QUEST_REP] = 
function(conn,char_id,pkt)
	if pkt == nil or pkt.list == nil then return end
	g_marry_mgr:notice_all_player(pkt)
end

Sv_commands[0][CMD_P2M_UPDADA_RING_REP] = 
function(conn,char_id,pkt)
	if pkt == nil then return end
	g_marry_mgr:notice_level_ring(pkt)
end

--强制离婚返回
Sv_commands[0][CMD_P2M_BREAK_MARRY_REP] = 
function(conn,char_id,pkt)
	if pkt == nil then return end
	g_marry_mgr:notice_break_marry(pkt)
end

Sv_commands[0][CMD_P2M_FIRST_MARRY_REP] = 
function(conn,char_id,pkt)
	if pkt == nil then return end
	g_marry_mgr:notice_first_marry(pkt)
end

Sv_commands[0][CMD_P2M_AGAIN_MARRY_REP] = 
function(conn,char_id,pkt)
	if pkt == nil then return end
	g_marry_mgr:notice_again_marry(pkt)
end

Sv_commands[0][CMD_P2M_BREAK_MARRY_EX_REP] = 
function(conn,char_id,pkt)
	if pkt == nil then return end
	g_marry_mgr:notice_other(pkt)
end

Sv_commands[0][CMD_P2M_BREAK_MARRY_EN_REP] = 
function(conn,char_id,pkt)
	if pkt == nil then return end
	g_marry_mgr:notice_other_answer(pkt)
end

--公共服增加亲密度返回
Sv_commands[0][CMD_P2M_ADD_QINMIDU_REP] = 
function(conn,char_id,pkt)
	if pkt == nil then return end
	g_marry_mgr:notice_add_qin(pkt)
end

--重办婚姻失败，给对方钱
Sv_commands[0][CMD_P2M_AGAIN_CHECK_REP] = 
function(conn,char_id,pkt)
	if pkt == nil then return end
	g_marry_mgr:notice_again_marry_error(pkt)
end

--获取婚姻场景副本列表
Clt_commands[1][CMD_GET_MARRY_FB_LIST_C] =
function(conn,pkt)
	if conn.char_id == nil then return end
	local ret = {}
	ret.list = g_marry_mgr:get_marry_fb_list()
	ret.result = 0
	g_cltsock_mgr:send_client(conn.char_id, CMD_GET_MARRY_FB_LIST_S,ret)
end

--进入场景申请
Clt_commands[1][CMD_QUEST_MARRY_FB_C] =
function(conn,pkt)
	if conn.char_id == nil then return end
	g_marry_mgr:insert_quest_fb_list(pkt,conn.char_id)
end

--批准进入场景人员列表
Clt_commands[1][CMD_AGREE_COMEIN_LIST_C] =
function(conn,pkt)
	if conn.char_id == nil then return end
	g_marry_mgr:insert_fb_list(conn.char_id,pkt)
end

--获取申请人列表
Clt_commands[1][CMD_GET_QUEST_LIST_C] =
function(conn,pkt)
	if conn.char_id == nil then return end
	local ret = {}
	ret.list,ret.uuid,ret.is_all = g_marry_mgr:get_quest_list(conn.char_id)
	ret.result = 0 
	g_cltsock_mgr:send_client(conn.char_id, CMD_GET_QUEST_LIST_S,ret)
end

--重办婚礼
Clt_commands[1][CMD_AGAIN_MARRY_C] =
function(conn,pkt)
	if conn.char_id == nil then return end
	--先前的场景是否已经结束
	if g_marry_mgr:check_again_marry(conn.char_id) == false then
		g_cltsock_mgr:send_client(conn.char_id, CMD_AGAIN_MARRY_S, {["result"]=22497})	
		return
	end
	--先判断钱够不够 
	local char_id = conn.char_id
	local player = g_obj_mgr:get_obj(char_id)
	if not player or pkt.id == 0 or pkt.id == nil then return end
	local pack_con = player:get_pack_con()
	--再判断格子数够不够
	local result = 0
	local all_price = 0
	--发送更新请求到公共服，等待更新后的数据过来
	local m_q_add = 0
	if pkt.id == 3401001 then
		m_q_add = 99
		local err_code = pack_con:del_item_by_item_id_inter_face(202007903830, 1, {['type']=ITEM_SOURCE.MARRY}, 1)
		if err_code ~= 0 then 
			return g_cltsock_mgr:send_client(conn.char_id, CMD_AGAIN_MARRY_S, {["result"] = err_code})
		end
	elseif pkt.id == 3401002 then
		m_q_add = 999
		local err_code = pack_con:del_item_by_item_id_inter_face(202007904040, 1, {['type']=ITEM_SOURCE.MARRY}, 1)
		if err_code ~= 0 then 
			return g_cltsock_mgr:send_client(conn.char_id, CMD_AGAIN_MARRY_S, {["result"] = err_code})
		end
	end
	g_marry_mgr:syns_marry_info(conn.char_id,pkt.id ,3600 ,pkt.list,1,3,all_price,m_q_add)
	--[[
	local lock_con = player:get_protect_lock()
	if pack_con then
		if pack_con:check_money_lock(MoneyType.JADE) then		
			return
		end
	end
	local money = pack_con:get_money()
	if money then
		if money.jade < pkt.money then 
			g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_MARRY_CREATE_S, {["result"]=22486})
			return
		end
	end
	]]
	--[[
	local all_price = g_marry_mgr:compute_item_price(pkt.list)
	all_price = all_price + g_marry_mgr:compute_item_price_ex(pkt.id)
	result = g_marry_mgr:give_item_list(pkt.list,conn.char_id,0) 
	if result == 0 then
		pack_con:dec_money(MoneyType.JADE, all_price, {['type']=MONEY_SOURCE.MARRY})
		g_marry_mgr:give_item_list(pkt.list,conn.char_id,1)
		g_marry_mgr:set_add_bonus(conn.char_id,all_price)

		--发送更新请求到公共服，等待更新后的数据过来
		local m_q_add = 0
		if pkt.id == 3401001 then
			m_q_add = 99
		elseif pkt.id == 3401002 then
			m_q_add = 999
		end
		g_marry_mgr:syns_marry_info(conn.char_id,pkt.id ,3600 ,pkt.list,1,3,all_price,m_q_add)
	else
		g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_MARRY_CREATE_S, {["result"]=result})	
	end
	]]
end

--离婚申请
Clt_commands[1][CMD_MARRY_DIVORCE_B] =
function(conn,pkt)
	if conn.char_id == nil then return end
	g_marry_mgr:break_marry(conn.char_id,pkt)
end

--离婚询问另一方返回
Clt_commands[1][CMD_DIVORCE_QUEST_B] =
function(conn,pkt)
	if conn.char_id == nil then return end
	pkt.send = conn.char_id
	if pkt.type == 0 then
		--同步到公共服		g_marry_mgr:syn_comm_list_break(conn.char_id)
	end
	g_svsock_mgr:send_server_ex(COMMON_ID,pkt.char_id, CMD_P2M_BREAK_MARRY_EN_REQ, pkt)
end

--升级婚戒 先扣 gift_gold gold
Clt_commands[1][CMD_UPDATE_RING_B] =
function(conn,pkt)
	if conn.char_id == nil then return end
	if g_marry_mgr:check_ring_up(conn.char_id) == false then return end

	--升级
	g_marry_mgr:update_ring(conn.char_id)
end