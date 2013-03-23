
local _manor_config = require("config.faction_manor_config")


f_goto_manor = function(obj, f_id)
	if not g_faction_manor_mgr:had_manor(f_id) then
		 return 22240
	end
	local map_id = 2901000
	local manor_copy = g_scene_mgr_ex:get_prototype(map_id)
	local pos = manor_copy:get_enter_oth_pos()

	local e_code, error_list = manor_copy:goto_manor(obj, f_id, pos)
	return e_code 
end


--进入帮派庄园	
Clt_commands[1][CMD_FACTION_MANOR_ENTER_C] =
function(conn,pkt)
	if not g_faction_manor_mgr:had_manor_by_cid(conn.char_id) then
		local new_pkt = {}
		new_pkt.result = 22240
		g_cltsock_mgr:send_client(conn.char_id, CMD_FACTION_MANOR_ENTER_S, new_pkt)
		return
	end

	local map_id = 2901000
	local prototype = g_scene_mgr_ex:get_prototype(map_id)
	local obj = g_obj_mgr:get_obj(conn.char_id)

	if not prototype or not obj then
		local new_pkt = {}
		new_pkt.result = 22259
		g_cltsock_mgr:send_client(conn.char_id, CMD_FACTION_MANOR_ENTER_S, new_pkt)
		return
	end

	local pos = prototype:get_enter_pos()

	local e_code, error_list = prototype:carry_scene(obj, pos)
	if SCENE_ERROR.E_SUCCESS ~= e_code then
		local new_pkt = {}
		new_pkt.result = e_code
		g_cltsock_mgr:send_client(conn.char_id, CMD_FACTION_MANOR_ENTER_S, new_pkt)
	end
end

--打开庄园面板	
Clt_commands[1][CMD_FACTION_MANOR_OPEN_PANEL_C] =
function(conn,pkt)
	if not g_faction_manor_mgr:had_manor_by_cid(conn.char_id) then
		local new_pkt = {}
		new_pkt.result = 22240
		g_cltsock_mgr:send_client(conn.char_id, CMD_FACTION_MANOR_OPEN_PANEL_S, new_pkt)
		return
	end

	local new_pkt = {}
	new_pkt.result = 0
	new_pkt.manor = g_faction_manor_mgr:get_syn_info_by_cid(conn.char_id, nil) or {}
	g_cltsock_mgr:send_client(conn.char_id, CMD_FACTION_MANOR_OPEN_PANEL_S, new_pkt)

end

--庄园升级
Clt_commands[1][CMD_FACTION_MANOR_LEVEL_UP_C] =
function(conn,pkt)
	--print("CMD_FACTION_MANOR_LEVEL_UP_C",)
	
	local result = g_faction_manor_mgr:can_level_up_by_cid(conn.char_id)
	if result ~= 0 then 
		return g_cltsock_mgr:send_client(conn.char_id, CMD_FACTION_MANOR_LEVEL_UP_S, {['result'] = result}) 
	end

	g_svsock_mgr:send_server_ex(COMMON_ID, conn.char_id, CMD_M2C_FACTION_MANOR_LEVEL_UP_C, pkt)
end

--巧匠升级
Clt_commands[1][CMD_FACTION_MANOR_CRAFTSMAN_UP_C] =
function(conn,pkt)
	--print("CMD_FACTION_MANOR_CRAFTSMAN_UP_C",)

	local result = g_faction_manor_mgr:can_craftsman_up_by_cid(conn.char_id)
	if result ~= 0 then 
		return g_cltsock_mgr:send_client(conn.char_id, CMD_FACTION_MANOR_CRAFTSMAN_UP_S, {['result'] = result}) 
	end
	g_svsock_mgr:send_server_ex(COMMON_ID, conn.char_id, CMD_M2C_FACTION_MANOR_CRAFTSMAN_UP_C, pkt)
end

--铁匠升级
Clt_commands[1][CMD_FACTION_MANOR_BLACKSMITH_UP_C] =
function(conn,pkt)
	--print("CMD_FACTION_MANOR_BLACKSMITH_UP_C",)

	local result = g_faction_manor_mgr:can_blacksmith_up_by_cid(conn.char_id)
	if result ~= 0 then 
		return g_cltsock_mgr:send_client(conn.char_id, CMD_FACTION_MANOR_BLACKSMITH_UP_S, {['result'] = result}) 
	end
	g_svsock_mgr:send_server_ex(COMMON_ID, conn.char_id, CMD_M2C_FACTION_MANOR_BLACKSMITH_UP_C, pkt)
