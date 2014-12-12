local debug_print = print
--local debug_print = function () end
local gbk_utf8 = function(val) return val end

local intensify_loader = require("config.loader.intensify_loader")
local intensify_config = require("config.intensify_congra_config")
--local integral_loader = require("config.integral_config") 

local occ_list = {11, 41, 51}

local function is_vailed(equip_t_class,part_list)
	local index_list = {}
	for k,v in pairs(part_list) do
		local i,j = string.find(v,equip_t_class)
		if i ~=nil and j ~= nil then
			table.insert(index_list,k)
		end
	end
	return index_list
end

--装备强化
Clt_commands[1][CMD_NPC_INTENSIFY_EQUIP_C] =
	function(conn, pkt)
		if not pkt.bag or not pkt.slot then return end
		local player = g_obj_mgr:get_obj(conn.char_id)
		local pack_con = player:get_pack_con()
		if pack_con:check_money_lock(MoneyType.GOLD) or pack_con:check_money_lock(MoneyType.GIFT_GOLD) then return end --上锁
		if pack_con:check_item_lock_by_bag_slot(pkt.stone.bag, pkt.stone.slot) then return end --上锁
		local equip = pack_con:get_item_by_bag_slot(pkt.bag, pkt.slot)
		if not equip then
			NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_NOT_FIND_ITEM)
			return
		end

		--判断是不是装备类
		if not equip.item.is_equipment and not equip.item.is_equipsealment then
			NpcContainerMgr:SendError(conn.char_id, 43015)
			return
		end

		----达到最大强化级数了返回
		if not equip.item.can_intensify or equip.item:can_intensify() ~= 0 then
			NpcContainerMgr:SendError(conn.char_id, 200035)
			return
		end

		--根据装备获得强化所需要装料及金钱
		local rank = tonumber(equip.item.rank) + 1

		--获取强化所需金钱
		local match_level = math.floor(equip.item.proto.value.level)
		local req_lvl = math.floor(equip.item.proto.value.req_lvl) -- 兼容90级装备id配置问题出现的强化bug
		local lvl_node = intensify_loader.Intensify_table[rank].lvl_list[match_level] or intensify_loader.Intensify_table[rank].lvl_list[req_lvl]
		if equip.item.is_equipsealment then
			lvl_node = intensify_loader.Intensify_table[rank].lvl_seal_list[match_level] or intensify_loader.Intensify_table[rank].lvl_seal_list[req_lvl]
			if not lvl_node then print("seal not lvl_node") return end
		end		
		local need_money = lvl_node and lvl_node.price		
		local money = pack_con:get_money()
		if money.gift_gold + money.gold  < need_money then
			NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_NOT_ENOUGH_GOLD)
			return
		end

		--获取所需材料
		local stone_item = pack_con:get_item_by_bag_slot(pkt.stone.bag, pkt.stone.slot)
		if not stone_item then
			NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_NOT_FIND_ITEM)
			return
		end

		local stone_id = stone_item.item_id
		local need_num = lvl_node.req_material_num
		local temp     = 0
		local stone_num = pack_con:get_item_count(stone_id)
		local del_list = {}
		local is_bind = equip.item.bind -- 0 绑定
	
		if stone_num < need_num then
			is_bind = 0
			if stone_num > 0 then
				del_list[stone_id] = stone_num
			end
			temp = need_num - stone_num
			if stone_item.item_id % 2 == 0 then
				stone_id = stone_id + 1
			else
				stone_id = stone_id - 1
			end
			stone_num = pack_con:get_item_count(stone_id)
			if stone_num < temp then
				NpcContainerMgr:SendError(conn.char_id, 22832)
				return
			end
			del_list[stone_id] = temp
		else
			del_list[stone_id] = need_num
			is_bind = stone_item.item:get_bind()
		end

		local equip_t_class = equip.item:get_t_class()         --取出装备部位
		local part_list = intensify_loader.Intensify_table[rank].part_list
		local index_list = is_vailed(tostring(equip_t_class),part_list)
		local mater_list = intensify_loader.Intensify_table[rank].material_list
		
		local valid_stone = false
		for k,v in pairs(index_list or {}) do
			if tonumber(mater_list[v]) == stone_item.item_id then
				valid_stone = true
			end
		end
	
		local req_lvl = stone_item.item:get_req_lvl()
		req_lvl = tonumber(req_lvl)
		 --判断对象等级是否高于物品等级
		if player:get_level() < req_lvl then
			NpcContainerMgr:SendError(conn.char_id, E_INVALID_LEVEL)
			return
		end

		if not valid_stone then
			NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_NOT_ENOUGH_ITEM)
			return
		end

		--强化成功率
		local s_r = crypto.random(0,100)
		local npro = table.size(pkt.add_per or {})
		--强化最多可以使用1个完美符
		if npro > MAX_PROTECT_GEM then
			print(gbk_utf8("强化最多可以使用1个五彩神石"))
			return
		end

		
		local c_r = intensify_loader.Intensify_table[rank].s_rate
		if equip.item.is_equipsealment then
			c_r = intensify_loader.Intensify_table[rank].s_seal_rate
		end	
		for _, n in pairs(pkt.add_per or {}) do
			local item = pack_con:get_item_by_bag_slot(n.bag, n.slot)
			if not item then
				g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_INTENSIFY_EQUIP_S, {["result"] = 25015}) 
				return 
			end
			local req_lvl = item.item:get_req_lvl()
			req_lvl = tonumber(req_lvl)
			 --判断对象等级是否高于物品等级
			if player:get_level() < req_lvl then
				NpcContainerMgr:SendError(conn.char_id, E_INVALID_LEVEL)
				return
			end

			local add_r = intensify_loader.Intensify_table[rank].add_s_rate_list[item.item_id]
			
			if not add_r then 
				g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_INTENSIFY_EQUIP_S, {["result"] = 25015})
				return
			end

			if add_r then
				c_r = c_r + add_r
			end

			if is_bind == 1 then
				if item.item:get_bind() == 0 then
					is_bind = 0
				end
			end
		end

		local s_pkt = {}
		s_pkt.result = 0
		s_pkt.rank = rank

		--如果强化石是绑定的,装备变成绑定
		if is_bind == 0 then --stone_item.item:get_bind() == 0 or 
			equip.item:set_bind()
		end

		--vip 加成
		local addition = player:get_addition(HUMAN_ADDITION.intensify)
		if addition < 0 then return end
		c_r = c_r + addition * 100

		if equip.item:get_benediction() and equip.item:get_benediction() >= intensify_config.get_luck_intensify(equip.item:get_level()) then
			s_r = 0
		end

		equip.item:set_perfect((100-s_r))

		--条件满足,执行强化操作
		local res = 0 
		if s_r < c_r  then
			equip.item:set_perfect(0)
			res = pack_con:intensify_equip(equip)
			if res ~= 0 then
				s_pkt.result = res
				g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_INTENSIFY_EQUIP_S, s_pkt)
				return
			end
			s_pkt.add_append  = equip.item:get_intensify_attr()
			s_pkt.add_rewards = equip.item:get_intensify_reward_attr()
			s_pkt.rank = equip.item.rank
			s_pkt.perfect_rewards = equip.item:get_intensify_perfect_attr()
			s_pkt.perfect = equip.item:get_perfect()

			--世界广播
			if equip.item.rank >= 31 then
				local sys_l = {}
				sys_l[1] = player:get_name()
				sys_l[2] = equip.item:get_name()
				sys_l[3] = equip.item.rank

				local color_l = {}
				color_l[2] = equip.item:get_color()
				local str_json = f_get_sysbd_format(10002, sys_l, color_l)
				f_cmd_sysbd(str_json)
			end

			--强化成功通知
			local args = {}
			args.item_id = equip.item:get_item_id()
			args.class = equip.item:get_t_class()
			args.level = equip.item.rank
			g_event_mgr:notify_event(EVENT_SET.EVENT_INTENSIFY, conn.char_id, args)
		
			--f_intensify_notify(conn.char_id, equip.item:get_s_class(), equip.item.rank)

		else --失败回落
			s_pkt.result = 200036
			res = pack_con:degenerate_equip(equip)
			if res ~= 0 then
				s_pkt.result = res
				g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_INTENSIFY_EQUIP_S, s_pkt)
				return
			end
			s_pkt.rank = equip.item.rank
			s_pkt.perfect_rewards = equip.item:get_intensify_perfect_attr()
			s_pkt.perfect = equip.item:get_perfect()
			--在强化+4,+7,+10,+12时回落则获得相应的礼包
			--if intensify_loader.Intensify_table[rank].reward_gift then
				--if pack_con:get_bag_free_slot_cnt() <= 0 then
					--NpcContainerMgr:SendError(conn.char_id, 43004)
					----如果背包已满则以邮件的方式发给玩家
					--local e_pkt = {}
					--e_pkt.char_lst = {}
					--e_pkt.char_lst[1] = {}
					--e_pkt.char_lst[1]["char_id"] = conn.char_id
					----e_pkt.char_lst[1]["email_id"] = 0
					--e_pkt.email_title = gbk_utf8("系统邮件")
					--e_pkt.email_content = gbk_utf8("您的背包已满，通过邮件给您发放强化奖励。")
					--local e_code, gift_item = Item_factory.create(tonumber(intensify_loader.Intensify_table[rank].reward_gift))
					--local item_list = {}
					--item_list["item_id"] = tonumber(intensify_loader.Intensify_table[rank].reward_gift)
					--item_list["item"] = gift_item
					--e_pkt.item = item_list
					--g_svsock_mgr:send_server_ex(WORLD_ID, 0, CMD_M2W_ADD_GOODS_ACK, e_pkt)

					--s_pkt.gift = {}
					--s_pkt.gift["gift_type"] = 1
					--s_pkt.gift["gift_id"] = tostring(intensify_loader.Intensify_table[rank].reward_gift)
					--s_pkt.gift["name"] = gift_item:get_name()
				--else
					--local e_code, gift_item = Item_factory.create(tonumber(intensify_loader.Intensify_table[rank].reward_gift))
					--pack_con:add_by_item(gift_item, {['type'] = ITEM_SOURCE.INTENSIFY})

					--s_pkt.gift = {}
					--s_pkt.gift["gift_type"] = 0
					--s_pkt.gift["gift_id"] = tostring(intensify_loader.Intensify_table[rank].reward_gift)
					--s_pkt.gift["name"] = gift_item:get_name()
				--end
			--end
		end
		--不管成功与失败都扣五彩神石
		local ret = {}
		for k, pro in pairs(pkt.add_per or {}) do
			if pack_con:check_item_lock_by_bag_slot(pro.bag,pro.slot) then return end
			--pack_con:del_item_by_bag_slot(pro.bag, pro.slot, 1, {['type']=ITEM_SOURCE.INTENSIFY})
			ret[k] = {}
			ret[k][1] = pro.bag
			ret[k][2] = pro.slot
			ret[k][3] = 1
		end
		if table.size(pkt.add_per) > 0 then
			pack_con:del_item_by_bags_slots(ret,{['type']=ITEM_SOURCE.INTENSIFY},1)
		end
		
		--删除宝石和金钱
		--pack_con:del_item_by_bag_slot(pkt.stone.bag, pkt.stone.slot, 1, {['type']=ITEM_SOURCE.INTENSIFY})
		
		--pack_con:del_item_by_item_id_inter_face(stone_item.item_id, need_num, {['type']=ITEM_SOURCE.INTENSIFY}, 1)
		for k, v in pairs(del_list) do
			ret.result = pack_con:del_item_by_item_id(k, v, {['type']=ITEM_SOURCE.GEM_FAST_LEVELUP})
		end	

		if need_money < money.gift_gold then
			pack_con:dec_money(MoneyType.GIFT_GOLD, need_money, {['type']=MONEY_SOURCE.INTENSIFY})
		else
			local left_money = need_money - money.gift_gold
			pack_con:dec_money(MoneyType.GIFT_GOLD, money.gift_gold, {['type']=MONEY_SOURCE.INTENSIFY})
			pack_con:dec_money(MoneyType.GOLD, left_money, {['type']=MONEY_SOURCE.INTENSIFY})
		end
		g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_INTENSIFY_EQUIP_S, s_pkt)

		--更新人物
		if pkt.bag == EQUIPMENT_BAG or pkt.bag == EQUIPSEAL_BAG then
			if pkt.bag == EQUIPSEAL_BAG then
				pack_con:count_seal_fighting()
				player:on_dress_update(21)				
			else
				player:on_update_attribute(2)
			end
		end
