local _f_t_c = require("config.faction_territory_config")
local stuff_f = require("obj.stuff_process")
--帮派领地相关的处理

--判断是否属于帮派领地的所属的帮派，属于返回1，不属于返回2，不在帮派线返回0
function f_is_owner_territory(char_id)
	if f_is_line_faction and g_faction_territory then
		if g_faction_territory:get_owner_id() == "" then return 3 end
		local ret = g_faction_territory:is_owner_territory(char_id)
		return ret and 1 or 2
	end
	return 0
end

--加帮派领地灵力type:类型，power:数值
function f_add_territory_power(type, power)
	if f_is_line_faction and g_faction_territory then
		g_faction_territory:add_territory_power(type, power)
	end
end

--最帮派领地灵力等级，当前值，下次升级值，type:类型
function f_get_territory_power(type)
	if f_is_line_faction and g_faction_territory then
		local ret = {}
		ret[1] = g_faction_territory.monster_level_up:get_level(type)
		ret[2] = g_faction_territory.monster_level_up:get_power(type)
		ret[3] = _f_t_c._level_power[ret[1]] or 9999999
		return ret
	end
	return {0, 0, 0}
end

--在帮派解散时判断是否已被占领的帮派解散
function f_cheak_faction_territory(faction_id)
	if f_is_line_faction and g_faction_territory then
		if faction_id == g_faction_territory:get_owner_id() then
			g_faction_territory:set_owner_id("")
			local ret = {}
			ret.owner_id = g_faction_territory:get_owner_id()
			g_svsock_mgr:send_server_ex(COMMON_ID, 0, CMD_M2P_APPLICATION_WAR_OVER_C, ret)
		end
	end
end

--摇钱树
--摇树
function f_shake_money_tree(char_id)
	return g_faction_territory.money_tree:shake(char_id, 1)
end

Clt_commands[1][CMD_TERRITORY_MONEY_TREE_SHAKE_C] =
function(conn,pkt)
	g_faction_territory:check_new_day()
	local new_pkt = {}
	if g_faction_territory.money_tree:get_remain_time(conn.char_id) <= 0 then
		new_pkt.result = 20681
		g_cltsock_mgr:send_client(conn.char_id, CMD_TERRITORY_MONEY_TREE_SHAKE_S, new_pkt)
		return
	end
	local player = g_obj_mgr:get_obj(conn.char_id);
	local pack_con = player:get_pack_con();
	local slot = pack_con:get_slot_by_item_id(_f_t_c.MONEY_TREE_TOOL_ID)
	slot = slot or pack_con:get_slot_by_item_id(_f_t_c.MONEY_TREE_TOOL_ID+1)
	
	if not slot then
		new_pkt.result = 200009
		--test
		--new_pkt.result = f_shake_money_tree(conn.char_id)
	else
		new_pkt.result = stuff_f.use_stuff_no_db_click(conn.char_id, SYSTEM_BAG, slot, conn.char_id)
	end
	
	g_cltsock_mgr:send_client(conn.char_id, CMD_TERRITORY_MONEY_TREE_SHAKE_S, new_pkt)
end


--取摇树道具
Clt_commands[1][CMD_TERRITORY_MONEY_TREE_TOOL_C] =
function(conn,pkt)
	g_faction_territory:check_new_day()
	local new_pkt = g_faction_territory:get_money_tree_tool(conn.char_id)
	g_cltsock_mgr:send_client(conn.char_id, CMD_TERRITORY_MONEY_TREE_TOOL_S, new_pkt)
end

