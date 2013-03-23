

local pet_equip_config = require("item.pet_equipment_config_loader")

--获取宠物背包信息
Clt_commands[1][CMD_MAP_PET_GET_BAG_C] =
function(conn, pkt)
	local obj = g_obj_mgr:get_obj(conn.char_id)
	if obj == nil or pkt.obj_id == nil then return end

	local pet_con = obj:get_pet_con()
	local pet_obj = pet_con:get_pet_obj(pkt.obj_id)
	if pet_obj == nil then return end

	local bag_con = pet_obj:get_pack_con()
	bag_con:update_list()
end

--移动
Clt_commands[1][CMD_MAP_PET_BAG_SWAP_C] =
function(conn, pkt)
	local obj = g_obj_mgr:get_obj(conn.char_id)

	if obj == nil or not pkt or not pkt.src_bag or not pkt.src_slot or not pkt.dst_bag then return end
	local new_pkt = {}
	new_pkt.result = 0

	local pet_con = obj:get_pet_con()
	
	if pkt.src_bag == PET_BAG and pkt.dst_bag == SYSTEM_BAG then   --从pet_bag到bag
		if not pkt.obj_id then return end
		local pet_obj = pet_con:get_pet_obj(pkt.obj_id)
		if pet_obj == nil then
			new_pkt.result = 22005
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PET_BAG_SWAP_S, new_pkt)
			return
		end
		local pet_bag = pet_obj:get_pack_con()
		new_pkt.result = pet_bag:pet_to_bag(pkt.src_bag, pkt.src_slot, pkt.dst_bag, pkt.dst_slot)

	elseif pkt.dst_bag == PET_BAG and pkt.src_bag == SYSTEM_BAG then  --从bag到pet_bag		
		local pet_obj = pet_con:get_combat_pet()
		if pet_obj == nil then
			new_pkt.result = 20566									  --只能对当前出战的宠物使用
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PET_BAG_SWAP_S, new_pkt)
			return
		end
		local pet_bag = pet_obj:get_pack_con()
		new_pkt.result = pet_bag:bag_to_pet(pkt.src_bag, pkt.src_slot, pkt.dst_bag, pkt.dst_slot)
	end
	
	g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PET_BAG_SWAP_S, new_pkt)
end

--升级
Clt_commands[1][CMD_MAP_PET_EQUIPMENT_UPDATE_C] = 
function(conn, pkt)
	if not pkt or not pkt.obj_id or not pkt.slot then return end

	local new_pkt = {}
	new_pkt.result = 0

	local player = g_obj_mgr:get_obj(conn.char_id)
	local pet_con = player:get_pet_con()
	local pet_obj = pet_con:get_pet_obj(pkt.obj_id)
	if pet_obj == nil then
		new_pkt.result = 22005
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PET_EQUIPMENT_UPDATE_S, new_pkt)
		return
	end

	local pet_bag = pet_obj:get_pack_con()
	local pet_item = pet_bag:get_grid(pkt.slot)
	if not pet_item then 
		new_pkt.result = 43052								--物品不存在
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PET_EQUIPMENT_UPDATE_S, new_pkt)
		return
	end

	local pack_con = player:get_pack_con()
	if pack_con:check_money_lock(MoneyType.GOLD) or pack_con:check_money_lock(MoneyType.GIFT_GOLD) then		return	end
	
							
	local pack_money = pack_con:get_money()	

	local level = pet_item.item:get_level()
	local money = pet_equip_config.pet_equipment[level+1].gold
	local money_type = 1
	if pack_money.gift_gold < money then
		if pack_money.gold < money then
			new_pkt.result = 20560								--你的金币不够，不能升级魂玉
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PET_EQUIPMENT_UPDATE_S, new_pkt)
			return
		end
		money_type = 2
	end

	local pet_level = pet_obj:get_level()
	new_pkt.result,new_pkt.del_exp = pet_item.item:on_upgrade(pet_level)
	if new_pkt.result == 0 then
		new_pkt.gold = money
		if money_type == 1 then
			pack_con:dec_money(MoneyType.GIFT_GOLD, money, {['type']=MONEY_SOURCE.NPC_BUY})
		elseif money_type == 2 then
			pack_con:dec_money(MoneyType.GOLD, money, {['type']=MONEY_SOURCE.NPC_BUY})
		end
	end
	--print("=====================>>new_pkt:",j_e(new_pkt))
	g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PET_EQUIPMENT_UPDATE_S, new_pkt)

	--更新包
	if new_pkt.result == 0 then
		local result = pet_bag:update_list()
		pet_bag:update_pet_equip()

		local str = string.format("insert log_items set char_id = %d, char_name='%s', item_name='%s', item_id=%d, item_num = %d, io=%d, type=%d, left_num=%d, time=%d, remark='%s'",
					conn.char_id, player:get_name(), pet_item.item:get_name(),pet_item.item:get_item_id(), 1,2, 78, 1, ev.time,  Json.Encode(pet_item.item:serialize_to_net()))
		f_multi_web_sql(str)

	end
