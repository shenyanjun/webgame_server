
local debug_print = function() end
local stuff_f = require("obj.stuff_process")
local bags_expand = require("bags.expand_bag_loader")
local integral_func=require("mall.integral_func")
local treasure_config = require("config.loader.treasure_fragment_loader")

--根据type获取item_id
local flower_id = {
	120010000141,
	120020000141,
	120030000141,
}


local randompet_cost = {
						{},
						{},
						{8,110},
						{8,110}
					}
--玩家各种行为操作
local CUOBEI = 1   --搓背
local operate_l = {
[CUOBEI]={["item_id"]=130000003021},
}


Clt_commands[1][CMD_MAP_GET_MONEY_C] = 
	function(conn, pkt)
		local player = g_obj_mgr:get_obj(conn.char_id)
		if player then
			local bag_mgr = player:get_pack_con()
			bag_mgr:update_clt_money()
		end
	end


Clt_commands[1][CMD_MAP_GET_PACK_DETAIL_C] =
	function(conn, pkt)
		if not conn.char_id or not pkt then return end
		local player = g_obj_mgr:get_obj(conn.char_id)
		if player then
			if tonumber(pkt[1])==FACTION_BAG then -- req faction bag info
				g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id, CMD_M2C_BAG_REQ_M, pkt)
				return 
			end
			
			local bag_mgr = player:get_pack_con()
			local bag_id = tonumber(pkt[1])
			local bag,e_code
			e_code, bag = bag_mgr:get_bag(bag_id)
			if e_code ~= 0 then 
				return
			end
			local info = bag:get_bag_info()
			g_cltsock_mgr:send_client_ex(conn, CMD_MAP_GET_PACK_DETAIL_S, info)
			
			if not ddd then
			
				--bag_mgr:get_skill_book_item(4545)
				--bag_mgr:add_item_l({{['type']=1, ['number']=1, ['item_id']=104001120120}})
				--bag_mgr:add_item_l({{['type']=1, ['number']=1, ['item_id']=601010020121}})
				--bag_mgr:add_item_l({{['type']=1, ['number']=1, ['item_id']=104000100120}})
				--bag_mgr:add_item_l({{['type']=1, ['number']=1, ['item_id']=104000100120}})
				--bag_mgr:add_item_l({{['type']=1, ['number']=1, ['item_id']=104000100120}})
			end
		
			return 
		end
	end

Clt_commands[1][CMD_MAP_SWAP_ITEM_C] =
	function(conn, pkt)
		local player = g_obj_mgr:get_obj(conn.char_id)
		if player then
			local bag_mgr = player:get_pack_con()
			bag_mgr:swap(pkt.src_bag, pkt.src_slot, pkt.dst_bag, pkt.dst_slot)
		end
		
	end

	
Clt_commands[1][CMD_MAP_SPLIT_ITEM_C] =
	function(conn, pkt)

		local bag = tonumber(pkt.bag)
		local slot = tonumber(pkt.slot)
		local count = tonumber(pkt.count)

		local player = g_obj_mgr:get_obj(conn.char_id)
		if player then
			local bag_mgr = player:get_pack_con()
			bag_mgr:split_item(bag,slot,count)
		end
	end



Clt_commands[1][CMD_MAP_DESTROY_ITEM_C] =
	function(conn, pkt)
		local player = g_obj_mgr:get_obj(conn.char_id)
		if player then
			local info
			local bag_mgr = player:get_pack_con()
			local bag = tonumber(pkt[1])
			local slot = tonumber(pkt[2])
			local count = tonumber(pkt[3])
			if bag_mgr:check_item_lock_by_bag_slot(bag,slot) then
				return
			end
			bag_mgr:del_item_by_bag_slot(bag,slot,nil,{['type']=ITEM_SOURCE.DESTROY_BUTTON})
			return 
		end
	end



--开格价格
Clt_commands[1][CMD_MAP_BUY_BAG_SLOT_PRICE_C] = 
	function(conn, pkt)
		if not pkt or not pkt[1] then
			return
		end
		local bag_id = tonumber(pkt[1])
		local valid_bag = {
			[19] = true,
			[20] = true,
		}
		if not valid_bag[bag_id] then
			return
		end
		local player = g_obj_mgr:get_obj(conn.char_id)
		local bag_mgr = player:get_pack_con()
		local e_code ,bag = bag_mgr:get_bag(bag_id)
		if e_code~= 0 then
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_BUY_BAG_SLOT_S, {['result']=e_code})
		end
		local cur_size =  bag:get_size()
		if not bags_expand.Expand_bag_price_tbl[bag_id][cur_size] then
			return 
		end
		local ret = {}
		ret[1] = bag_id
		ret[2] = bags_expand.Expand_bag_price_tbl[bag_id][cur_size].amount
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_BUY_BAG_SLOT_PRICE_S, ret)
	end


--[[旧的开格
Clt_commands[1][CMD_MAP_BUY_BAG_SLOT_C] =
	function(conn, pkt)
		local player = g_obj_mgr:get_obj(conn.char_id)
		if player then
			local bag_id = tonumber(pkt[1])
			local bag_mgr = player:get_pack_con()
			local e_code, bag = bag_mgr:get_bag(bag_id)
			if e_code ~= 0 then
				return 
			end
			local cur_size = bag:get_size()
			local money_list = bag_mgr:get_money()
			if not bags_expand.Expand_bag_price_tbl[bag_id][cur_size] or not bags_expand.Expand_bag_price_tbl[bag_id][cur_size].amount then
				return
			end
			local total = math.ceil(bags_expand.Expand_bag_price_tbl[bag_id][cur_size].amount / 5)

			e_code = bag_mgr:del_item_by_item_id_inter_face(ITEM_CURRENCY.BAG_OPENSLOT, total,  {['type']=ITEM_SOURCE.EXPAND_BAG }, 1)	

			if e_code ~= 0 then
				return g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_BUY_BAG_SLOT_S, {result = e_code})
			end

			--添加福利
			local ret = {}
			ret.result = bag_mgr:expand_bag(bag_id)
			if ret.result == 0 then
				ret.bag_id = bag_id
				ret.size = bag:get_size()
			end
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_BUY_BAG_SLOT_S, ret)
		end
	end
]]

Clt_commands[1][CMD_MAP_BUY_BAG_SLOT_C] =
	function(conn, pkt)
		--print("CMD_MAP_BUY_BAG_SLOT_C", j_e(pkt))
		local player = g_obj_mgr:get_obj(conn.char_id)
		if player then
			local bag_id = pkt.bag
			local bag_mgr = player:get_pack_con()
			local e_code, bag = bag_mgr:get_bag(bag_id)
			if e_code ~= 0 then
				return 
			end
			local cur_size = bag:get_size()
			--local money_list = bag_mgr:get_money()
			local all_money = bags_expand.Expand_bag_price_tbl[bag_id][cur_size] and bags_expand.Expand_bag_price_tbl[bag_id][cur_size].amount
			
			if all_money and all_money > 0 then
				pkt.all_money = all_money
				g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id, CMD_M2C_QQ_BAG_SLOT_M, pkt)
			end
		end
	end

--元宝直接开格 
Sv_commands[0][CMD_M2C_QQ_BAG_SLOT_C]=
function(conn, char_id, pkt)
	--print("CMD_M2C_QQ_BAG_SLOT_C", j_e(pkt))
	if pkt.result and pkt.result ~= 0 then
		g_cltsock_mgr:send_client(char_id, CMD_MAP_BUY_BAG_SLOT_S, {result = pkt.result})
		return
	end

	local player = g_obj_mgr:get_obj(char_id)
	if player then
		local bag_id = pkt.bag
		local bag_mgr = player:get_pack_con()
		local e_code, bag = bag_mgr:get_bag(bag_id)
		if e_code ~= 0 then
			pkt.result = 1
			g_svsock_mgr:send_server_ex(COMMON_ID,char_id, CMD_M2C_QQ_BAG_SLOT_REQ, pkt)
			return 
		end
		local cur_size = bag:get_size()
		local all_money = bags_expand.Expand_bag_price_tbl[bag_id][cur_size] and bags_expand.Expand_bag_price_tbl[bag_id][cur_size].amount
		if all_money ~= pkt.all_money then
			print("error open bag slot", all_money, pkt.all_money)
			pkt.result = 2
			g_svsock_mgr:send_server_ex(COMMON_ID,char_id, CMD_M2C_QQ_BAG_SLOT_REQ, pkt)
			return
		end

		--添加福利
		local ret = {}
		ret.result = bag_mgr:expand_bag(bag_id)
		if ret.result == 0 then
			ret.bag_id = bag_id
			ret.size = bag:get_size()
		end
		g_cltsock_mgr:send_client(char_id, CMD_MAP_BUY_BAG_SLOT_S, ret)
		pkt.result = 0
		g_svsock_mgr:send_server_ex(COMMON_ID,char_id, CMD_M2C_QQ_BAG_SLOT_REQ, pkt)
	end
end

Clt_commands[1][CMD_MAP_AUTO_MANAGE_C] =
	function(conn, pkt)

		debug_print("CMD_MAP_AUTO_MANAGE_C")
		local player = g_obj_mgr:get_obj(conn.char_id)
		if not player then return end
		local pack_con = player:get_pack_con()
		if pack_con then
			pack_con:sort_item(tonumber(pkt[1]))
		end
	end

--使用无参数物品
Clt_commands[1][CMD_MAP_USE_ITEM_C] =
	function(conn, pkt)
		if pkt == nil or pkt.bag == nil or pkt.slot == nil or pkt.obj_id == nil then return end
		stuff_f.use_stuff(conn.char_id, pkt.bag, pkt.slot, pkt.obj_id)
	end

