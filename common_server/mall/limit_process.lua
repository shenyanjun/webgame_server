require("mall.limit_mgr")

Sv_commands[0][CMD_MALL_GET_LIMIT_ITEM_C] = 
function(conn,char_id,pkt)
	local ret = g_limit_mgr:get_list(char_id, pkt)
	g_server_mgr:send_to_server(conn.id,char_id,CMD_MALL_GET_LIMIT_ITME_S,ret)
end



Sv_commands[0][CMD_MALL_BUY_LIMIT_ITEM_C] = 
function(conn,char_id,pkt)
	pkt.line = conn.id

	local ret = g_limit_mgr:buy_item(char_id, pkt)
	if ret then
		g_server_mgr:send_to_server(conn.id,char_id,CMD_MALL_BUY_LIMIT_ITEM_S,ret)
	end
end


Sv_commands[0][CMD_MALL_BUY_LIMIT_ITEM_REQ] = 
function(conn,char_id,pkt)
	g_currency_mgr:currency_success(char_id, pkt)
	if pkt.result == 0 then
		local ret = g_limit_mgr:dec_item(char_id, pkt)
		g_server_mgr:send_to_server(conn.id,char_id,CMD_MALL_BUY_LIMIT_ITEM_ANS, ret)
	end
end