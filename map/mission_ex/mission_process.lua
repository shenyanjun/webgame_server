local misson_loader = require("mission_ex.mission_loader")
local escort_config = require("config.escort_config")
local integral_func=require("mall.integral_func")
local _sf = require("scene_ex.scene_process")

--镖局坐标
local location = {64, 65} 

--获取任务列表
Clt_commands[1][CMD_NPC_GET_QUEST_LIST_C] =
function(conn, pkt)
	local player = g_obj_mgr:get_obj(conn.char_id)
	if player then
		local mission_con = player:get_mission_mgr()
		if not mission_con then return end
		
		mission_con:notify_all_accpet_quest()
		mission_con:notity_available_quest()
	end
end
	
--接受任务
Clt_commands[1][CMD_MISSION_ACCEPT_C] = 
function(conn, pkt)
	local player = g_obj_mgr:get_obj(conn.char_id)
	if player then
		local mission_con = player:get_mission_mgr()
		if not mission_con then return end
		--pkt.quest_id = 'visit_1028'
		local e_code = mission_con:accept_quest(pkt.quest_id)
		if E_SUCCESS ~= e_code then
			NpcContainerMgr:SendError(conn.char_id, e_code)
		end
	end
end

--完成任务
Clt_commands[1][CMD_MISSION_COMPLETE_C] =
function(conn, pkt)
	local player = g_obj_mgr:get_obj(conn.char_id)
	if player then
		local mission_con = player:get_mission_mgr()
		if not mission_con then return end
		local e_code = mission_con:complete_quest(pkt.quest_id, pkt.selected)
		if e_code and E_SUCCESS ~= e_code then
			NpcContainerMgr:SendError(conn.char_id, e_code)
		end
	end
end

--客户端通知任务完成
Clt_commands[1][CMD_QUEST_GUIDE_COMPLETE_C] = 
function(conn, pkt)
	local args = {}
	args.id = pkt.id
	args.type = pkt.type
	g_event_mgr:notify_event(EVENT_SET.EVENT_CLIENT, conn.char_id, args)
end

--放弃任务
Clt_commands[1][CMD_MISSION_REMOVE_C] = 
function(conn, pkt)
	local player = g_obj_mgr:get_obj(conn.char_id)
	if player then
		local mission_con = player:get_mission_mgr()
		if not mission_con then 
			return
		end
		local e_code = mission_con:delete_quest(pkt.quest_id)
	end
end

--任务传送
Clt_commands[1][CMD_MISSION_TRANS_C] = 
function(conn, pkt)
	local player = g_obj_mgr:get_obj(conn.char_id)
	if not player then return end
	local mission_con = player:get_mission_mgr()
	if not mission_con then return end
	if not mission_con:get_accept_mission(pkt.quest_id) then return end

	local meta = misson_loader.get_meta(pkt.quest_id)
	if not meta then return end
	local target_scene = meta.precondition.target_scene
	if not target_scene then  return end	
	local e_code = f_scene_carry(conn.char_id, target_scene.id, {target_scene.x, target_scene.y})
end
	
--刷新任务状态
Clt_commands[1][CMD_GET_QUEST_STATUS_C] =
function(conn, pkt)
	local player = g_obj_mgr:get_obj(conn.char_id)
	if not player then
		return 
	end
	local con = player:get_mission_mgr()
	con:notity_update_quest(pkt.quest_id, false)
end

local function notify_accept_escort(player, type)
	local char_id = player:get_id()
	local s_pkt = {}
	s_pkt.type = type
	s_pkt.param = {}
	local quest = g_mission_mgr:get_wait_accept_escort(char_id, type)
	if quest then	
		s_pkt.param[1] = quest:get_id()
		s_pkt.param[2] = (player:get_mission_mgr():get_param(PARAM_TYPE_ESCORT)).color
		s_pkt.param[3] = MISSION_STATUS_AVAILABLE
		s_pkt.param[4] = quest:get_reward(player)
		
	end
	g_cltsock_mgr:send_client(char_id, CMD_GET_QUEST_INFO_S, s_pkt)
end

 --刷新任务品质