--使用有CD和参数的物品
Clt_commands[1][CMD_USE_CD_PARAM_ITEM_B] =
	function(conn, pkt)	
		if pkt == nil or pkt.bag == nil or pkt.slot == nil or pkt.obj_id == nil 
		or not pkt.type or not pkt.param_l then return end
		stuff_f.use_stuff_CD_PARAM(conn.char_id, pkt.bag, pkt.slot, pkt.obj_id, pkt.type, pkt.param_l)
	end

--银行存钱
Clt_commands[1][CMD_BANK_SAVE_MONEY_C] =
	function(conn, pkt)
		debug_print("CMD_BANK_SAVE_MONEY_C", pkt.gold)
		if not pkt.gold then return end
		if pkt.gold < 0 then return end

		local player = g_obj_mgr:get_obj(conn.char_id)
		local pack_con = player:get_pack_con()
		--是否够存
		local money = pack_con:get_money()
		if money.gold < pkt.gold then
			f_cmd_show(conn.char_id, 20312)
			return
		end
		pack_con:add_money(MoneyType.BANK_GOLD, tonumber(pkt.gold), {['type']=MONEY_SOURCE.DEPOSIT})
	end

--银行取钱
Clt_commands[1][CMD_BANK_GET_MONEY_C] =
	function(conn, pkt)
		debug_print("CMD_BANK_GET_MONEY_C", pkt.gold)
		if not pkt.gold then return end
		if pkt.gold < 0 then return end

		local player = g_obj_mgr:get_obj(conn.char_id)
		local pack_con = player:get_pack_con()
		--是否够取
		if pack_con:check_money_lock(MoneyType.BANK_GOLD) then
			return
		end
		local money = pack_con:get_money()
		if money.bank_gold < pkt.gold then
			f_cmd_show(conn.char_id, 20313)
			return
		end
		pack_con:dec_money(MoneyType.BANK_GOLD, tonumber(pkt.gold), {['type']=MONEY_SOURCE.WITHDRAW})
	end

--快速出售
Clt_commands[1][CMD_ITEM_FAST_SALE_C] =
	function(conn, pkt)
		--debug_print("CMD_ITEM_FAST_SALE_C", j_e(pkt))
		if not pkt then return end
	
		local player = g_obj_mgr:get_obj(conn.char_id)
		local pack_con = player:get_pack_con()

		local item = pack_con:get_item_by_item_id(110010000120)
		if not item then
			item = pack_con:get_item_by_item_id(110010000121)
		end
		if not item then
			return
		end

		local param_l = {['bag_slot_list'] = pkt}
		local ret_code = pack_con:use_item(player, item, param_l)

		local s_pkt = {}
		s_pkt.result = ret_code
		g_cltsock_mgr:send_client(conn.char_id, CMD_ITEM_FAST_SALE_S, s_pkt)
	end

--高级快速出售(高级熔炼炉)
Clt_commands[1][CMD_ITEM_FAST_SALE_SENIOR_C] =
	function(conn, pkt)
		--debug_print("CMD_ITEM_FAST_SALE_C", j_e(pkt))
		if not pkt then return end
	
		local player = g_obj_mgr:get_obj(conn.char_id)
		local pack_con = player:get_pack_con()

		local item = pack_con:get_item_by_item_id(122010000130)
		if not item then
			item = pack_con:get_item_by_item_id(122010000131)
		end
		if not item then
			return
		end

		local param_l = {['bag_slot_list'] = pkt}
		local ret_code = pack_con:use_item(player, item, param_l)

		if ret_code ~= 0 then
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_USE_ITEM_S, {["result"] = ret_code});
		end
	end

--紫装熔炼
Clt_commands[1][CMD_MAP_SMELT_EQUIP_B] =
	function(conn, pkt)
		--debug_print("CMD_ITEM_FAST_SALE_C", j_e(pkt))
		if not pkt then return end
		
		local s_pkt = {}
		local player = g_obj_mgr:get_obj(conn.char_id)
		local pack_con = player:get_pack_con()

		if pack_con:check_item_lock_by_bag_slot(SYSTEM_BAG, pkt.slot) then return end --上锁

		local grid = pack_con:get_item_by_bag_slot(SYSTEM_BAG, pkt.slot)
		if not grid or not grid.item then
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_SMELT_EQUIP_S, {["result"] = ERROR_NPC_NOT_FIND_ITEM})
			return
		end
		if grid.item:get_m_class() ~= 1 or grid.item:get_s_class() ~= 53 then
			s_pkt.result = 43064
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_SMELT_EQUIP_S, s_pkt)
			return
		end

		local param_l = {['slot_l'] = pkt.slot_l}
		local ret_code = pack_con:use_item(player, grid, param_l)

		if ret_code ~= 0 then
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_USE_ITEM_S, {["result"] = ret_code})
		end
	end

Clt_commands[1][CMD_ITEM_EQUIP_UP_DURABLE_C] =
	function(conn, pkt)
		if not pkt then
			return
		end
		local player = g_obj_mgr:get_obj(conn.char_id);
		local pack_con = player:get_pack_con();
		if pack_con then
			local item = pack_con:get_item_by_bag_slot(pkt.item_bag, pkt.item_slot);
			local target = pack_con:get_item_by_bag_slot(pkt.target_bag, pkt.target_slot);
			if target then
				local s_pkt = {};
				local param_l = {}
				param_l.target = target
				s_pkt.result = pack_con:use_item(player,  item , param_l)
				g_cltsock_mgr:send_client(conn.char_id, CMD_ITEM_EQUIP_UP_DURABLE_S, s_pkt);
				return 
			end
		end
	end


--挂机参数获得所需(复活灵,熔炼炉)数量
local T_HOOK_ITEM = {105000000121, 110010000121}

Clt_commands[1][CMD_HOOK_GET_ITEM_COUNT_C] =
	function(conn, pkt)
		local player = g_obj_mgr:get_obj(conn.char_id);
		local pack_con = player:get_pack_con();

		local s_pkt = {}
		s_pkt.result = 0
		s_pkt.item_count = {}

		for k, v in pairs(T_HOOK_ITEM) do
			local cur_count = pack_con:get_all_item_count(v)
			s_pkt.item_count[k] = cur_count
		end

		g_cltsock_mgr:send_client(conn.char_id, CMD_HOOK_GET_ITEM_COUNT_S, s_pkt)
	end

--挂机自动补充HP/MP
Clt_commands[1][CMD_HOOK_AUTO_USE_ITEM_C] =
	function(conn, pkt)

		local player = g_obj_mgr:get_obj(conn.char_id);
		if not player or not pkt.target or not pkt.item_id then return end

		local pack_con = player:get_pack_con();

		local s_pkt = {}
		s_pkt.result = 0
		s_pkt.item_id = tonumber(pkt.item_id)

		--使用物品
		local item = pack_con:get_item_by_item_id(s_pkt.item_id)
		if not item then --没有该物品
			s_pkt.result = 43001
			s_pkt.cur_count = 0
			g_cltsock_mgr:send_client(conn.char_id, CMD_HOOK_AUTO_USE_ITEM_S, s_pkt)
			return
		end

		--使用物品
		stuff_f.use_stuff(conn.char_id, item.bag, item.slot, pkt.target)

		s_pkt.cur_count = pack_con:get_item_count(s_pkt.item_id)
		g_cltsock_mgr:send_client(conn.char_id, CMD_HOOK_AUTO_USE_ITEM_S, s_pkt)
	end



--+1强化卡   (bag,slot)
Clt_commands[1][CMD_INTENSIFY_EQUIP_C] =
	function(conn, pkt)
		if not pkt then
			return
		end

		local player = g_obj_mgr:get_obj(conn.char_id)
		local pack_con = player:get_pack_con()
		local item = pack_con:get_item_by_bag_slot(pkt.bag, pkt.slot)
		local target = pack_con:get_item_by_bag_slot(pkt.target_bag, pkt.target_slot)
		local param_l = {}
		param_l['equip']=target


		local item_id
		--区别外网和内部
		if tonumber(item.item.proto.value.item_lvl) == 1 then
			item_id = 121010000141
		elseif tonumber(item.item.proto.value.item_lvl) == 2 then
			item_id = 121010000241
		end

		local bind_id = tonumber(string.sub(item_id,0,-2) .. '0')
		local player = g_obj_mgr:get_obj(conn.char_id);
		local pack_con = player:get_pack_con();
		local item = pack_con:get_item_by_item_id(bind_id)
		if not item then
			item = pack_con:get_item_by_item_id(item_id)
		end
		--没有道具
		if not item then
			return 200009 --返回没有道具的错误码
		end 

		--使用物品
		local  param_l = {}
		param_l.target = target
		local ret_code = pack_con:use_item(player, item, param_l)

		local s_pkt = {}
		s_pkt.result = ret_code
		g_cltsock_mgr:send_client(conn.char_id, CMD_INTENSIFY_EQUIP_S, s_pkt)
	end


