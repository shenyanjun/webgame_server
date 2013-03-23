
local debug_print = function() end
local _cmd = require("map_cmd_func")

local _cmd_st = {}
_cmd_st[CMD_MAP_PLAYER_MOVE_C] = 1
_cmd_st[CMD_MAP_PLAYER_STOP_C] = 1
_cmd_st[CMD_MAP_PET_MOVE_C] = 1
_cmd_st[CMD_MAP_PET_STOP_C] = 1

local client_process = function(self, cmd, pkt)
	if not cmd then return end
	if not _cmd_st[cmd] then
		if pkt ~= nil then                                  
			pkt = Json.Decode(pkt)  
		else
			pkt = {}
		end     
	end 

	if Clt_commands[self.state] and Clt_commands[self.state][cmd] then
		g_timeout_mgr:reset_obj(self)

		local usec_1,sec_1 = crypto.timeofday()

		local fun = Clt_commands[self.state][cmd]
		local result, errmsg = pcall(fun, self, pkt)
		if not result then
			print("client Error:", errmsg)
			if not _cmd_st[cmd] then
				local _ = g_debug_log and g_debug_log:write("client Error:" .. errmsg .. " cmd:" 
					.. tostring(cmd) .. " char_id:" .. tostring(self.char_id or 0) .. " pkt:" .. Json.Encode(pkt))
			end
		end
		
		local usec_2,sec_2 = crypto.timeofday()
		local temp =  (sec_2+usec_2)-(sec_1+usec_1)
		if temp > 1 and not _cmd_st[cmd] then
			print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Clt_commands[self.state][cmd]", cmd, temp, Json.Encode(pkt), ev.time, self.char_id)
		end
	else
		print(table.concat({"client unknow command ", cmd, " for state ", self.state}))
	end
end


local on_close = 
function(conn)
	local char_id = conn.char_id
	_cmd.f_leave_map(conn, 1)
	if char_id ~= nil then
		g_svsock_mgr:send_server_ex(WORLD_ID, char_id, CMD_MAP_PLAYER_LEAVE_ACK, {})
	end
	g_cltsock_mgr:leave(conn)    --listen后超时  
end



local soclient = ev:create_socket(ev.SK_CLIENT)

--客户端监听
if MUDRV_VERSION == nil then
	soclient.on_accept = function (s)
		while true do
			local so,ip = ev:accept(s)
			if so == nil then break end

			so = ev:create_socket(ev.SK_CLIENT, so._sock_)
			local so, peer = Client_connection:New(so, ip)

			g_cltsock_mgr:set_state(so, 0)
			so.process = client_process
			so.on_close = on_close
			ev:watch(so, ev.EV_READ, 0)

			g_timeout_mgr:add_obj(so)
		end
	end

	if not ev:listen(soclient, "0.0.0.0", CLIENT_MAP_LIST[SELF_SV_ID]["port"]) then
		print("ev:listen is faile!!!!!!!!!!!!!!!!!!!!!!!!!!!")
		os.exit(1)
	end
	ev:watch(soclient, ev.EV_READ, 0)
else
	soclient.on_accept = function (s, so, ip)
		local so, peer = Client_connection:New(so, ip)

		g_cltsock_mgr:set_state(so, 0)
		so.process = client_process
		so.on_close = on_close
		ev:watch(so, ev.EV_READ, 0)

		g_timeout_mgr:add_obj(so)
	end

	if not ev:listen(soclient, "0.0.0.0", CLIENT_MAP_LIST[SELF_SV_ID]["port"], ev.SK_CLIENT) then
		print("ev:listen is faile!!!!!!!!!!!!!!!!!!!!!!!!!!!")
		os.exit(1)
	end
end

