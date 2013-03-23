
Consum_ret_mgr = oo.class(nil, "Consum_ret_mgr")

function Consum_ret_mgr:__init()
	self.consum_ret_con = Consum_ret_container()
	self:load_all()
end

function Consum_ret_mgr:load_all()
	local e_code, rows = Consum_ret_db:load_all()
	if e_code == 0 then
		for _, v in pairs(rows or {}) do
			local char_id = v.char_id
			local info = v.info
			if char_id and info then
				self:load_char_info(char_id, info)
			end
		end
	end
end

function Consum_ret_mgr:get_total_cost(consum_type, char_id)
	return self.consum_ret_con:get_total_cost(consum_type, char_id)
end

function Consum_ret_mgr:add_cost(consum_type, char_id, money)
	local e_code = self.consum_ret_con:add_cost(consum_type, char_id, money)
	if e_code ~= 0 then
		return e_code
	end
	Consum_ret_db:update(char_id) -- 操作入库
	self:get_char_info_by_type(consum_type, char_id)
	return 0
end

function Consum_ret_mgr:load_char_info(char_id, pack)
	self.consum_ret_con:load_char_info(char_id, pack)
end

function Consum_ret_mgr:serialize_char_to_db(char_id)
	return self.consum_ret_con:serialize_one_to_db(char_id)
end

function Consum_ret_mgr:get_char_info_by_type(consum_type, char_id)
	if g_player_mgr:is_online_char(char_id) then
		local ret = {}
		ret.info = self.consum_ret_con:get_char_info_by_type(consum_type, char_id) or {}
		ret.id = consum_type
		ret.result = 0
	
		local line = g_player_mgr:get_char_line(char_id)
		return g_server_mgr:send_to_server(line, char_id, CMD_GET_CONSUM_RET_INFO_C, ret)
	end
end

function Consum_ret_mgr:get_reward_by_type(consum_type, char_id, index)
	if g_player_mgr:is_online_char(char_id) then
		local e_code, reward = self.consum_ret_con:get_reward_by_type(consum_type, char_id, index)
		local line = g_player_mgr:get_char_line(char_id)
		if e_code ~= 0 then
			local ret = {}
			ret.id = consum_type
			ret.result = e_code
			return  g_server_mgr:send_to_server(line, char_id, CMD_GET_CONSUM_RET_REWARD_C, ret)
		end

		local node = {}
		node.char_id = char_id
		node.index = index
		node.id = consum_type
		node.reward = reward
		node.result = 0
		g_sock_event_mgr:add_event_count(char_id, CMD_GET_CONSUM_RET_CHECK_S, self, self.get_reward_success, self.get_reward_failed, node, 6, node)
		
		Consum_ret_db:update(char_id) -- 操作入库

		return g_server_mgr:send_to_server(line, char_id, CMD_GET_CONSUM_RET_REWARD_C, node)
	end
end

function Consum_ret_mgr:get_reward_success(node, pkt)
	if node and pkt then
		local char_id = node.char_id
		local consum_type = node.id
		if char_id and consum_type then
			self.consum_ret_con:unlock_char(consum_type, char_id) -- 解锁
			if pkt.result and pkt.result~=0 then -- 某些错误导致添加物品失败
				self.consum_ret_con:reset_reward_state_by_type(consum_type, char_id, node.index) -- 重置为未领取状态

				Consum_ret_db:update(char_id) -- 操作入库
				if g_player_mgr:is_online_char(char_id) then
					local ret = {}
					ret.result = pkt.result
					ret.id = consum_type
					local line = g_player_mgr:get_char_line(char_id)
					g_server_mgr:send_to_server(line, char_id, CMD_GET_CONSUM_RET_REWARD_C, ret)
				end

			end
			self:get_char_info_by_type(consum_type, char_id)
		end
	end
end

function Consum_ret_mgr:get_reward_failed(node, pkt)
	if node then
		local char_id = node.char_id
		local consum_type = node.id
		if char_id and consum_type then
			self.consum_ret_con:unlock_char(consum_type, char_id) -- 解锁
		end
	end
end







