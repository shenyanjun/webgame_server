--local debug_print = print
local debug_print = function() end

TY_COMMON =0 --文本邮件
TY_ANNEX = 1 --附件邮件
TY_GOLD	= 2 --邮寄金币

local src_log = {}
src_log.type = ITEM_SOURCE.EMAIL

Sv_commands[0][CMD_C2M_QUERY_ITEM_REQ] = 
	function(conn, char_id, pkt)
		if char_id == nil then return end
		if not pkt then return end
		
		local player = g_obj_mgr:get_obj(char_id)
		if not player then return end
		local pack_con = player:get_pack_con()
		if pack_con then
			if pack_con:check_money_lock(MoneyType.GOLD) then				return			end

			local s_pkt = {}
			s_pkt.item_list = {}
			s_pkt.result = 0
			
			if pkt.item_list ~=nil and Json.Encode(pkt.item_list) ~="[]" then	
				local money = pack_con:get_money()
				if money.gold < 10 then
					s_pkt.result = 200008
				end
				local item_l = pack_con:get_item_by_uuid(pkt.item_list[1].id)
				if not item_l or item_l.number < pkt.item_list[1].number then
					s_pkt.result = 43001
				else 
					s_pkt.item_list ={}
					s_pkt.item_list.item_id = item_l.item_id
					s_pkt.item_list.number = item_l.number
					s_pkt.item_list.item = item_l.item:serialize_to_db()
				end
				if pack_con:check_item_lock_by_item_uuid(SYSTEM_BAG,pkt.item_list[1].id) then
					return
				end	
			end

			if s_pkt.result == 0 then
				if pkt.mail_type == TY_GOLD then
					local money = pack_con:get_money()
					if money.gold < pkt.gold then
						s_pkt.result = 200008
					end
					if pkt.item_list ~=nil and Json.Encode(pkt.item_list) ~="[]"  and money.gold < pkt.gold + 10 then
						s_pkt.result = 200008		
					end
				end
			end

			if s_pkt.result == 0 then
				if pkt.item_list ~=nil and Json.Encode(pkt.item_list)~="[]"then
					pack_con:dec_money(MoneyType.GOLD, 10, {['type']=MONEY_SOURCE.PAY_SEND_TY_ANNEX})
					pack_con:del_item_by_uuid(SYSTEM_BAG,pkt.item_list[1].id,pkt.item_list[1].number, {['type']=ITEM_SOURCE.PAY_EMAIL})
				end
				if pkt.mail_type == TY_GOLD then
					pack_con:dec_money(MoneyType.GOLD, pkt.gold, {['type']=MONEY_SOURCE.SEND_TY_GOLD})
				end
			end
			g_svsock_mgr:send_server_ex(WORLD_ID, char_id, CMD_M2C_QUERY_ITEM_REP, s_pkt)
		end
	end

