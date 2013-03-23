

require("mall.limit_obj")
local mall_limit_loader = require("mall.limit_loader")
local mall_limit_loader_fest = require("mall.limit_loader_fest")
local database = "limit_mall"
local sell_max = 4

Limit_mgr = oo.class(nil,"Limit_mgr")
local one_hour = 60*60


function Limit_mgr:__init()
	self.item_l = {}
	self.count_l = {}
	self.normal_l = {}
	self.fest_l = {}
	self.fest_date = 0
	self.max = 0
	self.rank = nil
	self.next_time = nil
end

--购买列表
function Limit_mgr:get_list()
	local ret = self:serialize_to_net()
	return ret
end

--购买
function Limit_mgr:buy_item(char_id,pkt)
	local ret = {}
	ret.error = 0
	local item_id =  tonumber(pkt.item_id)
	local number = tonumber(pkt.number)
	local item_valid = false
	local list = {}
	for k,v in pairs(self.item_l or {}) do
		if v:get_id() == item_id then
			list = self:get_item_list(v)
			if number <= (self:get_total_count(list)-v:get_sell_count()) and ev.time < v:get_end_time() then
				item_valid = true
			elseif number > (self:get_total_count(list)-v:get_sell_count()) then
				item_valid = false
				ret.error = 60006
			elseif ev.time >= v:get_end_time() then
				item_valid = false
				ret.error = 60007
			end
		end
	end
	if not item_valid then
		if ret.error == 0 then
			ret.error = 60005
		end
		return ret
	end

	local count_valid = false
	local limit_count = self:get_limit_count(list)
	if self:get_buy_count(item_id,char_id)+number <= limit_count then
		count_valid = true
	end
	if not count_valid then
		ret.error = 60004
		return  ret
	end

	ret.number = number
	ret.item_id = item_id
	ret.currency = pkt.currency
	ret.price = self:get_price(list)
	ret.name = self:get_name(list)
	ret.day = pkt.day
	ret.line = pkt.line

	ret.openid = pkt.openid
	ret.openkey = pkt.openkey
	ret.serverid = pkt.serverid
	ret.pf = pkt.pf
	ret.pfkey = pkt.pfkey
	
	if ret.error ~= 0 then
		return ret
	end

	--if pkt.day and pkt.item_id then
		--e_code,item_obj = Item_factory.create(tonumber(pkt.item_id))
		--if not item_obj then return end
		--local e_code,price = item_obj:get_cost(tostring(pkt.day),1)
		--if e_code ~= 0 then 
			--return e_code
		--end	
		--ret.price = price
	--end

	if not g_currency_mgr:currency_id_exist(char_id) then
		
		g_currency_mgr:add_currency_id(char_id, ret, char_id, 3)
		return nil
	end
	return 20509
end

function Limit_mgr:get_buy_count(item_id,char_id)
	if not self.count_l[item_id]then
		self.count_l[item_id] = {}
	end
	if not self.count_l[item_id][char_id] then
		self.count_l[item_id][char_id] = 0
	end
	return self.count_l[item_id][char_id]
end

--获取列表
function Limit_mgr:get_item_list(obj)
	local list = {}
	if self.fest_date == 0 then
		if obj:get_backup() == 1 then
			list = mall_limit_loader.MallLimitTable[self.rank].backup_list[obj:get_index()]
		else
			list = mall_limit_loader.MallLimitTable[self.rank].item_list[obj:get_index()]
		end
	else
		list = mall_limit_loader_fest.MallLimitFestItemTable[self.fest_date][obj:get_index()]
	end
	return list
end


function Limit_mgr:get_total_count(list)
	return list.total_count or 0
end


function Limit_mgr:get_limit_count(list)
	return list.limited_count
end


function Limit_mgr:get_price(list)
	return list.new_price
end


function Limit_mgr:get_name(list)
	return list.name
end

--减少
function Limit_mgr:dec_item(char_id,pkt)

	for k,v in pairs(self.item_l or {}) do
		if v:get_id() == pkt.item_id then
			v:add_sell_count(pkt.number)
		end
	end
	local count = self:get_buy_count(pkt.item_id,char_id)
	self.count_l[pkt.item_id][char_id] = count+pkt.number
	local ret = self:serialize_to_net()
	self:update_db_data()
	return ret
end


function Limit_mgr:update_db_data()
	local dbh = f_get_db()
	local data = {}
	local normal_l = {}
	for i,v in pairs(self.normal_l or {}) do
		normal_l[i] = {}
		normal_l[i] = v:serialize_to_db()
	end
	local fest_l = {}
	for i,v in pairs(self.fest_l or {}) do
		fest_l[i] = {}
		fest_l[i] = v:serialize_to_db()
	end
	data.normal_l = normal_l
	data.fest_l = fest_l
	data.rank = self.rank
	data.max = self.max
	data.next_time = self.next_time
	data.fest_date = self.fest_date
	local query = string.format("{limit_id:%d}",1)
	local e_code = dbh:update(database,query,Json.Encode(data),true)
