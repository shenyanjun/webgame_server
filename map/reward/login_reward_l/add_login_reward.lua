
local add_login_loader = require("reward.login_reward_l.loader.add_login_loader")

local add_login_reward = "reward"
local ONE_DAY = 86400
local TWO_DAY = 172800
local BASE_REWARD = 1
local YELLOW_REWARD = 2

Add_login_reward = oo.class(nil,"Add_login_reward")

function Add_login_reward:__init(char_id)
	self.char_id = char_id
	self:clear()
end

function Add_login_reward:clear()
	self.login_time = 0				--登陆时间
	self.login_day  = 0				--登陆天数
	--self.sustain_day = 0 			--连续登陆
	self.type 		= 98			--连续登陆奖励类型
	self.reward_state = {}			--领取奖励状态表
	self.reward_yellow_state = {}	--黄钻领取奖励状态
	for i = 1 ,add_login_loader.get_max_day() do
		self.reward_state[i] = 0
		self.reward_yellow_state[i] = 0
	end
end

function Add_login_reward:login(first_login)
	if first_login then
		--self.sustain_day =  1
		self.login_day 	 =  1
		self.login_time = self:get_day_time()	
		self:set_gift_state(1)
	else
		local interval = self:is_other_day()
		if interval  == 0 then 
			return 
		else  
			self.login_day =  self:get_sum_day(self.login_time) + 1
			if self.login_day > self:get_reward_maxday() then return end
			self:set_gift_state(self.login_day)							
		end
	end
	self:save_db_info(1)
end

function Add_login_reward:set_gift_state(sustain_day)
	for i = sustain_day, 1, -1 do
		if self.reward_state[i] == 0 then
			self.reward_state[i] = 1
		end	
		if self.reward_yellow_state[i] == 0 then
			self.reward_yellow_state[i] = 1
		end	
	end
end

function Add_login_reward:is_can_get_gift(day, type)
	if type == BASE_REWARD then
		if self.reward_state[day] == 1 then	return 0 end
	elseif type == YELLOW_REWARD then
		if self.reward_yellow_state[day] == 1 then return 0 end
	end
	return 27003
end

function Add_login_reward:set_gain_gift(day, type)
	if not type then return end
	if type == BASE_REWARD then
		self.reward_state[day] = 2
	elseif type == YELLOW_REWARD then
		self.reward_yellow_state[day] = 2
	end
	self:save_db_info()
end

function Add_login_reward:get_gift(day, type)
	if type == BASE_REWARD then
		return add_login_loader.get_reward_day_info(day)
	elseif type == YELLOW_REWARD then
		return add_login_loader.get_reward_day_info(day,type)
	end
end

function Add_login_reward:send_net_info()
	local ret = {}
	ret.login_day = self.login_day 			--登陆天数		
	--ret.sustain_day = self.sustain_day 		--连续登陆
	ret.day_state = self.reward_state
	ret.day_yellow_state = self.reward_yellow_state
	return ret
end

function Add_login_reward:save_db_info(type)
	if self.login_day > self:get_reward_maxday() then return end
	local result = {} 
	if type then
		result.login_time = self.login_time
		result.login_day  = self.login_day
		--result.sustain_day = self.sustain_day
		result.type		  = self.type
	end
	result.reward_state = self.reward_state
	result.reward_yellow_state = self.reward_yellow_state
	local dbh = f_get_db()
	local query = string.format("{char_id:%d,type:%d}",self.char_id,self.type)
	local err_code = dbh:update(add_login_reward,query,Json.Encode(result),true)
end

--得到离线多少天
function Add_login_reward:get_sum_day(tm)
	return ((self:get_day_time() - tm)/ONE_DAY)
end

function Add_login_reward:get_day_time()
	local l_time = ev.time
	local time_today ={}
	time_today.year = os.date("%Y",l_time)
	time_today.month = os.date("%m",l_time)
	time_today.day = os.date("%d",l_time)
	time_today.hour = 0
	time_today.minute = 0
	time_today.second = 0
	local t_time = os.time(time_today)
	return t_time
end

--上线时判断
function Add_login_reward:is_other_day()
	if ev.time >= self.login_time + TWO_DAY then
		return 2
	end
	if ev.time >= self.login_time + ONE_DAY then
		return 1
	end
	return 0
end

function Add_login_reward:get_login_day()
	return self.login_day
end

function Add_login_reward:get_reward_maxday()
	return add_login_loader.get_max_day()
end