end

--强化转移
Clt_commands[1][CMD_B2M_TRANSFER_EQUIP_C] =
	function(conn, pkt)
		if conn.char_id == nil or pkt == nil then 
		    return;
		end

		local s_pkt = {};

		local player = g_obj_mgr:get_obj(conn.char_id)
		local pack_con = player:get_pack_con()
		if pack_con == nil then 
		    return;
		end
		local bag_id = pkt[3]

		--主装备等级
		local slot_main=pkt[1];
		local main_equipment = pack_con:get_item_by_bag_slot(bag_id, slot_main)
		

		--副装备
		local uuid_vice = pkt[2]
		local vice_equipment = pack_con:get_item_by_uuid(uuid_vice)  
		if pack_con:check_item_lock_by_item_uuid(SYSTEM_BAG, uuid_vice) then return end--上锁

		if not main_equipment or not vice_equipment then
		    debug_print(">>main equipment and vice equipment is empty...");
			return;
		end;
		if pack_con:check_item_lock_by_item(main_equipment.item) then return end--上锁
		
		 --是否为装备
		if main_equipment.item:get_m_class()~=ItemClass.ITEM_CLASS_EQUIP or vice_equipment.item:get_m_class()~=ItemClass.ITEM_CLASS_EQUIP then
		    debug_print(">>equipments are not valuable...")
			
			
		    s_pkt.result =E_NOT_VALID_TARGET;
		    g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_TRANSFER_EQUIP_S, s_pkt)
		    return
		end;

		if main_equipment.item:get_t_class() ~= vice_equipment.item:get_t_class() then
		    debug_print(">>equipments are not the same...")
			
			s_pkt.result =27608;
		    g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_TRANSFER_EQUIP_S, s_pkt)
		    return
		end;

		--判断等级
		local main_rank=main_equipment.item:get_rank();
		local vice_rank = vice_equipment.item:get_rank()
		if main_rank >= MAX_EQUIP_RANK then
		    debug_print(">>over max rank...");
			
			s_pkt.result =27610;
		    g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_TRANSFER_EQUIP_S, s_pkt)
		    return
		end;
		if main_rank > vice_rank then
		    debug_print("main rank less than vice_rank...");
			
			s_pkt.result =27609;
		    g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_TRANSFER_EQUIP_S, s_pkt)
		    return
		end;
		
		--获取装备宝石
		local main_gem_l=main_equipment.item:get_gem_l();
		local vice_gem_l=vice_equipment.item:get_gem_l();
		for key,value in pairs(main_gem_l) do
		    if table.size(value) > 0 then
			   debug_print(">>already have ruby...");
			   s_pkt.result =27611;
		       g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_TRANSFER_EQUIP_S, s_pkt)
		       return
			end;
		end;
		--获取怒气宝石
		local main_rage_gem_l=main_equipment.item:get_rage_gem_l();
		local vice_rage_gem_l=vice_equipment.item:get_rage_gem_l();
		for key,value in pairs(main_rage_gem_l or {}) do
		    if table.size(value) > 0 then
			   s_pkt.result =27611;
		       g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_TRANSFER_EQUIP_S, s_pkt)
		       return
			end;
		end;

		--转移宝石
		if not vice_gem_l then
		    debug_print("vice gem list is null...");
		end;
		main_equipment.item.hole_t=vice_gem_l;
		if not main_equipment.item.hole_t then
		    debug_print(">>transfer failed...");
		end;
		--转移怒气宝石
		main_equipment.item.rage_hole_t = vice_rage_gem_l
		if not main_equipment.item.hole_t then
		    debug_print(">>transfer failed...");
		end

		--绑定宝石
		if vice_equipment.item:get_bind() == 0 then
		    main_equipment.item:set_bind();
		end;

		--设置强化等级
		local rank = vice_rank
	    if rank > MAX_EQUIP_RANK then 
		    rank = MAX_EQUIP_RANK
		end
	    main_equipment.item:set_rank(rank)   --设置主装备rank

		--转移完美度
		main_equipment.item:set_perfect(vice_equipment.item:get_perfect())

		--转移完美度附加属性
		main_equipment.item.intensify_perfect = vice_equipment.item.intensify_perfect or {}

		----加祝福
		--local bene = vice_equipment.item:get_benediction()
		--main_equipment.item:add_benediction(bene)

		-- 删除装备认主状态
		main_equipment.item:del_ack_state()

		pack_con:update_grid({main_equipment},{['type']=ITEM_SOURCE.TRANSFER_EQUIP})
		--删除副装备
		pack_con:del_item_by_uuid(SYSTEM_BAG,uuid_vice,1,{['type']=ITEM_SOURCE.TRANSFER_EQUIP});
		
		
		s_pkt.result = 0
		g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_TRANSFER_EQUIP_S, s_pkt)

		--更新人物
		if bag_id == EQUIPMENT_BAG then
			player:on_update_attribute(2)
		end
	end

