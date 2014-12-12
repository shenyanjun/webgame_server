--local debug_print = print
local debug_print = function () end

local embed_loader = require("npc.config.embed_loader")
local formula_loader = require("config.loader.formula_loader")

--装备镶嵌
Clt_commands[1][CMD_NPC_ENCHASE_EQUIP_C] =
	function(conn, pkt)

		if not pkt.bag or not pkt.slot or not pkt.gem_list then return end

		local player = g_obj_mgr:get_obj(conn.char_id)
		local pack_con = player:get_pack_con()
		if pack_con:check_money_lock(MoneyType.GOLD) or pack_con:check_money_lock(MoneyType.GIFT_GOLD) then return end --上锁
		local equip = pack_con:get_item_by_bag_slot(pkt.bag, pkt.slot)
		if not equip then
			NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_NOT_FIND_ITEM)
			return
		end

		--判断是不是装备类
		if not equip.item.is_equipment then
			NpcContainerMgr:SendError(conn.char_id, 43015)
			return
		end
		local t_embed = embed_loader.EmbedTable[equip.item.proto.value.t_class]
		--所需金钱
		local match_level = math.floor(equip.item.proto.value.level/10+1)
		local lvl_node = t_embed.lvl_list[match_level]
		local need_money = lvl_node.price

		local ncount = 0
		for k,v in pairs(pkt.gem_list) do
			ncount = ncount + 1
		end
		if ncount <= 0 then
			NpcContainerMgr:SendError(conn.char_id, 200011)
			return
		end
		need_money = need_money * ncount

		local money = pack_con:get_money()
		if money.gift_gold + money.gold  < need_money then
			--f_bug_item_by_not_enough(conn.char_id, 104001100121)
			NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_NOT_ENOUGH_GOLD)
			return
		end

		--------------------------------------------------------
		local gem_tclass = {} --保存宝石的t_class列表
		for k,v in pairs(pkt.gem_list) do
			local item = pack_con:get_item_by_bag_slot(v.bag,v.slot)
			if not item then
				NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_NOT_FIND_ITEM)
				return
			end
			local req_lvl = item.item:get_req_lvl()
			req_lvl = tonumber(req_lvl)
			 --判断对象等级是否高于物品等级
			if player:get_level() < req_lvl then
				NpcContainerMgr:SendError(conn.char_id, E_INVALID_LEVEL)
				return
			end

			gem_tclass[k] = item.item.proto.value.t_class or 0
		end

		--如果pkt.gem_list存在相同的t_class则不能嵌
		for k, v in pairs(gem_tclass) do
			for m, n in pairs(gem_tclass) do
				if k ~= m and (v == n or formula_loader.CheckExclusion(n, v)) then
					g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_ENCHASE_EQUIP_S, {['result'] = 200034})
					return
				end
			end
		end
		--------------------------------------------------------
		--宝石是否可以镶嵌到该装备上
		local valid_gem = true
		for k,v in pairs(pkt.gem_list) do
			local item = pack_con:get_item_by_bag_slot(v.bag,v.slot)
			if not item then
				NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_NOT_FIND_ITEM)
				return
			end

			local b_find = false
			for _, gem_id in pairs(t_embed.item_list) do
				if item.item_id == gem_id then
					b_find = true --可以镶嵌到该装备上
					gem_item_id = item.item_id --保存item_id,用于限制不能镶嵌多个相同的
					break
				end
			end

			if b_find == false then
				valid_gem = false -- 不能镶嵌到该装备
				break
			end
		end

		if valid_gem == false then
			NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_DISVALID_GEM)
			return
		end

		--装备是否已经镶嵌到该装备上了(新增)--限制不能镶嵌多个
		local hole_t = equip.item.hole_t
		for k, v in pairs(hole_t) do
			if v[1] then
				local tmp_t_class = v[1].proto.value.t_class
				for kk, vv in pairs(gem_tclass) do
					if formula_loader.CheckExclusion(tmp_t_class, vv) then
						item_obj = nil
						g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_ENCHASE_EQUIP_S, {['result'] = 200034})
						return
					end
				end
				item_obj = nil
			end
		end

		local gem_l = {}
		for _, n in pairs(pkt.gem_list) do
			local item = pack_con:get_item_by_bag_slot(n.bag, n.slot)
			gem_l[n.embed_slot] = item.item_id
		end

		debug_print("Embed All gem Item OK")
		local ret_code = pack_con:embed_equip(equip, gem_l)
		
		if ret_code == 0 then
			--删除材料和扣金钱
			local ret = {}
			for k, gem_list in pairs(pkt.gem_list) do
				if pack_con:check_item_lock_by_bag_slot(gem_list.bag,gem_list.slot) then return end
				--pack_con:del_item_by_bag_slot(gem_list.bag, gem_list.slot, 1, {['type']=ITEM_SOURCE.EMBED}) --从背包中除宝石(扣一个宝石)
				ret[k] = {}
				ret[k][1] = gem_list.bag
				ret[k][2] = gem_list.slot
				ret[k][3] = 1
			end
			pack_con:del_item_by_bags_slots(ret,{['type']=ITEM_SOURCE.EMBED},1)
			if need_money < money.gift_gold then
				pack_con:dec_money(MoneyType.GIFT_GOLD, need_money, {['type']=MONEY_SOURCE.EMBED})
			else
				local left_money = need_money - money.gift_gold
				pack_con:dec_money(MoneyType.GIFT_GOLD, money.gift_gold, {['type']=MONEY_SOURCE.EMBED})
				pack_con:dec_money(MoneyType.GOLD, left_money, {['type']=MONEY_SOURCE.EMBED})
			end
		end

		local ret = {}
		ret.result = ret_code
		if ret_code ~= 0 then
			ret.result = 200038
		end
		g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_ENCHASE_EQUIP_S, ret)

		--更新人物
		if pkt.bag == EQUIPMENT_BAG then
			player:on_update_attribute(2)

			--宝石事件通知
			local args = {}
			args.item = equip.item
			g_event_mgr:notify_event(EVENT_SET.EVENT_GEM_EQUIPMENT, conn.char_id, args)
		end
	end