Clt_commands[1][CMD_CHANGE_COLOR_C] =
function(conn, pkt)
	if not pkt.bag or not pkt.slot or not pkt.type then
		return
	end
	
	local player = g_obj_mgr:get_obj(conn.char_id)
	if 0 ~= player:get_escort_status() then
		NpcContainerMgr:SendError(conn.char_id, 200093)
		return
	end
	
	local quest = g_mission_mgr:get_wait_accept_escort(conn.char_id, pkt.type)
	if not quest then
		NpcContainerMgr:SendError(conn.char_id, 200094 + pkt.type)
		return
	end
	
	local pack_con = player:get_pack_con()
	local equip = pack_con:get_item_by_bag_slot(pkt.bag, pkt.slot)
	if not equip or not equip.item.is_equipment then
		NpcContainerMgr:SendError(conn.char_id, 200092)
		return
	end
	
	if equip.item:get_level() < 30 then
		NpcContainerMgr:SendError(conn.char_id, 200094)
		return
	end
	
	local color = equip.item:get_color()
	if not color or 5 == color then
		NpcContainerMgr:SendError(conn.char_id, 200092)
		return
	end
	
	local mission_con = player:get_mission_mgr()
	local value = mission_con:get_param(PARAM_TYPE_ESCORT)
	if value then
		local today = f_get_today()
		if value.time >= today and color <= value.color then	
			NpcContainerMgr:SendError(conn.char_id, 200091)
			return
		end
	else
		value = {}
	end
	if pack_con:check_item_lock_by_bag_slot(pkt.bag, pkt.slot) then
		return
	end
	if 0 ~= pack_con:del_item_by_bag_slot(pkt.bag, pkt.slot, nil, {['type']=ITEM_SOURCE.CHANGE_QUEST_COLOR}) then
		return
	end
	
	value.time = ev.time
	value.color = color
	value.flag = 1
	mission_con:set_param(PARAM_TYPE_ESCORT, value)

	notify_accept_escort(player, pkt.type)
end

--获取押镖任务信息
Clt_commands[1][CMD_GET_QUEST_INFO_C] =
function(conn, pkt)
	if not pkt or not pkt.type then return end
	local player = g_obj_mgr:get_obj(conn.char_id)
	if not player then
		return
	end
	
	local con = player:get_mission_mgr()
	local value = con:get_param(PARAM_TYPE_ESCORT)
	
	local today = f_get_today()
	if not value or (not value.time) or value.time < today then
		value = value or {}
		value.time = ev.time
		value.flag = 0
		
		local nm = crypto.random(0, 100)
		local probability = escort_config.color_probability
		if nm <= probability.white then
			value.color = 1
		elseif nm <= probability.green then
			value.color = 2
		elseif nm <= probability.blue then
			value.color = 3
		elseif nm <= probability.purple then
			value.color = 4
		else
			value.color = 5
		end
		
		con:set_param(PARAM_TYPE_ESCORT, value)
	end

	notify_accept_escort(player, pkt.type)
end

--获取 日常环任务
Clt_commands[1][CMD_MISSION_GET_DAILY_C] = 
function(conn,pkt)
	local player = g_obj_mgr:get_obj(conn.char_id)
	if not player then return end
	local mission_con = player:get_mission_mgr()
	if not mission_con then return end
	mission_con:getandaccpet_loopdaily()
