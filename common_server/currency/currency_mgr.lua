
-----------------------------------统一管理腾讯货币接口-----------------------------
--local currency_loader = require("currency.currency_loader")
--消费类型对应该流水类型
local id_to_money_source = {
	MONEY_SOURCE.MALL, 
	MONEY_SOURCE.GM_MALL_BUY, 
	MONEY_SOURCE.MALL_LIMIT_BUY, 
	MONEY_SOURCE.SUMMON_BOSS, 
	MONEY_SOURCE.GET_ALL_OFFLINEEXP, 
	MONEY_SOURCE.RENEWAL_FASHION, 
	MONEY_SOURCE.VIP_MALL_BUY, 
	MONEY_SOURCE.EXPAND_BAG, 
	MONEY_SOURCE.CHEST_ONE, 
}

local overTime  = 5
local consignmentTime = 15

Currency_mgr = oo.class(nil, "Currency_mgr")

function Currency_mgr:__init()
	self.consignment_l = {}
	self.stall_l = {}
	self.currency_l = {}
end

function Currency_mgr:check_exchange(uid, pkt)
	if self.consignment_l[uid] then
		self:exchange_consignment(uid)
	elseif self.stall_l[uid] then
		return self:exchange_stall_ex(uid, pkt)
	else
		return 1
	end
end

--------------------寄售
function Currency_mgr:consignment_id_exist(uid)
	if self.consignment_l[uid] then
		if self.consignment_l[uid].time >= ev.time then
			return true
		else
			self:del_consignment_id(uid, 3)
			return false
		end
	else
		return false
	end
end

function Currency_mgr:add_consignment_id(uid, param, buyer, seller,amt, fee)
	param.fee = fee				--手续费算消费

	self.consignment_l[uid] = {}
	self.consignment_l[uid].time = ev.time + consignmentTime
	self.consignment_l[uid].param = param
	self.consignment_l[uid].buyer = buyer
	self.consignment_l[uid].seller = seller

	local pkt = {}
	pkt.openid = param.openid
	pkt.openkey = param.openkey
	pkt.serverid = param.serverid
	pkt.pf = param.pf
	pkt.pfkey = param.pfkey
	pkt.amt = amt
	pkt.fee = fee
	pkt.item_id = uid
	pkt.price = amt
	pkt.number = 1
	pkt.item_name = "寄售物品"
	pkt.seller_openid = g_player_mgr:char_id2acn(seller)

	local str = string.format(
				"insert into tx_trade set buyer =%d ,seller = %d,time = %d,uuid = '%s',type =1,phase = %d,param= '%s'",
					self.consignment_l[uid].buyer,
					self.consignment_l[uid].seller,
					ev.time,
					uid,
					1,
					Json.Encode(self.consignment_l[uid].param))

	g_web_sql:write(str)

	g_svsock_mgr:send_server_ex(WORLD_ID, buyer, CMD_C2G_TOKEN_CONSIGNMENT_C, pkt)
end

function Currency_mgr:del_consignment_id(uid, type)
	if self.consignment_l[uid] then
		local str = string.format(
					"insert into tx_trade set buyer =%d ,seller = %d,time = %d,uuid = '%s',type =1,phase = %d,param= '%s'",
						self.consignment_l[uid].buyer,
						self.consignment_l[uid].seller,
						ev.time,
						uid,
						type,
						Json.Encode(self.consignment_l[uid].param))

		g_web_sql:write(str)
	end
	self.consignment_l[uid] = nil
end

