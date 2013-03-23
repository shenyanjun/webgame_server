
-- 庄园升级
Sv_commands[0][CMD_M2C_FACTION_MANOR_LEVEL_UP_C] =
function(conn,char_id,pkt)
	--print("CMD_M2C_FACTION_MANOR_LEVEL_UP_C")

	local new_pkt = {}
	new_pkt.result = g_faction_manor_mgr:level_up_by_cid(char_id)
	g_server_mgr:send_to_server(conn.id, char_id, CMD_C2M_FACTION_MANOR_LEVEL_UP_S, new_pkt)

end

-- 巧匠升级
Sv_commands[0][CMD_M2C_FACTION_MANOR_CRAFTSMAN_UP_C] =
function(conn,char_id,pkt)
	--print("CMD_M2C_FACTION_MANOR_CRAFTSMAN_UP_C")
	
	local new_pkt = {}
	new_pkt.result = g_faction_manor_mgr:craftsman_up_by_cid(char_id)
	g_server_mgr:send_to_server(conn.id, char_id, CMD_C2M_FACTION_MANOR_CRAFTSMAN_UP_S, new_pkt)

end

-- 铁匠升级
Sv_commands[0][CMD_M2C_FACTION_MANOR_BLACKSMITH_UP_C] =
function(conn,char_id,pkt)
	--print("CMD_M2C_FACTION_MANOR_BLACKSMITH_UP_C")
	
	local new_pkt = {}
	new_pkt.result = g_faction_manor_mgr:blacksmith_up_by_cid(char_id)
	g_server_mgr:send_to_server(conn.id, char_id, CMD_C2M_FACTION_MANOR_BLACKSMITH_UP_S, new_pkt)

end

-- 秘境升级
Sv_commands[0][CMD_M2C_FACTION_MANOR_REALM_UP_C] =
function(conn,char_id,pkt)
	--print("CMD_M2C_FACTION_MANOR_REALM_UP_C")
	
	local new_pkt = {}
	new_pkt.result = g_faction_manor_mgr:realm_up_by_cid(char_id)
	g_server_mgr:send_to_server(conn.id, char_id, CMD_C2M_FACTION_MANOR_REALM_UP_S, new_pkt)

end

-- 巧匠研究配方
Sv_commands[0][CMD_M2C_FACTION_MANOR_STUDY_FORMULA_C] =
function(conn,char_id,pkt)
	--print("CMD_M2C_FACTION_MANOR_STUDY_FORMULA_C")
	
	local new_pkt = {}
	new_pkt.result, new_pkt.formula_id = g_faction_manor_mgr:study_formula_by_cid(char_id)
	g_server_mgr:send_to_server(conn.id, char_id, CMD_C2M_FACTION_MANOR_STUDY_FORMULA_S, new_pkt)

end

-- 巧匠刷新配方
Sv_commands[0][CMD_M2C_FACTION_MANOR_REFLASH_FORMULA_C] =
function(conn,char_id,pkt)
	--print("CMD_M2C_FACTION_MANOR_REFLASH_FORMULA_C", j_e(pkt))
	local t_class = pkt.t_class
	if not t_class then return end
	local lock_list = pkt.lock_list or {} 
	local new_pkt = {}
	new_pkt.result, new_pkt.formula_list = g_faction_manor_mgr:reflash_formula_by_cid(char_id, lock_list, t_class)
	g_server_mgr:send_to_server(conn.id, char_id, CMD_C2M_FACTION_MANOR_REFLASH_FORMULA_S, new_pkt)

end

-- 巧匠替换配方
Sv_commands[0][CMD_M2C_FACTION_MANOR_REPLACE_FORMULA_C] =
function(conn,char_id,pkt)
	--print("CMD_M2C_FACTION_MANOR_REPLACE_FORMULA_C", j_e(pkt))
	
	local new_pkt = {}
	new_pkt.result = g_faction_manor_mgr:replace_formula_by_cid(char_id)
	g_server_mgr:send_to_server(conn.id, char_id, CMD_C2M_FACTION_MANOR_REPLACE_FORMULA_S, new_pkt)

end


-- 加帮派历史消息
Sv_commands[0][CMD_M2C_FACTION_MANOR_SET_HISTORY_C] =
function(conn,char_id,pkt)
	--print("CMD_M2C_FACTION_MANOR_ROB_START_C")
	--历史消息
	local ret = {}
	if pkt.type == 28 then
		ret[1] = 28
		ret[2] = ev.time
		ret[3] = pkt.size
		g_faction_mgr:set_battle_info(pkt.f_id, 1, 2901000)
	elseif pkt.type == 29 then
		ret[1] = 29
		ret[2] = ev.time
		g_faction_mgr:set_battle_info(pkt.f_id, 0, 2901000)
		if pkt.fail then return end
	elseif pkt.type == 26 or pkt.type == 27 then
		ret = pkt.pkt
	else
		ret = pkt
	end
	local faction = ret[1] and g_faction_mgr:get_faction_by_cid(char_id) or g_faction_mgr:get_faction_by_fid(pkt.f_id)
	local _ = faction and faction:set_history_info(ret,nil)

end


--同步
--type:0增加庄园，1：庄园升级，2：繁荣值变化，3：灵气值，4：巧匠升级，5：铁匠升级，6：秘境升级，8：建筑减时间
Sv_commands[0][CMD_M2C_FACTION_MANOR_SYN_C] =
function(conn,char_id,pkt)
	--print("CMD_M2C_FACTION_MANOR_SYN_C", j_e(pkt))
	
	local new_pkt = {}
	if pkt.type == 0 then
		new_pkt.result = g_faction_manor_mgr:add_manor(pkt.f_id)
	elseif pkt.type == 1 then

	elseif pkt.type == 2 then
		new_pkt.result = g_faction_manor_mgr:add_flourish(pkt.f_id, pkt.flourish or 0)

	elseif pkt.type == 3 then
		new_pkt.result = g_faction_manor_mgr:add_power(pkt.f_id, pkt.power or 0)

	elseif pkt.type == 8 then
		new_pkt.result = g_faction_manor_mgr:sub_building_time(pkt.f_id, pkt.building)
	end

	--保存
	g_faction_manor_mgr:serialize(pkt.f_id)
end

--杀庄园强盗失败
Sv_commands[0][CMD_M2C_FACTION_MANOR_ROBBER_C] =
function(conn,char_id,pkt)
	--print("CMD_M2C_FACTION_MANOR_ROBBER_C")
	if pkt.f_id == nil then return end

	g_faction_manor_mgr:robber(pkt.f_id)
end

-- 更改入侵状态
Sv_commands[0][CMD_M2C_FACTION_MANOR_CHANGE_ROB_STATE_C] =
function(conn,char_id,pkt)
	
	local new_pkt = {}
	new_pkt.result, new_pkt.is_rob = g_faction_manor_mgr:change_rob_state_by_cid(char_id)
	g_server_mgr:send_to_server(conn.id, char_id, CMD_C2M_FACTION_MANOR_CHANGE_ROB_STATE_S, new_pkt)
end