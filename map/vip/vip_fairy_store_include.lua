

local store_config = require("vip.vip_fairy_store_loader")

--购买物品
Clt_commands[1][CMD_MAP_VIP_REMOTE_BUY_C]=
function(conn,pkt) 
	if not conn.char_id or pkt.number==0 then return end
	local ret = {}
	ret.result = 0
	if not store_config.FairyTable[pkt.catalog] then
		ret.result = 60008
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_VIP_REMOTE_BUY_S, ret)
		return 
	end
	local item_l = store_config.FairyTable[pkt.catalog].item_list
	if not item_l then 
		return 
	end
	if not item_l[tostring(pkt.item_id)] or not item_l[tostring(pkt.item_id)].price then 
		ret.result = 60008
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_VIP_REMOTE_BUY_S,ret)		
		return 
	end
	local price = item_l[tostring(pkt.item_id)].price
	local player = g_obj_mgr:get_obj(conn.char_id)
	local pack_con = player:get_pack_con()
	if pack_con:check_money_lock(MoneyType.GOLD) or pack_con:check_money_lock(MoneyType.GIFT_GOLD) then return end --上锁
	local money  = pack_con:get_money()

	local total_money = 0
	local money_type = 0
	local currency = tonumber(pkt.currency)
	if currency == 1 then
		total_money = money.gold
		money_type = 1
	elseif currency == 2 then 
		total_money = money.jade
		money_type =3
	elseif currency == 3 then
		total_money = money.gift_jade
		money_type = 4
	elseif currency == 4 then
		total_money = money.gift_gold
		money_type = 2
	elseif currency == 5 then
		total_money = money.gift_gold+ money.gold
	end

	local need_money = pkt.number*price
	if total_money < need_money then
		ret.result = 27503
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_VIP_REMOTE_BUY_S,ret)
		return 
	end
	if currency==4 then
		pkt.item_id = tonumber(string.sub(tostring(pkt.item_id),1,11).."0")
	end 

	if currency == 5 then
		if need_money <= money.gift_gold then
			pkt.item_id = tonumber(string.sub(tostring(pkt.item_id),1,11).."0")
		end
	end

	local item_l = {}
	item_l[1] = {}
	item_l[1].type = 1
	item_l[1].number = pkt.number
	item_l[1].item_id = pkt.item_id
	if pack_con:add_item_l(item_l,{['type']=ITEM_SOURCE.NPC_BUY}) ~= 0 then
		ret.result = 43017
		g_cltsock_mgr:send_client(conn.char_id,CMD_MAP_VIP_MALL_BUY_S,ret)
		return 
	end 
	if currency == 5 then
		if need_money < money.gift_gold then
			pack_con:dec_money(MoneyType.GIFT_GOLD, need_money, {['type']=MONEY_SOURCE.NPC_BUY})
		else
			local left_money = need_money - money.gift_gold
			pack_con:dec_money(MoneyType.GIFT_GOLD, money.gift_gold, {['type']=MONEY_SOURCE.NPC_BUY})
			pack_con:dec_money(MoneyType.GOLD, left_money, {['type']=MONEY_SOURCE.NPC_BUY})
		end
	else
		pack_con:dec_money(money_type,need_money,{['type']=MONEY_SOURCE.NPC_BUY})
	end


	g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_VIP_REMOTE_BUY_S, ret)
end 



--买回物品
Clt_commands[1][CMD_MAP_VIP_REMOTE_BUY_BACK_C]=
function(conn,pkt) 
	if not conn.char_id then return end

	local player = g_obj_mgr:get_obj(conn.char_id)
	local pack_con = player:get_pack_con()
	if pack_con:check_money_lock(MoneyType.GOLD) then return end --上锁
	local money = pack_con:get_money()
	local item_list = pack_con:get_garbage_item_list()
	
	pkt.slot = pkt.slot-1
	if pack_con:check_item_lock_by_bag_slot(GARBAGE_BAG,pkt.slot) then return end --上锁
	local ret = {}
	ret.result = 0
	if not item_list[pkt.slot] then 
		local _ = g_debug_log and g_debug_log:write("Error:Clt_commands[1][CMD_MAP_VIP_REMOTE_BUY_BACK_C] " .. tostring(pkt.slot))
		return 
	end

	local item_price = item_list[pkt.slot].item:get_sell_price() * item_list[pkt.slot].number * 2
	if money.gold < item_price then
		ret.result = 200008
		g_cltsock_mgr:send_client(conn.char_id,CMD_MAP_VIP_REMOTE_BUY_BACK_S,ret) 
		return
	end

	local grid = item_list[pkt.slot]
	local tmp_list = {}
	tmp_list[1] = {}
	tmp_list[1].type = 2
	tmp_list[1].number = grid.number
	tmp_list[1].item = grid.item
	local err_code = pack_con:add_item_l(tmp_list, {['type']=ITEM_SOURCE.NPC_BUY_BACK})
	if err_code ~= 0 then
		ret.result = err_code
		g_cltsock_mgr:send_client(conn.char_id,CMD_MAP_VIP_REMOTE_BUY_BACK_S,ret) 
		return 
	end

	pack_con:dec_money(MoneyType.GOLD, item_price, {['type']=MONEY_SOURCE.NPC_SALE_BUY})
	pack_con:del_item_by_bag_slot(GARBAGE_BAG, pkt.slot)

 	ret.list = {}
	ret.list[1] = {}
	local item_list = pack_con:get_garbage_item_list() or {}
	for k,v in pairs(item_list) do
		ret.list[1][k] = v.item:serialize_to_net()
		ret.list[1][k].number = v.number
		ret.list[1][k].item_id = v.item:get_item_id()
		ret.list[1][k].slot = k
	end
	g_cltsock_mgr:send_client(conn.char_id,CMD_MAP_VIP_REMOTE_BUY_BACK_S,ret) 
