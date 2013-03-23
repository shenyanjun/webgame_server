
local debug_print = function() end
local _cmd = require("map_cmd_func")

local _cmd_st = {}
_cmd_st[CMD_MAP_PLAYER_MOVE_C] = 1
_cmd_st[CMD_MAP_PLAYER_STOP_C] = 1
_cmd_st[CMD_MAP_PET_MOVE_C] = 1
_cmd_st[CMD_MAP_PET_STOP_C] = 1

local switchserver_process = function(self, char_id, cmd, pkt)
	if not cmd then return end
	if not _cmd_st[cmd] then
		if pkt ~= nil then                                  
			pkt = Json.Decode(pkt)  
		else
			pkt = {}
		end     
	end 

	--char_id, ip等初始化好
	self.char_id = char_id
	if Clt_commands[1][cmd] then
		g_timeout_mgr:reset_obj(self)
		local usec_1,sec_1 = crypto.timeofday()

		local fun = Clt_commands[1][cmd]
		local result, errmsg = pcall(fun, self, pkt)
		if not result then
			print("client Error:", errmsg, cmd)
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
	elseif CMD_MAP_PLAYER_ENTER_C == cmd then
		local fun = Clt_commands[0][cmd]
		local result, errmsg = pcall(fun, self, pkt)
		if not result then
			print("client Error:", errmsg, cmd)
		end
	else
		print(table.concat({"client unknow command ", cmd, " for state ", self.state}))
	end
end





local switchserver_send_error_send_error = function(self, char_id, cmd, pkt)
	print("switch_server_send_error", char_id, cmd, pkt)
end

local on_close = 
function(conn)
	--local char_id = conn.char_id
	_cmd.f_kill_all_char(2)
	--if char_id ~= nil then
		--g_svsock_mgr:send_server_ex(WORLD_ID, char_id, CMD_MAP_PLAYER_LEAVE_ACK, {})
	--end
	g_cltsock_mgr:leave(conn)    --listen后超时  

	g_cltsock_mgr:Destroy()
end



local serv_l = {}
serv_l.process = function(self, char_id, cmd, pkt) return switchserver_process(self, char_id, cmd, pkt) end
serv_l.state = 0
serv_l.on_send_error = function(self, char_id, cmd, pkt) return server_send_error(self, char_id, cmd, pkt) end
serv_l.on_close = on_close

g_cltsock_mgr:set_svproc(serv_l)
g_cltsock_mgr:set_send_error_backcall(switchserver_send_error_send_error)