end
Clt_commands[1][CMD_MISSION_GET_FACTION_C] =
function(conn, pkt)
	local player = g_obj_mgr:get_obj(conn.char_id)
	if not player then
		return
	end
	local s_pkt = {}

	local faction_obj = g_faction_mgr:get_faction_by_cid(conn.char_id)
	if not faction_obj then
		s_pkt.result = 200101
		g_cltsock_mgr:send_client(conn.char_id, CMD_MISION_FACTION_INFO_S, s_pkt)
		return
	end

	local con = player:get_mission_mgr()
	local loop_faction_mission = con:get_param(PARAM_TYPE_LOOP_INDIVIDUAL)
	
	if loop_faction_mission then
		local today = f_get_today()
		if loop_faction_mission.update_time < today then	
			loop_faction_mission.update_time = ev.time
			loop_faction_mission.count 		 = 1
			con:set_param(PARAM_TYPE_LOOP_INDIVIDUAL,loop_faction_mission)
		end
		if loop_faction_mission.quest_id then
			s_pkt.step	= loop_faction_mission.step
			s_pkt.count = tonumber(loop_faction_mission.count)
			local quest = con:get_accept_mission(loop_faction_mission.quest_id)	
			s_pkt.state	=  quest and quest:get_status() or MISSION_STATUS_AVAILABLE
			--挂着的帮派任务是否可接
			if s_pkt.state == MISSION_STATUS_AVAILABLE then
				local quest, e_code = g_mission_mgr:build_quest(loop_faction_mission.quest_id)
				local e_error = 1
				if E_SUCCESS == e_code then
					e_error = quest:can_accept(conn.char_id)
				end		
				if E_SUCCESS ~= e_error then	--如果升级等导致原任务不可接，不可完成，重随机一个
					local tmp_quest = loop_faction_mission.quest_id
					local ret ,quest_id = g_mission_mgr:random_faction_quest(conn.char_id)
					if ret ~= 0 then
						s_pkt.result = ret
						g_cltsock_mgr:send_client(conn.char_id, CMD_MISION_FACTION_INFO_S, s_pkt)
						return
					end
					loop_faction_mission.quest_id 	= quest_id
					f_quest_error_log("faction_mission cannot accept ~! char_id = %s, quest_id = %s, old_quest = %s.", tostring(conn.char_id), tostring(loop_faction_mission.quest_id), tostring(tmp_quest))
					con:set_param(PARAM_TYPE_LOOP_INDIVIDUAL,loop_faction_mission)
				end
			end
			s_pkt.quest_id 	= loop_faction_mission.quest_id
		elseif  loop_faction_mission.count <= FACTION_COMPLETE_TIME then
			f_quest_error_log("faction_mission with counts is not quest_id ~! char_id = %s, count = %s.", tostring(conn.char_id), tostring(loop_faction_mission.count))
			local ret ,quest_id = g_mission_mgr:random_faction_quest(conn.char_id)
			if ret ~= 0 then
				s_pkt.result = ret
				g_cltsock_mgr:send_client(conn.char_id, CMD_MISION_FACTION_INFO_S, s_pkt)
				return
			end
			loop_faction_mission.quest_id 	= quest_id
			loop_faction_mission.count		= loop_faction_mission.count + 1
			con:set_param(PARAM_TYPE_LOOP_INDIVIDUAL,loop_faction_mission)
			s_pkt.quest_id 	= loop_faction_mission.quest_id
			s_pkt.step		= loop_faction_mission.step
			s_pkt.count 	= tonumber(loop_faction_mission.count)
			s_pkt.state		= MISSION_STATUS_AVAILABLE
		end
		local step_award = g_mission_mgr:get_bonus(loop_faction_mission.step, loop_faction_mission.count)
		s_pkt.bonus = step_award + player:get_addition(HUMAN_ADDITION.faction_reward)
		g_cltsock_mgr:send_client(conn.char_id, CMD_MISION_FACTION_INFO_S, s_pkt)
		return 
	end
	--原来没任务，随一个出来
	loop_faction_mission = {}
	local ret ,quest_id = g_mission_mgr:random_faction_quest(conn.char_id)
	if ret ~= 0 then
		s_pkt.result = ret
		g_cltsock_mgr:send_client(conn.char_id, CMD_MISION_FACTION_INFO_S, s_pkt)
		return
	end
	loop_faction_mission.quest_id 	= quest_id 
	loop_faction_mission.step		= 1
	loop_faction_mission.count		= 1
	loop_faction_mission.update_time= ev.time
	con:set_param(PARAM_TYPE_LOOP_INDIVIDUAL,loop_faction_mission)

	s_pkt.quest_id 	= quest_id
	s_pkt.step		= loop_faction_mission.step
	s_pkt.count 	= tonumber(loop_faction_mission.count)
	s_pkt.state		= MISSION_STATUS_AVAILABLE
	local step_award = g_mission_mgr:get_bonus(loop_faction_mission.step, loop_faction_mission.count)
	s_pkt.bonus = step_award + player:get_addition(HUMAN_ADDITION.faction_reward)
	g_cltsock_mgr:send_client(conn.char_id, CMD_MISION_FACTION_INFO_S, s_pkt)
	return
end