--宠物装备强化转移
Clt_commands[1][CMD_MAP_PET_EQUIP_MERGE_B] =
	function(conn, pkt)
		if conn.char_id == nil or pkt == nil then 
		    return
		end

		local s_pkt = {}

		local player = g_obj_mgr:get_obj(conn.char_id)
		local pack_con = player:get_pack_con()
		if pack_con == nil then 
		    return
		end

		--主装备
		local slot_main=pkt[1]
		local main_equipment = pack_con:get_item_by_bag_slot(SYSTEM_BAG, slot_main)

		--副装备
		local uuid_vice = pkt[2]
		local vice_equipment = pack_con:get_item_by_bag_slot(SYSTEM_BAG, uuid_vice)  
		
		if not main_equipment or not vice_equipment then
			return
		end
		if pack_con:check_item_lock_by_item(vice_equipment.item) then return end--上锁
		if pack_con:check_item_lock_by_item(main_equipment.item) then return end--上锁

		 --是否为装备
		if not main_equipment.item.is_pet_equip or not vice_equipment.item.is_pet_equip then
		    s_pkt.result =200118
		    g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PET_EQUIP_MERGE_S, s_pkt)
		    return
		end

		if main_equipment.item:get_t_class() ~= vice_equipment.item:get_t_class() then			
			s_pkt.result =201003
		    g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PET_EQUIP_MERGE_S, s_pkt)
		    return
		end

		--判断等级
		local main_rank=main_equipment.item:get_level()
		local vice_rank = vice_equipment.item:get_level()
		if main_rank >= vice_rank then
			s_pkt.result =201004
		    g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PET_EQUIP_MERGE_S, s_pkt)
		    return
		end
		
		--判断品质
		local main_color = main_equipment.item:get_color()
		local vice_color = vice_equipment.item:get_color()
		if main_color < vice_color then
			s_pkt.result = 201005
		    g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PET_EQUIP_MERGE_S, s_pkt)
		    return
		end

		--等级经验
		local level = vice_equipment.item:get_level()
		local exp 	= vice_equipment.item:get_exp()

		--获取装备宝石
		local main_soul_l=main_equipment.item:get_soul_t()
		local vice_soul_l=vice_equipment.item:get_soul_t()
		if main_soul_l[1] then
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PET_EQUIP_MERGE_S, {['result'] = 201007})
		    return
		end

		--绑定
		if vice_equipment.item:get_bind() == 0 then
		    main_equipment.item:set_bind(0)
		end

		--删除副装备
		pack_con:del_item_by_bag_slot(SYSTEM_BAG, uuid_vice, 1, {['type']=ITEM_SOURCE.TRANSFER_EQUIP});

		--转移宝石
		main_equipment.item:set_soul_t(vice_soul_l)

		--转移等级经验
		main_equipment.item:set_level(level)
		main_equipment.item:set_exp(exp)
		main_equipment.item:update_attr()

		local e_code, ctn = pack_con:get_bag(SYSTEM_BAG)
		local log_list = {}
		log_list[1] = ctn:get_update_log(ItemSyncFlag.ITEM_SYNC_UPDATE, slot_main)
		pack_con:update_client(0, log_list, {['type']=ITEM_SOURCE.USE_ITEM})

		s_pkt.result = 0
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PET_EQUIP_MERGE_S, s_pkt)

	end

