require("skill.magic_skill.magic_base_skill")
local _sk_appendage_config = require("config.skill_appendage_config")
local _random = crypto.random



-- 
local skill_appendage_builder = function (skill_cmd, appendage_skill_type)
	local skill_name_format = "Skill_%d"
	local skill_clr = string.format(skill_name_format, skill_cmd)
	local skill_param = _sk_appendage_config._skill_p[skill_cmd]
	for level, params in pairs(skill_param or {} )do
		local skill_name = string.format(skill_name_format, skill_cmd + level)
		_G[skill_name] = _G[skill_clr](skill_cmd + level, appendage_skill_type)
		--print("==>skill_name", skill_name)
	end
end

------------------- 宠物附体技能 -----------------------

Skill_appendage = oo.class(Skill, "Skill_appendage")

function Skill_appendage:__init(id, ty)
	Skill.__init(self, id, ty)
	self.cmd_id = math.floor(id / 100) * 100
	self.level = id % 100
	local base_config = _sk_appendage_config._skill_base[id]
	if base_config == nil then
		base_config = _sk_appendage_config._skill_base[self.cmd_id] or {10, 0, 0}
	end
	self.distance = base_config[1]
	self.cd_time = base_config[2]
	self.expend_mp = base_config[3]
end


function Skill_appendage:effect(sour_id, param)
	--print("Skill_appendage:effect")
	param.param = _sk_appendage_config._skill_p[self.cmd_id][self.level]
	local obj = g_obj_mgr:get_obj(sour_id)
	local r = _random(1, 100)
	if r > param.param[1] or obj:get_mp() < self.expend_mp or param.obj_d == nil or not param.obj_d:is_alive() then
		return
	end
	local ret = self:on_effect(param)
	if ret == 0 and self.expend_mp > 0 then
		obj:add_mp(-self.expend_mp)
	end
	return ret
end

function Skill_appendage:on_effect(param)
	return 0
end

-- 当加入更高级的技能时，用于清理之前的附加值
function Skill_appendage:ineffectiveness(sour_id, param)
	
end


------------------- 宠物附体技能 加属性技能 -----------------------

Skill_appendage_attribute = oo.class(Skill_appendage, "Skill_appendage_attribute")

function Skill_appendage_attribute:__init(id, ty)
	Skill_appendage.__init(self, id, ty)
	
end

function Skill_appendage_attribute:effect(sour_id, param)
	--print("===>Skill_appendage_attribute:effect", sour_id, self.id)	
	local s_obj = g_obj_mgr:get_obj(sour_id)
	if s_obj ~= nil then
		local t = self:get_effect_val()
		for _, val in pairs(t) do
			s_obj:add_passive_effect(val[1], nil, val[2])
		end
	end
end

-- 当加入更高级的技能时，用于清理之前的附加值
function Skill_appendage_attribute:ineffectiveness(sour_id, param)
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

function Skill_appendage_attribute:get_effect_val()
	local t = {}
	local skill_cmd = self.cmd_id
	local level = self.level
	if skill_cmd == SKILL_OBJ_776000 then
		t[1] = {EXTRA_STRENGH, _sk_appendage_config._skill_p[skill_cmd][level]}

	elseif skill_cmd == SKILL_OBJ_776100 then
		t[1] = {EXTRA_INTELLIGENCE, _sk_appendage_config._skill_p[skill_cmd][level]}

	elseif skill_cmd == SKILL_OBJ_776200 then
		t[1] = {EXTRA_STEMINA, _sk_appendage_config._skill_p[skill_cmd][level]}
					  
	elseif skill_cmd == SKILL_OBJ_776300 then  
		t[1] = {EXTRA_CRITICAL_DE, _sk_appendage_config._skill_p[skill_cmd][level]}

	end

	return t
end

-- 
local skill_appendage_attribute_builder = function ()
	local skill_name_format = "Skill_%d"
	for skill_cmd = 776000, 777900, 100 do
		local skill_param = _sk_appendage_config._skill_p[skill_cmd]
		for level, params in pairs(skill_param or {} ) do
			local skill_name = string.format(skill_name_format, skill_cmd + level)
			_G[skill_name] = Skill_appendage_attribute(skill_cmd + level, SKILL_APPENDAGE_ATTRIBUTE)
			--print("==>skill_name", skill_name)
		end
	end
end

skill_appendage_attribute_builder()




-------------------  攻击触发类技能 -----------------------
-- 
f_skill_appendage_attack_builder = function (skill_cmd)
	skill_appendage_builder(skill_cmd, SKILL_APPENDAGE_ATTACK)
end