Clt_commands[1][CMD_MISSION_REFRESH_FACTION_C] =
function(conn, pkt)
	local player = g_obj_mgr:get_obj(conn.char_id)
	if not player then
		return
	end
	
	local con = player:get_mission_mgr()
	local loop_faction_mission = con:get_param(PARAM_TYPE_LOOP_INDIVIDUAL)
	if not loop_faction_mission then
		return 
	end

	local old_id = loop_faction_mission.quest_id

	local today = f_get_today()
	if loop_faction_mission.update_time < today then	
		loop_faction_mission.update_time = ev.time
		loop_faction_mission.count 		 = 1
		con:set_param(PARAM_TYPE_LOOP_INDIVIDUAL,loop_faction_mission)
	end

	--判断状态是否可刷新
	local quest = con:get_accept_mission(loop_faction_mission.quest_id)
	if quest then
		local s_pkt = {}
		s_pkt.result = 200103
		g_cltsock_mgr:send_client(conn.char_id, CMD_MISION_FACTION_INFO_S, s_pkt)
		return 
	end

	local ret, quest_id = g_mission_mgr:random_faction_quest(conn.char_id,loop_faction_mission.quest_id)
	if ret ~= 0 then
		local s_pkt = {}
		s_pkt.result = ret
		g_cltsock_mgr:send_client(conn.char_id, CMD_MISION_FACTION_INFO_S, s_pkt)
		return
	end

	--扣钱

	local level = tonumber(player:get_level())
	local cost = 50 * level
	local pack_con = player:get_pack_con()
	local money = pack_con:get_money()
	if money.gold < cost then
		local s_pkt = {}
		s_pkt.result = 200100
		g_cltsock_mgr:send_client(conn.char_id, CMD_MISION_FACTION_INFO_S, s_pkt)
		return 
	end
	if pack_con:check_money_lock(MoneyType.GOLD) then
		return
	end
	pack_con:dec_money(MoneyType.GOLD, cost, {['type']=MONEY_SOURCE.RANDOM_FACTION_M})

	loop_faction_mission.quest_id 	= quest_id
	con:set_param(PARAM_TYPE_LOOP_INDIVIDUAL,loop_faction_mission)

	local s_pkt = {}
	s_pkt.quest_id 	= loop_faction_mission.quest_id
	s_pkt.step		= loop_faction_mission.step
	s_pkt.count 	= tonumber(loop_faction_mission.count)
	s_pkt.state 	= MISSION_STATUS_AVAILABLE
	local step_award = g_mission_mgr:get_bonus(loop_faction_mission.step, loop_faction_mission.count)
	s_pkt.bonus = step_award + player:get_addition(HUMAN_ADDITION.faction_reward) 
	g_cltsock_mgr:send_client(conn.char_id, CMD_MISION_FACTION_INFO_S, s_pkt)

	local str = string.format("insert into faction_mission set quest_id = '%s',char_id = %d,create_time = %d",
	 				old_id,conn.char_id,ev.time)
	g_web_sql:write(str)
	--[[e_code = con:accept_quest(pkt.quest_id)
	if E_SUCCESS ~= e_code then
		NpcContainerMgr:SendError(conn.char_id, e_code)
	end]]
end

Clt_commands[1][CMD_MISSION_ESCORT_SPEED_CHANGE_C] =
function(conn, pkt)
	local player = g_obj_mgr:get_obj(conn.char_id)
	if not player then
		return
	end
	
	local lv = pkt.level
	local rate = {
		0.4
		, 0.8
		, 0.6
	}
	
	if 0 ~= player:get_escort_status() and rate[lv] then
		player:set_escort_status(1, rate[lv])
	end
end

Clt_commands[1][CMD_MISSION_ESCORT_SPEED_CANCEL_C] =
function(conn, pkt)
	local player = g_obj_mgr:get_obj(conn.char_id)
	if not player then
		return
	end
	
	if 0 ~= player:get_escort_status() then
		player:set_escort_status(1, 0.2)
	end
end

