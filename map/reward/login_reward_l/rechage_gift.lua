
local reward_t = require("config.reward_config")

Rechage_gift = oo.class(nil, "Rechage_gift")

function Rechage_gift:__init(char_id)
	self.char_id = char_id
	self.money = 0
	self.type = 1

	self.flag = 1 --0为可以领取，1为不可以领取 2已领取
end

function Rechage_gift:get_type()
	return self.type
end

function Rechage_gift:get_flag()
	return self.flag
end

function Rechage_gift:get_rechage_reward()
	return reward_t.f_get_rechage_reward()
end

function Rechage_gift:add_money(money)
	self.money = self.money + money
end

function Rechage_gift:reset_type_flag()
	if self.type >= 1 and self.flag ~= 0 then
		local index = 0
		local reward = self:get_rechage_reward()
		local size = table.size(reward)
		if self.type <= size then
			for k, v in ipairs(reward) do
				if self.money >= v[3] then
					if self.flag == 1 and self.type <= k then
						--print("self.money1",self.money,v[3], k)
						--self.type = k
						self.flag = 0
						index = 1
						break
					elseif self.flag == 2 and self.type < k then
						--print("self.money2",self.money,v[3], k)
						self.type = k
						self.flag = 0
						index = 1
						break
					end
				else
					if self.flag == 2 and self.type < k then
						self.type = k
						self.flag = 1
						index = 1
						break
					end
				end 
			end	
		end

		if index == 1 then
			local ret = self:serialize_to_net()
			g_cltsock_mgr:send_client(self.char_id, CMD_RECHAGE_GIFT_FETCH_S, ret)
		end
	end
end

function Rechage_gift:can_fetch()
	local reward = self:get_rechage_reward()
	local size = table.size(reward)
	if self.type > size then return end

	if self.flag ~= 0 then return 27607 end

	return 0
end

function Rechage_gift:fetch_item()
	--print("11111111111111111",self.type, self.flag, self.money)
	local reward = self:get_rechage_reward()
	local item = {{reward[self.type][1], reward[self.type][2]}}

	local player = g_obj_mgr:get_obj(self.char_id)
	local pack_con = player:get_pack_con()
	
	local item_id_list = {}
	for k,v in pairs(item or {})do
		item_id_list[k] = {}
		item_id_list[k].type = 1
		item_id_list[k].item_id = tonumber(v[1])
		item_id_list[k].number = tonumber(v[2])
	end

	local free_slot = pack_con:get_bag_free_slot_cnt()
	if free_slot <= 0 then
		return 43004
	end

	if  pack_con:add_item_l(item_id_list, {['type']=ITEM_SOURCE.FIRST_REWARD}) ~= 0 then
		return 27003
	end

	self.flag = 2
	if self.type == 1 then
		self:update_flag()
	end
	self:reset_type_flag()
	--print("22222222222222222",self.type, self.flag)
	self:serialize_to_db()
	return 0
end

function Rechage_gift:serialize_to_net()
	local reward = self:get_rechage_reward()

	local ret = {}
	ret.gift_id = reward[self.type][1]

	return ret
end

function Rechage_gift:update_flag()
	local str = string.format("update gift_list set status =1,receive_time=%d where char_id = %d and type = %d",ev.time,self.char_id,1)
	local dbh = get_dbh_web()
	dbh:execute(str)
end

function Rechage_gift:serialize_to_db()
	local ret = {}
	ret.char_id = self.char_id
	ret.type = self.type
	ret.flag = self.flag
	ret.money = self.money

	--print("serialize_to_db",j_e(ret))
	local dbh = f_get_db()
	local query = string.format("{char_id:%d}",self.char_id)
	local err_code = dbh:update("rechage_gift",query,Json.Encode(ret),true)
end

function Rechage_gift:unserialize()
	local dbh = f_get_db()
	local query =string.format("{char_id:%d}",self.char_id)
	local row, e_code = dbh:select_one("rechage_gift", nil, query)
	--print("111")
	if e_code == 0 and row ~= nil then
		self.type = row.type
		self.flag = row.flag
		self.money = row.money or 0
		--print("222",self.type, self.flag)
	--else
		--local dbh = get_dbh_web()
		--local rs = dbh:selectrow_ex("select * from gift_list where char_id =? and type = ?",self.char_id,1)
		--if rs ~= nil then
			----print("333")
			--if rs.status == 0 then
				--self.type = 1
				--self.flag = 0
			--elseif rs.status == 1 then
				--self.type = 1
				--self.flag = 2
			--end
		--else
			----print("444")
			--self.type = 1
			--self.flag = 1
		--end
	end 
end
