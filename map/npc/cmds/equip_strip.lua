--local debug_print = print
local debug_print = function () end

local strip_loader = require("npc.config.strip_loader")

--装备拆卸
Clt_commands[1][CMD_NPC_STRIP_EQUIP_C] =
	function(conn, pkt)
		if not pkt.slot or not pkt.bag or not pkt.material or not pkt.embed_slot then return end

		local player = g_obj_mgr:get_obj(conn.char_id)
		local pack_con = player:get_pack_con()
		if pack_con:check_money_lock(MoneyType.GOLD) or pack_con:check_money_lock(MoneyType.GIFT_GOLD) then return end --上锁
		if pack_con:check_item_lock_by_bag_slot(SYSTEM_BAG, pkt.material[1]) then return end --上锁
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

		--拆卸所有
		--if not pkt.embed_slot then
			--所需金钱
			local need_money = 0
			--得到宝石
			local item_list = {}
			--宝石数量
			local gem_cnt = 0
			--拆卸工具
			local tool_id

			--是否绑定
			local bind_flags = false
			for k, v in pairs(pkt.embed_slot) do
				local embed_obj = equip.item.hole_t[v][1]
				if embed_obj ~= nil then 
					local item_id = embed_obj:get_item_id()
					if not item_id then
						NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_NOT_FIND_ITEM)
						return
					end
					local e_code, item_obj = Item_factory.create(item_id)
					if not item_obj then
						NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_NOT_FIND_ITEM)
						return
					end
					local tmp_item = {}
					tmp_item.type = 2
					tmp_item.number = 1
					tmp_item.item = item_obj
					table.insert(item_list, tmp_item)

					local t_strip = nil
					t_strip = strip_loader.StripTable[item_obj:get_item_lvl()] --多少级宝石

					--所需金钱
					need_money = need_money + t_strip.price
					--所需石头
					gem_cnt = gem_cnt + 1
				end
			end
			local tool_list = {}
			for k, v in ipairs(pkt.material) do
				if gem_cnt <= 0 then break end
				local tmp_slot = pack_con:get_item_by_bag_slot(SYSTEM_BAG, v)
				local tmp_table = {}
				tmp_table.slot = v
				if tmp_slot.item:get_bind() ~= 1 then
					bind_flags = true
				end
				if not tool_id then
					tool_id = tmp_slot.item_id
				else
					if tool_id ~= tmp_slot.item_id then
						NpcContainerMgr:SendError(conn.char_id, 200115)
						return
					end
				end
				if gem_cnt <= tmp_slot.number then
					tmp_table.number = gem_cnt
				else
					tmp_table.number = tmp_slot.number	
				end
				gem_cnt = gem_cnt - tmp_table.number
				table.insert(tool_list, tmp_table)
			end
			--检查工具数量
			if gem_cnt > 0 then
				NpcContainerMgr:SendError(conn.char_id, 200011)
				return
			end

			--检查钱
			local money = pack_con:get_money()
			if money.gift_gold + money.gold  < need_money then
				item_obj = nil
				NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_NOT_ENOUGH_GOLD)
				return
			end

			--检查是否能加
			local e_code = pack_con:check_add_item_l_inter_face(item_list)
			if e_code ~= 0 then
				NpcContainerMgr:SendError(conn.char_id, e_code)
				return
			end
			--扣钱
			local money_list = {}
			money_list[MoneyType.GIFT_GOLD] = need_money
			pack_con:dec_money_l_inter_face(money_list, {['type']=MONEY_SOURCE.STRIP}, 1)
			--扣工具
			for k, v in ipairs(tool_list) do
				pack_con:del_item_by_bag_slot(SYSTEM_BAG, v.slot, v.number, {['type']=ITEM_SOURCE.STRIP})
			end
			--拆卸
			if bind_flags then equip.item:set_bind(0) end
			pack_con:dis_all_embed_equip(equip, pkt.embed_slot)
			--加宝石
			pack_con:add_item_l(item_list, {['type']=ITEM_SOURCE.STRIP})

		--需要拆卸的孔
		--else
			--local embed_obj = equip.item.hole_t[pkt.embed_slot][1]
			--if embed_obj == nil then return end
			--local item_id = embed_obj:get_item_id()
			--if not item_id then
				--NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_NOT_FIND_ITEM)
				--return
			--end
