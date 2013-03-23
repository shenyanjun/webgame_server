
--local debug_print = print
local debug_print = function() end
local stuff_f = require("obj.stuff_process")
local _scene = require("config.scene_config")
local faction_npc_loader = require("npc.config.faction_npc_loader")
local honor_loader = require("npc.config.honor_loader")
local _sk = require("skill.skill_process")

--local MAX_RECODE_PER_PAGE = 12

--获取NPC状态
Clt_commands[1][CMD_NPC_GET_NPC_QUEST_STATUS_C] =
	function(conn, pkt)
		debug_print("CMD_NPC_GET_NPC_QUEST_STATUS_C")
		NpcContainerMgr:GetMapNpcStatus(conn.char_id, g_mission_mgr:get_wait_accept_list(conn.char_id))
	end

--打开NPC面板
Clt_commands[1][CMD_NPC_HELLO_C] =
	function(conn, pkt)
		local player = g_obj_mgr:get_obj(conn.char_id)
		if pkt.npc_id == nil or player == nil then return end
		local npc = NpcContainerMgr:GetNpc(pkt.npc_id)
		if not npc then
			NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_NOT_FOUND)
			return
		end

		if not npc:CanContactWithPlayer(player) then
			NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_TOO_FAR)
			return
		end
		NpcContainerMgr:SetContactPlayer(conn.char_id, pkt.npc_id)

		local s_pkt = {}
		s_pkt[1] = pkt.npc_id
		s_pkt[2] = {} --action_list

		for k, v in pairs(npc:get_action_list() or {}) do --取得这个npc功能列表
			local action_obj = npc:GetActionById(v) --npc.action_list[v]
			local is_return = true
			-- 过滤领地战场action
			if action_obj.type == 43 and g_faction_territory:get_owner_id() ~= "" then is_return = false end
			if (action_obj.type == 44 or action_obj.type == 45) and g_faction_territory:get_owner_id() == "" then 
				is_return = false 
			end
			if action_obj and is_return then
				local a_pkt = {}
				a_pkt[1] = action_obj.id
				a_pkt[2] = action_obj.name
				a_pkt[3] = action_obj.type

				table.insert(s_pkt[2], a_pkt)
			end
		end

		local wait_accept_list = g_mission_mgr:get_wait_accept_list(conn.char_id)
		s_pkt[3] = {}
		for k, v in pairs(npc.start_quest_list) do
			local prototype = wait_accept_list[v.id]
			if wait_accept_list[v.id] then
				local item = {}
				item[1] = v.id
				item[2] = v.name
				item[3] = MISSION_STATUS_AVAILABLE
				item[4] = prototype:get_type()
				table.insert(s_pkt[3], item)
			end
		end

		local quest_mgr = player:get_quest_mgr()
		
		for k, v in pairs(npc.end_quest_list) do
			local quest = quest_mgr:get_accept_mission(v.id)
			if quest then
				local item = {}
				item[1] = quest:get_id()
				item[2] = v.name
				item[3] = quest:get_status()
				item[4] = quest:get_type()
				table.insert(s_pkt[3], item)
			end
		end

		g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_HELLO_S, s_pkt)
	end


