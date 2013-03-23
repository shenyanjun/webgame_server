
Statue_mgr = oo.class(nil, "Statue_mgr")

function Statue_mgr:__init()
	self.statue_list = {}
	self.date = nil
	--self.test_time = ev.time
	self.world_statue_list = {}
end

--创建雕像
function Statue_mgr:create_all_statue(statue_l)
	local is_notify = self.date
	self.statue_list = {}
	self.date = tonumber(os.date("%Y%m%d"))
	--self.test_time = ev.time
	
	for k,v in pairs(statue_l) do
		self.statue_list[k] = Statue_obj(k, v)
	end
	--跨服雕像
	local world_l = g_ww_mgr and g_ww_mgr:get_winner_info()
	if world_l then
		self.world_statue_list.members = world_l.members
		self.world_statue_list.info = world_l.info	
	end	
	local comm_l = self:net_get_all_statue()
	local pkt = {}
	pkt.comm_l = comm_l
	pkt.world_l = self.world_statue_list
	pkt = Json.Encode(pkt)
	g_server_mgr:send_to_all_comm_map(0, CMD_C2M_UPDATE_STATUE_ACK, pkt, true)
	--排行称号
	if is_notify then
		g_global_achi_mgr:set_ranking_reigns(comm_l)	
	end
end

function Statue_mgr:get_statue(id)
	return self.statue_list[id]
end

--map重启后更新
function Statue_mgr:update_statue_to_map(line)
	if PVP_MAP_LIST[line] == nil and line ~= PVP_MAP_FACTION then
		local pkt = {}
		pkt.comm_l = self:net_get_all_statue()
		pkt.world_l = self.world_statue_list
		pkt = Json.Encode(pkt)
		g_server_mgr:send_to_server(line, 0, CMD_C2M_UPDATE_STATUE_ACK, pkt, true)
	end
end

--网络
function Statue_mgr:net_get_all_statue()
	local tb = {}
	for k,v in pairs(self.statue_list) do
		--table.insert(tb, v:net_get_info())
		tb[k] = v:net_get_info()
	end
	
	return tb
end

--pkt:{{"info":[60],"char_id":79}...}
function Statue_mgr:callback_get_statue_list(param, pkt)
	self:create_all_statue(pkt)
end
function Statue_mgr:on_timer()
	self:on_timer_handle()
end

function Statue_mgr:on_timer_handle()
	local date = tonumber(os.date("%Y%m%d"))
	if self.date == nil or date > self.date then
		g_sock_event_mgr:add_event(0, CMD_G2C_GET_STATUE_REP, self, self.callback_get_statue_list, nil, {}, 5)
		g_server_mgr:send_to_server(GM_ID, 0, CMD_C2G_GET_STATUE_ACK, {})
	end
end 

function Statue_mgr:get_click_param()
	return self,self.on_timer,30,nil
end

