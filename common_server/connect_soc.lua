local server_process = function(self, char_id, cmd, pkt)
	if pkt ~= nil then
		pkt = Json.Decode(pkt)
	else 
		pkt = {}
	end

	if Sv_commands[1][cmd] then
		local fun = Sv_commands[1][cmd]	
		local result, errmsg = pcall(fun, self, char_id, pkt)

		if not result then
			print("Error:", errmsg)
		end
	elseif g_sock_event_mgr:process(char_id, cmd, pkt) == 0 then
		--print("sock_event:", char_id, cmd)
	else
		debug_print(table.concat({"unknow command ", cmd, " for state ", self.state}))
	end  
end

local on_close = 
function(self)
	--print("Server_connection on_close", self.id, self.char_id)
	self:on_send_error(self.char_id, self.cmd)
	g_svsock_mgr:destroy_servsock(self)
end

local server_send_error = function(self, char_id, cmd, pkt)
	print("server_connection send_pkt error", char_id, cmd, pkt)
end

local serv_l = {}
serv_l.process = server_process
serv_l.state = 0
serv_l.on_send_error = server_send_error
serv_l.on_close = on_close

g_svsock_mgr:set_svproc(serv_l)
g_svsock_mgr:set_send_error_backcall(server_send_error)