--任务快速完成
Clt_commands[1][CMD_MISION_QUICK_COMPLETE_B] =
function(conn, pkt)
	local player = g_obj_mgr:get_obj(conn.char_id)
	if not player then
		return
	end
	
	 --获取角色任务容器
	local mission_con = player:get_mission_mgr()
	if not mission_con then return end

	local pack_con = player:get_pack_con()
	if not pack_con then return end
	--获取任务对象
	local quest = pkt.mission_id and mission_con:get_accept_mission(pkt.mission_id)
	if not quest then return  end
	if quest:get_status() ~= MISSION_STATUS_INCOMPLETE then
		return 
	end
	local meta = misson_loader.get_meta(pkt.mission_id)
	if not meta then
		return E_MISSION_INVALID_ID
	end

	local n_item = meta.postcondition.quick_complete['item']
	local n_item_num = 1
	local result = 1	

	if n_item then	
		result = pack_con:del_item_by_item_id_inter_face(n_item, n_item_num, {['type']=ITEM_SOURCE.MISSION_COMPLETE}, 1)
	else
		local s_pkt = {}
		s_pkt.result = 200108
		g_cltsock_mgr:send_client(conn.char_id, CMD_MISION_QUICK_COMPLETE_S, s_pkt)
	end	
	if result ~= 0 then
		g_cltsock_mgr:send_client(conn.char_id, CMD_MISION_QUICK_COMPLETE_S, {result = result})
		return
	end
	quest:set_status(MISSION_STATUS_COMMIT)
	local e_code = mission_con:complete_quest(pkt.mission_id, nil)
	if E_SUCCESS ~= e_code then
		mission_con:notity_update_quest(pkt.mission_id, true)
		NpcContainerMgr:SendError(conn.char_id, e_code)
	end

	return
end

--获取领地信息
Clt_commands[1][CMD_MISION_MANOR_INFO_B] =
function(conn, pkt)
	if not pkt or not pkt.type then
		return
	end

	local s_pkt = {}
	s_pkt.info = f_get_territory_power(pkt.type)
	g_cltsock_mgr:send_client(conn.char_id, CMD_MISION_MANOR_INFO_S, s_pkt)
	return 
end

--交装备
Clt_commands[1][CMD_MISION_COMPLETE_COL_B] =
function(conn, pkt)
	if not pkt or not pkt.quest_id or not pkt.slot_l then
		return
	end

	local player = g_obj_mgr:get_obj(conn.char_id)
	if not player then
		return
	end
	
	 --获取角色任务容器
	local mission_con = player:get_mission_mgr()
	if not mission_con then return end

	local pack_con = player:get_pack_con()
	if not pack_con then return end

	local meta = misson_loader.get_meta(pkt.quest_id)
	if not meta then
		NpcContainerMgr:SendError(conn.char_id, E_MISSION_INVALID_ID)
		return 
	end

	if meta.flag ~= 4 then return end

	local e_code = mission_con:complete_quest(pkt.quest_id, pkt.selected, {['slot_l'] = pkt.slot_l})
	if e_code and E_SUCCESS ~= e_code then
		NpcContainerMgr:SendError(conn.char_id, e_code)
	end
end

--获取庄园任务信息
Clt_commands[1][CMD_MISION_GET_FINCA_INFO_B] =
function(conn, pkt)
	local player = g_obj_mgr:get_obj(conn.char_id)
	if not player then
		return
	end
	if player:get_level() < 41 then
		g_cltsock_mgr:send_client(conn.char_id, CMD_MISION_GET_FINCA_INFO_S, {['result'] = 25019})
	end
	local s_pkt = {}

	local faction_obj = g_faction_mgr:get_faction_by_cid(conn.char_id)
	if not faction_obj then
		s_pkt.result = 200101
		g_cltsock_mgr:send_client(conn.char_id, CMD_MISION_GET_FINCA_INFO_S, s_pkt)
		return
	end

	local con = player:get_mission_mgr()
	local finca_mission = con:get_param(PARAM_TYPE_FINCA)
	
	if finca_mission then
		local today = f_get_today()
		--检查更新时间
		if finca_mission.update_time < today then	
			finca_mission.update_time = ev.time
			finca_mission.count 	  = 0
			con:set_param(PARAM_TYPE_FINCA, finca_mission)
		end

		if finca_mission.quest_id then
			s_pkt.count = finca_mission.count
			local quest = con:get_accept_mission(finca_mission.quest_id)	
			s_pkt.state	=  quest and quest:get_status() or MISSION_STATUS_AVAILABLE

			--挂着的任务是否可接
			if s_pkt.state == MISSION_STATUS_AVAILABLE then
				local quest, e_code = g_mission_mgr:build_quest(finca_mission.quest_id)
				local e_error = 1
				if E_SUCCESS == e_code then
					e_error = quest:can_accept(conn.char_id)
				end	
					
				if E_SUCCESS ~= e_error then		--如果升级、对方帮派解散等导致原任务不可接，不可完成，重随机一个
					local tmp_quest = finca_mission.quest_id
					local ret ,quest_id = g_mission_mgr:random_finca_quest(conn.char_id)
					if ret ~= 0 then
						s_pkt.result = ret
						g_cltsock_mgr:send_client(conn.char_id, CMD_MISION_GET_FINCA_INFO_S, s_pkt)
						return
					end
					finca_mission.quest_id 	= quest_id
					finca_mission.state		= MISSION_STATUS_AVAILABLE
					f_quest_error_log("finca_mission cannot accept ~! char_id = %s, quest_id = %s, old_quest = %s.", tostring(conn.char_id), tostring(finca_mission.quest_id), tostring(tmp_quest))
					con:set_param(PARAM_TYPE_FINCA, finca_mission)
				end
			end
			s_pkt.quest_id 	= finca_mission.quest_id
		end
		g_cltsock_mgr:send_client(conn.char_id, CMD_MISION_GET_FINCA_INFO_S, s_pkt)
		return 
	
	else
	--原来没任务，随一个出来
		finca_mission = {}
		local ret ,quest_id = g_mission_mgr:random_finca_quest(conn.char_id)
		if ret ~= 0 then
			s_pkt.result = ret
			g_cltsock_mgr:send_client(conn.char_id, CMD_MISION_GET_FINCA_INFO_S, s_pkt)
			return
		end
		finca_mission.quest_id 	= quest_id 
		finca_mission.count		= 0
		finca_mission.update_time= ev.time
		con:set_param(PARAM_TYPE_FINCA,finca_mission)

		s_pkt.quest_id 	= quest_id
		s_pkt.count 	= finca_mission.count
		s_pkt.state		= MISSION_STATUS_AVAILABLE
		g_cltsock_mgr:send_client(conn.char_id, CMD_MISION_GET_FINCA_INFO_S, s_pkt)
		return
	end

	return
