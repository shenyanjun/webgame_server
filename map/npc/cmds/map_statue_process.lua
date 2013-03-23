
local statue_config = require("config.statue_config")

-----------------客户端--------------
--获取跨服雕像信息
Clt_commands[1][CMD_GET_WORLD_STATUE_C] = 
function(conn, pkt)
	if not conn.char_id then print("Error:not char_id cmd =",CMD_GET_WORLD_STATUE_C) return end
	local statue = g_statue_mgr:get_world_statue()
	if statue then
		g_cltsock_mgr:send_client(conn.char_id, CMD_GET_WORLD_STATUE_S,statue)
	end
end

--获取雕像信息
Clt_commands[1][CMD_MAP_GET_STATUE_C] =
function(conn, pkt)
	if pkt.obj_id == nil then return end
	local statue = g_statue_mgr:net_get_statue(pkt.obj_id)
	if statue ~= nil then
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_GET_STATUE_S, statue)
	end
end
--膜拜回调
local callback_worship_func = function(obj, param, pkt)
	local char_id = param.char_id
	local obj = g_obj_mgr:get_obj(char_id)
	if obj ~= nil and pkt.result == 0 then
		local level = obj:get_level()
		local idx = math.floor((level-30)/10)+1
		obj:add_exp(statue_config.exp[idx])
	end
	g_cltsock_mgr:send_client(char_id, CMD_MAP_WORSHIP_S, pkt)
end
Clt_commands[1][CMD_MAP_WORSHIP_C] =
function(conn, pkt)
	if pkt.type == nil or pkt.obj_id == nil then return end
	
	local obj = g_obj_mgr:get_obj(conn.char_id)
	if obj ~= nil then
		if obj:get_level() >= 30 then
			local new_pkt = {}
			new_pkt.type = pkt.type
			new_pkt.statue_id = g_statue_mgr:get_statue_id(pkt.obj_id)
			if new_pkt.statue_id == nil then return end
			 
			local param = {}
			param.char_id = conn.char_id
			g_sock_event_mgr:add_event(conn.char_id, CMD_C2M_WORSHIP_REP, nil, callback_worship_func, nil, param, 3)
			g_svsock_mgr:send_server_ex(COMMON_ID, conn.char_id, CMD_M2C_WORSHIP_ACK, new_pkt)
		else
			local new_pkt = {}
			new_pkt.result = 20872
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_WORSHIP_S, new_pkt)
		end
	end
end

--签名
Clt_commands[1][CMD_MAP_AUTOGRAPH_C] =
function(conn, pkt)
	if pkt.obj_id == nil or pkt.content == nil or string.len(pkt.content) > 128 then return end
	
	local obj = g_obj_mgr:get_obj(conn.char_id)
	if obj ~= nil then
		local new_pkt = {}
		new_pkt.result = g_statue_mgr:is_autograph(conn.char_id, pkt.obj_id)
		if new_pkt.result == 0 then
			new_pkt.content = pkt.content
			
			local s_pkt = {}
			s_pkt.statue_id = g_statue_mgr:get_statue_id(pkt.obj_id)
			s_pkt.content = pkt.content
			g_svsock_mgr:send_server_ex(COMMON_ID, conn.char_id, CMD_M2C_AUTOGRAPH_ACK, s_pkt)
		end
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_WORSHIP_C, new_pkt)
	end
end



-----------------服务器--------------
--雕像更新
Sv_commands[0][CMD_C2M_UPDATE_STATUE_ACK] =
function(conn, char_id, pkt)
	g_statue_mgr:create_all_statue(pkt)
	g_statue_mgr:show_all_statue()
end
--膜拜更新
Sv_commands[0][CMD_C2M_UPDATE_WORSHIP_ACK] =
function(conn, char_id, pkt)
	g_statue_mgr:update_worship(pkt.id, pkt.worship_l)
end

Sv_commands[0][CMD_C2M_AUTOGRAPH_REP] =
function(conn, char_id, pkt)
	--g_statue_mgr:update_worship(pkt.id, pkt.worship_l)
	g_statue_mgr:update_autograph(pkt.id, pkt.content)
end