--送花
Clt_commands[1][CMD_SEND_FLOWER_C] =
	function(conn, pkt)
		--参数不合法
		if not pkt or not pkt.slot or not pkt.char_id  then
			return 
		end

		local player = g_obj_mgr:get_obj(conn.char_id)
		local pack_con = player:get_pack_con()

		--是不是有道具，判断是否相符
		local slot = pack_con:get_item_by_bag_slot(SYSTEM_BAG , pkt.slot)
		local item = slot and slot.item
		if not item then
			s_pkt.result = 43001
			g_cltsock_mgr:send_client(conn.char_id, CMD_SEND_FLOWER_S ,s_pkt)
			return
		end
		if item:get_m_class() ~= 1 or item:get_s_class() ~= 20 then
			s_pkt.result = 43064
			g_cltsock_mgr:send_client(conn.char_id, CMD_SEND_FLOWER_S ,s_pkt)
			return
		end

		--没有道具
		local ret_code = 43064
		local s_pkt = {};
		--使用物品
		if item then
			local receiver = g_obj_mgr:get_obj(pkt.char_id)
			
			if receiver then		--同线直接送
				pkt.name = player:get_name()
				ret_code= pack_con:use_item(player, slot, pkt)

			else--不同线转发送
				local t_pkt = {}
				t_pkt.sender	= conn.char_id
				t_pkt.sender_n	= player:get_name()
				t_pkt.receiver	= pkt.char_id
				
				t_pkt.text		= pkt.text
				t_pkt.effect	= item.proto.value.effect
				t_pkt.item_id	= item:get_item_id()
				t_pkt.slot 		= pkt.slot
				--print("505 =", j_e(t_pkt))
				g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id, CMD_FLOWER_CHECK_ON_LINE_M, t_pkt)
				return
			end
		end

		
		s_pkt.result = ret_code;
		g_cltsock_mgr:send_client(conn.char_id, CMD_SEND_FLOWER_S, s_pkt)
	end

--收到鲜花数量
Clt_commands[1][CMD_MAP_GET_FLOWERS_INFO_B] =
	function(conn, pkt)
		local player = g_obj_mgr:get_obj(conn.char_id)
		if not player then return end
		
		local s_pkt = {}
		s_pkt.result = 0
		s_pkt.flowers = player:get_receive_flowers_cnt()

		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_GET_FLOWERS_INFO_S, s_pkt)
	end

--玩家操作
Clt_commands[1][CMD_MAP_PLAYER_OPERATE_C] =
function(conn, pkt)
	--参数不合法
	if not pkt or not pkt.type then
		return 
	end

	if pkt.type == CUOBEI then    --搓背
		local player = g_obj_mgr:get_obj(conn.char_id)
		local target = g_obj_mgr:get_obj(pkt.param_l.des_id)
		if player == nil or target == nil then return end

		local item_id = operate_l[CUOBEI]["item_id"]
		local bind_id = tonumber(string.sub(item_id,0,-2) .. '0')
		local pack_con = player:get_pack_con()
		local item = pack_con:get_item_by_item_id(bind_id)
		if not item then
			item = pack_con:get_item_by_item_id(item_id)
		end

		--没有道具
		local ret_code = 200009
		--使用物品
		if item then
			ret_code = pack_con:use_item(target, item, pkt.param_l.des_id)
		end
		if ret_code == 200009 then
			ret_code = 21007
		end
		local s_pkt = {};
		s_pkt.result = ret_code
		s_pkt.type = pkt.type
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PLAYER_OPERATE_S, s_pkt);
	end
end

--随机宠物蛋
Clt_commands[1][CMD_RANDOM_PET_EGG_B] =
	function(conn, pkt)
		--参数不合法
		if not pkt or not pkt.slot or not pkt.type or not pkt.money_type then
			return 
		end

		local s_pkt = {}
		local player = g_obj_mgr:get_obj(conn.char_id)
		local pack_con = player:get_pack_con()

		--是不是有道具，判断是否相符
		local slot = pack_con:get_item_by_bag_slot(SYSTEM_BAG , pkt.slot)
		local item = slot and slot.item
		if not item then
			s_pkt.result = 43001
			g_cltsock_mgr:send_client(conn.char_id, CMD_RANDOM_PET_EGG_S ,s_pkt)
			return
		end
		if item:get_m_class() ~= 1 or item:get_s_class() ~= 46 then
			s_pkt.result = 43064
			g_cltsock_mgr:send_client(conn.char_id, CMD_RANDOM_PET_EGG_S ,s_pkt)
			return
		end

		local s_pkt = {}
		--宠物蛋随机
		if item then
			local need_item = ITEM_CURRENCY.PETEGG_REFRESH
			local cnt = 1
			if pkt.type == 2 then
				cnt = 15
			end

			local bind_ctn
			s_pkt.result, bind_ctn = pack_con:del_item_by_item_id_inter_face(need_item, cnt,  {['type']=ITEM_SOURCE.RANDOM_PET_EGG}, 1)	
			if s_pkt.result == 0 then
				s_pkt.result = item:random(pkt.type)
			end
			if bind_ctn and bind_ctn > 0 then
				--print("bind_ctn", bind_ctn)
				item:set_bind(0)
			end

			if s_pkt.result == 0 then
				local e_code, ctn = pack_con:get_bag(SYSTEM_BAG)
				local log_list = {}
				log_list[1] = ctn:get_update_log(ItemSyncFlag.ITEM_SYNC_UPDATE, pkt.slot)
				
				local src_log = {['type']=ITEM_SOURCE.USE_ITEM}
				pack_con:update_client(0, log_list,src_log)
			end
			if s_pkt.result ~= 43067 then
				g_cltsock_mgr:send_client(conn.char_id, CMD_RANDOM_PET_EGG_S ,s_pkt)
			end
		end
	end

--设置宠物蛋星星
Clt_commands[1][CMD_SET_EGG_RANDOM_LEVEL_B] =
	function(conn, pkt)
		--参数不合法
		if not pkt or not pkt.level or not pkt.slot then
			return 
		end

		local s_pkt = {}
		local player = g_obj_mgr:get_obj(conn.char_id)
		local pack_con = player:get_pack_con()

		--是不是有道具，判断是否相符
		local slot = pack_con:get_item_by_bag_slot(SYSTEM_BAG , pkt.slot)
		local item = slot and slot.item
		if not item then
			s_pkt.result = 43001
			g_cltsock_mgr:send_client(conn.char_id, CMD_SET_EGG_RANDOM_LEVEL_S ,s_pkt)
			return
		end
		if item:get_m_class() ~= 1 or item:get_s_class() ~= 46 then
			s_pkt.result = 43064
			g_cltsock_mgr:send_client(conn.char_id, CMD_SET_EGG_RANDOM_LEVEL_S ,s_pkt)
			return
		end

		if item then
			ret_code= item:set_level(pkt.level)
			if ret_code ~= 0 then 
				s_pkt.result = ret_code
				g_cltsock_mgr:send_client(conn.char_id, CMD_SET_EGG_RANDOM_LEVEL_S ,s_pkt)
				return
			end

			local e_code, ctn = pack_con:get_bag(SYSTEM_BAG)
			local log_list = {}
			log_list[1] = ctn:get_update_log(ItemSyncFlag.ITEM_SYNC_UPDATE, pkt.slot)
			
			local src_log = {['type']=ITEM_SOURCE.USE_ITEM}
			pack_con:update_client(0, log_list,src_log)
			g_cltsock_mgr:send_client(conn.char_id, CMD_SET_EGG_RANDOM_LEVEL_S ,{['result'] = 0})
			return
		end
	end


--打开宠物蛋
Clt_commands[1][CMD_RANDOM_USE_PET_EGG_B] =
	function(conn, pkt)
		--参数不合法
		if not pkt or not pkt.location or not pkt.slot then
			return 
		end

		local s_pkt = {}
		local player = g_obj_mgr:get_obj(conn.char_id)
		local pack_con = player:get_pack_con()

		--是不是有道具，判断是否相符
		local slot = pack_con:get_item_by_bag_slot(SYSTEM_BAG , pkt.slot)
		local item = slot and slot.item
		if not item then
			s_pkt.result = 43001
			g_cltsock_mgr:send_client(conn.char_id, CMD_RANDOM_USE_PET_EGG_S ,s_pkt)
			return
		end
		if item:get_m_class() ~= 1 or item:get_s_class() ~= 46 then
			s_pkt.result = 43064
			g_cltsock_mgr:send_client(conn.char_id, CMD_RANDOM_USE_PET_EGG_S ,s_pkt)
			return
		end

		local t_pkt = {}
		t_pkt.location = pkt.location
		if item then
			ret_code= pack_con:use_item(player, slot, t_pkt)
			if ret_code ~= 0 then 
				s_pkt.result = ret_code
				g_cltsock_mgr:send_client(conn.char_id, CMD_RANDOM_USE_PET_EGG_S ,s_pkt)
			end
		end
	end

--抽奖卡填号码
Clt_commands[1][CMD_LOTTERY_SUBMIT_B] =
	function(conn, pkt)
		--参数不合法
		if not pkt or not pkt.slot or not pkt.number  then
			return 
		end

		--local period = 
		local s_pkt = {}
		local player = g_obj_mgr:get_obj(conn.char_id);
		local pack_con = player:get_pack_con();

		--是不是有道具，判断是否相符
		local slot = pack_con:get_item_by_bag_slot(SYSTEM_BAG , pkt.slot)
		local item = slot and slot.item
		if not item then
			s_pkt.result = 43001
			g_cltsock_mgr:send_client(conn.char_id, CMD_LOTTERY_SUBMIT_S ,s_pkt)
			return
		end
		if item:get_m_class() ~= 1 or (item:get_s_class() ~= 36 and item:get_s_class() ~= 62) then
			s_pkt.result = 43064
			g_cltsock_mgr:send_client(conn.char_id, CMD_LOTTERY_SUBMIT_S ,s_pkt)
			return
		end

		local s_pkt = {}
		s_pkt.number = pkt.number
		s_pkt.period = item.period
		--使用物品
		if item then
			ret_code= pack_con:use_item(player, slot, s_pkt)
			if ret_code ~= 0 then 
				s_pkt.result = ret_code
				g_cltsock_mgr:send_client(conn.char_id, CMD_LOTTERY_SUBMIT_S ,s_pkt)
			end
		end
	end

