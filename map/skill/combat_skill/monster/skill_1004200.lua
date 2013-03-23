
local _sk_config = require("config.skill_combat_config")


--空技能，只要特效
Skill_1004200 = oo.class(Skill_combat, "Skill_1004200")

function Skill_1004200:__init(cmd_id, lv)
	Skill_combat.__init(self, cmd_id, SKILL_GOOD, SKILL_OBJ_1004200, lv)
	-- 范围

end
--param.des_id
function Skill_1004200:effect(sour_id, param)
	if param.des_id == nil then return 21101 end
	local obj_s = g_obj_mgr:get_obj(sour_id)
	local obj_d = g_obj_mgr:get_obj(param.des_id)
	if obj_s == nil or obj_d == nil then 
		return 21101 
	end
	if sour_id ~= param.des_id and not self:is_validate_dis(obj_s, obj_d) then
		return 21131
	end

	local ret = obj_d:on_beskill(self.id, obj_s)
	if ret == 2 then
		obj_s:on_useskill(self.id, obj_d, 0)
		self:send_syn(obj_s, param.des_id, nil, ret)
		return 0
	elseif ret == 1 then
		self:send_syn(obj_s, param.des_id, nil, ret)
		return 0
	end
	return 21102
end

f_create_monster_skill_class("SKILL_OBJ_10042%02d", "Skill_10042%02d")


