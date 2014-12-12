
--local debug_print = print
local debug_print = function() end
local npc_exchange = require("npc.config.npc_exchange_loader")

--npc兑换功能请求
Clt_commands[1][CMD_NPC_EXCHANGE_LIST_C] =
	function(conn, pkt)
		local player = g_obj_mgr:get_obj(conn.char_id)
		if not pkt.action_id or not player then return end

		local npc = NpcContainerMgr:GetContactNpcWithPlayer(conn.char_id)
		if not npc then
			NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_NOT_FOUND)
			return
		end
		if not npc:CanContactWithPlayer(player) then
			NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_TOO_FAR)
			return
		end

		local action = npc:GetActionById(pkt.action_id)
		if not action then
			NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_HAS_NOT_ACTION)
			return
		end

		local ret = {}
		ret.action_id = pkt.action_id
		ret.exchange_list = {}
		if action.exchange_list then
			for k, v in pairs(action.exchange_list) do
				ret.exchange_list[k] = {}
				ret.exchange_list[k]["name"] = v.name
				ret.exchange_list[k]["list"] = {}
				for m=1, table.getn(v) do
					ret.exchange_list[k]["list"][m]	= v[m]
				end
			end
		end

		g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_EXCHANGE_LIST_S, ret)
	end

--npc兑换物品
Clt_commands[1][CMD_NPC_EXCHANGE_C] =
	function(conn, pkt)
		if not pkt or not pkt.exc_id or not pkt.count or pkt.count < 1 then return end
		local s_pkt = {}
		s_pkt.result = f_npc_exchange(conn.char_id, pkt.exc_id, pkt.count)
		g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_EXCHANGE_S, s_pkt)
	end


--npc兑换功能接口
function f_npc_exchange(char_id, exc_id, count)
	if not char_id or not exc_id then return end
	local player = g_obj_mgr:get_obj(char_id)
	local pack_con = player:get_pack_con()
	if pack_con:check_money_lock(MoneyType.GOLD) or pack_con:check_money_lock(MoneyType.GIFT_GOLD) then return end --上锁
	if pack_con:check_money_lock(MoneyType.JADE) or pack_con:check_money_lock(MoneyType.GIFT_JADE) then return end --上锁
	local exchage_obj = npc_exchange.NpcExchage[exc_id]  --f_build_npc_exchange(exc_id)
	if not exchage_obj then return end

	--暂时屏幕one_rank等级排名
	if exchage_obj.one_rank and exchage_obj.one_rank > 0 then
		return 200041
	end
	if exchage_obj.three_rank and exchage_obj.three_rank > 0 then
		return 200041
	end

	--收集的金钱是否満足
	local money = pack_con:get_money()
	local s_gift_gold = count * exchage_obj.coll_money_list.gift_gold
	local s_gift_jade = count * exchage_obj.coll_money_list.gift_jade
	local s_jade = count * exchage_obj.coll_money_list.jade
	local s_gold = count * exchage_obj.coll_money_list.gold

	if s_gift_gold > 0 then
		if money.gift_gold < s_gift_gold then
			return 200040
		end
	end
	if s_gift_jade > 0 then
		if money.gift_jade < s_gift_jade then
			return 200040
		end
	end
	if s_jade > 0 then
		if money.jade < s_jade then
			return 200040
		end
	end
	if s_gold > 0 then
		if money.gold < s_gold then
			return 200040
		end
	end

	--背包是否存在需要收集的物品
	for k, v in pairs(exchage_obj.coll_item_list) do
		if pack_con:get_all_item_count(v.item_id) < count * v.count then --get_item_count
			return 200041
		end
	end
	--背包是否已満
	local tmp_list = {}
	local i = 0
	for k, v in pairs(exchage_obj.exc_item_list) do
		i = i + 1
		tmp_list[i] = {}

		local err_code,item = Item_factory.create(v.item_id)
		if err_code ~= 0 then return end
		if item:is_fashion() and v.expire_time then
			item:set_last_time(v.expire_time)
		end

		tmp_list[i].type = 2
		tmp_list[i].item = item
		tmp_list[i].number = v.count * count

	end
	if i ~= 0 and pack_con:check_add_item_l_inter_face(tmp_list) ~= 0 then
		return 43004
	end

	--条件満足(兑换)
	pack_con:add_item_l(tmp_list, {['type']=ITEM_SOURCE.NPC_EXCHANGE})

	for _, item in pairs(exchage_obj.coll_item_list) do
		pack_con:del_item_by_item_id_bind_first(item.item_id, item.count *  count, {['type']=ITEM_SOURCE.PAY_NPC_EXCHANGE})
	end

	--兑换金钱
	if s_gift_gold > 0 then
		pack_con:dec_money(MoneyType.GIFT_GOLD, s_gift_gold, {['type']=MONEY_SOURCE.PAY_NPC_EXCHANGE})
	end
	if s_gift_jade > 0 then
		pack_con:dec_money(MoneyType.GIFT_JADE, s_gift_jade, {['type']=MONEY_SOURCE.PAY_NPC_EXCHANGE})
	end
	if s_jade > 0 then
		pack_con:dec_money(MoneyType.JADE, s_jade, {['type']=MONEY_SOURCE.PAY_NPC_EXCHANGE})
	end
	if s_gold > 0 then
		pack_con:dec_money(MoneyType.GOLD, s_gold, {['type']=MONEY_SOURCE.PAY_NPC_EXCHANGE})
	end

	if exchage_obj.exc_money_list.gift_gold > 0 then
		pack_con:add_money(MoneyType.GIFT_GOLD, exchage_obj.exc_money_list.gift_gold * count, {['type']=MONEY_SOURCE.GAIN_NPC_EXCHANGE})
	end
	if exchage_obj.exc_money_list.gift_jade > 0 then
		pack_con:add_money(MoneyType.GIFT_JADE, exchage_obj.exc_money_list.gift_jade * count, {['type']=MONEY_SOURCE.GAIN_NPC_EXCHANGE})
	end
	if exchage_obj.exc_money_list.jade > 0 then
		pack_con:add_money(MoneyType.JADE, exchage_obj.exc_money_list.jade * count, {['type']=MONEY_SOURCE.GAIN_NPC_EXCHANGE})
	end
	if exchage_obj.exc_money_list.gold > 0 then
		pack_con:add_money(MoneyType.GOLD, exchage_obj.exc_money_list.gold * count, {['type']=MONEY_SOURCE.GAIN_NPC_EXCHANGE})
	end

	if exchage_obj.broadcast then
		--print("exchage_obj.broadcast")
		local msg = {}
		f_construct_content(msg, player:get_name(), 53)
		f_construct_content(msg, f_get_string(2981), 12)
		local src_str
		for k, v in pairs(exchage_obj.coll_item_list) do
			f_construct_content(msg, tostring(v.count), 4)
			f_construct_content(msg, f_get_string(2982), 12)
			f_construct_content(msg, v.name, 4)
		end
		f_construct_content(msg, f_get_string(2983), 12)
		for k, v in pairs(exchage_obj.exc_item_list) do
			f_construct_content(msg, v.name .. ",", 4)
		end
		f_construct_content(msg, f_get_string(2984), 12)
		f_cmd_sysbd(msg)
	end

	return 0
end