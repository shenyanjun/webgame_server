--local debug_print = print
local debug_print = function () end

local drill_loader = require("npc.config.drill_loader")

--执行打孔
Clt_commands[1][CMD_NPC_DRILL_EQUIP_C]=
	function(conn, pkt)
		if not pkt or not pkt.bag or not pkt.slot or not pkt.material then return end
		debug_print("CMD_NPC_DRILL_EQUIP_C")

		local player = g_obj_mgr:get_obj(conn.char_id)
		local pack_con = player:get_pack_con()
		if pack_con:check_money_lock(MoneyType.GOLD) or pack_con:check_money_lock(MoneyType.GIFT_GOLD) then return end --上锁
		if pack_con:check_item_lock_by_bag_slot(pkt.material.bag, pkt.material.slot) then return end --上锁
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

		--当前装备已有的打孔数
		local hole_count = equip.item:get_hole_count()
		if hole_count >= MAX_EQUIP_DRILL then
			NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_CANT_DRILL_ANYMORE)
			return
		end

		local t_drill = drill_loader.DrillTable[hole_count + 1]
		local match_level = math.floor(equip.item.proto.value.level/10+1)
		local lvl_node = t_drill.lvl_list[match_level]
		--print("++++++++lvl_node", j_e(lvl_node))

		--获取打孔所需金钱
		local need_money = lvl_node.price
		local money = pack_con:get_money()
		debug_print("money.gift_gold + money.gold < need_money", money.gift_gold + money.gold, need_money)
		if money.gift_gold + money.gold  < need_money then
			NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_NOT_ENOUGH_GOLD)
			return
		end

		--获取打孔所需道具
		local material_item = pack_con:get_item_by_bag_slot(pkt.material.bag, pkt.material.slot)
		if not material_item then
			NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_NOT_FIND_ITEM)
			return
		end

		local need_num = lvl_node.req_material_num
		local valid_material = false
		for _, gem_id in pairs(t_drill.material_list) do
			if material_item.item_id == tonumber(gem_id) then
				valid_material = true
			end
		end
		if not valid_material then
			NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_NOT_ENOUGH_ITEM)
			return
		end

		--如果材料是绑定的,装备变成绑定
		if material_item.item:get_bind() == 0 then
			equip.item:set_bind()
		end
		--条件满足,执行打孔操作
		local ret_code = pack_con:drill_equip(equip)

		--删除材料和金钱
		pack_con:del_item_by_bag_slot(pkt.material.bag, pkt.material.slot, 1, {['type']=ITEM_SOURCE.DRILL})

		if need_money < money.gift_gold then
			pack_con:dec_money(MoneyType.GIFT_GOLD, need_money, {['type']=MONEY_SOURCE.DRILL})
		else
			local left_money = need_money - money.gift_gold
			pack_con:dec_money(MoneyType.GIFT_GOLD, money.gift_gold, {['type']=MONEY_SOURCE.DRILL})
			pack_con:dec_money(MoneyType.GOLD, left_money, {['type']=MONEY_SOURCE.DRILL})
		end

		local ret = {}
		ret.result = ret_code
		if ret_code ~= 0 then
			ret.result = 200037
		end
		g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_DRILL_EQUIP_S, ret)
	end

--装备附灵打孔
Clt_commands[1][CMD_MAP_RAGE_GEM_HOLE_B]=
	function(conn, pkt)
		if not pkt or not pkt.bag then return end

		local player = g_obj_mgr:get_obj(conn.char_id)
		local pack_con = player:get_pack_con()
		if pack_con:check_item_lock_by_item_id(617000000040) then return end --上锁
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

		--当前装备已有的打孔数
		local hole_count = equip.item:get_rage_hole_count()
		if hole_count >= 1 then
			NpcContainerMgr:SendError(conn.char_id, 201012)
			return
		end

		--扣除打孔所需道具
		local cnt = pack_con:get_all_item_count(617000000040)
		if cnt < 1 then
			NpcContainerMgr:SendError(conn.char_id, 201016)
			return
		end
		local e_code = pack_con:del_item_by_item_id_inter_face(617000000040, 1, {['type']=ITEM_SOURCE.RAGE_DRILL}, 1)
		if e_code ~= 0 then
			NpcContainerMgr:SendError(conn.char_id, e_code)
			return
		end

		--条件满足,执行附灵打孔操作
		local ret_code = pack_con:rage_drill_equip(equip)

		local ret = {}
		ret.result = ret_code
		if ret_code ~= 0 then
			ret.result = 200037
		end
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_RAGE_GEM_HOLE_S, ret)
	end