end

--修炼
Clt_commands[1][CMD_MAP_PET_EQUIPMENT_PRACTICE_C] = 
function(conn, pkt)
	--print("CMD_MAP_PET_EQUIPMENT_PRACTICE_C:",j_e(pkt))
	if not pkt or not pkt.obj_id or not pkt.slot then return end
	local new_pkt = {}
	new_pkt.result = 0

	local player = g_obj_mgr:get_obj(conn.char_id)
	local pet_con = player:get_pet_con()
	local pet_obj = pet_con:get_pet_obj(pkt.obj_id)
	if pet_obj == nil then
		new_pkt.result = 22005
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PET_EQUIPMENT_PRACTICE_S, new_pkt)
		return
	end

	local pet_bag = pet_obj:get_pack_con()
	new_pkt.result = pet_bag:set_cur_practice(pkt.slot)
	g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PET_EQUIPMENT_PRACTICE_S, new_pkt)
end


--吸取经验
Clt_commands[1][CMD_MAP_PET_EQUIPMENT_ABSORB_C] = 
function(conn, pkt)
	if not pkt or not pkt.obj_id or not pkt.slot then return end
	local new_pkt = {}
	new_pkt.result = 0

	local player = g_obj_mgr:get_obj(conn.char_id)
	local pet_con = player:get_pet_con()
	local pet_obj = pet_con:get_pet_obj(pkt.obj_id)
	if pet_obj == nil then
		new_pkt.result = 22005
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PET_EQUIPMENT_ABSORB_S, new_pkt)
		return
	end

	if pet_obj:get_p_flag() == 1 then
		return g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PET_EQUIPMENT_ABSORB_S, {["result"] = 20998})
	end

	local pet_bag = pet_obj:get_pack_con()
	local pet_item = pet_bag:get_grid(pkt.slot)

	if pet_item == nil then
		new_pkt.result = 20570
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PET_EQUIPMENT_ABSORB_S, new_pkt)
		return
	end

	new_pkt.result = pet_item.item:absorb_exp(pet_obj)
	g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PET_EQUIPMENT_ABSORB_S, new_pkt)

	if new_pkt.result == 0 then
		pet_bag:update_list()
		pet_bag:update_pet_equip()

		local result,exp = pet_obj:is_enough()

		local t_exp = {}
		t_exp.get_exp = exp
		local str = string.format("insert log_items set char_id = %d, char_name='%s', item_name='%s', item_id=%d, item_num = %d, io=%d, type=%d, left_num=%d, time=%d, remark='%s'",
					conn.char_id, player:get_name(), pet_item.item:get_name(),pet_item.item:get_item_id(), 1,2, 77, 1, ev.time,  Json.Encode(t_exp))
		f_multi_web_sql(str)





	end
end
