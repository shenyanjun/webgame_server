

--打开积分兑换面板
Sv_commands[0][CMD_M2C_EXCHANGE_GIFT_INFO_REQ] = 
function(conn,char_id,pkt)
	local ret = {}
	local tmp = g_integral_exchange_mgr:get_info(char_id)
	ret.date_jade = tmp.date_jade
	ret.week_jade = tmp.week_jade
	ret.month_jade = tmp.month_jade
	g_server_mgr:send_to_server(conn.id,char_id,CMD_C2M_EXCHANGE_GIFT_INFO_ANS,ret)
end

--更新
Sv_commands[0][CMD_M2C_EXCHANGE_GIFT_UPDATE_REQ] =
function(conn,char_id,pkt)	
	local ret = {}
	ret.result = 0
	ret.list = g_integral_exchange_mgr:get_exchange_times(char_id)
	g_server_mgr:send_to_server(conn.id,char_id,CMD_C2M_EXCHANGE_GIFT_UPDATE_ANS,ret)
end


--积分兑换
Sv_commands[0][CMD_M2C_EXCHANGE_GIRF_REQ] = 
function(conn,char_id,pkt)
	local ret  = {}
	ret = g_integral_exchange_mgr:exchange_gift(char_id,pkt)
	g_server_mgr:send_to_server(conn.id,char_id,CMD_C2M_EXCHANGE_GIRF_ANS,ret)
end


--充值
Sv_commands[0][CMD_M2C_EXCHANGE_GIFT_ADD_MOENY_REQ] = 
function(conn,char_id,pkt)
	if not pkt then return end
	g_integral_exchange_mgr:add_jade(conn.id,pkt.char_id,pkt.money)
end


--加个数
Sv_commands[0][CMD_M2C_EXCHANGE_GIFT_ADD_COUNTS_REQ] = 
function(conn,char_id,pkt)
	if not char_id or not pkt then return end
	g_integral_exchange_mgr:add_exchange_times(conn.id,char_id,pkt.catalog,pkt.id,1)
end