--使用新藏宝图
Clt_commands[1][CMD_USE_PUZZLE_MAP_B] =
	function(conn, pkt)
		--参数不合法
		if not pkt or not pkt.slot then
			return 
		end

		--local period = 
		local s_pkt = {}
		local player = g_obj_mgr:get_obj(conn.char_id);
		local pack_con = player:get_pack_con();

		--是不是有道具，判断是否相符
		local slot = pack_con:get_item_by_bag_slot(SYSTEM_BAG , pkt.slot)
		local item = slot and slot.item
		if not item then
			s_pkt.result = 43001
			g_cltsock_mgr:send_client(conn.char_id, CMD_USE_PUZZLE_MAP_S ,s_pkt)
			return
		end
		local tmp_s_class = item:get_s_class()
		if item:get_m_class() ~= 1 or (tmp_s_class ~= 82 and tmp_s_class ~= 83) then
			s_pkt.result = 43064
			g_cltsock_mgr:send_client(conn.char_id, CMD_USE_PUZZLE_MAP_S ,s_pkt)
			return
		end
		local tmp_color = item:get_color()
		local tmp_name = item:get_name()
		local tmp_id = item:get_item_id()
		--使用物品
		if item then
			ret_code= pack_con:use_item(player, slot, {})
			if ret_code ~= 0 then 
				s_pkt.result = ret_code
				g_cltsock_mgr:send_client(conn.char_id, CMD_USE_PUZZLE_MAP_S ,s_pkt)
				return
			else
				if tmp_s_class == 82 then
					g_treasure_mgr:dig_event(conn.char_id, tmp_color, tmp_id, tmp_name)
				elseif tmp_s_class == 83 then
					treasure_config.dig_event(conn.char_id, tmp_color, tmp_id, tmp_name)
				end
			end
		end

		g_cltsock_mgr:send_client(conn.char_id, CMD_USE_PUZZLE_MAP_S ,{["result"] = 0})
	end

--用钥匙开秘宝箱
Clt_commands[1][CMD_OPEN_SECURITY_BOX_B] =
	function(conn, pkt)
		--参数不合法
		if not pkt or not pkt.slot or not pkt.box_slot  then
			return 
		end

		--local period = 
		local player = g_obj_mgr:get_obj(conn.char_id)
		local pack_con = player:get_pack_con()
		local s_pkt = {}

		--是不是有道具，判断是否相符
		local slot = pack_con:get_item_by_bag_slot(SYSTEM_BAG , pkt.slot)
		local box_slot = pack_con:get_item_by_bag_slot(SYSTEM_BAG , pkt.box_slot)
		local item = slot and slot.item
		local box_item = box_slot and box_slot.item
		if not item or not box_item then
			s_pkt.result = 43001
			g_cltsock_mgr:send_client(conn.char_id, CMD_OPEN_SECURITY_BOX_S, s_pkt)
			return
		end
		if item:get_m_class() ~= 1 or item:get_s_class() ~= 41 or 
			box_item:get_m_class() ~= 1 or box_item:get_s_class() ~= 40	then

			s_pkt.result = 43064
			g_cltsock_mgr:send_client(conn.char_id, CMD_OPEN_SECURITY_BOX_S, s_pkt)
			return
		end
		--是否所需钥匙
		local key_id = item.proto.value.id
		local box_id = box_item.proto.value.id
		if (key_id == 141000000141 and box_id ~= 140000000141) or
			(key_id == 141000000241 and box_id ~= 140000000241) or	
			(key_id == 141000000341 and box_id ~= 140000000341) then
			s_pkt.result = 20375
			g_cltsock_mgr:send_client(conn.char_id, CMD_OPEN_SECURITY_BOX_S, s_pkt)
			return
		end

		--使用物品
		if item then
			ret_code= pack_con:use_item(player, slot, pkt)
			if ret_code ~= 0 then 
				s_pkt.result = ret_code
				g_cltsock_mgr:send_client(conn.char_id, CMD_OPEN_SECURITY_BOX_S ,s_pkt)
			end
		end
	end

--降妖
Clt_commands[1][CMD_MAP_CRATES_QXFJ_C] =
function(conn, pkt)
	--print("CMD_MAP_CRATES_QXFJ_C", j_e(pkt))
	--参数不合法
	if not pkt or not pkt.k_type or not pkt.money_type then
		return 
	end

	if pkt.k_type < 1 or pkt.k_type > 4 or pkt.money_type < 1 or pkt.money_type > 3 then
		return
	end
	
	local player = g_obj_mgr:get_obj(conn.char_id)
	if not player then return end

	local pack_con = player:get_pack_con()
	local e_code, bag = pack_con:get_bag(MONSTER_BAG)
	if e_code ~= 0 then 
		return
	end

	local count = pkt.money_type
	if pkt.money_type == 2 then
		count = 10
	elseif pkt.money_type == 3 then
		count = 30
	end

	local s_pkt = {}
	--降妖背包不足
	if count > bag:get_ept_cnt() then
		s_pkt.result = 43093
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_CRATES_QXFJ_S ,s_pkt)
		return
	end

	--
	local e_code, can_use_item = bag:can_control_monster(pkt.k_type, count, pkt.money_type)
	if e_code ~= 0 then 
		s_pkt.result = e_code
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_CRATES_QXFJ_S, s_pkt)
		return
	end 
	if can_use_item then	--直接使用道具
		local erorr, log_list
		local tmp_pkt = {}
		tmp_pkt.counts, erorr, log_list = bag:do_control_monster_use_item(pkt.k_type, count, pkt.money_type)
		if erorr == 0 then
			if pkt.k_type == 4 then
				pack_con:db_item_operation(log_list,{['type']= ITEM_SOURCE.CHEST_FOUR })
				pack_con:update_client(0, log_list,{['type']= ITEM_SOURCE.CHEST_FOUR })
			else
				pack_con:db_item_operation(log_list,{['type']=(ITEM_SOURCE.CHEST_ONE -1 + pkt.k_type)})
				pack_con:update_client(0, log_list,{['type']=(ITEM_SOURCE.CHEST_ONE -1 + pkt.k_type)})
			end
		end
		tmp_pkt.result = erorr
		--通知客户端剩余次数
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_CRATES_ONE_QTJL_S ,tmp_pkt)
	else
		pkt.all_money = bag:get_control_monster_cost(pkt.k_type, count, pkt.money_type)
		if pkt.all_money == nil then
			s_pkt.result = 21202
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_CRATES_QXFJ_S, s_pkt)
		end
		g_svsock_mgr:send_server_ex(COMMON_ID, conn.char_id, CMD_M2C_QQ_XIANG_YAO_M, pkt)
	end
	return
end

--降妖
Sv_commands[0][CMD_M2C_QQ_XIANG_YAO_C] =
function(conn, char_id, pkt)
	if pkt.result and pkt.result ~= 0 then
		g_cltsock_mgr:send_client(char_id, CMD_MAP_CRATES_QXFJ_S, {result = pkt.result})
		return
	end
	
	--参数不合法
	if not pkt or not pkt.k_type or not pkt.money_type then
		pkt.result = 111
		g_svsock_mgr:send_server_ex(COMMON_ID,char_id, CMD_M2C_QQ_XIANG_YAO_REQ, pkt)
		return 
	end
	
	local player = g_obj_mgr:get_obj(char_id)
	local pack_con = player and player:get_pack_con()
	local e_code, bag 
	if pack_con then
		e_code, bag = pack_con:get_bag(MONSTER_BAG)
	end
	
	if e_code ~= 0 or bag == nil then 
		pkt.result = 112
		g_svsock_mgr:send_server_ex(COMMON_ID,char_id, CMD_M2C_QQ_XIANG_YAO_REQ, pkt)
		return
	end

	local count = pkt.money_type
	if pkt.money_type == 2 then
		count = 10
	elseif pkt.money_type == 3 then
		count = 30
	end

	local s_pkt = {}
	--降妖背包不足
	if count > bag:get_ept_cnt() then
		s_pkt.result = 43093
		g_cltsock_mgr:send_client(char_id, CMD_MAP_CRATES_QXFJ_S ,s_pkt)
		pkt.result = 43093
		g_svsock_mgr:send_server_ex(COMMON_ID,char_id, CMD_M2C_QQ_XIANG_YAO_REQ, pkt)
		return
	end

	--
	local e_code, can_use_item = bag:can_control_monster(pkt.k_type, count, pkt.money_type)
	if e_code ~= 0 then 
		s_pkt.result = e_code
		g_cltsock_mgr:send_client(char_id, CMD_MAP_CRATES_QXFJ_S ,s_pkt)
		pkt.result = e_code
		g_svsock_mgr:send_server_ex(COMMON_ID,char_id, CMD_M2C_QQ_XIANG_YAO_REQ, pkt)
		return
	end 
	
	local erorr, log_list
	local tmp_pkt = {}
	tmp_pkt.counts, erorr, log_list = bag:do_control_monster(pkt.k_type, count, pkt.money_type, false)
	if erorr == 0 then
		if pkt.k_type == 4 then
			pack_con:db_item_operation(log_list,{['type']= ITEM_SOURCE.CHEST_FOUR })
			pack_con:update_client(0, log_list,{['type']= ITEM_SOURCE.CHEST_FOUR })
		else
			pack_con:db_item_operation(log_list,{['type']=(ITEM_SOURCE.CHEST_ONE -1 + pkt.k_type)})
			pack_con:update_client(0, log_list,{['type']=(ITEM_SOURCE.CHEST_ONE -1 + pkt.k_type)})
		end
	end
	tmp_pkt.result = erorr
	--通知客户端剩余次数
	g_cltsock_mgr:send_client(char_id, CMD_MAP_CRATES_ONE_QTJL_S ,tmp_pkt)

	pkt.result = erorr
	g_svsock_mgr:send_server_ex(COMMON_ID,char_id, CMD_M2C_QQ_XIANG_YAO_REQ, pkt)
	return