--宠物装备强化转移预览
Clt_commands[1][CMD_MAP_PET_EQUIP_M_REVIEW_B] =
	function(conn, pkt)
		if conn.char_id == nil or pkt == nil then 
		    return
		end

		local s_pkt = {}

		local player = g_obj_mgr:get_obj(conn.char_id)
		local pack_con = player:get_pack_con()
		if pack_con == nil then 
		    return
		end

		--主装备
		local slot_main=pkt[1]
		local main_equipment = pack_con:get_item_by_bag_slot(SYSTEM_BAG, slot_main)

		--副装备
		local uuid_vice = pkt[2]
		local vice_equipment = pack_con:get_item_by_bag_slot(SYSTEM_BAG, uuid_vice)  
		if not main_equipment or not vice_equipment then
			return
		end

		 --是否为装备
		if not main_equipment.item.is_pet_equip or not vice_equipment.item.is_pet_equip then
		    s_pkt.result =200118
		    g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PET_EQUIP_M_REVIEW_S, s_pkt)
		    return
		end

		if main_equipment.item:get_t_class() ~= vice_equipment.item:get_t_class() then			
			s_pkt.result =201003
		    g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PET_EQUIP_M_REVIEW_S, s_pkt)
		    return
		end

		--判断等级
		local main_rank=main_equipment.item:get_level()
		local vice_rank = vice_equipment.item:get_level()
		if main_rank >= vice_rank then
			s_pkt.result =201004
		    g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PET_EQUIP_M_REVIEW_S, s_pkt)
		    return
		end
		
		--判断品质
		local main_color = main_equipment.item:get_color()
		local vice_color = vice_equipment.item:get_color()
		if main_color < vice_color then
			s_pkt.result = 201005
		    g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PET_EQUIP_M_REVIEW_S, s_pkt)
		    return
		end

		--等级经验
		local level = vice_equipment.item:get_level()
		local exp 	= vice_equipment.item:get_exp()

		--获取装备宝石
		local main_soul_l=main_equipment.item:get_soul_t()
		local vice_soul_l=vice_equipment.item:get_soul_t()
		if main_soul_l[1] then
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PET_EQUIP_M_REVIEW_S, {['result'] = 201007})
		    return
		end

		--复制主装备
		local item_db = main_equipment.item:serialize_to_db()
		local err_code,tmp_item = Item_factory.clone(main_equipment.item:get_item_id(), item_db)

		--绑定
		if vice_equipment.item:get_bind() == 0 then
		    tmp_item:set_bind(0)
		end

		--转移宝石
		tmp_item:set_soul_t(vice_soul_l)

		--转移等级经验
		tmp_item:set_level(level)
		tmp_item:set_exp(exp)
		tmp_item:update_attr()

		s_pkt.result = 0
		s_pkt.item	 = tmp_item:serialize_to_net()
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PET_EQUIP_M_REVIEW_S, s_pkt)

	end

--装备强化 装备祝福 chendong 20121206
--[[
--装备祝福
Clt_commands[1][CMD_INTENSIFY_BENEDICTION_B] =
	function(conn, pkt)
		if not pkt or not pkt.slot or not pkt.bag then 
		    return
		end

		local s_pkt = {}
		local player = g_obj_mgr:get_obj(conn.char_id)
		local pack_con = player:get_pack_con()
		if pack_con == nil then 
		    return
		end


		--判断装备
		local slot = pack_con:get_item_by_bag_slot(pkt.bag , pkt.slot)
		local item = slot and slot.item
		if not item then
			s_pkt.result = 43001
			g_cltsock_mgr:send_client(conn.char_id, CMD_INTENSIFY_BENEDICTION_S ,s_pkt)
			return
		end
		if item:get_m_class()~=ItemClass.ITEM_CLASS_EQUIP then
			s_pkt.result = 43064
			g_cltsock_mgr:send_client(conn.char_id, CMD_INTENSIFY_BENEDICTION_S ,s_pkt)
			return
		end

		if pack_con:check_item_lock_by_item(item) then return end--上锁

		--进行祝福
		local error = item:do_benediction()
		if error ~= 0 then
			s_pkt.result = error
			g_cltsock_mgr:send_client(conn.char_id, CMD_INTENSIFY_BENEDICTION_S ,s_pkt)
			return
		end

		--更新
	    local e_code, ctn = pack_con:get_bag(pkt.bag)
		local log_list = {}
		log_list[1] = ctn:get_update_log(ItemSyncFlag.ITEM_SYNC_UPDATE, pkt.slot)		
		local src_log = {['type']=ITEM_SOURCE.USE_ITEM}
		pack_con:update_client(0, log_list,src_log)
		g_cltsock_mgr:send_client(conn.char_id, CMD_INTENSIFY_BENEDICTION_S ,{['result'] = e_code})
		if item:get_rank() >= 8 then
			local sys_l = {}
			sys_l[1] = player:get_name()
			sys_l[2] = item:get_name()
			sys_l[3] = item:get_rank()

			local color_l = {}
			color_l[2] = item:get_color()
			local str_json = f_get_sysbd_format(10002, sys_l, color_l)
			f_cmd_sysbd(str_json)
		end
		local args = {}
		args.item_id = item:get_item_id()
		args.class = item:get_t_class()
		args.level = item:get_rank()
		g_event_mgr:notify_event(EVENT_SET.EVENT_INTENSIFY, conn.char_id, args)

		pack_con:db_item_operation(log_list,{['type']=ITEM_SOURCE.USE_BENEDICTION})
		--更新人物
		if pkt.bag == EQUIPMENT_BAG then
			player:on_update_attribute(2)
		end

		return
	end
--]]