--传送到温泉或练功房
Clt_commands[1][CMD_TERRITORY_TRANSPORT_C] =
function(conn,pkt)
	g_faction_territory:check_new_day()
	local action = NpcContainerMgr:GetPlayerAction(conn.char_id)
	if not action or action.type ~= ACTION_TYPE_CHANGE_MAP_TOLL then
		NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_ACTION_NOT_RIGHT)
		return
	end

	local dst_area = action.transfer_list[tonumber(pkt.id)]
	if not dst_area then
		NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_TRANSFER_ID_NOT_FOUND)
		return
	end

	local type = 1
	if dst_area.map_id == 35400 then -- 练功房
		type = 2
	end
	local scene = g_scene_mgr_ex:get_scene({dst_area.map_id})
	local state = scene:get_status()
	if state ~= SCENE_STATUS.OPEN then
		NpcContainerMgr:SendError(conn.char_id, 20682, CMD_NPC_ACTION_CHANGE_MAP_S)
		return
	end

	local need_gold = g_faction_territory:get_transport_need_gold(conn.char_id, type)
	if need_gold > 0 then
		local new_pkt = {}
		new_pkt.need_gold = need_gold
		new_pkt.action_id = pkt.action_id
		new_pkt.id = pkt.id
		--new_pkt.name = g_faction_territory:get_owner_name()
		new_pkt.name = dst_area.name
		g_cltsock_mgr:send_client(conn.char_id, CMD_TERRITORY_TRANSPORT_S, new_pkt)
		return
	end	


	local pos = {}
	pos[1] = dst_area.pos_x
	pos[2] = dst_area.pos_y
	local error = f_scene_carry(conn.char_id, dst_area.map_id, pos)
	if 0 ~= error then
		NpcContainerMgr:SendError(conn.char_id, error)
	end
end

--扣铜币传送到温泉或练功房
Clt_commands[1][CMD_TERRITORY_SURE_TRANSPORT_C] =
function(conn,pkt)
	g_faction_territory:check_new_day()
	local action = NpcContainerMgr:GetPlayerAction(conn.char_id)
	if not action or action.type ~= ACTION_TYPE_CHANGE_MAP_TOLL then
		NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_ACTION_NOT_RIGHT)
		return
	end

	local dst_area = action.transfer_list[tonumber(pkt.id)]
	if not dst_area then
		NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_TRANSFER_ID_NOT_FOUND)
		return
	end

	local type = 1
	if dst_area.map_id == 35400 then -- 练功房
		type = 2
	end
	local scene = g_scene_mgr_ex:get_scene({dst_area.map_id})
	local state = scene:get_status()
	if state ~= SCENE_STATUS.OPEN then
		NpcContainerMgr:SendError(conn.char_id, 20682, CMD_NPC_ACTION_CHANGE_MAP_S)
		return
	end

	local need_gold = g_faction_territory:get_transport_need_gold(conn.char_id, type)
	if need_gold > 0 then
		local player = g_obj_mgr:get_obj(conn.char_id)
		local pack_con = player:get_pack_con()
		local money = pack_con:get_money()
		if money.gift_gold + money.gold < need_gold then
			NpcContainerMgr:SendError(conn.char_id, 200008, CMD_NPC_ACTION_CHANGE_MAP_S)
			return
		end
		
		if money.gift_gold > 0 and pack_con:check_money_lock(MoneyType.GIFT_GOLD) then			return		end
		if money.gift_gold < need_gold then
			if pack_con:check_money_lock(MoneyType.GOLD) then				return			end
			local temp_gold = need_gold - money.gift_gold
			pack_con:dec_money(MoneyType.GIFT_GOLD, money.gift_gold, {['type']=MONEY_SOURCE.NPC_SCENE_CARRY})
			pack_con:dec_money(MoneyType.GOLD, temp_gold, {['type']=MONEY_SOURCE.NPC_SCENE_CARRY})
		else
			pack_con:dec_money(MoneyType.GIFT_GOLD, need_gold, {['type']=MONEY_SOURCE.NPC_SCENE_CARRY})
		end
		g_faction_territory:add_transport_list(conn.char_id, type)
		g_faction_territory:add_faction_money(need_gold)
	end	

	local pos = {}
	pos[1] = dst_area.pos_x
	pos[2] = dst_area.pos_y
	local error = f_scene_carry(conn.char_id, dst_area.map_id, pos)
	if 0 ~= error then
		NpcContainerMgr:SendError(conn.char_id, error)
	end

end