--取NPC相应功能的详细信息
Clt_commands[1][CMD_NPC_GET_ACTION_DETAIL_C] =
	function(conn, pkt)
		local npc = NpcContainerMgr:GetContactNpcWithPlayer(conn.char_id)
		if not npc then
			NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_NOT_FOUND)
			return
		end

		local player = g_obj_mgr:get_obj(conn.char_id)
		local action = npc:GetActionById(pkt.action_id)
		if not action then
			NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_HAS_NOT_ACTION)
			return
		end

		local ret = {}
		local s_pkt = {}

		ret.action_id = pkt.action_id
		s_pkt[1] = pkt.action_id

		NpcContainerMgr:SetPlayerAction(conn.char_id, pkt.action_id)
		if action.type == ACTION_TYPE_TRADE_ITEM then
			local page = pkt.page or 1
			local pack_con = player:get_pack_con()
			ret.item_list = {}
			s_pkt[2] = 0 --total_page
			s_pkt[3] = 0 --page
			s_pkt[4] = {}
			s_pkt[5] = {}

			--卖买列表


			local ret = {}
			--ret[1] = pack_con.get_garbage_item_list and pack_con:get_garbage_item_list() or {}
			ret[1] = {}
			local item_list = pack_con:get_garbage_item_list() or {}
			for k,v in pairs(item_list) do
				ret[1][k] = v.item:serialize_to_net()
				ret[1][k].number = v.number
				ret[1][k].item_id = v.item:get_item_id()
				ret[1][k].slot = k
			end
			g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_ACTION_SELL_TMPLIST_S, ret)
		elseif action.type == ACTION_TYPE_LEARN_SKILL then
			ret.skill_list = {}
			s_pkt[2] = {}
			for _,lvl in pairs(action.skill_list) do
				local l = f_skill_get_study(player.id, lvl.id)
				if l then
					ret.skill_list[#ret.skill_list + 1] = {}
					ret.skill_list[#ret.skill_list].skill_id = l.skill_id
					ret.skill_list[#ret.skill_list].is_study = 0
					s_pkt[2][#ret.skill_list] = {}
					s_pkt[2][#ret.skill_list][1] = l.skill_id
					s_pkt[2][#ret.skill_list][2] = 0
					if l.is_study and l.level <= lvl.max_level and l.level >= lvl.min_level then
						ret.skill_list[#ret.skill_list].is_study = 1
						s_pkt[2][#ret.skill_list][2] = 1
					end
				end
			end
		elseif action.type == ACTION_TYPE_AUCTION then
			ret.auction_list = AuctionMgr:GetList()
		elseif action.type == ACTION_TYPE_GATHER then --组员集合
			local player = g_obj_mgr:get_obj(conn.char_id)
			local ret_code = f_team_gather(player, 1)
			NpcContainerMgr:SendError(conn.char_id, ret_code)
			return
		elseif action.type == ACTION_TYPE_PVP_LINE then --pvp专线
			local bpvp = f_is_pvp() or f_is_line_faction() or f_is_line_ww()
			if not bpvp then
				NpcContainerMgr:SendError(conn.char_id, 200084)
				return
			end
		elseif action.type == ACTION_FACTION_TERRITORY and g_faction_territory then --帮派领地
			s_pkt[2] = g_faction_territory:is_owner_territory(conn.char_id)
			s_pkt[3] = g_faction_territory:get_intensify_add_per()
			s_pkt[4] = g_faction_territory:get_intensify_money_per()
		elseif action.type == ACTION_TYPE_CHANGE_MAP_TOLL then --帮派领地温泉/练功房
			s_pkt[2] = {}
			local spa_list = g_scene_mgr_ex:get_type_list(MAP_TYPE_MANOR_SPA)
			if spa_list then
				local info = s_pkt[2]
				for _, scene in pairs(spa_list) do
					table.insert(info, scene:get_status_info())
				end
			end
		elseif action.type == ACTION_TYPE_STUDY_SKILL_NO_OCC and g_faction_territory then --帮派领地NPC学习技能
			s_pkt[2] = g_faction_territory:is_owner_territory(conn.char_id)
			s_pkt[3] = g_faction_territory:get_study_skill_money_per()
		end

		g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_GET_ACTION_DETAIL_S, s_pkt)
	end

--学习技能
Clt_commands[1][CMD_STUDY_SKILL_C] =
	function(conn, pkt)
		debug_print("CMD_STUDY_SKILL")
		if not pkt or not pkt.skill_id then return end

		--背包是否有该技能书
		local player = g_obj_mgr:get_obj(conn.char_id)
		if not player then return end
		local pack_con = player:get_pack_con()
		local book_item = pack_con:get_skill_book_item(tonumber(pkt.skill_id))
		if not book_item then
			NpcContainerMgr:SendError(conn.char_id, 43361)
			return
		end

		--调用使用技能书
		local ret_code = stuff_f.use_stuff(conn.char_id, book_item.bag, book_item.slot, conn.char_id)
	end

--技能升级
Clt_commands[1][CMD_NPC_ACTION_LEARN_SKILL_C] =
	function(conn, pkt)
		debug_print("CMD_NPC_ACTION_LEARN_SKILL_C")

		local ret = {}
		ret.result = f_skill_study_skill(conn.char_id, pkt.skill_id)
		if ret.result ~= -1 then
			ret.skill_id = pkt.skill_id
			g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_ACTION_LEARN_SKILL_S, ret)
		end
	end


--取得所有技能，不分职业
Clt_commands[1][CMD_NPC_GET_SKILL_NO_OCC_C] =
	function(conn, pkt)

	end

--可以跨职业学习技能
Clt_commands[1][CMD_NPC_STUDY_SKILL_NO_OCC_C] =
	function(conn, pkt)
		debug_print("CMD_NPC_STUDY_SKILL_NO_OCC_C")
		if not pkt or not pkt.skill_id then return end

		--背包是否有该技能书
		local player = g_obj_mgr:get_obj(conn.char_id)
		if not player then return end
		local pack_con = player:get_pack_con()
		local book_item = pack_con:get_skill_book_item(tonumber(pkt.skill_id))
		if not book_item then
			NpcContainerMgr:SendError(conn.char_id, 43361)
			return
		end

		local new_pkt = {}
		new_pkt.result = 0
		new_pkt.skill_id = pkt.skill_id
		--人物技能
		if not player:is_alive() then
			new_pkt.result = 43030
			g_cltsock_mgr:send_client(player:get_id(), CMD_NPC_ACTION_LEARN_SKILL_S, new_pkt)
			return 
		end
		--等级
		if player:get_level() < book_item.item:get_req_lvl() then
			new_pkt.result = 43021
			g_cltsock_mgr:send_client(player:get_id(), CMD_NPC_ACTION_LEARN_SKILL_S, new_pkt)
			return 
		end

		--是否可学
		local ret = f_skill_book_is_study(player, pkt.skill_id)

		if ret ~= 0 then
			new_pkt.result = ret
			g_cltsock_mgr:send_client(player:get_id(), CMD_NPC_ACTION_LEARN_SKILL_S, new_pkt)
			return 
		end

		local e_code = f_skill_book_study(player, pkt.skill_id)
		if e_code == 0 then
			pack_con:del_item_by_bag_slot(SYSTEM_BAG, book_item.slot, 1, STUDY_SKILL_NO_OCC)
		end
		new_pkt.result = e_code
		g_cltsock_mgr:send_client(player:get_id(), CMD_NPC_ACTION_LEARN_SKILL_S, new_pkt)
	end

--可以跨职业升级技能
Clt_commands[1][CMD_NPC_ACTION_LEARN_SKILL_NO_OCC_C] =
	function(conn, pkt)
		--debug_print("CMD_NPC_ACTION_LEARN_SKILL_NO_OCC_C")

		local ret = {}
		local money_per = (not g_faction_territory:is_owner_territory(conn.char_id)) and g_faction_territory:get_study_skill_money_per()
		ret.result = f_skill_study_skill(conn.char_id, pkt.skill_id, money_per)

		if ret.result ~= -1 then
			ret.skill_id = pkt.skill_id
			g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_ACTION_LEARN_SKILL_S, ret)
		end
	end

--转职技能同步
Clt_commands[1][CMD_NPC_UPGRADE_SKILL_BY_OCC_C] =
	function(conn, pkt)
		--print("CMD_NPC_UPGRADE_SKILL_BY_OCC_C")
		if not pkt or not pkt.occ then return end

		local ret = {}
		local obj = g_obj_mgr:get_obj(conn.char_id)
		local skill_con = obj:get_skill_con()
		if obj == nil or obj:get_level() < 40 then
			ret.result = 21057
		elseif not skill_con:is_had_full_combat_skill() then
			ret.result = 21058			
		else
			if skill_con:full_other_combat_skill(nil) then
				ret.result = 0
			else
				ret.result = 21059
			end				
		end
		g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_UPGRADE_SKILL_BY_OCC_S, ret)
		if ret.result == 0 then
			_sk.get_list(conn.char_id, conn.char_id)
		end
	end


--购买物品
Clt_commands[1][CMD_NPC_ACTION_BUY_ITEM_C] =
	function(conn, pkt)
		if not pkt.item_id then return end
		if pkt.number and pkt.number < 0 then return end

		local item_id = tonumber(pkt.item_id)
		local num = tonumber(pkt.number) or 1

		local player = g_obj_mgr:get_obj(conn.char_id)
		local action = NpcContainerMgr:GetPlayerAction(conn.char_id)
		if not action or action.type ~= ACTION_TYPE_TRADE_ITEM then
			NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_ACTION_NOT_RIGHT)
			return
		end

		local is_find = false
		local t_item = nil
		for _, v in pairs(action.item_list) do
			if item_id == v.id then
				is_find = true
				t_item = v
				break
			end
		end
		if not is_find then
			NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_NOT_SELL_THIS_ITEM)
			return
		end

		local pack_con = player:get_pack_con()
		
		local money = pack_con:get_money()
		local item_price = t_item.price * num

		--货币类型
		local currency
		if t_item.type == CURRENCY_GOLD then
			currency = MoneyType.GOLD
			if money.gold < item_price then
				NpcContainerMgr:SendError(conn.char_id, 200008, CMD_NPC_ACTION_BUY_ITEM_S)
				return
			end
		elseif t_item.type == CURRENCY_GIFT_GOLD then
			currency = MoneyType.GIFT_GOLD
			if money.gift_gold < item_price then
				NpcContainerMgr:SendError(conn.char_id, 200055, CMD_NPC_ACTION_BUY_ITEM_S)
				return
			end
		elseif t_item.type == CURRENCY_JADE then
			currency = MoneyType.JADE
			if money.jade < item_price then
				NpcContainerMgr:SendError(conn.char_id, 200052, CMD_NPC_ACTION_BUY_ITEM_S)
				return
			end
		elseif t_item.type == CURRENCY_GIFT_JADE then
			currency = MoneyType.GIFT_JADE
			if money.gift_jade < item_price then
				NpcContainerMgr:SendError(conn.char_id, 200056, CMD_NPC_ACTION_BUY_ITEM_S)
				return
			end
		else
			--print(gbk_utf8("NPC商品买卖不合法的货币类型"))
			NpcContainerMgr:SendError(conn.char_id, 10000, CMD_NPC_ACTION_BUY_ITEM_S)
			return
		end

		if pack_con:check_money_lock(currency) then return end --上锁

		local item_list = {}
		item_list[1] = {}
		item_list[1].type = 1
		item_list[1].item_id = tonumber(item_id)
		item_list[1].number = num
		local e_code = pack_con:check_add_item_l_inter_face(item_list)
		if e_code ~= 0 then 
			g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_ACTION_BUY_ITEM_S ,{['result'] = e_code})
			return 
		end

		pack_con:dec_money_l_inter_face({[currency] = item_price}, {['type']=MONEY_SOURCE.NPC_BUY}, nil, 1)

		local err_code = pack_con:add_item_l(item_list, {['type']=ITEM_SOURCE.NPC_BUY})
		if err_code ~= 0 then
			NpcContainerMgr:SendError(conn.char_id, err_code)
			return
		end

		--g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_ACTION_BUY_ITEM_S, ret)
	end

