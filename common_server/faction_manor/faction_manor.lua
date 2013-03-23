
local _manor_config = require("config.faction_manor_config")
local formula_config = require("config.loader.formula_loader")

-- 帮派庄园类，每个帮派对应一个对象
Faction_manor = oo.class(nil, "Faction_manor")

function Faction_manor:__init(f_id)

	self.id 		= f_id	-- 对应帮派ID
	self.level		= 1   	-- 庄园等级
	self.flourish 	= 500 	-- 繁荣值
	self.power 		= 0		-- 灵气值
	self.craftsman 	= 1		-- 巧匠等级
	self.blacksmith = 1		-- 铁匠等级
	self.realm		= 1		-- 秘境等级
	self.formula	= {}	-- 巧匠的配方列表
	self.formula_class = {}	-- 配方按宝石分类
	self.new_formula = {}	-- 刷新新配方
	self.level_time	= 0		-- 升级开始时间
	self.craftsman_time = 0
	self.blacksmith_time = 0
	self.realm_time = 0
	self.formula_time = 0
	self.is_rob		= 1		-- 是否可以异兽入侵，1为可以，0为不可以
	self.change_rob_time = 0-- 上次改变is_rob的时间
end

-- type:nil所有，1：庄园升级，2：繁荣值变化，3：灵气值，4：巧匠升级，5：铁匠升级，6：秘境升级，7：配方更新，8时间相关
-- 9开关异兽入侵
function Faction_manor:get_info(type)
	local info = {}
	info.id = self.id
	if type == nil then
		info.level		= self.level	
		info.flourish 	= self.flourish 
		info.power 		= self.power 	
		info.craftsman 	= self.craftsman
		info.blacksmith = self.blacksmith
		info.realm		= self.realm
		info.formula	= self.formula
		info.level_time		= self.level_time				
		info.craftsman_time = self.craftsman_time 
		info.blacksmith_time= self.blacksmith_time
		info.realm_time 	= self.realm_time 	
		info.formula_time 	= self.formula_time 
		info.is_rob		= self.is_rob	
	elseif type == 1 then
		info.level		= self.level
		info.power 		= self.power	
		info.level_time		= self.level_time				
	elseif type == 2 then
		info.flourish	= self.flourish	
	elseif type == 3 then
		info.power		= self.power	
	elseif type == 4 then
		info.craftsman	= self.craftsman
		info.power 		= self.power
		info.formula	= self.formula
		info.craftsman_time = self.craftsman_time 
	elseif type == 5 then
		info.blacksmith	= self.blacksmith
	elseif type == 6 then
		info.realm		= self.realm
		info.power 		= self.power
		info.realm_time 	= self.realm_time 	
	elseif type == 7 then
		info.formula	= self.formula
		info.power 		= self.power
		info.formula_time 	= self.formula_time 	
	elseif type == 8 then
		info.level		= self.level	
		info.craftsman 	= self.craftsman
		info.blacksmith = self.blacksmith
		info.realm		= self.realm
		info.level_time		= self.level_time				
		info.craftsman_time = self.craftsman_time 
		info.blacksmith_time= self.blacksmith_time
		info.realm_time 	= self.realm_time 	
		info.formula_time 	= self.formula_time 
	elseif type == 9 then
		info.is_rob		= self.is_rob
	end
	return info		
end

function Faction_manor:set_info(info)
	if self.id ~= info.id then return end

	self.level		= info.level or self.level
	self.flourish 	= info.flourish or self.flourish
	self.power 		= info.power or self.power
	self.craftsman 	= info.craftsman or self.craftsman
	self.blacksmith = info.blacksmith or self.blacksmith
	self.realm		= info.realm or self.realm
	self.formula	= info.formula or self.formula
	self.level_time		= info.level_time or self.level_time		
	self.craftsman_time = info.craftsman_time or self.craftsman_time
	self.blacksmith_time= info.blacksmith_time or self.blacksmith_time
	self.realm_time 	= info.realm_time or self.realm_time
	self.formula_time 	= info.formula_time or self.formula_time
	self.is_rob			= info.is_rob or self.is_rob
	self.formula_class = {}
	for k, v in pairs(self.formula) do
		local class = formula_config.Formula_class[v]
		if not self.formula_class[class] then
			self.formula_class[class] = {}
		end
		table.insert(self.formula_class[class], v)
	end
