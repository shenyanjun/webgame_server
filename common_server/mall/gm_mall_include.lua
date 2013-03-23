

require("mall.gm_mall_mgr")
g_gm_mall = Gm_mall_mgr()

--获取物品
Sv_commands[0][CMD_M2C_GET_GM_MALL_REQ] = 
function(conn,char_id,pkt)
	if not conn.id or not pkt then return end
	local ret = g_gm_mall:get_list(char_id, pkt)
	g_server_mgr:send_to_server(conn.id,char_id,CMD_C2M_GET_GM_MALL_ANS,ret)
end

--购买物品
Sv_commands[0][CMD_M2C_GM_MALL_BUY_ITEM_REQ] =
function(conn ,char_id ,pkt)
	if not conn.id or not pkt then return end
	g_gm_mall:buy_item(conn.id,char_id,pkt)
end