--
			--local e_code, item_obj = Item_factory.create(item_id)
			--if not item_obj then
				--NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_NOT_FIND_ITEM)
				--return
			--end
			--local t_strip = nil
			--t_strip = strip_loader.StripTable[item_obj:get_item_lvl()] --多少级宝石
--
			----背包是否已满
			--if pack_con:get_bag_free_slot_cnt() <= 0 then
				--item_obj = nil
				--NpcContainerMgr:SendError(conn.char_id, 43004)
				--return
			--end
--
			----所需金钱
			--local need_money = t_strip.price
			--local money = pack_con:get_money()
			--if money.gift_gold + money.gold  < need_money then
				--item_obj = nil
				--NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_NOT_ENOUGH_GOLD)
				--return
			--end
--
			----获取拆卸宝石所需材料
			--local material_item = pack_con:get_item_by_bag_slot(SYSTEM_BAG, pkt.material[1])
			--if not material_item then
				--NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_NOT_FIND_ITEM)
				--return
			--end
--
			--local valid_material = false
			--for _, t_mater in pairs(t_strip.material_list) do
				--if material_item.item_id == tonumber(t_mater.item_id) then
					--valid_material = true
					--break
				--end
			--end
			--if not valid_material then
				--NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_NOT_ENOUGH_ITEM)
				--return
			--end
--
			----如果材料是绑定的,装备变成绑定
			--if material_item.item:get_bind() == 0 then
				--equip.item:set_bind()
			--end
			----拆卸操作
			--pack_con:dis_embed_equip(equip, pkt.embed_slot)
			----拆卸的宝石增加到背包中
			--pack_con:add_by_item(item_obj, {['type'] = ITEM_SOURCE.STRIP})
--
			----扣金钱
			--if need_money < money.gift_gold then
				--pack_con:dec_money(MoneyType.GIFT_GOLD, need_money, {['type']=MONEY_SOURCE.STRIP})
			--else
				--local left_money = need_money - money.gift_gold
				--pack_con:dec_money(MoneyType.GIFT_GOLD, money.gift_gold, {['type']=MONEY_SOURCE.STRIP})
				--pack_con:dec_money(MoneyType.GOLD, left_money, {['type']=MONEY_SOURCE.STRIP})
			--end
--
			----删除材料和金钱
			--pack_con:del_item_by_bag_slot(SYSTEM_BAG, pkt.material[1], 1, {['type']=ITEM_SOURCE.STRIP})
		--end
		local ret = {}
		ret.result = 0
		g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_STRIP_EQUIP_S, ret)
	
		--更新人物
		if pkt.bag == EQUIPMENT_BAG then
			player:on_update_attribute(2)
		end
	end