end


function Limit_mgr:serialize_to_net()
	local date = os.date("%m%d",ev.time)
	self:create_list(tonumber(date))
	local item_list = {}
	for i,v in pairs(self.item_l or {}) do
		local list = self:get_item_list(v)
		item_list[i] = {}
		item_list[i].item_id = v:get_id()
		item_list[i].name = list.name
		item_list[i].price_old = list.original_price
		item_list[i].price = {0,0,0,0,0}

		local new_price = list.new_price
		local currency = list.currency
		if currency == 2 then
			item_list[i].price = {0,0,new_price,0,0}
		elseif currency == 3 then
			item_list[i].price = {0,new_price,new_price,0,0}
		elseif currency == 1 then 
			item_list[i].price = {0,new_price,0,0,0}
		elseif currency == 4 then
			item_list[i].price = {0,0,0,0,new_price}
		end
		item_list[i].count = math.max(list.total_count-v:get_sell_count(),0)
		item_list[i].time = math.max(v:get_end_time()-ev.time,0)		
	end
	return item_list
end


function Limit_mgr:create_list(date)
	if self.next_time == nil then  --开服、重启
		if self:db_load() ~= 0 then
			self:update(date)
			self.next_time = self:get_next_time()	
			self:db_insert()
		end
	else	--平时
		if ev.time < self.next_time then return end
		self:update(date)
		self.next_time = self:get_next_time()
		self:update_db_data()
	end
end



function Limit_mgr:db_insert()
	local dbh = f_get_db()
	local data = {}
	local normal_l = {}
	for i,v in pairs(self.normal_l or {}) do
		normal_l[i] = {}
		normal_l[i] = v:serialize_to_db()
	end
	local fest_l = {}
	for i,v in pairs(self.fest_l or {}) do
		fest_l[i] = {}
		fest_l[i] = v:serialize_to_db()
	end
	data.limit_id = 1
	data.normal_l = normal_l
	data.fest_l = fest_l
	data.rank = self.rank
	data.max = self.max
	data.next_time = self.next_time
	data.fest_date = self.fest_date
	
	local query = string.format("{limit_id:%d}",1)
	local fields = "{rank:1,max:1,fest_date:1,normal_l:1,fest_l:1,next_time:1}"
	local row,e_code = dbh:select_one(database,fields,query)
	if row ~= nil or e_code == 0 then
		local e_code = dbh:update(database,query,Json.Encode(data),true)
	else
		local e_code = dbh:insert(database,Json.Encode(data))
	end
end

function Limit_mgr:db_load()
	local dbh = f_get_db()
	local query = string.format("{limit_id:%d}",1)
	local fields = "{rank:1,max:1,fest_date:1,normal_l:1,fest_l:1,next_time:1}"
	local normal_ = {}
	local fest_l = {}
	local row,e_code = dbh:select_one(database,fields,query)
	if row == nil or e_code ~= 0 then return 1 end
	 
	self.rank = row.rank
	self.max = row.max
	self.next_time = row.next_time
	self.fest_date = row.fest_date
	normal_l = row.normal_l
	fest_l = row.fest_l

	for i,v in pairs(normal_l or {}) do
		local obj = Limit_obj(0,0,0)
		obj:clone(v)
		self.normal_l[i] = obj
	end
	for i,v in pairs(fest_l or {}) do
		local obj = Limit_obj(0,0,0)
		obj:clone(v)
		self.fest_l[i] = obj
	end
	--
	local normal_size = #self.normal_l
	if normal_size < sell_max then
		for i = normal_size + 1, sell_max do
			self:add_normal_date(self.rank, i)
		end
	end
	if self.fest_date == 0  then
		self.item_l = self.normal_l
	else
		self.item_l = self.fest_l
	end
	return 0
end


function Limit_mgr:update(date)	
	if not mall_limit_loader_fest.MallLimitFestItemTable[date] then
		local running_date = f_get_start_runing_day()+1
		local date_rank = self:get_date_rank(running_date)
		self.fest_date = 0
		self.fest_l = {}
		--边界点
		if running_date == mall_limit_loader.MallLimitTable[date_rank].item_list.max then		
			self:normal_clear()
			self:normal_date_reload_all(date_rank+1)	--注意(data_rank+1)
			self.item_l = self.normal_l
		--区间内
		elseif running_date < self.max then		
			self.item_l = self.normal_l
			for k,obj in pairs (self.item_l or {}) do
				local type = 0
				local list = self:get_item_list(obj)
				if ev.time >= obj:get_end_time() then
					type = 0
					self:clear_one(obj:get_id())
					self:normal_date_reload_one(type,k,date_rank)
				elseif (self:get_total_count(list)-obj:get_sell_count()) <= 0 then
					type = 1
					self:clear_one(obj:get_id())
					self:normal_date_reload_one(type,k,date_rank)
				end
			end
		else
			self:normal_clear()
			self:normal_date_reload_all(date_rank)	
			self.item_l = self.normal_l	
		end
	else
		--节日
		self:fest_clear()
		self:fest_date_reload_all(date)
		self.item_l = self.fest_l
	end	
