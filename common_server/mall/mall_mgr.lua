
local debug_print = function() end

local mall_loader = require("mall.mall_loader")

MallMgr = oo.class(nil, "MallMgr")

function MallMgr:__init()
end

function MallMgr:get_list(char_id, pkt)
	local catalog_l = mall_loader.CatalogTable[pkt.catalog]
	if not catalog_l then return end

	local ret = {}
	ret.current_page = pkt.page or 1
	ret.total_page = catalog_l.total_page
	ret.catalog = pkt.catalog
	ret.item_list = catalog_l.page_list[ret.current_page]

	return ret
end


function MallMgr:buy_item(char_id, pkt)
	if pkt == nil or pkt.item_id == nil or pkt.currency == nil or 
	pkt.number <= 0 or pkt.number > 100000 then return end

	pkt.item_id = tonumber(pkt.item_id)
	pkt.number = tonumber(pkt.number)
	pkt.currency = tonumber(pkt.currency)

	local item_info = mall_loader.CatalogTable_item[pkt.item_id]
	if item_info == nil then print(pkt.item_id, "is not exist!") return end

	local t_item_id, t_currency
	if pkt.currency == JADE then  --2 价格等于0的不设置为绑定
		t_item_id = pkt.item_id
		t_currency = JADE
	elseif pkt.currency == GIFT_JADE and item_info.currency == CURRENCY_JADE_AND_GIFT_JADE then   --绑定 3
		local str_id = tostring(pkt.item_id)
		local str_temp_id = string.sub(str_id, 0, -2)
		t_item_id = tonumber(str_temp_id .. "0")
		t_currency = GIFT_JADE
	else
		print(gbk_utf8("不合法的货币类型"))
		return
	end

	--购买
	local item_prace = tonumber(item_info.price[t_currency])
	local item_name = item_info.name
	local ret = {}
	ret.item_id = t_item_id
	ret.number = pkt.number
	ret.item_currency = t_currency
	ret.item_price = item_prace
	ret.item_name = item_name
	ret.day = pkt.day
	ret.line = pkt.line

	ret.openid = pkt.openid
	ret.openkey = pkt.openkey
	ret.serverid = pkt.serverid
	ret.pf = pkt.pf
	ret.pfkey = pkt.pfkey

	--if pkt.day and pkt.item_id then
		--e_code,item_obj = Item_factory.create(tonumber(pkt.item_id))
		--if not item_obj then return end
		--local e_code,price = item_obj:get_cost(tostring(pkt.day),1)
		--if e_code ~= 0 then 
			--return 
		--end	
		--ret.item_price = price
	--end

	if not g_currency_mgr:currency_id_exist(char_id) then
		
		g_currency_mgr:add_currency_id(char_id, ret, char_id, 1)

	end

	return ret
end

function MallMgr:do_buy_item(char_id, pkt)
	if pkt == nil or pkt.item_id == nil or pkt.currency == nil or 
	pkt.number <= 0 or pkt.number > 100000 then return end

	pkt.item_id = tonumber(pkt.item_id)
	pkt.number = tonumber(pkt.number)
	pkt.currency = tonumber(pkt.currency)

	local item_info = mall_loader.CatalogTable_item[pkt.item_id]
	if item_info == nil then print(pkt.item_id, "is not exist!") return end

	local t_item_id, t_currency
	if pkt.currency == 3 and item_info.currency == CURRENCY_JADE_AND_GIFT_JADE then   --绑定 3
		local str_id = tostring(pkt.item_id)
		local str_temp_id = string.sub(str_id, 0, -2)
		t_item_id = tonumber(str_temp_id .. "0")
		t_currency = 3
	else
		print(gbk_utf8("不合法的货币类型"))
		return
	end

	--购买
	local item_prace = tonumber(item_info.price[t_currency] * pkt.number)
	local item_name = item_info.name
	local ret = {}
	ret.item_id = t_item_id
	ret.number = pkt.number
	ret.item_currency = t_currency
	ret.item_price = item_prace
	ret.item_name = item_name
	ret.day = pkt.day
	return ret
end