end

--打开降妖记录
Clt_commands[1][CMD_MAP_CRATES_QTJL_C] =
function(conn, pkt)
	g_svsock_mgr:send_server_ex(COMMON_ID, conn.char_id, CMD_C2W_ALL_MONSTER_RECORD_M, pkt)
	return
end

--时装续费
Sv_commands[0][CMD_M2C_QQ_FASHION_C] =
	function(conn, char_id, pkt)
		--print("907 =", j_e(pkt))
		--参数不合法
		if pkt.result and pkt.result ~= 0 then
			g_cltsock_mgr:send_client(char_id, CMD_FASHION_RENEWAL_S, {result = pkt.result})
			return
		end
		

		local s_pkt = {}
		local player = g_obj_mgr:get_obj(char_id)
		local pack_con = player:get_pack_con()

		--是不是有道具，判断是否相符
		local slot = pack_con:get_item_by_bag_slot(SYSTEM_BAG , pkt.slot)
		local item = slot and slot.item
		if not item then
			s_pkt.result = 43001
			pkt.result = 43001
			g_svsock_mgr:send_server_ex(COMMON_ID,char_id, CMD_M2C_QQ_FASHION_REQ, pkt)
			g_cltsock_mgr:send_client(char_id, CMD_FASHION_RENEWAL_S ,s_pkt)
			return
		end
		if item:get_m_class() ~= 5 or item:get_s_class() ~= 12 then
			s_pkt.result = 43064
			g_cltsock_mgr:send_client(char_id, CMD_FASHION_RENEWAL_S ,s_pkt)
			pkt.result = 43064
			g_svsock_mgr:send_server_ex(COMMON_ID,char_id, CMD_M2C_QQ_FASHION_REQ, pkt)
			return
		end

		ret_code = item:set_last_time(pkt.days)

		local e_code, ctn = pack_con:get_bag(SYSTEM_BAG)
		local log_list = {}
		log_list[1] = ctn:get_update_log(ItemSyncFlag.ITEM_SYNC_UPDATE, pkt.slot)
			
		local src_log = {['type']=ITEM_SOURCE.USE_ITEM}
		pack_con:update_client(0, log_list,src_log)
		g_cltsock_mgr:send_client(char_id, CMD_FASHION_RENEWAL_S ,{['result'] = 0})
		
		pkt.result = 0
		g_svsock_mgr:send_server_ex(COMMON_ID,char_id, CMD_M2C_QQ_FASHION_REQ, pkt)
		return
	end

--时装续费
Clt_commands[1][CMD_FASHION_RENEWAL_B] =
	function(conn, pkt)
		if not pkt or not pkt.slot or not pkt.days or not pkt.money_type or 
			(pkt.money_type ~= 3) then
			return 
		end

		local s_pkt = {}
		local player = g_obj_mgr:get_obj(conn.char_id)
		local pack_con = player:get_pack_con()

		--是不是有道具，判断是否相符
		local slot = pack_con:get_item_by_bag_slot(SYSTEM_BAG , pkt.slot)
		local item = slot and slot.item
		if not item then
			s_pkt.result = 43001
			pkt.result = 43001
			g_svsock_mgr:send_server_ex(COMMON_ID,char_id, CMD_M2C_QQ_FASHION_REQ, pkt)
			g_cltsock_mgr:send_client(conn.char_id, CMD_FASHION_RENEWAL_S ,s_pkt)
			return
		end
		if item:get_m_class() ~= 5 or item:get_s_class() ~= 12 then
			s_pkt.result = 43064
			pkt.result = 43064
			g_svsock_mgr:send_server_ex(COMMON_ID,char_id, CMD_M2C_QQ_FASHION_REQ, pkt)
			g_cltsock_mgr:send_client(conn.char_id, CMD_FASHION_RENEWAL_S ,s_pkt)
			return
		end

		if item then
			local ret_code ,cost = item:get_cost(tostring(pkt.days), 1, 2)
			if ret_code ~= 0 then 
				s_pkt.result = ret_code
				g_cltsock_mgr:send_client(conn.char_id, CMD_FASHION_RENEWAL_S ,s_pkt)
				return
			end

			local ret = {}
			for k, v in pairs(pkt) do
				ret[k] = v
			end
			ret.cost = cost

			g_svsock_mgr:send_server_ex(COMMON_ID, conn.char_id, CMD_M2C_QQ_FASHION_M, ret)
		end
	end

--改名道具
Clt_commands[1][CMD_CHANGE_NAME_ITEM_B] =
	function(conn, pkt)
		--参数不合法
		if not pkt or not pkt.slot or not pkt.type or not pkt.name then
			return 
		end

		local s_pkt = {}

		if f_filter_world(pkt.name) then 
			s_pkt.result = 43074
			g_cltsock_mgr:send_client(conn.char_id, CMD_CHANGE_NAME_ITEM_S, s_pkt)
			return 
		end

		if pkt.type == 1 then
			local query = string.format("{name:'%s'}", pkt.name)
			local num, e_code = f_get_db():count("characters", query)
			if 0 == e_code and 0 ~= num then
				s_pkt.result = 43074
				g_cltsock_mgr:send_client(conn.char_id, CMD_CHANGE_NAME_ITEM_S, s_pkt)
				return 
			end
		elseif pkt.type == 2 then
			local e_code = g_faction_mgr:change_name(conn.char_id, pkt.name)
			if 0 ~= e_code then
				s_pkt.result = e_code
				g_cltsock_mgr:send_client(conn.char_id, CMD_CHANGE_NAME_ITEM_S, s_pkt)
				return 
			end
		else
			s_pkt.result = 1
			g_cltsock_mgr:send_client(conn.char_id, CMD_CHANGE_NAME_ITEM_S, s_pkt)
			return
		end

		local player = g_obj_mgr:get_obj(conn.char_id)
		local pack_con = player:get_pack_con()
		

		--是不是有道具，判断是否相符
		local slot = pack_con:get_item_by_bag_slot(SYSTEM_BAG , pkt.slot)
		local item = slot and slot.item
		if not item then
			s_pkt.result = 43001
			g_cltsock_mgr:send_client(conn.char_id, CMD_CHANGE_NAME_ITEM_S, s_pkt)
			return
		end
		if item:get_m_class() ~= 1 or item:get_s_class() ~= 49 + pkt.type then

			s_pkt.result = 43064
			g_cltsock_mgr:send_client(conn.char_id, CMD_CHANGE_NAME_ITEM_S, s_pkt)
			return
		end

		--使用物品
		if item then
			local param_l = {}
			param_l.name = pkt.name
			param_l.type = pkt.type
			param_l.char_id = conn.char_id
			s_pkt.result = pack_con:use_item(player, slot, param_l)
			g_cltsock_mgr:send_client(conn.char_id, CMD_CHANGE_NAME_ITEM_S ,s_pkt)
		end
	end

--宠物 增加祝福值 20121211 chendong
--[[
--增加祝福值道具
Clt_commands[1][CMD_ADD_BENEDICTION_ITEM_B] =
	function(conn, pkt)
		--参数不合法
		if not pkt or not pkt.s_slot or not pkt.d_slot or not pkt.count or not pkt.bag then
			return 
		end

		local s_pkt = {}

		local player = g_obj_mgr:get_obj(conn.char_id)
		local pack_con = player:get_pack_con()
		

		--是不是有道具，判断是否相符
		local d_slot = pack_con:get_item_by_bag_slot(pkt.bag , pkt.d_slot)
		local d_item = d_slot and d_slot.item
		if not d_item then
			s_pkt.result = 43001
			g_cltsock_mgr:send_client(conn.char_id, CMD_CHANGE_NAME_ITEM_S, s_pkt)
			return
		end
		if d_item:get_m_class()~=ItemClass.ITEM_CLASS_EQUIP then
			s_pkt.result = 43064
			g_cltsock_mgr:send_client(conn.char_id, CMD_ADD_BENEDICTION_ITEM_S ,s_pkt)
			return
		end

		local s_slot = pack_con:get_item_by_bag_slot(SYSTEM_BAG , pkt.s_slot)
		if not s_slot or s_slot.number < pkt.count or pkt.count < 1 then
			s_pkt.result = 43002
			g_cltsock_mgr:send_client(conn.char_id, CMD_ADD_BENEDICTION_ITEM_S, s_pkt)
			return
		end
		local s_item = s_slot and s_slot.item
		if s_item:get_m_class() ~= 1 or s_item:get_s_class() ~= 52 then
			s_pkt.result = 43064
			g_cltsock_mgr:send_client(conn.char_id, CMD_ADD_BENEDICTION_ITEM_S, s_pkt)
			return
		end

		--增加祝福值
		local benediction = s_item:get_benediction_value() * pkt.count
		local flags = false
		if s_item:get_bind() == 0 then
			flags = true
		end
		pack_con:del_item_by_bag_slot(SYSTEM_BAG, pkt.s_slot, pkt.count, {['type']=ITEM_SOURCE.ADD_BENEDICTION})

		d_item:add_benediction(benediction)
		if flags then
			d_item:set_bind(0)
		end

		local e_code, ctn = pack_con:get_bag(pkt.bag)
		local log_list = {}
		log_list[1] = ctn:get_update_log(ItemSyncFlag.ITEM_SYNC_UPDATE, pkt.d_slot)
		pack_con:update_client(0, log_list, {['type']=ITEM_SOURCE.USE_ITEM})

		s_pkt.result = 0
		g_cltsock_mgr:send_client(conn.char_id, CMD_ADD_BENEDICTION_ITEM_S ,s_pkt)
	end

--增加宠物祝福值
Clt_commands[1][CMD_ADD_BENEDICTION_PET_B] =
	function(conn, pkt)
		--参数不合法
		if not pkt or not pkt.slot or not pkt.pet_id then
			return 
		end

		local s_pkt = {}

		local player = g_obj_mgr:get_obj(conn.char_id)
		local pack_con = player:get_pack_con()
		if not pack_con then return end
		
		local pet_con = player:get_pet_con()
		if not pet_con then return end

		local pet_obj = pet_con:get_pet_obj(pkt.pet_id)
		if not pet_obj then print("1012") return end

		--是不是有道具，判断是否相符
		local slot = pack_con:get_item_by_bag_slot(SYSTEM_BAG , pkt.slot)
		if slot.number < pkt.count or pkt.count < 1 then
			s_pkt.result = 43002
			g_cltsock_mgr:send_client(conn.char_id, CMD_ADD_BENEDICTION_PET_S, s_pkt)
			return
		end
		local item = slot and slot.item
		if item:get_m_class() ~= 1 or (item:get_s_class()~=52 and item:get_s_class()~=80) then -- 80为后来添加的，只增加宠物祝福值的道具,cailizhong
			s_pkt.result = 43064
			g_cltsock_mgr:send_client(conn.char_id, CMD_ADD_BENEDICTION_PET_S, s_pkt)
			return
		end

		--cailizhong添加----------
		if item:get_s_class() == 80 then
			local e_code = item:can_use(player, pet_obj)
			if e_code ~= 0 then return end -- 不是宠物不能使用
			local pullulate = pet_obj:get_pullulate()
			if pullulate < item:get_pet_pullulate_value() then -- 宠物成长值达不到要求
				s_pkt.result = 31221
				g_cltsock_mgr:send_client(conn.char_id, CMD_ADD_BENEDICTION_PET_S, s_pkt)
				return
			end
		end
		--------------------------

		--增加祝福值
		local benediction = item:get_benediction_value() * pkt.count
		local flags = false
		if item:get_bind() == 0 then
			flags = true
		end
		pack_con:del_item_by_bag_slot(SYSTEM_BAG, pkt.slot, pkt.count, {['type']=ITEM_SOURCE.ADD_BENEDICTION})

		pet_obj:set_bless(benediction + pet_obj:get_bless())
		if flags then
			pet_obj:set_bind(0)
		end
		local new_pkt = pet_obj:net_get_att_info()
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PET_GET_ATT_S, new_pkt)

		s_pkt.result = 0
		g_cltsock_mgr:send_client(conn.char_id, CMD_ADD_BENEDICTION_PET_S ,s_pkt)
	end
--]]

