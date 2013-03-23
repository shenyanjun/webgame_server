-- 帮派神兽
-- CodeBy:cailizhong
-- 2012/8/10

local faction_dogz_config = require("config.xml.faction_dogz.faction_dogz_config")

Faction_dogz_mgr = oo.class(nil, "Faction_dogz_mgr")

function Faction_dogz_mgr:__init()
end

function Faction_dogz_mgr:load_faction_dogz()
	self.faction_dogz_list = {}
	self.player_list = {} -- 服务器传输消息锁定用
	self.call_dogz_flag = {} -- 神兽召唤时锁定单只神兽用
	local e_code, rows = Faction_dogz_db:load_all()
	if e_code == 0 then
		for _, v in pairs(rows or {}) do
			local faction_id = v.faction_id
			if faction_id then
				local faction = g_faction_mgr:get_faction_by_fid(faction_id)
				if faction then
					local dogz_con = Faction_dogz_container(faction_id)
					local e_code = dogz_con:unserialize_to_db(v)
					if e_code == 0 then
						self.faction_dogz_list[faction_id] = dogz_con
					end
				end
			end
		end
	end
end

function Faction_dogz_mgr:on_line(conn, char_id)
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	if faction then
		local faction_id = faction:get_faction_id()
		if faction_id then
			local ret = {}
			ret.result = 0
			ret.dogz_info = {}
			local dogz_con = self.faction_dogz_list[faction_id]
			if dogz_con ~= nil then
				ret.dogz_info = dogz_con:get_dogz_info_by_cid(char_id)
			end
			if g_player_mgr:is_online_char(char_id) then
				local line = g_player_mgr:get_char_line(char_id)
				g_server_mgr:send_to_server(line, char_id, CMD_GET_FACTION_DOGZ_INFO_C, ret)
			end
		end
	end
end

-- 领养神兽
function Faction_dogz_mgr:adopt_dogz(conn, char_id, dogz_id)
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	if faction then
		local faction_id = faction:get_faction_id()
		if faction_id then
			local dogz_need_level = faction_dogz_config.get_dogz_need_level(dogz_id)
			if not dogz_need_level or faction:get_level()<dogz_need_level then
				return g_server_mgr:send_to_server(conn.id, char_id, CMD_ADOPT_DOGZ_C, {["result"] = 31313})
			end
			local post = faction:get_post(char_id)
			if post~=1 and post~=2 then
				return  g_server_mgr:send_to_server(conn.id, char_id, CMD_ADOPT_DOGZ_C, {["result"] = 31312})
			end
			local need_money = faction_dogz_config.get_adopt_dogz_cost(dogz_id)
			if need_money==nil or need_money > faction:get_money() then
				return  g_server_mgr:send_to_server(conn.id, char_id, CMD_ADOPT_DOGZ_C, {["result"] = 31314})
			end
			local dogz_con = self.faction_dogz_list[faction_id]
			if not dogz_con or not dogz_con:get_dogz_obj() then
				faction:del_money(need_money) -- 扣除帮派资金
				local new_pkt = {}
				new_pkt.faction_id = faction:get_faction_id()
				new_pkt.cmd =25642
				new_pkt.list ={}
				new_pkt.list[1]= faction:syn_info(char_id,1,7)
				g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_SYN_UPDATE_S,Json.Encode(new_pkt),true)
				local new_dogz_con = Faction_dogz_container(faction_id)
				new_dogz_con:create_dogz_obj(dogz_id)
				self.faction_dogz_list[faction_id] = new_dogz_con
				Faction_dogz_db:update(faction_id)
				self:update_faction_dogz_info(faction_id)
				local ret = {}
				ret.result = 0
				g_server_mgr:send_to_server(conn.id, char_id, CMD_ADOPT_DOGZ_C, ret)
			else
				return g_server_mgr:send_to_server(conn.id, char_id, CMD_ADOPT_DOGZ_C, {["result"] = 31302})
			end
		end
	end
end

