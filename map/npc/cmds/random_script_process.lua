


local script_load = require("npc.config.random_script_loader")
local integral_func = require("mall.integral_func")

--物品的货币种类: 1铜币 2元宝 3礼券 4铜券 5元宝+礼券
local is_money_enough = function(char_id, money)
	local player = g_obj_mgr:get_obj(char_id)
	local pack_con = player:get_pack_con()							--玩家背包中的金钱
	local pack_money = pack_con:get_money()	
	if money.type == 1 then											--1铜币
		if pack_money.gold < money.price then
			return 43340
		end	
	elseif money.type == 2 then										--2元宝
		if pack_money.jade < money.price then
			return 43340
		end
	elseif money.type == 3 then										--3礼券
		if pack_money.gift_jade < money.price then
			return 43340
		end
	elseif money.type == 4 then										--4铜卷
		if pack_money.gift_gold < money.price then
			return 43340
		end
	elseif money.type == 5 then										--5元宝+礼券,优先扣除礼券
		if pack_money.gift_jade < money.price then
			if pack_money.jade < money.price then
				return 43340
			end
		end
	end 

	return 0
end

local pack_dec_money = function(char_id, money, action_id, item_id, number)
	local player = g_obj_mgr:get_obj(char_id)
	local pack_con = player:get_pack_con()							--玩家背包中的金钱
	local pack_money = pack_con:get_money()	
	local flag = false

	if money.type == 1 then
		pack_con:dec_money(MoneyType.GOLD, money.price, {['type']=MONEY_SOURCE.NPC_BUY})	
	elseif money.type == 2 then										--元宝消费 添加商城积分记录
		pack_con:dec_money(MoneyType.JADE, money.price, {['type']=MONEY_SOURCE.NPC_BUY})	
		integral_func.add_bonus(char_id, money.price,{['type']=MONEY_SOURCE.NPC_BUY})
		flag = true
	elseif money.type == 3 then
		pack_con:dec_money(MoneyType.GIFT_JADE, money.price, {['type']=MONEY_SOURCE.NPC_BUY})	
	elseif money.type == 4 then
		pack_con:dec_money(MoneyType.GIFT_GOLD, money.price, {['type']=MONEY_SOURCE.NPC_BUY})	
	elseif money.type == 5 then
		if pack_money.gift_jade < money.price then
			pack_con:dec_money(MoneyType.GIFT_GOLD, money.price, {['type']=MONEY_SOURCE.NPC_BUY})
		else													    --元宝消费 添加商城积分记录
			pack_con:dec_money(MoneyType.GIFT_JADE, money.price, {['type']=MONEY_SOURCE.NPC_BUY})	
			integral_func.add_bonus(char_id, money.price,{['type']=MONEY_SOURCE.NPC_BUY})
			flag = true
		end
	end
end

--打开神秘商人信息面板
Clt_commands[1][CMD_B2M_NPC_TRANSCRIPT_FIRST_C] =
	function(conn, pkt)
		--print("CMD_B2M_NPC_TRANSCRIPT_FIRST_C:",j_e(pkt))
		if not pkt or not pkt.action_id then return end

		local s_pkt = {}
		s_pkt.result = 0
		s_pkt.action_id = pkt.action_id

		local script_obj = g_random_script:get_random_script(conn.char_id)
		local money = script_obj:get_cost_refresh_item_list(pkt.action_id)		--刷新需要的money与货币类型
		s_pkt.list = script_obj:refresh_item_list(pkt.action_id, nil)			--获取刷新列表
		s_pkt.type = money.type
		s_pkt.price = money.price

		g_cltsock_mgr:send_client(conn.char_id, CMD_B2M_NPC_TRANSCRIPT_FIRST_S, s_pkt)
	end