end

--获取刷新庄园任务
Clt_commands[1][CMD_MISION_REFRESH_FINCA_B] =
function(conn, pkt)
	local player = g_obj_mgr:get_obj(conn.char_id)
	if not player then
		return
	end
	
	if player:get_level() < 41 then
		g_cltsock_mgr:send_client(conn.char_id, CMD_MISION_REFRESH_FINCA_S, {['result'] = 25019})
		return 
	end

	local con = player:get_mission_mgr()
	local finca_mission = con:get_param(PARAM_TYPE_FINCA)
	if not finca_mission then
		return 
	end

	local old_id = finca_mission.quest_id

	local today = f_get_today()
	if finca_mission.update_time < today then	
		finca_mission.update_time = ev.time
		finca_mission.count 	  = 1
		con:set_param(PARAM_TYPE_FINCA, finca_mission)
	end

	--判断状态是否可刷新
	local quest = con:get_accept_mission(finca_mission.quest_id)
	if quest then
		local s_pkt = {}
		s_pkt.result = 25018
		g_cltsock_mgr:send_client(conn.char_id, CMD_MISION_REFRESH_FINCA_S, s_pkt)
		return 
	end

	local ret, quest_id = g_mission_mgr:random_finca_quest(conn.char_id, finca_mission.quest_id)
	if ret ~= 0 then
		local s_pkt = {}
		s_pkt.result = ret
		g_cltsock_mgr:send_client(conn.char_id, CMD_MISION_REFRESH_FINCA_S, s_pkt)
		return
	end

	--扣钱
	local level = player:get_level()
	local cost = 50 * level
	local pack_con = player:get_pack_con()
	local money = pack_con:get_money()
	if money.gold < cost then
		local s_pkt = {}
		s_pkt.result = 200100
		g_cltsock_mgr:send_client(conn.char_id, CMD_MISION_REFRESH_FINCA_S, s_pkt)
		return 
	end
	if pack_con:check_money_lock(MoneyType.GOLD) then
		return
	end
	pack_con:dec_money(MoneyType.GOLD, cost, {['type']=MONEY_SOURCE.RANDOM_FINCA_M})

	finca_mission.quest_id 	= quest_id
	con:set_param(PARAM_TYPE_FINCA, finca_mission)

	local s_pkt = {}
	s_pkt.quest_id 	= finca_mission.quest_id
	s_pkt.count 	= finca_mission.count
	s_pkt.state 	= MISSION_STATUS_AVAILABLE

	g_cltsock_mgr:send_client(conn.char_id, CMD_MISION_REFRESH_FINCA_S, s_pkt)

	local str = string.format("insert into faction_mission set quest_id = '%s',char_id = %d,create_time = %d, type = 1",
	 				old_id,conn.char_id,ev.time)
	g_web_sql:write(str)

