-- 帮派摇钱树

--local debug_print = print
local debug_print = function() end

local money_tree_config = require("config.loader.faction_courtyard_loader")

Money_tree_obj = oo.class(nil, "Money_tree_obj")

function Money_tree_obj:__init()
	self.player_list = {} -- 摇树的玩家列表
	--self.update_time = ev.time -- 隔天重置使用
	--self.data_update_time = ev.time -- 定时存储使用,不入库
	self.player_flag = {} -- 锁
end

function Money_tree_obj:get_player_flag(char_id)
	return self.player_flag[char_id]
end

function Money_tree_obj:set_player_flag(char_id, flag)
	self.player_flag[char_id] = flag
end
--[[
function Money_tree_obj:get_data_update_time()
	return self.data_update_time
end

function Money_tree_obj:set_data_update_time(data_update_time)
	self.data_update_time = data_update_time
end
--]]
function Money_tree_obj:serialize_to_net()
	local ret = {}
	ret.player_list = self.player_list -- 摇树的玩家列表
	return ret
end
--[[
function Money_tree_obj:get_update_time()
	return self.update_time
end

function Money_tree_obj:set_update_time(update_time)
	self.update_time = update_time
end
--]]

-- 清除摇树的玩家列表，第二日时调用,用来重置玩家的摇树次数
function Money_tree_obj:clear_player_list()
	self.player_list = {}
end

-- 获取今日已经摇树的次数
function Money_tree_obj:get_rock_cnt(char_id)
	local char_id_str = tostring(char_id)
	return self.player_list[char_id_str] or 0
end

-- 获取今日剩余的摇树
function Money_tree_obj:get_last_rock_cnt(char_id, vip_level)
	--local cnts = money_tree_config.get_times(vip_level)
	local cnts = money_tree_config.get_max_rock_limit(vip_level)
	if cnts then
		return math.max(0, cnts - self:get_rock_cnt(char_id))
	end
end

-- 摇铜券树
function Money_tree_obj:rock(char_id)
	local char_id_str = tostring(char_id)
	if self.player_list[char_id_str] == nil then
		self.player_list[char_id_str] = 0
	end
	self.player_list[char_id_str] = self.player_list[char_id_str] + 1 -- 今日摇树次数+1
end

-- 重置玩家摇树的次数
function Money_tree_obj:reset_times()
	self.player_list = {}
end

function Money_tree_obj:serialize_to_db()
	local ret = {}
	ret.player_list = self:spec_player_list_serialize_to_db(self.player_list)
	--ret.update_time = self.update_time
	return ret
end

function Money_tree_obj:spec_player_list_serialize_to_db(player_list)
	local ret = {}
	for k, v in pairs(player_list or {}) do
		local char_id = tonumber(k)
		local cnt = v
		local player = {char_id, cnt}
		table.insert(ret, player)
	end
	return ret
end

-- 从数据库加载
function Money_tree_obj:unserialize_to_db(pack)
	if pack then
		if pack.player_list then
			self.player_list = self:spec_unserialize_to_db(pack.player_list)
		--	self.update_time = pack.update_time or ev.time
			return 0
		end
	end
end

function Money_tree_obj:spec_unserialize_to_db(player_list)
	local ret = {}
	for k, v in pairs(player_list or {}) do
		local char_id_str = tostring(v[1])
		local cnt = v[2]
		ret[char_id_str] = cnt
	end
	return ret
end