end


function Limit_mgr:get_date_rank(running_date)
	for k,v in pairs(mall_limit_loader.MallLimitTable) do
		if (running_date>=v.min and running_date<=v.max) then
			return k
		end
	end		
end


--后备配置
function Limit_mgr:normal_date_reload_one(type,index,date_rank)
	local list_l = {}
	local end_time = self.item_l[index]:get_end_time()
	if type == 0 then
		item_l = mall_limit_loader.MallLimitTable[date_rank].item_list
	else
		item_l = mall_limit_loader.MallLimitTable[date_rank].backup_list
	end
	local rec = {} --记录使用的item_id
	local sum = item_l.weights	--所有权值
	local old_sum = 0

	for k,v in pairs(self.item_l or {}) do
		if k~=index then
			local list = self:get_item_list(v)
			old_sum = old_sum+list.weights
			rec[v:get_index()] = true
		end
	end
	sum = sum-old_sum
	local tmp = 0
	local rd = crypto.random(1,sum+1)
	for k,v in pairs(item_l or {}) do
		if not rec[k] then
			tmp = tmp+item_l[k].weights
			if tmp>=rd then
				local item_id = item_l[k].id or 0
				if type == 0 then
					end_time = item_l[k].limited_time*one_hour+f_get_today()+12*one_hour-60
				end
				self.normal_l[index] = Limit_obj(item_id,end_time,k)
				if type == 1 then
					self.item_l[index]:set_backup()
				end
				break
			end
		end
	end
end

--补充数组长度
function Limit_mgr:add_normal_date(date_rank, index)
	
	local item_l = mall_limit_loader.MallLimitTable[date_rank].item_list

	local rec = {} --记录使用的item_id
	local sum = item_l.weights	--所有权值
	local old_sum = 0

	for k,v in pairs(self.normal_l or {}) do
		local list = self:get_item_list(v)
		old_sum = old_sum+list.weights
		rec[v:get_index()] = true
	end
	sum = sum-old_sum
	local tmp = 0
	local rd = crypto.random(1,sum+1)
	for k,v in pairs(item_l or {}) do
		if not rec[k] then
			tmp = tmp+item_l[k].weights
			if tmp>=rd then
				local item_id = item_l[k].id or 0
				local end_time = item_l[k].limited_time*one_hour+f_get_today()+12*one_hour-60
				self.normal_l[index] = Limit_obj(item_id,end_time,k)
				break
			end
		end
	end
end

--正常配置
function Limit_mgr:normal_date_reload_all(date_rank)
	local list = mall_limit_loader.MallLimitTable[date_rank].item_list
	local rec = {} --记录使用的item_id
	local sum = list.weights	--所有权值
	local len = table.getn(list)
	local item_id
	local end_time

	for i=1, sell_max do
		local rd = crypto.random(1,sum+1)
		local tmp = 0
		local pnt = 0
		for j=1,len do
			if not rec[j] then
				tmp = tmp+list[j].weights
				if tmp>=rd then
					pnt = j
					break
				end
			end
		end
		if pnt>=1 and pnt<= len then
			item_id = list[pnt].id or 0
			end_time = (list[pnt].limited_time or 0)*one_hour+f_get_today()+12*one_hour-60
			self.normal_l[i] = Limit_obj(item_id,end_time,pnt)
			rec[pnt] = true
			sum = sum-list[pnt].weights
		end
	end
	self.max = list.max
	self.rank = date_rank
end

--节日配置
function Limit_mgr:fest_date_reload_all(date) 
	for i=1, 2 do
		local list = mall_limit_loader_fest.MallLimitFestItemTable[date][i]
		local item_id = list.id or 0
		local end_time = (list.limited_time or 0)*one_hour+f_get_today()+12*one_hour-60
		self.fest_l[i] = Limit_obj(item_id,end_time,i)
	end
	self.fest_date = date
end


function Limit_mgr:get_next_time()
	local ret = f_get_tomorrow()+12*60*60
	return ret
end


function Limit_mgr:normal_clear()
	self.item_l = {}
	self.fest_l = {}
	self.normal_l = {}
	self.count_l = {}
	self.rank = nil
	self.max = 0
end

function Limit_mgr:fest_clear()
	self.item_l = {}
	self.fest_l = {}
	self.count_l = {}
end


function Limit_mgr:clear_one(item_id)
	self.count_l[item_id] = nil
end