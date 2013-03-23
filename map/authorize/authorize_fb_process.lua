--local debug_print = print
local debug_print = function() end

local authorize_loader = require("config.loader.authorize_loader")

--local src_log = {}
--src_log.type = ITEM_SOURCE.EMAIL

--打开进行委托面板
Clt_commands[1][CMD_C2W_AUTHORIZE_PRE_B] = 
	function(conn, pkt)
		local player = g_obj_mgr:get_obj(conn.char_id)
		if not player then return end
		local level = tonumber(player:get_level())
		if level < 30 then
			return 
		end
		g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id, CMD_C2W_AUTHORIZE_PRE_M, pkt)
	end

--打开我的委托
Clt_commands[1][CMD_C2W_AUTHORIZE_MINE_B] = 
	function(conn, pkt)
		local player = g_obj_mgr:get_obj(conn.char_id)
		if not player then return end
		local level = tonumber(player:get_level())
		if level < 30 then
			return 
		end
		g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id, CMD_C2W_AUTHORIZE_MINE_M, pkt)
	end

--打开所有委托界面
Clt_commands[1][CMD_C2W_AUTHORIZE_ALL_B] = 
	function(conn, pkt)
		local player = g_obj_mgr:get_obj(conn.char_id)
		if not player then return end
		local level = tonumber(player:get_level())
		if level < 30 then
			return 
		end

		g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id, CMD_C2W_AUTHORIZE_ALL_M, pkt)--CMD_CONSIGNMENT_INFOR_M,pkt)
	end

--领取奖励
Clt_commands[1][CMD_C2W_AUTHORIZE_MY_REWARD_B] = 
	function(conn, pkt)
		if not pkt or not pkt.authorize_id then return end
		local player = g_obj_mgr:get_obj(conn.char_id)
		if not player then return end

		g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id, CMD_C2W_AUTHORIZE_MY_REWARD_M, pkt)
	end

--进行委托
Clt_commands[1][CMD_C2W_AUTHORIZE_ENTRUST_B] = 
	function(conn, pkt)
		if not pkt or not pkt.authorize_id or not pkt.count or pkt.count < 1 then 
			return 
		end
		local char_id = conn.char_id
		local count = pkt.count
		local player = g_obj_mgr:get_obj(conn.char_id)
		if not player then return end
		local level = tonumber(player:get_level())
		if level < 30 then
			return 
		end
		local count_con  = player:get_copy_con()
		if not count_con then return end
		local pack_con = player:get_pack_con()
		if not pack_con then return end
		local lock = player:get_protect_lock()
		if not lock then return true end

		local authorize_id = pkt.authorize_id
		local scene_id = authorize_loader.get_authorize_scene(authorize_id)
		local contracts = authorize_loader.get_authorize_contract(authorize_id)
		local monster_id = authorize_loader.get_authorize_monster_id(pkt.authorize_id)
		if scene_id then
			if count_con:get_count_copy(scene_id) + pkt.count >  g_scene_config_mgr:get_copy_limit(scene_id) then
				local  e_pkt = {}
				e_pkt.result = 20528
				g_cltsock_mgr:send_client(conn.char_id, CMD_C2W_AUTHORIZE_ENTRUST_S, e_pkt)
				return 
			end
			local e_code , item = Item_factory.create(202001606041)
			if e_code~=0 then return e_code end
			if lock:check_lock_item(item) then return true end

			contracts = contracts * pkt.count
			if contracts > pack_con:get_all_item_count(202001606041) then
				local  e_pkt = {}
				e_pkt.result = 20529
				g_cltsock_mgr:send_client(conn.char_id, CMD_C2W_AUTHORIZE_ENTRUST_S, e_pkt)
				return 
			end

			local e_code = pack_con:del_item_by_item_id_inter_face(202001606041, contracts, {['type'] = ITEM_SOURCE.DO_AUTHORIZE}, 1)
			if e_code == 0 then
				local container = player:get_function_con()	
				for i = 1, pkt.count do
					container:finish_by_step(monster_id)
					count_con:add_count_copy(scene_id)
				end
				local r_con = player:get_retrieve_con()
				r_con:check_authorize(scene_id)
				 
				local str = ev.time .. " char_id:" ..char_id .. " authorize! authorize_id:" .. pkt.authorize_id .. " count:" .. count
				g_authorize_log:write(str)

				g_svsock_mgr:send_server_ex(COMMON_ID, char_id, CMD_C2W_AUTHORIZE_PRE_M, pkt)

				--直接领奖励
				local reward		= authorize_loader.get_authorize_reward(authorize_id)
				local add_gold 		= reward.gold or 0
				local add_gift_gold = reward.gift_gold or 0
				local add_gift_jade = reward.gift_jade or 0
				local add_jade 		= reward.jade or 0
				local add_exp		= reward.exp or 0

				add_gold 		= add_gold 	* count	
				add_gift_gold 	= add_gift_gold * count
				add_gift_jade 	= add_gift_jade * count	
				add_jade 		= add_jade * count	
				add_exp			= add_exp * count
				
				local money_list = {}
				money_list[MoneyType.GOLD] =  add_gold
				money_list[MoneyType.GIFT_GOLD] =  add_gift_gold
				money_list[MoneyType.GIFT_JADE] =  add_gift_jade
				money_list[MoneyType.JADE] =  add_jade
				pack_con:add_money_l(money_list, {['type'] = MONEY_SOURCE.AUTHORIZE_BONUS})
				
				--增加经验值
				if reward.exp ~= 0 then
					player:add_exp(add_exp)
				end

				local args = {}
				args.count = count
				g_event_mgr:notify_event(EVENT_SET.EVENT_AUTHORIZE, char_id, args)

				local str = ev.time .. " char_id:" ..char_id .. " get reward! authorize_id:" .. authorize_id .. " count:" .. count
				g_authorize_log:write(str)

				pkt.type = 1
				g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id, CMD_C2W_AUTHORIZE_ENTRUST_M, pkt)
			end
		end
	end
	
--领取委托任务
Clt_commands[1][CMD_C2W_AUTHORIZE_GET_MISSION_B] = 
	function(conn, pkt)	
		if not pkt or not pkt.authorize_id then return end
		local player = g_obj_mgr:get_obj(conn.char_id)
		if not player then return end
		local pack_con = player:get_pack_con()
		if not pack_con then return end
		local  pledge = authorize_loader.get_authorize_pledge(pkt.authorize_id)
		local money = pack_con:get_money()
		if money.gold < pledge then
			local s_pkt = {}
			s_pkt.result = 20530
			g_cltsock_mgr:send_client(conn.char_id, CMD_C2W_AUTHORIZE_GET_MISSION_S, s_pkt)
			return 
		end
		local quest, e_code = g_mission_mgr:build_quest(pkt.authorize_id)
		if E_SUCCESS ~= e_code then
			return
		end
		local e_error = quest:can_accept(conn.char_id)
		if E_SUCCESS ~= e_error then
			local s_pkt = {}
			s_pkt.result = e_error
			g_cltsock_mgr:send_client(conn.char_id, CMD_C2W_AUTHORIZE_GET_MISSION_S, s_pkt)
			return
		end
		
		g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id, CMD_C2W_AUTHORIZE_GET_MISSION_M, pkt)
	end

--领取所有委托奖励
Clt_commands[1][CMD_C2W_AUTHORIZE_GET_ALL_REWARD_B] = 
	function(conn, pkt)	
		local s_pkt = {}
		s_pkt.char_id = conn.char_id
		g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id, CMD_C2W_AUTHORIZE_GET_ALL_REWARD_M, s_pkt)
	end