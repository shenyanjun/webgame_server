-- 帮派庭院

--local debug_print = print
local debug_print = function() end

Faction_courtyard_mgr = oo.class(nil, "Faction_courtyard_mgr")

local COURTYARD_TYPE = 
{
	MONEY_TREE = 1, -- 摇钱树(铜券树)
	CENSER     = 2, -- 香炉
}

function Faction_courtyard_mgr:__init()
end

function Faction_courtyard_mgr:merge(faction_a_id, faction_b_id)
	if self.courtyard_list[faction_b_id] then
		self.courtyard_list[faction_b_id] = nil
		Faction_courtyard_db:del_one(faction_b_id)
	end
	self:update_faction_money_tree(faction_a_id)
	self:update_censer_info(faction_a_id)
end

function Faction_courtyard_mgr:del_courtyard(faction_id)
	if self.courtyard_list[faction_id] then
		self.courtyard_list[faction_id] = nil
		Faction_courtyard_db:del_one(faction_id)
	end
end

function Faction_courtyard_mgr:update_faction_money_tree(faction_id)
	local faction = g_faction_mgr:get_faction_by_fid(faction_id)
	if faction then
		local faction_id = faction:get_faction_id()
		if faction_id ~= nil then
			local faction_courtyard = self.courtyard_list[faction_id]
			if faction_courtyard and faction_courtyard:get_money_tree_obj() then
				local faction_member_list = faction:get_player_list()
				for char_id, v in pairs(faction_member_list or {}) do
					if g_player_mgr:is_online_char(char_id) then
						local message = {}
						message.result = 0
						message.info = faction_courtyard:get_money_tree_info_by_cid(char_id)
						local line = g_player_mgr:get_char_line(char_id)
						g_server_mgr:send_to_server(line, char_id, CMD_GET_MONEY_TREE_INFO_C, message)
					end
				end
			end
		end
	end
end

function Faction_courtyard_mgr:get_faction_courtyard(faction_id)
	if faction_id then
		return self.courtyard_list[faction_id]
	end
end

function Faction_courtyard_mgr:load_db()
	self.courtyard_list = {}
	local e_code, rows = Faction_courtyard_db:load_all()
	if e_code==0 and rows then
		for _, v in pairs(rows or {}) do
			local faction_id = v.faction_id
			local faction = g_faction_mgr:get_faction_by_fid(faction_id)
			if faction then
				faction_courtyard = Faction_courtyard()
				faction_courtyard:unserialize_to_db(v)
				self.courtyard_list[faction_id] = faction_courtyard
			end
		end
	end
end

function Faction_courtyard_mgr:on_line(conn, char_id, info_type)
	if info_type == COURTYARD_TYPE.MONEY_TREE then -- 获取摇钱树(铜券树)信息
		self:get_money_tree_info(conn, char_id)
	elseif info_type == COURTYARD_TYPE.CENSER then -- 获取香炉信息
		self:get_censer_info(conn, char_id)
	end
end

function Faction_courtyard_mgr:get_money_tree_info(conn, char_id)
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	if faction ~= nil then
		local faction_id = faction:get_faction_id()
		if faction_id ~= nil then
			local faction_courtyard = self.courtyard_list[faction_id]
			if faction_courtyard == nil then
				faction_courtyard = Faction_courtyard()
				self.courtyard_list[faction_id] = faction_courtyard
			end
			if faction_courtyard:get_money_tree_obj() == nil then
				faction_courtyard:create_money_tree_obj()
			end
			local message = {}
			message.result = 0
			message.info = faction_courtyard:get_money_tree_info_by_cid(char_id)
			return g_server_mgr:send_to_server(conn.id, char_id, CMD_GET_MONEY_TREE_INFO_C, message)
		end
	end
	return g_server_mgr:send_to_server(conn.id, char_id, CMD_GET_MONEY_TREE_INFO_C, {["result"] = 31333})
end

