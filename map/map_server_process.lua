
local debug_print = function() end
local _cmd = require("map_cmd_func")
local _gm_reward_loader = require("reward.gm_function_reward.gm_reward_loader")
local _gm_refresh_loader = require("function.gm_function.refresh_loader")

--world获取玩家列表
local _func_get_list = function()
	local obj_l = g_obj_mgr:get_list(OBJ_TYPE_HUMAN)
	local new_pkt = {}
	new_pkt.line = SELF_SV_ID
	new_pkt.player_list = {}
	local count = 0
	for k,v in pairs(obj_l) do
		local t = {}
		t.obj_id = k
		t.map_id = v:get_scene()[1]
		t.char_nm = v:get_name()
		t.sex = v:get_sex()
		count = count + 1
		new_pkt.player_list[count] = t
	end
	new_pkt.count = count
	return new_pkt
end



Sv_commands[0][CMD_WORLD_LOGIN_KEY_ACK] =
function(conn, char_id, pkt)
	--print("-----Sv_commands[0][CMD_WORLD_LOGIN_KEY_ACK]", char_id)
	g_key_mgr:add_key(char_id, pkt.key, pkt.acc_id)
end

--switch那边通知玩家链接断开
Sv_commands[0][CMD_MAP_PLAYER_EXIT_ACK] =
function(conn, char_id, pkt)
	print("CMD_MAP_PLAYER_EXIT_ACK", char_id)
	g_key_mgr:del_key(char_id)

	local cn = g_cltsock_mgr:get_conn(char_id)
	--[[local obj = g_obj_mgr:get_obj(char_id)
	if cn ~= nil and obj ~= nil then
		_cmd.f_leave_map(cn, 2)
	elseif obj == nil then
		g_svsock_mgr:send_server_ex(WORLD_ID, char_id, CMD_MAP_PLAYER_LEAVE_ACK, {})
	end]]

	_cmd.f_kill_char(cn, char_id, 2)
end

--world通知干掉玩家
Sv_commands[0][CMD_W2M_KICKOUT_PLAYER_ACK] =
function(conn, char_id, pkt)
	print("CMD_WORLD_KICKOUT_PLAYER_ACK", char_id)
	local cn = g_cltsock_mgr:get_conn(char_id)
	g_key_mgr:del_key(char_id)

	_cmd.f_kill_char(cn, char_id)
end

--world获取在线人数
Sv_commands[0][CMD_W2P_GET_ONLINE_ACK] =
function(conn, char_id, pkt)
	debug_print("CMD_W2P_GET_ONLINE_ACK", char_id)
	local new_pkt = {}
	new_pkt.num = g_cltsock_mgr:get_count()
	g_svsock_mgr:send_server_ex(WORLD_ID, char_id, CMD_P2W_GET_ONLINE_REP, new_pkt)
end

--[[Sv_commands[0][CMD_P2M_CHAR_ENTER_REP] =
	function(conn, char_id, pkt)
		--Map先自行处理,再将结果返回客房端
		local ret = {}
		if pkt.result == 0 then
			ret.result = 0
			g_player_mgr.player_l[char_id] = {}
			g_player_mgr.player_l[char_id] = Player(pkt.char_info)
			g_cltsock_mgr:send_client(char_id, CMD_MAP_PLAYER_ENTER_S, ret)
		end
	end--]]


Sv_commands[0][CMD_P2C_GET_PLAYER_LIST_REQ] =
	function(conn, char_id, pkt)
		local new_pkt = _func_get_list()
		g_svsock_mgr:send_server_ex(WORLD_ID, char_id, CMD_P2C_GET_PLAYER_LIST_REP, new_pkt)
	end


--[[Sv_commands[0][CMD_MALL_GET_PLAYER_LIST_REQ] =
	function(conn, char_id, pkt)
		local new_pkt = _func_get_list()
		g_svsock_mgr:send_server_ex(WORLD_ID, char_id, CMD_MALL_GET_PLAYER_LIST_REP, new_pkt)
	end]]

--角色帮派更新
Sv_commands[0][CMD_P2M_PLAYER_HEAD_INFO_S] =
function(conn, char_id, pkt)
	--print("Sv_commands[0][CMD_C2M_FACTION_UPDATE_REQ]", Json.Encode(pkt))
	local obj = g_obj_mgr:get_obj(char_id)
	if obj ~= nil and obj:get_type() == OBJ_TYPE_HUMAN then
		obj:set_faction(pkt)
	end
end