end

--秘境升级
Clt_commands[1][CMD_FACTION_MANOR_REALM_UP_C] =
function(conn,pkt)
	--print("CMD_FACTION_MANOR_BLACKSMITH_UP_C",)

	local result = g_faction_manor_mgr:can_realm_up_by_cid(conn.char_id)
	if result ~= 0 then 
		return g_cltsock_mgr:send_client(conn.char_id, CMD_FACTION_MANOR_REALM_UP_S, {['result'] = result}) 
	end
	g_svsock_mgr:send_server_ex(COMMON_ID, conn.char_id, CMD_M2C_FACTION_MANOR_REALM_UP_C, pkt)
end

--打开巧匠面板
Clt_commands[1][CMD_FACTION_MANOR_OPEN_CRAFTSMAN_C] =
function(conn,pkt)
	--print("CMD_FACTION_MANOR_OPEN_CRAFTSMAN_C",)

	local manor = g_faction_manor_mgr:get_manor_by_cid(conn.char_id)
	if manor ~= nil then 
		local new_pkt = {}
		new_pkt.craftsman = manor.craftsman
		new_pkt.power = {manor.power, _manor_config._realm_level[manor.realm][4]}
		new_pkt.cost = _manor_config._craftsman_level[manor.craftsman][7]
		new_pkt.formula = manor.formula
		new_pkt.formula_time =  math.max(0, manor.formula_time + _manor_config._formula_time[manor.craftsman] - ev.time)
		g_cltsock_mgr:send_client(conn.char_id, CMD_FACTION_MANOR_OPEN_CRAFTSMAN_S, new_pkt) 
	end
end

--巧匠研究配方
Clt_commands[1][CMD_FACTION_MANOR_STUDY_FORMULA_C] =
function(conn,pkt)
	--print("CMD_FACTION_MANOR_STUDY_FORMULA_C",)

	local result = g_faction_manor_mgr:can_study_formula_by_cid(conn.char_id)
	if result ~= 0 then 
		return g_cltsock_mgr:send_client(conn.char_id, CMD_FACTION_MANOR_STUDY_FORMULA_S, {['result'] = result}) 
	end
	g_svsock_mgr:send_server_ex(COMMON_ID, conn.char_id, CMD_M2C_FACTION_MANOR_STUDY_FORMULA_C, pkt)
end

--打开刷新面板
--CMD_FACTION_MANOR_OPEN_CRAFTSMAN_C
--CMD_FACTION_MANOR_OPEN_REFLASH_B
Clt_commands[1][CMD_FACTION_MANOR_OPEN_REFLASH_B]=
function(conn, char_id, pkt)
	--print("CMD_FACTION_MANOR_OPEN_REFLASH_B", j_e(pkt))
	local result = g_faction_manor_mgr:can_change_rob_state(conn.char_id)
	local manor = g_faction_manor_mgr:get_manor_by_cid(conn.char_id)
	local _ = g_faction_manor_mgr:set_reflash_flag_by_cid(conn.char_id, false)
	if manor ~= nil then 
		local cost = _manor_config._reflash_formula_cost
		local new_pkt = {}
		new_pkt.factor = cost[manor.craftsman][5]
		new_pkt.cost = cost[manor.craftsman][1]
		new_pkt.result = result
		g_cltsock_mgr:send_client(conn.char_id, CMD_FACTION_MANOR_OPEN_REFLASH_S, new_pkt) 
	end
end

--刷新配方
--CMD_FACTION_MANOR_OPEN_CRAFTSMAN_C
--CMD_FACTION_MANOR_REFLASH_FORMULA_B
Clt_commands[1][CMD_FACTION_MANOR_REFLASH_FORMULA_B] =
function(conn,pkt)
	--print("CMD_FACTION_MANOR_REFLASH_FORMULA_B", j_e(pkt))

	local result = g_faction_manor_mgr:can_change_rob_state(conn.char_id)
	if result ~= 0 then 
		return g_cltsock_mgr:send_client(conn.char_id, CMD_FACTION_MANOR_REFLASH_FORMULA_S, {['result'] = result}) 
	end
	local _ = g_faction_manor_mgr:set_reflash_flag_by_cid(conn.char_id, true)
	
	g_svsock_mgr:send_server_ex(COMMON_ID, conn.char_id, CMD_M2C_FACTION_MANOR_REFLASH_FORMULA_C, pkt)
