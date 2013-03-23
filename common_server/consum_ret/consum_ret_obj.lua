
local consum_ret_loader = require("config.loader.consum_ret_loader")

Consum_ret_obj = oo.class(nil, "Consum_ret_obj")

function Consum_ret_obj:__init()
	self.cost_list = {} -- char_id：{累计消费， {已领取的奖励}}

	self.player_list = {} -- 锁操作
end

function Consum_ret_obj:lock_char(char_id)
	if not self.player_list[char_id] then
		self.player_list[char_id] = true
		return 0
	end 
end

function Consum_ret_obj:unlock_char(char_id)
	self.player_list[char_id] = nil
end

function Consum_ret_obj:get_total_cost(char_id)
	if self.cost_list[char_id] then
		return self.cost_list[char_id][1]
	end
	return 0
end

function Consum_ret_obj:add_cost(char_id, money)
	if not self.cost_list[char_id] then
		self.cost_list[char_id] = {}
		self.cost_list[char_id][1] = 0
		self.cost_list[char_id][2] = {}
	end
	self.cost_list[char_id][1] = self.cost_list[char_id][1] + (money or 0)
	return 0
end

function Consum_ret_obj:serialize_to_db(char_id)
	if self.cost_list[char_id] then
		local ret = {}
		ret[1] = self.cost_list[char_id][1]
		ret[2] = {}
		for k, v in pairs(self.cost_list[char_id][2] or {}) do
			if v == true then
				table.insert(ret[2], k)
			end
		end
		return ret
	end
end

function Consum_ret_obj:unserialize_to_db(char_id, pack)
	self.cost_list[char_id] = {}
	self.cost_list[char_id][1] = pack[1]
	self.cost_list[char_id][2] = {}
	for k, v in pairs(pack[2] or {}) do
		self.cost_list[char_id][2][v] = true -- 表示已经领取过
	end
end

function Consum_ret_obj:get_reward(char_id, index)
	if self.cost_list[char_id] then
		if not self.cost_list[char_id][2][index] then
			local config = consum_ret_loader.get_jade_reward_config(index)
			if config and config.item_id and config.item_cnt and config.money then -- 检查配置
				if config.money <= self.cost_list[char_id][1] then
					self.cost_list[char_id][2][index] = true -- 设置为已经领取奖励
					return 0, config
				else
					return 27766 -- 累计消费金额未达到领取条件
				end
			else
				return 27765 -- 累计消费配置错误
			end
		else
			return 27764 -- 已经领取过奖励
		end
	end
	return 27763 -- 无法获取奖励
end

function Consum_ret_obj:reset_reward_state_by_type(char_id, index)
	if self.cost_list[char_id] then
		self.cost_list[char_id][2][index] = nil
	end
end