--购回卖出物品
Clt_commands[1][CMD_NPC_ACTION_BUY_BACK_C] =
	function(conn, pkt)
		local player = g_obj_mgr:get_obj(conn.char_id)

		--[[local npc = NpcContainerMgr:GetContactNpcWithPlayer(conn.char_id)
		if not npc then
			NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_NOT_FOUND)
			return
		end]]

		local action = NpcContainerMgr:GetPlayerAction(conn.char_id)
		if not action or action.type ~= ACTION_TYPE_TRADE_ITEM then
			NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_ACTION_NOT_RIGHT)
			return
		end

		local pack_con = player:get_pack_con()
		if pack_con:check_item_lock_by_bag_slot(GARBAGE_BAG,pkt.slot - 1) then return end --上锁
		if pack_con:check_money_lock(MoneyType.GOLD) then return end --上锁

		local money = pack_con:get_money()
		local item_list = pack_con:get_garbage_item_list()
		pkt.slot = pkt.slot - 1
		--number * sell_price * 2
		if not item_list[pkt.slot] then 
			local _ = g_debug_log and g_debug_log:write("Error:Clt_commands[1][CMD_NPC_ACTION_BUY_BACK_C] " .. tostring(pkt.slot))
			return 
		end

		local item_price = item_list[pkt.slot].item:get_sell_price() * item_list[pkt.slot].number * 2
		if money.gold < item_price then
			NpcContainerMgr:SendError(conn.char_id, 200008, CMD_NPC_ACTION_BUY_BACK_S)
			return
		end

		local grid = item_list[pkt.slot]
		local tmp_list = {}
		tmp_list[1] = {}
		tmp_list[1].type = 2
		--tmp_list[1].item_id = item.item_id
		tmp_list[1].number = grid.number
		tmp_list[1].item = grid.item
		local err_code = pack_con:add_item_l(tmp_list, {['type']=ITEM_SOURCE.NPC_BUY_BACK})
		if err_code ~= 0 then
			return err_code
		end

		pack_con:dec_money(MoneyType.GOLD, item_price, {['type']=MONEY_SOURCE.NPC_SALE_BUY})
		pack_con:del_item_by_bag_slot(GARBAGE_BAG, pkt.slot)

		local ret = {}
		ret[1] = {}
		local item_list = pack_con:get_garbage_item_list()
		for k,v in pairs(item_list) do
			ret[1][k] = v.item:serialize_to_net()
			ret[1][k].number = v.number
			ret[1][k].item_id = v.item:get_item_id()
			ret[1][k].slot = k
		end
		g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_ACTION_SELL_TMPLIST_S, ret)
	end

