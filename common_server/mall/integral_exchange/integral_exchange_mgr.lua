

local _config = require("mall.integral_exchange.integral_exchange_loader")
local database = "exchange_gitf"
local one_week = 8*24*60*60

Integral_exchange_mgr = oo.class(nil,"Integral_exchange_mgr")


function Integral_exchange_mgr:__init()
	self.char_l = {}
	self.count_l = {}
	self.times_l = {}
	self:load_db()
end

function Integral_exchange_mgr:load_db()
	local dbh = f_get_db()
	local field = "{count_l:1,times_l:1}"
	local query = string.format("{char_id:%d}",0)
	local row,err = dbh:select_one(database,field,query)
	self.count_l = row and row.count_l or {}
	self.times_l = row and row.times_l or {}
	self.times_l[1] = row and row.times_l and row.times_l[1] or tonumber(f_get_sunday())+one_week --周
	self.times_l[2] = row and row.times_l and row.times_l[2] or tonumber(os.date("%Y%m",ev.time)) --月
	self.times_l[3] = row and row.times_l and row.times_l[3] or tonumber(f_get_tomorrow())	--日
end

function Integral_exchange_mgr:update_data()
	local dbh = f_get_db()
	local data = {}
	data.count_l = self.count_l
	data.times_l = self.times_l
	local query = string.format("{char_id:%d}",0)
	local row,err = dbh:update(database,query,Json.Encode(data),true)	
end

function Integral_exchange_mgr:check_count()
	local now_month = tonumber(os.date("%Y%m",ev.time))
	local now = ev.time
	local update_flag = false

	--每日清空
	if now > self.times_l[3] then
		self.times_l[3] = tonumber(f_get_tomorrow())
		self.count_l[3] = {}
		update_flag = true
	end

	--周日清空
	if now > self.times_l[1] then
		self.times_l[1] = tonumber(f_get_sunday())+one_week
		self.count_l[1] = {}
		update_flag = true
	end

	--月底清空
	if now_month > self.times_l[2] then
		self.times_l[2] = now_month
		self.count_l[2] = {}
		update_flag = true
	end
	if update_flag then
		self:update_data()
	end
end

--兑换信息
function Integral_exchange_mgr:get_info(char_id)
	self:check_count()
	local obj = self:get_obj(char_id)
	local ret = obj:get_info()
	return ret
end

function Integral_exchange_mgr:get_obj(char_id)
	if not self.char_l[char_id] and char_id > 0 then
		local dbh = f_get_db()
		local query = string.format("{char_id:%d}",char_id)
		local fields = "{list:1}"
		local row,err = dbh:select_one(database,fields,query)
		local obj = Integral_exchange_obj(char_id)
		if row and err == 0 then		
			obj:clone(row.list)
		end 
		self.char_l[char_id] = obj
	end
	return self.char_l[char_id]
end

--退出保存注销
function Integral_exchange_mgr:logout(char_id)
	local obj = self.char_l[char_id]
	if obj then
		obj:logout()
	end
	self.char_l[char_id] = nil
end

--兑换
function Integral_exchange_mgr:exchange_gift(char_id,pkt)
	local catalog_id = tonumber(pkt.catalog_id)
	local exchange_id = tostring(pkt.exchange_id)
	local list = nil
	local ret = {}
	ret.result = 0
	for k,v in pairs(_config.IntegralExchangeTable[catalog_id] or {}) do
		if v.id == exchange_id then
			list = v
		end
	end
	if not list then
		ret.result = 60009
		return ret
	end
	local obj = self:get_obj(char_id)
	local obj_info = obj:get_info()
	local jade = 0
	local times = obj:get_exchange(catalog_id,exchange_id)
	if catalog_id == 1 then
		jade = obj_info.week_jade	
	elseif catalog_id == 2 then
		jade = obj_info.month_jade
	elseif catalog_id == 3 then
		jade = obj_info.date_jade
	end
	--充值不够
	if jade < list.need_jade then
		ret.result = 60010
		return ret
	end
	if times+1 > list.exchange_times then
		ret.result = 60012
		return ret
	end 
	ret.exchange_gift = list.exchange_gift
	ret.need_integral = list.need_integral
	ret.catalog = catalog_id
	ret.id = exchange_id
	return ret
end

--充值
function Integral_exchange_mgr:add_jade(map_id,char_id,counts)
	local obj = self:get_obj(char_id)
	local ret = obj:add_jade(counts)
	ret.result = 0
	g_server_mgr:send_to_server(map_id,char_id,CMD_C2M_EXCHANGE_GIFT_INFO_ANS,ret)
end

--更新次数
function Integral_exchange_mgr:get_exchange_times(char_id)
	self:check_count()
	local obj = self:get_obj(char_id)
	local list = obj:get_exchange_times()
	for k,v in pairs(list or {}) do
		self.count_l[k] = self.count_l[k] or {} 
		for key,value in pairs(v or {}) do
			self.count_l[k][value[2]] = self.count_l[k][value[2]] or 0
			list[k][key][4] = self.count_l[k][value[2]]
		end
	end
	return list
end

--添加次数
function Integral_exchange_mgr:add_exchange_times(map_id,char_id,catalog_id,exchange_id,counts)
	self:check_count()
	catalog_id = tonumber(catalog_id)
	exchange_id = tostring(exchange_id)

	local obj = self:get_obj(char_id)
	obj:add_exchange_times(catalog_id,exchange_id,counts)
	local total_counts = self:get_total_counts(catalog_id,exchange_id)
	self.count_l[catalog_id][exchange_id] = total_counts+counts
	self:update_data()

	local ret = {}
	ret.result = 0
	ret.list = self:get_exchange_times(char_id)
	g_server_mgr:send_to_server(map_id,char_id,CMD_M2C_EXCHANGE_GIFT_UPDATE_REQ,ret)
end

function Integral_exchange_mgr:get_total_counts(catalog_id,exchange_id)
	self.count_l[catalog_id] =  self.count_l[catalog_id] or {}
	self.count_l[catalog_id][exchange_id] = self.count_l[catalog_id][exchange_id] or 0
	return self.count_l[catalog_id][exchange_id]
end