--使用多个小金袋
Clt_commands[1][CMD_USE_MORE_GOLD_TOOL_B] =
	function(conn, pkt)
		--参数不合法
		if not pkt or not pkt.slot then
			return 
		end

		local s_pkt = {}

		local player = g_obj_mgr:get_obj(conn.char_id)
		local pack_con = player:get_pack_con()
		if not pack_con then return end
		local lock = player:get_protect_lock()
		local e_code, b_bag = pack_con:get_bag(SYSTEM_BAG)

		--是不是道具
		local slot = pack_con:get_item_by_bag_slot(SYSTEM_BAG , pkt.slot)
		local item = slot and slot.item
		if not item or item:get_item_id()/10 ~= 10400110012 then
			return
		end
		if not lock then return end
		if lock:check_lock_item(item) then return end
		local item_id = slot.item_id
		local uuid = slot.uuid
		local cnt = slot.number

		--使用物品
		local e_code = item:can_use(player, player)
		if e_code ~= 0 then
			g_cltsock_mgr:send_client(conn.char_id, CMD_USE_MORE_GOLD_TOOL_S ,{['result'] = e_code})
			return
		end

		local log_list = {}
		log_list[1] = b_bag:get_update_log(ItemSyncFlag.ITEM_SYNC_UPDATE, pkt.slot)

		e_code = item:use(player,player)
		if e_code ~= 0 then
			return e_code
		end

		for i = 1, cnt - 1 do
			item:use(player,player)
		end

		b_bag:inform_other_modual(3, pkt.slot, item_id, uuid)

		pack_con:del_item_by_bag_slot(SYSTEM_BAG, pkt.slot, cnt, {['type']=ITEM_SOURCE.USE_ITEM})
		------

		g_cltsock_mgr:send_client(conn.char_id, CMD_USE_MORE_GOLD_TOOL_S ,{['result'] = 0})
	end

--购买游戏货币
local buy_rate = {28, 26}
Clt_commands[1][CMD_BUY_GAMES_GOLD_B] =
	function(conn, pkt)
		if true then
			return ---干掉该功能
		end
		--参数不合法
		if not pkt or not pkt.money_type or not pkt.count or pkt.count < 1 then
			return 
		end

		local s_pkt = {}

		local player = g_obj_mgr:get_obj(conn.char_id)
		if not player then return end
		local pack_con = player:get_pack_con()
		if not pack_con then return end
		
		local moneylist = {}
		moneylist[pkt.money_type + 2] = buy_rate[pkt.money_type] * pkt.count
		if pkt.money_type == 1 then
			s_pkt.result = pack_con:dec_money_l_inter_face(moneylist, {['type']=MONEY_SOURCE.BUY_GOLD}, nil, 1)	
		elseif pkt.money_type == 2 then
			s_pkt.result = pack_con:dec_money_l_inter_face(moneylist, {['type']=MONEY_SOURCE.BUY_GOLD}, 2, 1)	
		else
			return
		end
			
		if s_pkt.result ~= 0 then
			g_cltsock_mgr:send_client(conn.char_id, CMD_BUY_GAMES_GOLD_S, s_pkt)
			return
		end

		local money_list = {}
		money_list[pkt.money_type] = pkt.count * 10000
		pack_con:add_money_l(money_list, {['type']=MONEY_SOURCE.BUY_GOLD})

		------

		g_cltsock_mgr:send_client(conn.char_id, CMD_BUY_GAMES_GOLD_S, {['result'] = 0})
	end

--批量使用物品
Clt_commands[1][CMD_MULTIPLE_USE_B] =
	function(conn, pkt)
		--参数不合法
		if not pkt or not pkt.slot or not pkt.count or not pkt.bag then
			return 
		end

		local player = g_obj_mgr:get_obj(conn.char_id)
		if not player then return end
		local pack_con = player:get_pack_con()
		if not pack_con then return end

		local lock = player:get_protect_lock()
		local e_code, b_bag = pack_con:get_bag(SYSTEM_BAG)
		--是不是合法道具
		local slot = pack_con:get_item_by_bag_slot(pkt.bag , pkt.slot)
		local item = slot and slot.item
		if not item or not item:can_multiple_use() then
			g_cltsock_mgr:send_client(conn.char_id, CMD_MULTIPLE_USE_S, {["result"] = 43086})
			return
		end
		if not lock then return end
		if lock:check_lock_item(item) then return end
		if slot.number < pkt.count then
			g_cltsock_mgr:send_client(conn.char_id, CMD_MULTIPLE_USE_S, {["result"] = 43002})
			return
		end

		local item_id = slot.item_id
		local uuid = slot.uuid
		local cnt = 0

		--使用物品
		e_code = item:can_use(player, player, {['cnt'] = pkt.count})
		if e_code ~= 0 then
			g_cltsock_mgr:send_client(conn.char_id, CMD_MULTIPLE_USE_S, {['result'] = e_code})
			return
		end

		local log_list = {}
		log_list[1] = b_bag:get_update_log(ItemSyncFlag.ITEM_SYNC_UPDATE, pkt.slot)

		if item:multiple_use_check() then
			e_code = item:use(player, player, {['cnt'] = pkt.count})
			if e_code == 0 then
				cnt = pkt.count
			end
		else
			for i = 1, pkt.count do
				e_code = item:use(player,player)
				if e_code ~= 0 then
					break
				end
				cnt = cnt + 1
			end
		end

		if cnt > 0 then
			b_bag:inform_other_modual(3, pkt.slot, item_id, uuid)

			pack_con:del_item_by_bag_slot(pkt.bag, pkt.slot, cnt, {['type']=ITEM_SOURCE.USE_ITEM})
		end
		------

		g_cltsock_mgr:send_client(conn.char_id, CMD_MULTIPLE_USE_S, {['result'] = e_code})
	end

--获取材料信息
Clt_commands[1][CMD_GET_HOME_MATERIAL_B] =
	function(conn, pkt)
		--参数不合法
		if not pkt then
			return 
		end

		local player = g_obj_mgr:get_obj(conn.char_id)
		if not player then return end
		local pack_con = player:get_pack_con()
		if not pack_con then return end

		local e_code, h_bag = pack_con:get_bag(HOME_BAG)
		if e_code ~= 0 then
			g_cltsock_mgr:send_client(conn.char_id, CMD_GET_HOME_MATERIAL_S, {['result'] = e_code})
		end

		local s_pkt = {}
		s_pkt.result = 0
		s_pkt.material = h_bag:get_material_info()
		g_cltsock_mgr:send_client(conn.char_id, CMD_GET_HOME_MATERIAL_S, s_pkt)

	end

--获取单个材料信息
Clt_commands[1][CMD_GET_HOME_MATERIAL_SINGLE_B] =
	function(conn, pkt)
		--参数不合法
		if not pkt or not pkt.id then
			return 
		end

		local player = g_obj_mgr:get_obj(conn.char_id)
		if not player then return end
		local pack_con = player:get_pack_con()
		if not pack_con then return end

		local e_code, h_bag = pack_con:get_bag(HOME_BAG)
		if e_code ~= 0 then
			return
		end

		local s_pkt = {}
		s_pkt.id = pkt.id
		s_pkt.num = h_bag:get_material_num(id)
		g_cltsock_mgr:send_client(conn.char_id, CMD_GET_HOME_MATERIAL_SINGLE_S, s_pkt)

	end

