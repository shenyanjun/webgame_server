
require("global")
require("global_function")
require("trade.obj_trade")
require("trade.trade_mgr")

local _dis = 10

--发起交易
Clt_commands[1][CMD_MAP_TRADE_REQUEST_C] =
function(conn, pkt)
	if pkt.obj_id == nil then return end

	local new_pkt = {}
	local obj_s = g_obj_mgr:get_obj(conn.char_id)
	local obj_d = g_obj_mgr:get_obj(pkt.obj_id)

	if obj_d == nil or obj_s == nil or conn.char_id == pkt.obj_id then 
		new_pkt.result = 21414
		return g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_TRADE_REQUEST_S, new_pkt)
	end

	--位置判断
	--[[if obj_s:get_map_id() ~= obj_d:get_map_id() or f_distance(obj_s:get_pos(), obj_d:get_pos()) > 10 then
		new_pkt.result = 21404
		return g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_TRADE_REQUEST_S, new_pkt)
	end]]

	--死亡判断
	if not obj_s:is_alive() or not obj_d:is_alive() then
		new_pkt.result = 21409
		return g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_TRADE_REQUEST_S, new_pkt)
	end

	--是否已经在交易
	local trade_id_s = obj_s:get_trade()
	local trade_id_d = obj_d:get_trade()
	local trade_obj_s = g_trade_mgr:get_trade_obj(trade_id_s)
	local trade_obj_d = g_trade_mgr:get_trade_obj(trade_id_d)
	if (trade_obj_s ~= nil and trade_obj_s:get_state() >=TRADE_START) or
	(trade_obj_d ~= nil and trade_obj_d:get_state() >= TRADE_START) then
		new_pkt.result = 21412
		return g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_TRADE_REQUEST_S, new_pkt)
	end

	--交易
	local trade_obj = g_trade_mgr:create_trade(obj_s, obj_d)
	new_pkt.result = 0
	new_pkt.obj_id = pkt.obj_id
	new_pkt.trade_id = trade_obj:get_id()
	g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_TRADE_REQUEST_S, new_pkt)

	local new_pkt = {}
	new_pkt.obj_id = obj_s:get_id()
	new_pkt.trade_id = trade_obj:get_id()
	new_pkt.name = obj_s:get_name()
	g_cltsock_mgr:send_client(pkt.obj_id, CMD_MAP_TRADE_ASK_S, new_pkt)
end

--接受交易
Clt_commands[1][CMD_MAP_TRADE_ACCEPT_C] =
function(conn, pkt)
	local obj_s = g_obj_mgr:get_obj(conn.char_id)
	if obj_s == nil then return end

	local trade_id = obj_s:get_trade()
	local trade_obj = g_trade_mgr:get_trade_obj(trade_id)
	if trade_obj ~= nil and trade_obj:get_state() == TRADE_PREPARE then
		local list = trade_obj:get_member()
		local obj_d = g_obj_mgr:get_obj(trade_obj:get_other_obj_id(conn.char_id))
		if obj_d == nil then 
			g_trade_mgr:del_trade(trade_id)
			return 
		end

		--位置判断
		--[[if obj_s:get_map_id() ~= obj_d:get_map_id() or f_distance(obj_s:get_pos(), obj_d:get_pos()) > 10 then
			return 
		end]]
		--死亡判断
		if not obj_s:is_alive() or not obj_d:is_alive() then
			g_trade_mgr:del_trade(trade_id)
			return
		end

		trade_obj:set_state(TRADE_START)
		local new_pkt = {}
		new_pkt.trade_id = trade_id
		new_pkt.sour_id = obj_s:get_id()
		new_pkt.sour_name= obj_s:get_name()
		new_pkt.des_id= obj_d:get_id()
		new_pkt.des_name= obj_d:get_name()
		g_cltsock_mgr:send_client(list[1], CMD_MAP_TRADE_START_S, new_pkt)
		g_cltsock_mgr:send_client(list[2], CMD_MAP_TRADE_START_S, new_pkt)
	end
end

--拒绝交易
Clt_commands[1][CMD_MAP_TRADE_REFUSE_C] =
function(conn, pkt)
	local obj_s = g_obj_mgr:get_obj(conn.char_id)
	if obj_s == nil then return end

	local trade_id = obj_s:get_trade()
	local trade_obj = g_trade_mgr:get_trade_obj(trade_id)
	if trade_obj ~= nil then
		local list = trade_obj:get_member()
		local new_pkt = {}
		new_pkt.obj_id = conn.char_id
		new_pkt.trade_id = trade_id
		g_cltsock_mgr:send_client(list[1], CMD_MAP_TRADE_REFUSE_S, new_pkt)
		g_cltsock_mgr:send_client(list[2], CMD_MAP_TRADE_REFUSE_S, new_pkt)

		g_trade_mgr:del_trade(trade_id)
	end