--祝福预览
--[[
Clt_commands[1][CMD_BENEDICTION_PREVIEW_B] =
	function(conn, pkt)		
		if not pkt or not pkt.slot or not pkt.bag then 
		    return
		end

		local s_pkt = {}
		local player = g_obj_mgr:get_obj(conn.char_id)
		local pack_con = player:get_pack_con()
		if pack_con == nil then 
		    return
		end

		--判断装备
		local slot = pack_con:get_item_by_bag_slot(pkt.bag , pkt.slot)
		local item = slot and slot.item
		if not item then
			s_pkt.result = 43001
			g_cltsock_mgr:send_client(conn.char_id, CMD_BENEDICTION_PREVIEW_S ,s_pkt)
			return
		end
		if item:get_m_class()~=ItemClass.ITEM_CLASS_EQUIP then
			s_pkt.result = 43064
			g_cltsock_mgr:send_client(conn.char_id, CMD_BENEDICTION_PREVIEW_S ,s_pkt)
			return
		end

		--祝福预览组包
		local item_id = item:get_item_id()
		local item_obj = item:spec_serialize_to_db()
		local e_code ,tmp_item = Item_factory.clone(item_id,item_obj)
		s_pkt.result = e_code
		if e_code ~= 0 then
			g_cltsock_mgr:send_client(conn.char_id, CMD_BENEDICTION_PREVIEW_S ,s_pkt)
			return
		else
			--s_pkt.preview = {}
			--for i = 7, MAX_EQUIP_RANK do
				tmp_item:set_rank(item:get_rank()+1)
				s_pkt.preview = tmp_item:spec_serialize_to_net() or {}
				--table.insert(s_pkt.preview, tmp_item:spec_serialize_to_net())
			--end
			g_cltsock_mgr:send_client(conn.char_id, CMD_BENEDICTION_PREVIEW_S ,s_pkt)
			return
		end

	end
--]]