--宠物魂魄拆卸
Clt_commands[1][CMD_MAP_PET_STRIP_C] =
	function(conn, pkt)
		if not pkt.slot or not pkt.pet_id or not pkt.index or not pkt.s_slot then return end

		local player = g_obj_mgr:get_obj(conn.char_id)

		local pet_con = player:get_pet_con()
		if not pet_con then return  end 
		local pet_obj = pet_con:get_pet_obj(pkt.pet_id)
		if not pet_obj then return end 
		local s_pkt = {}

		if pet_con:get_combat_pet_id() == pkt.pet_id then
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PET_EQUIP_SOUL_S, {["result"] = 22004})
			return  
		end

		--检查魂玉魂魄
		local pet_equip = pet_obj:get_pack_con()
		local grid = pet_equip:get_grid(pkt.slot)
		local grid_item = grid and grid.item
		if grid_item == nil then
			return 
		end

		local e_code, need_money = grid_item:strip_soul_money(pkt.index)
		if e_code ~= 0 then
			g_cltsock_mgr:send_client(char_id, CMD_MAP_PET_STRIP_S, {["result"] = e_code})
			return
		end

		--检查物品
		local pack_con = player:get_pack_con()
		if pack_con:get_bag_free_slot_cnt() < 1 then 
			g_cltsock_mgr:send_client(char_id, CMD_MAP_PET_STRIP_S, {["result"] = 43080})
			return 
		end

		if pack_con:check_item_lock_by_item_id(605000000121) then return end --上锁
		local s_slot = pack_con:get_item_by_bag_slot(SYSTEM_BAG , pkt.s_slot)
		local s_item = s_slot and s_slot.item
		if not s_item then
			s_pkt.result = 43001
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PET_STRIP_S, s_pkt)
			return
		end

		if s_item:get_item_id() ~= 605000000121 and s_item:get_item_id() ~= 605000000120 then
			s_pkt.result = 43082
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PET_STRIP_S ,s_pkt)
			return
		end
		local flags = false
		if s_item:get_bind() == 0 then flags = true end

		--检查钱
		local money_list = {}
		money_list[MoneyType.GIFT_GOLD] = need_money
		e_code = pack_con:dec_money_l_inter_face(money_list, {['type']=MONEY_SOURCE.PET_STRIP_EQUIP}, 1)
		if e_code ~= 0 then
			return  g_cltsock_mgr:send_client(char_id, CMD_MAP_PET_STRIP_S, {["result"] = e_code})
		end
		pack_con:del_item_by_bag_slot(SYSTEM_BAG, pkt.s_slot, 1, {['type']=ITEM_SOURCE.PET_STRIP_EQUIP})

		--加魂魄
		local soul = grid_item:strip_soul(pkt.index)
		local item_list = {}
		item_list[1] = {}
		item_list[1].type = 2
		item_list[1].item = soul
		item_list[1].number = 1
		e_code = pack_con:add_item_l(item_list, {['type']=ITEM_SOURCE.PET_STRIP_EQUIP})
		if e_code~=0 then
			g_cltsock_mgr:send_client(char_id, CMD_MAP_PET_STRIP_S, {["result"] = e_code})
			return 
		end
		if flags then
			grid_item:set_bind(0)
		end
		pet_equip:update_list()
		pet_equip:update_pet_equip(1)

		local ret = {}
		ret.result = 0
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PET_STRIP_S, ret)
	end

--宠物吸取魂玉
Clt_commands[1][CMD_MAP_PET_EAT_EQUIP_B] =
	function(conn, pkt)
		if not pkt.slot or not pkt.obj_id then return end

		local player = g_obj_mgr:get_obj(conn.char_id)
		local s_pkt = {}
		--检查宠物
		local pet_con = player:get_pet_con()
		if not pet_con then return  end 
		local pet_obj = pet_con:get_pet_obj(pkt.obj_id)
		if not pet_obj then return end 
		if pet_obj:get_p_flag() == 1 then
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PET_EAT_EQUIP_S, {["result"] = 21064})
			return
		end

		--检查魂玉
		local pack_con = player:get_pack_con()
		if pack_con:check_item_lock_by_bag_slot(SYSTEM_BAG, pkt.slot) then return end --上锁
		local grid = pack_con:get_item_by_bag_slot(SYSTEM_BAG, pkt.slot)
		local grid_item = grid and grid.item
		if grid_item == nil then
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PET_EAT_EQUIP_S, s_pkt)
			return 
		end
		if not grid_item.is_pet_equip then 
			s_pkt.result = 200118
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PET_EAT_EQUIP_S, s_pkt)
			return
		end
		s_pkt.result = grid_item:pet_can_absorb() 
		if s_pkt.result ~= 0 then
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PET_EAT_EQUIP_S, s_pkt)
			return
		end
		local bind_flags = false
		if grid_item:get_bind() ~= 1 then
			bind_flags = true
		end
		local all_exp = grid_item:get_all_exp()
		local tmp_lvl = grid_item:get_level()
		grid_item:set_exp(0)
		grid_item:set_level(1)
		grid_item:old_max_capacity()

		--加经验
		if bind_flags then
			pet_obj:set_bind(0)
		end
		local surplus_exp = all_exp - pet_obj:add_soul_exp(all_exp)
		if surplus_exp > 0 then
			grid_item:set_exp(surplus_exp)
			grid_item:level_up_auto(tmp_lvl)

			local e_code, ctn = pack_con:get_bag(SYSTEM_BAG)
			local log_list = {}
			log_list[1] = ctn:get_update_log(ItemSyncFlag.ITEM_SYNC_UPDATE, pkt.slot)
			pack_con:update_client(0, log_list, {['type']=ITEM_SOURCE.USE_ITEM})
		else
			--扣除魂玉
			pack_con:del_item_by_bag_slot(SYSTEM_BAG, pkt.slot, 1, {['type']=ITEM_SOURCE.pet_absorb})
		end

		local new_pkt = {}
		new_pkt.list = pet_con:net_get_list()
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PET_GET_LIST_S, new_pkt)

		local ret = {}
		ret.result = 0
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PET_EAT_EQUIP_S, ret)

		f_pet_info_insert_web(2, 21, conn.char_id, pkt.obj_id)
	end

