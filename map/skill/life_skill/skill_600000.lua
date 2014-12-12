--[[
local debug_print = function () end
local _sk_config = require("config.skill_combat_config")


--打坐技能
Skill_600000 = oo.class(Skill_life,"Skill_600000")

function Skill_600000:__init(skill_id, lv)
	Skill_life.__init(self, skill_id, SKILL_OBJ_600000, lv)
end

function Skill_600000:effect(sour_id, param)

	local obj_s = g_obj_mgr:get_obj(sour_id)
	if obj_s == nil then
		return 21101
	end

	local ret = obj_s:is_carry()
	if ret ~= 0 then
		return ret
	end

	local ret = obj_s:on_beskill(self.id, obj_s)
	if ret == 2 then
		obj_s:on_useskill(self.id, obj_s, 0)
		self:send_syn(obj_s, nil, nil, ret)

		g_scene_mgr_ex:convey_to_relive(obj_s)

		return 0
	elseif ret == 1 then
		self:send_syn(obj_s, nil, nil, ret)
		return 0
	end
	return 21002
	
end


f_create_life_skill_class("SKILL_OBJ_6000%02d", "Skill_6000%02d")

]]