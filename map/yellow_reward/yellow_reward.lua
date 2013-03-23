local database = "yellow_reward"
local ONE_DAY = 86400


Yellow_reward = oo.class(nil,"Yellow_reward")


function Yellow_reward:__init(obj_id)
	self.char_id = obj_id
	self.new_sign = 0
	self.every_sign = 0
	self.lvup_sign  = {}
	self.login_time = self:get_day_time()
end

function Yellow_reward:online()
	if self:is_other_day() then
		self.login_time = self:get_day_time()
		self.every_sign = 0
		self:update_char()
	end		
end

function Yellow_reward:set_gift_sign(type)
	if type == 1 then
		self.new_sign = 1
	elseif type == 2 then
		self.every_sign = 1
	end	
	self:update_char()
end

function Yellow_reward:is_can_reward(type)
	if type == 1 then
		return self.new_sign
	elseif type == 2 then
		return self.every_sign
	end
end

function Yellow_reward:info_to_net()
	local info = {}
	info.new = self.new_sign
	info.every = self.every_sign
	return info
end

function Yellow_reward:update_char(type)
	local player = g_obj_mgr:get_obj(self.char_id)
	if not player then return end
	if player:get_qlevel() == 0 then
		return
	end
	local dbh = f_get_db()
	local data = {} 	
	data.char_id = self.char_id
	data.yellow_reward = {}
	data.yellow_reward.login_time = self.login_time
	data.yellow_reward.new_sign = self.new_sign
	data.yellow_reward.every_sign = self.every_sign

	local query = string.format("{char_id:%d}",self.char_id)

	local err_code = dbh:update(database,query,Json.Encode(data),true)
	if err_code ~= 0 then
		print("Yellow_reward:update_char :",err_code,database,j_e(data))
	end
end

function Yellow_reward:is_other_day(num)     --ÉÏÏßÊ±ÅÐ¶Ï
	if num == nil then num = 1 end
	if ev.time >= self.login_time + num * ONE_DAY then
		return true
	end
	return false
end

function Yellow_reward:get_day_time()
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