--出售物品
Clt_commands[1][CMD_NPC_ACTION_SELL_ITEM_C] =
	function(conn, pkt)
		debug_print("CMD_NPC_ACTION_SELL_ITEM_C")
		if not pkt.bag or not pkt.slot then return end

		local ret = { ["result"] = 0 }
		local player = g_obj_mgr:get_obj(conn.char_id)
		--local npc = NpcContainerMgr:GetContactNpcWithPlayer(conn.char_id)
		--if not npc:CanContactWithPlayer(player) then
			--NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_TOO_FAR)
			--return
		--end

		local action = NpcContainerMgr:GetPlayerAction(conn.char_id)
		if not action or action.type ~= ACTION_TYPE_TRADE_ITEM then
			NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_ACTION_NOT_RIGHT)
			return
		end
		local pack_con = player:get_pack_con()
		if pack_con:check_item_lock_by_bag_slot(pkt.bag,pkt.slot) then return end --上锁
		local grid = pack_con:get_item_by_bag_slot(pkt.bag, pkt.slot)
		if not grid then return end

		local bind_flag = grid.item:get_bind()

		if bind_flag == 0 then  --绑定，铜券
			pack_con:add_money(MoneyType.GIFT_GOLD, grid.item:get_sell_price() * grid.number, {['type']=MONEY_SOURCE.NPC_SELL})
		else
			pack_con:add_money(MoneyType.GOLD, grid.item:get_sell_price() * grid.number, {['type']=MONEY_SOURCE.NPC_SELL})
		end

		pack_con:del_item_by_bag_slot(pkt.bag, pkt.slot, nil, {['type']=ITEM_SOURCE.NPC_SELL})
		pack_con:add_garbage(grid)
		ret = {}
		ret[1] = {}
		local item_list = pack_con:get_garbage_item_list()
		for k,v in pairs(item_list) do
			ret[1][k] = v.item:serialize_to_net()
			ret[1][k].number = v.number
			ret[1][k].item_id = v.item:get_item_id()
			ret[1][k].slot = k
		end
		g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_ACTION_SELL_TMPLIST_S, ret)
		
	end

