
local debug_print = function() end
local _expr = require("config.expr")
local _sk_config = require("config.skill_combat_config")
local _random = crypto.random

-- 狂暴
Skill_1002800 = oo.class(Skill_combat, "Skill_1002800")

function Skill_1002800:__init(cmd_id, lv)
	Skill_combat.__init(self, cmd_id, SKILL_GOOD, SKILL_OBJ_1002800, lv)
	
	self.ak_per = _sk_config._skill_p[SKILL_OBJ_1002800][lv][2]
	self.sec = _sk_config._skill_p[SKILL_OBJ_1002800][lv][3] 
end
--param.des_id
function Skill_1002800:effect(sour_id, param)
	if param.des_id == nil then return 21101 end
	local obj_s = g_obj_mgr:get_obj(sour_id)
	local obj_d = g_obj_mgr:get_obj(param.des_id)
	if obj_s == nil or obj_d == nil then 
		return 21101 
	end

	if not self:is_validate_dis(obj_s, obj_d) then
		return 21131
	end

	local ret = obj_d:on_beskill(self.id, obj_s)
	if ret == 2 then
		--攻击力增益效果
		local impact_o = Impact_1401(param.des_id, self:get_level())

		param.per = self.ak_per
		impact_o:set_sec_count(1)
		impact_o:set_count(self.sec)
		impact_o:effect(param)

		obj_s:on_useskill(self.id, obj_d, 0)
		self:send_syn(obj_s, param.des_id, nil, ret)

		debug_print("Skill_1002800:effect:sour_id:", sour_id, "param.per", param.per, "param.des_id", param.des_id)
		return 0
	elseif ret == 1 then
		self:send_syn(obj_s, param.des_id, nil, ret)
		return 0
	end
	return 21102
end

f_create_monster_skill_class("SKILL_OBJ_10028%02d", "Skill_10028%02d")