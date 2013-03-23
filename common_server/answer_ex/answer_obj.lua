
Answer_obj = oo.class(nil, "Answer_obj")

function Answer_obj:__init(char_id, name)
	self.char_id = char_id
	self.name = name
	self.char_count = 0
	self.answer_status = 0
	self.right_answer_count = 0
	self.answer_count = 0
	self.max_answer_count = 0
	self.score = 0
	self.reward_flag = false
	self.max_dec_count = 0
	self.max_dou_count = 0
	self.double_count = 0
	self.decrease_count = 0
	self.double_use_flag = 0
	self.decrease_use_flag = 0

end

function Answer_obj:set_max_answer_count(count)
	self.max_answer_count = count
end

function Answer_obj:clear_obj_status()
	self.answer_status = 0
	self.decrease_use_flag = 0
	self.double_use_flag = 0
end

function Answer_obj:get_score()
	return self.score
end

function Answer_obj:get_id()
	return self.char_id
end


----计算得分-------
function Answer_obj:calculate_score(time)
	local temp_score = 0
	temp_score = math.min(math.floor((1 - math.pow(time*0.02, 0.1))*296) + 5,100)
	self.score = self.score + math.floor(temp_score * (1 + self.double_use_flag))
	return temp_score
end

----面板信息----
function Answer_obj:get_all_info()
	local ret = {}
	ret[1] = self.decrease_count
	ret[2] = self.double_count
	ret[3] = self.right_answer_count
	ret[4] = 0
	ret[5] = self.score
	return ret
end

----答题状态----------------
function Answer_obj:set_answer_status(flag)
	self.answer_status = 1
end

function Answer_obj:get_answer_status()
	return self.answer_status
end

----vip加成-----------------
function Answer_obj:set_vip_addition(pkt)
	self.decrease_count = pkt.exc or 0
	self.double_count = pkt.dou or 0
	self.max_dec_count = pkt.exc or 0
	self.max_dou_count = pkt.dou or 0
end

function Answer_obj:get_max_dec_count()
	return self.max_dec_count
end

function Answer_obj:get_max_dou_count()
	return self.max_dou_count
end

-----加倍--------------
function Answer_obj:get_double_count()
	return self.double_count
end

function Answer_obj:dec_double_count(flag)
	self.double_count = self.double_count - flag
end

function Answer_obj:set_double_flag(flag)
	self.double_use_flag = flag
end

function Answer_obj:get_double_flag()
	return self.double_use_flag
end

----排错---------------
function Answer_obj:get_decrease_count()
	return self.decrease_count
end

function Answer_obj:dec_decrease_count(flag)
	self.decrease_count = self.decrease_count - flag
end

function Answer_obj:set_decrease_flag(flag)
	self.decrease_use_flag = flag
end

function Answer_obj:get_decrease_flag()
	return self.decrease_use_flag
end

----答题数--------------
function Answer_obj:add_answer_count(flag)
	self.answer_count = self.answer_count + flag
end

function Answer_obj:get_answer_count()
	return self.answer_count
end

function Answer_obj:add_right_count()
	self.right_answer_count = self.right_answer_count + 1
end

function Answer_obj:get_right_count()
	return self.right_answer_count
end

function Answer_obj:is_answer()
	if self.answer_count > 0 then
		return 1
	end
	return 0
end

function Answer_obj:is_finish()
	if self.answer_count >= self.max_answer_count then
		return 1
	end
	return 0
end


----奖励状态----------------
function Answer_obj:get_reward_flag()
	return self.reward_flag
end

function Answer_obj:set_reward_flag(flag)
	self.reward_flag = flag
end
