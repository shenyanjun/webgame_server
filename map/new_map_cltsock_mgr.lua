--local debug_print = print
local debug_print = function() end

LINE_ON = 0    --上线
LINE_CUT = 1   --离线
LINE_OFF = 2   --下线

New_cltsock_mgr_map = oo.class(Svsock_mgr, "New_cltsock_mgr_map")

function New_cltsock_mgr_map:__init(sv_list)
	self.conn_l = {}           --服务器连接列表
	self.sv_l = table.copy(sv_list)    
	self.backcall_send_error = nil

	self.cltsock_l = {}
end

function New_cltsock_mgr_map:set_svproc(sv_proc)
	self.sv_proc = sv_proc
end

function New_cltsock_mgr_map:set_send_error_backcall(func)
	self.backcall_send_error = func
	print("######Svsock_mgr:set_send_error_backcall", func)
end

function New_cltsock_mgr_map:add_servsock(sv_id, conn)
	self.conn_l[sv_id] = {}
	self.conn_l[sv_id].sock = conn

	Server_connection:New(conn) 
	for k,v in pairs(self.sv_proc) do
		self.conn_l[sv_id].sock[k] = v
	end
	conn.id = sv_id

	ev:watch(conn, ev.EV_READ, 0)
	conn:send_pkt(0, CMD_SERVER_CONNECTION, {["id"]=SELF_SV_ID,["info"]=CLIENT_MAP_LIST[SELF_SV_ID]})   
	self:on_add_servsock(sv_id, conn)
end

function New_cltsock_mgr_map:on_add_servsock(sv_id, conn)
end

function New_cltsock_mgr_map:get_list()
	return self.conn_l
end

--[[function Svsock_mgr:is_connect(sv_id)
	return self.conn_l[sv_id] ~= nil
end]]--

function New_cltsock_mgr_map:connect_servsock(sv_id)
	local t = self.conn_l[sv_id]                       
	local so = t and t.sock                                    
	if so == nil then      
		so = ev:create_socket(ev.SK_SERVER)                                
		if ev:connect(so, SERVER_LIST[sv_id]["ip"], SERVER_LIST[sv_id]["port"]) then
			self:add_servsock(sv_id, so)                   
		else
			--self:destroy_servsock(so)
			ev:destroy_socket(so)
			so = nil
		end                                               
	end                                                  

	return so            
end
function New_cltsock_mgr_map:get_servsock(sv_id)
	local t = self.conn_l[sv_id] and self.conn_l[sv_id]["sock"]
	if t == nil and sv_id ~= SELF_SV_ID then
		for _,v in pairs(self.sv_l) do
			if v == sv_id then
				return self:connect_servsock(sv_id)
			end
		end
	else
		return t
	end
end      

function New_cltsock_mgr_map:Destroy()
	self.conn_l[SWITCH_ID].sock:Destroy()
	self.conn_l[SWITCH_ID] = nil
	self.cltsock_l = {}
end   

--pkt
function New_cltsock_mgr_map:send_server(conn, char_id, cmd, pkt, is_encoded)
	if conn and conn.send_pkt then
		if not conn:send_pkt(char_id, cmd, pkt, is_encoded) then
			--self:destroy_servsock(conn)
			ev:destroy_socket(conn)
		end
	else
		
		print("send_server error:conn is nil", char_id, cmd, debug.traceback())
		local _ = self.backcall_send_error and self.backcall_send_error(conn, char_id, cmd, pkt)
	end
end
function New_cltsock_mgr_map:send_server_ex(sv_id, char_id, cmd, pkt, is_encoded)
	local conn = self:get_servsock(sv_id)
	self:send_server(conn, char_id, cmd, pkt, is_encoded)
end

function New_cltsock_mgr_map:destroy_servsock(conn)
	if conn and conn.id then
		self.conn_l[conn.id] = nil
	end

	--local _ = conn and conn:Destroy()
end

function New_cltsock_mgr_map:connect_allserver()                  
	for k, v in pairs(self.sv_l) do
		--print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>", k, v)
		if v ~= SELF_SV_ID then
			self:connect_servsock(v)
		end
	end
end

--*************event***********

function New_cltsock_mgr_map:get_click_param()
	return self, self.on_timer, 3, nil
end
function New_cltsock_mgr_map:on_timer(tm)
	for _, v in pairs(self.sv_l) do
		local conn = self:get_servsock(v)
		self:send_server(conn, 0, CMD_SERVER_PULSE, {})
	end
end



----------------------
function New_cltsock_mgr_map:send_client_ex(conn, cmd, pkt, is_encoded)
	if conn and conn.char_id then
		conn:send_pkt(conn.char_id, cmd, pkt, is_encoded)
	end
end
function New_cltsock_mgr_map:send_client(id, cmd, pkt, is_encoded)
	local sock = self:get_servsock(SWITCH_ID)
	if sock and sock.send_pkt then
		sock:send_switch_pkt(id, cmd, pkt, is_encoded)
		return true
	else
		--debug_print("Cltsock_mgr_map:send_client error", id, cmd)
		return false
	end
end


function New_cltsock_mgr_map:enter(conn, char_id)
	--local cn = self.cltsock_l[char_id]
	self.cltsock_l[char_id] = conn
	--conn.state = 1

	--if cn ~= nil then
		--g_timeout_mgr:del_obj(cn)
		--local _ = cn:Destroy()
	--end
end                                             

function New_cltsock_mgr_map:leave(conn)
	if conn == nil then return end

	g_timeout_mgr:del_obj(conn)
	--if conn.char_id ~= nil then
		--self.cltsock_l[conn.char_id] = nil
	--end
	--conn:Destroy()
	self.cltsock_l[conn.char_id] = nil
	self:send_server(conn, conn.char_id, CMD_MAP_PLAYER_EXIT_C, {})
end

function New_cltsock_mgr_map:destroy(conn)
	if conn == nil then return end
	local _ = conn.Destroy and conn:Destroy()
end

function New_cltsock_mgr_map:get_conn(char_id)
	return self.cltsock_l[char_id]
end

function New_cltsock_mgr_map:set_state(conn, state)
	conn.state = state
end
