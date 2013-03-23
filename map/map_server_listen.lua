
local _cmd = require("map_cmd_func")

local server_process = function(self, char_id, cmd, pkt)
	if pkt ~= nil then
		pkt = Json.Decode(pkt)
	else 
		pkt = {}
	end

	--服务器连接包
	--[[if cmd == CMD_SERVER_CONNECTION then
		return g_svsock_mgr:accept_server(self, cmd, pkt)
	end]]

	local usec_1,sec_1 = crypto.timeofday()

	if Sv_commands[0][cmd] then
		local fun = Sv_commands[0][cmd]
		local result, errmsg = pcall(fun, self, char_id, pkt)
		if not result then
			print("server Error:", errmsg)
			local _ = g_debug_log and g_debug_log:write("server Error:" .. errmsg .. " cmd:" .. tostring(cmd))
		end
	elseif g_sock_event_mgr:process(char_id, cmd, pkt) == 0 then
		print("sock_event:", char_id, cmd)
	else
		print(table.concat({"server unknow command ", cmd,  " for state ", self.state}))
	end 

	local usec_2,sec_2 = crypto.timeofday()
	local temp =  math.floor(((sec_2+usec_2)-(sec_1+usec_1))*1000000)
	if temp > 1000000 then
		print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Sv_commands[self.state][cmd]", cmd, temp, Json.Encode(pkt))
	end
end

local server_send_error = function(self, char_id, cmd, pkt)
	--print("server_send_error", char_id, cmd, pkt)
	if (char_id ~= nil and char_id > 0) and (cmd ~= nil and cmd > CMD_BEGIN) then
		_cmd.f_kill_char(self, char_id, 1)
	end
end

local on_close = 
function(self)
	--print("Server_connection on_close", self.id, self.char_id)
	self:on_send_error(self.char_id, self.cmd)
	g_svsock_mgr:destroy_servsock(self)
end


local serv_l = {}
--serv_l.process = server_process
serv_l.process = function(self, char_id, cmd, pkt) return server_process(self, char_id, cmd, pkt) end
serv_l.state = 0
--serv_l.on_send_error = server_send_error
serv_l.on_send_error = function(self, char_id, cmd, pkt) return server_send_error(self, char_id, cmd, pkt) end
serv_l.on_close = on_close

g_svsock_mgr:set_svproc(serv_l)
g_svsock_mgr:set_send_error_backcall(server_send_error)