--职业进阶
Clt_commands[1][CMD_GET_OCC_LEVELUP_B] =
	function(conn, pkt)
		--print("1331 =", j_e(pkt))
		local player = g_obj_mgr:get_obj(conn.char_id)
		if not player then return end
		if player:get_level() < 80 then
			g_cltsock_mgr:send_client(conn.char_id, CMD_GET_OCC_LEVELUP_S, {["result"] = 43021})
			return
		end

		--if player:check_occ_levelup() then
			--g_cltsock_mgr:send_client(conn.char_id, CMD_GET_OCC_LEVELUP_S, {["result"] = 43092})
			--return
		--end

		local pack_con = player:get_pack_con()
		if not pack_con then return end
		-- 渡劫 职业进阶 chendong 120925
		--[[
		if not g_kalpa_mgr:is_full_80_level(conn.char_id) then			g_cltsock_mgr:send_client(conn.char_id, CMD_GET_OCC_LEVELUP_S, {["result"] = 43089})			return		end		--]]

		local skill_con = player:get_skill_con()
		if not skill_con:is_full_80_level_combat_skill(player:get_occ()) then			g_cltsock_mgr:send_client(conn.char_id, CMD_GET_OCC_LEVELUP_S, {["result"] = 43090})			return		end

		--元神满级
		local soul_con = player:get_soul()		if not soul_con:is_all_complete(14) then			g_cltsock_mgr:send_client(conn.char_id, CMD_GET_OCC_LEVELUP_S, {["result"] = 43091})			return		end

		local error = pack_con:del_item_by_item_id_inter_face(202004200040, 1, {["type"] = ITEM_SOURCE.EQUIP_ADVANCED}, 1)
		if error ~= 0 then			g_cltsock_mgr:send_client(conn.char_id, CMD_GET_OCC_LEVELUP_S, {["result"] = error})			return		end
		player:occ_levelup()

		g_cltsock_mgr:send_client(conn.char_id, CMD_GET_OCC_LEVELUP_S, {["result"] = 0})

		--广播
		local sys_l = {}
		sys_l[1] = player:get_name()

		local color_l = {}
		local str_json = f_get_sysbd_format(10019, sys_l, color_l)
		f_cmd_sysbd(str_json)

	end
	
Clt_commands[1][CMD_MAP_MOVE_ITEM_B] = 
	function(conn,pkt)
		if not pkt then return end
		local player = g_obj_mgr:get_obj(conn.char_id)
		if not player then return end
		local pack_con = player:get_pack_con()
		--pkt.src_bag  pkt.dst_bag
		local e_code = pack_con:move_all(pkt.src_bag,pkt.dst_bag)
		if e_code~=0 then
			local s_ret = {}
			s_ret.result = e_code
			g_cltsock_mgr:send_client(conn.char_id,CMD_MAP_MOVE_ITEM_S ,s_ret)
		end
	end
	
----------------------------------------*******************************处理从common返回命令接口（广播等）
--请求列表
Sv_commands[0][CMD_C2W_ALL_MONSTER_RECORD_C] = 
	function(conn, char_id, pkt)
		if char_id == nil then return end
		if not pkt then return end
		g_cltsock_mgr:send_client(char_id, CMD_MAP_CRATES_QTJL_S, pkt)
	end

--对方在线，则扣鲜花
Sv_commands[0][CMD_FLOWER_CHECK_ON_LINE_C] = 
	function(conn, char_id, pkt)
		if char_id == nil then return end
		if not pkt then return end
		local s_pkt = {}
		if pkt.result ~= 0 then			--对方不在线
			s_pkt.result = pkt.result
			g_cltsock_mgr:send_client(char_id, CMD_SEND_FLOWER_S, s_pkt)

		else							--在线，扣除鲜花
			local player = g_obj_mgr:get_obj(pkt.sender)
			if not player then return end

			local pack_con = player:get_pack_con()
			local slot = pack_con:get_item_by_bag_slot(SYSTEM_BAG , pkt.slot)
			local item = slot and slot.item

			if not item then return end
			
			if item:get_m_class() ~= 1 or item:get_s_class() ~= 20	then return	end

			--扣花
			pack_con:del_item_by_bag_slot(SYSTEM_BAG, pkt.slot, 1, {['type']=ITEM_SOURCE.USE_ITEM})

			g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id, CMD_FLOWER_PRE_SEND_M, pkt)
		end

		return
	end

--找到接受者所在线加上鲜花
Sv_commands[0][CMD_FLOWER_SEND_C] = 
	function(conn, char_id, pkt)
		if not pkt then return end
		pkt.result = f_other_flower(pkt.sender, pkt.receiver, pkt.effect, pkt.text, pkt.sender_n, pkt.item_id)

		g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id, CMD_FLOWER_SEND_M, pkt)
	end

--加上鲜花后的返回
Sv_commands[0][CMD_FLOWER_SEND_READY_C] = 
	function(conn, char_id, pkt)
		if not pkt or not pkt.result then return end

		local s_pkt = {}
		s_pkt.result = pkt.result

		if pkt.result ~= 0 then 	--回滚,通过邮件补偿
			local spkt = {}
			spkt.sender = -1
			spkt.recevier = pkt.sender
			spkt.title = f_get_string(516) or ""
			spkt.content = f_get_string(517) or ""
			spkt.number = 1

			spkt.item_id = pkt.item_id
			g_svsock_mgr:send_server_ex(COMMON_ID, char_id, CMD_M2P_SEND_EMAIL_NO_BOX_S, spkt)

			local str_log = string.format("flower compensate(char_id, receiverr, type) values(%d,%d,'%s')",
			pkt.sender, pkt.receiver, pkt.type)
			g_item_log:write(str_log)

		else						--成功，加亲密度
			g_marry_mgr:use_flw_add_res(pkt.sender, pkt.receiver, pkt.effect)
		end

		g_cltsock_mgr:send_client(pkt.sender, CMD_SEND_FLOWER_S, s_pkt)
	end


--离婚通知
Sv_commands[0][CMD_P2M_SET_RING_DB] = 
	function(conn, char_id, pkt)
		if not pkt or not pkt.char_id then return end
		
		local player = g_obj_mgr:get_obj(pkt.char_id)
		if not player then
			local m_db = f_get_db()
			local query = string.format("{id:%d}", pkt.char_id)
			local info = {["married"] = 0}
			info = Json.Encode(info)
			m_db:update("characters", query, info)
		else
			player:break_marriage()
			player:on_update_attribute(2)
		end
	end

----------------------------------------*******************************物品接口（广播等）
------------------------------------------使用帮主弹劾令
function f_use_impeach(char_id)
	return g_faction_mgr:impeach(char_id)
end

------------------------------------------使用帮派资源道具广播
function f_broadcast_faction_item(char_id, char_name, item_id, count)
	
	local pk = {}
	pk.type			= 31
	pk.char_id		= char_id
	pk.char_name	= char_name
	pk.item_id		= item_id
	pk.count		= count
	g_svsock_mgr:send_server_ex(WORLD_ID, char_id, CMD_C2W_FACTION_ITEM_MISSION_S, pk)

	return 0
end

------------------------------------------使用抽奖券选号码
function f_lottery_choice_number(char_id, number)
	if char_id and number then
		local pk = {}
		pk.char_id  = char_id
		pk.number	= number
		g_svsock_mgr:send_server_ex(COMMON_ID,char_id, CMD_LOTTERY_CHOICE_NUMBER_M, pk)
	end
	return 0
end

------------------------------------------使用实物抽奖券选号码
function f_spec_lottery_choice_number(char_id, number)
	if char_id and number then
		local pk = {}
		pk.char_id  = char_id
		pk.number	= number
		g_svsock_mgr:send_server_ex(COMMON_ID,char_id, CMD_SPECLOTTERY_CHOICE_NUMBER_M, pk)
	end
	return 0
end

------------------------------------------使用彩票领奖广播
function f_broadcast_lottery_item(type, char_id, char_name, lvl, period, series, bonus)
	
	local pk = {}
	pk.type			= type
	pk.char_id		= char_id
	pk.char_name	= char_name
	pk.lvl			= lvl
	pk.period		= period
	pk.id			= series
	pk.bonus		= bonus
	g_svsock_mgr:send_server_ex(WORLD_ID, char_id, CMD_M2C_GET_LOTTERY_S, pk)

	return 0
end

------------------------------------------秘宝箱广播
function f_broadcast_security_box(char_id, pk)

	g_svsock_mgr:send_server_ex(WORLD_ID, char_id, CMD_M2C_SECURITY_BOX_W, pk)

	return 0
end

------------------------------------------宠物蛋广播
function f_broadcast_pet_egg(char_id, pk)

	g_svsock_mgr:send_server_ex(WORLD_ID, char_id, CMD_M2C_BROADCAST_PET_EGG_W, pk)

	return 0
end

------------------------------------------改名道具广播到common
function f_change_name_item(pk)

	g_svsock_mgr:send_server_ex(COMMON_ID, pk.char_id, CMD_M2C_CHANGENAME_ITEM_M, pk)

	return 0
end

------------------------------------------魂玉加经验错误
function f_pet_add_exp_error(pk)

	g_cltsock_mgr:send_client(pk.char_id, CMD_MAP_PET_ADD_EXP_ERROR_S, pk)

	return 0
end


