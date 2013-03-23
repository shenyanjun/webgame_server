
Faction_courtyard = oo.class(nil, "Faction_courtyard")

function Faction_courtyard:__init()
	self.money_tree_obj = nil
	self.censer_obj = nil
	self.update_time = ev.time -- 入库
	self.data_update_time = ev.time -- 不入库
end

function Faction_courtyard:reset()
	if self.money_tree_obj then
		self.money_tree_obj:clear_player_list()
	end
	if self.censer_obj then
		self.censer_obj:clear_player_list()
	end
end

function Faction_courtyard:get_update_time()
	return self.update_time
end

function Faction_courtyard:set_update_time(update_time)
	self.update_time = update_time
end

function Faction_courtyard:get_data_update_time()
	return self.data_update_time
end

function Faction_courtyard:set_data_update_time(data_update_time)
	self.data_update_time = data_update_time
end

function Faction_courtyard:get_censer_op_flag(char_id)
	return self.censer_obj:get_player_flag(char_id)
end

function Faction_courtyard:set_censer_op_flag(char_id, flag)
	self.censer_obj:set_player_flag(char_id, flag)
end

function Faction_courtyard:get_money_tree_op_flag(char_id)
	return self.money_tree_obj:get_player_flag(char_id)
end

function Faction_courtyard:set_money_tree_op_flag(char_id, flag)
	self.money_tree_obj:set_player_flag(char_id, flag)
end

function Faction_courtyard:create_money_tree_obj()
	self.money_tree_obj = Money_tree_obj()
end

function Faction_courtyard:create_censer_obj()
	self.censer_obj = Censer_obj()
end

function Faction_courtyard:get_money_tree_obj()
	return self.money_tree_obj
end

function Faction_courtyard:get_censer_obj()
	return self.censer_obj
end

function Faction_courtyard:unserialize_to_db(pack)
	if pack then
		self.update_time = pack.update_time or ev.time
		if pack.money_tree_obj then
			local money_tree_obj = Money_tree_obj()
			local e_code = money_tree_obj:unserialize_to_db(pack.money_tree_obj)
			if e_code == 0 then
				self.money_tree_obj = money_tree_obj
			end
		end
		if pack.censer_obj then
			local censer_obj = Censer_obj()
			local e_code = censer_obj:unserialize_to_db(pack.censer_obj)
			if e_code == 0 then
				self.censer_obj = censer_obj
			end
		end
	end
end

function Faction_courtyard:get_money_tree_info_by_cid(char_id)
	local ret = {}
	if self.money_tree_obj then
		local faction = g_faction_mgr:get_faction_by_cid(char_id)
		if faction ~= nil then
			ret[1] = faction:get_gold_level() -- 金库等级
			ret[2] = self.money_tree_obj:get_rock_cnt(char_id)
		end
	end
	return ret
end

function Faction_courtyard:get_last_rock_cnt_by_cid(char_id, vip_level)
	return self.money_tree_obj:get_last_rock_cnt(char_id, vip_level)
end

function Faction_courtyard:rock_money_tree(char_id)
	self.money_tree_obj:rock(char_id)
end

function Faction_courtyard:get_censer_info_by_cid(char_id)
	local ret = {}
	if self.censer_obj then
		local faction = g_faction_mgr:get_faction_by_cid(char_id)
		if faction ~= nil then
			ret.info = {}
			ret.info[1] = faction:get_book_level() -- 香炉等级（观星阁等级）
			ret.info[2] = self.censer_obj:get_nimbus() -- 当前灵气值
			ret.info[3] = self.censer_obj:get_net_player_list(char_id) -- 获取已经上过的香列表
			ret.info[4] = self.censer_obj:get_jibai_flag(char_id)
			ret.record = self.censer_obj:get_net_record_list()
		end
	end
	return ret
end

function Faction_courtyard:baiji(char_id)
	if self.censer_obj then
		local faction = g_faction_mgr:get_faction_by_cid(char_id)
		if faction ~= nil then
			if faction:get_dissolve_flag() == 1 then
				return 26047
			end
			if self.censer_obj:get_jibai_flag(char_id) == 0 then
				self.censer_obj:set_jibai_flag(char_id, nil)
				return 0
			else return 31341
			end
		end
	end
	return 31333
end

function Faction_courtyard:check_use_candle(char_id, id)
	if self.censer_obj then
		return self.censer_obj:check_use(char_id, id)
	end
	return 31333
end

function Faction_courtyard:use_candle(char_id, id, level)
	if self.censer_obj then
		local flag = self.censer_obj:use_candle(char_id, id, level)
		if flag == 1 then
			local faction = g_faction_mgr:get_faction_by_cid(char_id)
			if faction then
				local members = faction:get_player_list()
				for char_id, v in pairs(members or {}) do
					self.censer_obj:set_jibai_flag(char_id, true)
				end
			end
		end
	end
end

function Faction_courtyard:serialize_to_db()
	local ret = {}
	ret.update_time = self.update_time or ev.time
	if self.money_tree_obj then
		ret.money_tree_obj = self.money_tree_obj:serialize_to_db()
	end
	if self.censer_obj then
		ret.censer_obj = self.censer_obj:serialize_to_db()
	end
	return ret
end

-- 退帮时清除拜祭标记
function Faction_courtyard:clear_baiji_flag(char_id)
	self.censer_obj:set_jibai_flag(char_id, nil)
end