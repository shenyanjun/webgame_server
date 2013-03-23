--$Id: week_reward.lua 61929 2013-03-20 07:06:44Z tangpf $
--2010-01-20
--laojc
--星期六日登录奖励


local reward_t = require("config.reward_config")

Week_reward = oo.class(Reward,"Week_reward")

function Week_reward:__init(obj_id)
	Reward.__init(self,obj_id)
	self.char_id = obj_id
	self.type = 2
end


--------------------------------------基本操作--------------------------------------------

function Week_reward:get_random_item()
	if self:is_weekly() then
		local item_list = reward_t.f_week_random_item()
		if item_list == nil then
			return {}
		else
			return item_list[1] or {}
		end
	else
		return {}
	end
end



function Week_reward:is_weekly()
	local day = os.date("%w",ev.time)
	if tonumber(day) == 0 or tonumber(day) == 6 then
		return true
	end
	return false
end


function Week_reward:can_be_fetch()
	if not self:is_weekly() then return 27603 end          --是否是周末周日
	if self:is_fetch() then return 27601 end

	return 0

end
--
--function Week_reward:login()
	--if self:is_weekly() then
		--
	--end
--end