function Currency_mgr:exchange_consignment(uid)
	local item = self.consignment_l[uid]
	if not item then
		return 1
	end

	if g_consignment:buy_consignment(item.buyer, item.param) then
		g_consum_ret_mgr:add_cost(1, item.buyer, item.param.fee)

		local line = g_player_mgr:get_map_id(item.buyer)

		if line then
			local t_pkt = {}
			t_pkt.pages		= 1
			t_pkt.pagesize 	= 5
			t_pkt.timestamp	= -1
			t_pkt.condition_list = {}
			t_pkt.condition_list.sub_type = 'total'
			local s_pkt = g_consignment:get_list(t_pkt) or {}
			g_server_mgr:send_to_server(line, item.buyer, CMD_CONSIGNMENT_SEARCH_C, s_pkt)
		end

		g_svsock_mgr:send_server_ex(WORLD_ID, item.buyer, CMD_G2W_UPDATE_QQ_C, {})
		g_svsock_mgr:send_server_ex(WORLD_ID, item.seller, CMD_G2W_UPDATE_QQ_C, {})

		self:del_consignment_id(uid, 2)

		return 0
	else
		self:del_consignment_id(uid, 4)
		return 1
	end
end



--------------------摆摊
function Currency_mgr:stall_id_exist(uid)
	if self.stall_l[uid] then
		if self.stall_l[uid].time >= ev.time then
			return true
		else
			self:del_stall_id(uid, 3)
			return false
		end
	else
		return false
	end
end

function Currency_mgr:add_stall_id(uid, param, buyer, seller,amt, fee)
	self.stall_l[uid] = {}
	self.stall_l[uid].time = ev.time + consignmentTime
	self.stall_l[uid].param = param
	self.stall_l[uid].buyer = buyer
	self.stall_l[uid].seller = seller

	local pkt = {}
	pkt.openid = param.openid
	pkt.openkey = param.openkey
	pkt.serverid = param.serverid
	pkt.pf = param.pf
	pkt.pfkey = param.pfkey
	pkt.amt = amt
	pkt.fee = fee
	pkt.item_id = uid
	pkt.price = param.stall_cost
	pkt.number = param.count
	pkt.item_name = "摆摊物品"
	pkt.seller_openid = g_player_mgr:char_id2acn(seller)


	g_svsock_mgr:send_server_ex(WORLD_ID, buyer, CMD_C2G_TOKEN_CONSIGNMENT_C, pkt)

	local str = string.format(
				"insert into tx_trade set buyer =%d ,seller = %d,time = %d,uuid = '%s',type =2,phase = %d,param= '%s'",
					self.stall_l[uid].buyer,
					self.stall_l[uid].seller,
					ev.time,
					uid,
					1,
					Json.Encode(self.stall_l[uid].param))

	g_web_sql:write(str)
end

function Currency_mgr:del_stall_id(uid, type)
	if self.stall_l[uid] then
		local str = string.format(
					"insert into tx_trade set buyer =%d ,seller = %d,time = %d,uuid = '%s',type =2,phase = %d,param= '%s'",
						self.stall_l[uid].buyer,
						self.stall_l[uid].seller,
						ev.time,
						uid,
						type,
						Json.Encode(self.stall_l[uid].param))

		g_web_sql:write(str)
	end
	self.stall_l[uid] = nil
end

function Currency_mgr:exchange_stall_ex(uid, pkt)
	local item = self.stall_l[uid]
	item.time = ev.time + overTime
	item.pkt = pkt				--异步回GM

	local line = g_player_mgr:get_map_id(item.buyer)
	if not line then
		self:del_stall_id(uid, 4)

		return 1
	end

	g_server_mgr:send_to_server(line, item.buyer, CMD_C2M_QQ_STALL_C, {result = 0, param = item.param})	
end

function Currency_mgr:exchange_stall(pkt)
	self.stall_l[pkt.uid].pkt.result = pkt.result

	local ret = 4
	if pkt.result == 0 then
		ret = 2
		g_svsock_mgr:send_server_ex(WORLD_ID, self.stall_l[pkt.uid].buyer, CMD_G2W_UPDATE_QQ_C, {})
		g_svsock_mgr:send_server_ex(WORLD_ID, self.stall_l[pkt.uid].seller, CMD_G2W_UPDATE_QQ_C, {})
	end
	g_svsock_mgr:send_server_ex ( WORLD_ID, 0, CMD_C2G_QQ_CONSIGNMENT_C, self.stall_l[pkt.uid].pkt)

	self:del_stall_id(pkt.uid, ret)