--帮派副本争夺传送
Clt_commands[1][CMD_TERRITORY_COPY_OCCUPY_C] =
function(conn,pkt)
	local action = NpcContainerMgr:GetPlayerAction(conn.char_id)
	if not action or action.type ~= ACTION_TYPE_TERRITORY_COPY_OCCUPY then
		NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_ACTION_NOT_RIGHT)
		return
	end

	local dst_area = action.transfer_list[1]
	if not dst_area then
		NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_TRANSFER_ID_NOT_FOUND)
		return
	end

	local prototype = g_scene_mgr_ex:get_prototype(dst_area.map_id)
	local obj = g_obj_mgr:get_obj(conn.char_id)

	if not prototype or not obj then
		NpcContainerMgr:SendError(conn.char_id, 200200)
		return
	end

	local map_id, pos = nil, nil
	map_id = dst_area.map_id
	pos = {dst_area.pos_x, dst_area.pos_y}

	local e_code, error_list = prototype:carry_scene(obj, {map_id, pos})
	if SCENE_ERROR.E_SUCCESS ~= e_code then
		local new_pkt = {}
		new_pkt.result = e_code
		new_pkt.error_l = error_l
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_CHANGE_MAP_S, new_pkt)
	end
end

--帮派攻防战传送
Clt_commands[1][CMD_TERRITORY_BATTLE_TRANSPORT_C] =
function(conn,pkt)
	local action = NpcContainerMgr:GetPlayerAction(conn.char_id)
	if not action or action.type ~= ACTION_TYPE_TERRITORY_BATTLE then
		NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_ACTION_NOT_RIGHT)
		return
	end

	local dst_area = action.transfer_list[1]
	if not dst_area then
		NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_TRANSFER_ID_NOT_FOUND)
		return
	end

	local prototype = g_scene_mgr_ex:get_prototype(dst_area.map_id)
	local obj = g_obj_mgr:get_obj(conn.char_id)

	if not prototype or not obj then
		NpcContainerMgr:SendError(conn.char_id, 200200)
		return
	end

	local map_id, pos = nil, nil
	if prototype:is_attacker(obj) then
		map_id, pos = prototype:get_attack_layer_pos(obj)
	else
		map_id, pos = prototype:get_defense_layer_pos(obj)
	end
	if map_id == nir or pos == nil then
		map_id = dst_area.map_id
		pos = {dst_area.pos_x, dst_area.pos_y}
	end
	local e_code, error_list = prototype:carry_scene(obj, {map_id, pos})
	if SCENE_ERROR.E_SUCCESS ~= e_code then
		local new_pkt = {}
		new_pkt.result = e_code
		new_pkt.error_l = error_l
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_CHANGE_MAP_S, new_pkt)
	end
end

--帮派攻防最后结果得分下页
Clt_commands[1][CMD_TERRITORY_BATTLE_SCORE_PAGE_C] =
function(conn,pkt)
	local scene = g_scene_mgr_ex:get_prototype(2401000)
	local new_pkt = scene:get_battle_score(pkt.type, pkt.page)
	if new_pkt == nil then return end
	g_cltsock_mgr:send_client(conn.char_id, CMD_TERRITORY_BATTLE_SCORE_PAGE_S, new_pkt)
end

--攻防战战况信息  
Clt_commands[1][CMD_TERRITORY_BATTLE_INFO_C] =
function(conn,pkt)
	local scene = g_scene_mgr_ex:get_prototype(2401000)
	local new_pkt = scene:get_battle_info(conn.char_id)
	if new_pkt == nil then return end
	g_cltsock_mgr:send_client(conn.char_id, CMD_TERRITORY_BATTLE_INFO_S, new_pkt)
end

--攻防战战况信息  
Clt_commands[1][CMD_TERRITORY_BATTLE_INFO_PAGE_C] =
function(conn,pkt)
	if pkt.type == nil or pkt.page == nil then return end
	local scene = g_scene_mgr_ex:get_prototype(2401000)
	local new_pkt = {}
	new_pkt.list = scene:get_battle_info_page(pkt.type, pkt.page)
	if new_pkt.list == nil then return end
	new_pkt.type = pkt.type 
	new_pkt.page = pkt.page
	g_cltsock_mgr:send_client(conn.char_id, CMD_TERRITORY_BATTLE_INFO_PAGE_S, new_pkt)
end