end

--取消交易
Clt_commands[1][CMD_MAP_TRADE_CANCEL_C] =
function(conn, pkt)
	--print("99999999999999999999999999999999999999999999999999999")
	local obj_s = g_obj_mgr:get_obj(conn.char_id)
	if obj_s == nil then return end

	local trade_id = obj_s:get_trade()
	local trade_obj = g_trade_mgr:get_trade_obj(trade_id)
	if trade_obj ~= nil then
		local list = trade_obj:get_member()
		local new_pkt = {}
		new_pkt.obj_id = conn.char_id
		new_pkt.trade_id = trade_id
		g_cltsock_mgr:send_client(list[1], CMD_MAP_TRADE_CANCEL_S, new_pkt)
		g_cltsock_mgr:send_client(list[2], CMD_MAP_TRADE_CANCEL_S, new_pkt)

		g_trade_mgr:del_trade(trade_id)
	end
end

--锁定交易
Clt_commands[1][CMD_MAP_TRADE_LOCK_C] =
function(conn, pkt)
	if pkt.item_l == nil or pkt.money_l == nil then return end

	--print("@@@@@@@@@CMD_MAP_TRADE_LOCK_C1")
	local obj_s = g_obj_mgr:get_obj(conn.char_id)
	if obj_s == nil then return end

	local trade_id = obj_s:get_trade()
	local trade_obj = g_trade_mgr:get_trade_obj(trade_id)
	if trade_obj ~= nil and trade_obj:get_state() == TRADE_START then
		--print("@@@@@@@@@CMD_MAP_TRADE_LOCK_C2")
		local obj_d = g_obj_mgr:get_obj(trade_obj:get_other_obj_id(conn.char_id))
		if obj_d == nil then return end

		--判断物品
		local new_pkt = {}
		new_pkt.item_l = {}
		new_pkt.money_l = {}

		local pack_con = obj_s:get_pack_con()
		for k, v in ipairs(pkt.item_l) do
			local item = pack_con:get_item_by_uuid(v.uuid)
			if item == nil or item.item:get_bind() == 0 then
				g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_TRADE_LOCK_S, {["result"]=21402})
				g_trade_mgr:del_trade(trade_id)
				return
			end
			local tmp_pkt = {}
			tmp_pkt["index"] = v.index
			tmp_pkt["item_id"] = item.item_id
			tmp_pkt["item_obj"] = item.item:serialize_to_net()
			tmp_pkt["number"] = item.number
			table.insert(new_pkt.item_l, tmp_pkt)

			v.number = item.number   --保存数目
		end

		new_pkt.money_l.gold = pkt.money_l.gold or 0
		--new_pkt.money_l.jade = pkt.money_l.jade or 0

		if new_pkt.money_l.gold < 0 then   --判断
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_TRADE_LOCK_S, {["result"]=ret})
			g_cltsock_mgr:send_client(obj_d:get_id(), CMD_MAP_TRADE_LOCK_S, {["result"]=ret})
			g_trade_mgr:del_trade(trade_id)
			return
		end

		--锁定
		local ret = trade_obj:lock_item_l(conn.char_id, pkt)
		--print("&&&&&&&&&&&&&&&&&&trade_obj:lock_item_l", ret)
		if ret ~= 0 then
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_TRADE_LOCK_S, {["result"]=ret})
			g_cltsock_mgr:send_client(obj_d:get_id(), CMD_MAP_TRADE_LOCK_S, {["result"]=ret})
			g_trade_mgr:del_trade(trade_id)
			return
		end

		--print("@@@@@@@@@CMD_MAP_TRADE_LOCK_C4")
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_TRADE_LOCK_S, {["result"]=0})
		g_cltsock_mgr:send_client(obj_d:get_id(), CMD_MAP_TRADE_LOCK_SYN, new_pkt)

		if trade_obj:get_state() == TRADE_LOCK then
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_TRADE_LAST_S, {})
			g_cltsock_mgr:send_client(obj_d:get_id(), CMD_MAP_TRADE_LAST_S, {})
		end
	end
end

