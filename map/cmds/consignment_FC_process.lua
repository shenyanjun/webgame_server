--local debug_print = print
local debug_print = function() end

--local src_log = {}
--src_log.type = ITEM_SOURCE.EMAIL

--上架
Sv_commands[0][CMD_CONSIGNMENT_SALE_C] = 
	function(conn, char_id, pkt)
		if char_id == nil then return end
		if not pkt then return end
		local player = g_obj_mgr:get_obj(char_id)
		if not player then return end
		local ss_pkt = pkt.pkt
		local counts = pkt.counts
		local allow  = 1 + player:get_addition(HUMAN_ADDITION.consignment)

		if not counts or counts >= allow then
			local t_pkt = {}
			t_pkt.result = 20506
			g_cltsock_mgr:send_client(char_id, CMD_CONSIGNMENT_SALE_S, t_pkt)
			return 
		end
		if player:get_level() < 31 then
			local t_pkt = {}
			t_pkt.result = 20504
			g_cltsock_mgr:send_client(char_id, CMD_CONSIGNMENT_SALE_S, t_pkt)
			return 
		end
		 
		local pack_con = player:get_pack_con()
		local lock_con = player:get_protect_lock()
		local s_pkt = {}
		if pack_con then
			local slot	= ss_pkt.slot
			local count = ss_pkt.count
			--判断是否有物品并扣除
			if slot == -2 then 			--寄售元宝,腾讯版干掉
				return
				--if pack_con:check_money_lock(MoneyType.JADE) then		
					--return
				--end
				--local money = pack_con:get_money()
				--if money.jade < count then
					--local t_pkt = {}
					--t_pkt.result = 20500
					--g_cltsock_mgr:send_client(char_id, CMD_CONSIGNMENT_SALE_S, t_pkt)
					--return 
				--end
				--s_pkt.item_id = -2
				--pack_con:dec_money(MoneyType.JADE, count, {['type']=MONEY_SOURCE.CONSIGNMENT_DEC})

			elseif slot == -1 then 		--寄售铜币
				if pack_con:check_money_lock(MoneyType.GOLD) then		
					return
				end
				local money = pack_con:get_money()
				if money.gold < count then
					local t_pkt = {}
					t_pkt.result = 20501
					g_cltsock_mgr:send_client(char_id, CMD_CONSIGNMENT_SALE_S, t_pkt)
					return 
				end
				s_pkt.item_id = -1
				pack_con:dec_money(MoneyType.GOLD, count, {['type']=MONEY_SOURCE.CONSIGNMENT_DEC})

			elseif slot > 0  then 		--寄售背包物品
				if pack_con:check_item_lock_by_bag_slot(SYSTEM_BAG,slot) then return end
				local s_slot = pack_con:get_item_by_bag_slot(SYSTEM_BAG,slot)
				if not s_slot then
					local t_pkt = {}
					t_pkt.result = 20502
					g_cltsock_mgr:send_client(char_id, CMD_CONSIGNMENT_SALE_S, t_pkt)
					return 
				end 
				count = s_slot.number
				local item = s_slot.item
				if item:get_bind() == 0 then
					local t_pkt = {}
					t_pkt.result = 20503
					g_cltsock_mgr:send_client(char_id, CMD_CONSIGNMENT_SALE_S, t_pkt)
					return
				end
				s_pkt.item_id = item.proto.value.id
				s_pkt.item_DB = item:serialize_to_db()
				pack_con:del_item_by_bag_slot(SYSTEM_BAG,slot,nil,{['type']=ITEM_SOURCE.CONSIGNMENT_DEC})
			end
			--向common服发信息
			s_pkt.owner_id		= char_id
			s_pkt.owner_name	= player:get_name()
			s_pkt.count 		= count
			s_pkt.money_type	= ss_pkt.gold_flag
			s_pkt.money_count	= ss_pkt.gold_count
			s_pkt.allows		= allow
			s_pkt.server_id		= ss_pkt.server_id
			g_svsock_mgr:send_server_ex(COMMON_ID,char_id, CMD_CONSIGNMENT_SALE_REQ_M, s_pkt)
		end

	end

--请求列表
Sv_commands[0][CMD_CONSIGNMENT_SEARCH_C] = 
	function(conn, char_id, pkt)
		if char_id == nil then return end
		if not pkt then return end
		--print("CMD_CONSIGNMENT_SEARCH_C pkt = ",j_e(pkt))
		g_cltsock_mgr:send_client(char_id, CMD_CONSIGNMENT_SEARCH_S, pkt)
	end

--打开自己寄售
Sv_commands[0][CMD_CONSIGNMENT_INFOR_C] = 
	function(conn, char_id, pkt)
		if char_id == nil then return end
		if not pkt then return end
		local player = g_obj_mgr:get_obj(char_id)
		if not player then return end
		pkt.allow  = 1 + player:get_addition(HUMAN_ADDITION.consignment)
		g_cltsock_mgr:send_client(char_id, CMD_CONSIGNMENT_INFOR_S, pkt)
	end

--下架
Sv_commands[0][CMD_CONSIGNMENT_DELETE_C] = 
	function(conn, char_id, pkt)
		if char_id == nil then return end
		if not pkt then return end
		g_cltsock_mgr:send_client(char_id, CMD_CONSIGNMENT_DELETE_S, pkt)
	end

--购买
Sv_commands[0][CMD_CONSIGNMENT_BUY_C] = 
	function(conn, char_id, pkt)
		if char_id == nil then return end
		if not pkt then return end

		if pkt.result then
			g_cltsock_mgr:send_client(char_id, CMD_CONSIGNMENT_BUY_S, pkt)
			return
		end

		local player = g_obj_mgr:get_obj(pkt.char_id)
		if not player then return end

		local pack_con = player:get_pack_con()
		local lock_con = player:get_protect_lock()
		local s_pkt = {}
		if pack_con and pkt.money_type then
			local money = pack_con:get_money()

			if pkt.money_type == 1 then
				if pack_con:check_money_lock(MoneyType.GOLD) then		
					return
				end
				if money.gold < pkt.money_count then
					s_pkt.result = 20501
					g_cltsock_mgr:send_client(char_id, CMD_CONSIGNMENT_BUY_S, s_pkt)
					return 
				end
				pack_con:dec_money(MoneyType.GOLD, pkt.money_count, {['type']=MONEY_SOURCE.BUY_CONSIGNMENT_DEC})

			elseif pkt.money_type == 2 then

			end
			pkt.buyer_name = player:get_name()
			g_svsock_mgr:send_server_ex(COMMON_ID,char_id, CMD_CONSIGNMENT_BUY_REQ_M, pkt)
		end
		return
	end

	--CMD_C2M_FORBID_SAY
	Sv_commands[0][CMD_C2M_FORBID_SAY] = 
	function(conn,char_id,pkt)
		--print(j_e(pkt)) 禁言返回，暂时不做处理
	end