--宠物吸取魂玉预览
Clt_commands[1][CMD_MAP_PREVIEW_PET_EAT_EQUIP_B] =
	function(conn, pkt)
		if not pkt.slot or not pkt.obj_id then return end

		local player = g_obj_mgr:get_obj(conn.char_id)
		local s_pkt = {}
		--检查宠物
		local pet_con = player:get_pet_con()
		if not pet_con then return  end 
		local pet_obj = pet_con:get_pet_obj(pkt.obj_id)
		if not pet_obj then return end 
		if pet_obj:get_p_flag() == 1 then
			g_cltsock_mgr:send_client(obj_id, CMD_MAP_PREVIEW_PET_EAT_EQUIP_S, {["result"] = 20999})
			return
		end

		--检查魂玉
		local pack_con = player:get_pack_con()
		if pack_con:check_item_lock_by_bag_slot(SYSTEM_BAG, pkt.slot) then return end --上锁
		local grid = pack_con:get_item_by_bag_slot(SYSTEM_BAG, pkt.slot)
		local grid_item = grid and grid.item
		if grid_item == nil then
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PREVIEW_PET_EAT_EQUIP_S, s_pkt)
			return 
		end
		if not grid_item.is_pet_equip then 
			s_pkt.result = 200118
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PREVIEW_PET_EAT_EQUIP_S, s_pkt)
			return
		end
		s_pkt.result = grid_item:pet_can_absorb() 
		if s_pkt.result ~= 0 then
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PREVIEW_PET_EAT_EQUIP_S, s_pkt)
			return
		end
		
		local all_exp = grid_item:get_all_exp()

		s_pkt.lvl = pet_obj:pre_level(all_exp)
		s_pkt.result = 0

		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PREVIEW_PET_EAT_EQUIP_S, s_pkt)

	end

--装备拆卸
Clt_commands[1][CMD_MAP_RAGE_GEM_STRIP_B] =
	function(conn, pkt)
		if not pkt.slot or not pkt.bag then return end

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

		--得到宝石
		local item_list = {}

		--是否能拆
		local gem_id, gem_lvl = equip.item:get_rage_embed_id()
		if not gem_id then
			NpcContainerMgr:SendError(conn.char_id, 201015)
			return
		end
		item_list[1] = {}
		item_list[1].item_id = gem_id
		item_list[1].type = 1
		item_list[1].number = 1

		--所需金钱
		local need_money = 1000 * gem_lvl
		local money = pack_con:get_money()
		if money.gift_gold + money.gold  < need_money then
			item_obj = nil
			NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_NOT_ENOUGH_GOLD)
			return
		end

		--检查是否能加
		local e_code = pack_con:check_add_item_l_inter_face(item_list)
		if e_code ~= 0 then
			NpcContainerMgr:SendError(conn.char_id, e_code)
			return
		end
		--扣钱
		local money_list = {}
		money_list[MoneyType.GIFT_GOLD] = need_money
		pack_con:dec_money_l_inter_face(money_list, {['type']=MONEY_SOURCE.RAGE_STRIP}, 1)

		--拆卸
		pack_con:dis_rage_embed_equip(equip)
		--加宝石
		pack_con:add_item_l(item_list, {['type']=ITEM_SOURCE.RAGE_STRIP})

		local ret = {}
		ret.result = 0
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_RAGE_GEM_STRIP_S, ret)
	
		--更新人物
		if pkt.bag == EQUIPMENT_BAG then
			player:on_update_attribute(2)
		end
	end


