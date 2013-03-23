-- 帮派香炉

--local debug_print = print
local debug_print = function() end

local MAX_RECORD_NUM = 6

local censer_config = require("config.loader.faction_censer_loader")

Censer_obj = oo.class(nil, "Censer_obj")

function Censer_obj:__init()
	self.player_list = {} -- 上香列表 char_id:{id--已上香的id: true}
	self.record_list = {} -- 最近记录 {char_id, id--香的id, addValue--灵气增加值, time--上香时间}
	self.record_num = 0
	self.nimbus = 0 -- 当前灵气值
	self.jibai = {} -- 拜祭标记
	--self.update_time = ev.time -- 隔天重置使用
	--self.data_update_time = ev.time -- 定时存储使用,不入库
	self.player_flag = {} -- 锁
end

function Censer_obj:get_player_flag(char_id)
	return self.player_flag[char_id]
end

function Censer_obj:set_player_flag(char_id, flag)
	self.player_flag[char_id] = flag
end

function Censer_obj:check_use(char_id, id)
	if self.player_list[char_id] ~= nil then
		if self.player_list[char_id][id] ~= nil then
			return 31342 -- 今日已经使用过该香
		end
	end
	return 0
end

-- 使用香
function Censer_obj:use_candle(char_id, id, level)
	local flag
	if self.player_list[char_id] == nil then
		self.player_list[char_id] = {}
	end
	self.player_list[char_id][id] = true
	local addValue = censer_config.get_nimbus(id) or 0
	self.nimbus = self.nimbus + addValue
	if self.nimbus > censer_config.get_max_nimbus(level) then
		self.nimbus = self.nimbus % censer_config.get_max_nimbus(level)
		flag = 1 -- 灵气满了
	end
	local record = {char_id, id, addValue, ev.time}
	self:add_record_to_record_list(record)
	return flag
end

function Censer_obj:add_record_to_record_list(record)
	self.record_list[self.record_num + 1] = record or {}
	table.sort(self.record_list, function(a, b) return a[4] > b[4] end)
	self.record_num =  self.record_num + 1
	if self.record_num > MAX_RECORD_NUM then
		self.record_num = MAX_RECORD_NUM
	end
	self.record_list[MAX_RECORD_NUM + 1] = nil
end

function Censer_obj:get_net_record_list()
	local ret = {}
	local all_player_list = g_player_mgr:get_all_char() -- 获取所有玩家列表
	for i = 1, MAX_RECORD_NUM do
		local v = self.record_list[i]
		if v then
			local char_id = v[1]
			local char_name = all_player_list[char_id]["char_nm"] -- 获取玩家名字
			local id = v[2]
			local addValue = v[3]
			local time = v[4]
			local record = {char_name, id, addValue, time}
			table.insert(ret, record)
		else
			break
		end
	end
	return ret
end

-- 设置能否祭拜的标记
function Censer_obj:set_jibai_flag(char_id, flag)
	self.jibai[char_id] = flag
end

function Censer_obj:get_jibai_flag(char_id)
	if self.jibai[char_id] == nil then
		return 1
	elseif self.jibai[char_id] == true then
		return 0
	end
end

function Censer_obj:get_nimbus()
	return self.nimbus
end

function Censer_obj:get_net_player_list(char_id)
	local ret = {}
	for id, v in pairs(self.player_list[char_id] or {}) do
		table.insert(ret, id)
	end
	return ret
end

function Censer_obj:unserialize_to_db(pack)
	if pack then
		if pack.player_list then
			self.player_list = self:spec_player_list_unserialize_to_db(pack.player_list)
			self.record_list = pack.record_list or {}
			self.record_num = table.getn(self.record_list) or 0
			self.jibai = self:spec_jibai_unserialize_to_db(pack.jibai)
			self.nimbus = pack.nimbus or 0
		--	self.update_time = pack.update_time or ev.time
			return 0
		end
	end
end

-- 祭拜标志列表 char_id:true  数据库格式{char_id, char_id,...}
function Censer_obj:spec_jibai_unserialize_to_db(jibai)
	local ret = {}
	for _, char_id in pairs(jibai or {}) do
		ret[char_id] = true
	end
	return ret
end

-- 上香列表 char_id:{id:true , id:true,...} 数据库格式:{char_id, {id, id,...}}
function Censer_obj:spec_player_list_unserialize_to_db(player_list)
	local ret = {}
	for _, v in pairs(player_list or {}) do
		local char_id = v[1]
		ret[char_id] = {}
		for _, id in pairs(v[2] or {}) do
			ret[char_id][id] = true
		end
	end
	return ret
end

function Censer_obj:serialize_to_db()
	local ret = {}
	ret.player_list = self:spec_player_list_serialize_to_db(self.player_list)
	ret.record_list = self.record_list
	ret.jibai = self:spec_jibai_serialize_to_db(self.jibai)
	ret.nimbus = self.nimbus
--	ret.update_time = self.update_time
	return ret
end

-- 祭拜标志列表 char_id:true  数据库格式{char_id, char_id,...}
function Censer_obj:spec_jibai_serialize_to_db(list)
	local ret = {}
	for char_id, v in pairs(list or {}) do
		if v == true then
			table.insert(ret, char_id)
		end
	end
	return ret
end

-- 上香列表 char_id:{id:true , id:true,...} 数据库格式:{char_id, {id, id,...}}
function Censer_obj:spec_player_list_serialize_to_db(list)
	local ret = {}
	for char_id, v in pairs(list or {}) do
		local player = {}
		player[1] = char_id
		player[2] = {}
		for id, d in pairs(v) do
			table.insert(player[2], id)
		end
		table.insert(ret, player)
	end
	return ret
end

function Censer_obj:clear_player_list()
	self.player_list = {}
end




