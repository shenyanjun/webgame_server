
local faction_update_loader = require("item.faction_update_loader")
local _manor_config = require("config.faction_manor_config")

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
	self.formula_table={}	-- 巧匠的配方列表table方式
	self.level_time	= 0		-- 升级开始时间
	self.craftsman_time = 0
	self.blacksmith_time = 0
	self.realm_time = 0
	self.formula_time = 0
	self.is_rob		= 1		-- 是否可以异兽入侵，1为可以，0为不可以
	self.reflash_flag = nil	--刷新配方标识
end

-- type:nil所有，1：庄园升级，2：繁荣值变化，3：灵气值，4：巧匠升级，5：铁匠升级，6：秘境升级，7：配方更新
function Faction_manor:get_info(type)
	local info = {}
	info.id = self.id
	if type == nil then
		info.level		= self.level	
		info.flourish 	= {self.flourish, _manor_config._manor_level[self.level][6]} 
		info.power 		= {self.power, _manor_config._realm_level[self.realm][4]}
		info.craftsman 	= self.craftsman
		info.blacksmith = self.blacksmith
		info.realm		= self.realm
		info.formula	= self.formula
		info.level_time		= math.max(0, self.level_time + _manor_config._manor_level[self.level][8] - ev.time)				
		info.craftsman_time = math.max(0, self.craftsman_time + _manor_config._craftsman_level[self.craftsman][8] - ev.time)
		info.blacksmith_time= 0
		info.realm_time 	= math.max(0, self.realm_time + _manor_config._realm_level[self.realm][6] - ev.time)
		--info.formula_time 	= self.formula_time
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
		info.formula_time 	= self.formula_time 	
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
	if info.formula ~= nil then
		self.formula_table = {}
		for k, v in ipairs(info.formula) do
			self.formula_table[v] = 1
		end
	end
end

--能否满足升级条件
function Faction_manor:can_level_up(char_id)
	local r = self:auth(char_id)
	if r ~= 0 then
		return r
	end
	if self.level_time > 0 and ev.time < self.level_time + _manor_config._manor_level[self.level][8] then
		return 22253
	end
	local up_to_level = self.level + 1
	local entry = _manor_config._manor_level[self.level]
	local faction = g_faction_mgr:get_faction_by_fid(self.id)
	if entry == nil or faction == nil or _manor_config._manor_level[up_to_level] == nil then
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

	return 0
end

--能否升级巧匠
function Faction_manor:can_craftsman_up(char_id)
	local r = self:auth(char_id)
	if r ~= 0 then
		return r
	end
	if self.craftsman_time > 0 and ev.time < self.craftsman_time + _manor_config._craftsman_level[self.craftsman][8] then
		return 22253
	end
	local up_to_craftsman = self.craftsman + 1
	local entry = _manor_config._craftsman_level[self.craftsman]
	local faction = g_faction_mgr:get_faction_by_fid(self.id)
	if entry == nil or faction == nil or _manor_config._craftsman_level[up_to_craftsman] == nil then
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
	
	return 0
end

--能否升级铁匠
function Faction_manor:can_blacksmith_up(char_id)
	local r = self:auth(char_id)
	if r ~= 0 then
		return r
	end

	return 0
end

--能否升级秘境
function Faction_manor:can_realm_up(char_id)
	local r = self:auth(char_id)
	if r ~= 0 then
		return r
	end
	if self.realm_time > 0 and ev.time < self.realm_time + _manor_config._realm_level[self.realm][6] then
		return 22253
	end
	local up_to_realm = self.realm + 1
	local entry = _manor_config._realm_level[self.realm]
	local faction = g_faction_mgr:get_faction_by_fid(self.id)
	if entry == nil or faction == nil or _manor_config._realm_level[up_to_realm] == nil then
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
	
	return 0
end

--能否研究配方
function Faction_manor:can_study_formula(char_id)
	local r = self:auth(char_id)
	if r ~= 0 then
		return r
	end
	if self.formula_time > 0 and ev.time < self.formula_time + _manor_config._formula_time[self.craftsman] then
		return 22254
	end
	if self.power < _manor_config._craftsman_level[self.craftsman][7] then
		return 22250	
	end
	return 0
end

function Faction_manor:check_formula(formula_id)
	return self.formula_table[formula_id]
end

function Faction_manor:set_reflash_flag(flag)
	self.reflash_flag = flag
end

function Faction_manor:get_reflash_flag(flag)
	return self.reflash_flag
end


--判断能否刷强盗
function Faction_manor:can_rob()
	if self.is_rob == 0 then
		return false
	end
	local faction = g_faction_mgr:get_faction_by_fid(self.id)
	if faction == nil then return false end
	--繁荣度
	if self.flourish < math.ceil(_manor_config._refresh_monster_req[1] * _manor_config._manor_level[self.level][6]) then
		return false
	end
	--帮派资金
	if faction:get_money() < math.ceil(_manor_config._refresh_monster_req[2] * faction_update_loader.gold_list[faction.gold_level][5]) then
		return false
	end
	--建设度
	if faction:get_construct_point() < math.ceil(_manor_config._refresh_monster_req[3] * faction_update_loader.action_list[faction.action_level][5]) then
		return false
	end
	--当前在线人数
	local online_member_count = faction:get_online_member_count()
	if online_member_count <= _manor_config._refresh_monster_online[1]
		or online_member_count < math.ceil(_manor_config._refresh_monster_req[4] * faction_update_loader.faction_list[faction.level][8]) then
		return false
	end
	
	return online_member_count <= _manor_config._refresh_monster_online[2] and 1 or online_member_count <= _manor_config._refresh_monster_online[3] and 2 or 3
	--return true
end

function Faction_manor:auth(char_id)
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	if faction:get_factioner_id() ~= char_id then
		return 22252
	end

	return 0
end

--取维护相关信息
function Faction_manor:get_maintenance()
	local factor = _manor_config.ADD_POWER_RATIO * self.flourish
	local manor_cost = math.floor(factor * _manor_config._manor_level[self.level][7]) * 24
	local craftsman_cost = math.floor(factor * _manor_config._craftsman_level[self.craftsman][6]) * 24
	local realm_supply = math.floor(factor * _manor_config._realm_level[self.realm][5]) * 24
	if self.is_rob == 1 then
		realm_supply = math.floor(realm_supply * _manor_config._rob_factor)
	end
	return {manor_cost, craftsman_cost, realm_supply}
end