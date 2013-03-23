
--上线取数据
Sv_commands[0][CMD_M2P_CHILD_LOGIN_C] =
function(conn,char_id,pkt)
	if conn == nil or char_id == nil then return end
	g_char_mgr:online(char_id)
	--local char_container = g_char_mgr:get_container(char_id)
	--char_container:update_all_child()

	--g_server_mgr:send_to_server(conn.id,char_id, CMD_M2P_CHILD_LOGIN_S, {["result"] = 0})
end

--生孩子
Sv_commands[0][CMD_M2P_BREED_CHILD_C] =
function(conn,char_id,pkt)
	if conn == nil or char_id == nil or pkt == nil then return end

	local char_container = g_char_mgr:get_container(char_id)

	local result, child_id = char_container:add_child()
	if not result then return g_server_mgr:send_to_server(conn.id,char_id, CMD_M2P_BREED_CHILD_S, {["result"] = 31120}) end


	local child_obj = char_container:get_child(child_id)
	char_container:set_flag(1)

	local ret = {}
	g_sock_event_mgr:set_event_id(char_id, pkt, ret)

	ret.info = char_container:serialize_to_net()
	ret.result = 0
	ret.child_id = child_obj:get_child_id()
	g_server_mgr:send_to_server(conn.id,char_id, CMD_M2P_BREED_CHILD_S, ret)

	local str = ev.time .. " children_breed " .. "char_id " ..char_id .." info :" Json.Encode(child_obj:serialize_to_net())
	g_children_log:write(str)
end

--改名
Sv_commands[0][CMD_M2P_MODIFY_NAME_C] =
function(conn,char_id,pkt)
	if conn == nil or char_id == nil or pkt == nil then return end

	local char_container = g_char_mgr:get_container(char_id)
	char_container:modify_name(pkt.child_id, pkt.name)

	char_container:set_flag(1)
	local ret = pkt
	g_sock_event_mgr:set_event_id(char_id, pkt, ret)

	ret.result = 0
	g_server_mgr:send_to_server(conn.id,char_id, CMD_M2P_MODIFY_NAME_S, ret)
end

--加经验
Sv_commands[0][CMD_M2P_CHILD_EXP_C] =
function(conn,char_id,pkt)
	if char_id == nil or pkt == nil then return end

	local char_container = g_char_mgr:get_container(char_id)
	local child_obj = char_container:get_child(pkt.child_id)
	if not child_obj then return end

	child_obj:add_exp(pkt.exp)
	char_container:update_single_child(pkt.child_id)

	char_container:set_flag(1)

	local str = ev.time .. " children_add_exp " .. "char_id " ..char_id .." child_id :" .. pkt.child_id .. " exp :" .. pkt.exp
	g_children_log:write(str)
end

--道具加心情
Sv_commands[0][CMD_M2P_CHILD_MOOD_C] =
function(conn,char_id,pkt)
	if char_id == nil or pkt == nil then return end

	local char_container = g_char_mgr:get_container(char_id)
	local child_obj = char_container:get_child(pkt.child_id)
	if not child_obj then return end

	local o_mood = child_obj:get_mood()
	child_obj:set_mood(o_mood + pkt.mood)

	char_container:update_single_child(pkt.child_id)

	char_container:set_flag(1)

	local str = ev.time .. " children_add_mood " .. "char_id " ..char_id .." child_id :" .. pkt.child_id .. " mood :" .. pkt.mood
	g_children_log:write(str)
end

--查看对方信息
Sv_commands[0][CMD_M2P_CHILD_OTHER_INFO_C] =
function(conn,char_id,pkt)
	if char_id == nil or conn == nil or pkt == nil then return end
	if not g_player_mgr:is_online_char(char_id) then return end

	if g_player_mgr:is_online_char(pkt.char_id) then
		local server_id = g_player_mgr:get_map_id(pkt.char_id)

		local ret = {}
		ret.char_id_1 = char_id
		ret.char_id_2 = pkt.char_id

		g_char_mgr:get_other_info(ret, server_id)

	else
		--local char_con = g_char_mgr:get_container(pkt.char_id)
		--local ret = {}
		--ret[1] = char_con:serialize_to_net_ex()
		--ret[2] = pkt.char_id
		g_server_mgr:send_to_server(conn.id,char_id, CMD_M2P_CHILD_OTHER_INFO_S, {["result"] = 31132})
	end
end