end

--交庄园拜访任务
Clt_commands[1][CMD_MISION_COMPLETE_STEAL_B] =
function(conn, pkt)
	if not pkt or not pkt.quest_id or not pkt.slot_l then
		return
	end
	
	local player = g_obj_mgr:get_obj(conn.char_id)
	if not player then
		return
	end
	
	 --获取角色任务容器
	local mission_con = player:get_mission_mgr()
	if not mission_con then return end

	local scene_obj = player:get_scene_obj()
	local manor_owner_id = scene_obj.get_manor_owner and scene_obj:get_manor_owner()

	if not manor_owner_id then  
		NpcContainerMgr:SendError(conn.char_id, 25024) 
		return
	end

	local finca_mission = mission_con:get_param(PARAM_TYPE_FINCA)
	if not finca_mission then
		NpcContainerMgr:SendError(conn.char_id, 200101) 
		return 
	end
	if finca_mission.quest_id ~= pkt.quest_id then
		return
	end

	local quest = mission_con.accept_list[finca_mission.quest_id]
	if quest then
		local meta = misson_loader.get_meta(finca_mission.quest_id)
		if not meta then
			NpcContainerMgr:SendError(conn.char_id, E_MISSION_INVALID_ID) 
			return
		end
		if meta.flag ~= MISSION_FLAG_COLLECT_VISIT then
			NpcContainerMgr:SendError(conn.char_id, E_MISSION_INVALID_ID) 
			return
		end
		local e_code , f_id = quest:get_faction_id()
		if e_code ~= 0 then
			NpcContainerMgr:SendError(conn.char_id, e_code) 
			return 
		elseif manor_owner_id ~= f_id then
			NpcContainerMgr:SendError(conn.char_id, 25025) 
			return
		end
	else
		NpcContainerMgr:SendError(conn.char_id, 25022) 
		return 
	end	

	local pack_con = player:get_pack_con()
	if not pack_con then return end

	local e_code = mission_con:complete_quest(pkt.quest_id, pkt.selected, {['slot_l'] = pkt.slot_l})
	if e_code and E_SUCCESS ~= e_code then
		NpcContainerMgr:SendError(conn.char_id, e_code)
	end
end

--庄园任务传送
Clt_commands[1][CMD_MISION_FINCA_TRANSPORT_B] =
function(conn, pkt)
	if not pkt then
		return
	end

	local player = g_obj_mgr:get_obj(conn.char_id)
	if not player then
		return
	end
	
	 --获取角色任务容器
	local mission_con = player:get_mission_mgr()
	if not mission_con then return end

	local e_code, f_id = mission_con:get_transport_f_id()
	if E_SUCCESS ~= e_code then
		NpcContainerMgr:SendError(conn.char_id, e_code)
	else
		if f_goto_manor(player, f_id) == 0 then
			local s_pkt = {}
			s_pkt.result = 0
			local faction_obj = g_faction_mgr:get_faction_by_fid(f_id)
			s_pkt.faction_name = faction_obj:get_faction_name()
			g_cltsock_mgr:send_client(conn.char_id, CMD_MISION_FINCA_TRANSPORT_S, s_pkt)
		end
	end
end

--按类型交装备
Clt_commands[1][CMD_MISION_COMPLETE_TYPE_B] =
function(conn, pkt)
	if not pkt or not pkt.quest_id or not pkt.slot_l then
		return
	end

	local player = g_obj_mgr:get_obj(conn.char_id)
	if not player then
		return
	end
	
	 --获取角色任务容器
	local mission_con = player:get_mission_mgr()
	if not mission_con then return end

	local pack_con = player:get_pack_con()
	if not pack_con then return end

	local meta = misson_loader.get_meta(pkt.quest_id)
	if not meta then
		NpcContainerMgr:SendError(conn.char_id, E_MISSION_INVALID_ID)
		return 
	end

	if meta.flag ~= 10 then return end

	local e_code = mission_con:complete_quest(pkt.quest_id, pkt.selected, {['slot_l'] = pkt.slot_l})
	if e_code and E_SUCCESS ~= e_code then
		NpcContainerMgr:SendError(conn.char_id, e_code)
	end
