Exp_reward = oo.class(nil, "Exp_reward")

function Exp_reward:__init(config)
	self.next_time = nil
	self.addition_list = {}
	self:reset_config(config)
end

function Exp_reward:reset_config(config)
	if not config then
		config = {}
	end
	
	self.exp_factor = config.exp_factor or 10
	self.exp_base = config.exp_base or 1000
	self.addition_limit = config.addition_limit or 40
	self.interval = config.interval or 10
	self.base_factor = config.base_factor or 0.025
	self.level_factor = config.level_factor or 30
	self.team_factor = config.team_factor or 0.02
	self.buff_type = config.buff_type
	self.vip_type = config.vip_type
	self.level_limit = config.level_limit or 30
	self.faction_append = {}	-- 帮派附加加成
end

function Exp_reward:get_addition_limit()
	return self.addition_limit
end

function Exp_reward:get_addition(obj_id)
	return self.addition_list[obj_id] or 0
end

function Exp_reward:get_soap_and_faction_addition(obj_id)
	-- 帮派加成
	local faction = g_faction_mgr:get_faction_by_cid(obj_id)
	local faction_id = faction and faction:get_faction_id()
	local d = faction_id and (self.faction_append[faction_id] or 0) or 0
	local a = self.base_factor * math.min(self.addition_list[obj_id] or 0, self.addition_limit)
	return math.ceil((a + d) * 100)
end

function Exp_reward:get_addition_limit_remain(obj_id)
	return self.addition_limit - (self.addition_list[obj_id] or 0)
end

function Exp_reward:add_addition(obj_id, count)
	self.addition_list[obj_id] = (self.addition_list[obj_id] or 0) + count
end

function Exp_reward:del_addition(obj_id)
	self.addition_list[obj_id] = nil
end

function Exp_reward:clear_addition()
	self.addition_list = {}
end

function Exp_reward:start()
	self.next_time = ev.time + self.interval
end

function Exp_reward:stop()
	self.next_time = nil
end

function Exp_reward:calc_addition(obj)
	local a = self.base_factor * math.min(self.addition_list[obj:get_id()] or 0, self.addition_limit)
				* (obj:get_level() / self.level_factor)^2 * 0.8
	local team = g_team_mgr:get_team_obj(obj:get_team())
	local b = team and ((team:get_line_count() - 1) * self.team_factor) or 0
	local c = self.vip_type and obj:get_addition(self.vip_type) or 0
	-- 帮派加成
	local faction = g_faction_mgr:get_faction_by_cid(obj:get_id())
	local faction_id = faction and faction:get_faction_id()
	local d = faction_id and (self.faction_append[faction_id] or 0) or 0
	return a + b + c + d
end

function Exp_reward:try_reward(now, obj_list)
	if self.next_time and self.next_time <= now and obj_list then
		self.next_time = now + self.interval
		local obj_mgr = g_obj_mgr
		local buff_addition = self.buff_type and g_buffer_reward_mgr:buff_reward(self.buff_type) or 0
		for obj_id, _ in pairs(obj_list) do
			local obj = obj_mgr:get_obj(obj_id)
			local level = obj and obj:get_level()
			if level and level >= self.level_limit then
				local exp_base = self.exp_base + self.exp_factor * (level - self.level_limit) * (level / 10)
				local addition = (1 + self:calc_addition(obj) + buff_addition) * (obj:is_alive() and 1 or 0.5)
				obj:add_exp(math.floor(exp_base * addition))
			end
		end
	end
end

function Exp_reward:set_faction_append(faction_id, per)
	self.faction_append[faction_id] = per
end

function Exp_reward:get_faction_append(faction_id)
	return self.faction_append[faction_id] or 0
end

function Exp_reward:celan_faction_append()
	self.faction_append = {}
end