function Faction_dogz_mgr:update_faction_dogz_info(faction_id)
	local faction = g_faction_mgr:get_faction_by_fid(faction_id)
	if faction then
		for char_id, v in pairs(faction:get_player_list() or {}) do
			if g_player_mgr:is_online_char(char_id) then
				self:on_line(nil, char_id)
			end
		end
	end
end

function Faction_dogz_mgr:get_dogz_con(faction_id)
	if faction_id then
		return self.faction_dogz_list[faction_id]
	end
end

-- 神兽互动
function Faction_dogz_mgr:act_dogz(conn, char_id, dogz_id, act_type, soul)
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	if faction then
		local faction_id = faction:get_faction_id()
		if faction_id then
			local dogz_con = self.faction_dogz_list[faction_id]
			if dogz_con and dogz_con:get_dogz_obj() then
				local ret = {}
				ret.act_type = act_type
				if act_type == 3 then -- 喂养
					if self.player_list[char_id] == nil then
						local e_code = dogz_con:can_feed(char_id, soul)
						if e_code ~= 0 then
							ret.result = e_code
							return g_server_mgr:send_to_server(conn.id, char_id, CMD_ACT_DOGZ_C, ret)
						end
						local node = {}
						node.char_id = char_id
						node.faction_id = faction_id
						node.act_type = act_type
						node.soul = soul
						node.cnt = table.getn(soul)
						self.player_list[char_id] = true -- 锁定操作
						g_sock_event_mgr:add_event_count(char_id, CMD_CHECK_ACT_DOGZ_S, self, self.feed_dogz_success, self.feed_dogz_failed, node, 3, node)
						local line = g_player_mgr:get_char_line(char_id)
						return g_server_mgr:send_to_server(line, char_id, CMD_CHECK_ACT_DOGZ_C, node)
					end
				elseif act_type==1 or act_type==2 then
					local e_code = dogz_con:can_play_or_train(char_id)
					if e_code ~= 0 then
						ret.result = e_code
						return g_server_mgr:send_to_server(conn.id, char_id, CMD_ACT_DOGZ_C, ret)
					end
					if act_type == 1 then
						dogz_con:train_dogz(char_id)
					elseif act_type == 2 then
						dogz_con:play_dogz(char_id)
					end
					self:update_faction_dogz_info(faction_id)
					ret.result = 0
					return g_server_mgr:send_to_server(conn.id, char_id, CMD_ACT_DOGZ_C, ret)
				end
			end
		end
	end
end

function Faction_dogz_mgr:feed_dogz_success(node, pkt)
	if node and pkt then
		local char_id = node.char_id
		if char_id then
			self.player_list[char_id] = nil -- 重置锁标记
			local faction_id = node.faction_id
			local soulVal = pkt.soulVal
			local cnt = node.cnt
			if faction_id and soulVal then
				local dogz_con = self.faction_dogz_list[faction_id]
				if dogz_con then
					local add_val = dogz_con:feed_dogz(char_id, soulVal, cnt)
					local ret = {}
					ret.result = 0
					ret.act_type = node.act_type
					ret.add_val = add_val
					ret.cnt = node.cnt
					local line = g_player_mgr:get_char_line(char_id)
					g_server_mgr:send_to_server(line, char_id, CMD_ACT_DOGZ_C, ret)
					self:update_faction_dogz_info(faction_id)
				end
			end
		end
	end
end

function Faction_dogz_mgr:feed_dogz_failed(node, pkt)
	if node then
		local char_id = node.char_id
		if char_id then
			self.player_list[char_id] = nil -- 重置标记
		end
	end
end

