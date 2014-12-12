
local _f_t_c = require("config.faction_territory_config")
--帮派领地

Faction_territory = oo.class(nil,"Faction_territory")

function Faction_territory:__init()
	--领地等级
	self.level = 0

	--专属id
	self.owner_id = nil
	self.owner_name = nil
	--传到温泉所需的铜币
	self.spa_gold = _f_t_c.FACTION_SPA_GOLD
	--当天spa已付费玩家
	self.spa_m_list = {}
	--传到练功房所需的铜币
	self.med_gold = _f_t_c.FACTION_MED_GOLD
	--当天练功房已付费玩家
	self.med_m_list = {}

	--被占领小时
	self.hold_hours = 0

		
	--摇钱树
	self.money_tree = Money_tree(1)
	--怪物升级
	self.monster_level_up = Monster_level_up()

	self.tomorrow = f_get_tomorrow()
end


function Faction_territory:get_owner_id()
	return self.owner_id or ""
end

function Faction_territory:get_owner_name()
	--return self.owner_name or ""
	local faction_o = g_faction_mgr:get_faction_by_fid(self.owner_id)
	return faction_o and faction_o:get_faction_name() or f_get_string(1605)
end

function Faction_territory:set_owner_id(id)
	if id == nil then id = "" end
	if id ~= self.owner_id then  
		self.hold_hours = 0
		self.monster_level_up:set_power(1, 0)
		self.monster_level_up:set_power(2, 0)
	end
	self.owner_id = id

	local faction_o = g_faction_mgr:get_faction_by_fid(self.owner_id)
	self.owner_name = faction_o and faction_o:get_faction_name() or f_get_string(1605)
	self:serialize()
end

function Faction_territory:is_owner_territory(char_id)
	if self.owner_id == nil then return false end
	local faction_o = g_faction_mgr:get_faction_by_cid(char_id)
	local faction_id = faction_o and faction_o:get_faction_id()
	if faction_id == self.owner_id then
		return true
	end
	return false
end


-- 检查是否新的一天
function Faction_territory:check_new_day()
	if ev.time > self.tomorrow then
		self.spa_m_list = {}
		self.med_m_list = {}
		self.money_tree:on_new_day()
		self.tomorrow = f_get_tomorrow()
	end
end

--传送所需铜币
--type:1为温泉，2为练功房
function Faction_territory:get_transport_need_gold(char_id, type)
	local faction_o = g_faction_mgr:get_faction_by_cid(char_id)
	local faction_id = faction_o and faction_o:get_faction_id()

	if faction_id == self.owner_id then
		return 0
	end

	if type == 1 then -- spa
		if self.spa_m_list[char_id] then 
			return 0 
		else 
			return self.spa_gold
		end
	elseif type == 2 then --练功房
		if self.med_m_list[char_id] then 
			return 0 
		else
			return self.med_gold
		end
	end

	return self.spa_gold
end

--type:1为温泉，2为练功房
function Faction_territory:add_transport_list(char_id, type)
	if type == 1 then -- spa
		self.spa_m_list[char_id] = true
	elseif type == 2 then --练功房
		self.med_m_list[char_id] = true
	end
end

--为领地所属帮派添加帮派资金
function Faction_territory:add_faction_money(money)
	local faction_o = self.owner_id 
	if faction_o then

	end
end

--铁匠强化加成（1为百分之一）
function Faction_territory:get_intensify_add_per()
	return _f_t_c.TERRITORY_INTENSIFY_ADD_PER or 0
end

--非所属帮派铁匠强化加成增加金币百分比(1为百分之一百)
function Faction_territory:get_intensify_money_per()
	return _f_t_c.TERRITORY_INTENSIFY_MONEY_PER or 0
end

--非所属帮派学习技能(1为百分之一百)
function Faction_territory:get_study_skill_money_per()
	return _f_t_c.TERRITORY_STUDY_SKILL_MONEY_PER or 0
end

--取得对应的怪物级别
--type:1为攻，2为防
function Faction_territory:get_monster_level(type, occ)
	return self.monster_level_up:get_monster_level(type, occ)
end

