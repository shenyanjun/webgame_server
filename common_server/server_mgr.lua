
local Server_handler = require("server_socket_handler")

Server_mgr = oo.class(nil, "Server_mgr")

function Server_mgr:__init()
	self.map_server_list = {}
	self.hide_map_list = {}

	self.socket = nil
	self.timeout = 30
	self.server_list = {}
end

function Server_mgr:start(ip, port)
	--服务器监听
	self.socket = ev:create_socket(ev.SK_SERVER)
	self.socket.on_accept = Server_handler.accept_handler
	if MUDRV_VERSION == nil then
		if not ev:listen(self.socket, ip, port) then
			return false
		end
		ev:watch(self.socket, ev.EV_READ, 0)
	else
		if not ev:listen(self.socket, ip, port, ev.SK_SERVER) then
			return false
		end
	end
	return true
end

function Server_mgr:update_server(conn)
	if conn.id then
		if not self.server_list[conn.id] then
			f_error_log("Server_mgr:update_server(%d, %s) Not Exists Server Info!"
				, conn.id
				, tostring(conn.ip))
		else
			self.server_list[conn.id].timeout = ev.time + self.timeout
		end
	end
end

function Server_mgr:is_map_id(server_id)
	return server_id and MAP_MIN_ID <= server_id and server_id <= MAP_MAX_ID
end

function Server_mgr:accept_server(conn, pkt)
	local server_id = pkt.id
	if CHAT_ID ~= server_id and MALL_ID ~= server_id and GM_ID ~= server_id and not self:is_map_id(server_id) then
		f_error_log("Server_mgr:accept_server(%s, %d) Invalid Server ID!"
			, conn.ip
			, server_id)
		conn:Destroy()
		return
	end
	
	if self.server_list[server_id] then
		conn:Destroy()
		return
	end
	
	conn.id = server_id
	local info = {}
	info.timeout = ev.time + self.timeout
	info.conn = conn
	self.server_list[server_id] = info
	if self:is_map_id(server_id) then
		local map_info = {}
		map_info.line_id = server_id
		map_info.name = pkt.info.name
		map_info.ip = pkt.info.ip
		map_info.port = pkt.info.port
		self.map_server_list[server_id] = map_info
		g_lottery_mgr:update_winners_info(server_id)
		g_lottery_mgr:winners_period_to_map(server_id)
		g_faction_mgr:syn_all_faction(server_id)
		g_marry:send_all_marry_info(server_id)
		--官职  accept_server 121113 chendong
		--g_officer_mgr:send_all_officer_info(server_id)
		g_statue_mgr:update_statue_to_map(server_id)
		--g_faction_battle_mgr:syn_all_to_map(server_id)
		g_faction_manor_mgr:syn_all_to_map(server_id)
		--宠物繁殖
		g_pet_breed_mgr:syn_all_breed(server_id)
		g_collection_activity_mgr:syn_all_buf(server_id)
		g_activity_mgr:syn_all_activity(server_id)
		g_world_lvl_mgr:update_map_lvl(server_id)
		g_achi_tree_mgr:notice_map()
		g_activity_rank_mgr:syn_map_config(server_id)
		g_activity_rank_mgr:syn_map_rank_data(server_id)
		g_global_achi_mgr:syn_all_to_map(server_id)
		
		if 1 == ENABLE_GATE then
			g_ww_mgr:node_sync(server_id)
		end
	end
end

function Server_mgr:destory_connection(conn)
	if not conn then
		return
	end
	local server_id = conn.id
	if server_id and self.server_list[server_id] then
		self.server_list[server_id] = nil
		self.map_server_list[server_id] = nil
	end
end

function Server_mgr:send_to_all_map(obj_id, cmd, pkt, is_encoded)
	for k, _ in pairs(self.map_server_list) do
		self:send_to_server(k, obj_id, cmd, pkt, is_encoded)
	end
end

function Server_mgr:send_to_all_comm_map(obj_id, cmd, pkt, is_encoded)
	for k, _ in pairs(self.map_server_list) do
		if PVP_MAP_LIST[k] == nil and k ~= PVP_MAP_FACTION then
			self:send_to_server(k, obj_id, cmd, pkt, is_encoded)
		end
	end
end

function Server_mgr:send_to_all_pvp_map(obj_id, cmd, pkt, is_encoded)
	for k, _ in pairs(self.map_server_list) do
		if PVP_MAP_LIST[k] then
			self:send_to_server(k, obj_id, cmd, pkt, is_encoded)
		end
	end
end

function Server_mgr:send_to_server(server_id, char_id, cmd, pkt, is_encoded)
	local conn = self.server_list[server_id] and self.server_list[server_id].conn
	if conn and conn.send_pkt then
		if not conn:send_pkt(char_id, cmd, pkt, is_encoded) then
			conn:Destroy()
		end
	else
		f_warning_log("Server %s Not Exist! char_id = %s, cmd = %s.", tostring(server_id), tostring(char_id), tostring(cmd))
	end
end

function Server_mgr:on_timer()
	local now = ev.time
	local timeout_list = {}
	for server_id, info in pairs(self.server_list) do
		if info.timeout <= now then
			table.insert(timeout_list, info.conn)
			f_error_log("Server_mgr:on_timer(id = %s, ip = %s, server_id = %s, timeout = %s, now = %s) Conn Timeout!"
				, tostring(info.conn.id)
				, tostring(info.conn.ip)
				, tostring(server_id)
				, tostring(info.timeout)
				, tostring(now))
		end
	end

	for _, conn in pairs(timeout_list) do
		conn:Destroy()
	end
end