end

--替换配方
--CMD_FACTION_MANOR_OPEN_CRAFTSMAN_C
--CMD_FACTION_MANOR_REPLACE_FORMULA_B
Clt_commands[1][CMD_FACTION_MANOR_REPLACE_FORMULA_B] =
function(conn,pkt)
	--print("CMD_FACTION_MANOR_OPEN_CRAFTSMAN_C", j_e(pkt))

	local result = g_faction_manor_mgr:can_change_rob_state(conn.char_id)
	if result ~= 0 then 
		return g_cltsock_mgr:send_client(conn.char_id, CMD_FACTION_MANOR_REPLACE_FORMULA_S, {['result'] = result}) 
	end
	local result = g_faction_manor_mgr:get_reflash_flag_by_cid(conn.char_id)
	if result == false then
		local ret = 22268
		return g_cltsock_mgr:send_client(conn.char_id, CMD_FACTION_MANOR_REPLACE_FORMULA_S, {['result'] = ret}) 
	end
	local _ = g_faction_manor_mgr:set_reflash_flag_by_cid(conn.char_id, false)
	g_svsock_mgr:send_server_ex(COMMON_ID, conn.char_id, CMD_M2C_FACTION_MANOR_REPLACE_FORMULA_C, pkt)
end

--升级需求信息
Clt_commands[1][CMD_FACTION_MANOR_UPGRADE_INFO_C] =
function(conn,pkt)
	--print("CMD_FACTION_MANOR_OPEN_CRAFTSMAN_C",)

	local manor = g_faction_manor_mgr:get_manor_by_cid(conn.char_id)
	if manor ~= nil and pkt.type ~= nil then 
		local new_pkt = {}
		new_pkt.type = pkt.type
		if pkt.type == 1 then
			local entry = _manor_config._manor_level[manor.level]
			new_pkt.info = {entry[1], entry[2], entry[3], entry[4], entry[5], entry[8]}
		end
		if pkt.type == 2 then
			local entry = _manor_config._craftsman_level[manor.craftsman]
			new_pkt.info = {entry[1], entry[2], entry[3], entry[4], entry[8]}
		end
		if pkt.type == 3 then
			local entry = _manor_config._realm_level[manor.realm]
			new_pkt.info = {entry[1], entry[2], entry[3], entry[6]}
		end
		g_cltsock_mgr:send_client(conn.char_id, CMD_FACTION_MANOR_UPGRADE_INFO_S, new_pkt) 
	end
end

--庄园建筑减时间
Clt_commands[1][CMD_FACTION_MANOR_SUB_TIME_C] =
function(conn,pkt)
	--print("CMD_FACTION_MANOR_SUB_TIME_C",)

	local result, time = g_faction_manor_mgr:sub_building_time(conn.char_id, pkt)
	if result ~= -1 then
		local new_pkt = {}
		new_pkt.result = result
		new_pkt.building_id = pkt.building_id
		new_pkt.time = time
		g_cltsock_mgr:send_client(conn.char_id, CMD_FACTION_MANOR_SUB_TIME_S, new_pkt)
	end
end

--取维护信息
Clt_commands[1][CMD_FACTION_MANOR_GET_MAINTAIN_INFO_C] =
function(conn,pkt)
	--print("CMD_FACTION_MANOR_GET_MAINTAIN_INFO_C")
	local faction = g_faction_mgr:get_faction_by_cid(conn.char_id)
	if faction == nil then
		return
	end

	local cost_l = faction:get_maintenance()
	local cost_l2 = g_faction_manor_mgr:get_maintenance(faction:get_faction_id())
	cost_l[5] = cost_l2[1]
	cost_l[6] = cost_l2[2]
	cost_l[7] = cost_l2[3]

	local new_pkt = {}
	new_pkt.list = cost_l
	g_cltsock_mgr:send_client(conn.char_id, CMD_FACTION_MANOR_GET_MAINTAIN_INFO_S, new_pkt)
end

--更改入侵状态
Clt_commands[1][CMD_FACTION_MANOR_CHANGE_ROB_STATE_C] =
function(conn,pkt)
	local result = g_faction_manor_mgr:can_change_rob_state(conn.char_id)
	if result ~= 0 then 
		return g_cltsock_mgr:send_client(conn.char_id, CMD_FACTION_MANOR_CHANGE_ROB_STATE_S, {['result'] = result}) 
	end
	g_svsock_mgr:send_server_ex(COMMON_ID, conn.char_id, CMD_M2C_FACTION_MANOR_CHANGE_ROB_STATE_C, pkt)
