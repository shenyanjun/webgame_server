
local authorize_loader = require("config.loader.authorize_loader")
local misson_loader = require("mission_ex.mission_loader")
--require("mission_ex.quest.quest_authorize")

local debug_print = function() end

--打开进行委托界面
Sv_commands[0][CMD_C2W_AUTHORIZE_PRE_C] = 
	function(conn, char_id, pkt)
		if char_id == nil then return end
		if not pkt then return end
		local player = g_obj_mgr:get_obj(char_id)
		if not player then return end
		local count_con  = player:get_copy_con()
		if not count_con then return end

		local pk = {}
		for k , v in pairs(pkt) do
			pk[k] = {}
			pk[k].entrust = v
			local scene_id = authorize_loader.get_authorize_scene(k)
			if scene_id then
				local tmp_cnt = g_scene_config_mgr:get_copy_limit(scene_id) - count_con:get_count_copy(scene_id)
				if tmp_cnt < 0 then tmp_cnt = 0 end

				pk[k].surplus = tmp_cnt
			end
		end
		g_cltsock_mgr:send_client(char_id, CMD_C2W_AUTHORIZE_PRE_S, pk)
	end

--打开我的委托界面
Sv_commands[0][CMD_C2W_AUTHORIZE_MINE_C] = 
	function(conn, char_id, pkt)
		if char_id == nil then return end
		if not pkt then return end
		local player = g_obj_mgr:get_obj(char_id)
		if not player then return end
		local count_con  = player:get_copy_con()
		if not count_con then return end

		local pk = {}
		for k , v in pairs(pkt) do
			pk[k] = {}
			pk[k].entrust = pkt[k].entrust
			pk[k].total	  = pkt[k].total
			local scene_id = authorize_loader.get_authorize_scene(k)
			if scene_id then
				local tmp_cnt = g_scene_config_mgr:get_copy_limit(scene_id) - count_con:get_count_copy(scene_id)
				if tmp_cnt < 0 then tmp_cnt = 0 end

				pk[k].surplus = tmp_cnt
			end
		end

		g_cltsock_mgr:send_client(char_id, CMD_C2W_AUTHORIZE_MINE_S, pk)
	end

--打开所有委托
Sv_commands[0][CMD_C2W_AUTHORIZE_ALL_C] = 
	function(conn, char_id, pkt)
		if char_id == nil then return end
		if not pkt then return end
		local player = g_obj_mgr:get_obj(char_id)
		if not player then return end
		local container = player:get_copy_con()
		if not container then return end

		local s_pkt = {}
		for k, v in pairs(pkt) do
			local scene_id = authorize_loader.get_authorize_scene(k)
			s_pkt[k] = {}
			s_pkt[k].can_accept   = v

			local tmp_cnt = g_scene_config_mgr:get_copy_limit(scene_id) - container:get_count_copy(scene_id)
			if tmp_cnt < 0 then tmp_cnt = 0 end
			s_pkt[k].can_complete = tmp_cnt
		end

		g_cltsock_mgr:send_client(char_id, CMD_C2W_AUTHORIZE_ALL_S, s_pkt)
	end

--领取奖励
Sv_commands[0][CMD_C2W_AUTHORIZE_MY_REWARD_C] = 
	function(conn, char_id, pkt)
		if char_id == nil then return end
		if not pkt then return end
		local player = g_obj_mgr:get_obj(char_id)
		if not player then return end
		local pack_con = player:get_pack_con()
		if not pack_con then return end
		if pkt.result ~= 0 then
			g_cltsock_mgr:send_client(char_id, CMD_C2W_AUTHORIZE_MY_REWARD_S, pkt)
			return
		end

		local pk = {}
		local count = pkt.count

		local reward		= authorize_loader.get_authorize_reward(pkt.authorize_id)
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

		local str = ev.time .. " char_id:" ..char_id .. " get reward! authorize_id:" .. pkt.authorize_id .. " count:" .. count
		g_authorize_log:write(str)

		g_svsock_mgr:send_server_ex(COMMON_ID,char_id, CMD_C2W_AUTHORIZE_MINE_M, pkt)
	end

