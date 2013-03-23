
local _manor_config = require("config.faction_manor_config")local formula_loader = require("config.loader.formula_loader")
-- 帮派庄园管理类

Faction_manor_mgr = oo.class(nil, "Faction_manor_mgr")

function Faction_manor_mgr:__init()
	self.faction_manor_l = {}			-- 帮派庄园的对象列表
	self.add_power_time = ev.time
end

-- type:nil所有，1：庄园升级，2：繁荣值变化，3：灵气值，4：巧匠升级，5：铁匠升级，6：秘境升级
function Faction_manor_mgr:get_syn_info(f_id, type)
	local info = {}
	if f_id == nil then
		for k, v in pairs(self.faction_manor_l) do
			table.insert(info, v:get_info(type))
		end
	elseif self.faction_manor_l[f_id] then
		info[1] = self.faction_manor_l[f_id]:get_info(type)
	end
	return info		
end

function Faction_manor_mgr:syn(f_id, type)
	local info = self:get_syn_info(f_id, type)
	g_server_mgr:send_to_all_map(0, CMD_C2M_FACTION_MANOR_SYN_S, info)

	--self:debug_print()
end

function Faction_manor_mgr:set_syn_info(info)
	for k, v in ipairs(info) do
		if self.faction_manor_l[v.id] == nil then
			self.faction_manor_l[v.id] = Faction_manor(v.id)
		end
		self.faction_manor_l[v.id]:set_info(v)
	end
end

--增加某帮派的庄园
function Faction_manor_mgr:add_manor(f_id)
	if self.faction_manor_l[f_id] == nil then
		local manor = Faction_manor(f_id)
		self.faction_manor_l[f_id] = manor
		manor:add_formula(1100)
		local formula_id = _manor_config.get_formula_from_list(manor.formula, _manor_config._random_formula)
		manor:add_formula(formula_id)
		local formula_id2 = _manor_config.get_formula_from_list(manor.formula, _manor_config._random_formula)
		manor:add_formula(formula_id2)
	end
	self:syn(f_id, nil)
end

--是否有庄园
function Faction_manor_mgr:had_manor(f_id)
	return self.faction_manor_l[f_id] ~= nil
end

function Faction_manor_mgr:had_manor_by_cid(char_id)
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	return faction and self.faction_manor_l[faction:get_faction_id()] ~= nil
end

--庄园升级
function Faction_manor_mgr:level_up(f_id)
	local manor = self.faction_manor_l[f_id]
	if manor == nil then return 22240 end
	
	local re = manor:level_up()
	if re == 0 then
		self:syn(f_id, 1)
	end
	return re
end

function Faction_manor_mgr:level_up_by_cid(char_id)
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	if faction == nil then
		return 22240
	end
	local f_id = faction:get_faction_id()
	local r = self:level_up(f_id)
	if r == 0 then
		--历史消息
		local manor = self.faction_manor_l[f_id]
		local entry = _manor_config._manor_level[manor.level]
		
		local ret = {}
		ret[1] = 23
		ret[2] = ev.time
		ret[3] = char_id
		ret[4] = faction.faction_player_list[char_id]["name"]
		ret[5] = 1
		ret[6] = entry[3]
		ret[7] = entry[5]
		ret[8] = entry[4]
		local _ = faction and faction:set_history_info(ret,nil)
	end
	return r
end

function Faction_manor_mgr:get_level(f_id)
	local manor = self.faction_manor_l[f_id]
	return manor and manor.level
end

--增加繁荣值
function Faction_manor_mgr:add_flourish(f_id, val)
	local manor = self.faction_manor_l[f_id]
	if manor == nil then return 22240 end
	
	local old_flourish = manor.flourish
	manor:add_flourish(val)
	if old_flourish ~= manor.flourish then
		self:syn(f_id, 2)
	end
end

function Faction_manor_mgr:get_flourish(f_id)
	local manor = self.faction_manor_l[f_id]
	return manor and manor.flourish
end