end

--召唤boss
Clt_commands[1][CMD_FACTION_MANOR_SUMMON_BOSS_C] =
function(conn,pkt)
	--print("CMD_FACTION_MANOR_SUMMON_BOSS_C", j_e(pkt))
	local new_pkt = {}

	if not g_faction_manor_mgr:had_manor_by_cid(conn.char_id) then
		new_pkt.result = 22240
		g_cltsock_mgr:send_client(conn.char_id, CMD_FACTION_MANOR_SUMMON_BOSS_S, new_pkt)
		return
	end

	local map_id = 2901000
	local prototype = g_scene_mgr_ex:get_prototype(map_id)
	local obj = g_obj_mgr:get_obj(conn.char_id)

	if not prototype or not obj then
		new_pkt.result = 22259
		g_cltsock_mgr:send_client(conn.char_id, CMD_FACTION_MANOR_SUMMON_BOSS_S, new_pkt)
		return
	end
	local ret = {}
	new_pkt.result, ret = prototype:pre_summon_boss(obj, pkt.boss_id)
	if new_pkt.result > 0 then
		g_cltsock_mgr:send_client(conn.char_id, CMD_FACTION_MANOR_SUMMON_BOSS_S, new_pkt)
	elseif new_pkt.result == 0 then
		for k, v in pairs(pkt) do
			ret[k] = v
		end
		g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id, CMD_M2C_QQ_BOSS_M, ret)
	end
end

Sv_commands[0][CMD_M2C_QQ_BOSS_C]=
function(conn, char_id, pkt)
	if pkt.result and pkt.result ~= 0 then
		g_cltsock_mgr:send_client(char_id, CMD_FACTION_MANOR_SUMMON_BOSS_S, {result = pkt.result})
		return
	end



	if not g_faction_manor_mgr:had_manor_by_cid(char_id) then
		pkt.result = 22240
		g_svsock_mgr:send_server_ex(COMMON_ID,char_id, CMD_M2C_QQ_BOSS_REQ, pkt)
		g_cltsock_mgr:send_client(char_id, CMD_FACTION_MANOR_SUMMON_BOSS_S, pkt)
		return
	end

	local map_id = 2901000
	local prototype = g_scene_mgr_ex:get_prototype(map_id)
	local obj = g_obj_mgr:get_obj(char_id)

	if not prototype or not obj then
		pkt.result = 22259
		g_svsock_mgr:send_server_ex(COMMON_ID,char_id, CMD_M2C_QQ_BOSS_REQ, pkt)
		g_cltsock_mgr:send_client(char_id, CMD_FACTION_MANOR_SUMMON_BOSS_S, pkt)
		return
	end
	local ret = {}
	local new_pkt = {}
	new_pkt.result, new_pkt.call_reward = prototype:summon_boss(obj, pkt.boss_id)
	pkt.result = new_pkt.result
	if new_pkt.result >= 0 then
		g_svsock_mgr:send_server_ex(COMMON_ID,char_id, CMD_M2C_QQ_BOSS_REQ, pkt)
	end

	g_cltsock_mgr:send_client(char_id, CMD_FACTION_MANOR_SUMMON_BOSS_S, new_pkt)
end

--------------------------------- 服务器间通讯
--庄园升级的回复包
Sv_commands[0][CMD_C2M_FACTION_MANOR_LEVEL_UP_S]=
function(conn, char_id, pkt)
	g_cltsock_mgr:send_client(char_id, CMD_FACTION_MANOR_LEVEL_UP_S, pkt)

	if pkt.result == 0 then
		local new_pkt = {}
		new_pkt.result = 0
		new_pkt.manor = g_faction_manor_mgr:get_syn_info_by_cid(conn.char_id, nil)
		local _ = new_pkt.manor and g_cltsock_mgr:send_client(char_id, CMD_FACTION_MANOR_OPEN_PANEL_S, new_pkt)
	end
end

