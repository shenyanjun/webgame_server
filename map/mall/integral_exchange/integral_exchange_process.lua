local debug_print = print

--打开积分兑换面板
Clt_commands[1][CMD_MAP_EXCHANGE_JADE_GIFT_INFO_C] = 
function(conn,pkt)
	if not conn.char_id then return end
	g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id,CMD_M2C_EXCHANGE_GIFT_INFO_REQ,pkt)
end

Sv_commands[0][CMD_C2M_EXCHANGE_GIFT_INFO_ANS] = 
function(conn,char_id,pkt)
	local player = g_obj_mgr:get_obj(char_id)
	if not player then return end
	local pack_con = player:get_pack_con()
	local money = pack_con:get_money()
	local ret = {}
	ret.date_jade = pkt.date_jade
	ret.week_jade = pkt.week_jade
	ret.month_jade = pkt.month_jade
	ret.integral = money.integral
	ret.result = 0
	g_cltsock_mgr:send_client(char_id,CMD_MAP_EXCHANGE_JADE_GIFT_INFO_S,ret)
end

--更新
Clt_commands[1][CMD_MAP_EXCHANGE_JADE_GIFT_UPDATE_C] =
function(conn,pkt)
	if not conn.char_id then return end
	g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id,CMD_M2C_EXCHANGE_GIFT_UPDATE_REQ,pkt)
end

Sv_commands[0][CMD_C2M_EXCHANGE_GIFT_UPDATE_ANS] = 
function(conn,char_id,pkt)
	local ret = {}
	ret = pkt
	g_cltsock_mgr:send_client(char_id,CMD_MAP_EXCHANGE_JADE_GIFT_UPDATE_S,ret)
end


--积分兑换
Clt_commands[1][CMD_MAP_EXCHANGE_JADE_GIFT_C] = 
function(conn,pkt)
	if not conn.char_id or not pkt then return end
	g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id,CMD_M2C_EXCHANGE_GIRF_REQ,pkt)
end

Sv_commands[0][CMD_C2M_EXCHANGE_GIRF_ANS] = 
function(conn,char_id,pkt)
	if not pkt then debug_print("=========") return end
	local ret  = {}
	ret = pkt
	if ret.result ~= 0  then
		g_cltsock_mgr:send_client(char_id,CMD_MAP_EXCHANGE_JADE_GIFT_S,ret)
		return 
	end
	local player = g_obj_mgr:get_obj(char_id)
	local pack_con = player:get_pack_con()
	local money = pack_con:get_money()
	--积分不够
	if money.integral < pkt.need_integral then
		ret.result = 60011
		g_cltsock_mgr:send_client(char_id,CMD_MAP_EXCHANGE_JADE_GIFT_S,ret)
		return 
	end
	--加礼券，减积分
	pack_con:add_money(MoneyType.GIFT_JADE,pkt.exchange_gift,{['type'] = MONEY_SOURCE.EXCHANGE_GIFT})
	pack_con:dec_money(MoneyType.INTEGRAL,pkt.need_integral,{['type'] = MONEY_SOURCE.EXCHANGE_GIFT})
	--公共服加数量
	local new_pkt = {}
	new_pkt.catalog = pkt.catalog
	new_pkt.id = pkt.id
	g_svsock_mgr:send_server_ex(COMMON_ID,char_id,CMD_M2C_EXCHANGE_GIFT_ADD_COUNTS_REQ,new_pkt)
	ret = {}
	ret.result = 0
	g_cltsock_mgr:send_client(char_id,CMD_MAP_EXCHANGE_JADE_GIFT_S,ret)
end

