


local reset_loader = require("npc.config.reset_loader")
local reset_seal_loader = require("npc.config.reset_seal_loader")

local reset_count = {	[1]	= true,
						[4] = true}

--装备洗炼
Clt_commands[1][CMD_NPC_RESET_EQUIP_C]=
function(conn, pkt)
	if not conn.char_id or not pkt.bag or not pkt.slot or not pkt.material_l or not pkt.reset
			or not pkt.count or not reset_count[pkt.count] or not pkt.retain or not pkt.m_type then return end

	--过滤掉重复的锁定项
	for k, v in pairs(pkt.retain) do
		for kk, vv in pairs(pkt.retain) do
			if kk ~= k and vv == v then
				return
			end
		end
	end

	local player = g_obj_mgr:get_obj(conn.char_id)
	local pack_con = player:get_pack_con()
	if pack_con:check_money_lock(MoneyType.GOLD) or pack_con:check_money_lock(MoneyType.GIFT_GOLD) then return end --上锁
	if pack_con:check_item_lock_by_bag_slot(SYSTEM_BAG, pkt.material_l[1]) then return end --上锁
	local equip = pack_con:get_item_by_bag_slot(pkt.bag,pkt.slot)
	
	--物品不存在
	if not equip then
	    NpcContainerMgr:SendError(conn.char_id,ERROR_NPC_NOT_FIND_ITEM)
		return 
	end

	--不是装备
	if not equip.item.is_equipment then
	    NpcContainerMgr:SendError(conn.char_id,43063)
		return
	end

	local lock_cnt = 0
	local lock_cost_cnt = 0
	if equip.item:get_req_lvl() >= 1 then			--开放锁定的等级
		for k, v in pairs(pkt.retain or {}) do
			lock_cnt = lock_cnt + 1
		end
		lock_cnt = lock_cnt * pkt.count
		if lock_cnt > 0 then
			if lock_cnt - player:get_free_lock_cnt() < 0 then
				lock_cost_cnt = 0
			else
				lock_cost_cnt = lock_cnt - player:get_free_lock_cnt()
			end
			--if lock_cost_cnt > 5 then
				--return
			--end
		end 
	end
	

	--绿装以上
	local color = equip.item:get_color()
	if color < EquipColor.GREEN then
	    NpcContainerMgr:SendError(conn.char_id,43062)
		return 
	end
	
	--洗练种类不对
	local reset_type = pkt.reset
	if reset_type < 1 or reset_type > 3 then
		NpcContainerMgr:SendError(conn.char_id,43015)
		return
	end


	local t_rand = reset_loader.RandomTable[reset_type]
	local equip_level = equip.item.proto.value.level
	--没有物品
	if not equip_level then
		NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_NOT_FIND_ITEM)
		return 
	end

	local match_level = get_equip_index(reset_type, equip_level)
	local money_node = t_rand.money_list[match_level][color]
	local need_money = money_node.req_money * pkt.count
	local money_type = money_node.money_type

	local money = 0
	local bag_money = pack_con:get_money()
	if money_type == MoneyType.GOLD then
		money = bag_money.gift_gold+bag_money.gold
	elseif money_type == MoneyType.GIFT_GOLD then
		money = bag_money.gift_gold +bag_money.gift_gold
	elseif money_type == MoneyType.JADE then
		money = bag_money.gift_gold+bag_money.jade
	end

	--不够钱
	if money < need_money then
	    NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_NOT_ENOUGH_GOLD)
		return 
	end

	--没有道具
	local bind_flags = false
	local tool_list = {}
	local tool_id
	local gem_cnt = pkt.count
	for k, v in ipairs(pkt.material_l) do
		if gem_cnt <= 0 then break end
		local tmp_slot = pack_con:get_item_by_bag_slot(SYSTEM_BAG, v)
		local tmp_table = {}
		tmp_table.slot = v
		if not tool_id then
			tool_id = tmp_slot.item_id
		else
			if tool_id ~= tmp_slot.item_id then
				NpcContainerMgr:SendError(conn.char_id, 200116)
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
	
	if not tool_id or gem_cnt > 0 then
		local ret = {}
		ret.result = 27615
		g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_RESET_EQUIP_S, ret)
		return
	end
	local material_list = t_rand.material_list[color]
	local valid_material = false
	for _, v in pairs(material_list or {}) do
		if tool_id == tonumber(v.id) then
			valid_material = true
		end
	end

	if not valid_material then
		local ret = {}
		ret.result = 27615
		g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_RESET_EQUIP_S, ret)
		return
	end

	--减钱减材料
	if lock_cost_cnt > 0 then		--锁定花费
		local need_item = ITEM_CURRENCY.EQUIP_RESET_LOCK
		local s_pkt = {}
		s_pkt.result = pack_con:del_item_by_item_id_inter_face(need_item, lock_cost_cnt,  {['type']=ITEM_SOURCE.EQUIP_RANDOM}, 1)	
		
		if s_pkt.result ~= 0 then
			g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_RESET_EQUIP_S, s_pkt)
			return
		end
	end

	local gift_money = bag_money.gift_gold
	if need_money <= gift_money then
		pack_con:dec_money(MoneyType.GIFT_GOLD, need_money, {['type']=MONEY_SOURCE.EQUIP_RANDOM})
	else
		local left_money = need_money - gift_money
		pack_con:dec_money(MoneyType.GIFT_GOLD, gift_money, {['type']=MONEY_SOURCE.EQUIP_RANDOM})
		pack_con:dec_money(MoneyType.GOLD, left_money, {['type']=MONEY_SOURCE.EQUIP_RANDOM})
	end

	for k, v in pairs(tool_list) do
		pack_con:del_item_by_bag_slot(SYSTEM_BAG, v.slot, v.number, {['type']=ITEM_SOURCE.EQUIP_RANDOM})
	end

	player:add_lock_cnt(pkt.count * lock_cnt)

	--绑定
	if tool_id % 2 == 0 then
	    equip.item:set_bind()
	end
    --1全部洗练；2数值洗练
	local e_code = pack_con:reset_equip(equip, reset_type, pkt.count, pkt.retain)

	local ret = {}
	ret.result = e_code
	if e_code ~= 0 then
		ret.result = 27614
	end
	
	g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_RESET_EQUIP_S, ret)
	send_free_lock_count(conn.char_id)