--巧匠升级的回复包
Sv_commands[0][CMD_C2M_FACTION_MANOR_CRAFTSMAN_UP_S]=
function(conn, char_id, pkt)
	g_cltsock_mgr:send_client(char_id, CMD_FACTION_MANOR_CRAFTSMAN_UP_S, pkt)

	if pkt.result == 0 then
		local new_pkt = {}
		new_pkt.result = 0
		new_pkt.manor = g_faction_manor_mgr:get_syn_info_by_cid(conn.char_id, nil)
		local _ = new_pkt.manor and g_cltsock_mgr:send_client(char_id, CMD_FACTION_MANOR_OPEN_PANEL_S, new_pkt)
	end
end

--铁匠升级的回复包
Sv_commands[0][CMD_C2M_FACTION_MANOR_BLACKSMITH_UP_S]=
function(conn, char_id, pkt)
	g_cltsock_mgr:send_client(char_id, CMD_FACTION_MANOR_BLACKSMITH_UP_S, pkt)

	if pkt.result == 0 then
		local new_pkt = {}
		new_pkt.result = 0
		new_pkt.manor = g_faction_manor_mgr:get_syn_info_by_cid(conn.char_id, nil)
		local _ = new_pkt.manor and g_cltsock_mgr:send_client(char_id, CMD_FACTION_MANOR_OPEN_PANEL_S, new_pkt)
	end
end

--秘境升级的回复包
Sv_commands[0][CMD_C2M_FACTION_MANOR_REALM_UP_S]=
function(conn, char_id, pkt)
	g_cltsock_mgr:send_client(char_id, CMD_FACTION_MANOR_REALM_UP_S, pkt)

	if pkt.result == 0 then
		local new_pkt = {}
		new_pkt.result = 0
		new_pkt.manor = g_faction_manor_mgr:get_syn_info_by_cid(conn.char_id, nil)
		local _ = new_pkt.manor and g_cltsock_mgr:send_client(char_id, CMD_FACTION_MANOR_OPEN_PANEL_S, new_pkt)
	end
end

--巧匠研究配方的回复包
Sv_commands[0][CMD_C2M_FACTION_MANOR_STUDY_FORMULA_S]=
function(conn, char_id, pkt)
	if pkt.result == 0 then
		local manor = g_faction_manor_mgr:get_manor_by_cid(char_id)
		if manor ~= nil then 
			local new_pkt = {}
			new_pkt.craftsman = manor.craftsman
			new_pkt.power = {manor.power, _manor_config._realm_level[manor.realm][4]}
			new_pkt.cost = _manor_config._craftsman_level[manor.craftsman][7]
			new_pkt.formula = manor.formula
			new_pkt.formula_time =  math.max(0, manor.formula_time + _manor_config._formula_time[manor.craftsman] - ev.time)
			g_cltsock_mgr:send_client(char_id, CMD_FACTION_MANOR_OPEN_CRAFTSMAN_S, new_pkt) 
		end
	end
	g_cltsock_mgr:send_client(char_id, CMD_FACTION_MANOR_STUDY_FORMULA_S, pkt)
end



--刷新巧匠配方的回复包
Sv_commands[0][CMD_C2M_FACTION_MANOR_REFLASH_FORMULA_S]=
function(conn, char_id, pkt)
	--print("****CMD_C2M_FACTION_MANOR_REFLASH_FORMULA_S*****", j_e(pkt))
	g_cltsock_mgr:send_client(char_id, CMD_FACTION_MANOR_REFLASH_FORMULA_S, pkt)
end

--替换巧匠配方的回复包
Sv_commands[0][CMD_C2M_FACTION_MANOR_REPLACE_FORMULA_S]=
function(conn, char_id, pkt)
	--print("****CMD_C2M_FACTION_MANOR_REPLACE_FORMULA_S*****", j_e(pkt))
	g_cltsock_mgr:send_client(char_id, CMD_FACTION_MANOR_REPLACE_FORMULA_S, pkt)
end

--更改入侵状态
Sv_commands[0][CMD_C2M_FACTION_MANOR_CHANGE_ROB_STATE_S]=
function(conn, char_id, pkt)
	g_cltsock_mgr:send_client(char_id, CMD_FACTION_MANOR_CHANGE_ROB_STATE_S, pkt)
end

--公共服发过来的同步包
Sv_commands[0][CMD_C2M_FACTION_MANOR_SYN_S]=
function(conn, char_id, pkt)
	--print("CMD_C2M_FACTION_MANOR_SYN_S", j_e(pkt))
	
	g_faction_manor_mgr:set_syn_info(pkt)

	--g_faction_manor_mgr:debug_print()
end


