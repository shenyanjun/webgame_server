--$Id: rechage_reward.lua 61930 2013-03-20 07:08:19Z tangpf $
--2010-01-21
--laojc
--充值
local reward_t = require("config.reward_config")
local integral = require("mall.integral_func")


Rechage_reward = oo.class(nil,"Rechage_reward")

function Rechage_reward:init()
	--self.reward_list = {}
	--local dbh = get_dbh_web()
--
	--local rs = dbh:selectall_ex("select * from gift_list where type = 1")
	--if rs ~= nil and dbh.errcode == 0 then
		--for k,v in pairs(rs) do
			--local id = v.char_id
			--if id ~= nil and id ~= "" then
				--self.reward_list[id] = {}
				--self.reward_list[id].status = v.status
				--self.reward_list[id].receive_time = v.receive_time
			--end
		--end
	--end


	--充值礼包容器
	self.gift_con = {}
end

---------------------------------------首充礼包----------------------------------------------------
function Rechage_reward:get_rechage_reward()
	return reward_t.f_get_rechage_reward()
end

function Rechage_reward:can_be_fetch(char_id,type)
	local gift_con = self:get_container(char_id)
	if not gift_con then return end

	return gift_con:can_fetch()

	--if gift_con:get_type() > 1 then
		--return 27607
	--elseif gift_con:get_type() == 1 and gift_con:get_flag() == 1 then
		--return 27607
	--else
		--local dbh = get_dbh_web()
		--local rs = dbh:selectrow_ex("select * from gift_list where char_id =? and type = ?",char_id,type)
		--if rs ~= nil then
			--if rs.status == 0 then
				--return 0
			--else
				--return 27607
			--end
		--end
		--return 27606
	--end
end

function Rechage_reward:fetch_flag(char_id, type)
	local gift_con = self:get_container(char_id)
	if not gift_con then return end

	local gift_type = gift_con:get_type()
	local gift_flag = gift_con:get_flag()
	if gift_type > 1 then
		return 1
	elseif gift_type == 1 then
		if gift_flag == 1 then
			return 2
		elseif gift_flag == 0 then
			return 0
		else
			return 1
		end
	else 
		local dbh = get_dbh_web()
		local rs = dbh:selectrow_ex("select * from gift_list where char_id =? and type = ?",char_id,type)
		if rs ~= nil then
			if rs.status == 0 then
				return 0  --可以领取
			else
				return 2  --没得领，没充值
			end
		end
		return 2
	end
end

function Rechage_reward:fetch_item(char_id)
	--local item = self:get_rechage_reward()
	--if item == nil then return end 
--
	--local player = g_obj_mgr:get_obj(char_id)
	--local pack_con = player:get_pack_con()
	--
	--local item_id_list = {}
	--for k,v in pairs(item or {})do
		--item_id_list[k] = {}
		--item_id_list[k].type = 1
		--item_id_list[k].item_id = tonumber(v[1])
		--item_id_list[k].number = v[2]
	--end
--
	--local free_slot = pack_con:get_bag_free_slot_cnt()
	--if free_slot <=0  then
		--return 43004
	--end
--
	--if  pack_con:add_item_l(item_id_list, {['type']=ITEM_SOURCE.FIRST_REWARD}) ~= 0 then
		--return 27003
	--end
	--self:update_flag(char_id,1)
	--return 0

	local gift_con = self:get_container(char_id)
	if not gift_con then return end

	return gift_con:fetch_item()
end

--function Rechage_reward:update_flag(char_id,type)
	--local str = string.format("update gift_list set status =1,receive_time=%d where char_id = %d and type = %d",ev.time,char_id,type)
--
	--local dbh = get_dbh_web()
	--dbh:execute(str)
--
	--self.reward_list[char_id] = {}
	--self.reward_list[char_id].status = 1
	--self.reward_list[char_id].receive_time = ev.time
--end

----------------------------------------充值--------------------------------------------
function Rechage_reward:add_money(char_id,money,rechage_id)
	--print("Rechage_reward:add_money", char_id,money,rechage_id)
	if money == nil or char_id ==nil then return end
	local player = g_obj_mgr:get_obj(char_id)
	if player == nil then return end
	--print("add_money2")
	local pack_con = player:get_pack_con()
	pack_con:add_money(MoneyType.JADE, money, {['type']=MONEY_SOURCE.CHARGE})
	self:update_flag_by_rechage_id(rechage_id)
	
	--print("add_money3")
	local gift_con = self:get_container(char_id)
	gift_con:add_money(money)
	gift_con:reset_type_flag()

	--local func_con = player:get_function_con()
	--func_con:recharge()
	
	--充值元宝
	local pkt = {}
	pkt.char_id = char_id
	pkt.money = money
	g_svsock_mgr:send_server_ex(COMMON_ID,char_id,CMD_M2C_EXCHANGE_GIFT_ADD_MOENY_REQ,pkt)
	integral.charge(char_id,money)
	return 0
end

function Rechage_reward:get_money_by_rechage_id(rechage_id)
	local dbh = get_dbh_web()

	local rs = dbh:selectrow_ex("select gold, char_id from pay_order where order_id = ?",rechage_id)
	if rs ~= nil then
		return tonumber(rs.gold),tonumber(rs.char_id)
	end
	return nil , nil
end

function Rechage_reward:update_flag_by_rechage_id(rechage_id)
	local str = string.format("update pay_order set status = 1 where order_id ='%s'",rechage_id)
	--g_web_sql:write(str)
	local dbh = get_dbh_web()
	dbh:execute(str)
end

--------------------------------------登录-------------------------------------------------
function Rechage_reward:login(char_id)
	self.gift_con[char_id] = Rechage_gift(char_id)
	self.gift_con[char_id]:unserialize()

	--local dbh = get_dbh_web()
	--local rs = dbh:selectall("select gold,order_id,status from pay_order where char_id = ? and flag = ?",char_id, 0)
	--if rs ~= nil then
		--for k,v in pairs(rs or {}) do
			--if tonumber(v[3]) == 0 then
				--self:add_money(char_id,tonumber(v[1]),v[2])
			--else
				--self.gift_con[char_id]:add_money(tonumber(v[1]))	
			--end
		--end
	--end
	--self.gift_con[char_id]:reset_type_flag()
	--print("=========",self.gift_con[char_id]:get_type(),self.gift_con[char_id]:get_flag(),self.gift_con[char_id].money)
end

function Rechage_reward:logout(char_id)
	if self.gift_con[char_id] then
		self.gift_con[char_id]:serialize_to_db()
		self.gift_con[char_id] = nil
	end
end

function Rechage_reward:get_container(char_id)
	return self.gift_con[char_id]
end

Rechage_reward:init()