function Faction_courtyard_mgr:rock_money_tree(conn, char_id, vip_level)
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	if faction ~= nil then
		local faction_id = faction:get_faction_id()
		if faction_id ~= nil then
			local faction_courtyard = self.courtyard_list[faction_id]
			if faction_courtyard and faction_courtyard:get_money_tree_obj() then
				local last_cnt = faction_courtyard:get_last_rock_cnt_by_cid(char_id, vip_level)
				if last_cnt > 0 then
					if faction_courtyard:get_money_tree_op_flag(char_id) == nil then
						faction_courtyard:set_money_tree_op_flag(char_id, true)
						local info = faction_courtyard:get_money_tree_info_by_cid(char_id)
						local node = {}
						node.char_id = char_id
						node.cnt = info[2]
						node.faction_id = faction_id
						node.level = info[1]
						g_sock_event_mgr:add_event_count(char_id, CMD_ROCK_MONEY_TREE_CHECK_S, self, self.rock_tree_success, self.rock_tree_failed, node, 3, node)
						local line = g_player_mgr:get_char_line(char_id)
						return g_server_mgr:send_to_server(line, char_id, CMD_ROCK_MONEY_TREE_CHECK_C, node)
					end
				else
					return g_server_mgr:send_to_server(conn.id, char_id, CMD_ROCK_MONEY_TREE_C, {["result"] = 31334})
				end
			end
		end
	end
	g_server_mgr:send_to_server(conn.id, char_id, CMD_ROCK_MONEY_TREE_C, {["result"] = 31333})
end

function Faction_courtyard_mgr:rock_tree_success(node, pkt)
	local char_id = node and node.char_id
	if char_id then
		local faction_id = node.faction_id
		if faction_id then
			local faction_courtyard = self.courtyard_list[faction_id]
			if faction_courtyard and faction_courtyard:get_money_tree_obj() then
				faction_courtyard:set_money_tree_op_flag(char_id, nil)
				faction_courtyard:rock_money_tree(char_id)
				local line = g_player_mgr:get_char_line(char_id)
				local ret = {}
				ret.result = 0
				local info = faction_courtyard:get_money_tree_info_by_cid(char_id)
				ret.cnt = info[2]
				g_server_mgr:send_to_server(line, char_id, CMD_ROCK_MONEY_TREE_C, ret)
			end
		end
	end
end

function Faction_courtyard_mgr:rock_tree_failed(node, pkt)
	local char_id = node and node.char_id
	if char_id then
		local faction_id = node.faction_id
		if faction_id then
			local faction_courtyard = self.courtyard_list[faction_id]
			if faction_courtyard and faction_courtyard:get_money_tree_obj() then
				faction_courtyard:set_money_tree_op_flag(char_id, nil)
			end
		end
	end
end

----------------------帮派烧香--------------
function Faction_courtyard_mgr:get_censer_info(conn, char_id)
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	if faction ~= nil then
		local faction_id = faction:get_faction_id()
		if faction_id ~= nil then
			local faction_courtyard = self.courtyard_list[faction_id]
			if faction_courtyard == nil then
				faction_courtyard = Faction_courtyard()
				self.courtyard_list[faction_id] = faction_courtyard
			end
			if faction_courtyard:get_censer_obj() == nil then
				faction_courtyard:create_censer_obj()
			end
			local ret = faction_courtyard:get_censer_info_by_cid(char_id)
			ret.result = 0
			debug_print("----------------")
			debug_print(j_e(ret))
			return g_server_mgr:send_to_server(conn.id, char_id, CMD_GET_GANG_INFO_C, ret)
		end
	end
end

-- 上香或者祭拜
function Faction_courtyard_mgr:worship(conn, char_id, act_type, id)
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	if faction ~= nil then
		local faction_id = faction:get_faction_id()
		if faction_id ~= nil then
			local faction_courtyard = self.courtyard_list[faction_id]
			if faction_courtyard and faction_courtyard:get_censer_obj() then
				if act_type == 0 then -- 拜祭
					local e_code = faction_courtyard:baiji(char_id)
					local ret = {}
					ret.result = e_code
					ret.act_type = act_type
					return g_server_mgr:send_to_server(conn.id, char_id, CMD_WORSHIP_C, ret)
				elseif act_type == 1 then -- 上香
					if faction_courtyard:get_censer_op_flag(char_id) == nil then
						
						local e_code = faction_courtyard:check_use_candle(char_id, id)
						if e_code ~= 0 then
							local ret = {}
							ret.result = e_code
							return g_server_mgr:send_to_server(conn.id, char_id, CMD_WORSHIP_C, ret)
						end
						faction_courtyard:set_censer_op_flag(char_id, true)
						local node = {}
						node.char_id = char_id
						node.id = id -- 香的id
						node.act_type = act_type
						node.faction_id = faction_id
						node.level = faction:get_book_level()
						g_sock_event_mgr:add_event_count(char_id, CMD_WORSHIP_CHECK_S, self, self.worship_success, self.worship_failed, node, 3, node)
						return g_server_mgr:send_to_server(conn.id, char_id, CMD_WORSHIP_CHECK_C, node)
					end
				end
			end
		end
	end
