
local _expr = require("config.expr")
local _sk_config = require("config.skill_combat_config")

--剑火燃雷
Skill_311100 = oo.class(Skill_combat, "Skill_311100")

function Skill_311100:__init(cmd_id, lv)
	Skill_combat.__init(self, cmd_id, SKILL_BAD, SKILL_OBJ_311100, lv)
	self.dg = _sk_config._skill_p[SKILL_OBJ_311100][lv][2]
end
--param.des_id
function Skill_311100:effect(sour_id, param)
	if param.des_id == nil or sour_id == param.des_id then return 21101 end
	local obj_s = g_obj_mgr:get_obj(sour_id)
	local obj_d = g_obj_mgr:get_obj(param.des_id)
	if obj_s == nil or obj_d == nil then return 21101 end

	if not self:is_validate_dis(obj_s, obj_d) then
		return 21131
	end

	local scene_o = obj_s:get_scene_obj()
	local md_ret = scene_o:is_attack(sour_id, param.des_id)
	if md_ret ~= 0 then
		return md_ret
	end

	local ret = obj_d:on_beskill(self.id, obj_s)
	if ret == 2 then
		--持续伤害
		local impact_o = Impact_1301(param.des_id)
		local p1 = table.copy(param)
		p1.sour_id = sour_id
		p1.skill_id = self.id
		p1.ak = math.random(obj_s:get_m_attack_t())
		p1.dg = self.dg

		impact_o:set_count(5)
		impact_o:effect(p1)

		obj_s:on_useskill(self.id, obj_d, 0)
		self:send_syn(obj_s, param.des_id, nil, ret)
		return 0
	elseif ret == 1 then
		self:send_syn(obj_s, param.des_id, nil, ret)
		return 0
	end
	return 21102
end


f_create_skill_class("SKILL_OBJ_3111%02d", "Skill_3111%02d")
