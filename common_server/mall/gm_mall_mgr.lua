


local gm_mall_config = require("mall.gm_mall_loader")

Gm_mall_mgr = oo.class(nil,"Gm_mall_mgr")

function Gm_mall_mgr:__init()
	self.buy_l = {}
	self.sell_l = {}
	self.next_time = ev.time-1
	self.total_size = 0
end

function Gm_mall_mgr:get_list(char_id,pkt)
	return self:serialize_to_net(char_id,pkt.page,pkt.pageSize)
end

function Gm_mall_mgr:buy_item(server_id,char_id,pkt)
	if not pkt.page or not pkt.pageSize then return end
	local ret = {}
	ret.error = 0
	local item_id = tonumber(pkt.item_id)
	local number = tonumber(pkt.number)
	local item = nil
	local item_l = gm_mall_config.GmMallTable
	for i=(pkt.page-1)*pkt.pageSize+1,(pkt.page)*pkt.pageSize do
		if not item_l[i] then break end
		if item_id == item_l[i].item_id then
			item = item_l[i]
			break
		end
	end
	if not item or not self:is_valid(item) then
		ret.error = 60005
	end
	local buy_count = self:get_buy_count(item_id,char_id)
	if item.single_count ~= -1 and buy_count+number > item.single_count then
		ret.error = 60004
	end
	local sell_count = self:get_sell_count(item_id)
	if item.total_count ~= -1 and number > (item.total_count-sell_count) then
		ret.error = 60006
	end
	if ret.error ~= 0 then
		g_server_mgr:send_to_server(server_id,char_id,CMD_C2M_GM_MALL_BUY_ITEM_ANS,ret)
		return 
	end

	ret.number = number
	ret.item_id = item_id
	ret.currency = pkt.currency
	ret.price = item.price
	ret.name = item.name
	ret.day = pkt.day
	ret.server_id = server_id
	ret.page = pkt.page
	ret.pageSize = pkt.pageSize
	ret.char_id = char_id
	ret.line = server_id

	ret.openid = pkt.openid
	ret.openkey = pkt.openkey
	ret.serverid = pkt.serverid
	ret.pf = pkt.pf
	ret.pfkey = pkt.pfkey

	--if pkt.day and pkt.item_id then
		--e_code,item_obj = Item_factory.create(tonumber(item_id))
		--if not item_obj then return end
		--local e_code,price = item_obj:get_cost(tostring(pkt.day),1)
		--if e_code ~= 0 then 
			--return 
		--end	
		--ret.price = price
	--end


	if not g_currency_mgr:currency_id_exist(char_id) then
		
		g_currency_mgr:add_currency_id(char_id, ret, char_id, 2)

	end

	--g_server_mgr:send_to_server(server_id,char_id,CMD_C2M_GM_MALL_BUY_ITEM_ANS,ret)
	--local param = ret
	--g_sock_event_mgr:add_event(char_id,CMD_M2C_GM_MALL_DEC_TIME_REQ,self,self.dec_item,self.get_time_out,param,3)
end

function Gm_mall_mgr:do_buy_item(server_id,char_id,pkt)
	g_server_mgr:send_to_server(server_id,char_id,CMD_C2M_GM_MALL_BUY_ITEM_ANS,pkt)

	g_sock_event_mgr:add_event(char_id,CMD_M2C_GM_MALL_DEC_TIME_REQ,self,self.dec_item,self.get_time_out,pkt,3)
end

--function Gm_mall_mgr:buy_item(server_id,char_id,pkt)
	--if not pkt.page or not pkt.pageSize then return end
	--local ret = {}
	--ret.error = 0
	--local item_id = tonumber(pkt.item_id)
	--local number = tonumber(pkt.number)
	--local item = nil
	--local item_l = gm_mall_config.GmMallTable
	--for i=(pkt.page-1)*pkt.pageSize+1,(pkt.page)*pkt.pageSize do
		--if not item_l[i] then break end
		--if item_id == item_l[i].item_id then
			--item = item_l[i]
			--break
		--end
	--end
	--if not item or not self:is_valid(item) then
		--ret.error = 60005
	--end
	--local buy_count = self:get_buy_count(item_id,char_id)
	--if item.single_count ~= -1 and buy_count+number > item.single_count then
		--ret.error = 60004
	--end
	--local sell_count = self:get_sell_count(item_id)
	--if item.total_count ~= -1 and number > (item.total_count-sell_count) then
		--ret.error = 60006
	--end
	--if ret.error ~= 0 then
		--g_server_mgr:send_to_server(server_id,char_id,CMD_C2M_GM_MALL_BUY_ITEM_ANS,ret)
		--return 
	--end
