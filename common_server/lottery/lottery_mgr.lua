
-----------------------------------寄售行-----------------------------
require("lottery.lottery_numbers")
require("lottery.lottery_winners")
require("lottery.lottery_mgr_db")


--定时存盘时间
local update_time = 110

Lottery_mgr = oo.class(nil, "Lottery_mgr")

local add_ratio = {500, 200, 100, 50}
local mul_ratio = {0.25, 0.2, 0.1, 0.01}
local add_table	= {0, 0, 0, 0}

all_bonus = {0,0,0,0}

--定时器1   定时存盘
function Lottery_mgr:update_time_lottery()
	local f = function()
		if self.lottery_numbers then
			self:update_current_lottery()
		end
		ev:timeout(update_time, self:update_time_lottery())	
	end
	return f
end

--2     推算下周1凌晨1:00抽奖算法 并定好下次抽奖和公布时间
--function Lottery_mgr:draw_lottery_time()
	--local f = function()
		--self:draw_lottery()
--
		--local draw_time = f_get_sunday() + 8 * 24 * 3600 + 1800   --下周一0:30抽奖 
		--ev:timeout(draw_time - ev.time, self:draw_lottery_time())		
	--end
	--return f
--end


function Lottery_mgr:__init()
	local submit_time
	if ev.time < f_get_sunday() + 24 * 3600 +1 then
		submit_time = f_get_sunday() + 24 * 3600 + 1
	else
		submit_time = f_get_sunday() + 8 * 24 * 3600 + 1
	end
	local day_table	  = os.date("*t" , submit_time)
	self.period 	  = (day_table.year % 100) * 10000 + day_table.month * 100 + day_table.day
	--累积奖金
	self.bonus		  = {}
	for i = 1 , 4 do
		self.bonus[i] = 0
	end

	self:load_current_lottery(self.period)
	
	if ev.time < f_get_sunday() + 12 * 3 * 3600 + 10 * 60 then
		self.winners_period_time = f_get_sunday() + 12 * 3 * 3600 + 10 * 60
	else
		self.winners_period_time = f_get_sunday() + 12 * 3 * 3600 + 10 * 60 + 7 * 24 * 3600
	end
	self.winners_period = {}
	self:load_three_info()
	

	--定时存盘
	--ev:timeout(update_time, self:update_time_lottery())	
	self.update_time = ev.time + update_time

	--定时开奖
	--ev:timeout(submit_time + 1800 - ev.time , self:draw_lottery_time())	
	local draw_time = f_get_sunday() + 24 * 3600 + 10
	if draw_time < ev.time then
		draw_time = draw_time + 7 * 24 * 3600
	end
	self.draw_time = draw_time

	--定时找到公布时间,改通用方法
	local notice_time = f_get_sunday() + 36 * 3600 + 60 * 2
	if notice_time < ev.time then
		notice_time = notice_time + 7 * 24 * 3600
	end
	self.notice_time = notice_time
end

function Lottery_mgr:get_click_param()
	return self, self.on_timer,3,nil
end

function Lottery_mgr:on_timer()
	if ev.time > self.winners_period_time then
		self:load_three_info(1)
		self.winners_period_time = self.winners_period_time + 7 * 24 * 3600
	end
	if ev.time > self.notice_time then
		self.lottery_winners:notice_lottery()
		self.notice_time = self.notice_time + 7 * 24 * 3600
	end
	if ev.time > self.draw_time then
		self:draw_lottery()
		self.draw_time = self.draw_time + 7 * 24 * 3600
	end
	if ev.time > self.update_time then
		if self.lottery_numbers then
			self:update_current_lottery()
		end
		self.update_time = self.update_time + update_time
	end
end

-------------------------------------更新all_bonus
function Lottery_mgr:update_all_bonus(char_id,number)
	for i = 1,4 do
		all_bonus[i] = self.bonus[i]
	end
	return 0
end

-------------------------------------选择一个号码
function Lottery_mgr:choice_number(char_id,number)
	self.lottery_numbers:choice_number(char_id,number)
	return 0
end


------------------------------------抽奖
function Lottery_mgr:draw_lottery()

	---判断期数是否对，测试可注释
	local submit_time = f_get_sunday() + 8 * 24 * 3600 + 1
	local day_table	  = os.date("*t" , submit_time)
	local now_period  = (day_table.year % 100) * 10000 + day_table.month * 100 + day_table.day
	
	--if now_period <= self.period then
		--return false
	--end

	self.period = now_period

	local winners_list = self.lottery_numbers:draw_lottery()
	
	local total_count = self.lottery_numbers:get_total_count()

	for i = 1 , 4 do
		local flags = true
		for k,v in pairs(winners_list[i]) do
			if k ~= 'bonus' then
				for k1 , v1 in pairs(v) do
					flags = false					--有人中奖
					break
				end
			end
		end
		if flags then
			self.bonus[i] = self.bonus[i] + add_ratio[i] + math.ceil(total_count * mul_ratio[i])
			winners_list[i]['bonus'] = 0
		else
			winners_list[i]['bonus'] = self.bonus[i] + add_ratio[i] + math.ceil(total_count * mul_ratio[i])
			self.bonus[i] = 0
		end
	end

	local data = {}
	data.period		= self.period
	data.valid_time = submit_time
	data.winners	= winners_list

	self.lottery_winners = Lottery_winners(data)
	self.lottery_numbers = Lottery_numbers()

	self:update_winners_info()
	self:winners_period_to_map()
	self:update_all_bonus()

	--if true then
		--self.lottery_winners:notice_lottery()
		--print("self.lottery_winners =",j_e(self.lottery_winners))
	--end
	return true
