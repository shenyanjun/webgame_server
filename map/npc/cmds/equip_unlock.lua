


local unlock_loader= require("npc.config.unlock_loader")

Clt_commands[1][CMD_NPC_UNLOCK_EQUIP_C] =
function(conn, pkt)
	if not conn.char_id or not pkt or not pkt.bag or not pkt.slot or not pkt.material then return end
	local player = g_obj_mgr:get_obj(conn.char_id)
	local pack_con = player:get_pack_con()
	if pack_con:check_money_lock(MoneyType.GOLD) or pack_con:check_money_lock(MoneyType.GIFT_GOLD) then return end --上锁
	if pack_con:check_item_lock_by_bag_slot(pkt.material.bag, pkt.material.slot) then return end --上锁
	if pack_con:check_item_lock_by_bag_slot(pkt.bag, pkt.slot) then return end --上锁
	local equip = pack_con:get_item_by_bag_slot(pkt.bag, pkt.slot)
	local ret = {}
	ret.result = 0

	--背包没有物品
	if not equip then
		NpcContainerMgr:SendError(conn.char_id,ERROR_NPC_NOT_FIND_ITEM)
		return
	end

	--不是装备
	if not equip.item.is_equipment then
		NpcContainerMgr:SendError(conn.char_id,43015)
		return 
	end

	local src_id = equip.item_id
	local t_unlock = unlock_loader.UnlockTable[src_id]
	--不是解封装备
	if not t_unlock or not t_unlock.des_id then
		NpcContainerMgr:SendError(conn.char_id,27617)
		return
	end 


	--道具
	local material = pack_con:get_item_by_bag_slot(pkt.material.bag,pkt.material.slot)
	local material_name = material.item:get_name()
	local material_list = t_unlock.item_list
	local valid_material = false
	for _,v in pairs(material_list or {}) do
		if material.item_id == tonumber(v.material_id) then
			valid_material = true
		end
	end
	if not valid_material then
		NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_NOT_ENOUGH_ITEM)
		return 
	end
	
	local des_id = t_unlock.des_id
	if not des_id then
		NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_NOT_FIND_ITEM)
		return 		
	end

	local total_money =  t_unlock.money
	local money = pack_con:get_money()
	if total_money > money.gift_gold+money.gold then
		NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_NOT_ENOUGH_GOLD)
		return 			
	end

	local error,des_equip = Item_factory.create(des_id)
	if not des_equip or error ~= 0 then print(" Create failed") return end
	--绑定
	if material.item:get_bind() == 0 or equip.item:get_bind() == 0 then
		des_equip:set_bind()
	end
	
	local source_name = equip.item:get_name()
	local des_name = des_equip:get_name()
	local equipment = equip_transfer_attr(equip.item,des_equip)
	if not equipment then print(" equipment unlock failed") return end
	--加装备
	if 0 ~= pack_con:add_by_item(equipment,{['type']=ITEM_SOURCE.EQUIP_UNLOCK}) then
		ret.result = 43017
		g_cltsock_mgr:send_client(conn.char_id,CMD_NPC_UNLOCK_EQUIP_S,ret)
		return 
	end

	--减钱
	if total_money < money.gift_gold then
		pack_con:dec_money(MoneyType.GIFT_GOLD, total_money, {['type']=MONEY_SOURCE.EQUIP_UNLOCK})
	else
		local left_money = total_money - money.gift_gold
		pack_con:dec_money(MoneyType.GIFT_GOLD, money.gift_gold, {['type']=MONEY_SOURCE.EQUIP_UNLOCK})
		pack_con:dec_money(MoneyType.GOLD, left_money, {['type']=MONEY_SOURCE.EQUIP_UNLOCK})
	end
	--减材料
	pack_con:del_item_by_bag_slot(pkt.material.bag, pkt.material.slot,1,{['type']=ITEM_SOURCE.EQUIP_UNLOCK})
	pack_con:del_item_by_bag_slot(pkt.bag, pkt.slot,1,{['type']=ITEM_SOURCE.EQUIP_UNLOCK})

	
	--广播
	local sys_l = {}
	sys_l[1] = player:get_name()
	sys_l[2] = material_name
	sys_l[3] = source_name
	sys_l[4] = des_name
	local str_json = f_get_sysbd_format(10011, sys_l)
	f_cmd_sysbd(str_json)
	
	--更新人物
	if pkt.bag == EQUIPMENT_BAG then
		player:on_dress_update(1)
	end
	g_cltsock_mgr:send_client(conn.char_id,CMD_NPC_UNLOCK_EQUIP_S,ret)
end 


