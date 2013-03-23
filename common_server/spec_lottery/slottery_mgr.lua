
--2012-01-05
--cqs
--实物抽奖

-----------------------------------实物抽奖-----------------------------
require("spec_lottery.slottery_numbers")
--require("spec_lottery.slottery_winners")
require("spec_lottery.slottery_mgr_db")

local lottery_loader = require("config.loader.spec_lottery_loader")


Slottery_mgr = oo.class(nil, "Slottery_mgr")

--定时存盘时间
local update_time = 180

--延迟发邮件时间
local delay_time = 60 * 5 

--需发邮件的中奖者
local winners_email = {}

--每等级物品信息
local reward_lvl_string = {}
--每次的领奖结束月日
day_table = {}


function Slottery_mgr:__init()
	self.status = 0			--0所有活动都过了   1等待开始活动	2活动中

	self:init_period()

	self:init_notice()		

	self:init_accept_numbers()

	--定时存盘
	self.update_time = ev.time + update_time

end


--计算公布时间,启动和算奖后进行
function Slottery_mgr:init_period()
	self.status, self.period, self.change_t = lottery_loader.get_recently_period()
end


--计算下期时间 启动和算奖后进行
function Slottery_mgr:init_notice()
	self.notice_t, self.period_notice = lottery_loader.get_notice_time()
end

--初始化接受填写号码
function Slottery_mgr:init_accept_numbers()
	if self.status == 2 then
		local rs= Slottery_mgr_db:LoadNumbers(self.period)
		if rs == nil then 
			self.lottery_numbers = Slottery_numbers()
		else
			local numbers
			for k , v in pairs(rs) do
				numbers = v.numbers
				break
			end

			self.lottery_numbers = Slottery_numbers(numbers)
		end
	end
end

--计算中奖查询公布时间
function Slottery_mgr:update_number()
	if self.status == 2 then
		local data = self.lottery_numbers:spec_serialize_to_db()
		Slottery_mgr_db:update_numbers(self.period, data)
	end
end

----------------计时器
function Slottery_mgr:get_click_param()
	return self, self.on_timer,3,nil
end

function Slottery_mgr:on_timer()
	if ev.time > self.notice_t then				--公告时间到
		self:notice_number(self.period_notice)

		self.notice_t = self.notice_t + 10000000
	end 

	if self.status == 2 then
		if ev.time > self.update_time then		--活动中 存盘
			self:update_number()

			self.update_time = self.update_time + update_time
		end

		if ev.time > self.change_t then			--时间到开奖
			self:draw_lottery()					--计算号码

			self:init_notice()					--计算公布时间
				
			self:init_period()					--计算下期时间

			self:init_accept_numbers()			--算完奖，重新初始化接受号码
			return
		end

	elseif self.status == 1 then				--时间到活动开始
		if ev.time > self.change_t then
			self.status = 2
			self:init_accept_numbers()
			self.change_t = lottery_loader.get_period_over_t(self.period)
			return
		end

	end
end

-------------------------------------***外部接口***------------
function Slottery_mgr:choice_number(char_id, number)
	if self.status == 2 then
		self.lottery_numbers:choice_number(char_id, number)
		return 0
	else
		return 1
	end
end


------------------------------------抽奖
function Slottery_mgr:draw_lottery()
	if self.status ~= 2 then
		return false
	end

	self:update_number()

	local winners_list, winner_name = self.lottery_numbers:draw_lottery()

	Slottery_mgr_db:update_winners(self.period, winners_list, winner_name)

	--if true then
		--print("self.lottery_winners =",j_e(winners_list))
	--end
	self.lottery_numbers = nil
	return true
end

