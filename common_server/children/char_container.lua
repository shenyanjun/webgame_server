local FIVE_MIN = 10 * 60
local MAX_NUM = 1
local DALLIANCE_TIME = 10 * 60
--local HW_TIME = 60 * 60

Char_container = oo.class(nil, "Char_container")

function Char_container:__init(char_id)
	self.char_id = char_id

	self.child_list = {}

	self.online_time = ev.time + FIVE_MIN--每5分钟扣心情值

	self.child_count = 0

	self.flag = 0  --0为不入库 1为入库

	self.dalliance_time = 0  --被调戏时间

	self.dalliance_count = 0  --调戏次数
	self.be_dalliance_count = 0 --被调戏次数

	self.day_time = 0

	--self.hw_time = 0  --夫妻调戏
end


--function Char_container:can_hw_dalliance()
	--if ev.time - self.hw_time >= HW_TIME then
		--return true
	--end
--
	--return false
--end
--
--function Char_container:set_hw_time(time)
	--self.hw_time = time
--end

function Char_container:get_day_time()
	local l_time = self.day_time
	local time_today ={}
	time_today.year = os.date("%Y",l_time)
	time_today.month = os.date("%m",l_time)
	time_today.day = os.date("%d",l_time)
	time_today.hour = 0
	time_today.minute = 0
	time_today.second = 0
	local t_time = os.time(time_today)
	return t_time
end

function Char_container:is_other_day(num)
	if num == nil then num = 1 end
	if ev.time >= self:get_day_time() + num * 86400 then
		self.dalliance_count = 0
		self.be_dalliance_count = 0
		self.day_time = ev.time
		return true
	end
	return false
end

--被调戏可否
function Char_container:can_be_dalliance()
	if ev.time - self.dalliance_time >= DALLIANCE_TIME then
		return 66666
	end

	if self.be_dalliance_count >= g_vip_play_inf:get_vip_field(self.char_id,VIPATTR.FAIRIES_PMOLEST) then
		return 66666
	end

	return 0
end

--被调戏后设置一些参数
function Char_container:set_param_1()
	self.dalliance_time = ev.time
	self.be_dalliance_count = self.be_dalliance_count + 1
end

--主动调戏后设置参数
function Char_container:set_param_2()
	self.dalliance_count = self.dalliance_count + 1
end

--主动调戏可否
function Char_container:can_dalliance()
	if self.dalliance_count >= g_vip_play_inf:get_vip_field(self.char_id,VIPATTR.FAIRIES_IMOLEST) then
		return 333333
	end

	return 0
end

function Char_container:set_flag(flag)
	self.flag = flag
end

function Char_container:get_flag()
	return self.flag
end

function Char_container:modify_name(child_id, name)
	if self.child_list[child_id] then
		self.child_list[child_id]:set_name(name)
	end
end

function Char_container:reset_online_time()
	self.online_time = ev.time + FIVE_MIN
end

function Char_container:get_online_time()
	return self.online_time
end

function Char_container:get_child(child_id)
	return self.child_list[child_id]
end

function Char_container:add_child()
	if self.child_count >= MAX_NUM then return false end

	local child = Char_obj(self.char_id)
	local child_id = child:get_child_id()
	self.child_list[child_id] = child
	self.child_count = self.child_count + 1

	return true, child_id
end

function Char_container:add_child2(child)
	if self.child_count >= MAX_NUM then return false end

	local child_id = child:get_child_id()
	self.child_list[child_id] = child
	self.child_count = self.child_count + 1

	return true
end

function Char_container:del_child(child_id)
	self.child_list[child_id] = nil
	self.child_count = self.child_count - 1
end

--同步信息
function Char_container:update_single_child(child_id)
	local server_id = g_player_mgr:get_map_id(self.char_id)
	if server_id == nil then return end

	local child_obj = self.child_list[child_id]
	if not child_obj then return end

	local info = {}
	info[1] = child_obj:serialize_to_net()

	g_server_mgr:send_to_server(server_id,self.char_id,CMD_P2M_SYN_CHILD_INFO_C,info)
end

