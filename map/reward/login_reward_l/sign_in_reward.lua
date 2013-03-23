--$Id$

--每日签到功能
local sign_in_config = require("reward.login_reward_l.loader.sign_in_loader")

Sign_in_reward = oo.class(nil,"Sign_in_reward")

function Sign_in_reward:__init(char_id)
	self.char_id = char_id
	self.type = 6			--奖励类型
	self:clear()
	
end

function Sign_in_reward:clear()
	self.login_day = 0				--最后登陆时间
	self.sign_day  = 0				--签到天数
	self.sign_list = {}
	self.reward = {0,0,0,0,0,0,0}			--领取奖励状态表
	self.vip_reward = {0,0,0,0,0,0,0}		--vip领取奖励状态

end

-- 签到逻辑
function Sign_in_reward:sign_in()
	local date = os.date("%Y%m%d", ev.time)
	date = tonumber(date)
	print ("签到时间: "..date)

	if date > self.login_day then
		self.login_day = date
		self.sign_day = self.sign_day + 1
		local day = self.login_day % 100
		table.insert(self.sign_list, day)
		self:save()
	end
end

function Sign_in_reward:check_next_month()
	local date = os.date("%Y%m%d", ev.time)
	date = tonumber(date)
	if date - self.login_day > 50 then
		self:clear()
		self:save()
	end
end

function Sign_in_reward:send_net_info()
	
	local data = {}
	--data.login_day = self.login_day
	data.sign_day = self.sign_day
	data.sign_list = self.sign_list
	data.reward = self.reward
	data.vip_reward = self.vip_reward
	--print("CMD_MAP_SIGN_IN_INFO_S", j_e(data))
	print("===>协议号："..CMD_MAP_SIGN_IN_INFO_S.."  数据"..j_e(data))
	print (sign_in_config)
	sign_in_config.print_info_test()
	print ("===== end =====")
	g_cltsock_mgr:send_client(self.char_id, CMD_MAP_SIGN_IN_INFO_S, data)
end

function Sign_in_reward:get_reward(type, day)
	
	local player = g_obj_mgr:get_obj(self.char_id)
	local condition = sign_in_config.get_condition(day)
	if player == nil or self.sign_day < condition then
		return 31371
	end
	local reward_s = nil
	if type == 1 then
		reward_s = self.reward
	elseif type == 2 then
		reward_s = self.vip_reward
	else
		return 31371
	end
	if reward_s[day] ~= 0 then
		return 31372
	end
	--
	local reward_list = sign_in_config.get_reward_day_info(type, day)
	local new_item_list = {}
	local count = 1
	for k,v in pairs(reward_list or {}) do
		new_item_list[count] = {}
		new_item_list[count]["item_id"]     = v.item_id
		new_item_list[count]["type"]   		= 1
		new_item_list[count]["number"] 		= v.number
		count = count + 1
	end
	local pack_con = player:get_pack_con()	
	if pack_con then
		local result = pack_con:add_item_l(new_item_list, {['type']=ITEM_SOURCE.SIGN_IN_REWARD})
		if result ~= 0 then
			return result
		end
	end
	reward_s[day] = 1
	self:save()
	self:send_net_info()
end

function Sign_in_reward:set_info(data)
	local date = os.date("%Y%m%d", ev.time)
	date = tonumber(date)
	if date - data.login_day > 50 then
		return
	end
	self.login_day = data.login_day
	self.sign_day = data.sign_day
	self.sign_list = data.sign_list
	self.reward = data.reward
	local length = #self.reward
	--print( j_e(self.reward ) )
	if length < 7 then
		for i = length+1, 7 do
			table.insert( self.reward, 0 )
			--print( i, j_e(self.reward ) )
		end
	end
	self.vip_reward = data.vip_reward
	local vip_length = #self.vip_reward
	--print( j_e( self.vip_reward ) )
	if vip_length < 7 then
		for i = vip_length+1, 7 do
			table.insert( self.vip_reward, 0 )
			--print( i, j_e(self.vip_reward ) )
		end
	end
end

function Sign_in_reward:save()
	local data = {}
	data.login_day = self.login_day
	data.sign_day = self.sign_day
	data.sign_list = self.sign_list
	data.reward = self.reward
	data.vip_reward = self.vip_reward

	local dbh = f_get_db()
	local query = string.format("{char_id:%d,type:%d}", self.char_id, self.type)
	local err_code = dbh:update("reward", query, Json.Encode(data), true)
end



