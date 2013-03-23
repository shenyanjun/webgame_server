--2010-01-20
--laojc
--节日登录奖励

local reward_t = require("config.reward_config")

Festival_reward = oo.class(Reward,"Festival_reward")

function Festival_reward:__init(obj_id)
	Reward.__init(self,obj_id)
	self.char_id = obj_id
	self.type = 3
end

------------------------------------基本操作------------------------------------------------

function Festival_reward:get_random_item()
	local vip = g_vip_mgr:get_vip_info(self.char_id)
	local type = 4
	if vip == 0 or vip == 5 then
		type = 4
	elseif vip == 1 then
		type = 3
	elseif vip == 2 then
		type = 2
	elseif vip == 3 then
		type = 1
	end

	local item_list = reward_t.f_festival_random_item(type)
	return item_list
end

function Festival_reward:is_festival()
	local item_list = self:get_random_item()
	if item_list == nil then
		return false
	end

	self.item_list = item_list
	return true
end


function Festival_reward:can_be_fetch(char_id)
	if not self:is_festival() then return 27604 end         --是否是在节日
	if self:is_fetch()  then return 27601 end

	return 0
end