--[[
--帮派领地装备强化
Clt_commands[1][CMD_TERRITORY_INTENSIFY_EQUIP_C] =
function(conn, pkt)
	if not pkt.bag or not pkt.slot then return end

	local player = g_obj_mgr:get_obj(conn.char_id)
	local pack_con = player:get_pack_con()
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

	--达到最大强化级数了返回
	if tonumber(equip.item.rank) >= MAX_EQUIP_RANK then
		NpcContainerMgr:SendError(conn.char_id, 200035)
		return
	end

	--根据装备获得强化所需要装料及金钱
	local rank = tonumber(equip.item.rank) + 1

	--获取强化所需金钱
	local match_level = math.floor(equip.item.proto.value.level)
	local req_lvl = math.floor(equip.item.proto.value.req_lvl) -- 兼容90级装备id配置问题出现的强化bug
	local lvl_node = intensify_loader.Intensify_table[rank].lvl_list[match_level] or intensify_loader.Intensify_table[rank].lvl_list[req_lvl]
	local need_money = lvl_node.price
	if not g_faction_territory:is_owner_territory(conn.char_id) then	-- 非帮派所属
		need_money = math.floor(need_money + need_money * g_faction_territory:get_intensify_money_per())
	end
	local money = pack_con:get_money()
	if money.gift_gold + money.gold  < need_money then
		NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_NOT_ENOUGH_GOLD)
		return
	end

	--获取所需材料
	local stone_item = pack_con:get_item_by_bag_slot(pkt.stone.bag, pkt.stone.slot)
	if not stone_item then
		NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_NOT_FIND_ITEM)
		return
	end

	local equip_t_class = equip.item:get_t_class()         --取出装备部位
	local part_list = intensify_loader.Intensify_table[rank].part_list
	local index_list = is_vailed(tostring(equip_t_class),part_list)
	local mater_list = intensify_loader.Intensify_table[rank].material_list
	local need_num = lvl_node.req_material_num
	local valid_stone = false
	for k,v in pairs(index_list or {}) do
		if tonumber(mater_list[v]) == stone_item.item_id then
			valid_stone = true
		end
	end

	if not valid_stone then
		NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_NOT_ENOUGH_ITEM)
		return
	end

	--强化成功率
	local s_r = crypto.random(0,100)
	local npro = table.size(pkt.add_per or {})
	--强化最多可以使用1个五彩神石
	if npro > MAX_PROTECT_GEM then
		print(gbk_utf8("强化最多可以使用1个五彩神石"))
		return
	end

	local is_bind = 1 --非绑定
	local c_r = intensify_loader.Intensify_table[rank].s_rate
	c_r = c_r + g_faction_territory:get_intensify_add_per()		-- 帮派领地加成
	for _, n in pairs(pkt.add_per or {}) do
		local item = pack_con:get_item_by_bag_slot(n.bag, n.slot)
		local add_r = intensify_loader.Intensify_table[rank].add_s_rate_list[item.item_id]

		if not add_r then 
			g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_INTENSIFY_EQUIP_S, {["result"] = 25015})
			return
		end

		if add_r then
			c_r = c_r + add_r
		end

		if is_bind == 1 then
			if item.item:get_bind() == 0 then
				is_bind = 0
			end
		end
	end

	local s_pkt = {}
	s_pkt.result = 0
	s_pkt.rank = rank

	--如果强化石是绑定的,装备变成绑定
	if stone_item.item:get_bind() == 0 or is_bind == 0 then
		equip.item:set_bind()
	end

	--vip 加成
	local addition = player:get_addition(HUMAN_ADDITION.intensify)
	if addition < 0 then return end
	c_r = c_r + addition * 100
	if c_r >= 90 then				--大于90默认为必定成功
		c_r = 100
	end

	equip.item:set_perfect((100-s_r))

	----加强化祝福
	--local stone_id = tonumber(string.sub(tostring(stone_item.item_id),1,11))
	--local c_value = intensify_config.get_congra(stone_id)
	--equip.item:add_benediction(c_value)

	--条件满足,执行强化操作
	if s_r < c_r  then
		equip.item:set_perfect(0)
		res = pack_con:intensify_equip(equip)
		if res ~= 0 then
			s_pkt.result = res
			g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_INTENSIFY_EQUIP_S, s_pkt)
			return
		end

		s_pkt.add_append  = equip.item:get_intensify_attr()
		s_pkt.add_rewards = equip.item:get_intensify_reward_attr()
		s_pkt.rank = equip.item.rank
		s_pkt.perfect_rewards = equip.item:get_intensify_perfect_attr()
		s_pkt.perfect = equip.item:get_perfect()

		--世界广播
		if equip.item.rank >= 8 then
			local sys_l = {}
			sys_l[1] = player:get_name()
			sys_l[2] = equip.item:get_name()
			sys_l[3] = equip.item.rank

			local color_l = {}
			color_l[2] = equip.item:get_color()
			local str_json = f_get_sysbd_format(10002, sys_l, color_l)
			f_cmd_sysbd(str_json)
		end

		--强化成功通知
		local args = {}
		args.item_id = equip.item:get_item_id()
		args.class = equip.item:get_t_class()
		args.level = equip.item.rank
		g_event_mgr:notify_event(EVENT_SET.EVENT_INTENSIFY, conn.char_id, args)
	
		--f_intensify_notify(conn.char_id, equip.item:get_s_class(), equip.item.rank)

	else --失败回落
		s_pkt.result = 200036
		res = pack_con:degenerate_equip(equip)
		if res ~= 0 then
			s_pkt.result = res
			g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_INTENSIFY_EQUIP_S, s_pkt)
			return
		end
		s_pkt.rank = equip.item.rank
		s_pkt.perfect_rewards = equip.item:get_intensify_perfect_attr()
		s_pkt.perfect = equip.item:get_perfect()
		--在强化+4,+7,+10,+12时回落则获得相应的礼包
		--if intensify_loader.Intensify_table[rank].reward_gift then
			--if pack_con:get_bag_free_slot_cnt() <= 0 then
				--NpcContainerMgr:SendError(conn.char_id, 43004)
				----如果背包已满则以邮件的方式发给玩家
				--local e_pkt = {}
				--e_pkt.char_lst = {}
				--e_pkt.char_lst[1] = {}
				--e_pkt.char_lst[1]["char_id"] = conn.char_id
				----e_pkt.char_lst[1]["email_id"] = 0
				--e_pkt.email_title = gbk_utf8("系统邮件")
				--e_pkt.email_content = gbk_utf8("您的背包已满，通过邮件给您发放强化奖励。")
				--local e_code, gift_item = Item_factory.create(tonumber(intensify_loader.Intensify_table[rank].reward_gift))
				--local item_list = {}
				--item_list["item_id"] = tonumber(intensify_loader.Intensify_table[rank].reward_gift)
				--item_list["item"] = gift_item
				--e_pkt.item = item_list
				--g_svsock_mgr:send_server_ex(WORLD_ID, 0, CMD_M2W_ADD_GOODS_ACK, e_pkt)
--
				--s_pkt.gift = {}
				--s_pkt.gift["gift_type"] = 1
				--s_pkt.gift["gift_id"] = tostring(intensify_loader.Intensify_table[rank].reward_gift)
				--s_pkt.gift["name"] = gift_item:get_name()
			--else
				--local e_code, gift_item = Item_factory.create(tonumber(intensify_loader.Intensify_table[rank].reward_gift))
				--pack_con:add_by_item(gift_item, {['type'] = ITEM_SOURCE.INTENSIFY})
--
				--s_pkt.gift = {}
				--s_pkt.gift["gift_type"] = 0
				--s_pkt.gift["gift_id"] = tostring(intensify_loader.Intensify_table[rank].reward_gift)
				--s_pkt.gift["name"] = gift_item:get_name()
			--end
		--end
	end

	--不管成功与失败都扣五彩神石
	local ret = {}
	for k, pro in pairs(pkt.add_per or {}) do
		--pack_con:del_item_by_bag_slot(pro.bag, pro.slot, 1, {['type']=ITEM_SOURCE.INTENSIFY})
		ret[k] = {}
		ret[k][1] = pro.bag
		ret[k][2] = pro.slot
		ret[k][3] = 1
	end
	pack_con:del_item_by_bags_slots(ret,{['type']=ITEM_SOURCE.INTENSIFY},1)
	--删除宝石和金钱
	pack_con:del_item_by_bag_slot(pkt.stone.bag, pkt.stone.slot, 1, {['type']=ITEM_SOURCE.INTENSIFY})
	if need_money < money.gift_gold then
		pack_con:dec_money(MoneyType.GIFT_GOLD, need_money, {['type']=MONEY_SOURCE.FACTION_INTENSIFY})
	else
		local left_money = need_money - money.gift_gold
		pack_con:dec_money(MoneyType.GIFT_GOLD, money.gift_gold, {['type']=MONEY_SOURCE.FACTION_INTENSIFY})
		pack_con:dec_money(MoneyType.GOLD, left_money, {['type']=MONEY_SOURCE.FACTION_INTENSIFY})
	end

	g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_INTENSIFY_EQUIP_S, s_pkt)

	--更新人物
	if pkt.bag == EQUIPMENT_BAG then
		player:on_update_attribute(2)
	end
end
--]]
--过滤职业
function f_get_other_occs(occ)
	local o_list = {}
	for i = 1, table.getn(occ_list) do
		if occ_list[i] ~= occ then
			table.insert(o_list, occ_list[i])
		end
	end

	return o_list
end

