


local integral_func=require("mall.integral_func")


--功能：领取福利
--参数：客户端socket，数据包pkt
--返回：成功0/失败-1
Clt_commands[1][CMD_MAP_MALL_GET_BONUS_C]=
function(conn,pkt) 
    if not conn.char_id then
	    debug_print("char_id is nil...") 
		return -1 
	end 
	local ret=integral_func.exchange_bonus(conn.char_id) 

	local retpkt={} 
	retpkt.result=ret 
	g_cltsock_mgr:send_client(conn.char_id,CMD_MAP_MALL_GET_BONUS_S,retpkt) 
end 


--功能：领取积分
--参数：客户端socket，数据包pkt
--返回：成功0/失败-1
Clt_commands[1][CMD_MAP_MALL_BONUS_C]=
function(conn,pkt) 
    if not conn.char_id then
	    debug_print("char_id is nil...") 
		return -1 
	end 
	local total = integral_func.get_jade(conn.char_id) 

	local retpkt={}
	retpkt.result = 0 
	retpkt.count = total

	if total <= 0 then
	    retpkt.result = 60002
	end

	g_cltsock_mgr:send_client(conn.char_id,CMD_MAP_MALL_BONUS_S,retpkt)
end 