function Faction_territory:add_territory_power(type, power)
	 local old_level = self.monster_level_up:get_level(type)
	 local old_power = self.monster_level_up:get_power(type)
	 self.monster_level_up:add_power(type, power)

	 local level = self.monster_level_up:get_level(type)
	 local power = self.monster_level_up:get_power(type)

	 if type == 1 then
		if math.floor(old_power / 100) ~= math.floor(power / 100) then
			local msg = {}
			local bd_str = f_get_string(1606)
			f_construct_content(msg, string.format(bd_str, power, (_f_t_c._level_power[level] or 9999999) - power), 13)
			f_cmd_sysbd(msg)
		end
		if old_level ~= level then
			local msg = {}
			local bd_str = f_get_string(1608)
			f_construct_content(msg, string.format(bd_str, level, self.monster_level_up:get_level(2)), 13)
			f_cmd_sysbd(msg)
		end
	 elseif type == 2 then
		if math.floor(old_power / 100) ~= math.floor(power / 100) then
			local msg = {}
			local bd_str = f_get_string(1607)
			f_construct_content(msg, string.format(bd_str, power, (_f_t_c._level_power[level] or 9999999) - power), 13)
			f_cmd_sysbd(msg)
		end
		if old_level ~= level then
			local msg = {}
			local bd_str = f_get_string(1609)
			f_construct_content(msg, string.format(bd_str, self.monster_level_up:get_level(1), level), 13)
			f_cmd_sysbd(msg)
		end
	 end
end

--定时器，每小时被调用
function Faction_territory:each_hour(tm)
	if self.owner_id == "" then return end
	self.hold_hours = self.hold_hours + 0
	local day = math.min(math.floor((self.hold_hours + 24) / 24), #_f_t_c._system_add_power_each_day)
	local add_power = math.floor(_f_t_c._system_add_power_each_day[day] / 24)
	self:add_territory_power(1, add_power)
	--self:add_territory_power(2, add_power)
	--print("type1:, type2:, add_power",self.monster_level_up:get_power(1), self.monster_level_up:get_power(2), add_power)
end

function Faction_territory:get_click_param()
	return self, self.each_hour, _f_t_c._second_of_hour, nil
end
-------------------------------------网络相关-------------------------------------------------------
--客户端同步信息
function Faction_territory:serialize_to_net()
	local ret = {}
	ret.owner_id = self.owner_id or ""
	return ret
end

function Faction_territory:get_money_tree_tool(char_id)
	local new_pkt = {}
	--new_pkt.item_id = MONEY_TREE_TOOL_ID;
	local obj = g_obj_mgr:get_obj(char_id)
	local pack_con = obj:get_pack_con()
	new_pkt.item_size = pack_con:get_all_item_count(_f_t_c.MONEY_TREE_TOOL_ID) or 0
	--new_pkt.remain_time = self.money_tree:get_remain_time(char_id)
	new_pkt.time = self.money_tree:get_time(char_id)
	new_pkt.time_t = _f_t_c.MONEY_TREE_MAX_TIME
	new_pkt.watering_time = self.money_tree:get_watering_time()
	new_pkt.watering_time_t = _f_t_c.MONEY_TREE_FULL
	local skill_con = obj:get_skill_con()
	local cd_o = skill_con:get_skill_cd(SKILL_OBJ_121)
	new_pkt.cd_time = math.floor(cd_o and cd_o:get_last_time() or 0)
	return new_pkt
end


----------持久化函数----------
--db保存信息
function Faction_territory:serialize_to_db()
	local ret = {}
	ret.territory_id = 1
	ret.owner_id = self.owner_id or ""
	ret.money_tree = self.money_tree:serialize_to_db()
	ret.monster_level_up = self.monster_level_up:serialize_to_db()
	ret.hold_hours = self.hold_hours
	return ret
end

function Faction_territory:unserialize_from_db(rows)
	self.owner_id = rows.owner_id or ""
	self.money_tree:unserialize_from_db(rows.money_tree)
	self.monster_level_up:unserialize_from_db(rows.monster_level_up)
	self.hold_hours = rows.hold_hours or 0
end

function Faction_territory:serialize()
	local m_db = f_get_db()
	local query = string.format("{territory_id:%d}", 1)
	local info = self:serialize_to_db()
	--print("Faction_territory:serialize():", Json.Encode(info))
	m_db:update("territory", query, Json.Encode(info), true)
end

function Faction_territory:unserialize()
	local m_db = f_get_db()
	local query = string.format("{territory_id:%d}", 1)
	local rows, e_code = m_db:select_one("territory", nil, query, nil, "{territory_id:1}")
	if rows ~= nil then
		--print("Faction_territory:unserialize():", Json.Encode(rows))
		self:unserialize_from_db(rows)
	end
end
