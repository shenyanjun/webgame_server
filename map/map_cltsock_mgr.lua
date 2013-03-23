--local debug_print = print
local debug_print = function() end

LINE_ON = 0    --上线
LINE_CUT = 1   --离线
LINE_OFF = 2   --下线

Cltsock_mgr_map = oo.class(nil, "Cltsock_mgr_map")

function Cltsock_mgr_map:__init()
	self.cltsock_l = {}
end

function Cltsock_mgr_map:send_client_ex(conn, cmd, pkt, is_encoded)
	if conn and conn.char_id then
		conn:send_pkt(cmd, pkt, is_encoded)
	end
end
function Cltsock_mgr_map:send_client(id, cmd, pkt, is_encoded)
	local sock = self.cltsock_l[id]
	if sock and sock.send_pkt then
		sock:send_pkt(cmd, pkt, is_encoded)
		return true
	else
		--debug_print("Cltsock_mgr_map:send_client error", id, cmd)
		return false
	end
end


function Cltsock_mgr_map:enter(conn, char_id)
	local cn = self.cltsock_l[char_id]
	self.cltsock_l[char_id] = conn
	conn.state = 1

	if cn ~= nil then
		g_timeout_mgr:del_obj(cn)
		local _ = cn:Destroy()
	end
end

function Cltsock_mgr_map:leave(conn)
	if conn == nil then return end

	g_timeout_mgr:del_obj(conn)
	if conn.char_id ~= nil then
		self.cltsock_l[conn.char_id] = nil
	end
	conn.state = 0
	--conn:Destroy()
end

function Cltsock_mgr_map:destroy(conn)
	if conn == nil then return end
	local _ = conn.Destroy and conn:Destroy()
end

function Cltsock_mgr_map:get_conn(char_id)
	return self.cltsock_l[char_id]
end

function Cltsock_mgr_map:set_state(conn, state)
	conn.state = state
end
