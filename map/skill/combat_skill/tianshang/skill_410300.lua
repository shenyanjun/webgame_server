
local _expr = require("config.expr")
local _sk_config = require("config.skill_combat_config")

--幻影重重 
Skill_410300 = oo.class(Skill_combat, "Skill_410300")

function Skill_410300:__init(cmd_id, lv)
	Skill_combat.__init(self, cmd_id, SKILL_GOOD, SKILL_OBJ_410300, lv)
	self.per = _sk_config._skill_p[SKILL_OBJ_410300][lv][2] 
	self.sec = _sk_config._skill_p[SKILL_OBJ_410300][lv][3] 
end
--param nil
function Skill_410300:effect(sour_id, param)
	local obj_s = g_obj_mgr:get_obj(sour_id)
	if obj_s == nil then return 21101 end

	local scene_o = obj_s:get_scene_obj()
	local ret = obj_s:on_beskill(self.id, obj_s)
	if ret == 2 then
		--燃烧效果
		local impact_o = Impact_1511(sour_id)
		param.per = self.per
		impact_o:set_count(self.sec) 
		impact_o:effect(param)

		obj_s:on_useskill(self.id, obj_s, 0)
		self:send_syn(obj_s, nil, nil, ret)
		return 0
	elseif ret == 1 then
		self:send_syn(obj_s, nil, nil, ret)
		return 0
	end
	return 21002
end


f_create_skill_class("SKILL_OBJ_4103%02d", "Skill_4103%02d")
