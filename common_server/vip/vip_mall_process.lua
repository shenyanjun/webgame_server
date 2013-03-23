

local vip_mall_config = require("vip.vip_mall_loader")

Sv_commands[0][CMD_MALL_VIP_BUY_ITEM_REQ] = 
function(conn,char_id,pkt)
	local ret = {}
	ret.error = 0

	local vip_type = pkt.catalog
	if not vip_mall_config.VipMallTable[vip_type] then
		ret.error = 60008
		g_server_mgr:send_to_server(conn.id,char_id,CMD_MALL_VIP_BUY_ITEM_ANS,ret)
	end
	
	
	local item_list = vip_mall_config.VipMallTable[vip_type].item_list[tostring(pkt.item_id)]
	if not item_list then
		ret.error = 60008
		g_server_mgr:send_to_server(conn.id,char_id,CMD_MALL_VIP_BUY_ITEM_ANS,ret)
	end

	local price = item_list.price
	if not price then
		ret.error = 60008
		g_server_mgr:send_to_server(conn.id,char_id,CMD_MALL_VIP_BUY_ITEM_ANS,ret)
	end

	local name = item_list.name
	local total = price*pkt.number
	--print("31 =", j_e(item_list))
	
	--local item_obj,e_code
	--if pkt.day and pkt.item_id then
		--local item_id = tonumber(pkt.item_id)
		--item_id  = tonumber(string.sub(tostring(item_id),1,11).."1")

		--e_code,item_obj = Item_factory.create(tonumber(item_id))
		--if not item_obj then return end
		--
		--e_code,price = item_obj:get_cost(tostring(pkt.day),1)
		--if e_code ~= 0 then
			--g_server_mgr:send_to_server(conn.id,char_id, CMD_MALL_VIP_BUY_ITEM_ANS,{error = e_code})	
			--return
		--end

		--total = price*number
	--end

	ret.currency = pkt.currency
	ret.total = total
	ret.price = price
	ret.name = name
	ret.number = pkt.number
	ret.item_id = pkt.item_id
	ret.day = pkt.day
	for k, v in pairs(pkt) do
		ret[k] = v
	end

	ret.line = conn.id

	if not g_currency_mgr:currency_id_exist(char_id) then
		
		g_currency_mgr:add_currency_id(char_id, ret, char_id, 7)
	else
		
		g_server_mgr:send_to_server(conn.id,char_id, CMD_MALL_VIP_BUY_ITEM_ANS,{error = 20509})	
		return 

	end

	--g_server_mgr:send_to_server(conn.id,char_id,CMD_MALL_VIP_BUY_ITEM_ANS,ret)
end

Sv_commands[0][CMD_M2C_SYS_VIP_INFO] = 
function(conn,char_id,pkt)
	if pkt and pkt.endtime and pkt.cardtype then
		g_vip_play_inf:update_vip_list(char_id,pkt.endtime,pkt.cardtype)
	end
end