end

function Faction_courtyard_mgr:worship_success(node, pkt)
	local char_id = node and node.char_id
	if char_id then
		local faction_id = node.faction_id
		if faction_id then
			local faction_courtyard = self.courtyard_list[faction_id]
			if faction_courtyard and faction_courtyard:get_censer_obj() then
				faction_courtyard:set_censer_op_flag(char_id, nil)
				faction_courtyard:use_candle(char_id, node.id, node.level) -- 上香操作
				local line = g_player_mgr:get_char_line(char_id)
				local ret = {}
				ret.result = 0
				ret.act_type = node.act_type
				ret.id = node.id
				ret.level = node.level
				g_server_mgr:send_to_server(line, char_id, CMD_WORSHIP_C, ret)
				self:update_censer_info(faction_id)
			end
		end
	end
end

function Faction_courtyard_mgr:worship_failed(node, pkt)
	local char_id = node and node.char_id
	if char_id then
		local faction_id = node.faction_id
		if faction_id then
			local faction_courtyard = self.courtyard_list[faction_id]
			if faction_courtyard and faction_courtyard:get_censer_obj() then
				faction_courtyard:set_censer_op_flag(char_id, nil)
			end
		end
	end
end

function Faction_courtyard_mgr:update_censer_info(faction_id)
	local faction = g_faction_mgr:get_faction_by_fid(faction_id)
	if faction then
		local faction_id = faction:get_faction_id()
		if faction_id ~= nil then
			local faction_courtyard = self.courtyard_list[faction_id]
			if faction_courtyard and faction_courtyard:get_censer_obj() then
				local faction_member_list = faction:get_player_list()
				for char_id, v in pairs(faction_member_list or {}) do
					if g_player_mgr:is_online_char(char_id) then
						local message = faction_courtyard:get_censer_info_by_cid(char_id)
						message.result = 0
						local line = g_player_mgr:get_char_line(char_id)
						g_server_mgr:send_to_server(line, char_id, CMD_GET_GANG_INFO_C, message)
					end
				end
			end
		end
	end
end

-- 退帮时清除拜祭标记
function Faction_courtyard_mgr:clear_baiji_flag(faction_id, char_id)
	local faction = g_faction_mgr:get_faction_by_fid(faction_id)
	if faction then
		local faction_id = faction:get_faction_id()
		if faction_id ~= nil then
			local faction_courtyard = self.courtyard_list[faction_id]
			if faction_courtyard and faction_courtyard:get_censer_obj() then
				faction_courtyard:clear_baiji_flag(char_id)
			end
		end
	end
end


-------定时器
function Faction_courtyard_mgr:get_reset_click_param(tm)
	return self, self.reset_faction_courtyard, tm, nil
end

-- 第二天重置次数
function Faction_courtyard_mgr:reset_faction_courtyard()
	for faction_id, faction_courtyard in pairs(self.courtyard_list or {}) do
		local update_time = faction_courtyard:get_update_time()
		if os.date("%x", update_time) ~= os.date("%x", ev.time) then
			faction_courtyard:set_update_time(ev.time)
			faction_courtyard:reset()
			self:update_faction_money_tree(faction_id)
			self:update_censer_info(faction_id)
		end
	end
end

function Faction_courtyard_mgr:get_data_click_param(tm)
	return self, self.save_faction_courtyard, tm, nil
end

function Faction_courtyard_mgr:save_faction_courtyard()
	for faction_id, faction_courtyard in pairs(self.courtyard_list or {}) do
		local data_update_time = faction_courtyard:get_data_update_time()
		if data_update_time + crypto.random(1,180) * 4 <= ev.time then
			faction_courtyard:set_data_update_time(ev.time)
			Faction_courtyard_db:update_one(faction_id)
		end
	end
end

function Faction_courtyard_mgr:exit_save_faction_courtyard()
	for faction_id, faction_courtyard in pairs(self.courtyard_list or {}) do
		Faction_courtyard_db:update_one(faction_id)
	end
end