end


--升级，消耗帮派资金，消耗帮派建设度
function Faction_manor:level_up()
	local up_to_level = self.level + 1
	local entry = _manor_config._manor_level[self.level]
	local faction = g_faction_mgr:get_faction_by_fid(self.id)
	if entry == nil or faction == nil then
		return 22241
	end
	if faction:get_level() < entry[1] then
		return 22245
	end
	if self.craftsman < entry[2] then
		return 22246		
	end
	if self.power < entry[3] then
		return 22242		
	end
	if faction:get_money() < entry[4] then
		return 22243		
	end
	if faction:get_construct_point() < entry[5] then
		return 22244	
	end
	if self.level_time > 0 then
		return 22253
	end

	--设置金钱，科技点，建设度 flag 1:金钱，2科技点 3建设度	g_faction_mgr:set_ctm_info(self.id, -entry[4], 1)
	g_faction_mgr:set_ctm_info(self.id, -entry[5], 3)
	self.power = self.power - entry[3]

	--self.level = up_to_level
	self.level_time = ev.time

	return 0
end

--增加繁荣值
function Faction_manor:add_flourish(val)
	self.flourish = math.max(0, math.min(_manor_config._manor_level[self.level][6], self.flourish + val))
end

--增加灵气值
function Faction_manor:add_power(val)
	self.power = math.max(0, math.min(_manor_config._realm_level[self.realm][4], self.power + val))
end

--升级巧匠
function Faction_manor:craftsman_up()
	local up_to_craftsman = self.craftsman + 1
	local entry = _manor_config._craftsman_level[self.craftsman]
	local faction = g_faction_mgr:get_faction_by_fid(self.id)
	if entry == nil or faction == nil then
		return 22241
	end
	if self.level < entry[1] then
		return 22247
	end
	if faction:get_money() < entry[2] then
		return 22243
	end
	if faction:get_construct_point() < entry[3] then
		return 22244
	end
	if self.power < entry[4] then
		return 22242
	end
	if self.craftsman_time > 0 then
		return 22253
	end

	--设置金钱，科技点，建设度 flag 1:金钱，2科技点 3建设度	g_faction_mgr:set_ctm_info(self.id, -entry[2], 1)
	g_faction_mgr:set_ctm_info(self.id, -entry[3], 3)
	self.power = self.power - entry[4]

	local formula_id = _manor_config.get_formula_from_list(self.formula, _manor_config._random_formula)
	self:add_formula(formula_id)
	local formula_id2 = _manor_config.get_formula_from_list(self.formula, _manor_config._random_formula)
	self:add_formula(formula_id2)

	--self.craftsman = up_to_craftsman
	self.craftsman_time = ev.time

	return 0
end

--升级铁匠
function Faction_manor:blacksmith_up()
	self.blacksmith = self.blacksmith + 1
	
	return 0
end

--升级秘境
function Faction_manor:realm_up()
	local up_to_realm = self.realm + 1
	local entry = _manor_config._realm_level[self.realm]
	local faction = g_faction_mgr:get_faction_by_fid(self.id)
	if entry == nil or faction == nil then
		return 22241
	end
	if self.level < entry[1] then
		return 22247		
	end
	if faction:get_money() < entry[2] then
		return 22243		
	end
	if faction:get_construct_point() < entry[3] then
		return 22244	
	end
	if self.realm_time > 0 then
		return 22253
	end

	--设置金钱，科技点，建设度 flag 1:金钱，2科技点 3建设度	g_faction_mgr:set_ctm_info(self.id, -entry[2], 1)
	g_faction_mgr:set_ctm_info(self.id, -entry[3], 3)
	
	--self.realm = up_to_realm
	self.realm_time = ev.time
	return 0
end