function Faction_manor_mgr:get_flourish_by_cid(char_id)
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	return faction and self:get_flourish(faction:get_faction_id())
end

--增加灵气值
function Faction_manor_mgr:add_power(f_id, val)
	local manor = self.faction_manor_l[f_id]
	if manor == nil then return 22240 end
	
	local old_power = manor.power
	manor:add_power(val)
	if old_power ~= manor.power then
		self:syn(f_id, 3)
	end
end

function Faction_manor_mgr:get_power(f_id)
	local manor = self.faction_manor_l[f_id]
	return manor and manor.power
end

function Faction_manor_mgr:get_power_by_cid(char_id)
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	return faction and self:get_power(faction:get_faction_id())
end

--升级巧匠
function Faction_manor_mgr:craftsman_up(f_id)
	local manor = self.faction_manor_l[f_id]
	if manor == nil then return 22240 end
	
	local re = manor:craftsman_up()
	if re == 0 then
		self:syn(f_id, 4)
	end
	return re
end

function Faction_manor_mgr:craftsman_up_by_cid(char_id)
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	if faction == nil then
		return 22240
	end

	local f_id = faction:get_faction_id()
	local r = self:craftsman_up(f_id)
	if r == 0 then
		--历史消息
		local manor = self.faction_manor_l[f_id]
		local entry = _manor_config._craftsman_level[manor.craftsman]
		
		local ret = {}
		ret[1] = 23
		ret[2] = ev.time
		ret[3] = char_id
		ret[4] = faction.faction_player_list[char_id]["name"]
		ret[5] = 3
		ret[6] = entry[4]
		ret[7] = entry[3]
		ret[8] = entry[2]
		local _ = faction and faction:set_history_info(ret,nil)
	end
	return r
end

function Faction_manor_mgr:get_craftsman_level(f_id)
	local manor = self.faction_manor_l[f_id]
	return manor and manor.craftsman
end

function Faction_manor_mgr:get_craftsman_level_by_cid(char_id)
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	return faction and self:get_craftsman_level(faction:get_faction_id())
end

--升级铁匠
function Faction_manor_mgr:blacksmith_up(f_id)
	local manor = self.faction_manor_l[f_id]
	if manor == nil then return 22240 end
	
	local re = manor:blacksmith_up()
	if re == 0 then
		self:syn(f_id, 5)
	end
	return re
end

function Faction_manor_mgr:blacksmith_up_by_cid(char_id)
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	if faction == nil then
		return 22240
	end
	return self:blacksmith_up(faction:get_faction_id())
end

function Faction_manor_mgr:get_blacksmith_level(f_id)
	local manor = self.faction_manor_l[f_id]
	return manor and manor.blacksmith
end

function Faction_manor_mgr:get_blacksmith_level_by_cid(char_id)
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	return faction and self:get_blacksmith_level(faction:get_faction_id())
end

--升级秘境
function Faction_manor_mgr:realm_up(f_id)
	local manor = self.faction_manor_l[f_id]
	if manor == nil then return 22240 end
	
	local re = manor:realm_up()
	if re == 0 then
		self:syn(f_id, 6)
	end
	return re
end

function Faction_manor_mgr:realm_up_by_cid(char_id)
	--print("Faction_manor_mgr:realm_up_by_cid()", char_id)
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	if faction == nil then
		return 22240
	end
	
	local f_id = faction:get_faction_id()
	local r = self:realm_up(f_id)
	if r == 0 then
		--历史消息
		local manor = self.faction_manor_l[f_id]
		local entry = _manor_config._realm_level[manor.realm]
		
		local ret = {}
		ret[1] = 23
		ret[2] = ev.time
		ret[3] = char_id
		ret[4] = faction.faction_player_list[char_id]["name"]
		ret[5] = 2
		ret[6] = 0
		ret[7] = entry[3]
		ret[8] = entry[2]
		local _ = faction and faction:set_history_info(ret,nil)

	end
	return r
end

function Faction_manor_mgr:get_realm_level(f_id)
	local manor = self.faction_manor_l[f_id]
	return manor and manor.realm
end