--------------------------------------发送到map，更新中奖者信息
function Slottery_mgr:notice_number(period)
	print("152 ")
	local winners = {}
	local rs= Slottery_mgr_db:LoadWinners(period)
	if rs == nil then 
		return
	else
		for k , v in pairs(rs) do
			winners = v.winners
			break
		end
	end
	
	--构造字符串并广播
	local pkt = {}
	winners_email = {}


	local all_flags = true
	for k , v in pairs(winners[3]) do
		if k ~= 'bonus' then
			all_flags = false					--有人中奖
			break
		end
	end

	if all_flags then

		return false
	end
	pkt.period = period
	pkt.id = lottery_loader.get_series_by_period(period)

	for i = 1 , 27 do
		pkt[i] = {}
	end

	pkt[1].type 	= 0
	pkt[1].period = period


	pkt[2].type		= 1	
	pkt[2].lvl	 	= 4

	local i = 1
	for k , v in pairs(winners[4]) do
		if k ~= 'bonus' then
			pkt[2+i].type		= 2
			pkt[2+i].lvl		= 4
			pkt[2+i].number_count		= i
			pkt[2+i].number	= k
			i = i + 1
		end
	end

	local flags = true
	local name = {}
	local winners_count = 0
	local lottery_count = 0

	for k,v in pairs(winners[4]) do
		if k ~= 'bonus' then
			for k1 , v1 in pairs(v) do
				flags = false					--有人中奖
				local char_id = tonumber(k1)
				winners_count = winners_count + 1
				lottery_count = lottery_count + v1

				local  t = 1
				local  tmp_name = g_player_mgr.all_player_l[char_id]["char_nm"]
				local tmp_flags = true
				for k , v in pairs(name) do
					if v == tmp_name then
						tmp_flags = false
						break
					end
					t = t + 1
					if t > 3 then
						tmp_flags = false
						break
					end
				end
				if tmp_flags then
					table.insert(name , tmp_name) 
				end
			end
		end
	end
	if flags then
		pkt[13].type = 4
		pkt[13].lvl  = 4
	else 
		pkt[13].type  = 3
		pkt[13].lvl  = 4
		pkt[13].player_count = winners_count
		pkt[13].name  = name

		

		for k,v in pairs(winners[4]) do
			if k ~= 'bonus' then
				for k1 , v1 in pairs(v) do				--有人中奖
					local char_id = tonumber(k1)
					local s_pk = {}
					s_pk.char_id = char_id
					s_pk.bonus = pkt[13].bonus
					s_pk.lvl = 4
					table.insert(winners_email, s_pk)
				end
			end
		end

	end


	pkt[14].type	= 1	
	pkt[14].lvl	 	= 3

	i = 1
	for k , v in pairs(winners[3]) do
		if k ~= 'bonus' then
			pkt[14+i].type		= 2
			pkt[14+i].lvl		= 3
			pkt[14+i].number_count		= i
			pkt[14+i].number	= k
			i = i + 1
		end
	end

	flags = true
	name = {}
	winners_count = 0
	lottery_count = 0

	for k,v in pairs(winners[3]) do
		if k ~= 'bonus' then
			for k1 , v1 in pairs(v) do
				flags = false					--有人中奖
				local char_id = tonumber(k1)
				winners_count = winners_count + 1
				lottery_count = lottery_count + v1

				local  t = 1
				local  tmp_name = g_player_mgr.all_player_l[char_id]["char_nm"]
				local tmp_flags = true
				for k , v in pairs(name) do
					if v == tmp_name then
						tmp_flags = false
						break
					end
					t = t + 1
					if t > 3 then
						tmp_flags = false
						break
					end
				end
				if tmp_flags then
					table.insert(name , tmp_name) 
				end
			end
		end
	end
	if flags then
		pkt[20].type = 4
		pkt[20].lvl = 3
	else 
		pkt[20].type  = 3
		pkt[20].lvl = 3
		pkt[20].player_count = winners_count
		pkt[20].name = name

		for k,v in pairs(winners[3]) do
			if k ~= 'bonus' then
				for k1 , v1 in pairs(v) do				--有人中奖
					local char_id = tonumber(k1)
					local s_pk = {}
					s_pk.char_id = char_id
					s_pk.bonus = pkt[20].bonus
					s_pk.lvl = 3
					table.insert(winners_email, s_pk)
				end
			end
		end

	end

	pkt[21].type	= 1	
	pkt[21].lvl	 	= 2

	i = 1
	for k , v in pairs(winners[2]) do
		if k ~= 'bonus' then
			pkt[21+i].type		= 2
			pkt[21+i].lvl		= 2
			pkt[21+i].number_count	= i
			pkt[21+i].number	= k
			i = i + 1
		end
	end

	flags = true
	name = {}
	winners_count = 0
	lottery_count = 0

	for k,v in pairs(winners[2]) do
		if k ~= 'bonus' then
			for k1 , v1 in pairs(v) do
				flags = false					--有人中奖
				local char_id = tonumber(k1)
				winners_count = winners_count + 1
				lottery_count = lottery_count + v1

				local  t = 1
				local  tmp_name = g_player_mgr.all_player_l[char_id]["char_nm"]
				local tmp_flags = true
				for k , v in pairs(name) do
					if v == tmp_name then
						tmp_flags = false
						break
					end
					t = t + 1
					if t > 3 then
						tmp_flags = false
						break
					end
				end
				if tmp_flags then
					table.insert(name , tmp_name) 
				end
			end
		end
	end
	if flags then
		pkt[24].type = 4
		pkt[24].lvl = 2
	else 
		pkt[24].type  = 3
		pkt[24].lvl = 2
		pkt[24].player_count = winners_count
		pkt[24].name = name

		for k,v in pairs(winners[2]) do
			if k ~= 'bonus' then
				for k1 , v1 in pairs(v) do				--有人中奖
					local char_id = tonumber(k1)
					local s_pk = {}
					s_pk.char_id = char_id
					s_pk.bonus = pkt[24].bonus
					s_pk.lvl = 2
					table.insert(winners_email, s_pk)
				end
			end
		end

	end

	pkt[25].type	= 1	
	pkt[25].lvl	 	= 1

	i = 1
	for k , v in pairs(winners[1]) do
		if k ~= 'bonus' then
			pkt[25+i].type		= 2
			pkt[25+i].lvl		= 1
			pkt[25+i].number_count		= i
			pkt[25+i].number	= k
			i = i + 1
		end
	end

	flags = true
	name = {}
	winners_count = 0
	lottery_count = 0

	for k,v in pairs(winners[1]) do
		if k ~= 'bonus' then
			for k1 , v1 in pairs(v) do
				flags = false					--有人中奖
				local char_id = tonumber(k1)
				winners_count = winners_count + 1
				lottery_count = lottery_count + v1

				local  t = 1
				local  tmp_name = g_player_mgr.all_player_l[char_id]["char_nm"]
				local tmp_flags = true
				for k , v in pairs(name) do
					if v == tmp_name then
						tmp_flags = false
						break
					end
					t = t + 1
					if t > 3 then
						tmp_flags = false
						break
					end
				end
				if tmp_flags then
					table.insert(name , tmp_name) 
				end
			end
		end
	end
	if flags then
		pkt[27].type = 4
		pkt[27].lvl	 = 1
	else 
		pkt[27].type  = 3
		pkt[27].lvl	 = 1
		pkt[27].player_count = winners_count
		pkt[27].name = name

		for k,v in pairs(winners[1]) do
			if k ~= 'bonus' then
				for k1 , v1 in pairs(v) do				--有人中奖
					local char_id = tonumber(k1)
					local s_pk = {}
					s_pk.char_id = char_id
					s_pk.bonus = pkt[27].bonus
					s_pk.lvl = 1
					table.insert(winners_email, s_pk)
				end
			end
		end

	end

	pkt = Json.Encode(pkt)
	for k , v in pairs(g_player_mgr.online_player_l) do
		g_svsock_mgr:send_server_ex(WORLD_ID, k, CMD_C2W_NOTICE_SPEC_LOTTERY_S, pkt, true)
	end

	reward_lvl_string = lottery_loader.get_period_reward_string(period)
	day_table = lottery_loader.get_period_month_day(period)

	ev:timeout(delay_time,self:structure_all_email(period))

end

function Slottery_mgr:structure_all_email(period)
	local f = function()
		for k , v in pairs(winners_email) do
			self:structure_email(v.char_id, v.lvl, period)
		end
	end
	return f
end

---------构造中奖玩家邮件
function Slottery_mgr:structure_email(char_id, lvl, period )
	local title  = string.format(f_get_string(555),	lottery_loader.get_period_activity_name(period))	--g_u("恭喜您的xxxx彩票中奖了!")
	local lvl_type 
	if lvl == 1 then
		lvl_type = f_get_string(545)	--g_u("一等奖")
	elseif lvl == 2 then
		lvl_type = f_get_string(546)	--g_u("二等奖")
	elseif lvl == 3 then
		lvl_type = f_get_string(547)	--g_u("三等奖")
	elseif lvl == 4 then
		lvl_type = f_get_string(548)	--g_u("幸运奖")
	end

	local content	= string.format(f_get_string(554),
										period, lvl_type, reward_lvl_string[lvl], day_table.month, day_table.day)

	local g_email = Email(-1,char_id,title,content,0,Email_type.type_common,Email_sys_type.type_sys,{})
	if g_email ~= nil then
		g_email_mgr:add_email(g_email)
	end
end


