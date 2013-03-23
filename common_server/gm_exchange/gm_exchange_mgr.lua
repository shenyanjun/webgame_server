


local database = "gm_exchange_char"
local _exchange = require("gm_exchange.gm_exchange_loader")

Gm_exchange_mgr = oo.class(nil,"Gm_exchange_mgr")


function Gm_exchange_mgr:__init()
	self.sell_l = {}
	self.buy_l = {}
	self.date = tonumber(os.date("%Y%m%d"))
end

--后台更新
function Gm_exchange_mgr:clear()
	self.sell_l = {}
	self.buy_l = {}
	self.date = tonumber(os.date("%Y%m%d"))
end

--网络构包
function Gm_exchange_mgr:serialize_to_net(server_id,char_id,pkt)
	--对时
	self:check_exchange_l()
	local ret = {}
	ret.result = 0
	if self.count == 0 then
		ret.result = 22301
		g_server_mgr:send_to_server(server_id,char_id,CMD_M2C_GM_EXC_GET_LIST_ANS,ret)
		return 
	end
	local list = _exchange.ExchangeTable
	local page = tonumber(pkt.page)
	local pageSize = tonumber(pkt.pageSize)
	ret.page = page
	ret.pageSize = pageSize
	ret.totalPage = math.ceil((self.count)/pageSize)
	local item_l = {}
	for i=math.max(page-1,0)*pageSize+1,page*pageSize do
		if not list[i] then break end
		if self:check_valid(list[i]) then
			local obj = {}
			obj[1] = list[i].des_id
			obj[2] = list[i].des_name
			obj[3] = list[i].des_count
			obj[4] = -1
			obj[5] = -1
			local sell_count = self:get_sell_count(list[i].exc_id)
			if list[i].total ~= -1 then
				obj[4] = math.max(list[i].total-sell_count,0)
			end
			if list[i].end_time ~= -1 then
				obj[5] = math.max(list[i].end_time-ev.time,0)
			end
			obj[6] = list[i].item_l
			obj[7] = list[i].money_l
			obj[8] = list[i].exc_id
			obj[9] = -1
			if list.single ~= -1 then
				obj[9] = list[i].single
			end
			obj[10] = list[i].days
			if list[i].days == nil then
				obj[10] = -2
			end
			table.insert(item_l,obj)
		end
	end
	ret.list = item_l
	g_server_mgr:send_to_server(server_id,char_id,CMD_M2C_GM_EXC_GET_LIST_ANS,ret)
end

--时间
function Gm_exchange_mgr:check_exchange_l()
	self.count = 0
	if table.getn(_exchange.ExchangeTable) == 0 then return end
	local list = {}
	local now = ev.time
	local next = {}
	for k,v in pairs(_exchange.ExchangeTable or {}) do
		if self:check_valid(v) then
			table.insert(list,v)
			self.count = self.count+1
		elseif v.end_time ~= -1 and now < v.end_time then
			table.insert(next,v)
		end
	end
	for i,v in pairs(next or {}) do
		table.insert(list,v)
	end
	_exchange.ExchangeTable = list
end

--兑换
function Gm_exchange_mgr:exchange_item(server_id,char_id,pkt)
	if not pkt.page or not pkt.pageSize then return end
	if tonumber(os.date("%Y%m%d")) > self.date then
		self:clear()
	end
	local ret = {}
	ret.result = 0
	local exc_id = pkt.exchange_id
	local item = nil
	local list = _exchange.ExchangeTable
	local page = tonumber(pkt.page)
	local pageSize = tonumber(pkt.pageSize)
	for i=math.max(page-1,0)*pageSize+1,(page)*pageSize do
		if not list[i] then break end
		if exc_id == list[i].exc_id then
			item = list[i]
			break
		end
	end

	--返回购买更新
	local new_pkt = {}
	new_pkt.page = page
	new_pkt.pageSize = pageSize
	--判断物品有效
	if not item or not self:check_valid(item) then
		ret.result = 22302
		g_server_mgr:send_to_server(server_id,char_id,CMD_C2M_GM_EXC_TIME_ANS,ret)
		self:serialize_to_net(server_id,char_id,new_pkt)
		return 
	end
	local buy_count = self:get_buy_count(char_id,item.exc_id)
	if item.single ~= -1 and buy_count+item.des_count > item.single then
		ret.result = 22303
	end
	local sell_count = self:get_sell_count(item.exc_id)
	if item.total ~= -1 and item.des_count+sell_count > item.total then
		ret.result = 22304
	end
	if ret.result ~= 0 then
		g_server_mgr:send_to_server(server_id,char_id,CMD_C2M_GM_EXC_TIME_ANS,ret)
		self:serialize_to_net(server_id,char_id,new_pkt)
		return 
	end

	ret.item = item
	g_server_mgr:send_to_server(server_id,char_id,CMD_C2M_GM_EXC_TIME_ANS,ret)
	local param = {}
	param.item = item
	param.page = page
	param.pageSize = pageSize
	param.server_id = server_id
	param.char_id = char_id
	g_sock_event_mgr:add_event(char_id,CMD_M2C_GM_EXC_NOTIFY_ANS,self,self.call_back_function,self.get_time_out,param,2)
end

function Gm_exchange_mgr:call_back_function(param,pkt)
	local item = param.item
	local page = param.page
	local pageSize = param.pageSize
	local server_id = param.server_id
	local char_id = param.char_id
	--记录购买
	local sell_count = self:get_sell_count(item.exc_id)
	local buy_count = self:get_buy_count(char_id,item.exc_id)
	self.buy_l[item.exc_id][char_id] = buy_count+item.des_count
	self.sell_l[item.exc_id] = sell_count+item.des_count

	--返回购买更新
	local new_pkt = {}
	new_pkt.page = page
	new_pkt.pageSize = pageSize
	self:serialize_to_net(server_id,char_id,new_pkt)
end

function Gm_exchange_mgr:get_time_out(param)

end

--检查时间
function Gm_exchange_mgr:check_valid(obj)
	local now = ev.time
	if obj.start_time ~= -1 then
		if now < obj.start_time then return false end
	end

	if obj.end_time ~= -1 then
		if now >= obj.end_time then return false end
	end
	return true
end

--已卖
function Gm_exchange_mgr:get_sell_count(exc_id)
	if not self.sell_l[exc_id] then
		self.sell_l[exc_id] = 0
	end
	return self.sell_l[exc_id]
end

--已买
function Gm_exchange_mgr:get_buy_count(char_id,exc_id)
	if not self.buy_l[exc_id] then
		self.buy_l[exc_id] = {}
	end
	if not self.buy_l[exc_id][char_id] then
		self.buy_l[exc_id][char_id] = 0
	end
	return self.buy_l[exc_id][char_id]
end