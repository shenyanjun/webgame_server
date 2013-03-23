
--2012-01-05
--cqs
--实物抽奖

-----------------------------------实物抽奖-----------------------------

local lottery_loader = require("config.loader.spec_lottery_loader")

local database = "lottery_winner"


Slottery_mgr = oo.class(nil, "Slottery_mgr")


function Slottery_mgr:__init()
	----公告改变时间，既下次活动开始时间
	--self.notice_time = ev.time
	----公告哪个系列，空则没公告
	--self.series 
	--发给客户端的获奖者信息
	self.series_info = {}

	----领奖改变时间
	--self.reward_time
	----领奖期数，空则不在领奖
	--self.period


	self:init_reward_info()

	self:init_notice()
end


--计算领奖时间,self.period非空有奖	继续初始化奖励表
function Slottery_mgr:init_reward_info(flags)
	--self.period非空有奖   self.reward_time非空需要倒计时
	self.period, self.reward_time = lottery_loader.get_period_rewarl_t()

	--self.period非空有奖  初始化self.reward_l
	self:init_reward_l(self.period)

	--self.period非空有奖  初始化self.winners_l
	self:init_winners_l(self.period)

	--更新获奖查询信息
	if flags and self.period then
		self:init_series_info()
	end
end


--计算中奖查询公布时间
function Slottery_mgr:init_notice()
	self.series, self.notice_time = lottery_loader.get_notice_demand()

	self:init_series_info(self.series)
end


----------------计时器
function Slottery_mgr:get_click_param()
	return self, self.on_timer,3,nil
end

function Slottery_mgr:on_timer()
	if self.reward_time and ev.time >  self.reward_time then				--公告时间到
		self:init_reward_info(1)
	end 

	if self.notice_time and ev.time >  self.notice_time then				--公告时间到
		self:init_notice()
	end
end

-------------------------------------***数据库接口***------------
function Slottery_mgr:LoadWinners(period)
	local db = f_get_db()

	local query = string.format("{period:%d}",period)

	local rows, e_code = db:select(database, nil, query)
	if 0 == e_code then
		return rows
	else
		print("LoadWinners Error: ", e_code)
	end
	return nil
end
-------------------------------------***内部接口***------------
function Slottery_mgr:init_reward_l(period)
	if period then
		self.reward_l = lottery_loader.get_period_reward_l(period)
	end
end

function Slottery_mgr:init_winners_l(period)
	if period then
		self.winners_l = {}
		local winners_info = self:init_period_demand(period)
		for kk, vv in pairs(winners_info) do
			for k, v in pairs(vv) do
				self.winners_l[tonumber(k)] = tonumber(kk)
			end
		end
	end
end


function Slottery_mgr:init_series_info()
	if self.series then
		self.series_info = {}
		local series_p = lottery_loader.get_series_period(self.series)
		for k, v in ipairs(series_p) do
			--print("118", k, j_e(v))
			if ev.time >= lottery_loader.get_period_open_t(v) then
				local period_demand = {}
				period_demand.period = v
				period_demand.winners = self:init_period_demand(v)
				table.insert(self.series_info, period_demand)
			end
		end
		--print("116 =", j_e(self.series_info))
	end
end

function Slottery_mgr:init_period_demand(period)
	local rs= self:LoadWinners(period)
	if rs == nil then 
		return {}
	else
		local winners_info = {}
		local pkt
		for k , v in pairs(rs) do
			pkt = v.winner_n
			break
		end

		return pkt
	end
end
-----------------------------------***外部接口***------------
--获奖查询信息   
function Slottery_mgr:get_series_info()
	local pkt = {}
	pkt.list = self.series_info
	pkt.period = self.period
	return pkt
end

--领奖   
function Slottery_mgr:get_reward_lvl(number)
	if not self.period then
		return 20405
	end
	return 0, self.winners_l[number]
end

--按等级获取奖励内容   
function Slottery_mgr:get_reward_info(lvl)
	local reward_list = table.copy(self.reward_l[lvl])
	return reward_list
end

--获取系列id   
function Slottery_mgr:get_series_id()
	return self.series
end

--获取期数   
function Slottery_mgr:get_period_s()
	return tostring(self.period)
end