--传送
Clt_commands[1][CMD_NPC_ACTION_CHANGE_MAP_C]=
	function(conn, pkt)
		local player = g_obj_mgr:get_obj(conn.char_id)
		--[[local npc = NpcContainerMgr:GetContactNpcWithPlayer(conn.char_id)
		if not npc then
			NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_NOT_FOUND)
			return
		end
		local action = npc:GetActionById(pkt.action_id)]]

		local action = NpcContainerMgr:GetPlayerAction(conn.char_id)
		if not action or action.type ~= ACTION_TYPE_CHANGE_MAP then
			NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_ACTION_NOT_RIGHT)
			return
		end

		local dst_area = action.transfer_list[tonumber(pkt.id)]
		if not dst_area then
			NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_TRANSFER_ID_NOT_FOUND)
			return
		end
		local pack_con = player:get_pack_con()
		if pack_con:check_money_lock(MoneyType.GOLD) or pack_con:check_money_lock(MoneyType.GIFT_GOLD) then return end --上锁
		local money = pack_con:get_money()
		if money.gift_gold + money.gold < dst_area.taxi then
			NpcContainerMgr:SendError(conn.char_id, 200008, CMD_NPC_ACTION_CHANGE_MAP_S)
			return
		end
		
		if money.gift_gold < dst_area.taxi then
			local temp_gold = dst_area.taxi - money.gift_gold
			pack_con:dec_money(MoneyType.GIFT_GOLD, money.gift_gold, {['type']=MONEY_SOURCE.NPC_SCENE_CARRY})
			pack_con:dec_money(MoneyType.GOLD, temp_gold, {['type']=MONEY_SOURCE.NPC_SCENE_CARRY})
		else
			pack_con:dec_money(MoneyType.GIFT_GOLD, dst_area.taxi, {['type']=MONEY_SOURCE.NPC_SCENE_CARRY})
		end
		
		local pos = {}
		pos[1] = dst_area.pos_x
		pos[2] = dst_area.pos_y
		
		local error = f_scene_carry(conn.char_id, dst_area.map_id, pos)
		if 0 ~= error then
			NpcContainerMgr:SendError(conn.char_id, error)
		end
	end

--一键传送
Clt_commands[1][CMD_NPC_MAP_TRANSPORT_C] =
	function(conn, pkt)
		debug_print("CMD_NPC_MAP_TRANSPORT_C")
		if not pkt.type then return end		if f_is_pvp() or f_is_line_faction() or f_is_line_ww() then 			NpcContainerMgr:SendError(conn.char_id,21159,CMD_NPC_MAP_TRANSPORT_S)			return  		end		local type = tonumber(pkt.type)
		
		local player = g_obj_mgr:get_obj(conn.char_id)
		local pack_con = player and player:get_pack_con()
		if not pack_con then
		 	return
		end
		--押镖
		if player:get_escort_status() == 1 then
			NpcContainerMgr:SendError(conn.char_id, 21160)
			return
		end

		local ret = {}
		ret.result = 0
		--local vip_trans = g_vip_mgr:get_vip_attr(conn.char_id,VIPATTR.TRANSFER)
		local vip_trans, vip_type = g_vip_mgr:get_transfer_surplus(conn.char_id)
		local transporter
		if vip_trans <= 0 then
			transporter = pack_con:get_item_by_item_id(103030000120) or pack_con:get_item_by_item_id(103030000121)
			if not transporter then
				if vip_type > 0 then
					NpcContainerMgr:SendError(conn.char_id, 20401, CMD_NPC_MAP_TRANSPORT_S)
				else
					NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_NOT_ENOUGH_ITEM, CMD_NPC_MAP_TRANSPORT_S)
				end
				--g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_MAP_TRANSPORT_S, ret)
				return 
			end
		end

		local param_l = {}
		local pos = {}
		if type == MapCarryType.CARRY_NPC then --传送到NPC
			local npc = NpcContainerMgr:GetNpc(pkt.npc_id)
			if not npc then
				NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_NOT_FOUND, CMD_NPC_MAP_TRANSPORT_S)
				return
			end

			if f_scene_is_copy(pkt.map_id) then --副本不能用
				NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_TRANSPORT_FAIL, CMD_NPC_MAP_TRANSPORT_S)
				return
			end

			local t_pos = npc.scene[pkt.map_id]
			if not t_pos then
				NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_TRANSPORT_FAIL, CMD_NPC_MAP_TRANSPORT_S)
				return
			end

			param_l['map_id'] = pkt.map_id
			param_l['pos_x'] = t_pos.pos_list[1].pos_x
			param_l['pos_y'] = t_pos.pos_list[1].pos_y
			
		elseif type == MapCarryType.CARRY_POINT then --传送点传送
			param_l['map_id'] = pkt.map_id
			param_l['pos_x'] = pkt.pos_x
			param_l['pos_y'] = pkt.pos_y
		elseif type == MapCarryType.CARRY_STRIP then --传送带传送
			local carry_info = _scene._carry[pkt.carry_id]
			if not carry_info then
				NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_TRANSPORT_FAIL, CMD_NPC_MAP_TRANSPORT_S)
				return
			end

			local map_id
			if f_scene_is_copy(carry_info[4]) then --目标地图为副本不能用
				pos[1] = carry_info[2]
				pos[2] = carry_info[3]
				map_id = carry_info[1]
			else
				pos[1] = carry_info[5]
				pos[2] = carry_info[6]
				map_id = carry_info[4]
			end

			param_l['map_id'] = map_id
			param_l['pos_x'] = pos[1]
			param_l['pos_y'] = pos[2]
			
		else
			NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_TRANSPORT_FAIL, CMD_NPC_MAP_TRANSPORT_S)
			return
		end

		if vip_trans <= 0 then					--非vip使用物品
			--统一调用pack_con:use_item
			ret.result = pack_con:use_item(player, transporter, param_l)
			if ret.result ~= 0 and ret.result~= 43005 then
				NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_TRANSPORT_FAIL, CMD_NPC_MAP_TRANSPORT_S)
				return
			end
		else		--vip，不减物品
			ret.result = f_scene_carry(conn.char_id,param_l["map_id"],{param_l["pos_x"],param_l['pos_y']})
			g_vip_mgr:sub_transfer(conn.char_id, 1)
		end

		g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_MAP_TRANSPORT_S, ret)
	end

