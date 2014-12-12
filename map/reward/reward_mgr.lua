local debug_print = function() end

Reward_mgr = oo.class(nil,"Reward_mgr")

function Reward_mgr:__init()
	self.reward_obj_l = {}
end

function Reward_mgr:create_reward_obj(char_id)
	--exist destroy it
	if self.reward_obj_l[char_id] then
		self.reward_obj_l[char_id] = nil
	end
	
	local reward_obj = Obj_reward(char_id)
	if not reward_obj then return end

	if not reward_obj:load() then
		reward_obj = nil
		return false
	end

	self.reward_obj_l[char_id] = {}
	self.reward_obj_l[char_id]["reward_obj"] = reward_obj

	return true
end

function Reward_mgr:destroy_reward_obj(char_id)
	if self.reward_obj_l[char_id] then
		self.reward_obj_l[char_id] = nil
	end
end

function Reward_mgr:get_reward_remain_time(char_id)
	if self.reward_obj_l[char_id] ~= nil then
		local reward_obj = self.reward_obj_l[char_id]["reward_obj"]
		if not reward_obj then return end

		return reward_obj:get_remain_time()
	end
end

function Reward_mgr:get_reward_item(char_id)
	if self.reward_obj_l[char_id] ~= nil then
		local reward_obj = self.reward_obj_l[char_id]["reward_obj"]
		if not reward_obj then return end

		return reward_obj:get_reward_item()
	end
end

--领取奖励
function Reward_mgr:featch_reward(char_id)
	if self.reward_obj_l[char_id] ~= nil then
		local reward_obj = self.reward_obj_l[char_id]["reward_obj"]
		if not reward_obj then return end

		return reward_obj:featch_reward_present()
	end
end

--玩家下线保存
function Reward_mgr:update_reward_remain_time(char_id)
	if self.reward_obj_l[char_id] ~= nil then
		local reward_obj = self.reward_obj_l[char_id]["reward_obj"]
		if not reward_obj then return end

		return reward_obj:update_remain_time()
	end
end

--服务器关闭时保存
function Reward_mgr:serialize()
	print("---------Reward_mgr:serialize")
	for k,reward in pairs(self.reward_obj_l) do
		reward.reward_obj:update_remain_time()
	end
end

-----------event----------
--function Reward_mgr:get_click_param()
	--return self, self.on_timer, 1, nil
--end
--
--function Reward_mgr:on_timer(tm)
	--for k,v in pairs(self.reward_obj_l) do
		--if v.reward_obj:get_state() == 1 then
			--v.reward_obj:on_timer(1)
		--end
	--end
--end
--