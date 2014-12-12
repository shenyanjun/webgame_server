
local _expr = require("config.expr")
local _sk_config = require("config.skill_combat_config")

--罡风凌云
Skill_110500 = oo.class(Skill_combat, "Skill_110500")

function Skill_110500:__init(cmd_id, lv)
	Skill_combat.__init(self, cmd_id, SKILL_GOOD, SKILL_OBJ_110500, lv)

	self.sec = _sk_config._skill_p[SKILL_OBJ_110500][lv][2] 
	self.sp_per = _sk_config._skill_p[SKILL_OBJ_110500][lv][3] 
end
--param nil
function Skill_110500:effect(sour_id, param)
	local obj_s = g_obj_mgr:get_obj(sour_id)
	if obj_s == nil then 
		return 21101 
	end
	
	local ret = obj_s:on_beskill(self.id, obj_s)
	if ret == 2 then
		--加速效果
		local impact_o = Impact_1451(sour_id)
		impact_o:set_count(self.sec)     --10秒
		local p2 = table.copy(param)
		p2.per = self.sp_per
		impact_o:effect(p2)

		obj_s:on_useskill(self.id, obj_s, 0)
		self:send_syn(obj_s, nil, nil, ret)
		return 0
	elseif ret == 1 then
		self:send_syn(obj_s, nil, nil, ret)
		return 0
	end
	return 21002
end

f_create_skill_class("SKILL_OBJ_1105%02d", "Skill_1105%02d")
