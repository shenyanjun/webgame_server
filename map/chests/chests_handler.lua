

local gbk_utf8 = function(val) return val end
local debug_print = print
--local debug_print = function() end

local TM_CHEST = 1.0
local pre_time = {}
local proto_mgr = require("item.proto_mgr")
local _open_chests = require("chests.chests_analytical")

local say_6_l = {}
--say_6_l[1] = gbk_utf8("恭喜")
--say_6_l[2] = gbk_utf8("降妖")
--say_6_l[3] = gbk_utf8("获得了")
say_6_l[1] = f_get_string(700)
say_6_l[2] = f_get_string(701)
say_6_l[3] = f_get_string(301)

local sysbd_format = function(format_l, tail_str)
	local say_list = {}
	f_construct_content(say_list, say_6_l[1], 18)
	f_construct_content(say_list, format_l[1], 54)
	f_construct_content(say_list, say_6_l[2], 18)
	f_construct_content(say_list, format_l[2], 18)
	f_construct_content(say_list, say_6_l[3], 18)
	f_construct_content(say_list, tail_str, 18)
	return say_list
end

--local radio_chests = function(char_id, gift_list, k_type)
	--local radio_spkt = {}
	--local player= g_obj_mgr:get_obj(char_id)
	--local player_name = player:get_name()																	
	--local chests_name = _open_chests.get_open_chests_param_name(k_type) 		            	
	--local str_news = {}
	--local props_id = {}
	--local radio_num = 1
--
	--for k, v in pairs(gift_list) do
		--local id = v[1]
		--local e_code, proto = proto_mgr.get_proto(id)
		--if e_code ~= 0 then
			--local list = {}
			--list.player_name = player_name
			--list.char_id = char_id
			--list.chests_name = chests_name
			--list.props_name = gbk_utf8(proto.value.name)
			--list.props_id = id
			--list.time = ev.time
			--table.insert(radio_spkt, list)
			--if props_id[id] == nil then
			--props_id[id] = id
			--str_news[radio_num] = gbk_utf8(proto.value.name)
			--radio_num = radio_num + 1
		--end	
	--end	
--
	--local str_news_result = table.concat(str_news, ",")
--
	--g_svsock_mgr:send_server_ex(WORLD_ID, 0, CMD_M2M_CHESTS_TO_EMAIL_S, radio_spkt)
--
	--local sys_l = {}
	--sys_l[1] = player_name
	--sys_l[2] = chests_name
	--local str_json = sysbd_format(sys_l, gbk_utf8(str_news_result))
	--f_cmd_sysbd(str_json)
--end

--列举玩家抽到的物品或道具
Clt_commands[1][CMD_MAP_CRATES_QXFJ_C] =
	function(conn, pkt)
		if not pkt then return end

		local s_pkt = {}
		s_pkt.result = 0
		s_pkt.list = {}

		if pre_time[conn.char_id] ~= nil then
			if (ev.now - pre_time[conn.char_id]) < TM_CHEST then
				s_pkt.result = 20314				
				g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_CRATES_QXFJ_S, s_pkt)
				return
			end
		end
		pre_time[conn.char_id] = ev.now

		local player = g_obj_mgr:get_obj(conn.char_id)
		local pack_con = player:get_pack_con()
		local free_count = pack_con:get_free_chest_slot_count()
		local chests_count = _open_chests.get_open_chests_time(pkt.k_type, pkt.money_type)
		if free_count < chests_count then
			s_pkt.result = 43354				
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_CRATES_QXFJ_S, s_pkt)
			return
		end
		
		local chests_obj = g_chests_mgr:get_chests(conn.char_id)
						
		local is_enough_money = chests_obj:enough_money_and_dec_money(conn.char_id, pkt.k_type, pkt.money_type)
		if is_enough_money ~= 0 then   			
			s_pkt.result = is_enough_money
			g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_CRATES_QXFJL_S, s_pkt)
			return
		end

		local gift_list, gift_list_radio = chests_obj:get_random_list(conn.char_id, pkt.k_type, pkt.money_type)
		s_pkt.list = chests_obj:construct(gift_list)

		local ret_code = pack_con:add_chest_item_list(s_pkt.list)
		if ret_code ~= 0 then
			s_pkt.result = ret_code				
			local ret = chests_obj:give_back_money(coon.char_id, pkt.k_type, pkt.money_type)
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_CRATES_QXFJ_S, s_pkt)
			return
		end

		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_CRATES_QXFJ_S, s_pkt)
		if gift_list_radio ~= nil then
			radio_chests(conn.char_id, gift_list_radio, pkt.k_type)
		end
	end