end


---------------------普通购买
function Currency_mgr:currency_id_exist(uid)
	if self.currency_l[uid] then
		if self.currency_l[uid].time >= ev.time then
			return true
		else
			self:del_currency_id(uid, 3)
			return false
		end
	else
		return false
	end
end

function Currency_mgr:add_currency_id(uid, param, buyer, type)
	--print("Currency_mgr:add_currency_id", uid, j_e(param), buyer, type)
	self.currency_l[uid] = {}
	self.currency_l[uid].time = ev.time + overTime
	self.currency_l[uid].param = param
	self.currency_l[uid].buyer = buyer
	self.currency_l[uid].type = type

	local pkt = {}
	pkt.openid = param.openid
	pkt.openkey = param.openkey
	pkt.serverid = param.serverid
	pkt.pf = param.pf
	pkt.pfkey = param.pfkey

	pkt.item_id = uid
	if type == 1 then	--商城
		pkt.price = param.item_price
		pkt.number = param.number
		pkt.item_name = param.item_name
	elseif type == 2 or type == 3 then --2gm商城，3限购商城
		pkt.price = param.price
		pkt.number = param.number
		pkt.item_name = param.name
	elseif type == 4 then
		pkt.price = param.price
		pkt.number = 1
		pkt.item_name = "BOSS"
	elseif type == 5 then
		pkt.price = param.all_money
		pkt.number = 1
		pkt.item_name = "OFFLINE"
	elseif type == 6 then
		pkt.price = param.cost
		pkt.number = 1--param.days
		pkt.item_name = "FASHION"
	elseif type == 7 then --vip商城
		pkt.price = param.price
		pkt.number = param.number
		pkt.item_name = param.name
	elseif type == 8 then
		pkt.price = param.all_money
		pkt.number = 1
		pkt.item_name = "BAG_SLOT"
	elseif type == 9 then
		pkt.price = param.all_money
		pkt.number = 1
		pkt.item_name = "XIANG_YAO"
	end

	g_svsock_mgr:send_server_ex(WORLD_ID, buyer, CMD_M2G_QQ_CURENCY_M, pkt)

	local str = string.format(
				"insert into tx_currency set char_id =%d ,time = %d,type =%d,phase = %d,param= '%s'",
					self.currency_l[uid].buyer,
					ev.time,
					self.currency_l[uid].type,
					1,
					Json.Encode(self.currency_l[uid].param))

	g_web_sql:write(str)
end

function Currency_mgr:del_currency_id(uid, phase)
	if self.currency_l[uid] then
		local str = string.format(
					"insert into tx_currency set char_id =%d ,time = %d,type =%d,phase = %d,param= '%s'",
						self.currency_l[uid].buyer,
						ev.time,
						self.currency_l[uid].type,
						phase,
						Json.Encode(self.currency_l[uid].param))

		g_web_sql:write(str)
	end
	self.currency_l[uid] = nil
end