--进行委托
Sv_commands[0][CMD_C2W_AUTHORIZE_ENTRUST_C] = 
	function(conn, char_id, pkt)
		if char_id == nil then return end
		if not pkt then return end
		local player = g_obj_mgr:get_obj(char_id)
		if not player then return end

		if pkt.result ~= 0 then
			g_cltsock_mgr:send_client(char_id, CMD_C2W_AUTHORIZE_MY_REWARD_S, pkt)
			return
		end
	end

--领取委托任务
Sv_commands[0][CMD_C2W_AUTHORIZE_GET_MISSION_C] = 
	function(conn, char_id, pkt)
		if char_id == nil then return end
		if not pkt then return end
		if pkt.result ~= 0 then
			g_cltsock_mgr:send_client(char_id, CMD_C2W_AUTHORIZE_GET_MISSION_S, pkt)
			return
		end
		local player = g_obj_mgr:get_obj(char_id)
		if not player then 
			g_svsock_mgr:send_server_ex(COMMON_ID,char_id, CMD_C2W_AUTHORIZE_GET_MISSION2_M, pkt)
			return 
		end

		local mission_con = player:get_mission_mgr()
		if not mission_con then return end
		local pack_con = player:get_pack_con()
		if not pack_con then return end

		local meta = misson_loader.get_meta(pkt.authorize_id)
		if meta then
			local quest = Quest_authorize(meta,1)
			local e_error = quest:can_accept(char_id)
			if e_error ~= E_SUCCESS then
				return
			end
			local e_code = mission_con:accept_and_record(quest,1)
			if E_SUCCESS ~= e_code then
				NpcContainerMgr:SendError(char_id, e_code)
				g_svsock_mgr:send_server_ex(COMMON_ID,char_id, CMD_C2W_AUTHORIZE_GET_MISSION2_M, pkt)
				return 
			end
			local pledge = authorize_loader.get_authorize_pledge(pkt.authorize_id)
			local money = pack_con:get_money()
			if pledge > money.gold then
				pledge = money.gold
			end
			if pledge > 0 and pack_con:check_money_lock(MoneyType.GOLD) then		
				return
			end
			pack_con:dec_money(MoneyType.GOLD, pledge, {['type']=MONEY_SOURCE.ACCEPT_AUTHORIZE})

			local str = ev.time .. " char_id:" ..char_id .. " get authorize mission! authorize_id:" .. pkt.authorize_id
			g_authorize_log:write(str)

			local t_pkt = {}
			g_svsock_mgr:send_server_ex(COMMON_ID,char_id, CMD_C2W_AUTHORIZE_ALL_M, t_pkt)
		end
	end

--领取所有奖励
Sv_commands[0][CMD_C2W_AUTHORIZE_GET_ALL_REWARD_C] = 
	function(conn, char_id, pkt)
		if not pkt then return end
		local s_pkt = {}

		if pkt.result ~= 0 then 
			s_pkt.result = pkt.result
			g_cltsock_mgr:send_client(char_id, CMD_C2W_AUTHORIZE_GET_ALL_REWARD_S, s_pkt)
			return
		end

		local player = g_obj_mgr:get_obj(char_id)
		if not player then return end
		local pack_con = player:get_pack_con()
		if not pack_con then return end

		local flags = false

		for k, v in pairs(pkt) do	
			if k ~= 'result' then
				local count = v
				local authorize_id = k

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

				local str = ev.time .. " char_id:" ..char_id .. " get reward! authorize_id:" .. authorize_id .. " count:" .. count
				g_authorize_log:write(str)
				flags = true
			end
		end
		if flags then
			s_pkt.result = 0
		else
			s_pkt.result = 20524
		end
		g_cltsock_mgr:send_client(char_id, CMD_C2W_AUTHORIZE_GET_ALL_REWARD_S, s_pkt)
	end