--装备转职预览
Clt_commands[1][CMD_REVIEW_EQUIP_CHANGE_OCC_B] =
function(conn, pkt)
	if not pkt or not pkt.slot or not pkt.bag then 
	    return
	end

	local s_pkt = {}
	local player = g_obj_mgr:get_obj(conn.char_id)
	local pack_con = player:get_pack_con()
	if pack_con == nil then 
	    return
	end

	--判断装备
	local slot = pack_con:get_item_by_bag_slot(pkt.bag, pkt.slot)
	local item = slot and slot.item
	if not item then
		s_pkt.result = 43001
		g_cltsock_mgr:send_client(conn.char_id, CMD_BENEDICTION_PREVIEW_S ,s_pkt)
		return
	end
	if item:get_m_class()~=ItemClass.ITEM_CLASS_EQUIP then
		s_pkt.result = 43064
		g_cltsock_mgr:send_client(conn.char_id, CMD_BENEDICTION_PREVIEW_S ,s_pkt)
		return
	end

	--预览组包
	local occ = item:get_req_class()
	local occ_chg = f_get_other_occs(occ)

	s_pkt.list = {}
	s_pkt.uuid = slot.uuid

	local item_id = item:get_item_id()
	

	for k, v in pairs(occ_chg) do
		local t_id	= item_id - occ * 1000000000 + v * 1000000000
	
		local item_obj = item:spec_serialize_to_db()
		local tmp_t = {}
		tmp_t.occ = v
		local e_code ,tmp_item = Item_factory.clone(t_id, item_obj)
		s_pkt.result = e_code
		if e_code ~= 0 then
			g_cltsock_mgr:send_client(conn.char_id, CMD_REVIEW_EQUIP_CHANGE_OCC_S ,s_pkt)
			return
		else
			tmp_t.item = tmp_item:spec_serialize_to_net()
			table.insert(s_pkt.list, tmp_t)
		end

	end
	s_pkt.result = 0

	g_cltsock_mgr:send_client(conn.char_id, CMD_REVIEW_EQUIP_CHANGE_OCC_S ,s_pkt)
end

--装备转职
Clt_commands[1][CMD_TERRITORY_EQUIP_CHANGE_OCC_B] =
function(conn, pkt)
	if not pkt or not pkt.slot or not pkt.bag or not pkt.occ
		or not pkt.money_type or (pkt.money_type ~= 1 and pkt.money_type ~= 2) then 
	    return
	end

	local s_pkt = {}
	local player = g_obj_mgr:get_obj(conn.char_id)
	local pack_con = player:get_pack_con()
	if pack_con == nil then 
	    return
	end
	--保护锁
	if pack_con:check_item_lock_by_bag_slot(pkt.bag, pkt.slot) then return end --上锁

	--判断装备
	local slot = pack_con:get_item_by_bag_slot(pkt.bag, pkt.slot)
	local item = slot and slot.item
	if not item then
		s_pkt.result = 43001
		g_cltsock_mgr:send_client(conn.char_id, CMD_TERRITORY_EQUIP_CHANGE_OCC_S ,s_pkt)
		return
	end
	if item:get_m_class()~=ItemClass.ITEM_CLASS_EQUIP then
		s_pkt.result = 43064
		g_cltsock_mgr:send_client(conn.char_id, CMD_TERRITORY_EQUIP_CHANGE_OCC_S ,s_pkt)
		return
	end

	--
	local occ = item:get_req_class()
	if occ == pkt.occ then
		s_pkt.result = 43078
		g_cltsock_mgr:send_client(conn.char_id, CMD_TERRITORY_EQUIP_CHANGE_OCC_S ,s_pkt)
		return
	end

	local item_id = item:get_item_id()

	local t_id	= item_id - occ * 1000000000 + pkt.occ * 1000000000

	local item_obj = item:spec_serialize_to_db()
	local tmp_t = {}
	tmp_t.occ = v
	local e_code ,tmp_item = Item_factory.clone(t_id, item_obj)
	s_pkt.result = e_code
	if e_code ~= 0 then
		g_cltsock_mgr:send_client(conn.char_id, CMD_TERRITORY_EQUIP_CHANGE_OCC_S ,s_pkt)
		return
	else
		local cost = math.floor( 1000 * item:get_req_lvl() * ( 2^item:get_color() )/ 30 )
		if not g_faction_territory:is_owner_territory(conn.char_id) then	-- 非帮派所属
			cost = math.floor(cost * 1.5)
		end
		
		local money_list = {}
		money_list[pkt.money_type] = cost
		s_pkt.result = pack_con:dec_money_l_inter_face(money_list, {['type']=MONEY_SOURCE.EQUIP_CHANGE_OCC})
		if s_pkt.result ~= 0 then
			g_cltsock_mgr:send_client(conn.char_id, CMD_TERRITORY_EQUIP_CHANGE_OCC_S ,s_pkt)
			return
		end

		pack_con:del_item_by_bag_slot(pkt.bag, pkt.slot, 1, {['type']=ITEM_SOURCE.EQUIP_CHANGE_OCC})

		if pkt.money_type == 2 then
			tmp_item:set_bind(0)
		end
		local item_list = {}
		item_list[1] = {}
		item_list[1].type = 2
		item_list[1].item = tmp_item
		item_list[1].number = 1
		pack_con:add_item_l(item_list, {['type']=ITEM_SOURCE.EQUIP_CHANGE_OCC}) 

		s_pkt.result = 0
		g_cltsock_mgr:send_client(conn.char_id, CMD_TERRITORY_EQUIP_CHANGE_OCC_S ,s_pkt)
	end
	
end

