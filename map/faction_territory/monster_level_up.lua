local _f_t_c = require("config.faction_territory_config")

Monster_level_up = oo.class(nil, "Monster_level_up")

function Monster_level_up:__init()
	self.power = {0, 0}	--攻方， 防方
end

function Monster_level_up:add_power(type, power)
	self.power[type] = self.power[type] + power
end

function Monster_level_up:set_power(type, power)
	self.power[type] = power
end

function Monster_level_up:get_power(type)
	return self.power[type]
end

function Monster_level_up:get_monster_level(type, occ)
	if not (_f_t_c._monster_can_level_up[type] and _f_t_c._monster_can_level_up[type][occ]) then return end

	return _f_t_c._power_to_level(self.power[type])
end

function Monster_level_up:get_level(type)
	return _f_t_c._power_to_level(self.power[type])
end

-- 数据库保存
function Monster_level_up:serialize_to_db()
	local ret = {}
	ret.power = self.power
	return ret
end

function Monster_level_up:unserialize_from_db(entry)
	self.power = entry and entry.power or {0, 0}
end