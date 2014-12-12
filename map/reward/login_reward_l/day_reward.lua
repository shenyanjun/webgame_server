--2010-01-20
--laojc
--每日登录奖励

local reward_t = require("config.reward_config")

Day_reward = oo.class(Reward,"Day_reward")

function Day_reward:__init(obj_id)
	Reward.__init(self,obj_id)
	self.char_id = obj_id
	self.type = 1
	self.flag = 1
end


function Day_reward:get_random_item()
	local item_list = reward_t.f_day_random_item()
	if item_list == nil then
		return {}
	else
		return item_list[1] or {}
	end
end

function Day_reward:login()
	self.flag = 1
end