--刷新神秘商人信息面板 
Clt_commands[1][CMD_B2M_NPC_TRANSCRIPT_REFRESH_C] = 
	function(conn, pkt)
		--print("CMD_B2M_NPC_TRANSCRIPT_REFRESH_C:",j_e(pkt))
		if not pkt or not pkt.action_id then return end
		local player = g_obj_mgr:get_obj(char_id)
		local pack_con = player:get_pack_con()							--玩家背包中的金钱
		local pack_money = pack_con:get_money()	
		
		local spkt = {}
		spkt.result = 0
		spkt.action_id = pkt.action_id

		local script_obj = g_random_script:get_random_script(conn.char_id)
		--check玩家的钱是否足够
		local money = script_obj:get_cost_refresh_item_list(pkt.action_id)	--刷新需要的money与货币类型
		if pack_con:check_money_lock(money.type) then return end --上锁

		spkt.result = is_money_enough(conn.char_id, money)
		
		if spkt.result == 0 then
			--刷新物品列表
			spkt.list = script_obj:refresh_item_list(pkt.action_id, 1)	
			--扣钱
			pack_dec_money(conn.char_id, money, pkt.action_id)
		end
		g_cltsock_mgr:send_client(conn.char_id, CMD_B2M_NPC_TRANSCRIPT_REFRESH_S, spkt)
	end

--神秘商人的购买
Clt_commands[1][CMD_B2M_NPC_TRANSCRIPT_BUY_C] = 
	function(conn, pkt)
		--print("CMD_B2M_NPC_TRANSCRIPT_BUY_C:",j_e(pkt))
		if pkt == nil or pkt.action_id == nil or pkt.item_id == nil or pkt.number == nil then return end
		
		local s_pkt = {}
		s_pkt.result = 0

		local num = tonumber(pkt.number) or 1
		local item_id = tonumber(pkt.item_id)

		local script_obj = g_random_script:get_random_script(conn.char_id)

		--所选择数量超过存量
		s_pkt.result = script_obj:is_item_number(pkt.action_id, item_id, num)  
		if s_pkt.result ~= 0 then															
			g_cltsock_mgr:send_client(conn.char_id, CMD_B2M_NPC_TRANSCRIPT_BUY_S, s_pkt)
			return 
		end

		--check玩家的钱包是否足够
		local money = script_obj:get_cost_one_item(pkt.action_id, item_id)
		money.price = money.price * num
		s_pkt.result = is_money_enough(conn.char_id, money)
		if s_pkt.result ~= 0 then
			g_cltsock_mgr:send_client(conn.char_id, CMD_B2M_NPC_TRANSCRIPT_BUY_S, s_pkt)
			return 
		end

		--将物品加入背包
		local player = g_obj_mgr:get_obj(conn.char_id)
		local pack_con = player:get_pack_con()	
		if pack_con:check_money_lock(money.type) then return end --上锁

		local item_list = {}
		item_list[1] = {}
		item_list[1].type = 1
		item_list[1].item_id = item_id
		item_list[1].number = num
		local err_code = pack_con:add_item_l(item_list, {['type']=ITEM_SOURCE.NPC_BUY})
		if err_code ~= 0 then
			NpcContainerMgr:SendError(conn.char_id, err_code)
			g_cltsock_mgr:send_client(conn.char_id, CMD_B2M_NPC_TRANSCRIPT_BUY_S, s_pkt)
			return
		end

		--减去物品列表响应的数量
		script_obj:dec_item_list(pkt.action_id, item_id, num)
		--扣钱操作
		pack_dec_money(conn.char_id, money, pkt.action_id, item_id, num)
		
		--刷新物品列表
		s_pkt.action_id = pkt.action_id
		local script_obj = g_random_script:get_random_script(conn.char_id)
		s_pkt.list = script_obj:refresh_item_list(pkt.action_id, nil)	
		g_cltsock_mgr:send_client(conn.char_id, CMD_B2M_NPC_TRANSCRIPT_FIRST_S, s_pkt)

	end