--增加配方
function Faction_manor:add_formula(formula_id)
	if formula_id == nil then return 0 end

	for k, v in ipairs(self.formula) do
		if v == formula_id then
			return 22249
		end
	end
	table.insert(self.formula, formula_id)
	local class = formula_config.Formula_class[formula_id]
	if not self.formula_class[class] then
		self.formula_class[class] = {}
	end
	table.insert(self.formula_class[class], formula_id)
	return 0
end

--研究配方
function Faction_manor:study_formula()
	if self.power < _manor_config._craftsman_level[self.craftsman][7] then
		return 22250	
	end
	if self.formula_time > 0 then
		return 22254
	end

	local formula_id = _manor_config.get_formula_from_list(self.formula, _manor_config._level_formula[self.craftsman])
	if formula_id == nil then
		return 22251
	end
	local ret = self:add_formula(formula_id)
	if ret == 0 then
		self.power = self.power - _manor_config._craftsman_level[self.craftsman][7]
		self.formula_time = ev.time
	end
	return ret, formula_id
end



--刷新配方
function Faction_manor:reflash_formula(lock_formula, t_class)
	local config = _manor_config
	if not config._new_lvl_formula[self.craftsman][t_class] then
		--print("Error:level_formula is nil")
		return 22269
	end
	local class_formula_count = config._new_lvl_class_formula_count[self.craftsman][t_class]
	if not self.formula_class[t_class] then
		return 22267
	end
	local count = #self.formula_class[t_class]
	if count <= 0 then
		return 22267
	end
	--print("formula count:", class_formula_count, count)
	if class_formula_count == count then
		return 22270
	end
	local exist_l = {}
	for _, v in pairs(self.formula_class[t_class]) do
		exist_l[v] = 1
	end
	for k, v in pairs(lock_formula or {}) do
		if not exist_l[v] then
			return 22266
		end
	end
	local lock_count = lock_formula and #lock_formula or 0
	local cost = config._reflash_formula_cost[self.craftsman]
	local add_cost = math.floor(cost[1]*lock_count/10)
	local flag = 1
	if add_cost == cost[1]*lock_count/10 then
		flag = 0
	end
	local cost_all = cost[1] + add_cost + flag
	--设置金钱，科技点，建设度 flag 1:金钱，2科技点 3建设度	local faction = g_faction_mgr:get_faction_by_fid(self.id)	if faction:get_construct_point() < cost_all then
		return 22244	
	end	g_faction_mgr:set_ctm_info(self.id, -cost_all, 3)
	local fun = config.get_random_formula_list
	local reflash_formula = fun(lock_formula, self.craftsman, t_class, count)
	if not reflash_formula then print("Error:reflash is nil") end
	self.new_formula = {["class"] = t_class, ["reflash_formula"] = reflash_formula, ["old_list"] = exist_l }
	--print("reflash_formula:", reflash_formula)
	return 0, reflash_formula, cost_all
end

--替换配方
function Faction_manor:replace_formula()
	local class = self.new_formula.class
	local new_formula = self.new_formula.reflash_formula
	local old_list = self.new_formula.old_list
	if not new_formula or not old_list or not class then 
		return 
	end
	local formula = {}
	local index = 1
	for k, v in pairs(self.formula) do
		if old_list[v] then
			formula[k] = new_formula[index] 
			index = index + 1
		else 
			formula[k] = v
		end
	end
	self.formula = formula
	self.formula_class[class] = {}
	for k, v in pairs(new_formula) do
		table.insert(self.formula_class[class], v)
	end
	return 0
end

--帮派被盗
function Faction_manor:robber()
	local faction = g_faction_mgr:get_faction_by_fid(self.id)
	if faction == nil then return end

	local flourish = math.floor(_manor_config._monster_rob[1] * self.flourish)
	self:add_flourish(-flourish)

	local money = math.floor(_manor_config._monster_rob[2] * faction:get_money())
	g_faction_mgr:set_ctm_info(self.id, -money, 1)

	local construct = math.floor(_manor_config._monster_rob[3] * faction:get_construct_point())
	g_faction_mgr:set_ctm_info(self.id, -construct, 3)

	local temp = {}
	temp[1] = 21
	temp[2] = ev.time
	temp[3] = flourish
	temp[4] = money
	temp[5] = construct
	local faction = g_faction_mgr:get_faction_by_fid(self.id)
	local _ = faction and faction:set_history_info(temp, nil)