Sv_commands[0][CMD_C2M_ADD_ATTACHMENT_REQ] = 
	function(conn, char_id, pkt)
		--debug_print("CMD_C2M_ADD_ATTACHMENT_REQ", j_e(pkt))
		if char_id == nil then return end
		if not pkt and not pkt.item_list then return end

		local player = g_obj_mgr:get_obj(char_id)
		if not player then return end
		
		local pack_con = player:get_pack_con()
		local s_pkt = {}
		s_pkt.result = 0

		--金币是否足够
		if pkt.mail_type == TY_ANNEX then
			if pkt.gold >0 then
				if pack_con:check_money_lock(MoneyType.GOLD) then					return				end
			end
			if pack_con:get_money().gold < pkt.gold then
				s_pkt.result = 200008
			end
		end

		if s_pkt.result == 0 then
		 	if pkt.item_list[1] == nil then
				if pkt.mail_type == TY_GOLD then
					pack_con:add_money(MoneyType.GOLD, pkt.gold, {['type']=MONEY_SOURCE.RECV_TY_GOLD})
					--local str = "char_id:" .. char_id .." 提取了" .. pkt.gold .. " 铜币"
					--g_email_log:write(str)
				end
			else
				--背包是否已满
				if pack_con:get_bag_free_slot_cnt() <= 0 then
					s_pkt.result = 43004
					s_pkt._evt = pkt._evt
					g_svsock_mgr:send_server_ex(WORLD_ID, char_id, CMD_M2C_ADD_ATTACHMENT_REP, s_pkt)
					return
				end

				local errcode, item = Item_factory.clone(pkt.item_list[1].item_id,pkt.item_list[1].item)
				local attach = {}
				attach[1] = {}
				attach[1].type = 2
				attach[1].number = pkt.item_list[1].count
				attach[1].item = item

				if pack_con:add_item_l(attach,src_log) == 0 then
					if pkt.mail_type == TY_ANNEX then
						pack_con:dec_money(MoneyType.GOLD, pkt.gold, {['type']=MONEY_SOURCE.PAY_TY_ANNEX})
						--local str = "char_id:" .. char_id .." 花费" .. pkt.gold .. " 获得物品：".. Json.Encode(pkt.item_list[1].item) 
						--g_email_log:write(str)
					elseif pkt.mail_type == TY_GOLD then
						pack_con:add_money(MoneyType.GOLD, pkt.gold, {['type']=MONEY_SOURCE.RECV_TY_GOLD})
						--local str = "char_id:" .. char_id .." 提取了" .. pkt.gold .. " 同时获得物品：".. Json.Encode(pkt.item_list[1].item)
						--g_email_log:write(str)
					end
					s_pkt.result = 0
				end
			end
		end
		s_pkt._evt = pkt._evt
		g_svsock_mgr:send_server_ex(WORLD_ID, char_id, CMD_M2C_ADD_ATTACHMENT_REP, s_pkt)

		--local serialized_item_list = f_serialize_itemlist(pkt.item_list[1].item)
		--local str ="char_id:" .. char_id .. " email_item:" .. Json.Encode(pkt.item_list) .. " del_gold:" .. pkt.gold
		--g_email_log:write(str)
	end

	Sv_commands[0][CMD_C2M_ADD_ATTACHMENT_L_REQ] = 
	function(conn, char_id, pkt)
		debug_print("CMD_C2M_ADD_ATTACHMENT_L_REQ", j_e(pkt))
		if char_id == nil then return end
		if not pkt and not pkt.item_list then return end

		local player = g_obj_mgr:get_obj(char_id)
		if not player then return end
		
		local pack_con = player:get_pack_con()
		local s_pkt = {}
		s_pkt.result = 0
		s_pkt.email_id_l = pkt.email_id_l
		s_pkt._evt = pkt._evt
		s_pkt.char_id = char_id
		local flags = false
		if pkt.item_list[1] then
			local item_l = {}
			for k, v in ipairs(pkt.item_list) do
				local errcode, item = Item_factory.clone(v.item_id, v.item)
				if errcode ~= 0 then return end

				local attach = {}
				attach = {}
				attach.type = 2
				attach.number = v.count
				attach.item = item
				table.insert(item_l, attach)
			end

			--背包是否已满
			s_pkt.result = pack_con:check_add_item_l_inter_face(item_l)
			if s_pkt.result ~= 0 then
				g_svsock_mgr:send_server_ex(WORLD_ID, char_id, CMD_M2C_ADD_ATTACHMENT_L_REP, s_pkt)
				return
			end

			if pack_con:add_item_l(item_l, src_log) == 0 then
				--local str = "char_id:" .. char_id .." 获得物品：".. Json.Encode(pkt.item_list)
				--g_email_log:write(str)
				s_pkt.result = 0
				flags = true
			end
		end

		if pkt.gold > 0 then
			pack_con:add_money(MoneyType.GOLD, pkt.gold, {['type']=MONEY_SOURCE.RECV_TY_GOLD})
			--local str = "char_id:" .. char_id .." 提取了" .. pkt.gold .. " 铜币"
			--g_email_log:write(str)
			flags = true
		end
		
		if  s_pkt.result == 0 and not flags then
			 s_pkt.result = 43095
		end
		g_svsock_mgr:send_server_ex(WORLD_ID, char_id, CMD_M2C_ADD_ATTACHMENT_L_REP, s_pkt)
		--local serialized_item_list = f_serialize_itemlist(pkt.item_list[1].item)
	end
