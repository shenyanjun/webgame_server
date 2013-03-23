
require("config.skill_cmd")
local _sk_magic_config = require("config.skill_magic_config")

local _random = crypto.random


-- 
local skill_magic_builder = function (skill_cmd, magic_skill_type)
	local skill_name_format = "Skill_%d"
	local skill_clr = string.format(skill_name_format, skill_cmd)
	local skill_param = _sk_magic_config._skill_p[skill_cmd]
	for level, params in pairs(skill_param or {} )do
		local skill_name = string.format(skill_name_format, skill_cmd + level)
		_G[skill_name] = _G[skill_clr](skill_cmd + level, magic_skill_type)
		--print("==>skill_name", skill_name)
	end
end

------------------- 法宝技能 -----------------------

Skill_magic = oo.class(Skill, "Skill_magic")

function Skill_magic:__init(id, ty)
	Skill.__init(self, id, ty)
	self.cmd_id = math.floor(id / 100) * 100
	self.level = id % 100
	local base_config = _sk_magic_config._skill_base[id]
	if base_config == nil then
		base_config = _sk_magic_config._skill_base[self.cmd_id] or {10, 0, 0}
	end
	self.distance = base_config[1]
	self.cd_time = base_config[2]
	self.expend_mp = base_config[3]
end


function Skill_magic:effect(sour_id, param)
	--print("Skill_magic:effect")
	param.param = _sk_magic_config._skill_p[self.cmd_id][self.level]
	local obj = g_obj_mgr:get_obj(sour_id)
	if obj:get_mp() < self.expend_mp then
		return
	end
	local ret = self:on_effect(param)
	if ret == 0 and self.expend_mp > 0 then
		obj:add_mp(-self.expend_mp)
	end
	return ret
end

function Skill_magic:on_effect(param)
	return 0
end

-- 当加入更高级的技能时，用于清理之前的附加值
function Skill_magic:ineffectiveness(sour_id, param)
	
end



------------------- 法宝技能 加属性技能 -----------------------

Skill_magic_attribute = oo.class(Skill_magic, "Skill_magic_attribute")

function Skill_magic_attribute:__init(id, ty)
	Skill_magic.__init(self, id, ty)
	
end

function Skill_magic_attribute:effect(sour_id, param)
	--print("===>Skill_magic_attribute:effect,sour_id", sour_id)	
	local s_obj = g_obj_mgr:get_obj(sour_id)
	if s_obj ~= nil then
		local t = self:get_effect_val()
		for _, val in pairs(t) do
			s_obj:add_passive_effect(val[1], nil, val[2])
		end
	end
end

-- 当加入更高级的技能时，用于清理之前的附加值
function Skill_magic_attribute:ineffectiveness(sour_id, param)
	local s_obj = g_obj_mgr:get_obj(sour_id)

	if s_obj ~= nil then
		local t = self:get_effect_val()
		for _, val in pairs(t) do
			local extra = {}
			extra[1] = -val[2][1]
			extra[2] = -val[2][2]
			s_obj:add_passive_effect(val[1], nil, extra)
		end
	end
end

