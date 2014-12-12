--2011-03-07
--laojc
--原石打磨
--[[
每次打磨只会获得一个道具，打磨原石有几率获得宝石或宝石碎片。

]]
--
local stone_loader = require("npc.config.stone_polish_loader")
--local item_reward = f_get_item_reward()

Clt_commands[1][CMD_B2M_STONE_POLISH_C] =
	function(conn, pkt)
		if pkt.item_id == nil or pkt.item_count == nil or pkt.item_count < 0 then return end
		local ret = {}
		ret.result = 0

		local item_id_t = pkt.item_id
		if stone_loader.item_reward[item_id_t] == nil then return end

		local player = g_obj_mgr:get_obj(conn.char_id)
		local pack_con = player:get_pack_con()
		if pack_con:check_money_lock(MoneyType.GOLD) then return end --上锁
		if pack_con:check_item_lock_by_item_id(tonumber(item_id_t)) then return end --上锁
		local money = pack_con:get_money()
		--判断背包的物品个数是否跟count相符
		local item_count = pack_con:get_item_count(tonumber(item_id_t))
		if item_count < tonumber(pkt.item_count) then 
			ret.result = 232323
			return g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_STONE_POLISH_S, ret)
		end

		--钱够否
		local money_l = stone_loader.item_reward[item_id_t].money * pkt.item_count
		if money.gold < money_l then 
			ret.result = 43340
			return g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_STONE_POLISH_S, ret)
		end --钱不够

		local item_list = {}
		local percent = stone_loader.item_reward[item_id_t].gift_percent
		for i = 1 ,pkt.item_count do
			local num = math.random(1,100)
			if num <= percent then
				local item = f_random_wave(stone_loader.item_reward[item_id_t].reward_list,1)
				local item_id = item[1][1]
				local number = item[1][2]
				if not item_list[item_id] then
					item_list[item_id] = {}
					item_list[item_id].item_id = item_id
					item_list[item_id].number = number
					item_list[item_id].type = 1
				else
					item_list[item_id].number = item_list[item_id].number + number
				end
			end
		end
		local e_code = pack_con:del_item_by_item_id(tonumber(item_id_t),pkt.item_count,{['type'] = ITEM_SOURCE.STONE_POLISH})
		if e_code == 0 then
			local src_log = {['type'] = ITEM_SOURCE.STONE_POLISH}
			local e_code = pack_con:add_item_l(item_list, src_log)
			if e_code ~= 0 then
				return 
			end

			pack_con:dec_money(MoneyType.GOLD, money_l, {['type']=MONEY_SOURCE.STONE_POLISH})

			g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_STONE_POLISH_S, ret)
		end
	end