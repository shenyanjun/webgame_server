--local debug_print = print
local debug_print = function() end

--登陆map取快捷键
Clt_commands[1][CMD_MAP_GET_ACTION_BTN_C] = 
	function(conn, pkt)
	    debug_print("CMD_MAP_GET_ACTION_BTN_C")
	    local player = g_obj_mgr:get_obj(conn.char_id)
		if not player then return end
		local action_con = player:get_action_con()
		if not action_con then return end
		local action_btns_list = action_con:get_action_button()

		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_GET_ACTION_BTN_S, action_btns_list)
		
		--发送系统设置
		local ret = {}
		ret.setting = player:get_setting()
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_SYS_SETTING_S, ret)

		--发送挂机参数设置
		local hang = player:get_hang()
		if hang == "{}" then
			hang = ""
		end

		--print(gbk_utf8(">>>>>>>>>>>>>>>>发送挂机参数设置"), hang, type(hang))
		local s_pkt = {}
		s_pkt.setting = hang or ""
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_HANG_SETTING_S, s_pkt)
	end

--设置快捷键
Clt_commands[1][CMD_MAP_ACTION_SET_C] = 
	function(conn, pkt)
		--print("CMD_MAP_ACTION_SET_C", pkt.slot, pkt.type,	pkt.id,	pkt.src_bag, pkt.src_slot)
		if not pkt.slot or not pkt.type or not pkt.id then return end
		
		--银行物品不能拖到快捷拦
		--if pkt.src_bag and pkt.src_bag >= BANK_BAG then return end

		local player = g_obj_mgr:get_obj(conn.char_id)
		local action_con = player:get_action_con()
		if action_con then
			action_con:set_action_button(tonumber(pkt.type), tonumber(pkt.slot), tonumber(pkt.id), pkt.src_bag, pkt.src_slot)
		end
	end

--快捷拦使用物品
Clt_commands[1][CMD_MAP_ACTION_USE_ITEM_C] = 
	function(conn, pkt)
		--debug_print("CMD_MAP_ACTION_USE_ITEM_C", j_e(pkt))
		if not pkt.obj_id or not pkt.slot then return end

		local player = g_obj_mgr:get_obj(conn.char_id)
		local action_con = player:get_action_con()
		if action_con then
			action_con:use_action_item(pkt.obj_id, tonumber(pkt.slot))
		end
	end


--快捷拦换位
Clt_commands[1][CMD_MAP_ACTION_SWAP_C] = 
	function(conn, pkt)
		--debug_print("CMD_MAP_ACTION_SWAP_C", j_e(pkt))
		if not pkt.src_slot or not pkt.dst_slot then return end
		local player = g_obj_mgr:get_obj(conn.char_id)
		local action_con = player:get_action_con()
		if action_con then
			action_con:swap_action_button(tonumber(pkt.src_slot), tonumber(pkt.dst_slot))
		end
	end

--删除快捷键
Clt_commands[1][CMD_MAP_ACTION_DESTROY_C] = 
	function(conn, pkt)
		--debug_print("CMD_MAP_ACTION_DESTROY_C", j_e(pkt))
		if not pkt.slot then return end
		local player = g_obj_mgr:get_obj(conn.char_id)
		local action_con = player:get_action_con()
		if action_con then
			action_con:destroy_action_button(tonumber(pkt.slot))
		end
	end

--系统设置参数
Clt_commands[1][CMD_MAP_SYS_SETTING_C] = 
	function(conn, pkt)
		local player = g_obj_mgr:get_obj(conn.char_id)
		player:set_setting(pkt.setting)
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_SYS_SETTING_S, pkt)
	end

--挂机参数设置
Clt_commands[1][CMD_MAP_HANG_SETTING_C] = 
	function(conn, pkt)
		--print("CMD_MAP_HANG_SETTING_C", pkt.setting)
		--print(gbk_utf8("挂机参数设置"), type(pkt.setting), j_e(pkt))

		if not pkt or not pkt.setting then return end
		local hang = tostring(pkt.setting)
		local player = g_obj_mgr:get_obj(conn.char_id)
		player:set_hang(hang)

		local s_pkt = {}
		s_pkt.result = 0
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_HANG_SETTING_S, s_pkt)
	end

--vip挂机时间
Clt_commands[1][CMD_MAP_VIP_HANG_C] = 
	function(conn, pkt)
		if not pkt or not conn.char_id then return end

		local player = g_obj_mgr:get_obj(conn.char_id)

		local s_pkt = {}
		s_pkt.result = 0
		s_pkt.time	 = player:get_vip_bang_time()
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_VIP_HANG_S, s_pkt)
	end
