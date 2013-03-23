
local _save_table = "global_achi"
local _config = require("config.loader.global_achi_loader")
Global_achi_mgr = oo.class(nil,"Global_achi_mgr")

function Global_achi_mgr:__init()

	--
	self.global_achi_list = {}
	self.global_reigns = {}		--保存玩家不在线时的称号
end

function Global_achi_mgr:set_achi_done(pkt)
	local achi_id = nil
	if self.global_achi_list[pkt.achi_id] == nil then
		self.global_achi_list[pkt.achi_id] = {}
	end
	local achi_info = _config.get_achi_info(pkt.achi_id)
	if achi_info and table.is_empty(self.global_achi_list[pkt.achi_id]) then
		--table.insert(self.global_achi_list[pkt.achi_id], {pkt.achi_id, pkt.char_id, pkt.name})
		self.global_achi_list[pkt.achi_id] = pkt.info
		achi_id = pkt.achi_id
		--
		for k, v in pairs(self.global_achi_list[pkt.achi_id]) do
			local char_id = v[2]
			self:do_reward(char_id, v[1])
			local player_info = g_player_mgr:get_info(v[2])
			local level = player_info and player_info.level or 0
			local cost = g_consum_ret_mgr:get_total_cost(1, char_id) or 0
			local sql_str = string.format("insert into log_achievement set ach_id = %d, ach_name = '%s', char_id = %d, char_name = '%s', level = %d, cost = %d, time = %d",
			 achi_info.id, achi_info.name, char_id, v[3], level, cost, ev.time)
			g_web_sql:write(sql_str)
		end
		self:save()
	end
	g_server_mgr:send_to_all_map(0, CMD_C2M_GLOBAL_ACHI_SYNC, {item = self.global_achi_list[pkt.achi_id]})

	return achi_id
end

function Global_achi_mgr:set_reigns(pkt)
	local char_id = pkt[1]
	local line = g_player_mgr:get_char_line(char_id)

	if line ~= nil then
		g_server_mgr:send_to_server(line, char_id, CMD_C2M_GLOBAL_SET_REIGNS, pkt)
	else
		if self.global_reigns[char_id] == nil then
			self.global_reigns[char_id] = {}
		end
		local is_exist = false
		for k, v in pairs(self.global_reigns[char_id]) do
			if v[3] == pkt[3] then
				is_exist = true
				self.global_reigns[char_id][k] = pkt
				break;
			end
		end
		if not is_exist then
			table.insert(self.global_reigns[char_id], pkt)
		end
	end
end

function Global_achi_mgr:do_reward(char_id, achi_id)
	local info = _config.get_achi_info(achi_id)
	local reward_list = info.reward
	local send_email = false
	local item_list = {}
	for k, v in pairs(reward_list or {}) do
		if v.type == 1 then
			self:set_reigns({char_id, v.reigns_id, v.reigns_level, ev.time})
		elseif v.type == 2 then
			send_email = true
			table.insert(item_list, {v.item_id, v.item_count, v.item_name})
		end
	end
	if send_email then
		self:send_email_reward(char_id, item_list)
	end
end

function Global_achi_mgr:send_email_reward(char_id, reward)
	local email = {}
	email.sender = -1
	email.recevier = char_id
	email.title = f_get_string(2976)
	email.content = f_get_string(2977)
	email.box_title = f_get_string(2978)
	email.money_list = {}
	
	email.item_list = {}
	for _, v in ipairs(reward) do
		local item = {}
		item.id = v[1]
		item.name = v[3]
		item.count = v[2]
		table.insert(email.item_list, item)
	end
	
	g_email_mgr:send_email_interface(email)
end

function Global_achi_mgr:set_ranking_reigns(comm_l)

	for type, v in pairs(comm_l) do
		--print("set_ranking_reigns", type, v[4][1])
		local achi_id = _config.get_rank_status_to_achi_id(type)
		if achi_id then
			self:do_reward(v[4][1], achi_id)
		end
	end
end

--重启同步
function Global_achi_mgr:syn_all_to_map(server_id)
	local pkt = {}
	pkt.achi_list = {}
	for k, v in pairs(self.global_achi_list) do
		table.insert(pkt.achi_list, v)
	end
	g_server_mgr:send_to_server(server_id, 0, CMD_C2M_GLOBAL_ACHI_SYNC, pkt)
end

function Global_achi_mgr:online(char_id, line)
	if self.global_reigns[char_id] then
		for k, v in pairs(self.global_reigns[char_id]) do
			g_server_mgr:send_to_server(line, char_id, CMD_C2M_GLOBAL_SET_REIGNS, v)
		end
		self.global_reigns[char_id] = nil
	end
end

-----------------------------数据保存
function Global_achi_mgr:save()
	local data = {}
	data.achi_list = {}
	for k, v in pairs(self.global_achi_list) do
		table.insert(data.achi_list, v)
	end
	data.reigns = {}
	for k, v in pairs(self.global_reigns) do
		table.insert(data.reigns, v) 
	end
	--
	local m_db = f_get_db()
	local query = string.format("{name:'%s'}", "achi")
	m_db:update(_save_table, query, Json.Encode(data), true)
end

function Global_achi_mgr:load()
	local m_db = f_get_db()
	local query = string.format("{name:'%s'}", "achi")
	local rows, e_code = m_db:select_one(_save_table, nil, query)
	if rows ~= nil then
		if rows.achi_list then
			self.global_achi_list = {}
			for k, v in pairs(rows.achi_list) do
				self.global_achi_list[v[1][1]] = v
			end
		end
		if rows.reigns then
			self.global_reigns = {}
			for k, v in pairs(rows.reigns) do
				local char_id = v[1][1]
				if char_id then
					self.global_reigns[char_id] = v
				end
			end
		end
	end
end