--夫妻调戏
Sv_commands[0][CMD_M2P_CHILD_DALLIANCE_C] =
function(conn,char_id,pkt)
	if char_id == nil or pkt == nil then return end

	local other_id = g_marry:get_marry_char_id(char_id)
	if other_id ~= pkt.char_id then
		return g_server_mgr:send_to_server(conn.id,char_id, CMD_M2P_CHILD_DALLIANCE_S, {["result"] = 31126})
	end

	local children_con1 = g_char_mgr:get_container(char_id)
	local children_con2 = g_char_mgr:get_container(pkt.char_id)

	local child_obj1 = children_con1:get_child(pkt.child_id1)
	local child_obj2 = children_con2:get_child(pkt.child_id2)
	if not child_obj1 or not child_obj2 then return end

	local mood1 = child_obj1:get_mood()
	local mood2 = child_obj2:get_mood()

	child_obj1:set_mood(mood1 + 12)
	child_obj2:set_mood(mood2 + 12)

	children_con1:set_flag(1)
	children_con2:set_flag(1)

	children_con1:update_single_child(pkt.child_id1)
	children_con2:update_single_child(pkt.child_id2)
	g_server_mgr:send_to_server(conn.id,char_id, CMD_M2P_CHILD_DALLIANCE_S, {["result"] = 0})

	g_char_mgr:bdc(1, {char_id,pkt.char_id},{["mood"] = 12})

	local str = ev.time .. " children_hw_dalliance " .. "s_char_id: " ..char_id .. " s_child_id:" .. pkt.child_id1 .. " d_char_id: " .. pkt.char_id .. " d_child_id :" .. pkt.child_id2
	g_children_log:write(str)

end

--玩家道具调戏
Sv_commands[0][CMD_M2P_CHILD_DALLIANCE_ITEM_C] =
function(conn,char_id,pkt)
	if char_id == nil or pkt == nil then return end

	local children_con1 = g_char_mgr:get_container(pkt.char_id)
	local child_obj1 = children_con1:get_child(pkt.child_id)
	if not child_obj1 then return end

	local mood1 = child_obj1:get_mood()
	child_obj1:set_mood(pkt.mood + mood1)
	child_obj1:add_exp(pkt.exp)

	children_con1:set_flag(1)
	children_con1:update_single_child(pkt.child_id)
	g_char_mgr:bdc(2, {pkt.char_id, char_id},{["char_name"] = g_player_mgr.all_player_l[char_id].char_nm, ["mood"] = pkt.mood, ["exp"] = pkt.exp, ["item_name"] = pkt.item_name})

	local children_con = g_char_mgr:get_container(char_id)
	local child_obj = children_con:get_child(pkt.combat_id)
	if child_obj then

		local mood = child_obj:get_mood()
		child_obj:set_mood(pkt.mood1 + mood)
		child_obj:add_exp(pkt.exp1)

		children_con:set_flag(1)
		children_con:update_single_child(pkt.combat_id)
		g_char_mgr:bdc(3, {char_id},{["mood"] = pkt.mood1, ["exp"] = pkt.exp1})
	end

	g_server_mgr:send_to_server(conn.id,char_id, CMD_M2P_CHILD_DALLIANCE_ITEM_S, {["result"] = 0})

	local str = ev.time .. " children_item_dalliance " .. "s_char_id: " ..char_id .. " s_mood:" .. pkt.mood1 .. " s_exp:" .. pkt.exp1 .. " d_char_id: " .. pkt.char_id .. " d_child_id :" .. pkt.child_id .. " d_mood:" .. pkt.mood .." d_exp: ".. pkt.exp
	g_children_log:write(str)
end

--按身份调戏
Sv_commands[0][CMD_M2P_CHILD_DALLIANCE_FRIEND_C] =
function(conn,char_id,pkt)
	if char_id == nil or pkt == nil then return end

	local children_con1 = g_char_mgr:get_container(char_id)
	local children_con2 = g_char_mgr:get_container(pkt.char_id)

	children_con1:is_other_day()
	children_con2:is_other_day()

	local result = children_con1:can_dalliance()
	if result ~= 0 then
		return g_server_mgr:send_to_server(conn.id,char_id, CMD_M2P_CHILD_DALLIANCE_FRIEND_S, {["result"] = result})
	end

	result = children_con2:can_be_dalliance()
	if result ~= 0 then
		return g_server_mgr:send_to_server(conn.id,char_id, CMD_M2P_CHILD_DALLIANCE_FRIEND_S, {["result"] = result})
	end

	local child_obj1 = children_con1:get_child(pkt.child_id1)
	local child_obj2 = children_con2:get_child(pkt.child_id2)
	if not child_obj1 or not child_obj2 then return end

	if pkt.flag == 1 then  --调戏1 加经验
		child_obj1:add_exp(10)
		child_obj2:add_exp(10)

		children_con1:set_param_2()
		children_con2:set_param_1()

		children_con1:set_flag(1)
		children_con2:set_flag(1)

		children_con1:update_single_child(pkt.child_id1)
		children_con2:update_single_child(pkt.child_id2)

		g_server_mgr:send_to_server(conn.id,char_id, CMD_M2P_CHILD_DALLIANCE_FRIEND_S, {["result"] = 0})
	elseif pkt.flag == 2 then  --调戏2 加心情
		local mood1 = child_obj1:get_mood()
		local mood2 = child_obj2:get_mood()
	
		child_obj1:set_mood(mood1 + 2)
		child_obj2:set_mood(mood2 + 2)

		children_con1:set_param_2()
		children_con2:set_param_1()

		children_con1:set_flag(1)
		children_con2:set_flag(1)

		children_con1:update_single_child(pkt.child_id1)
		children_con2:update_single_child(pkt.child_id2)

		g_server_mgr:send_to_server(conn.id,char_id, CMD_M2P_CHILD_DALLIANCE_FRIEND_S, {["result"] = 0})
	end
end






