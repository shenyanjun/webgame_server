
local filter_loader = require("config.loader.filter_loader")
local data_base =  "app_filter"
local MIN = 60

Application_filter = oo.class(nil, "Application_filter")

function Application_filter:__init()
	
	self.application_list = {}		--报名人是否进入战场
	
	self.char_list = {}				--报名的全部人

	--排好序的玩家id列表
	self.sort_list = {}

	--领地专属者
	self.faction_id = nil

	--玩家离开一分钟的列表
	self.leave_char = {}
end

function Application_filter:get_sort_list()
	return self.sort_list
end

function Application_filter:get_faction_id()
	return self.faction_id
end
--求报名值
function Application_filter:get_sum(f_level, fight, vip)	
	--随机值
	local random = math.random(10,12) / 10

	--vip系数
	local vip_num = filter_loader.vip[tostring(vip)]

	--帮派等级系数
	local faction_num = filter_loader.faction[tostring(f_level)]

	local result = math.floor(fight * faction_num * random * vip_num)
	return result
end


--报名条件
function Application_filter:is_application_ok(char_id, money)
	--是否有帮派
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	if faction == nil then return 20850 end

	if self.faction_id == faction:get_faction_id() then return 20851 end
	if self.faction_id == nil or self.faction_id == "" then return 20852 end
	
	--金钱
	local app_money = filter_loader.condition.money
	if app_money > money then return 20853 end

	--等级
	local app_level = filter_loader.condition.level
	local player_level = g_player_mgr.all_player_l[char_id].level
	if app_level > player_level then return 20854 end

	--时间段
	local start_time = filter_loader.start_time
	local end_time = filter_loader.end_time
	local l_time = ev.time
	local hour = os.date("%H",l_time)
	local minute = os.date("%M",l_time)
	local second = os.date("%S",l_time)

	local sec_sum = second + minute * 60 + hour * 3600
	local sec_start = start_time.sec + start_time.min * 60 + start_time.hour * 3600
	local sec_end = end_time.sec + end_time.min * 60 + end_time.hour * 3600

	if sec_sum >= sec_start and sec_sum <= sec_end then return 20855 end

	return 0

end

--报名
function Application_filter:application_on(char_id,pkt)
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	if faction ~= nil then
		--帮派等级
		local lvl = faction:get_level()

		--报名值
		local result = self:get_sum(lvl,pkt.fight,pkt.vip)

		local flag = 0
		if self.char_list[char_id] == nil then
			flag = 1
		end
		self.char_list[char_id] = {}
		self.char_list[char_id][1] = pkt.fight
		self.char_list[char_id][2] = pkt.vip
		self.char_list[char_id][3] = lvl
		self.char_list[char_id][4] = result
		self.char_list[char_id][5] = faction:get_faction_name()
		self.char_list[char_id][6] = g_player_mgr.all_player_l[char_id].char_nm

		if table.size(self.sort_list) == 0 then
			table.insert(self.sort_list,char_id)
		else
			if flag == 0 then
				for k, v in pairs(self.sort_list or {}) do
					if v == char_id then
						table.remove(self.sort_list,k)
						break
					end
				end
			end
			for k, v in pairs(self.sort_list or {}) do
				if self.char_list[v][4] < result then
					table.insert(self.sort_list,k,char_id)
					break
				elseif k == table.getn(self.sort_list) then
					table.insert(self.sort_list,char_id)
					break
				end
			end
		end
		
		self:update_application(char_id)

		if flag == 1 then
			return true
		end
		return false
	end
	return false
end

--进入战场设置当前的标志位  flag :1 代表进入战场 0 为未进入战场
function Application_filter:set_war_flag(char_id,flag)
	if self.char_list[char_id] ~= nil and self.char_list[char_id][1] ~= nil then
		self.application_list[char_id] = flag
	end
end

function Application_filter:get_war_flag(char_id)
	return self.application_list[char_id] or 0
end

function Application_filter:is_in_war(char_id)
	if self.application_list[char_id] == 1 then
		return true
	end
	return false
end

function Application_filter:clear_war()
	self.application_list = {}
end

--排序
function Application_filter:sort()
	local t_table = {}
	for k,v in pairs(self.sort_list or {}) do
		if k <= filter_loader.member.max and self:is_in_war(v) == false then
			table.remove(self.sort_list,k)
			table.insert(t_table,v)
		end
	end

	for k,v in pairs(t_table) do
		table.insert(self.sort_list,v)
	end
end

--战场结束清空数据
function Application_filter:clear(faction_id)
	self.faction_id = faction_id
	self.application_list = {}
	self.char_list = {}
	self.sort_list = {}
	self:delete_application()
end


--玩家离线一分钟通知后排序
function Application_filter:sort_leave(char_id)
	for k,v in pairs(self.sort_list or {}) do
		if v == char_id then
			table.remove(self.sort_list,k)
			table.insert(self.sort_list,v)
			break
		end
	end
end