function Skill_magic_attribute:get_effect_val()
	local t = {}
	local skill_cmd = self.cmd_id
	local level = self.level
	if skill_cmd == SKILL_OBJ_880100 then
		t[1] = {EXTRA_STEMINA, _sk_magic_config._skill_p[skill_cmd][level]}

	elseif skill_cmd == SKILL_OBJ_880200 then
		t[1] = {EXTRA_PHYSICAL_AK, _sk_magic_config._skill_p[skill_cmd][level]}
		t[2] = {EXTRA_MAGIC_AK, _sk_magic_config._skill_p[skill_cmd][level]}

	elseif skill_cmd == SKILL_OBJ_880300 then
		t[1] = {EXTRA_ICE_DE, _sk_magic_config._skill_p[skill_cmd][level]}

	elseif skill_cmd == SKILL_OBJ_880400 then
		t[1] = {EXTRA_POISON_DE, _sk_magic_config._skill_p[skill_cmd][level]}
					  
	elseif skill_cmd == SKILL_OBJ_880500 then
		t[1] = {EXTRA_FIRE_DE, _sk_magic_config._skill_p[skill_cmd][level]}
					
	elseif skill_cmd == SKILL_OBJ_880600 then
		t[1] = {EXTRA_STRENGH, _sk_magic_config._skill_p[skill_cmd][level]}
					  
	elseif skill_cmd == SKILL_OBJ_880700 then
		t[1] = {EXTRA_INTELLIGENCE, _sk_magic_config._skill_p[skill_cmd][level]}
					  
	elseif skill_cmd == SKILL_OBJ_880800 then
		t[1] = {EXTRA_INTELLIGENCE, _sk_magic_config._skill_p[skill_cmd][level]}
					  
	elseif skill_cmd == SKILL_OBJ_880900 then
		t[1] = {EXTRA_POINT, _sk_magic_config._skill_p[skill_cmd][level]}
					  
	elseif skill_cmd == SKILL_OBJ_881000 then
		t[1] = {EXTRA_PHYSICAL_DE, _sk_magic_config._skill_p[skill_cmd][level]}
		t[2] = {EXTRA_MAGIC_DE, _sk_magic_config._skill_p[skill_cmd][level]}
					 
	elseif skill_cmd == SKILL_OBJ_881100 then
		t[1] = {EXTRA_CRITICAL_EF, _sk_magic_config._skill_p[skill_cmd][level]}
		
	elseif skill_cmd == SKILL_OBJ_881200 then
		t[1] = {EXTRA_STRENGH, _sk_magic_config._skill_p[skill_cmd][level]}
		t[2] = {EXTRA_INTELLIGENCE, _sk_magic_config._skill_p[skill_cmd][level]}
		t[3] = {EXTRA_STEMINA, _sk_magic_config._skill_p[skill_cmd][level]}
		t[4] = {EXTRA_DEXTERITY, _sk_magic_config._skill_p[skill_cmd][level]}
					
	elseif skill_cmd == SKILL_OBJ_881300 then
		t[1] = {EXTRA_ICE_AK, _sk_magic_config._skill_p[skill_cmd][level]}
					
	elseif skill_cmd == SKILL_OBJ_881400 then
		t[1] = {EXTRA_FIRE_AK, _sk_magic_config._skill_p[skill_cmd][level]}
					
	elseif skill_cmd == SKILL_OBJ_881500 then
		t[1] = {EXTRA_POISON_AK, _sk_magic_config._skill_p[skill_cmd][level]}

	elseif skill_cmd == SKILL_OBJ_881600 then
		t[1] = {EXTRA_PHYSICAL_AK, {-0.2, 0}}
		t[2] = {EXTRA_MAGIC_AK, {-0.2, 0}}
		t[3] = {EXTRA_STEMINA, _sk_magic_config._skill_p[skill_cmd][level]}
	
	elseif skill_cmd == SKILL_OBJ_881700 then
		t[1] = {EXTRA_DOCTOR_MAGIC, _sk_magic_config._skill_p[skill_cmd][level]}		
				
	elseif skill_cmd == SKILL_OBJ_880000 then
		t[1] = {EXTRA_STRENGH, _sk_magic_config._skill_p[skill_cmd][level]}

	elseif skill_cmd == SKILL_OBJ_879900 then
		t[1] = {EXTRA_INTELLIGENCE, _sk_magic_config._skill_p[skill_cmd][level]}

	elseif skill_cmd == SKILL_OBJ_879800 then
		t[1] = {EXTRA_INTELLIGENCE, _sk_magic_config._skill_p[skill_cmd][level]}

	elseif skill_cmd == SKILL_OBJ_879700 then
		t[1] = {EXTRA_STOP_DE, _sk_magic_config._skill_p[skill_cmd][level]}

	elseif skill_cmd == SKILL_OBJ_879600 then
		t[1] = {EXTRA_SILENCE_DE, _sk_magic_config._skill_p[skill_cmd][level]}

	end

	return t
end

-- 
local skill_magic_attribute_builder = function ()
	local skill_name_format = "Skill_%d"
	for skill_cmd = 879000, SKILL_MAGIC_BEGIN + 2900, 100 do
		local skill_param = _sk_magic_config._skill_p[skill_cmd]
		for level, params in pairs(skill_param or {} ) do
			local skill_name = string.format(skill_name_format, skill_cmd + level)
			_G[skill_name] = Skill_magic_attribute(skill_cmd + level, SKILL_MAGIC_ATTRIBUTE)
			--print("==>skill_name", skill_name)
		end
	end
end

skill_magic_attribute_builder()


-------------------  触发附加伤害技能 -----------------------

Skill_magic_damage_add = oo.class(Skill_magic, "Skill_magic_damage_add")

function Skill_magic_damage_add:__init(id, ty)
	Skill_magic.__init(self, id, ty)
	
end

function Skill_magic_damage_add:effect(sour_id, param)
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

function Skill_magic_damage_add:on_effect(param)
	return {0, 0}
end

-- 
f_skill_magic_damage_add_builder = function (skill_cmd)
	skill_magic_builder(skill_cmd, SKILL_MAGIC_DAMAGE_ADD)
end


-------------------  触发减免伤害技能 -----------------------

Skill_magic_damage_sub = oo.class(Skill_magic, "Skill_magic_damage_sub")

function Skill_magic_damage_sub:__init(id, ty)
	Skill_magic.__init(self, id, ty)
	
end

function Skill_magic_damage_sub:effect(sour_id, param)
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

function Skill_magic_damage_sub:on_effect(param)
	return {0, 0}
end

-- 
f_skill_magic_damage_sub_builder = function (skill_cmd)
	skill_magic_builder(skill_cmd, SKILL_MAGIC_DAMAGE_SUB)
end

-------------------  攻击触发类技能 -----------------------
-- 
f_skill_magic_attack_builder = function (skill_cmd)
	skill_magic_builder(skill_cmd, SKILL_MAGIC_ATTACK)
end

-------------------  被攻击触发类技能 -----------------------
-- 
f_skill_magic_be_attack_builder = function (skill_cmd)
	skill_magic_builder(skill_cmd, SKILL_MAGIC_BE_ATTACK)
end

-------------------  主动使用类技能 -----------------------
-- 
f_skill_magic_use_builder = function (skill_cmd)
	skill_magic_builder(skill_cmd, SKILL_MAGIC_USE)
end

-------------------  组队加buff类技能 -----------------------
-- 
f_skill_magic_team_builder = function (skill_cmd)
	skill_magic_builder(skill_cmd, SKILL_MAGIC_TEAM)
end