end

function Faction_manor:sub_building_time(building)
	if building[1] == 1 then
		if self.level_time <= 0 then return 22255 end
		self.level_time = self.level_time - building[2]
		if ev.time >= self.level_time + _manor_config._manor_level[self.level][8]  then
			self.level = self.level + 1
			self.level_time = 0
			local temp = {}
			temp[1] = 24
			temp[2] = ev.time
			temp[3] = 1
			temp[4] = self.level
			local faction = g_faction_mgr:get_faction_by_fid(self.id)
			local _ = faction and faction:set_history_info(temp, nil)
		end
		return 0
	elseif building[1] == 2 then
		if self.craftsman_time <= 0 then return 22255 end
		self.craftsman_time = self.craftsman_time - building[2]
		if ev.time >= self.craftsman_time + _manor_config._craftsman_level[self.craftsman][8] then
			self.craftsman = self.craftsman + 1
			self.craftsman_time = 0
			local temp = {}
			temp[1] = 24
			temp[2] = ev.time
			temp[3] = 3
			temp[4] = self.craftsman
			local faction = g_faction_mgr:get_faction_by_fid(self.id)
			local _ = faction and faction:set_history_info(temp, nil)
		end
		return 0
	elseif building[1] == 3 then
		if self.realm_time <= 0 then return 22255 end
		self.realm_time = self.realm_time - building[2]
		if ev.time >= self.realm_time + _manor_config._realm_level[self.realm][6] then
			self.realm = self.realm + 1
			self.realm_time = 0
			local temp = {}
			temp[1] = 24
			temp[2] = ev.time
			temp[3] = 2
			temp[4] = self.realm
			local faction = g_faction_mgr:get_faction_by_fid(self.id)
			local _ = faction and faction:set_history_info(temp, nil)
		end
		return 0
	end
	return 22255
end

--检查是否有时间到了可以升级的
function Faction_manor:check_upgrade()
	local ret = -1
	if self.level_time > 0 and ev.time >= self.level_time + _manor_config._manor_level[self.level][8] then
		self.level = self.level + 1
		self.level_time = 0
		ret = 8
		local temp = {}
		temp[1] = 24
		temp[2] = ev.time
		temp[3] = 1
		temp[4] = self.level
		local faction = g_faction_mgr:get_faction_by_fid(self.id)
		local _ = faction and faction:set_history_info(temp, nil)
	end
	if self.craftsman_time > 0 and ev.time >= self.craftsman_time + _manor_config._craftsman_level[self.craftsman][8] then
		self.craftsman = self.craftsman + 1
		self.craftsman_time = 0
		ret = 8
		local temp = {}
		temp[1] = 24
		temp[2] = ev.time
		temp[3] = 3
		temp[4] = self.craftsman
		local faction = g_faction_mgr:get_faction_by_fid(self.id)
		local _ = faction and faction:set_history_info(temp, nil)
	end
	if self.blacksmith_time > 0 then
		self.blacksmith = self.blacksmith + 1
		self.blacksmith_time = 0
		ret = 8
	end
	if self.realm_time > 0 and ev.time >= self.realm_time + _manor_config._realm_level[self.realm][6] then
		self.realm = self.realm + 1
		self.realm_time = 0
		ret = 8
		local temp = {}
		temp[1] = 24
		temp[2] = ev.time
		temp[3] = 2
		temp[4] = self.realm
		local faction = g_faction_mgr:get_faction_by_fid(self.id)
		local _ = faction and faction:set_history_info(temp, nil)
	end
	if self.formula_time > 0 and ev.time >= self.formula_time + _manor_config._formula_time[self.craftsman] then
		self.formula_time = 0
		ret = 8
	end
	 	
	return ret
end

--更改是否可以异兽入侵
function Faction_manor:change_rob_state()
	if ev.time < self.change_rob_time + _manor_config._change_rob_time then
		return 22258
	end
	self.is_rob = self.is_rob == 1 and 0 or 1
	self.change_rob_time = ev.time
	
	return 0
end