end

--交押镖任务传送
Clt_commands[1][CMD_MISION_COMPLETE_TRANSPORT_C] =
function(conn, pkt)
	local player = g_obj_mgr:get_obj(conn.char_id)
	if not player then
		return
	end
	
	 --获取角色任务容器
	_sf.change_scene_cm(conn.char_id, 30500, location)
end

--日常环形任务一键完成
Clt_commands[1][CMD_MISSION_COMPLETE_DAILY_C] =
function(conn,pkt)
	local player = g_obj_mgr:get_obj(conn.char_id)
	if not player then return end
	
	if DAILY_COMPLETE_TIME < player:get_misc(8) then
		local s_pkt = {}
		s_pkt.result = 200016
		g_cltsock_mgr:send_client(conn.char_id, CMD_MISSION_GET_DAILY_S, s_pkt)
		return 
	end
	--获取角色任务容器
	local mission_con = player:get_mission_mgr()
	if not mission_con then return end
	local flag = 1
	--获取任务对象
	local quest = pkt.quest_id and mission_con:get_accept_mission(pkt.quest_id)
	if not quest then
		local ret ,quest_id = g_mission_mgr:random_daily_quest(conn.char_id)
		if ret ~= 0 then return end
		pkt.quest_id = quest_id
		flag = 0
	else
		if quest:get_status() ~= MISSION_STATUS_INCOMPLETE then
			return 
		end
	end

	local meta = misson_loader.get_meta(pkt.quest_id)
	if not meta then
		return E_MISSION_INVALID_ID
	end

	local pack_con = player:get_pack_con()
	if not pack_con then return end

	local n_item = meta.postcondition.quick_complete['item']
	local n_item_num = DAILY_COMPLETE_TIME - player:get_misc(8) + 1
	local result = 1

	if n_item then	
		result = pack_con:del_item_by_item_id_inter_face(n_item, n_item_num, {['type']=ITEM_SOURCE.MISSION_DAILY_LOOP}, 1)
	else
		g_cltsock_mgr:send_client(conn.char_id, CMD_MISSION_COMPLETE_DAILY_S, {result = 200108})
		return
	end	

	if result ~= 0 then
		local s_pkt = {}
		s_pkt.result = result
		g_cltsock_mgr:send_client(conn.char_id, CMD_MISSION_COMPLETE_DAILY_S, s_pkt)
		return 
	end

	if flag ~= 0 then 
		n_item_num = n_item_num -1 
	end
	local reward = meta.reward
	local add_gold 		= (reward.gold or 0) * n_item_num
	local add_gift_gold = (reward.gift_gold or 0) * n_item_num
	local add_gift_jade = (reward.gift_jade or 0) * n_item_num
	local add_jade 		= (reward.jade or 0) * n_item_num
	local add_exp		= (reward.exp or 0) * n_item_num
	local add_honor		= (reward.honor or 0) * n_item_num

	--增加奖励
	local money_list = {}
	money_list[MoneyType.GOLD] 		=  add_gold
	money_list[MoneyType.GIFT_GOLD] =  add_gift_gold
	money_list[MoneyType.GIFT_JADE] =  add_gift_jade
	money_list[MoneyType.JADE] 		=  add_jade
	money_list[MoneyType.HONOR]		=  add_honor
	pack_con:add_money_l(money_list, {['type'] = MONEY_SOURCE.TASK})
	
	--增加经验值
	if add_exp and add_exp > 0 then
		player:add_exp(add_exp)
	end
	player:set_misc(8,DAILY_COMPLETE_TIME+1)
	local args = {}
	args.id = meta.id
	args.type = meta.type
	args.flag = meta.flag
	args.count = n_item_num
	g_event_mgr:notify_event(EVENT_SET.EVENT_COMPLETE_QUEST, conn.char_id, args)
	mission_con:getandaccpet_loopdaily()

	if flag ~= 0 then
		quest:set_status(MISSION_STATUS_COMMIT)
		local e_code = mission_con:complete_quest(pkt.quest_id)
		if E_SUCCESS ~= e_code then
			mission_con:notity_update_quest(pkt.quest_id, true)
			--NpcContainerMgr:SendError(conn.char_id, e_code)
		end
	end
end