end 


--修理装备
Clt_commands[1][CMD_MAP_VIP_REPAIR_C]=
function(conn,pkt) 
	if not conn.char_id then return end
	local ret = { ["result"] = 0 }
	local player = g_obj_mgr:get_obj(conn.char_id)
	local pack_con = player:get_pack_con()
	local money = 0

	local repair_list = {}
	local cnt = 0
	if pkt and pkt.all == 1 then
		--全部修复
		local equip_l = pack_con:get_equip()
		if equip_l then
			for k,v in pairs(equip_l) do
				money = money + v.item:get_repair_cost()
				cnt = cnt + 1
				repair_list[cnt] = v
			end
		end
	elseif pkt.bag and pkt.slot then
		--修复一个装备
		local equip = pack_con:get_item_by_bag_slot(pkt.bag , pkt.slot)
		if not equip or not equip.item.is_equipment then
			return
		end 
		money = money + equip.item:get_repair_cost()
		cnt = cnt + 1
		repair_list[cnt] = equip
	end
	local e_code = pack_con:dec_gold_gift_and_gold(money, {['type']=MONEY_SOURCE.REPAIR})
	if e_code~=0 then
		return g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_ACTION_REPAIR_ITEM_S, {['result']=e_code})
	end
	pack_con:repair_equip(repair_list)
	g_cltsock_mgr:send_client(conn.char_id,CMD_MAP_VIP_REPAIR_S,ret) 
end 




--出售物品
Clt_commands[1][CMD_MAP_VIP_REMOTE_SALE_C] =
function(conn, pkt)
	if not pkt.bag or not pkt.slot then return end
	local ret = { ["result"] = 0 }
	local player = g_obj_mgr:get_obj(conn.char_id)
	local pack_con = player:get_pack_con()
	if pack_con:check_item_lock_by_bag_slot(pkt.bag,pkt.slot) then return end --上锁
	local grid = pack_con:get_item_by_bag_slot(pkt.bag, pkt.slot)
	if not grid then return end

	local bind_flag = grid.item:get_bind()

	if bind_flag == 0 then  --绑定，铜券
		pack_con:add_money(MoneyType.GIFT_GOLD, grid.item:get_sell_price() * grid.number, {['type']=MONEY_SOURCE.NPC_SELL})
	else
		pack_con:add_money(MoneyType.GOLD, grid.item:get_sell_price() * grid.number, {['type']=MONEY_SOURCE.NPC_SELL})
	end

	pack_con:del_item_by_bag_slot(pkt.bag, pkt.slot, nil, {['type']=ITEM_SOURCE.NPC_SELL})
	pack_con:add_garbage(grid)
 	ret.list = {}

	ret.list[1] = {}
	local item_list = pack_con:get_garbage_item_list() or {}
	for k,v in pairs(item_list) do
		ret.list[1][k] = v.item:serialize_to_net()
		ret.list[1][k].number = v.number
		ret.list[1][k].item_id = v.item:get_item_id()
		ret.list[1][k].slot = k
	end
	g_cltsock_mgr:send_client(conn.char_id,CMD_MAP_VIP_REMOTE_BUY_BACK_S, ret)
		
end


--获取修理装备需要金币
Clt_commands[1][CMD_MAP_VIP_REPAIR_COST_C] =
function(conn, pkt)
	local s_pkt = {}
	s_pkt.result = 0

	local player = g_obj_mgr:get_obj(conn.char_id)
	local pack_con = player:get_pack_con()
	s_pkt.cost = pack_con:get_repair_cost(pkt.all)

	g_cltsock_mgr:send_client(conn.char_id,CMD_MAP_VIP_REPAIR_COST_S, s_pkt)
end


--打开面板
Clt_commands[1][CMD_MAP_VIP_OPEN_STORE_C] =
function(conn, pkt)
	local player = g_obj_mgr:get_obj(conn.char_id)
	local pack_con = player:get_pack_con()
	local item_list = pack_con:get_garbage_item_list()

	local ret = {}
	ret[1] = {}
	local item_list = pack_con:get_garbage_item_list() or {}
	for k,v in pairs(item_list) do
		ret[1][k] = v.item:serialize_to_net()
		ret[1][k].number = v.number
		ret[1][k].item_id = v.item:get_item_id()
		ret[1][k].slot = k
	end
	g_cltsock_mgr:send_client(conn.char_id,CMD_MAP_VIP_OPEN_STORE_S, ret)
end