function Faction_manor_mgr:get_realm_level_by_cid(char_id)
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	return faction and self:get_realm_level(faction:get_faction_id())
end

--研究配方
function Faction_manor_mgr:study_formula(f_id)
	local manor = self.faction_manor_l[f_id]
	if manor == nil then return 22240 end
	
	local re, formula_id = manor:study_formula()
	if re == 0 then
		self:syn(f_id, 7)
	end
	return re, formula_id
end

function Faction_manor_mgr:study_formula_by_cid(char_id)
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	if faction == nil then
		return 22240
	end

	local f_id = faction:get_faction_id()
	local r, formula_id = self:study_formula(f_id)
	if r == 0 then
		--历史消息
		local manor = self.faction_manor_l[f_id]
		local entry = _manor_config._craftsman_level[manor.craftsman]
		
		local ret = {}
		ret[1] = 25
		ret[2] = ev.time
		ret[3] = char_id
		ret[4] = faction.faction_player_list[char_id]["name"]
		ret[5] = entry[7]
		ret[6] = formula_loader.GetFormula_name(tostring(formula_id)) or " "
		local _ = faction and faction:set_history_info(ret,nil)
	end
	return r, formula_id
end

--刷新配方
function Faction_manor_mgr:reflash_formula(f_id, lock_l, t_class)
	local manor = self.faction_manor_l[f_id]
	if manor == nil then return 22240 end
	
	local re, formula_list, cost = manor:reflash_formula(lock_l, t_class)
	return re, formula_list, cost
end

function Faction_manor_mgr:reflash_formula_by_cid(char_id, lock_l, t_class)
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	if faction == nil then
		return 22240
	end

	local f_id = faction:get_faction_id()
	local r, formula_list, cost = self:reflash_formula(f_id, lock_l, t_class)
	if r == 0 then
		--历史消息
		local manor = self.faction_manor_l[f_id]
		local entry = _manor_config._craftsman_level[manor.craftsman]
		
		local ret = {}
		ret[1] = 31
		ret[2] = ev.time
		ret[3] = char_id
		ret[4] = faction.faction_player_list[char_id]["name"]
		ret[5] = cost
		local _ = faction and faction:set_history_info(ret,nil)
	end
	return r, formula_list
end

--替换配方
function Faction_manor_mgr:replace_formula(f_id)
	local manor = self.faction_manor_l[f_id]
	if manor == nil then return 22240 end
	
	local re = manor:replace_formula()
	if re == 0 then
		self:syn(f_id, 7)
		self:serialize(f_id)
	end
	return re
end

function Faction_manor_mgr:replace_formula_by_cid(char_id)
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	if faction == nil then
		return 22240
	end

	local f_id = faction:get_faction_id()
	local r = self:replace_formula(f_id)
	if r == 0 then
		--历史消息
		local manor = self.faction_manor_l[f_id]
		local entry = _manor_config._craftsman_level[manor.craftsman]
		
		local ret = {}
		ret[1] = 32
		ret[2] = ev.time
		ret[3] = char_id
		ret[4] = faction.faction_player_list[char_id]["name"]
		local _ = faction and faction:set_history_info(ret,nil)
	end
	return r
end


--增加配方
function Faction_manor_mgr:add_formula(f_id, formula_id)
	local manor = self.faction_manor_l[f_id]
	if manor == nil then return 22240 end
	
	local re = manor:add_formula(formula_id)
	if re == 0 then
		self:syn(f_id, 7)
	end
	return re
end

function Faction_manor_mgr:add_formula_by_cid(char_id, formula_id)
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	if faction == nil then
		return 22240
	end
	return self:add_formula(faction:get_faction_id(), formula_id)
end

function Faction_manor_mgr:get_formula_list(f_id)
	local manor = self.faction_manor_l[f_id]
	return manor and manor.formula
end

function Faction_manor_mgr:get_formula_list_by_cid(char_id)
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	return faction and self:get_formula_list(faction:get_faction_id())
end

