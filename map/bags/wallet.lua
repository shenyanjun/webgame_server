
Wallet = oo.class(nil, "Wallet")

function Wallet:__init(char_id, gold, gift_gold, jade, gift_jade, bank_gold, bk_ground)
	self.char_id = char_id
	self.money = {}
	self.money[MoneyType.GOLD] = gold or 0
	self.money[MoneyType.GIFT_GOLD] = gift_gold or 0
	self.money[MoneyType.JADE] = jade or 0
	self.money[MoneyType.GIFT_JADE] = gift_jade or 0
	self.money[MoneyType.BANK_GOLD] = bank_gold or 0
	self.money[MoneyType.BACK_GROUND] = bk_ground or 0
end

--发送客户端
function Wallet:send_client()
	local pkt = {}
	pkt.type = TYPE_GET_PACK_DETAIL_MONEY
	pkt.data = {}
	pkt.data = self:get_money()
	g_cltsock_mgr:send_client(self.char_id, CMD_MAP_GET_PACK_DETAIL_S, pkt)
end

--发送profile服务器
function Wallet:send_profile(money_type)
	local pkt = {}
	pkt.acc_id = self.acc_id
	pkt.m_type = money_type
	pkt.money = self:get_money()
	g_svsock_mgr:send_server_ex(PROFILE_ID, self.char_id, CMD_M2P_UPDATE_MONEY_SYNC, pkt)
end

--写后台数据
function Wallet:write_log(money_type, value, op_l)
	if not op_l.op_type then
		return false
	end
	if op_l.op_type == Money_Consume_Type.CONSUME_TYPE_NONE then
		if op_l.money_change == Money_change.add_money then
			f_write_gold_money_log(self.char_id, 1, money_type, value)
		elseif op_l.money_change == Money_change.dec_money then
			f_write_gold_money_log(self.char_id, 0, money_type, value)
		end
	elseif money_type == MoneyType.JADE or money_type == MoneyType.GIFT_JADE then
		local log_info = {}
		log_info["price"] = value
		log_info["op_type"] = op_l.op_type
		log_info["currency"] = money_type
		log_info["remain_money"] = self.money[money_type]
		f_write_money_db_log(self.char_id, log_info)
	end
end

--更新相关信息
function Wallet:update_money(money_type, value, op_l)
	self:send_client()
	self:send_profile(money_type)
	self:write_log(money_type, value, op_l)
end

--加钱
function Wallet:add_money(money_type, value, op_l)
	if not money_type or not value then
		return false
	end

	if value < 0 then
		return false
	end

	if money_type==MoneyType.BANK_GOLD then
		self.money[MoneyType.GOLD] = self.money[MoneyType.GOLD] - value
		self.money[MoneyType.BANK_GOLD] = self.money[MoneyType.BANK_GOLD] + value
	else
		self.money[money_type] = self.money[money_type] + value
	end

	--变动类型
	if not op_l then
		op_l = {}
	end
	op_l.money_change= Money_change.add_money

	self:update_money(money_type, value, op_l)
	return true
end




--减去某种类型的钱
function Wallet:dec_money(money_type, value, op_l)
	if value < 0  then
		return false
	end
	if self.money[money_type] < value then
		return false
	else
		if money_type==MoneyType.BANK_GOLD then
			self.money[MoneyType.GOLD] = self.money[MoneyType.GOLD] + value
			self.money[MoneyType.BANK_GOLD] = self.money[MoneyType.BANK_GOLD] - value
		else
			self.money[money_type] = self.money[money_type] - value
		end
	end

	--变动类型
	if not op_l then
		op_l = {}
	end
	op_l.money_change= Money_change.dec_money

	self:update_money(money_type, value, op_l)
	return true
end

--先扣票，再扣币
function Wallet:dec_gift_gold(value, op_l)
	if self.money[MoneyType.GOLD] + self.money[MoneyType.GIFT_GOLD] < value then
		return false, 200008
	end
	if self.money[MoneyType.GIFT_GOLD] < value then
		local left = value - self.money[MoneyType.GIFT_GOLD]
		self:dec_money(MoneyType.GIFT_GOLD, self.money[MoneyType.GIFT_GOLD] , op_l)
		self:dec_money(MoneyType.GOLD, left, op_l)
	else
		self:dec_money(MoneyType.GIFT_GOLD, value , op_l)
	end
	return true
end

--获取钱包信息
function Wallet:get_money()
	local ret = {}
	ret.gold = self.money[MoneyType.GOLD]
	ret.gift_gold = self.money[MoneyType.GIFT_GOLD]
	ret.jade = self.money[MoneyType.JADE]
	ret.gift_jade = self.money[MoneyType.GIFT_JADE]
	ret.bank_gold = self.money[MoneyType.BANK_GOLD]
	return ret
end


--打印
function Wallet:print_status()
	print("MoneyType.GOLD : ", self.money[MoneyType.GOLD])
	print("MoneyType.GIFT_GOLD : ", self.money[MoneyType.GIFT_GOLD])
	print("MoneyType.JADE : ", self.money[MoneyType.JADE])
	print("MoneyType.GIFT_JADE : ", self.money[MoneyType.GIFT_JADE])
	print("MoneyType.BANK_GOLD : ", self.money[MoneyType.BANK_GOLD])
end

