--建帮令和金币数量
local debug_print=print
local DEL_GOLD = 10000
local YINBI_COUNT = 100
--local src_log = {}
--src_log.type = ITEM_SOURCE.FACTION

Sv_commands[0][CMD_C2M_QUERY_CHECK_REQ] =
	function(conn, char_id, pkt)
		debug_print("CMD_M2C_DEL_FACTION_SYMBOL_REQ",char_id)

		local player = g_obj_mgr:get_obj(char_id)
		if not player then return end
		local pack_con = player:get_pack_con()

		local nobind_id = 103050000121
		local bind_id = 103050000120

		local money = pack_con:get_money()
		local s_pkt = {}
		s_pkt.result = 0
		local gold = tonumber(money.gold)
		--if gold < DEL_GOLD then 
			--s_pkt.result = 26006 
			--g_svsock_mgr:send_server_ex(WORLD_ID, char_id, CMD_C2M_QUERY_CHECK_REP, s_pkt)
			--return
		--end

		local count = pack_con:get_item_count(nobind_id) + pack_con:get_item_count(bind_id)
		if count == 0 then 
			s_pkt.result = 26005 
			g_svsock_mgr:send_server_ex(WORLD_ID, char_id, CMD_C2M_QUERY_CHECK_REP, s_pkt)
			return
		end

		local bind_id = 103050000120
		pack_con:del_item_by_item_id_bind_first(bind_id, 1, {['type']=ITEM_SOURCE.FACTION})
		--pack_con:dec_money(MoneyType.GOLD, DEL_GOLD, {['type']=MONEY_SOURCE.FACTION})
		
		g_svsock_mgr:send_server_ex(WORLD_ID, char_id, CMD_C2M_QUERY_CHECK_REP, s_pkt)

		local str = ev.time_str .. " char_id:" ..char_id .. " create faction and del_item_id" .. bind_id
		g_faction_log:write(str)
	end

--银币数量
Sv_commands[0][CMD_C2M_QUERY_YINBI_REQ] =
	function(conn, char_id, pkt)
		debug_print("CMD_C2M_QUERY_YINBI_REQ")

		local player = g_obj_mgr:get_obj(char_id)
		if not player then return end
		local pack_con = player:get_pack_con()

		local money = pack_con:get_money()
		local s_pkt = {}
		s_pkt.result = 0
		local count  = tonumber(money.gold)
		if count < YINBI_COUNT then
			s_pkt.result = 26020
			g_svsock_mgr:send_server_ex(WORLD_ID, char_id, CMD_C2M_QUERY_YINBI_REP, s_pkt)
			return
		end
		
		pack_con:dec_money(MoneyType.GOLD, YINBI_COUNT, {['type']=MONEY_SOURCE.FACTION_RECRUIT})
		g_svsock_mgr:send_server_ex(WORLD_ID, char_id, CMD_C2M_QUERY_YINBI_REP, s_pkt)

		local str = ev.time_str .. " char_id:" ..char_id .. "花费 gold:" .. YINBI_COUNT
		g_faction_log:write(str)
	end
