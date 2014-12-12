
local _expr = require("config.expr")
local _sk_config = require("config.skill_combat_config")

--修罗降世
Skill_110800 = oo.class(Skill_combat, "Skill_110800")

function Skill_110800:__init(cmd_id, lv)
	Skill_combat.__init(self, cmd_id, SKILL_GOOD, SKILL_OBJ_110800, lv)
	
	self.sec = _sk_config._skill_p[SKILL_OBJ_110800][lv][2] 
	self.de_per = _sk_config._skill_p[SKILL_OBJ_110800][lv][3] 
end
--param nil
function Skill_110800:effect(sour_id, param)
	local obj_s = g_obj_mgr:get_obj(sour_id)
	if obj_s == nil then 
		return 21101 
	end

	local ret = obj_s:on_beskill(self.id, obj_s)
	if ret == 2 then
		--降伤害效果
		local impact_o = Impact_1831(sour_id, self:get_level())
		impact_o:set_count(self.sec)  
		param.per = self.de_per
		impact_o:effect(param)

		obj_s:on_useskill(self.id, obj_s, 0)
		self:send_syn(obj_s, nil, nil, ret)
		return 0
	elseif ret == 1 then
		self:send_syn(obj_s, nil, nil, ret)
		return 0
	end
	return 21102
end

f_create_skill_class("SKILL_OBJ_1108%02d", "Skill_1108%02d")