-- cailizhong添加-------
-- 装备认主
Clt_commands[1][CMD_EQUIPMENT_ACK_OWNER_C] =
function (conn, pkt)
	 -- 检查参数
	if not pkt.bag or not pkt.slot or not pkt.stone or not pkt.stone.bag or not pkt.stone.slot then
		return g_cltsock_mgr:send_client(conn.char_id, CMD_EQUIPMENT_ACK_OWNER_S, {["result"] = 31250})
	end
	local player = g_obj_mgr:get_obj(conn.char_id) -- 获取玩家对象
	if not player then return end
	local pack_con = player:get_pack_con() -- 获取人物背包
	if not pack_con then return end

	--测试用--------------------
	--pkt.stone.bag = SYSTEM_BAG
	--pkt.stone.slot = pack_con:get_slot_by_item_id(601430000041)
	--if pkt.stone.slot == nil then print("nil stone") end
	--print("-----------")
	--------------------------------

	if pack_con:check_money_lock(MoneyType.GOLD) or pack_con:check_money_lock(MoneyType.GIFT_GOLD) then return end --上锁
	if pack_con:check_item_lock_by_bag_slot(pkt.stone.bag, pkt.stone.slot) then return end --上锁
	 -- 获取装备
	local equip = pack_con:get_item_by_bag_slot(pkt.bag, pkt.slot)
	if not equip then
		return g_cltsock_mgr:send_client(conn.char_id, CMD_EQUIPMENT_ACK_OWNER_S, {["result"] = 43001})
	end
	-- 判断是否是装备类
	if not equip.item.is_equipment then
		return g_cltsock_mgr:send_client(conn.char_id, CMD_EQUIPMENT_ACK_OWNER_S, {["result"] = 43015})
	end
	-- 判断装备强化等级
	if equip.item.rank < 7 then
		return g_cltsock_mgr:send_client(conn.char_id, CMD_EQUIPMENT_ACK_OWNER_S, {["result"] = 31251})
	end
	 -- 获取认主所需石头
	local slot = pack_con:get_item_by_bag_slot(pkt.stone.bag, pkt.stone.slot)
	local stone_item = slot and slot.item
	if not stone_item then -- 找不到物品
		return g_cltsock_mgr:send_client(conn.char_id, CMD_EQUIPMENT_ACK_OWNER_S, {["result"] = 43001})
	end
	-- 检查物品使用等级
	local req_lvl = stone_item:get_req_lvl()
	if player:get_level() < req_lvl then
		return g_cltsock_mgr:send_client(conn.char_id, CMD_EQUIPMENT_ACK_OWNER_S, {["result"] = 43021})
	end
	-- 要使用的装备认主道具低于当前水平，不能认主
	--local ack_owner_flag = stone_item:get_item_lvl()
	local ack_owner_flag = tonumber(stone_item.proto.value.ack_lvl)
	if equip.item:get_ack_owner_flag() > ack_owner_flag then
		return g_cltsock_mgr:send_client(conn.char_id, CMD_EQUIPMENT_ACK_OWNER_S, {["result"] = 31252})
	end
	-- 检查物品是否是灵石
	if stone_item:get_m_class()~=6 or stone_item:get_s_class()~=18 or stone_item:get_t_class()~=43 then
		return g_cltsock_mgr:send_client(conn.char_id, CMD_EQUIPMENT_ACK_OWNER_S, {["result"] = 31253})
	end
	-- 获取认主名称
	local owner_name = stone_item.proto.value.owner_name
	if not owner_name then
		owner_name = player:get_name()
	end
	-- 装备名字检查
	local e_code = equip.item:check_name()
	if e_code ~= 0 then
		local ret = {}
		ret.result = e_code
		return g_cltsock_mgr:send_client(conn.char_id, CMD_EQUIPMENT_ACK_OWNER_S, ret)
	end
	-- 扣钱，扣道具
	local need_money = tonumber(stone_item.proto.value.money)
	if need_money==nil or need_money<=0 then
		return g_cltsock_mgr:send_client(conn.char_id, CMD_EQUIPMENT_ACK_OWNER_S, {["result"] = 31254})
	end
	local ret = {}
	ret.result = pack_con:dec_gold_gift_and_gold(need_money, {['type']=MONEY_SOURCE.EQUIMENT_ACK_OWNER}) -- 扣钱
	if ret.result ~= 0 then
		return g_cltsock_mgr:send_client(conn.char_id, CMD_EQUIPMENT_ACK_OWNER_S, ret)
	end
	ret.result = pack_con:del_item_by_bag_slot(pkt.stone.bag, pkt.stone.slot, 1, {['type']=ITEM_SOURCE.EQUIMENT_ACK_OWNER}) -- 扣物品
	if ret.result ~= 0 then
		return g_cltsock_mgr:send_client(conn.char_id, CMD_EQUIPMENT_ACK_OWNER_S, ret)
	end
	-- 装备设置为绑定
	equip.item:set_bind()
	-- 装备认主实际操作
	equip.item:set_ack_owner_flag(ack_owner_flag, owner_name)
	local e_code, ctn = pack_con:get_bag(pkt.bag)
	local log_list = {}
	log_list[1] = ctn:get_update_log(ItemSyncFlag.ITEM_SYNC_UPDATE, pkt.slot)
	-- 通知客户端更新单件装备信息
	pack_con:update_client(e_code, log_list, {['type']=ITEM_SOURCE.EQUIMENT_ACK_OWNER})
	g_cltsock_mgr:send_client(conn.char_id, CMD_EQUIPMENT_ACK_OWNER_S, ret)
end
--装备分解
Clt_commands[1][CMD_NPC_RESOLVE_EQUIP_C] = 
function(conn, pkt)
	if not pkt then return end 
	for i,v in pairs(pkt) do
		local player = g_obj_mgr:get_obj(conn.char_id)
		local pack_con = player:get_pack_con()
		--if pack_con:check_money_lock(MoneyType.GOLD) or pack_con:check_money_lock(MoneyType.GIFT_GOLD) then return end --上锁
		if pack_con:check_item_lock_by_bag_slot(SYSTEM_BAG, v) then return end --上锁
		local equip = pack_con:get_item_by_bag_slot(SYSTEM_BAG, v)
		if not equip then
			NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_NOT_FIND_ITEM)
			return
		end
		--判断可不可以分解
		if not equip.item.is_resolve then
			NpcContainerMgr:SendError(conn.char_id, 200047)
			return
		end
		local resolve_reward = {}  --分解奖励
		local s_pkt = {}
		s_pkt.result = equip.item:is_resolve()
		if s_pkt.result ~= 0 then
			g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_RESOLVE_EQUIP_S, s_pkt)
			return 
		end
		local e_code, ret = equip.item:resolve(pack_con)
		s_pkt.result = ret
		if e_code ~= 0 then
			g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_RESOLVE_EQUIP_S, s_pkt)
			return 
		end
		pack_con:del_item_by_bag_slot(SYSTEM_BAG, v, 1, {['type']=ITEM_SOURCE.EQUIP_RESOLVE}) -- 扣物品
		g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_RESOLVE_EQUIP_S, s_pkt)
	end
end