--
	--ret.number = number
	--ret.item_id = item_id
	--ret.currency = pkt.currency
	--ret.price = item.price
	--ret.name = item.name
	--ret.day = pkt.day
	--ret.server_id = server_id
	--ret.page = pkt.page
	--ret.pageSize = pkt.pageSize
	--ret.char_id = char_id
	--g_server_mgr:send_to_server(server_id,char_id,CMD_C2M_GM_MALL_BUY_ITEM_ANS,ret)
	--local param = ret
	--g_sock_event_mgr:add_event(char_id,CMD_M2C_GM_MALL_DEC_TIME_REQ,self,self.dec_item,self.get_time_out,param,3)
--end

function Gm_mall_mgr:serialize_to_net(char_id,page,size)
	local ret = {}
	local list = {}
	if ev.time >= self.next_time then 
		self:update()
	end
	self:check_valid()
	local item_l = gm_mall_config.GmMallTable
	for i=(page-1)*size+1,(page)*size do
		local item = item_l[i]
		if not item then break end
		if self:is_valid(item) then
			local item_obj = {}
			item_obj[1] = item.item_id
			item_obj[2] = item.name
			item_obj[3] = item.price
			item_obj[4] = item.currency
			item_obj[5] = -1
			item_obj[6] = -1
			local sell_count = self:get_sell_count(item.item_id)
			if item.total_count ~= -1 then
				item_obj[5] = math.max(item.total_count-sell_count,0)
			end
			if item.end_time ~= -1 then
				item_obj[6] = math.max(item.end_time-ev.time,0)
			end
			item_obj[7] = item.type
			item_obj[8] = item.ori_price
			if item.single_count ~= -1 then
				item_obj[9] = math.max(item.single_count - self:get_buy_count(item.item_id, char_id), 0)
			else
				item_obj[9] = -1
			end
			table.insert(list,item_obj)
		end
	end
	ret.list = list
	ret.page = page
	ret.pageSize = size
	ret.totalPage = math.ceil(self.total_size/size)
	return ret
end

function Gm_mall_mgr:check_valid()
	local item_l = gm_mall_config.GmMallTable
	local list = {}
	local next_l ={}
	local count = 0
	for i,v in pairs(item_l) do
		if not v then break end
		if self:check_start(v) then
			table.insert(next_l,v)
			count = count+1
		elseif self:check_end(v) then
			table.insert(list,v)
		end
	end		
	for i,v in pairs(next_l or {}) do
		table.insert(list,v)
	end	
	self.total_size = math.max(table.getn(list)-count,0)
	gm_mall_config.GmMallTable = list
end

function Gm_mall_mgr:check_end(item)
	if item.end_time ~= -1 then
		if ev.time >= item.end_time then
			return false
		end
	end	
	return true
end

function Gm_mall_mgr:check_start(item)
	if item.start_time ~= -1 then
		if item.start_time >= ev.time then
			return true
		end
	end
	return false
end

function Gm_mall_mgr:is_valid(item)
	if item.start_time ~= -1 then
		if ev.time <= item.start_time then
			return false
		end
	end
	if item.end_time ~= -1 then
		if ev.time >= item.end_time then
			return false
		end
	end
	return true
end

function Gm_mall_mgr:dec_item(param,pkt)
	param.result = 0;
	g_currency_mgr:currency_success(param.char_id, param)

	local sell_count = self:get_sell_count(param.item_id)
	local buy_count = self:get_buy_count(param.item_id,param.char_id)
	self.buy_l[param.item_id][param.char_id] = buy_count+pkt.number
	self.sell_l[param.item_id] = sell_count+pkt.number
	local ret = self:serialize_to_net(param.char_id,param.page,param.pageSize)
	g_server_mgr:send_to_server(param.server_id,param.char_id,CMD_C2M_GM_MALL_DEC_ITEM_ANS,ret)
end

function Gm_mall_mgr:get_time_out(param)
	
end

function Gm_mall_mgr:update()
	self.buy_l = {}
	self.sell_l = {}
	self.next_time = f_get_tomorrow()
end

function Gm_mall_mgr:get_sell_count(item_id)
	if not self.sell_l then
		self.sell_l = {}
	end
	if not self.sell_l[item_id] then
		self.sell_l[item_id] = 0
	end
	return self.sell_l[item_id]
end

function Gm_mall_mgr:get_buy_count(item_id,char_id)
	if not self.buy_l then
		self.buy_l = {}
	end
	if not self.buy_l[item_id] then
		self.buy_l[item_id] = {}
	end
	if not self.buy_l[item_id][char_id] then
		self.buy_l[item_id][char_id] = 0
	end
	return self.buy_l[item_id][char_id]
end