function Faction_manor_mgr:sub_building_time(f_id, building)
	local manor = self.faction_manor_l[f_id]
	if manor == nil then return 22240 end
	
	local re = manor:sub_building_time(building)
	if re == 0 then
		self:syn(f_id, 8)
	end
	return re
end

--杀庄园强盗失败
function Faction_manor_mgr:robber(f_id)
	local manor = self.faction_manor_l[f_id]
	if manor == nil then return 22240 end
	
	manor:robber()
	self:syn(f_id, 2)
end

--重启同步
function Faction_manor_mgr:syn_all_to_map(server_id)
	local pkt = self:get_syn_info(nil, nil)
	g_server_mgr:send_to_server(server_id, 0, CMD_C2M_FACTION_MANOR_SYN_S, pkt)
end

function Faction_manor_mgr:get_click_param()
	return self, self.on_timer, 2, nil
end

function Faction_manor_mgr:on_timer()
	--print("Faction_manor_mgr:on_timer()")
	if ev.time >= self.add_power_time + _manor_config.ON_TIME_SECOND then
		for f_id, manor in pairs(self.faction_manor_l) do
			local power_add = math.floor(_manor_config.ADD_POWER_RATIO * manor.flourish * _manor_config._realm_level[manor.realm][5])
			if manor.is_rob == 1 then
				power_add = math.floor(power_add * _manor_config._rob_factor)
			end
			local power_del = math.floor(_manor_config.ADD_POWER_RATIO * manor.flourish * (_manor_config._manor_level[manor.level][7] + _manor_config._craftsman_level[manor.craftsman][6]))
			manor:add_power(power_add - power_del)
			--历史消息
			local ret = {}
			ret[1] = 22
			ret[2] = ev.time
			ret[3] = power_add
			ret[4] = power_del
			local faction = g_faction_mgr:get_faction_by_fid(f_id)
			local _ = faction and faction:set_history_info(ret,nil)
		end
		self:syn(nil, 3)
		self.add_power_time = ev.time
		self:serialize(f_id)
	end
	self:check_upgrade()
end

--检查是否有时间到了可以升级的
function Faction_manor_mgr:check_upgrade()
	for f_id, manor in pairs(self.faction_manor_l) do
		local ret = manor:check_upgrade(power)
		if ret >= 0 then
			self:syn(f_id, ret)
			self:serialize(f_id)
		end
	end
end

--更改是否可以异兽入侵
function Faction_manor_mgr:change_rob_state_by_cid(char_id)
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	local manor = faction and self.faction_manor_l[faction:get_faction_id()]
	if manor == nil then return 22240 end
	
	local re = manor:change_rob_state()
	if re == 0 then
		self:syn(f_id, 9)
	end
	
	return re, manor.is_rob
end

function Faction_manor_mgr:debug_print()
	print("=====================================================")
	for k, v in pairs(self.faction_manor_l) do
		print(Json.Encode(v:get_info(nil)))
		print("-----------------------------------------------------")
	end
end

------------- 保存
function Faction_manor_mgr:serialize(f_id)
	--print("Faction_manor_mgr:serialize()",f_id)	
	local info = self.faction_manor_l[f_id] and self.faction_manor_l[f_id]:get_info(nil)
	if info ~= nil then
		local m_db = f_get_db()
		local query = string.format("{id:'%s'}", f_id)
		m_db:update("faction_manor", query, Json.Encode(info), true)
	end
end

function Faction_manor_mgr:serialize_all()
	--print("Faction_manor_mgr:serialize_all()")
	for k, v in pairs(self.faction_manor_l) do
		self:serialize(k)
	end
end

function Faction_manor_mgr:unserialize()
	local m_db = f_get_db()
	local rows, e_code = m_db:select("faction_manor")
	if rows ~= nil and e_code == 0 then
		for k, v in pairs(rows) do
			local faction = g_faction_mgr:get_faction_by_fid(v.id)
			if faction ~= nil then
				self.faction_manor_l[v.id] = Faction_manor(v.id)
				self.faction_manor_l[v.id]:set_info(v)
			end
		end
	end
end