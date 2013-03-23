

local gbk_utf8 = function(val) return val end
local debug_print = print
--local debug_print = function() end
local _random = crypto.random
local _open_chests = require("chests.chests_analytical")

------Chests_func------------
Chests_func = oo.class(nil,"Chests_func")

function Chests_func:__init()
	self.chests_player_record = {}
end

function Chests_func:set_player_record(char_id, k_type)
	local list = {}
	list["money"] = 0
	list["radio"] = 0
	self.chests_player_record[char_id][k_type] = list 
end

--玩家char_id宝箱的有关消费记录
function Chests_func:chests_player_record_init(char_id)
	if self.chests_player_record[char_id] ~= nil then
		return
	end
	self.chests_player_record[char_id] = {}
	local time = _open_chests.get_number_chests_type()
	for i = 1, time do
		self:set_player_record(char_id, i)
	end
end

--构造包给client
function Chests_func:construct(gift_list)
	local spkt_flag = {}
	local s_pkt = {}
	local i = 1	
	for k, v in pairs(gift_list) do
		local id = v[1]
		if spkt_flag[id] == nil then
			spkt_flag[id] = i
			local list = {}
			list.type = 1
			list.item_id = id
			list.number = 1
			list.name = gbk_utf8(v[2])
			table.insert(s_pkt, list)
			i = i + 1
		else
			s_pkt[ spkt_flag[id] ].number = s_pkt[ spkt_flag[id] ].number + 1
		end
	end
	return s_pkt
end

--判断是否需要处理广播道具的问题
function Chests_func:is_judge_need_radio(char_id, k_type)
	if self.chests_player_record[char_id][k_type]["radio"] ~= 0 then
		self:set_player_record(char_id, k_type)
		return false
	end

	money = self.chests_player_record[char_id][k_type]["money"]
	local compensation_money = _open_chests.get_open_chests_ompensation(k_type)	
	if compensation_money > money then
		return false					
	end
	return true							
end

--根据随机数number返回那个物品或者道具
function Chests_func:get_one_gift(gift_temp, number)
	local sum = 0
	local status = 0			
	local i
 
	for k, v in pairs(gift_temp) do
		sum = sum + v[3]
		if number <= sum then
			if v[4] == 1 then			
				status = 1
			end
			i = k
			break
		end
	end
	return gift_temp[i], status
end

--检查玩家元宝是个足够,并扣除玩家的元宝
function Chests_func:enough_money_and_dec_money(char_id, k_type, money_type)
	local chests_money = _open_chests.get_open_chests_money(k_type, money_type)
	local player = g_obj_mgr:get_obj(char_id)
	local pack_con = player:get_pack_con()
	local left_money = pack_con:get_money()			

	if pack_con:check_money_lock(MoneyType.JADE) then
		return
	end
	if left_money.jade < chests_money then
		return 	200052									
	end

	self.chests_player_record[char_id][k_type]["money"] = self.chests_player_record[char_id][k_type]["money"] + chests_money
	pack_con:dec_money(MoneyType.JADE, chests_money, {['type']=MONEY_SOURCE.CHEST})	

	local str = string.format("dec %d money from char(%d) ", chests_money, char_id)
	g_chests_log:write(str)

	return 0
end

--返回元宝给玩家
function Chests_func:give_back_money(char_id, k_type, money_type)
	local chests_money = _open_chests.get_open_chests_money(k_type, money_type)
	local player = g_obj_mgr:get_obj(char_id)
	local pack_con = player:get_pack_con()
	local left_money = pack_con:get_money()			

	self.chests_player_record[char_id][k_type]["money"] = self.chests_player_record[char_id][k_type]["money"] - chests_money
	pack_con:add_money(MoneyType.JADE, chests_money)	

	local str = string.format("give back %d money to char(%d) ", chests_money, char_id)
	g_chests_log:write(str)

	return 0
end

--随机抽取相应的物品或装备 同时判断玩家是否应该有一个广播物品或装备的逻辑处理
function Chests_func:get_random_list(char_id, k_type, money_type)
	local gift_list = {}			
	local gift_radio_list = {}		
	local left_sum = 0
	local right_sum = _open_chests.get_open_chests_k_type_sum(k_type)
	local chests_times = _open_chests.get_open_chests_time(k_type, money_type)
	local status = 0
	local radio_flag = false

	gift_temp = _open_chests.get_open_chests(k_type)
	for i = 1, chests_times - 1 do
		local number = _random(left_sum, right_sum+1)		
		gift_list[i], status = self:get_one_gift(gift_temp, number)
		if status == 1 then
			table.insert(gift_radio_list, gift_list[i])
			radio_flag = true
		end
	end

	if radio_flag == false then
		status = self:is_judge_need_radio(char_id, k_type)
		if status then
			left_sum = _open_chests.get_open_chests_radio_value(k_type) + 1
		end
	end
	number = _random(left_sum, right_sum+1)	
	gift_list[chests_times], status = self:get_one_gift(gift_temp, number)
	if status == 1 then
		radio_flag = true
		table.insert(gift_radio_list, gift_list[chests_times])
	end

	local str = string.format(" char(%d) , chests_type(%d) gift_list: %s ", char_id, k_type, Json.Encode(gift_list))
	g_chests_log:write(str)

	if radio_flag then
		self:set_player_record(char_id, k_type)
		return gift_list, gift_radio_list
	end

	return gift_list, nil
end