------------------------------------------配置错误日志
function f_record_item_no_exp(item_id)
	local str = ev.time .. " item_id:" ..item_id .. " no exp!!"
	g_item_record_log:write(str)

	return 0
end

function f_test_fuction(char_id)
	local player = g_obj_mgr:get_obj(char_id)
	local pack_con = player:get_pack_con()
	local item_db = {['cur_endure']=250,['intensify_card']=0,['bind']=1,['hole_t']={},['append_t']={},['max_endure']=250,['skill_t']={},['rank']=1}
	local item_list = {}
	item_list[1] = {}
	item_list[1].count = 1
	item_list[1].id	   = 551010003011
	item_list[1].name  ="fsdag"
	item_list[1].item_db = item_db
	local _,g_bag = Item_factory.create(104002000130)	g_bag:set_item_list(item_list)

	local list = {}
	list[1] = {}
	list[1].type = 2
	list[1].item = g_bag
	list[1].number = 1

	list[2] = {}
	list[2].type = 1
	list[2].item_id = 601010010111
	list[2].number = 199

	local money_list = {}
	money_list[MoneyType.GIFT_JADE] = 5
	money_list[MoneyType.GOLD] = 100
	money_list[MoneyType.JADE] = 100
	local src_log ={}
	src_log.type =ITEM_SOURCE.GAIN_STALL_TRADE
	print("result =", pack_con:dec_money_l_inter_face(money_list, src_log))
	--local err_code = pack_con:add_item_l(list,src_log)
end

--打开血脉印记--刷新仙灵技能--cailizhong
--随机仙灵技能
Clt_commands[1][CMD_RANDOM_CHILD_SKILL_B] =
function(conn, pkt)
	if not pkt or not pkt.slot or not pkt.random_type then
		return -- 参数不合法
	end

	local ret = {}
	local player = g_obj_mgr:get_obj(conn.char_id) -- 获取人物对象
	local pack_con = player:get_pack_con() -- 获取人物背包
	-- 判断是否存在道具(血脉印记)
	local slot = pack_con:get_item_by_bag_slot(SYSTEM_BAG, pkt.slot) -- 获取格子物品
	local item = slot and slot.item
	if not item then
		ret.result = 43001 -- 找不到物品
		g_cltsock_mgr:send_client(conn.char_id, CMD_RANDOM_CHILD_SKILL_S, ret)
		return
	end
	if item:get_m_class()~=1 or item:get_s_class()~=78 then -- 仙灵技能刷新道具，血脉印记
		ret.result = 43064 -- 物品不对
		g_cltsock_mgr:send_client(conn.char_id, CMD_RANDOM_CHILD_SKILL_S, ret)
		return
	end
--[[
	if pkt.random_type==1 and item:get_free_flag() == 0 then -- 可以免费刷新，并且点击的是单次刷新按钮
		pkt.random_type = 3
	end
--]]
	local money_list = {}
	if pkt.random_type == 3 then -- 免费刷新
	elseif pkt.random_type == 1 then -- 单次刷新
		money_list[pkt.money_type] = 10  -- 扣除10元宝(礼券)
	elseif pkt.random_type == 2 then -- 批量刷新
		money_list[pkt.money_type] = 110 -- 扣除110元宝（礼券）
	else
		return -- 参数不合法
	end

	if pkt.random_type==1 or pkt.random_type==2 then
		if pkt.money_type~=3 and pkt.money_type~=4 then -- 金钱类型不是元宝或礼券
			return -- 金钱类型错误
		end
		-- 扣钱
		local ret = {}
		local e_code = pack_con:dec_money_l_inter_face(money_list, {['type']=MONEY_SOURCE.RANDOM_CHILD_SKILL})
		if e_code ~= 0 then
			ret.result = e_code
			g_cltsock_mgr:send_client(conn.char_id, CMD_RANDOM_CHILD_SKILL_S, ret) -- 扣金钱失败
			return
		end
	end
	
	if pkt.money_type == 4 then -- 礼券
		item:set_bind(0) -- 使用绑定
	end
	local ret = {}
	ret.list         = item:random_skill(pkt.random_type) -- 随机仙灵技能
	ret.random_count = item:get_random_count() -- 获取刷新次数
	if pkt.money_type == 3 then -- 元宝
		integral_func.add_bonus(conn.char_id, money_list[pkt.money_type], {['type']=MONEY_SOURCE.RANDOM_CHILD_SKILL}) -- 返利
	end

	local e_code, ctn = pack_con:get_bag(SYSTEM_BAG)
	local log_list = {}
	log_list[1] = ctn:get_update_log(ItemSyncFlag.ITEM_SYNC_UPDATE, pkt.slot)
	local src_log = {['type']=ITEM_SOURCE.USE_ITEM}
	pack_con:update_client(0, log_list, src_log)
	ret.result = e_code
	g_cltsock_mgr:send_client(conn.char_id, CMD_RANDOM_CHILD_SKILL_S, ret)
end

-- 选中仙灵随机技能 -- cailizhong
Clt_commands[1][CMD_RANDOM_USE_CHILD_SKILL_B] = 
function(conn, pkt)
	if not pkt or not pkt.index or not pkt.slot or pkt.index<0 or pkt.index>12 then
		return -- 参数错误
	end
	local player = g_obj_mgr:get_obj(conn.char_id)
	local pack_con = player:get_pack_con()
	local ret = {}
	-- 判断是否存在道具(血脉印记)
	local slot = pack_con:get_item_by_bag_slot(SYSTEM_BAG, pkt.slot) -- 获取格子物品
	local item = slot and slot.item
	if not item then
		ret.result = 43001 -- 找不到物品
		g_cltsock_mgr:send_client(conn.char_id, CMD_RANDOM_USE_CHILD_SKILL_S, ret)
		return
	end
	if item:get_m_class()~=1 or item:get_s_class()~=78 then -- 仙灵技能刷新道具，血脉印记
		ret.result = 43064 -- 物品不对
		g_cltsock_mgr:send_client(conn.char_id, CMD_RANDOM_USE_CHILD_SKILL_S, ret)
		return
	end
	local t_pkt = {}
	t_pkt.index = pkt.index
	local e_code = pack_con:use_item(player, slot, t_pkt)
	ret.result = e_code
	g_cltsock_mgr:send_client(conn.char_id, CMD_RANDOM_USE_CHILD_SKILL_S, ret)
end

-- 打开仙灵刷技能面板--每个物品每天由客户端请求一次--cailizhong添加
Clt_commands[1][CMD_OPEN_FRESH_CHILD_SKILL_B] = 
function(conn, pkt)
	if not pkt or not pkt.slot then
		return -- 参数错误
	end
	local player = g_obj_mgr:get_obj(conn.char_id)
	local pack_con = player:get_pack_con()
	local ret = {}
	-- 判断是否存在道具(血脉印记)
	local slot = pack_con:get_item_by_bag_slot(SYSTEM_BAG, pkt.slot) -- 获取格子物品
	local item = slot and slot.item
	if not item then
		ret.result = 43001 -- 找不到物品
		g_cltsock_mgr:send_client(conn.char_id, CMD_OPEN_FRESH_CHILD_SKILL_S, ret)
		return
	end
	if item:get_m_class()~=1 or item:get_s_class()~=78 then -- 仙灵技能刷新道具，血脉印记
		ret.result = 43064 -- 物品不对
		g_cltsock_mgr:send_client(conn.char_id, CMD_OPEN_FRESH_CHILD_SKILL_S, ret)
		return
	end
	local flag = item:get_free_flag() or 1 -- 获取物品能否免费刷新的标记,0可以，1不可以
	local e_code, ctn = pack_con:get_bag(SYSTEM_BAG)
	local log_list = {}
	log_list[1] = ctn:get_update_log(ItemSyncFlag.ITEM_SYNC_UPDATE, pkt.slot)
	local src_log = {['type']=ITEM_SOURCE.USE_ITEM}
	pack_con:update_client(0, log_list, src_log)
	ret.result = e_code
	ret.flag = flag
	g_cltsock_mgr:send_client(conn.char_id, CMD_OPEN_FRESH_CHILD_SKILL_S, ret)
end

--common服返回帮派仑库数据
--assert(Sv_commands[0][CMD_C2M_BAG_RES_C]==nil)	
Sv_commands[0][CMD_C2M_BAG_RES_C] =
	function(conn,char_id,pkt)
		g_cltsock_mgr:send_client(char_id, CMD_MAP_GET_PACK_DETAIL_S, pkt)
	end
	
--common服返回帮派仑库更新数据
--assert(Sv_commands[0][CMD_C2M_UPDATE_ITEM_C]==nil)
Sv_commands[0][CMD_C2M_UPDATE_ITEM_C] =
	function(conn,char_id,pkt)
		--g_cltsock_mgr:send_client(char_id, CMD_MAP_UPDATE_ITEM_S, pkt)
		
		local faction = nil 
		if pkt.faction_id then
			faction = g_faction_mgr:get_faction_by_fid(pkt.faction_id)
		else
			faction = g_faction_mgr:get_faction_by_cid(char_id)
		end
		if faction then
			faction:syn_send_all(pkt,CMD_MAP_UPDATE_ITEM_S)
		end
	end
--客户端请求帮派仓库操作记录信息
Clt_commands[1][CMD_GETRECORD_FACTION_WAREHOUSE_B] = 
	function(conn,pkt)
		g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id, CMD_M2C_BAG_OPERATE_REQ, pkt)
	end
--公共服返回帮派仓库操作记录信息
Sv_commands[0][CMD_C2M_BAG_OPERATE_RES] =
	function(conn,char_id,pkt)
		g_cltsock_mgr:send_client(char_id, CMD_GETRECORD_FACTION_WAREHOUSE_S, pkt)
	end
