


--随机打开物品列表

local _random = crypto.random
local script_load = require("npc.config.random_script_loader")

Random_script = oo.class(nil, "Random_script")

function Random_script:__init()
	self.action_random_list = {}        --随机物品列表
	self.action_item_list = {}   		--购买物品计数
end

--清空
function Random_script:set_zero_char()
	self.action_random_list = {}
	self.action_item_list = {}
end

--产生随机物品列表
function Random_script:get_random_item_list(action_id)
	if self.action_item_list[action_id] == nil then
		self.action_item_list[action_id] = {}
	end

	if script_load.Random_config[action_id].random_item_list.item_list ~= nil then
		self.action_random_list[action_id] = {}
		local value_t = script_load.Random_config[action_id].random_item_list.value_t
		local limit = script_load.Random_config[action_id].random_item_list.limit
		local rdm_item_list = script_load.Random_config[action_id].random_item_list.item_list
		
		local cur_value = 0
		for i=1,limit do
			value_t = value_t - cur_value
			local rdm = _random(1, value_t+1)

			local dd = 0
			local del_list = {}
			for item_id,item_obj in pairs(rdm_item_list or {}) do
				if del_list[item_id] == nil then
					dd = item_obj.value + dd
					if dd >= rdm then
						self.action_random_list[action_id][item_id] = 1
						del_list[item_id] = 1
						cur_value = item_obj.value
						break
					end
				end
			end
		end
	end
end

--玩家购买物品后,在item_list表扣除物品数量
function Random_script:dec_item_list(action_id, item_id, number)	
	self.action_item_list[action_id][item_id] = (self.action_item_list[action_id][item_id] or 0) + number
end

--一次刷新所需要的花费与货币类型
function Random_script:get_cost_refresh_item_list(action_id)
	local temp = {}
	temp.price = script_load.Random_config[action_id].money
	temp.type = script_load.Random_config[action_id].money_type
	return temp
end

--一个物品所需要的花费与货币类型
function Random_script:get_cost_one_item(action_id,item_id)
	local temp = {}
	if script_load.Random_config[action_id].random_item_list.item_list ~= nil and 
		script_load.Random_config[action_id].random_item_list.item_list[item_id] ~= nil then

		temp.price = script_load.Random_config[action_id].random_item_list.item_list[item_id].price
		temp.type = script_load.Random_config[action_id].random_item_list.item_list[item_id].type
	elseif script_load.Random_config[action_id].certain_item_list.item_list[item_id] ~= nil then
		temp.price = script_load.Random_config[action_id].certain_item_list.item_list[item_id].price
		temp.type = script_load.Random_config[action_id].certain_item_list.item_list[item_id].type
	end

	return temp
end


--判断能否购买如此number物品
function Random_script:is_item_number(action_id, item_id, number) 
	local item_c = self.action_item_list[action_id][item_id] or 0
	local total = 0
	if script_load.Random_config[action_id].random_item_list.item_list ~= nil and 
		script_load.Random_config[action_id].random_item_list.item_list[item_id] ~= nil then

		total = script_load.Random_config[action_id].random_item_list.item_list[item_id].number
	elseif script_load.Random_config[action_id].certain_item_list.item_list[item_id] ~= nil then
		total = script_load.Random_config[action_id].certain_item_list.item_list[item_id].number
	end

	if item_c + number <= total then
		return 0
	else
		return 24008
	end
end


------client操作-------
--刷新物品列表 (refresh:非nil显式刷新)
function Random_script:refresh_item_list(action_id, refresh)
	if refresh ~= nil then
		self:get_random_item_list(action_id)
	elseif self.action_random_list[action_id] == nil then
		self:get_random_item_list(action_id)
	end

	return self:net_get_info(action_id)
end

--整理action_id表 to client
function Random_script:net_get_info(action_id)
	local result = {}
	--随机
	for item_id,_ in pairs(self.action_random_list[action_id] or {}) do
		local o
		if script_load.Random_config[action_id].random_item_list.item_list ~= nil then
			o = script_load.Random_config[action_id].random_item_list.item_list[item_id]
		end

		if o ~= nil then
			local item_c = o.number - (self.action_item_list[action_id][item_id] or 0)
			if item_c > 0 then
				local list = {}
				list.item_id = item_id
				list.number = item_c
				list.type = o.type
				list.price = o.price

				table.insert(result, list)
			end
		end
	end

	--正常
	for item_id,o in pairs(script_load.Random_config[action_id].certain_item_list.item_list or {}) do
		local item_c = o.number - (self.action_item_list[action_id][item_id] or 0)
		if item_c > 0 then
			local list = {}
			list.item_id = item_id
			list.number = item_c
			list.type = o.type
			list.price = o.price

			table.insert(result, list)
		end
	end
	return result
end