function Application_filter:load()
	local dbh = f_get_db()
	local rows, e_code = dbh:select(data_base)
	if e_code == 0 and rows ~= nil then
		for k,v in pairs(rows or {}) do
			self.char_list[v.char_id] = {}
			self.char_list[v.char_id][1] = v.fight
			self.char_list[v.char_id][2] = v.vip
			self.char_list[v.char_id][3] = v.level
			self.char_list[v.char_id][4] = v.app_result
			self.char_list[v.char_id][5] = v.faction_name
			self.char_list[v.char_id][6] = g_player_mgr.all_player_l[v.char_id].char_nm

			if k == 1 then
				table.insert(self.sort_list, v.char_id)
			else
				for m,n in pairs(self.sort_list) do
					if self.char_list[n][4] < v.app_result then
						table.insert(self.sort_list, m, v.char_id)
						break
					elseif m == table.size(self.sort_list) then
						table.insert(self.sort_list, v.char_id)
						break
					end
				end
			end
		end
	end 

	local query = string.format("{territory_id:%d}", 1)
	local rows, e_code = dbh:select_one("territory", nil, query, nil, "{territory_id:1}")
	if rows ~= nil then
		self.faction_id = rows.owner_id
	end
end

function Application_filter:serialize_to_db(char_id)
	local ret = {}
	ret.fight = self.char_list[char_id][1]
	ret.vip = self.char_list[char_id][2]
	ret.level = self.char_list[char_id][3]
	ret.faction_name = self.char_list[char_id][5]
	ret.app_result = self.char_list[char_id][4]
	ret.char_id = char_id

	return ret
end

function Application_filter:update_application(char_id)
	local db = f_get_db()
	local ret = self:serialize_to_db(char_id)
	local condition = string.format("{char_id:%d}",char_id)
	db:update(data_base,condition,Json.Encode(ret),true)
end

function Application_filter:delete_application()
	local db = f_get_db()
	local e_code = db:delete_all(data_base)
	if 0 ~= e_code then
		print("Error:  delete_application failed", e_code)
	end
end

--查看列表
function Application_filter:get_net_info(char_id)
	local ret = {}
	ret.list = {}
	ret.single_info = {}

	if self.char_list[char_id] == nil then return ret end

	local count = 0
	for k,v in pairs(self.sort_list or {}) do
		if k <= 150 then
			local char_list = {}
			char_list[1] = g_player_mgr.all_player_l[v].char_nm
			char_list[2] = g_player_mgr.all_player_l[v].level
			char_list[3] = self.char_list[v][1]
			char_list[4] = self.char_list[v][5]
			char_list[5] = self.char_list[v][3]
			char_list[6] = self.char_list[v][2]
			table.insert(ret.list, char_list)
		end

		if v == char_id then
			count = k
		end
	end

	ret.single_info[1] = table.size(self.char_list)
	ret.single_info[2] = table.size(self.application_list)
	if count ~= 0 then
		ret.single_info[3] = count
	else
		for m, n in pairs(self.sort_list or {}) do
			if n == char_id then
				ret.single_info[3] = m
				break
			end
		end
	end
	if ret.single_info[3] == nil then
		ret.single_info[3] = #self.sort_list + 1
	end
	--print("dddddddddddddddddddd",j_e(self.char_list))
	ret.single_info[4] = self.char_list[char_id][1]
	ret.single_info[5] = self.char_list[char_id][3] 
	ret.single_info[6] = self.char_list[char_id][2]
	
	return ret
end

--打开面板信息
function Application_filter:get_open_info(char_id)
	local ret = {}
	local faction = g_faction_mgr:get_faction_by_fid(self.faction_id)
	if faction == nil then
		ret[1] = nil
	else
		ret[1] = faction:get_faction_name()
	end

	ret[2] = table.size(self.char_list)
	if self.char_list[char_id] == nil then
		ret[3] = 0
	else
		ret[3] = 1
	end
	return ret
end

--map跟common同步信息
function Application_filter:syn_info()
	local ret = {}
	ret[1] = self.faction_id or ""
	ret[2] = {}
	for k,v in pairs(self.sort_list or {}) do
		if k <= filter_loader.member.max then
			table.insert(ret[2], v)
		else
			break
		end
	end
	return ret
end

--玩家离线一分钟处理
--function Application_filter:on_timer()
	--local flag = 0 
	--for k,v in pairs(self.leave_char or {}) do
		--if v + MIN < ev.time then
			--self:del_char(k)
			--flag = 1
		--end
	--end
	--if flag == 1 then
		---- 同步
		--local ret = self:syn_info()
		--g_server_mgr:send_to_all_map(0, CMD_P2M_APPLICATION_SYN_S, ret)
	--end
--end
--
--function Application_filter:get_click_param()
	--return self, self.on_timer,3,nil	
--end
--
--function Application_filter:insert_char(char_id)
	--self.leave_char[char_id] = ev.time
	--self:set_war_flag(char_id, nil)
--end
--
--function Application_filter:del_char(char_id)
	--self.leave_char[char_id] = nil
	--self:sort_leave(char_id)
--end







Application_filter:__init()