--获取快速修理装备需要金币
Clt_commands[1][CMD_NPC_FAST_REPAIR_COST_C] =
	function(conn, pkt)
		local s_pkt = {}
		s_pkt.result = 0

		local player = g_obj_mgr:get_obj(conn.char_id)
		local pack_con = player:get_pack_con()
		s_pkt.money = pack_con:get_fast_repair_cost()
		g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_FAST_REPAIR_COST_S, s_pkt)
	end

--快速修理装备
Clt_commands[1][CMD_NPC_FAST_REPAIR_EQUIP_C] =
	function(conn, pkt)
		local player = g_obj_mgr:get_obj(conn.char_id)
		local pack_con = player:get_pack_con()
		if pack_con:check_money_lock(MoneyType.GOLD) or pack_con:check_money_lock(MoneyType.GIFT_GOLD) then return end --上锁

		local money = pack_con:get_fast_repair_cost()
		local e_code = pack_con:dec_gold_gift_and_gold(money, {['type']=MONEY_SOURCE.FAST_REPAIR})
		if e_code ~=0 then
			g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_FAST_REPAIR_EQUIP_S, {['result']=e_code})
			return
		end

		local repair_list = {}
		local cnt = 0
		local equip_l = pack_con:get_equip()

		pack_con:repair_equip(equip_l)
		player:on_change_equip(1)
		g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_FAST_REPAIR_EQUIP_S, {['result']=0})
	end

--获取修理装备需要金币
Clt_commands[1][CMD_NPC_REPAIR_COST_ITEM_C] =
	function(conn, pkt)
		local s_pkt = {}
		s_pkt.result = 0

		local player = g_obj_mgr:get_obj(conn.char_id)
		local pack_con = player:get_pack_con()
		s_pkt.cost = pack_con:get_repair_cost(pkt.all)

		g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_REPAIR_COST_ITEM_S, s_pkt)
	end

--修理物品
Clt_commands[1][CMD_NPC_ACTION_REPAIR_ITEM_C] =
	function(conn, pkt)
		local ret = { ["result"] = 0 }
		local player = g_obj_mgr:get_obj(conn.char_id)
		--local npc = NpcContainerMgr:GetContactNpcWithPlayer(conn.char_id)

		local action = NpcContainerMgr:GetPlayerAction(conn.char_id)
		if not action or action.type ~= ACTION_TYPE_TRADE_ITEM then
			NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_ACTION_NOT_RIGHT)
			return
		end

		local pack_con = player:get_pack_con()
		if pack_con:check_money_lock(MoneyType.GOLD) or pack_con:check_money_lock(MoneyType.GIFT_GOLD) then return end --上锁
		local money = 0
		local repair_list = {}
		local cnt = 0
		if pkt and pkt.all == 1 then
			--全部修复
			local equip_l = pack_con:get_equip()
			if equip_l then
				for k,v in pairs(equip_l) do
					money = money + v.item:get_repair_cost()
					cnt = cnt + 1
					repair_list[cnt] = v
				end
			end
		elseif pkt.bag and pkt.slot then
			--修复一个装备
			local equip = pack_con:get_item_by_bag_slot(pkt.bag , pkt.slot)
			if not equip or not equip.item.is_equipment then
				return
			end 
			money = money + equip.item:get_repair_cost()
			cnt = cnt + 1
			repair_list[cnt] = equip
		end
		local e_code = pack_con:dec_gold_gift_and_gold(money, {['type']=MONEY_SOURCE.REPAIR})
		if e_code~=0 then
			return g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_ACTION_REPAIR_ITEM_S, {['result']=e_code})
		end
		pack_con:repair_equip(repair_list)
		g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_ACTION_REPAIR_ITEM_S, ret)
	end