end


function get_equip_index(rand_flag,equip_level)
	local equip_level_list = reset_loader.RandomTable[rand_flag].money_list
	for k,v in pairs(equip_level_list or {}) do
		if equip_level >=v.min and equip_level <= v.max then
			return k
		end
	end
	return 0
end

Clt_commands[1][CMD_MAP_RESET_CHOICE_B]=
function(conn, pkt)
	if not conn.char_id or not pkt.bag or not pkt.slot or not pkt.index then return end

	local player = g_obj_mgr:get_obj(conn.char_id)
	local pack_con = player:get_pack_con()
	if not pack_con then return end
	if pack_con:check_item_lock_by_bag_slot(pkt.bag, pkt.slot) then return end --上锁

	local equip = pack_con:get_item_by_bag_slot(pkt.bag,pkt.slot)
	--物品不存在
	if not equip then
	    NpcContainerMgr:SendError(conn.char_id,ERROR_NPC_NOT_FIND_ITEM)
		return 
	end

	--不是装备 or 不是 封灵装备
	if not equip.item.is_equipment and not equip.item.is_equipsealment then
	    NpcContainerMgr:SendError(conn.char_id,43063)
		return
	end

	local e_code = equip.item:get_reset_attribute(pkt.index)
	if e_code == 0 then
		if equip.item.is_equipment then
			pack_con:update_grid({equip}, {['type']=ITEM_SOURCE.EQUIP_RANDOM})
		elseif equip.item.is_equipsealment then
			pack_con:update_grid({equip}, {['type']=ITEM_SOURCE.EQUIP_SEAL_RANDOM})
		end

		--更新人物
		if pkt.bag == EQUIPMENT_BAG or pkt.bag == EQUIPSEAL_BAG then
			player:on_update_attribute(2)
		end
	end

	g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_RESET_CHOICE_S, {["result"] = e_code})
end

--查询剩余洗练次数
Clt_commands[1][CMD_NPC_FREE_RESET_EQUIP_C]=
function(conn, pkt)
	send_free_lock_count(conn.char_id)
end

function send_free_lock_count(char_id)
	local player = g_obj_mgr:get_obj(char_id)
	if not player then return end
	g_cltsock_mgr:send_client(char_id, CMD_NPC_FREE_RESET_EQUIP_S, {["cnt"] = player:get_free_lock_cnt()})
end