--装备附灵镶嵌
Clt_commands[1][CMD_MAP_RAGE_GEM_EMBBED_B] =
	function(conn, pkt)
		if not pkt.bag or not pkt.slot or not pkt.gem then return end

		local player = g_obj_mgr:get_obj(conn.char_id)
		local pack_con = player:get_pack_con()
		if pack_con:check_item_lock_by_bag_slot(SYSTEM_BAG, pkt.gem) then return end --上锁
		local equip = pack_con:get_item_by_bag_slot(pkt.bag, pkt.slot)
		if not equip then
			NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_NOT_FIND_ITEM)
			return
		end

		--判断是不是装备类
		if not equip.item.is_equipment then
			NpcContainerMgr:SendError(conn.char_id, 43015)
			return
		end
		local t_embed = embed_loader.RageEmbed[equip.item.proto.value.t_class].item_list
		
		--------------------------------------------------------
		local item = pack_con:get_item_by_bag_slot(SYSTEM_BAG, pkt.gem)
		if not item then
			NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_NOT_FIND_ITEM)
			return
		end
		local req_lvl = item.item:get_req_lvl()
		req_lvl = tonumber(req_lvl)
		 --判断对象等级是否高于物品等级
		if player:get_level() < req_lvl then
			NpcContainerMgr:SendError(conn.char_id, E_INVALID_LEVEL)
			return
		end
		local gem_id = item.item:get_item_id()
		if equip.item:get_bind() == 0 then				--装备绑定  宝石也绑定
			gem_id = gem_id - (gem_id % 2)
		end
		--------------------------------------------------------
		--宝石是否可以镶嵌到该装备上
		local hole_count = equip.item:get_rage_hole_count()
		if hole_count == 0 then
			NpcContainerMgr:SendError(conn.char_id, 201013)
			return
		end
		if not equip.item:check_rage_embed() then
			NpcContainerMgr:SendError(conn.char_id, 201014)
			return
		end

		if item.item:get_m_class() ~= 6 or item.item:get_s_class() ~= 1 then
			NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_DISVALID_GEM)
			return
		end
		local t_class = item.item:get_t_class()

		if not t_embed[t_class] then
			NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_DISVALID_GEM)
			return
		end

		local ret_code = pack_con:del_item_by_bag_slot(SYSTEM_BAG, pkt.gem, 1, {['type']=ITEM_SOURCE.RAGEEMBED})
		if ret_code ~= 0 then
			NpcContainerMgr:SendError(conn.char_id, e_code)
			return
		end

		pack_con:rage_embed_equip(equip, gem_id)

		local ret = {}
		ret.result = 0
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_RAGE_GEM_EMBBED_S, ret)

		--更新人物
		if pkt.bag == EQUIPMENT_BAG then
			player:on_update_attribute(2)
		end
	end