function Faction_dogz_mgr:call_dogz(conn, char_id, dogz_id)
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	if faction then
		local faction_id = faction:get_faction_id()
		if faction_id then
			local post = faction:get_post(char_id)
			if post~=1 and post~=2 then
				return g_server_mgr:send_to_server(conn.id, char_id, CMD_CALL_DOGZ_C, {["result"] = 31312})
			end
			local dogz_con = self.faction_dogz_list[faction_id]
			if dogz_con then
				local e_code, stage = dogz_con:can_call()
				if e_code ~= 0 then
					local ret = {}
					ret.result = e_code
					return g_server_mgr:send_to_server(conn.id, char_id, CMD_CALL_DOGZ_C, ret)
				end
				if self.call_dogz_flag[faction_id] == nil then
					local node = {}
					node.char_id = char_id
					node.faction_id = faction_id
					node.top_n_list = dogz_con:get_top_n_list()
					node.dogz_id = dogz_id
					node.stage = stage
					self.call_dogz_flag[faction_id] = true -- 锁操作
					g_sock_event_mgr:add_event_count(char_id, CMD_CHECK_CALL_DOGZ_S, self, self.call_dogz_success, self.call_dogz_failed, node, 3, node)
					local line = g_player_mgr:get_char_line(char_id)
					return g_server_mgr:send_to_server(line, char_id, CMD_CHECK_CALL_DOGZ_C, node)
				end
			end
		end
	end
end

function Faction_dogz_mgr:call_dogz_success(node, pkt)
	if node then
		local faction_id = node.faction_id
		if faction_id then
			self.call_dogz_flag[faction_id] = nil -- 重置标记
			local dogz_con = self.faction_dogz_list[faction_id]
			if dogz_con then
				dogz_con:call_dogz()
				self.faction_dogz_list[faction_id] = nil
				local char_id = node.char_id
				if char_id then
					local line = g_player_mgr:get_char_line(char_id)
					local ret = {}
					ret.result = 0
					ret.top_n_list = node.top_n_list
					g_server_mgr:send_to_server(line, char_id, CMD_CALL_DOGZ_C, ret)
				end
				self:update_faction_dogz_info(faction_id)
			end
		end
	end
end

function Faction_dogz_mgr:call_dogz_failed(node, pkt)
	if node then
		local faction_id = node.faction_id
		if faction_id then
			self.call_dogz_flag[faction_id] = nil -- 重置标记
		end
	end
end

-- 人物退出帮派删除人物相关记录
function Faction_dogz_mgr:del_char_id(faction_id, char_id)
	if faction_id and char_id then
		local dogz_con = self.faction_dogz_list[faction_id]
		if dogz_con then
			dogz_con:clear_record_by_cid(char_id)
			self:update_faction_dogz_info(faction_id)
		end
	end
end

-- 删除帮派神兽
function Faction_dogz_mgr:del(faction_id)
	if faction_id then
		if self.faction_dogz_list[faction_id] then
			self.faction_dogz_list[faction_id] = nil
			Faction_dogz_db:del(faction_id) -- 从数据库删除
		end
	end
end

--  帮派合并
function Faction_dogz_mgr:merge(faction_a_id, faction_b_id)
	self:del(faction_b_id)
	self:update_faction_dogz_info(faction_a_id)
end

------------------定时器部分-----------------------
-- 神兽心情掉落
function Faction_dogz_mgr:get_click_mood_param()
	return self, self.mood_on_timer, 30, nil
end

function Faction_dogz_mgr:mood_on_timer()
	for faction_id, dogz_con in pairs(self.faction_dogz_list or {}) do
		dogz_con:mood_on_timer()
	end
end

-- 定时数据保存
function Faction_dogz_mgr:get_click_data_param(tm)
	return self, self.data_on_timer, tm, nil
end

function Faction_dogz_mgr:data_on_timer()
	for faction_id, dogz_con in pairs(self.faction_dogz_list or {}) do
		dogz_con:data_on_timer()
	end
end

-- 隔天重置喂养次数
function Faction_dogz_mgr:get_click_reset_param(tm)
	return self, self.reset_on_timer, tm, nil
end

function Faction_dogz_mgr:reset_on_timer()
	for faction_id, dogz_con in pairs(self.faction_dogz_list or {}) do
		dogz_con:reset_on_timer()
	end
end

-- 关闭服务器保存数据
function Faction_dogz_mgr:serialize_to_db()
	for faction_id, dogz_con in pairs(self.faction_dogz_list or {}) do
		dogz_con:exit_save()
	end
end