--封灵装备洗练(参数跟之前装备洗练一样)
Clt_commands[1][CMD_NPC_RESET_SEALEQUIP_C]=
function(conn, pkt)
	if not pkt.bag or not pkt.slot or not pkt.material_l or not pkt.reset
	or not pkt.count or not reset_count[pkt.count] or not pkt.retain then return end
	local player = g_obj_mgr:get_obj(conn.char_id)
	local pack_con = player:get_pack_con()
	if pack_con:check_money_lock(MoneyType.GOLD) or pack_con:check_money_lock(MoneyType.GIFT_GOLD) then return end --上锁
	if pack_con:check_item_lock_by_bag_slot(SYSTEM_BAG, pkt.material_l[1]) then return end --上锁
	local equip = pack_con:get_item_by_bag_slot(pkt.bag,pkt.slot)
	
	--物品不存在
	if not equip then
	    NpcContainerMgr:SendError(conn.char_id,ERROR_NPC_NOT_FIND_ITEM)
		return 
	end

	--不是装备
	if not equip.item.is_equipsealment then
	    NpcContainerMgr:SendError(conn.char_id,43063)
		return
	end

	--验证钱
	local color = equip.item:get_color()
	local need_money = reset_seal_loader.get_reset_money(color) * pkt.count
	local money  = pack_con:get_money()
	if money.gold + money.gift_gold < need_money then
		NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_NOT_ENOUGH_GOLD)
		return 
	end	
	local material = pack_con:get_item_by_bag_slot(SYSTEM_BAG, pkt.material_l[1])
	if not material then 
		NpcContainerMgr:SendError(conn.char_id, 27615)
		return
	end	

	--验证洗练道具
	local material_id = material.item:get_item_id()
	local need_material = reset_seal_loader.get_reset_material(color)
	if not need_material[material_id] then
		NpcContainerMgr:SendError(conn.char_id, 200010)
		return 
	end
	--需要洗练道具的数量
	local need_material_count = need_material[material_id] * pkt.count
	if pack_con:get_all_item_count(material_id) < need_material_count then
		NpcContainerMgr:SendError(conn.char_id, 31161)
		return
	end
	--验证锁定道具的数量
	--锁定属性的个数
	local lock_cnt = 0
	for i,v in pairs(pkt.retain or {}) do
		lock_cnt = lock_cnt + 1
	end
	local ret = {}
	if lock_cnt > 0 then
		local need_lock_item = ITEM_CURRENCY.EQUIP_RESET_SEAL_LOCK
		local need_lock_item_count = lock_cnt * pkt.count
		if pack_con:get_all_item_count(need_lock_item) < need_lock_item_count then
			NpcContainerMgr:SendError(conn.char_id, 31161)
			return
		end
		ret.result = pack_con:del_item_by_item_id_inter_face(need_lock_item,need_lock_item_count,{['type']=ITEM_SOURCE.EQUIP_SEAL_RANDOM}, 1)
		if ret.result ~= 0 then
			NpcContainerMgr:SendError(conn.char_id, ret.result)
			return
		end
	end
	
	local money_list = {}
	money_list[MoneyType.GIFT_GOLD] = need_money
	ret.result = pack_con:dec_money_l_inter_face(money_list, {['type']=MONEY_SOURCE.EQUIP_SEAL_RANDOM},1)
	
	if ret.result ~= 0 then
		NpcContainerMgr:SendError(conn.char_id, ret.result)
		return
	end

	ret.result = pack_con:del_item_by_item_id_inter_face(material_id,need_material_count,{['type']=ITEM_SOURCE.EQUIP_SEAL_RANDOM}, 1)

	if ret.result ~= 0 then
		NpcContainerMgr:SendError(conn.char_id, ret.result)
		return
	end
	if material_id % 2 == 0 then
		equip.item:set_bind()
	end

	local t_retain = {}
	for i,v in pairs(pkt.retain) do
		t_retain[tonumber(v)] = true
	end
	ret.result = equip.item:reset_appent(pkt.count, t_retain)
	pack_con:count_seal_fighting()  --计算总战斗力
	player:on_dress_update(21)      --更新外观显示
	local e_code, ctn = pack_con:get_bag(pkt.bag)
	local log_list = {}
	log_list[1] = ctn:get_update_log(ItemSyncFlag.ITEM_SYNC_UPDATE, pkt.slot)
	local src_log = {['type']=ITEM_SOURCE.EQUIP_SEAL_RANDOM}
	pack_con:update_client(0, log_list, src_log)
	g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_RESET_SEALEQUIP_S, ret)

end

--封灵装备外观是否展现
Clt_commands[1][CMD_NPC_SHOW_SEALEQUIP_C]=
function(conn,pkt)
	if not pkt and not pkt.show then return end
	local player = g_obj_mgr:get_obj(conn.char_id)
	local pack_con = player:get_pack_con()
	
	local e_code , bag = pack_con:get_bag(EQUIPSEAL_BAG)
	if e_code ~= 0 then return end
	bag:set_show(pkt.show)
	player:on_dress_update(21)
	g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_SHOW_SEALEQUIP_S, {["result"] = 0})
end