--交易
Clt_commands[1][CMD_MAP_TRADE_OK_C] =
function(conn, pkt)
	local obj_s = g_obj_mgr:get_obj(conn.char_id)
	if obj_s == nil then return end

	local trade_id = obj_s:get_trade()
	local trade_obj = g_trade_mgr:get_trade_obj(trade_id)
	if trade_obj ~= nil and trade_obj:get_state() == TRADE_LOCK then
		if not trade_obj:ok(conn.char_id) then
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_TRADE_OK_S, {["result"]=21402})
			g_trade_mgr:del_trade(trade_id)
			return
		end

		if trade_obj:get_state() == TRADE_OK then
			local des_id = trade_obj:get_other_obj_id(conn.char_id)
			local s_list = {}
			s_list.item_list = {}
			s_list.money_list = {}

			local s_pack_con = obj_s:get_pack_con()
			local d_player = g_obj_mgr:get_obj(des_id)
			local d_pack_con = d_player:get_pack_con()

			local s_item_l = trade_obj:get_item_l(conn.char_id)
			for k,v in pairs(s_item_l.item_l or {}) do
				s_list.item_list[k] = {}
				s_list.item_list[k]["uid"] = v.uuid
				s_list.item_list[k]["count"] = v.number
			end
			s_list.money_list.gold = s_item_l.money_l and s_item_l.money_l.gold or 0
			--s_list.money_list.jade = s_item_l.money_l and s_item_l.money_l.jade or 0
			if s_list.money_list.gold > 0 then
				if s_pack_con:check_money_lock(MoneyType.GOLD) then
					g_trade_mgr:del_trade(trade_id)
					return
				end
			end
			local d_list = {}
			d_list.item_list = {}
			d_list.money_list = {}
			
			local d_item_l = trade_obj:get_item_l(des_id)
			for k,v in pairs(d_item_l.item_l or {}) do
				d_list.item_list[k] = {}
				d_list.item_list[k]["uid"] = v.uuid
				d_list.item_list[k]["count"] = v.number
			end
			d_list.money_list.gold = d_item_l.money_l and d_item_l.money_l.gold or 0
			--d_list.money_list.jade = d_item_l.money_l and d_item_l.money_l.jade or 0
			if d_list.money_list.gold > 0 then
				if d_pack_con:check_money_lock(MoneyType.GOLD) then
					g_trade_mgr:del_trade(trade_id)
					return
				end
			end
			local ret = f_trade_each_other(conn.char_id, s_list, des_id, d_list)
			if not ret then

			elseif ret == 43060 then
				g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_TRADE_OK_S, {["result"]=43060})
				g_cltsock_mgr:send_client(des_id, CMD_MAP_TRADE_OK_S, {["result"]=43004})
			elseif ret == 43004 then
				g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_TRADE_OK_S, {["result"]=ret})
				g_cltsock_mgr:send_client(des_id, CMD_MAP_TRADE_OK_S, {["result"]=43060})
			else
				g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_TRADE_OK_S, {["result"]=ret})
				g_cltsock_mgr:send_client(des_id, CMD_MAP_TRADE_OK_S, {["result"]=ret})
			end
			g_trade_mgr:del_trade(trade_id)

		end
	end
end


--玩家退出时取消交易
function f_trade_cancel(obj_id)
	local obj_s = g_obj_mgr:get_obj(obj_id)
	if obj_s == nil then return end

	local trade_id = obj_s:get_trade()
	local trade_obj = g_trade_mgr:get_trade_obj(trade_id)
	if trade_obj ~= nil then
		local des_id = trade_obj:get_other_obj_id(obj_id)
		local new_pkt = {}
		new_pkt.obj_id = des_id
		new_pkt.trade_id = trade_id
		g_cltsock_mgr:send_client(des_id, CMD_MAP_TRADE_CANCEL_S, new_pkt)

		g_trade_mgr:del_trade(trade_id)
	end
end

