
local _config = require("mall.integral_exchange.integral_exchange_loader")
local database = "exchange_gitf"
local one_week = 8*24*60*60

Integral_exchange_obj = oo.class(nil,"Integral_exchange_ojb")

function Integral_exchange_obj:__init(char_id)
	self.char_id = char_id
	self.date_jade = 0
	self.week_jade = 0
	self.month_jade = 0

	self.times_l = {}

	self.date_date = tonumber(f_get_tomorrow())
	self.week_date = f_get_sunday()+ one_week
	if 0 == tonumber(os.date("%w",ev.time)) then
		self.week_date = f_get_today() + 24*60*60	--隔周更新
	end
	self.month_date = tonumber(os.date("%Y%m",ev.time))
end                                                                                                                                                        

--玩家退出，保存信息
function Integral_exchange_obj:logout()
	self:update_char()
end

--存盘
function Integral_exchange_obj:update_char()
	local dbh = f_get_db()
	local data = {}
	data.char_id = self.char_id
	data.list = {}

	data.list.date_jade = self.date_jade
	data.list.week_jade = self.week_jade
	data.list.month_jade = self.month_jade
	
	data.list.times_l = self.times_l
	
	data.list.date_date = self.date_date
	data.list.week_date = self.week_date
	data.list.month_date = self.month_date
	local query = string.format("{char_id:%d}",self.char_id)
	local fields = "{list:1}"
	local row ,err = dbh:select_one(database,fields,query)
	if row and err==0 then
		dbh:update(database,query,Json.Encode(data))
	else
		dbh:insert(database,Json.Encode(data))
	end
end

--克隆
function Integral_exchange_obj:clone(data)
	self.times_l = data.times_l
	self.date_jade = data.date_jade or 0
	self.week_jade = data.week_jade
	self.month_jade = data.month_jade
	
	self.date_date = data.date_date or tonumber(f_get_tomorrow())
	self.week_date = data.week_date
	self.month_date = data.month_date
end

--充值
function Integral_exchange_obj:add_jade(counts)
	self:check_clear()
	self.date_jade = self.date_jade+counts
	self.week_jade = self.week_jade+counts
	self.month_jade = self.month_jade+counts

	local ret = {}
	ret.date_jade = self.date_jade
	ret.week_jade = self.week_jade
	ret.month_jade = self.month_jade
	self:update_char()
	return ret
end

--增加兑换次数
function Integral_exchange_obj:add_exchange_times(catalog,id,count)
	self:check_clear()
	local times = self:get_exchange(catalog,id)
	self.times_l[catalog][id] = times+count
	self:update_char()
end

--获取判断信息
function Integral_exchange_obj:get_info()
	self:check_clear()
	local list = {}
	list.date_jade = self.date_jade
	list.week_jade = self.week_jade
	list.month_jade = self.month_jade
	return list
end


--每周日，每月1号清空
function Integral_exchange_obj:check_clear()
	local now_month = tonumber(os.date("%Y%m",ev.time))
	local now = ev.time
	local update_flag = false

	--每日清空
	if now > self.date_date then
		self.date_date = tonumber(f_get_tomorrow())
		self.date_jade = 0
		self.times_l[3] = {}
		update_flag = true
	end

	--周日清空
	if now > self.week_date then
		self.week_date = tonumber(f_get_sunday())+one_week	--每周更新
		if 0 == tonumber(os.date("%w",ev.time)) then
			self.week_date = f_get_today(ev.time)+24*60*60	--隔周更新
		end
		self.week_jade = 0
		self.times_l[1] = {}
		update_flag = true
	end

	--月底清空
	if now_month > self.month_date then
		self.month_date = now_month
		self.month_jade = 0
		self.times_l[2] = {}
		update_flag = true
	end

	if update_flag then
		self:update_char()
	end
end


--更新
function Integral_exchange_obj:get_exchange_times()
	local list = {}
	for k,v in pairs(_config.IntegralExchangeTable or {}) do
		list[k] = {}
		if not self.times_l[k] then 
			self.times_l[k] = {}
		end

		for key,value in pairs(v) do
			
			if not self.times_l[k][value.id] then
				self.times_l[k][value.id] = 0
			end
			local count = math.max(value.exchange_times-self.times_l[k][value.id],0)
			local ret = {}
			ret[1] = k
			ret[2] = tostring(value.id)
			ret[3] = count
			list[k][key] = ret
		end 
	end
	return list
end

--次数
function Integral_exchange_obj:get_exchange(catalog_id,exchange_id)

	if not self.times_l[catalog_id] then
		self.times_l[catalog_id] = {}
	end
	if not self.times_l[catalog_id][exchange_id] then
		self.times_l[catalog_id][exchange_id] = 0
	end
	return self.times_l[catalog_id][exchange_id]
end