
local _expr = require("config.expr")
--local _sk_param_passive = f_get_passive_skill_param()
local _sk_config_passive = require("config.skill_passive_config")

---------增加命中----------
Passive_point = oo.class(Skill_passive,"Passive_point")

function Passive_point:__init(cmd_id, ty, lv)
	Skill_passive.__init(self, cmd_id, ty, SKILL_ADD_POINT, lv)
	self.point = _sk_config_passive._skill_p[ty][lv]
end
--返回param
function Passive_point:get_effect()
end

--param nil
function Passive_point:effect(sour_id, param)
	local obj_s = g_obj_mgr:get_obj(sour_id)
	obj_s:clean_passive_effect(SKILL_ADD_POINT)
	obj_s:add_passive_effect(SKILL_ADD_POINT, nil, self.point)
end


-------------增加暴击-------------
Passive_critical = oo.class(Skill_passive,"Passive_critical")

function Passive_critical:__init(cmd_id, ty,  lv)
	Skill_passive.__init(self, cmd_id, ty, SKILL_ADD_CRITICAL, lv)
	self.critical = _sk_config_passive._skill_p[ty][lv]
end
--返回param
function Passive_critical:get_effect()
end

--param nil
function Passive_critical:effect(sour_id, param)
	local obj_s = g_obj_mgr:get_obj(sour_id)
	obj_s:clean_passive_effect(SKILL_ADD_CRITICAL)
	obj_s:add_passive_effect(SKILL_ADD_CRITICAL, nil, self.critical)
end


--------------减少mp-----------
Passive_mp = oo.class(Skill_passive,"Passive_mp")

function Passive_mp:__init(cmd_id, ty, lv)
	Skill_passive.__init(self, cmd_id, ty, SKILL_SUB_MP, lv)
	self.sk_l = _sk_config_passive._skill_p[ty][lv]
end
--返回param
function Passive_mp:get_effect()
end

--param nil
function Passive_mp:effect(sour_id, param)
	local obj_s = g_obj_mgr:get_obj(sour_id)
	obj_s:clean_passive_effect(SKILL_SUB_MP)

	for k,v in pairs(self.sk_l) do
		local i = 1
		while true do
			local str = string.format(k, i)
			i = i + 1
			if _G[str] == nil then break end
			obj_s:add_passive_effect(SKILL_SUB_MP, _G[str], v)
		end
	end
end


--------------减少cd--------------
Passive_cd = oo.class(Skill_passive,"Passive_cd")

function Passive_cd:__init(cmd_id, ty, lv)
	Skill_passive.__init(self, cmd_id, ty, SKILL_SUB_CD, lv)
	self.cd_l = _sk_config_passive._skill_p[ty][lv]
end
--返回param
function Passive_cd:get_effect()
end

--param nil
function Passive_cd:effect(sour_id, param)
	local obj_s = g_obj_mgr:get_obj(sour_id)
	local skill_con = obj_s:get_skill_con()

	for k,v in pairs(self.cd_l) do
		--[[local i = 1
		while true do
			local str = string.format(k, i)
			i = i + 1
			if _G[str] == nil then break end

			local cd_o = skill_con:get_skill_cd(_G[str])
			if cd_o ~= nil then
				cd_o:set_cd_time(cd_o:get_cd_time() - v)
				break
			end
		end]]
		local str = string.format(k, 0)   --cmd_id
		if _G[str] ~= nil then
			local cd_o = skill_con:get_skill_cd(_G[str])
			if cd_o ~= nil then
				cd_o:set_cd_time(cd_o:get_cd_time() - v)
			end
		end
	end
	return 0
end


----------------增加技能攻击力--------------
Passive_attack = oo.class(Skill_passive,"Passive_attack")

function Passive_attack:__init(cmd_id, ty, lv)
	Skill_passive.__init(self, cmd_id, ty, SKILL_ADD_ATTACK, lv)
	self.ak_per = _sk_config_passive._skill_p[ty][lv]
