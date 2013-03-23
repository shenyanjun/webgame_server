-- 帮派庭院
--local debug_print = print
local debug_print = function() end

local money_tree_config = require("config.loader.faction_courtyard_loader")
local censer_config = require("config.loader.faction_censer_loader")

-- 玩家上线或切线请求摇钱树信息
Clt_commands[1][CMD_GET_MONEY_TREE_INFO_B] = 
function(conn, pkt)
	debug_print("in CMD_GET_MONEY_TREE_INFO_B")
	if conn and conn.char_id then -- 检查参数
		g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id, CMD_GET_MONEY_TREE_INFO_M, pkt) -- 获取铜券树信息
	end
end

Sv_commands[0][CMD_GET_MONEY_TREE_INFO_C] = 
function(conn, char_id, pkt)
	debug_print("in CMD_GET_MONEY_TREE_INFO_C")
	debug_print(j_e(pkt))
	g_cltsock_mgr:send_client(char_id, CMD_GET_MONEY_TREE_INFO_S, pkt)
end

-- 玩家摇树
Clt_commands[1][CMD_ROCK_MONEY_TREE_B] = 
function(conn, pkt)
	debug_print("in CMD_ROCK_MONEY_TREE_B")
	if conn and conn.char_id then -- 检查参数
		pkt.vip_level = g_vip_mgr:get_vip_info(conn.char_id)
		g_svsock_mgr:send_server_ex(COMMON_ID, conn.char_id, CMD_ROCK_MONEY_TREE_M, pkt)
	end
end

Sv_commands[0][CMD_ROCK_MONEY_TREE_CHECK_C] = 
function(conn, char_id, pkt)
	debug_print("in CMD_ROCK_MONEY_TREE_CHECK_C")
	debug_print(j_e(pkt))
	debug_print("---------------------------")
	if char_id == nil then return end
	local cnt = pkt.cnt
	if cnt then
		local player = g_obj_mgr:get_obj(char_id)
		if not player then return end
		local pack_con = player:get_pack_con()
		if not pack_con then return end
		cnt = cnt + 1
		local need_money = money_tree_config.get_cost(cnt)
		if not need_money then return end
		local gold_jade = money_tree_config.get_give_gold_jade(cnt)
		if not gold_jade then return end
		local faction = g_faction_mgr:get_faction_by_cid(char_id)
		if not faction then return end
		local gold_level = faction:get_gold_level()
		if not gold_level then return end
		local multi = money_tree_config.get_addition(gold_level)
		if not multi then return end
		local money_list = {}
		money_list[MoneyType.GIFT_JADE] = need_money
		local ret = pkt
		g_sock_event_mgr:set_event_id(char_id, pkt, ret)
		local e_code = pack_con:dec_money_l_inter_face(money_list, {['type']=(MONEY_SOURCE.MONEY_TREE)}, 2, nil)
		if e_code ~= 0 then
			local ret = {}
			ret.result = e_code
			return g_cltsock_mgr:send_client(char_id, CMD_ROCK_MONEY_TREE_S, ret)
		end
		g_svsock_mgr:send_server_ex(COMMON_ID,char_id, CMD_ROCK_MONEY_TREE_CHECK_S, ret)
	end
end

Sv_commands[0][CMD_ROCK_MONEY_TREE_C] = 
function(conn, char_id, pkt)
	if pkt and pkt.result == 0 then
		local player = g_obj_mgr:get_obj(char_id)
		if not player then return end
		local pack_con = player:get_pack_con()
		if not pack_con then return end
		local gold_jade = money_tree_config.get_give_gold_jade(pkt.cnt)
		if not gold_jade then return end
		local faction = g_faction_mgr:get_faction_by_cid(char_id)
		if not faction then return end
		local gold_level = faction:get_gold_level()
		local multi = money_tree_config.get_addition(gold_level)
		if not multi then return end
		local money = gold_jade * multi
		pack_con:add_money(MoneyType.GIFT_GOLD, money, {['type'] = MONEY_SOURCE.MONEY_TREE})
	end
	g_cltsock_mgr:send_client(char_id, CMD_ROCK_MONEY_TREE_S, pkt)