--npc奖励
Clt_commands[1][CMD_B2M_NPC_REWARD_C] =
	function(conn, pkt)
		local ret = { ["result"] = 0 }
		local player = g_obj_mgr:get_obj(conn.char_id)
		local npc = NpcContainerMgr:GetContactNpcWithPlayer(conn.char_id)
		if not npc then
			NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_NOT_FOUND)
			return
		end
		local action = npc:GetActionById(pkt.action_id)   --直接取action
		
		--local action = NpcContainerMgr:GetPlayerAction(conn.char_id)
		if not action then
			NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_HAS_NOT_ACTION)
			return
		end

		if not action or action.type ~= ACTION_TYPE_REWARD then
			NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_ACTION_NOT_RIGHT)
			return
		end

		local action_id = action.id
		--是否可领取
		local result = g_daily_reward_mgr:can_be_fetch(conn.char_id,action_id)
		if result ~= 0 then 
			ret.result = result
			g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_NPC_REWARD_S, ret)
			return 
		end

		local item_list = action.item_list
		local random_count = action.random_count
		local item = {}
		for k,v in pairs(item_list or {})do
			item[k] = {}
			item[k][1] = v.id
			item[k][2] = v.number
		end

		if random_count > 0 then
			item = f_random_no_wave(item,random_count)
		end

		result = g_daily_reward_mgr:fetch_item(conn.char_id,action_id,item)

		ret.result = result
		g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_NPC_REWARD_S, ret)
	end

--帮派npc
Clt_commands[1][CMD_B2M_FACTION_BUY_ITEM_C] =
	function(conn, pkt)
		if pkt == nil then return end
		local player = g_obj_mgr:get_obj(conn.char_id)

		local pack_con = player:get_pack_con()
		local free_slot = pack_con:get_bag_free_slot_cnt()
		if free_slot <=0  then
			return g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_FACTION_BUY_ITEM_S, {["result"] = 43004})
		end
		
		local item_info = faction_npc_loader.faction_npc_list[pkt.item_id]
		local item_count = pkt.item_count
		if item_count < 0 then return end
		if item_info == nil then return end

		if pack_con:get_bag_free_slot_cnt() < 1 then
			return g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_FACTION_BUY_ITEM_S, {["result"] = 43004})
		end

		local result = g_faction_mgr:can_buy_item(conn.char_id, item_info,item_count)

		if result ~= 0 then return g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_FACTION_BUY_ITEM_S, {["result"] = result}) end
		
		local item_list = {}
		item_list[1] = {}
		item_list[1].type = 1
		item_list[1].item_id = tonumber(pkt.item_id)
		item_list[1].number = pkt.item_count

		local error_code = pack_con:add_item_l(item_list,{['type'] = ITEM_SOURCE.FACTION_NPC})
		if error_code == 0 then
			local contribution = item_info[2] * pkt.item_count
			local new_pkt = {}
			new_pkt.flag = 6
			new_pkt.param = -contribution
			g_faction_mgr:update_faction_level(conn.char_id,new_pkt)
			g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_FACTION_BUY_ITEM_S, {["result"] = 0})

			local str = ev.time .. " char_id:" ..conn.char_id .. " spend contribution to add item:" .. contribution
			g_faction_log:write(str)

			local str = string.format("insert log_faction_npc set faction_id ='%s',char_id = %d, item_id='%s', item_num=%d, contribution=%d,create_time=%d",
				g_faction_mgr:get_faction_by_cid(conn.char_id):get_faction_id(), conn.char_id,pkt.item_id,item_count, item_info[2] * item_count, ev.time)
			f_multi_web_sql(str)
		else
			g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_FACTION_BUY_ITEM_S, {["result"] = error_code})
		end
	end

--荣誉值购买装备
Clt_commands[1][CMD_B2M_HONOR_BUY_ITEM_C] =
	function(conn, pkt)
		if conn.char_id ==nil or pkt == nil then return end
		
		local player = g_obj_mgr:get_obj(conn.char_id)
		local pack_con = player:get_pack_con()
		if pack_con == nil then return end
		if pack_con:check_money_lock(MoneyType.HONOR) then return end --上锁
		local money = pack_con:get_money()
		local honor_value = money.honor

		local item_value = honor_loader.honor_list[pkt.item_id]
		if item_value == nil then return end
		local spend_honor = item_value * pkt.item_count
		if spend_honor < 0 then return end
		
		if honor_value < spend_honor then return end

		if pack_con:get_bag_free_slot_cnt() < 1 then
			return g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_HONOR_BUY_ITEM_S, {["result"] = 43004})
		end
		
		--cailizhong
		local e_code, item = Item_factory.create(tonumber(pkt.item_id))	
		if e_code ~= 0 then return e_code end
		local item_list = {}
		if item:is_fashion() then -- 是时装
			item_list[1] = {}
			item_list[1].type = 2
			item:set_last_time(7) -- 暂时写死7天
			item_list[1].item = item
			item_list[1].number = tonumber(pkt.item_count)
		else -- 不是时装
			item_list[1] = {}
			item_list[1].type = 1
			item_list[1].item_id = tonumber(pkt.item_id)
			item_list[1].number = pkt.item_count
		end
		local e_code = pack_con:check_add_item_l_inter_face(item_list) -- 检查能否添加物品
		if e_code ~= 0 then return 22500 end -- 背包满了

		pack_con:dec_money(MoneyType.HONOR,spend_honor,{['type'] = MONEY_SOURCE.HONOR}) -- 扣除荣誉值

		local error_code = pack_con:add_item_l(item_list,{['type'] = ITEM_SOURCE.HONOR})
		if error_code == 0 then
			g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_HONOR_BUY_ITEM_S, {["result"] = 0})
		else
			local str = ev.time .. " char_id:" ..conn.char_id .. " spend honor to add item:" .. spend_honor
			g_honor_log:write(str)
		end
		--cailizhong注释掉
		--[[
		local item_list = {}
		item_list[1] = {}
		item_list[1].type = 1
		item_list[1].item_id = tonumber(pkt.item_id)
		item_list[1].number = pkt.item_count
		

		local error_code = pack_con:add_item_l(item_list,{['type'] = ITEM_SOURCE.HONOR})
		if error_code == 0 then
			pack_con:dec_money(MoneyType.HONOR,spend_honor,{['type'] = MONEY_SOURCE.HONOR})
			g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_HONOR_BUY_ITEM_S, {["result"] = 0})
		else
			local str = ev.time .. " char_id:" ..conn.char_id .. " spend honor to add item:" .. spend_honor
			g_honor_log:write(str)
		end
		--]]
		-------------------------------
	end