function Currency_mgr:currency_send_goods(uid, pkt)
	--print("Currency_mgr:currency_send_goods:", j_e(pkt))
	
	local item = self.currency_l[uid]
	if not item then
		return 1
	end
	if pkt == nil then
		print("error currency_send_goods:", uid, Json.Encode(item))
	end

	item.time = ev.time + overTime
	item.pkt = pkt

	local line = g_player_mgr:get_map_id(item.buyer)

	if not line or item.param.line ~= line then
		return 1
	end

	if item.type == 1 then				--商城

		g_server_mgr:send_to_server(line, item.buyer, CMD_MALL_BUY_ITEM_S, item.param)
	
	elseif item.type == 2 then			--GM商城
	
		g_gm_mall:do_buy_item(line, uid, item.param)
	
	elseif item.type == 3 then			--限购商城
		
		g_server_mgr:send_to_server(line,uid,CMD_MALL_BUY_LIMIT_ITEM_S,item.param)
	
	elseif item.type == 4 then
		
		g_server_mgr:send_to_server(line,uid,CMD_M2C_QQ_BOSS_C,item.param)
	
	elseif item.type == 5 then
		
		g_server_mgr:send_to_server(line,uid,CMD_M2C_QQ_OFFLINE_C,item.param)

	elseif item.type == 6 then
		
		g_server_mgr:send_to_server(line,uid,CMD_M2C_QQ_FASHION_C,item.param)
	
	elseif item.type == 7 then
		
		g_server_mgr:send_to_server(line,uid,CMD_MALL_VIP_BUY_ITEM_ANS,item.param)

	elseif item.type == 8 then
		--背包开格 
		g_server_mgr:send_to_server(line,uid,CMD_M2C_QQ_BAG_SLOT_C,item.param)

	elseif item.type == 9 then
		--降妖
		g_server_mgr:send_to_server(line,uid,CMD_M2C_QQ_XIANG_YAO_C,item.param)

	end

	return 0
end

function Currency_mgr:currency_success(char_id, param)

	local pkt = self.currency_l[char_id].pkt
	if pkt == nil then
		print("error currency_success:", char_id, Json.Encode(param), Json.Encode(self.currency_l[char_id]))
	end
	pkt.result = param.result

	local ret = 4

	if param.result == 0 then
		ret = 2
		g_consum_ret_mgr:add_cost(1, char_id, pkt.paytotal)
		g_svsock_mgr:send_server_ex(WORLD_ID, char_id, CMD_G2W_UPDATE_QQ_C, {})
		--流水
		local type = id_to_money_source[self.currency_l[char_id].type]
		if type == nil then
			print("error currency_success type:", Json.Encode(pkt))
			type = 0
		end
		local player_info = g_player_mgr.all_player_l[char_id]
		local name = player_info and player_info["char_nm"] or ""
		local level = player_info and player_info["level"] or 0
		str = string.format("insert log_money set char_id=%d, char_name='%s', level=%d, io=%d, type=%d, money_type=%d, left_num=%d, time=%d, money_num=%d",
						char_id, name, level, 0,  type, 3,  0, ev.time, pkt.paytotal)
		g_web_sql:write(str)
		--发回map 做消费返还活动统计
		local line = g_player_mgr:get_map_id(char_id)
		local new_pkt = {}
		new_pkt.money = pkt.paytotal
		new_pkt.type = type
		g_server_mgr:send_to_server(line, char_id, CMD_C2M_CONSUME_INFO, new_pkt)
	else
		print("currency_success 2:", char_id, Json.Encode(param), Json.Encode(self.currency_l[char_id]))
	end

	g_svsock_mgr:send_server_ex( WORLD_ID, 0, CMD_C2G_QQ_GOODS_C, pkt)

	self:del_currency_id(char_id, ret)
end

function Currency_mgr:check_del_cur(char_id)
	if self.currency_l[char_id] then

		self:del_currency_id(char_id, 4)

	end
end

function Currency_mgr:check_del_con(uid)
	if self.consignment_l[uid] then
		self:del_consignment_id(uid, 4)
	elseif self.stall_l[uid] then
		self:del_stall_id(uid, 4)
	end
end

function Currency_mgr:get_click_param()
	return self, self.on_timer, 2, nil
end

function Currency_mgr:on_timer()
	for k , v in pairs(self.consignment_l) do
		if v.time < ev.time then
			self:del_consignment_id(k, 3)
		end
	end

	for k , v in pairs(self.currency_l) do
		if v.time < ev.time then
			self:del_stall_id(k, 3)
		end
	end

	for k , v in pairs(self.stall_l) do
		if v.time < ev.time then
			self:del_currency_id(k, 3)
		end
	end
end


