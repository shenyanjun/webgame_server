
local whole_config = require("config.whole_lost_config")

local db_table = "whole"
--line：线ID，索引
--date：更新时间
--info：掉落控制的具体数据,二维数组[物品id, 数量]

--世界产出控制
Whole_produce = oo.class(nil, "Whole_produce")

local update_time = 43200		--12小时，每天中午12点
local record_time = 600			--10分钟入库

function Whole_produce:__init()
	self.item_list = {}    		--道具可产出信息
	self.item_produce = {}		--道具已产出信息

	self.treasure_list = {}		--藏宝图可产出信息
	self.treasure_produce = {}	--藏宝图已产出信息
end


--------------------------------------数据库操作
function Whole_produce:load()
	local mid_day = f_get_midday()
	if ev.time < mid_day then
		self.date = mid_day - 86400
	else
		self.date = mid_day
	end
	self.update_time = self.date + 86400
	self.record_time = ev.time + record_time
	self:initByconfig()

	local row = self:selectWhole()

	if rows then
		if self.date <= row.date then			--更新时间已过需要重新init
			for k, v in ipairs(row.info or {}) do
				if self.item_list[v[1]] then
					self.item_produce[v[1]] = v[2]
					self.item_list[v[1]] = self.item_list[v[1]] - v[2]
				end
			end

			for k, v in ipairs(row.t_info or {}) do
				if self.treasure_list[v[1]] then
					self.treasure_produce[v[1]] = v[2]
					self.treasure_list[v[1]] = self.treasure_list[v[1]] - v[2]
				end
			end
		end
	end
end

function Whole_produce:initByconfig()
	self.item_list = {}
	self.item_produce = {}
	self.treasure_list = {}		
	self.treasure_produce = {}

	for k, v in pairs(whole_config.list or {}) do
		if not self.item_list[k] or self.item_list[k] > v then
			self.item_list[k] = v
		end
		self.item_produce[k] = 0
	end

	for k, v in pairs(whole_config.treasure_l or {}) do
		if not self.treasure_list[k] or self.treasure_list[k] > v then
			self.treasure_list[k] = v
		end
		self.treasure_produce[k] = 0
	end
end

function Whole_produce:selectWhole()
	local db = f_get_db()
	local query = string.format("{line:%d}", Map_sv)

	local row, e_code = db:select_one(db_table, nil, query)
	if 0 == e_code then
		return row
	else
		print("select_whole Error: ", e_code)
		return nil
	end
end


function Whole_produce:updateWholeproduce()
	local record = {}
	record.date = self.date
	record.line = Map_sv
	record.info = {}
	record.t_info = {}
	local i = 1
	for k, v in pairs(self.item_produce) do
		record.info[i] = {}
		record.info[i][1] = k
		record.info[i][2] = v
		i = i + 1
	end

	i = 1
	for k, v in pairs(self.treasure_produce) do
		record.t_info[i] = {}
		record.t_info[i][1] = k
		record.t_info[i][2] = v
		i = i + 1
	end

	local db = f_get_db()
	local query = string.format("{line:%d}",Map_sv)

	local e_code = db:update(db_table, query, Json.Encode(record), true, false)

	if 0 ~= e_code then
		print("Error: ", e_code)
	end
end

-------------------------------------------计时器
function Whole_produce:get_click_param()
	return self, self.on_timer, 3, nil
end

function Whole_produce:on_timer()
	if ev.time > self.update_time then
		self:initByconfig()
		self.date = self.update_time
		self.update_time = self.update_time + 86400
	end
	if ev.time > self.record_time then
		self:updateWholeproduce()
		self.record_time = self.record_time + record_time
	end
end

-------------------------------------------接口
--怪物掉落
function Whole_produce:add_lost_item(item_id)
	if item_id and self.item_list[item_id] ~= nil then
		if self.item_list[item_id] > 0 then
			self.item_list[item_id] = self.item_list[item_id] - 1
			self.item_produce[item_id] = self.item_produce[item_id] + 1
			return true
		else
			return false
		end
	end

	return true
end

--藏宝图掉落
function Whole_produce:check_lost_item_l(item_list)
	local except_l = {}

	for k, v in ipairs(item_list or {}) do
		if self.treasure_list[v] and self.treasure_list[v] < 1 then
			table.insert(except_l, k)
		end
	end

	return except_l
end
function Whole_produce:add_lost_item_l(item_list)
	for k, item_id in ipairs(item_list) do
		if self.treasure_list[item_id] then
			self.treasure_list[item_id] = self.treasure_list[item_id] - 1
			self.treasure_produce[item_id] = self.treasure_produce[item_id] + 1
		end
	end
end


