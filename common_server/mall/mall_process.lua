
require("mall.mall_loader")
require("mall.mall_mgr")

local mall_benefit_loader = require("mall.mall_benefit_loader")

Sv_commands[0][CMD_MALL_GET_ITEM_LIST_C] = 
function(conn,char_id,pkt)
	local ret = g_mall_mgr:get_list(char_id, pkt)
	g_server_mgr:send_to_server(conn.id,char_id,CMD_MALL_GET_ITEM_LIST_S,ret)
end

Sv_commands[0][CMD_MALL_BUY_ITEM_GIFTJADE_M] = 
function(conn,char_id,pkt)
	pkt.line = conn.id
	local ret = g_mall_mgr:do_buy_item(char_id, pkt)
	g_server_mgr:send_to_server(conn.id,char_id,CMD_MALL_BUY_ITEM_GIFTJADE_C,ret)
end



Sv_commands[0][CMD_MALL_BUY_ITEM_C] = 
function(conn,char_id,pkt)
	pkt.line = conn.id
	local ret = g_mall_mgr:buy_item(char_id, pkt)
	--g_server_mgr:send_to_server(conn.id,char_id,CMD_MALL_BUY_ITEM_S,ret)
end


Sv_commands[0][CMD_MALL_INTEGRAL_BUY_C] = 
function(conn,char_id,pkt)
    if not char_id then
	    return 
	end
	local item_id=pkt.item_id;
	local number=pkt.item_count;
	local price=mall_benefit_loader.CatalogTable_item[tonumber(item_id)].price
	local item_name=mall_benefit_loader.CatalogTable_item[tonumber(item_id)].name
	if not price then print(pkt.item_id, "is not exist!") return end

	local total=price*number 
	local ret = {}
	ret.item_id = item_id
	ret.number = number
	ret.total = total
	ret.item_name = item_name
	ret.price = price
	ret.day = pkt.day
	g_server_mgr:send_to_server(conn.id,char_id,CMD_MALL_INTEGRAL_BUY_S,ret)
end