--答题积分值购买装备
Clt_commands[1][CMD_B2M_GLORY_BUY_ITEM_C] =
	function(conn, pkt)
		if conn.char_id ==nil or pkt == nil then return end
		
		local player = g_obj_mgr:get_obj(conn.char_id)
		local pack_con = player:get_pack_con()
		if pack_con == nil then return end
		if pack_con:check_money_lock(MoneyType.GLORY) then return end --上锁
		local money = pack_con:get_money()
		local glory_value = money.glory

		local item_value = honor_loader.glory_list[pkt.item_id]
		if item_value == nil then return end
		local spend_glory = item_value * pkt.item_count
		if spend_glory < 0 then return end
		
		if glory_value < spend_glory then return end

		if pack_con:get_bag_free_slot_cnt() < 1 then
			return g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_HONOR_BUY_ITEM_S, {["result"] = 43004})
		end
		
		--cailizhong
		local e_code, item = Item_factory.create(tonumber(pkt.item_id))	
		if e_code ~= 0 then return e_code end
		local item_list = {}
		if item:is_fashion() then -- 是时装
			item_list[1] = {}
			item_list[1].type = 2
			item:set_last_time(7) -- 暂时写死7天
			item_list[1].item = item
			item_list[1].number = tonumber(pkt.item_count)
		else -- 不是时装
			item_list[1] = {}
			item_list[1].type = 1
			item_list[1].item_id = tonumber(pkt.item_id)
			item_list[1].number = pkt.item_count
		end
		local e_code = pack_con:check_add_item_l_inter_face(item_list) -- 检查能否添加物品
		if e_code ~= 0 then return 22500 end -- 背包满了

		pack_con:dec_money(MoneyType.GLORY,spend_glory,{['type'] = MONEY_SOURCE.GLORY}) -- 扣除荣誉值

		local error_code = pack_con:add_item_l(item_list,{['type'] = ITEM_SOURCE.GLORY})
		if error_code == 0 then
			g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_GLORY_BUY_ITEM_S, {["result"] = 0})
		else
			local str = ev.time .. " char_id:" ..conn.char_id .. " spend glory to add item:" .. spend_glory
			g_honor_log:write(str)
		end
	end

--同场景传送
Clt_commands[1][CMD_NPC_CHANGE_POS_C] =
	function(conn, pkt)
		debug_print("CMD_NPC_CHANGE_POS_C")
		
		--押镖
		if player:get_escort_status() == 1 then
			NpcContainerMgr:SendError(conn.char_id, 21160)
			return
		end

		local action = NpcContainerMgr:GetPlayerAction(conn.char_id)
		if not action or action.type ~= ACTION_TYPE_CHANGE_MAP then
			NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_ACTION_NOT_RIGHT)
			return
		end

		local dst_area = action.transfer_list[tonumber(pkt.id)]
		if not dst_area then
			NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_TRANSFER_ID_NOT_FOUND)
			return
		end
		local pack_con = player:get_pack_con()
		if pack_con:check_money_lock(MoneyType.GOLD) or pack_con:check_money_lock(MoneyType.GIFT_GOLD) then return end --上锁
		local money = pack_con:get_money()
		if money.gift_gold + money.gold < dst_area.taxi then
			NpcContainerMgr:SendError(conn.char_id, 200008, CMD_NPC_ACTION_CHANGE_MAP_S)
			return
		end
		
		if money.gift_gold < dst_area.taxi then
			local temp_gold = dst_area.taxi - money.gift_gold
			pack_con:dec_money(MoneyType.GIFT_GOLD, money.gift_gold, {['type']=MONEY_SOURCE.NPC_SCENE_CARRY})
			pack_con:dec_money(MoneyType.GOLD, temp_gold, {['type']=MONEY_SOURCE.NPC_SCENE_CARRY})
		else
			pack_con:dec_money(MoneyType.GIFT_GOLD, dst_area.taxi, {['type']=MONEY_SOURCE.NPC_SCENE_CARRY})
		end
		
		local pos = {}
		pos[1] = dst_area.pos_x
		pos[2] = dst_area.pos_y
		
		local error = f_scene_change_pos(conn.char_id, dst_area.map_id, pos) or 21207
		if 0 ~= error then
			NpcContainerMgr:SendError(conn.char_id, error)
		end
	end