
module("server_socket_handler", package.seeall)
--Server_handler = {}

local function server_cmd_handler(conn, obj_id, cmd, pkt)
	local pkt = pkt and Json.Decode(pkt) or {}
	local fun = Sv_commands[0][cmd]
	if fun then
		local result, errmsg = pcall(fun, conn, obj_id, pkt)
		if not result then
			f_error_log("common_server_cmd_handler(conn = %s, obj_id = %s, cmd = %s) Occur Error: %s!"
				, tostring(conn.ip)
				, tostring(obj_id)
				, tostring(cmd)
				, errmsg)
		end
	elseif 0 == g_sock_event_mgr:process(obj_id, cmd, pkt) then
		--[[f_info_log("common_server_cmd_handler(conn = %s, obj_id = %s, cmd = %s) Process Sock Event!"
			, tostring(conn.ip)
			, tostring(obj_id)
			, tostring(cmd))]]
	else
		f_error_log("common_server_cmd_handler(conn = %s, obj_id = %s, cmd = %s) Invalid Cmd!"
			, tostring(conn.ip)
			, tostring(obj_id)
			, tostring(cmd))
	end 
end

local function process_handler(conn, obj_id, cmd, pkt)
	if cmd then
		g_server_mgr:update_server(conn)
		if CMD_SERVER_PULSE == cmd then
			return
		elseif cmd < CMD_COMMON_END then
			server_cmd_handler(conn, obj_id, cmd, pkt)
			return
		end
	end
	f_error_log("process_handler(conn = %s, obj_id = %s, cmd = %s) Invalid Cmd!"
		, tostring(conn.ip)
		, tostring(obj_id)
		, tostring(cmd))
end

function error_handler(conn, obj_id, cmd, pkt)
	f_error_log("error_handler(%s, %s, %s)"
		, tostring(conn.ip)
		, tostring(obj_id)
		, tostring(cmd))
end

function close_handler(conn)
	conn:on_send_error(conn.char_id, conn.cmd)
	g_server_mgr:destory_connection(conn)
end

if MUDRV_VERSION == nil then
	function accept_handler(socket)
		while true do
			local conn, ip = ev:accept(socket)
			if not conn then
				break 
			end
			conn = ev:create_socket(ev.SK_SERVER, conn._sock_)
			conn = Server_connection:New(conn)
			conn.process = process_handler
			conn.on_send_error = error_handler
			conn.on_close = close_handler
			conn.ip = ip
			conn.state = 0
			ev:watch(conn, ev.EV_READ, 0)
		end
	end
else
	function accept_handler(socket, conn)
		conn = Server_connection:New(conn)
		conn.process = process_handler
		conn.on_send_error = error_handler
		conn.on_close = close_handler
		conn.ip = ip
		conn.state = 0
		ev:watch(conn, ev.EV_READ, 0)
	end
end