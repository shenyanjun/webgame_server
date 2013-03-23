--local debug_print = print
local debug_print = function () end

local advanced_loader = require("npc.config.advanced_loader")

--装备进阶
Clt_commands[1][CMD_MAP_EQUIP_ADVANCED_B] =
	function(conn, pkt)			--pkt.bind:绑定的数量;pkt.nobind:非绑数量
		if not pkt.slot or not pkt.bag or not pkt.bind or not pkt.nobind then return end

		local player = g_obj_mgr:get_obj(conn.char_id)
		local pack_con = player:get_pack_con()
		if pack_con:check_money_lock(MoneyType.GOLD) or pack_con:check_money_lock(MoneyType.GIFT_GOLD) then return end --上锁
		if pack_con:check_item_lock_by_bag_slot(pkt.bag, pkt.slot) then return end --上锁
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

		--过滤材料列表
		local bind_flag = 1
		--for k, v in ipairs(pkt.material_l) do
			--local m_slot = pack_con:get_item_by_bag_slot(SYSTEM_BAG, v)
			--if not m_slot then
				--NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_NOT_FIND_ITEM)
				--return
			--end
--
			--local m_item_id = m_slot.item_id
			--local m_bind = m_item_id % 2
			--local need_id = m_item_id + 1 - m_bind
			--if m_bind == 0 then
				--bind_flag = 0
			--end
			----只能选择都绑或都不绑
			--if not material_l[need_id] then
				--material_l[need_id] = {}
				--material_l[need_id].bind = m_bind
				--material_l[need_id].list = {}
			--else
				--if m_bind ~= material_l[need_id].bind then
					--NpcContainerMgr:SendError(conn.char_id, 201010)
					--return
				--end 
			--end
			--local tmp_t = {}
			--tmp_t.slot = v
			--tmp_t.num = m_slot.number
			--table.insert(material_l[need_id].list, tmp_t)
		--end

		--if not bind_flag then return end

		local advanced_info = advanced_loader.get_advanced_info(equip.item_id)
		if not advanced_info then
			NpcContainerMgr:SendError(conn.char_id, 201011)
			return
		end

		--检查材料
		local slot_l ={}
		local material_id 
		local need_cnt 
		for k, v in pairs(advanced_info.material_l) do
			--local m_id = k - 1 + bind_flag
			--if not material_l[k] then
				--NpcContainerMgr:SendError(conn.char_id, 201010)
				--return
			--end
			--local cnt = v
			--for kk, vv in ipairs(material_l[k].list) do
				--if cnt > 0 then
					--local tmp_t = {}
					--tmp_t.slot = vv.slot
					--if cnt <= vv.num then
						--tmp_t.num = cnt
						--table.insert(slot_l, tmp_t)
						--cnt = 0
						--break
					--else
						--tmp_t.num = vv.num
						--table.insert(slot_l, tmp_t)
						--cnt = cnt - vv.num
					--end
				--else
					--break
				--end
			--end
--
			--if cnt > 0 then
				--NpcContainerMgr:SendError(conn.char_id, 201010)
				--return
			--end
			material_id = k
			need_cnt = v
			if pkt.bind + pkt.nobind ~= v or 
				pack_con:get_item_count(material_id) < pkt.nobind or
				pack_con:get_item_count(material_id - 1) < pkt.bind	then
				NpcContainerMgr:SendError(conn.char_id, 201017)
				return
			end

			break
		end

		if not material_id then
			return
		end

		--随机以确定更新ID
		local gain_equip
		if advanced_info.rate >= crypto.random(1,101) then
			gain_equip = advanced_info.success
		else
			gain_equip = advanced_info.fail
		end
		if bind_flag == 0 or equip.item:get_bind() == 0 or pkt.bind > 0 then
			gain_equip = gain_equip - 1
		end
		
		local error,des_equip = Item_factory.create(gain_equip)
		if error ~= 0 then
			NpcContainerMgr:SendError(conn.char_id, error)
			return 
		end
		local equipment = equip_transfer_attr(equip.item, des_equip)
		local new_n = equipment:get_name()

		--检查是否能加
		local tmp_item_l ={}
		tmp_item_l[1] = {}
		tmp_item_l[1].type = 2
		tmp_item_l[1].number = 1
		tmp_item_l[1].item = equipment
		local e_code  = pack_con:check_add_item_l_inter_face(tmp_item_l, SYSTEM_BAG)
		if e_code ~= 0 then
			NpcContainerMgr:SendError(conn.char_id, e_code)
			return
		end

		--扣钱
		local money_list = {}
		money_list[MoneyType.GIFT_GOLD] = advanced_info.gold
		e_code = pack_con:dec_money_l_inter_face(money_list, {['type'] = MONEY_SOURCE.EQUIP_ADVANCED}, 1)
		if e_code ~= 0 then
			NpcContainerMgr:SendError(conn.char_id, e_code)
			return
		end
		--扣材料
		if pkt.nobind > 0 then
			pack_con:del_item_by_item_id( material_id, pkt.nobind, {['type']=ITEM_SOURCE.EQUIP_ADVANCED})
		end
		if pkt.bind > 0 then
			bind_flag = 0
			pack_con:del_item_by_item_id( material_id - 1, pkt.bind, {['type']=ITEM_SOURCE.EQUIP_ADVANCED})
		end

		--扣装备
		local old_n = equip.item:get_name()
		local old_colre = equip.item:get_color()
		pack_con:del_item_by_bag_slot(pkt.bag, pkt.slot, 1, {['type']=ITEM_SOURCE.EQUIP_ADVANCED})

		--加装备
		error = pack_con:add_by_item(equipment, {['type']=ITEM_SOURCE.EQUIP_ADVANCED})
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_EQUIP_ADVANCED_S, {["result"] = error})
		
		--广播
		local sys_l = {}
		sys_l[1] = player:get_name()
		sys_l[2] = old_n
		sys_l[3] = new_n

		local color_l = {}
		color_l[1] = old_colre
		color_l[2] = equipment:get_color()
		local str_json = f_get_sysbd_format(10018, sys_l, color_l)
		f_cmd_sysbd(str_json)

		--更新人物
		if pkt.bag == EQUIPMENT_BAG then
			player:on_dress_update(1)
		end
	end


