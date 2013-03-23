

local err_fun = function(char_id, cmd, err)
	local new_pkt = {}
	new_pkt.result = err
	g_cltsock_mgr:send_client(char_id, cmd, new_pkt)
end

local item_level = 56

----打开五行基本面板
Clt_commands[1][CMD_MAGICKEY_OPEN_BASE_B] = 
function(conn, pkt)
	local char_id = conn.char_id

	local player = g_obj_mgr:get_obj(char_id)
	if not player then return end

	local mk_con = player:get_magickey_con()
	if not mk_con then return end

	local s_pkt = mk_con:all_base_tonet(1)
	
	g_cltsock_mgr:send_client_ex(conn, CMD_MAGICKEY_OPEN_BASE_S, s_pkt)
end

--基本五行升阶
Clt_commands[1][CMD_MAGICKEY_LVLUP_BASE_B] = 
function(conn, pkt)
	local char_id = conn.char_id

	if not pkt or not pkt.number or pkt.number < 1 or pkt.number > 5 then return end

	local player = g_obj_mgr:get_obj(char_id)
	if not player then return end

	local mk_con = player:get_magickey_con()
	if not mk_con then return end

	mk_con:levelup_base_tonet(pkt.number, (pkt.add or 0))
end

--打开特定法宝
Clt_commands[1][CMD_MAGICKEY_OPEN_ITEM_B] = 
function(conn, pkt)
	local char_id = conn.char_id

	if not pkt or not pkt.point or pkt.point < 1 or pkt.point > 8 then return end

	local player = g_obj_mgr:get_obj(char_id)
	if not player then return end

	local mk_con = player:get_magickey_con()
	if not mk_con then return end

	mk_con:open_item_base_tonet(pkt.point)
end

--开启法宝
Clt_commands[1][CMD_MAGICKEY_ITEM_ACTIVITY_B] = 
function(conn, pkt)
	local char_id = conn.char_id

	if not pkt or not pkt.point or pkt.point < 1 or pkt.point > 8 then return end

	local player = g_obj_mgr:get_obj(char_id)
	if not player then return end

	local mk_con = player:get_magickey_con()
	if not mk_con then return end

	mk_con:activity_item_tonet(pkt.point)
end

--元素注入
Clt_commands[1][CMD_MAGICKEY_ITEM_INJECT_B] = 
function(conn, pkt)
	local char_id = conn.char_id
	if not pkt or not pkt.point or pkt.point < 1 or pkt.point > 8 or not pkt.count or pkt.count < 1
		or not pkt.element or pkt.element < 1 or pkt.element > 5 then return end

	local player = g_obj_mgr:get_obj(char_id)
	if not player then return end
	if player:get_level() < item_level then	
		g_cltsock_mgr:send_client_ex(conn, CMD_MAGICKEY_ITEM_INJECT_S, {["result"] = 43021})
		return
	end

	local mk_con = player:get_magickey_con()
	if not mk_con then return end

	mk_con:inject_item_tonet(pkt.point, pkt.element, pkt.count)
end

--技能激活
Clt_commands[1][CMD_MAGICKEY_ACTIVITY_SKILL_B] = 
function(conn, pkt)
	local char_id = conn.char_id

	if not pkt or not pkt.point or pkt.point < 1 or pkt.point > 8 
		or not pkt.skill_id then return end

	local player = g_obj_mgr:get_obj(char_id)
	if not player then return end

	local mk_con = player:get_magickey_con()
	if not mk_con then return end

	mk_con:activity_skill_net(pkt.point, pkt.skill_id)
end

--五行元素注入
Clt_commands[1][CMD_MAGICKEY_INJECT_B] = 
function(conn, pkt)
	local char_id = conn.char_id
	if not pkt or not pkt.element or pkt.element < 1 or pkt.element > 5 or not pkt.count or pkt.count < 1 then return end

	local player = g_obj_mgr:get_obj(char_id)
	if not player then return end
	if player:get_level() < item_level then	
		g_cltsock_mgr:send_client_ex(conn, CMD_MAGICKEY_INJECT_S, {["result"] = 43021})
		return
	end

	local mk_con = player:get_magickey_con()
	if not mk_con then return end

	mk_con:inject_base_tonet(pkt.element, pkt.count)
end