end
--返回param
function Passive_attack:get_effect()
end

--param nil
function Passive_attack:effect(sour_id, param)
	local obj_s = g_obj_mgr:get_obj(sour_id)
	obj_s:clean_passive_effect(SKILL_ADD_ATTACK)
	obj_s:add_passive_effect(SKILL_ADD_ATTACK, nil, self.ak_per)

	--[[for k,v in pairs(self.sk_l) do
		local i = 1
		while true do
			local str = string.format(k, i)
			i = i + 1
			if _G[str] == nil then break end
			obj_s:add_passive_effect(SKILL_ADD_ATTACK, _G[str], v)
		end
	end]]
end


----------------增加治疗效果--------------
Passive_doctor = oo.class(Skill_passive,"Passive_doctor")

function Passive_doctor:__init(cmd_id, ty, lv)
	Skill_passive.__init(self, cmd_id, ty, SKILL_ADD_DOCTOR, lv)
	self.sk_per = _sk_config_passive._skill_p[ty][lv]
end
--返回param
function Passive_doctor:get_effect()
end

--param nil
function Passive_doctor:effect(sour_id, param)
	local obj_s = g_obj_mgr:get_obj(sour_id)
	obj_s:clean_passive_effect(SKILL_ADD_DOCTOR)
	obj_s:add_passive_effect(SKILL_ADD_DOCTOR, nil, self.sk_per)

	--[[for k,v in pairs(self.sk_l) do
		local i = 1
		while true do
			local str = string.format(k, i)
			i = i + 1
			if _G[str] == nil then break end
			obj_s:add_passive_effect(SKILL_ADD_DOCTOR, _G[str], v)
		end
	end]]
end



------------------- 通用被动技能 -----------------------

Skill_passive_common = oo.class(Skill_passive, "Skill_passive_common")


function Skill_passive_common:__init(skill_type, level)
	Skill_passive.__init(self, skill_type + level, SKILL_PASSIVE, skill_type, level)
	self.extra = table.copy(_sk_config_passive._skill_p[skill_type][level])
	self.skill_type = skill_type
	--print("==>skill_type:", skill_type, "level:", level, "extra[1]:", self.extra[1], "extra[2]:", self.extra[2])
end

function Skill_passive_common:get_effect(param)
	return nil;
end

function Skill_passive_common:effect(sour_id, param)
	local s_obj = g_obj_mgr:get_obj(sour_id)
	--print("===>Skill_passive_common:effect,sour_id", sour_id)
	if s_obj ~= nil then
		s_obj:add_passive_effect(self:get_extra_type(self.skill_type), nil, self.extra)
	end
end

-- 当加入更高级的技能时，用于清理之前的附加值
function Skill_passive_common:ineffectiveness(sour_id, param)
	local s_obj = g_obj_mgr:get_obj(sour_id)

	if s_obj ~= nil then
		local extra = {}
		extra[1] = -self.extra[1]
		extra[2] = -self.extra[2]
		s_obj:add_passive_effect(self:get_extra_type(self.skill_type), nil, extra)
	end
end

-- 根据skill_type返回增加的类型的值
function Skill_passive_common:get_extra_type(skill_type)
	local extra_type = (skill_type - SKILL_PASSIVE_COMMON_BEGIN) / 100 + 1

	if extra_type < 1 and extra_type > 50 then
		print("===>Skill_passive_common:get_extra_type: something error")
		return nil
	end
	return extra_type
end


local skill_passive_common_builder = function ()
	local skill_name_format = "Skill_%d"
	
	for skill_type = SKILL_PASSIVE_COMMON_BEGIN, SKILL_PASSIVE_COMMON_END, 100 do
		local skill_param = _sk_config_passive._skill_p[skill_type]
		for level, params in pairs(skill_param or {} )do
			local skill_name = string.format(skill_name_format, skill_type + level)
			_G[skill_name] = Skill_passive_common(skill_type, level)
			--print("==>skill_name", skill_name)
		end
	end
end

skill_passive_common_builder()