--装备重铸
Clt_commands[1][CMD_MAP_EQUIP_SPEC_UNLOCK_B] =
function(conn, pkt)
	if not conn.char_id or not pkt or not pkt.material or not pkt.equip then return end
	local player = g_obj_mgr:get_obj(conn.char_id)
	local pack_con = player:get_pack_con()
	if pack_con:check_money_lock(MoneyType.GOLD) or pack_con:check_money_lock(MoneyType.GIFT_GOLD) then return end --上锁
	if pack_con:check_item_lock_by_bag_slot(SYSTEM_BAG, pkt.material) then return end --上锁
	if pack_con:check_item_lock_by_bag_slot(SYSTEM_BAG, pkt.equip) then return end --上锁
	local equip = pack_con:get_item_by_bag_slot(SYSTEM_BAG, pkt.equip)
	local ret = {}
	ret.result = 0

	--背包没有物品
	if not equip then
		NpcContainerMgr:SendError(conn.char_id,ERROR_NPC_NOT_FIND_ITEM)
		return
	end

	--不是装备
	if not equip.item.is_equipment then
		NpcContainerMgr:SendError(conn.char_id,43015)
		return 
	end
	--筛选装备ID,只配了非绑ID
	local equip_id = equip.item_id
	if equip_id % 2 == 0 then
		equip_id = equip_id + 1
	end

	--检查材料
	local material = pack_con:get_item_by_bag_slot(SYSTEM_BAG,pkt.material)
	if material.item:get_m_class() ~= 6 or material.item:get_s_class() ~= 16 or material.item:get_t_class() ~= 0 then			
		s_pkt.result = 201008
	    g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_EQUIP_SPEC_UNLOCK_S, s_pkt)
	    return
	end
	if player:get_level() < material.item:get_req_lvl() then
		NpcContainerMgr:SendError(conn.char_id, E_INVALID_LEVEL)
		return
	end

	local material_id = material.item_id
	local bind_flags = false
	if material_id % 2 == 0 then
		material_id = material_id + 1
		bind_flags = true
	end
	--绑定
	if equip.item:get_bind() == 0 then
	    bind_flags = true
	end

	local t_unlock = unlock_loader.SpecUnlock[material_id] and unlock_loader.SpecUnlock[material_id][equip_id]
	--不是解封装备
	if not t_unlock then
		NpcContainerMgr:SendError(conn.char_id,201009)
		return
	end

	local total_money =  t_unlock.money
	local money = pack_con:get_money()
	if total_money > money.gift_gold+money.gold then
		NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_NOT_ENOUGH_GOLD)
		return 			
	end

	local des_id = t_unlock.des_id
	if bind_flags then
		des_id = des_id - 1
	end

	--绑定
	local error,des_equip = Item_factory.create(des_id)
	if not des_equip or error ~= 0 then print(" Create failed") return end
	
	--减材料
	pack_con:del_item_by_bag_slot(SYSTEM_BAG, pkt.material, 1,{['type']=ITEM_SOURCE.SPECIAL_UNLOCK})
	pack_con:del_item_by_bag_slot(SYSTEM_BAG, pkt.equip, 1,{['type']=ITEM_SOURCE.SPECIAL_UNLOCK})

	--转移属性
	local source_name = equip.item:get_name()
	local des_name = des_equip:get_name()
	local equipment = equip_transfer_attr(equip.item, des_equip)
	if not equipment then print(" equipment unlock failed") return end

	--加装备
	if 0 ~= pack_con:add_by_item(equipment, {['type']=ITEM_SOURCE.SPECIAL_UNLOCK}) then
		ret.result = 43017
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_EQUIP_SPEC_UNLOCK_S, ret)
		return 
	end

	--减钱
	if total_money < money.gift_gold then
		pack_con:dec_money(MoneyType.GIFT_GOLD, total_money, {['type']=MONEY_SOURCE.SPECIAL_UNLOCK})
	else
		local left_money = total_money - money.gift_gold
		pack_con:dec_money(MoneyType.GIFT_GOLD, money.gift_gold, {['type']=MONEY_SOURCE.SPECIAL_UNLOCK})
		pack_con:dec_money(MoneyType.GOLD, left_money, {['type']=MONEY_SOURCE.SPECIAL_UNLOCK})
	end

	g_cltsock_mgr:send_client(conn.char_id,CMD_MAP_EQUIP_SPEC_UNLOCK_S,ret)
end 

--装备重铸预览
Clt_commands[1][CMD_MAP_EQUIP_PREVIEW_UNLOCK_B] =
function(conn, pkt)
	if not conn.char_id or not pkt or not pkt.material or not pkt.equip then return end
	local player = g_obj_mgr:get_obj(conn.char_id)
	local pack_con = player:get_pack_con()

	local equip = pack_con:get_item_by_bag_slot(SYSTEM_BAG, pkt.equip)
	local ret = {}
	ret.result = 0

	--背包没有物品
	if not equip then
		NpcContainerMgr:SendError(conn.char_id,ERROR_NPC_NOT_FIND_ITEM)
		return
	end

	--不是装备
	if not equip.item.is_equipment then
		NpcContainerMgr:SendError(conn.char_id,43015)
		return 
	end
	--筛选装备ID,只配了非绑ID
	local equip_id = equip.item_id
	if equip_id % 2 == 0 then
		equip_id = equip_id + 1
	end

	--检查材料
	local material = pack_con:get_item_by_bag_slot(SYSTEM_BAG,pkt.material)
	if material.item:get_m_class() ~= 6 or material.item:get_s_class() ~= 16 or material.item:get_t_class() ~= 0 then			
		s_pkt.result = 201008
	    g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_EQUIP_PREVIEW_UNLOCK_B, s_pkt)
	    return
	end

	local material_id = material.item_id
	local bind_flags = false
	if material_id % 2 == 0 then
		material_id = material_id + 1
		bind_flags = true
	end
	--绑定
	if equip.item:get_bind() == 0 then
	    bind_flags = true
	end

	local t_unlock = unlock_loader.SpecUnlock[material_id] and unlock_loader.SpecUnlock[material_id][equip_id]
	--不是解封装备
	if not t_unlock then
		NpcContainerMgr:SendError(conn.char_id,201009)
		return
	end

	local des_id = t_unlock.des_id
	if bind_flags then
		des_id = des_id - 1
	end

	--绑定
	local error,des_equip = Item_factory.create(des_id)
	if not des_equip or error ~= 0 then print(" Create failed") return end

	--转移属性
	local source_name = equip.item:get_name()
	local des_name = des_equip:get_name()
	local equipment = equip_transfer_attr(equip.item, des_equip)
	if not equipment then print(" equipment unlock failed") return end
	
	ret.item = equipment:serialize_to_net()
	ret.equip = pkt.equip
	g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_EQUIP_PREVIEW_UNLOCK_S, ret)
end 