--交易物品
function f_trade_each_other(s_id, s_trade_list, d_id, d_trade_list)
	--print("s_id, d_id", s_id, d_id)
	--print("s_trade_list,  d_trade_list", j_e(s_trade_list),  j_e(d_trade_list))

	if not s_id or not d_id then return 21402 end
	local s_player = g_obj_mgr:get_obj(s_id)
	local d_player = g_obj_mgr:get_obj(d_id)

	if not s_player or not d_player then return 21402 end

	local s_pack_con = s_player:get_pack_con()
	local d_pack_con = d_player:get_pack_con()

	--源方物品是否合法
	local s_del_id_list = {}

	local s_item_id_list = {}
	local me_item_count = 1
	for k, v in pairs(s_trade_list.item_list) do
		local s_item = s_pack_con:get_item_by_uuid(v.uid)
		if not s_item then return 21402 end
		if s_item.number ~= v.count then return 21402 end
		if s_pack_con:check_item_lock_by_item_uuid(v.uid) then
			return false
		end
		s_item_id_list[me_item_count] = {}
		s_item_id_list[me_item_count].type = 2
		--s_item_id_list[me_item_count].item_id = s_item.item_id
		s_item_id_list[me_item_count].number = s_item.number
		s_item_id_list[me_item_count].item = s_item.item

		s_del_id_list[me_item_count] = {}
		s_del_id_list[me_item_count].bag = s_item.bag
		s_del_id_list[me_item_count].slot = s_item.slot

		me_item_count = me_item_count + 1
	end

	--print("s_item_id_list>>>>", j_e(s_item_id_list))

	local s_gold = s_trade_list.money_list.gold
	
	local s_money = s_pack_con:get_money()
	if s_gold > 0 then
		if s_gold > s_money.gold then return 21402 end
	end

	-------------------------------------------------------------------------
	--目的方物品是否合法
	local d_del_id_list = {}

	local d_item_id_list = {}
	local his_item_count = 1
	for k, v in pairs(d_trade_list.item_list) do
		local d_item = d_pack_con:get_item_by_uuid(v.uid)
		if not d_item then return 21402 end
		if d_item.number ~= v.count then return 21402 end
		if d_pack_con:check_item_lock_by_item_uuid(v.uid) then
			return false
		end

		d_item_id_list[his_item_count] = {}
		--d_item_id_list[his_item_count].item_id = d_item.item_id
		d_item_id_list[his_item_count].type = 2
		d_item_id_list[his_item_count].number = d_item.number
		d_item_id_list[his_item_count].item = d_item.item

		d_del_id_list[his_item_count] = {}
		d_del_id_list[his_item_count].bag = d_item.bag
		d_del_id_list[his_item_count].slot = d_item.slot

		his_item_count = his_item_count + 1
	end

	--print("d_item_id_list>>>>", j_e(d_item_id_list))

	local d_gold = d_trade_list.money_list.gold

	local d_money = d_pack_con:get_money()

	if d_gold and d_gold > 0 then
		if d_gold > d_money.gold then return 21402 end
	end

	-------------------------------------------------------------------------
	--双方背包是否满
	local s_free_slot = s_pack_con:get_bag_free_slot_cnt()
	if table.getn(d_item_id_list) > s_free_slot then return 43004 end

	local d_free_count = d_pack_con:get_bag_free_slot_cnt()
	if table.getn(s_item_id_list) > d_free_count then return 43060 end

	-------------------------------------------------------------------------
	--条件満足(交易)
	--先删除物品
	local pkt_s = {}
	for k, v in pairs(s_del_id_list) do
		pkt_s[k] = {}
		pkt_s[k][1] = v.bag
		pkt_s[k][2] = v.slot
		--s_pack_con:del_item_by_bag_slot(v.bag, v.slot, nil, {['type']=ITEM_SOURCE.TRADE_BTW_PLAYERS})
	end
	s_pack_con:del_item_by_bags_slots(pkt_s,{['type']=ITEM_SOURCE.TRADE_BTW_PLAYERS},nil)


	local s_ret = s_pack_con:add_item_l(d_item_id_list, {['type']=ITEM_SOURCE.TRADE_BTW_PLAYERS})
	if s_ret ~= 0 then return 21402 end

	local pkt_d = {}
	for k, v in pairs(d_del_id_list) do
		pkt_d[k] = {}
		pkt_d[k][1] = v.bag
		pkt_d[k][2] = v.slot
		--d_pack_con:del_item_by_bag_slot(v.bag, v.slot, nil, {['type']=ITEM_SOURCE.TRADE_BTW_PLAYERS})
	end
	d_pack_con:del_item_by_bags_slots(pkt_d,{['type']=ITEM_SOURCE.TRADE_BTW_PLAYERS},nil)


	local d_ret = d_pack_con:add_item_l(s_item_id_list, {['type']=ITEM_SOURCE.TRADE_BTW_PLAYERS})
	if d_ret ~= 0 then return 21402 end

	--交易金钱
	if d_gold and d_gold > 0 then
		s_pack_con:add_money(MoneyType.GOLD, d_gold, {['type']=MONEY_SOURCE.GAIN_TRADE})
		d_pack_con:dec_money(MoneyType.GOLD, d_gold, {['type']=MONEY_SOURCE.PAY_TRADE})
	end

	if s_gold and s_gold > 0 then
		d_pack_con:add_money(MoneyType.GOLD, s_gold, {['type']=MONEY_SOURCE.GAIN_TRADE})
		s_pack_con:dec_money(MoneyType.GOLD, s_gold, {['type']=MONEY_SOURCE.PAY_TRADE})
	end

	local s_serialized_item_list = f_serialize_itemlist(s_item_id_list)
	local d_serialized_item_list = f_serialize_itemlist(d_item_id_list)
	local str = string.format("insert into log_trade set buyer_id =%d ,buyer_name = '%s',seller_id = %d,seller_name = '%s',time =%d,buyer_obj = '%s',seller_obj= '%s',buyer_money = '%s',seller_money = '%s',buyer_account = '%s',seller_account = '%s'",
				s_id,s_player:get_name(),d_id,d_player:get_name(),ev.time,Json.Encode(s_serialized_item_list),Json.Encode(d_serialized_item_list),Json.Encode(s_trade_list.money_list),Json.Encode(d_trade_list.money_list),s_player:get_account_id(),d_player:get_account_id())
	f_multi_web_sql(str)


	return 0
end