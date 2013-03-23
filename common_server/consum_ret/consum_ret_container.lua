
Consum_ret_container = oo.class(nil, "Consum_ret_container")

--[[
数据库格式：
	{
		char_id:
		info: [ [累计消费, {已领取的奖励}], [累计消费, {已领取的奖励}] ]
	}
--]]

function Consum_ret_container:__init()
	self.obj_list = {}
	self.obj_list[1] = Consum_ret_obj() -- 累计元宝消费
end

function Consum_ret_container:serialize_one_to_db(char_id)
	local ret = {}
	for k, v in pairs (self.obj_list or {}) do
		table.insert(ret, v:serialize_to_db(char_id))
	end
	return ret
end

function Consum_ret_container:get_total_cost(consum_type, char_id)
	local consum_ret_obj = self.obj_list[consum_type]
	if not consum_ret_obj then
		return 0
	end
	return consum_ret_obj:get_total_cost(char_id)
end

function Consum_ret_container:add_cost(consum_type, char_id, money)
	local consum_ret_obj = self.obj_list[consum_type]
	if not consum_ret_obj then
		return 27761
	end
	return consum_ret_obj:add_cost(char_id, money)
end

function Consum_ret_container:load_char_info(char_id, pack)
	for k, v in pairs(pack) do
		if self.obj_list[k] then
			self.obj_list[k]:unserialize_to_db(char_id, v)
		end
	end
end

function Consum_ret_container:get_char_info_by_type(consum_type, char_id)
	local ret = {}
	if self.obj_list[consum_type] then
		ret = self.obj_list[consum_type]:serialize_to_db(char_id)
	end
	return ret or {0}
end

function Consum_ret_container:get_reward_by_type(consum_type, char_id, index)
	local consum_ret_obj = self.obj_list[consum_type]
	if consum_ret_obj then
		
		local e_code = consum_ret_obj:lock_char(char_id) -- 上锁
		if e_code ~= 0 then
			return 27762 -- 操作过于频繁，内部还未解锁
		end

		local e_code, config = consum_ret_obj:get_reward(char_id, index)
		if e_code ~= 0 then
			self:unlock_char(consum_type, char_id) -- 解锁
			return e_code
		end
		return 0, config
	end
	return 27761 -- 领取参数错误
end

function Consum_ret_container:reset_reward_state_by_type(consum_type, char_id, index)
	local consum_ret_obj = self.obj_list[consum_type]
	if consum_ret_obj then
		consum_ret_obj:reset_reward_state_by_type(char_id, index)
	end
end

-- 解锁
function Consum_ret_container:unlock_char(consum_type, char_id)
	local consum_ret_obj = self.obj_list[consum_type]
	if consum_ret_obj then
		consum_ret_obj:unlock_char(char_id)
	end
end