end

--[[
Sv_commands[0][CMD_SYN_UPDATE_FACTION_COURTYARD_INFO_S] = 
function(conn,char_id,pkt)
	if pkt and pkt.faction_id and pkt.flag then
		g_faction_courtyard_mgr:syn_update_faction_courtyard(pkt)
	end
end
--]]

---------------帮派烧香---------------------
-- 上线获取信息
Clt_commands[1][CMD_GET_GANG_INFO_B] = 
function(conn, pkt)
	debug_print("in CMD_GET_GANG_INFO_B")
	if conn and conn.char_id then
		g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id, CMD_GET_GANG_INFO_M, pkt) -- 获取香炉信息
	end
end

Sv_commands[0][CMD_GET_GANG_INFO_C] = 
function(conn, char_id, pkt)
	debug_print("in CMD_GET_GANG_INFO_C")
	debug_print(j_e(pkt))
	g_cltsock_mgr:send_client(char_id, CMD_GET_GANG_INFO_S, pkt)
end

-- 上香或者拜祭
Clt_commands[1][CMD_WORSHIP_B] = 
function(conn, pkt)
	debug_print("in CMD_WORSHIP_B")
	debug_print(j_e(pkt))
	if conn and conn.char_id and pkt and pkt.act_type then
		g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id, CMD_WORSHIP_M, pkt) -- 上香或者祭拜
	end
end

Sv_commands[0][CMD_WORSHIP_CHECK_C] = 
function(conn, char_id, pkt)
	debug_print("in CMD_WORSHIP_CHECK_C")
	debug_print(j_e(pkt))
	if conn and char_id and pkt and pkt.act_type and pkt.id then
		local player = g_obj_mgr:get_obj(char_id)
		if not player then return end
		debug_print("=================")
		local pack_con = player:get_pack_con()
		if not pack_con then return end
		debug_print("=================")
		debug_print(type(pkt.id))
		local need_money = censer_config.get_price(pkt.id)
		if not need_money then return end
		debug_print("=================")
		local money_list = {}
		money_list[MoneyType.GIFT_JADE] = need_money
		local ret = pkt
		g_sock_event_mgr:set_event_id(char_id, pkt, ret)
		local e_code = pack_con:dec_money_l_inter_face(money_list, {['type']=(MONEY_SOURCE.CENSER)}, 2, nil)
		if e_code ~= 0 then
			local ret = {}
			ret.result = e_code
			return g_cltsock_mgr:send_client(char_id, CMD_WORSHIP_S, ret)
		end
		debug_print("=================")
		g_svsock_mgr:send_server_ex(COMMON_ID,char_id, CMD_WORSHIP_CHECK_S, ret)
	end
end

Sv_commands[0][CMD_WORSHIP_C] = 
function(conn, char_id, pkt)
	debug_print("in CMD_WORSHIP_C")
	debug_print(j_e(pkt))
	if conn and char_id and pkt and pkt.act_type then
		if pkt.result == 0 then
			if pkt.act_type == 0 then
				local t_pkt = {}
				t_pkt.flag = 6
				t_pkt.param = 20 -- 20帮贡
				g_faction_mgr:update_faction_level(char_id, t_pkt) -- 增加帮贡
			elseif pkt.act_type == 1 then -- 上香
				local contribution = censer_config.get_contribution(pkt.id) or 0
				local addition = censer_config.get_addition(pkt.level) or 0
				local t_pkt = {}
				t_pkt.flag = 6
				t_pkt.param = contribution * addition
				debug_print("in CMD_WORSHIP_C", contribution, addition)
				g_faction_mgr:update_faction_level(char_id, t_pkt) -- 增加帮贡
			end
		end
		g_cltsock_mgr:send_client(char_id, CMD_WORSHIP_S, pkt)
	end
end