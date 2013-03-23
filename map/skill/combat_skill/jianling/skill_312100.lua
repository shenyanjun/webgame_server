
local _expr = require("config.expr")
local _sk_config = require("config.skill_combat_config")

--穿云剑诀，增加物攻
Skill_312100 = oo.class(Skill_combat, "Skill_312100")

function Skill_312100:__init(cmd_id, lv)
	Skill_combat.__init(self, cmd_id, SKILL_GOOD, SKILL_OBJ_312100, lv)
	
	self.sec = _sk_config._skill_p[SKILL_OBJ_312100][lv][2]
	self.ak_per = _sk_config._skill_p[SKILL_OBJ_312100][lv][3]
end
--param nil
function Skill_312100:effect(sour_id, param)
	local obj_s = g_obj_mgr:get_obj(sour_id)
	if obj_s == nil then 
		return 21101 
	end

	local ret = obj_s:on_beskill(self.id, obj_s)
	if ret == 2 then
		--物攻效果2
		local impact_o = Impact_1402(sour_id, self:get_level())
		impact_o:set_count(self.sec)  
		param.per = self.ak_per
		impact_o:effect(param)

		--[[local impact_con = obj_s:get_impact_con()
		local impact_o_old = impact_con:find_impact(impact_o:get_cmd_id())
		local lv = impact_o_old and impact_o_old:get_level() or self:get_level()
		if lv <= self:get_level() then 
			param.per = self.ak_per
			impact_o:effect(param)
		end]]

		obj_s:on_useskill(self.id, obj_s, 0)
		self:send_syn(obj_s, nil, nil, ret)
		return 0
	elseif ret == 1 then
		self:send_syn(obj_s, nil, nil, ret)
		return 0
	end
	return 21102
end

f_create_skill_class("SKILL_OBJ_3121%02d", "Skill_3121%02d")
