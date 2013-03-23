
require("config.skill_cmd")
local _sk_magic_config = require("config.xml.human_fight.magic_skill_config")

local _random = crypto.random

-- 
local skill_magic_builder = function (skill_cmd, magic_skill_tye)
	local skill_name_format = "Skill_%d"
	local skill_clr = string.format(skill_name_format, skill_cmd)
	local skill_param = _sk_magic_config._skill_p[skill_cmd]
	for level, params in pairs(skill_param or {} )do
		local skill_name = string.format(skill_name_format, skill_cmd + level)
		_G[skill_name] = _G[skill_clr](skill_cmd + level, magic_skill_tye)
		--print("==>skill_name", skill_name)
	end
end

-------------------  触发附加伤害技能 -----------------------
Magic_skill_damage_add = oo.class(Human_skill_obj,"Magic_skill_damage_add")

function Magic_skill_damage_add:__init(skill_id, type)
	Human_skill_obj.__init(self, skill_id, type)

end

function Magic_skill_damage_add:effect(sour_id, param)
	--print("===>Skill_magic_damage_add:effect,sour_id", sour_id)	
	if param.obj_s == nil or param.obj_d == nil then
		return
	end
	local r = _random(1, 100)
	local entry = _sk_magic_config._skill_p[self.cmd_id][self.level]
	if r < entry[1] then
		param.factor = entry[2]
		param.trouble = entry[3]
		return self:on_effect(param)
	end
	return nil
end

function Magic_skill_damage_add:on_effect(param)
	return {0, 0}
end

f_skill_magic_damage_add_builder = function (skill_cmd)
	skill_magic_builder(skill_cmd, SKILL_MAGIC_DAMAGE_ADD)
end

-------------------  触发减免伤害技能 -----------------------

Magic_skill_damage_sub = oo.class(Human_skill_obj, "Magic_skill_damage_sub")

function Magic_skill_damage_sub:__init(skill_id, type)
	Human_skill_obj.__init(self, skill_id, type)
	
end

function Magic_skill_damage_sub:effect(sour_id, param)
	--print("===>Skill_magic_damage_sub:effect,sour_id", sour_id)	
	if param.obj_s == nil or param.obj_d == nil then
		return
	end
	local r = _random(1, 100)
	local entry = _sk_magic_config._skill_p[self.cmd_id][self.level]
	if r < entry[1] then
		param.factor = entry[2]
		param.trouble = entry[3]
		return self:on_effect(param)
	end
	return nil
end

function Magic_skill_damage_sub:on_effect(param)
	return {0, 0}
end

f_skill_magic_damage_sub_builder = function (skill_cmd)
	skill_magic_builder(skill_cmd, SKILL_MAGIC_DAMAGE_SUB)
end





