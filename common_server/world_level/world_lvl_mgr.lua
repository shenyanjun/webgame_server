
--2012-03-13
--cqs
--世界等级管理类

----------------------------------------------------------------


World_lvl_mgr = oo.class(nil, "World_lvl_mgr")



function World_lvl_mgr:__init()
	self.average_lvl = nil
	
	self.tomorrow = f_get_today() + 24 * 3600

	self.update = ev.time + 10
end

function World_lvl_mgr:get_click_param()
	return self, self.on_timer,3,nil
end

function World_lvl_mgr:on_timer()
	if ev.time > self.tomorrow then
		self.average_lvl = nil
		self:get_average_level()
	elseif not self.average_lvl and ev.time > self.update then
		self.update = ev.time + 30
		self:get_average_level()
	end
end

--向world请求等级
function World_lvl_mgr:get_average_level()
	g_svsock_mgr:send_server_ex(WORLD_ID, 0, CMD_C2W_GET_AVERAGE_LEVEL_C, pkt)
end

--改变等级
function World_lvl_mgr:change_average_lvl(lvl)
	if lvl then
		if not self.average_lvl or self.average_lvl ~= lvl then
			self.average_lvl = lvl
			self:update_all_map_lvl()
		end
	end
end


--控制全服等级
function World_lvl_mgr:update_all_map_lvl()
	if self.average_lvl then
		local pkt = {}
		pkt.lvl = self.average_lvl
		g_server_mgr:send_to_all_map(0, CMD_NOTICE_WORLD_LEVEL_C, pkt)
	end
end

--控制单服等级
function World_lvl_mgr:update_map_lvl(server_id)
	if self.average_lvl then
		local pkt = {}
		pkt.lvl = self.average_lvl
		g_server_mgr:send_to_server(server_id, 0, CMD_NOTICE_WORLD_LEVEL_C, pkt)
	end
end