end


-------------------------------------load数据库
function Lottery_mgr:load_current_lottery(period)
	local rs= Lottery_mgr_db:Loadlottery(period)
	if rs == nil then 
		self.lottery_numbers = Lottery_numbers()
		self.lottery_winners = Lottery_winners()
	else
		local numbers
		local winners
		local bonus	
		for k , v in pairs(rs) do
			numbers = v.numbers
			winners = v.winners
			bonus	= v.bonus
			break
		end

		self.lottery_numbers = Lottery_numbers(numbers)
		self.lottery_winners = Lottery_winners(winners)

		
		for i = 1 , 4 do
			self.bonus[i] = bonus[i]
		end

	end
	self:update_all_bonus()
end

-------------------------------------update数据库
function Lottery_mgr:update_current_lottery()
	local db_data = self:spec_serialize_to_db()
	local rs= Lottery_mgr_db:update_Lottery(self.period,db_data)

	return
end

function Lottery_mgr:spec_serialize_to_db()
	local pkt = {}
	pkt.period	= self.period
	pkt.numbers = self.lottery_numbers:spec_serialize_to_db()
	pkt.winners = self.lottery_winners:spec_serialize_to_db()
	pkt.bonus	= self.bonus
	return pkt
end

--------------------------------------发送到map，更新中奖者信息
function Lottery_mgr:spec_serialize_to_map()
	local pkt = {}
	pkt = self.lottery_winners:spec_serialize_to_map()
	return pkt
end

function Lottery_mgr:per_bonus()
	local pkt = self.winners_period
	if self.winners_period and self.winners_period[1] and self.winners_period[1].winners then
		for i = 1, table.getn(self.winners_period[1].winners) do
			local counts = 0
			local bonus  = 0
			for k, v in pairs(self.winners_period[1].winners[i]) do
				if k ~= 'bonus' then
					for kk, vv in pairs(v) do
						counts = counts + vv
					end
				else 
					bonus = v
				end
			end
			if counts ~= 0 then
				pkt[1].winners[i].bonus = math.ceil(bonus/counts)
			end
		end
	end
	return pkt
end

--每期获奖查询
function Lottery_mgr:winners_period_to_map(conn_id)
	local pkt = {}
	pkt = self:per_bonus()
	if conn_id then
		g_server_mgr:send_to_server(conn_id,0, CMD_LOTTERY_WINNERS_PERIOD_C, pkt)
	else
		g_server_mgr:send_to_all_map(0,CMD_LOTTERY_WINNERS_PERIOD_C,pkt)
	end
	return 0
end

--每期获奖号码
function Lottery_mgr:update_winners_info(conn_id)
	local pkt = {}
	pkt = self.lottery_winners:spec_serialize_to_map()
	if conn_id then
		g_server_mgr:send_to_server(conn_id,0, CMD_LOTTERY_UPDATE_WINNERS_C, pkt)
	else
		g_server_mgr:send_to_all_map(0,CMD_LOTTERY_UPDATE_WINNERS_C,pkt)
	end

	return 0
end

function Lottery_mgr:load_three_info(type)
	local loc_time
	if type or ev.time > f_get_sunday() + 3600 * 36 + 10 * 60 then
		loc_time =  f_get_sunday() + 8 * 24 * 3600 + 1
	else
		loc_time =  f_get_sunday() + 1 * 24 * 3600 + 1
	end
	self.winners_period = {}
	for i = 1, 3 do
		local submit_time = loc_time - (i - 1) * 7 * 24 * 3600
		local submit_time1 = submit_time - 7 * 24 * 3600
		local day_table	  = os.date("*t" , submit_time)
		local day_table1	  = os.date("*t" , submit_time1)
		local period  = (day_table.year % 100) * 10000 + day_table.month * 100 + day_table.day
		local period1  = (day_table1.year % 100) * 10000 + day_table1.month * 100 + day_table1.day
		local pkt = self:winners_period_info(period,period1,i)
		
		table.insert(self.winners_period,pkt)
	end 
	if type then
		self:winners_period_to_map()
	end
	return
end

function Lottery_mgr:winners_period_info(period, period1,lvl)
	local pkt = {}
	pkt.period = period1
	pkt.winners = {}
	local flags = false
	local rs= Lottery_mgr_db:Loadlottery(period)
	if rs ~= nil then
		for k , v in pairs(rs) do
			for i = 1, 3 do
				pkt.winners[i] = {}
				for k , v in pairs(v.winners.winners[i]) do
					if k == "bonus" then
						flags = true
						if lvl == 1 and v == 0 then
							pkt.winners[i]['bonus'] = all_bonus[i]
						else
							pkt.winners[i]['bonus'] = v
						end
					else
						local l_number = k
						pkt.winners[i][k] = {}
						for k1, v1 in pairs(v) do
							local char_id = tonumber(k1)
							local  tmp_name = g_player_mgr.all_player_l[tonumber(k1)]["char_nm"]
							if pkt.winners[i][k][tmp_name] then
								pkt.winners[i][k][tmp_name] = pkt.winners[i][k][tmp_name] + v1
							else
								pkt.winners[i][k][tmp_name] = v1
							end
						end
					end
				end
			end
			break
		end
	end
	return pkt
end