--功能开关
Sv_commands[0][CMD_G2W_SET_SWITCH_ACK] =
function(conn, char_id, pkt)
--[[
	print("#####Sv_commands[0][CMD_G2W_SET_SWITCH_ACK]", pkt.switch_type, pkt.flag)
	if pkt.switch_type == 1 then					--竞技场开关
		if 1 == pkt.flag then
			print("f_get_arena_mgr():start()")
			f_get_arena_mgr():start()
		else
			print("f_get_arena_mgr():stop()")
			f_get_arena_mgr():stop()
		end
	elseif pkt.switch_type == 2 then				--战场开关
		if 1 == pkt.flag then
			print("MAP_TYPE_WAR:start()")
			local mgr_obj = g_scene_mgr:get_scene_mgr(MAP_TYPE_WAR)
			if mgr_obj then
				mgr_obj:start()
			end
		else
			print("MAP_TYPE_WAR:stop()")
			local mgr_obj = g_scene_mgr:get_scene_mgr(MAP_TYPE_WAR)
			if mgr_obj then
				mgr_obj:stop()
			end
		end
	end
]]
end

--热更新
Sv_commands[0][CMD_G2M_MAP_HOT_UPDATE_ACK] =
function(conn, char_id, pkt)
	for k,file in pairs(pkt.file_list) do
		require_ex(file)
	end
end

Sv_commands[0][CMD_W2M_GET_PVP_INFO_REQ] =
function(conn, char_id, pkt)
	local new_pkt = {{}, {}, {}}
	--1战场
	local war_list = g_scene_mgr_ex:get_type_list(MAP_TYPE_FRENZY)
	if war_list then
		local info = new_pkt[1]
		for _, scene in pairs(war_list) do
			table.insert(info, scene:get_status_info())
		end
	end
	--2温泉
	local spa_list = g_scene_mgr_ex:get_type_list(MAP_TYPE_SPA)
	if spa_list then
		local info = new_pkt[2]
		for _, scene in pairs(spa_list) do
			table.insert(info, scene:get_status_info())
		end
	end
	--3新战场
	local new_war_list = g_scene_mgr_ex:get_type_list(MAP_TYPE_BATTLEFIELD)
	if new_war_list then
		local info = new_pkt[3]
		for _, scene in pairs(new_war_list) do
			table.insert(info, scene:get_status_info())
		end
	end

	g_svsock_mgr:send_server_ex(WORLD_ID, char_id, CMD_M2W_GET_PVP_INFO_REP, new_pkt)
end

Sv_commands[0][CMD_W2C_QUALIFY_SORT_REP] =
function(conn, char_id, pkt)
	local prototype = g_scene_mgr_ex:get_prototype(MAP_COPY_INFO_37)
	if prototype then
		prototype:update_sort(pkt)
	end
end

Sv_commands[0][CMD_W2C_QUALIFY_SCORE_SYN] =
function(conn, char_id, pkt)
	local prototype = g_scene_mgr_ex:get_prototype(MAP_COPY_INFO_37)
	if prototype then
		prototype:update_score(pkt.team_id, pkt.score)
	end
end

--后台发送任务可交
Sv_commands[0][CMD_G2M_SET_FUNCTION_STATUS_ACK] =
function(conn, char_id, pkt)

	local player = pkt.char_id and g_obj_mgr:get_obj(pkt.char_id)--角色对象
	if not player then
		return
	end
	if pkt.type == 1  then

		 --获取角色任务容器
		local mission_con = player:get_mission_mgr()
		if not mission_con then return end
		--获取任务对象
		local quest = pkt.id and mission_con:get_accept_mission(pkt.id)
		if not quest then return  end

		quest:set_status(MISSION_STATUS_COMMIT)
		mission_con:notity_update_quest(pkt.id, true)
	end
--	elseif pkt.type == 2 then
--		local goal_con = player:get_goal_con()
--		if not goal_con then return end

--		local goal = pkt.id and goal_con:get_accept_goal(pkt.id)
--		if not goal then return end
--		goal:set_status(GOAL_STATUS.COMMIT)
--		goal_con:on_goal_update(pkt.id)
--	end
end

