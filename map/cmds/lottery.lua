
-----------------------------------处理与common的信息
-----------------------------------杂类，其实可以封装起来，但内容不多懒得搞
--local winners_pkt = {
	----一等奖
        --{["bonus"] = 10000,		--表示该等级总奖金
	--["251"]={["809"]=2}  },	--表示号码252，有玩家ID：809的买了2注(其实领奖不需要考虑玩家ID)  则使用252号码抽奖券可得10000 / 2的礼券
	----2等奖
        --{["bonus"] = 5000,
	--["888"]={["779"]=1},  ["818"]={["779"]=3}  },
--
        --{["bonus"] =2000,
	--["188"]={["779"]=1},["118"]={["779"]=3},["218"]={["779"]=3}},
--
        --{["bonus"] = 1000,
	--["388"]={["779"]=1},["318"]={["779"]=3},["418"]={["779"]=3},["512"]={["779"]=3}}
--}
local winners_info = {}
local winners_period = {}
winners_period.list = {}
Sv_commands[0][CMD_LOTTERY_UPDATE_WINNERS_C] = 
function(conn, char_id, pkt)
	for i = 1 , 4 do
		winners_info[i] = {}
		if pkt[i] and type(pkt[i]) =='table' and pkt[i] ~= {} then
			winners_info[i].bonus = pkt[i].bonus
			winners_info[i].list  = {}
			local number_count = 0
			for k , v in pairs(pkt[i]) do
				if k ~= 'bonus' and v ~= {} then
					table.insert(winners_info[i].list,tonumber(k))
					for k1 , v1 in pairs(v) do
						number_count = number_count + v1
					end
				end
			end
			winners_info[i].count = number_count
		end
	end
end

Sv_commands[0][CMD_LOTTERY_WINNERS_PERIOD_C] = 
function(conn, char_id, pkt)
	winners_period.list = pkt
	return
end


--获奖查询
Clt_commands[1][CMD_B2S_DEMAND_LOTTERY_B] =
	function(conn, pkt)
		local t_pkt = winners_period
		g_cltsock_mgr:send_client(conn.char_id, CMD_B2S_DEMAND_LOTTERY_S, t_pkt)
	end


function f_get_lottery_lvl(number)
	for i = 1, 4 do
		for k , v in pairs(winners_info[i].list) do
			if number == v then
				return i
			end
		end
	end
end

function f_get_lottery_bonus(char_id,number)
	local player = g_obj_mgr:get_obj(char_id)
	if not player then
		return
	end
	local pack_con = player:get_pack_con()

	local lvl = f_get_lottery_lvl(number)
	local bonus  
	if lvl then
		if winners_info[lvl].count >= 1 then
			bonus = math.ceil(winners_info[lvl].bonus / winners_info[lvl].count)
			local args = {}
			args.level = lvl
			g_event_mgr:notify_event(EVENT_SET.EVENT_GET_REWARD, char_id, args)
		else
			bonus = 2
		end
	else
		bonus = 2
	end
	local money_list = {}
	money_list[MoneyType.GIFT_JADE] =  bonus

	local str = " char_id:" ..char_id .. " get reward! number:" .. number .. " bonus:" .. bonus
	g_lottery_log:write(str)

	pack_con:add_money_l(money_list, {['type'] = MONEY_SOURCE.WIN_LOTTERY})

	if lvl then
		f_broadcast_lottery_item(1, char_id, player:get_name(), lvl, nil, nil, bonus)
	end

	return 
end

-------------********实物抽奖******--------------
function f_get_spec_lottery_bonus(char_id, number)
	local player = g_obj_mgr:get_obj(char_id)
	if not player then
		return 1
	end
	local pack_con = player:get_pack_con()

	local e_code, lvl = g_spec_lottery_mgr:get_reward_lvl(number)
	if e_code ~= 0 then return e_code end
	--不中1~4 则lvl=99 安慰奖
	if not lvl then
		lvl = 99
	end

	local reward_l = g_spec_lottery_mgr:get_reward_info(lvl)
	--是否能加奖励
	local item_l = table.copy(reward_l.item_l)
	e_code = pack_con:check_add_item_l_inter_face(item_l) 
	if e_code ~= 0 then return e_code end

	pack_con:add_money_l(reward_l.money_l, {['type'] = MONEY_SOURCE.WIN_SPEC_LOTTERY})

	pack_con:add_item_l(reward_l.item_l, {['type']=ITEM_SOURCE.WIN_SPEC_LOTTERY}) 

	--写获奖记录日志
	local str = string.format("insert log_lucky set active_id=%d  ,char_id=%d, char_name='%s', date='%s', gift=%d, time=%d, num=%d",
					g_spec_lottery_mgr:get_series_id(), char_id, player:get_name(), g_spec_lottery_mgr:get_period_s(), lvl, os.time(), number)
	f_multi_web_sql(str)

	--广播
	if lvl == 1 or lvl == 2 or lvl == 3 or lvl == 4 then
		f_broadcast_lottery_item(2, char_id, player:get_name(), lvl, g_spec_lottery_mgr:get_period_s(), g_spec_lottery_mgr:get_series_id())
	end

	return 0
end

--实物获奖查询
Clt_commands[1][CMD_B2S_DEMAND_SPEC_LOTTERY_B] =
	function(conn, pkt)
		local t_pkt = g_spec_lottery_mgr:get_series_info()
		g_cltsock_mgr:send_client(conn.char_id, CMD_B2S_DEMAND_SPEC_LOTTERY_S, t_pkt)
	end