function Char_container:update_all_child()
	local server_id = g_player_mgr:get_map_id(self.char_id)
	if server_id == nil then return end

	local info = {}
	local count = 1
	for k,v in pairs(self.child_list) do
		info[count] = v:serialize_to_net()
		count = count + 1
	end

	g_server_mgr:send_to_server(server_id,self.char_id,CMD_P2M_SYN_CHILD_INFO_C,info)
end

function Char_container:update_some_child(child_list)
	if table.size(child_list) == 0 then return end

	local server_id = g_player_mgr:get_map_id(self.char_id)
	if server_id == nil then return end

 	local info = {}
	local count = 1
	for k,v in pairs(child_list) do
		local child_obj = self.child_list[v]
		info[count] = child_obj:serialize_to_net()
		count = count + 1
	end

	g_server_mgr:send_to_server(server_id,self.char_id,CMD_P2M_SYN_CHILD_INFO_C,info)
end

--上线信息同步
function Char_container:update_online_child()
	local server_id = g_player_mgr:get_map_id(self.char_id)
	if server_id == nil then return end

	local info = {}
	local count = 1
	for k,v in pairs(self.child_list) do
		info[count] = v:serialize_to_net()
		count = count + 1
	end

	g_server_mgr:send_to_server(server_id,self.char_id,CMD_P2M_LOGIN_CHILD_INFO_C,info)
end

--定时器专门接口
function Char_container:add_mood(mood)
	if ev.time - self.online_time >= 0 then
		local child_list = {}
		local ret = false
		for k,v in pairs(self.child_list) do
			local o_mood = v:get_mood()
			v:set_mood(o_mood + mood)
			table.insert(child_list, v:get_child_id())
		end
		self.online_time = ev.time + FIVE_MIN
		self.flag = 1
		--更新宠物信息
		self:update_some_child(child_list)
	end
end

function Char_container:add_mood2(mood, child_id)
	if self.child_list[child_id] ~= nil then
		self.child_list[child_id]:set_mood(mood)
	end
end

function Char_container:serialize_to_net()
	local ret = {}
	for k,v in pairs(self.child_list) do
		table.insert(ret, v:serialize_to_net())
	end

	return ret
end

function Char_container:serialize_to_net_ex()
	local ret = {}
	for k,v in pairs(self.child_list) do
		table.insert(ret, v:serialize_to_net_ex())
	end

	return ret
end

function Char_container:serialize_to_db()
	local dbh = f_get_db()
	local ret = {}
	ret.char_id = self.char_id
	--ret.day_time = self.day_time
	--ret.dalliance_time = self.dalliance_time
	--ret.dalliance_time = self.dalliance_count
	--ret.be_dalliance_time = self.be_dalliance_count
	--ret.hw_time = self.hw_time
	ret.child_list = {}
	for k, v in pairs(self.child_list) do
		table.insert(ret.child_list, v:serialize_to_db())
	end

	local query = string.format("{char_id:%d}",self.char_id)

	dbh:update("children_common",query,Json.Encode(ret),true)
end

function Char_container:db_load()
	local dbh = f_get_db()
	local data = "{child_list:1}"--,day_time:1,dalliance_time:1,dalliance_count:1,be_dalliance_count:1
	local query =string.format("{char_id:%d}",self.char_id)

	local row, e_code = dbh:select_one("children_common", data, query)
	if e_code == 0 and row ~= nil then
		--self.day_time = row.day_time or 0
		--self.dalliance_time = row.dalliance_time or 0
		--self.dalliance_count = row.dalliance_count or 0
		--self.be_dalliance_count = row.be_dalliance_count or 0
		--self.hw_time = row.hw_time or 0
		for k,v in pairs(row.child_list) do
			local char_obj = Char_obj(self.char_id, v[1])
			char_obj:unserialize_to_db(v)
			self:add_child2(char_obj)
		end
	end
end


----流水 
--function Char_container:log_children(child_obj, type, io)
--
	--local str = string.format("insert log_fairies set char_id =%d, char_name = '%s', fairies_id = '%s', fairies_name = '%s', fairies_class = %d, io = %d, type = %d, time = %d, remark = '%s'",
				--self.char_id, g_player_mgr.all_player_l[self.char_id].char_nm, child_obj:get_child_id(), child_obj:get_name(), child_obj:get_sex(), type, io, type, ev.time, Json.Encode(child_obj:serialize_to_net()))
		--g_web_sql:write(str)
--end