--获取其他玩家详细属性
--[[Sv_commands[0][CMD_W2M_GET_HUMAN_ATT_REQ] =
function(conn, char_id, pkt)
	if not pkt or not pkt.obj_id then return end
	
	local new_pkt = {}
	new_pkt.result = 20034
	
	local obj = g_obj_mgr:get_obj(pkt.obj_id)
	if obj and OBJ_TYPE_HUMAN == obj:get_type() then
		if not pkt.flag or pkt.flag == 1 then
			new_pkt.result = nil
			new_pkt.info = obj:net_get_info()
			new_pkt.attribute = obj:net_get_att_info(1)
			local pack_con = obj:get_pack_con()
			new_pkt.equip = pack_con:get_equip_ex()
		end
	end
	
	g_svsock_mgr:send_server_ex(WORLD_ID, char_id, CMD_MAP_ASK_HUMAN_ATT_S, new_pkt)  
	--g_svsock_mgr:send_server_ex(WORLD_ID, char_id, CMD_M2W_GET_HUMAN_ATT_REP, new_pkt)
end]]

--公共服获取其他玩家详细属性
Sv_commands[0][CMD_C2M_REQUEST_HUMAN_ATTR_ACK] =
function(conn, char_id, pkt)
	if not pkt or not pkt.obj_id then return end
	
	local new_pkt = {}
	local obj = g_obj_mgr:get_obj(pkt.obj_id)
	if obj and OBJ_TYPE_HUMAN == obj:get_type() then
		if not pkt.flag or pkt.flag == 1 then
			new_pkt.info = obj:net_get_info()
			new_pkt.attribute = obj:net_get_att_info(1)
			local pack_con = obj:get_pack_con()
			new_pkt.equip = pack_con:get_equip_ex()
			
			g_svsock_mgr:send_server_ex(COMMON_ID, char_id, CMD_M2C_REQUEST_HUMAN_ATTR_REP, new_pkt)  
		end
	end
end

--公共服返回玩家信息，发送给玩家
Sv_commands[0][CMD_C2M_GET_HUMAN_ATTR_REP] =
function(conn, char_id, pkt)
	g_cltsock_mgr:send_client(char_id, CMD_MAP_ASK_HUMAN_ATT_S, pkt)
end

--公共服获取其他玩家仙灵详细属性
Sv_commands[0][CMD_C2M_REQUEST_CHILD_ATTR_ACK] =
function(conn, char_id, pkt)
	if not pkt or not pkt.owner_id or not pkt.child_id then return end
	--print("==>CMD_C2M_REQUEST_CHILD_ATTR_ACK")
	local new_pkt = {}
	local obj = g_obj_mgr:get_obj(pkt.owner_id)
	if obj and OBJ_TYPE_HUMAN == obj:get_type() then
		if not pkt.flag or pkt.flag == 1 then
			local children_con = obj:get_children_con()
			if not children_con then return end

			local child_obj = children_con:get_child_obj(pkt.child_id)
			if not child_obj then return end

			local ret = {}
			ret[1] = {}
			ret[1][1] = g_children_mgr:get_child_info_from_line(pkt.owner_id, pkt.child_id)
			ret[2] = pkt.owner_id
			g_svsock_mgr:send_server_ex(COMMON_ID, char_id, CMD_M2C_REQUEST_CHILD_ATTR_REP, ret)  
		end
	end
end

--公共服返回玩家信息，发送给玩家
Sv_commands[0][CMD_C2M_GET_CHILD_ATTR_REP] =
function(conn, char_id, pkt)
	--print("==>CMD_C2M_GET_CHILD_ATTR_REP", j_e(pkt))
	g_cltsock_mgr:send_client(char_id, CMD_MAP_CHILD_RANK_INFO_S, pkt)
end

--更新怪物掉落
Sv_commands[0][CMD_W2M_MONSTER_UPDATE_REQ] = 
function(conn,char_id,pkt)
	if not conn then return end
	g_monster_lost:load_db_lost()
end

--累计在线奖励更新
Sv_commands[0][CMD_W2M_ONLINE_REWARD_UPDATE_REQ] = 
function(conn,char_id,pkt)
	if not conn then return end
	_gm_reward_loader.update_gm_reward()
	g_online_reward:gm_update()
end


--刷怪更新
Sv_commands[0][CMD_W2M_REFRESH_UPDATE_REQ] = 
function(conn,char_id,pkt)
	if not pkt then return end
	if f_is_pvp() or f_is_line_faction() then return end
	_gm_refresh_loader.load_db()
end

--后台通知黄钻等级
Sv_commands[0][CMD_W2M_SET_QLEVEL_C] = 
function(conn,char_id,pkt)
	if pkt.qlevel == nil then return end
	local obj = g_obj_mgr:get_obj(char_id)
	local _ = obj and obj:set_qlevel(pkt.qlevel)
end