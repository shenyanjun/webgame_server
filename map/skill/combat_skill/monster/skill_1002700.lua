
local debug_print = function() end
local _expr = require("config.expr")
local _sk_config = require("config.skill_combat_config")
local _random = crypto.random

--召唤炸弹怪 扔向玩家
Skill_1002700 = oo.class(Skill_combat, "Skill_1002700")

function Skill_1002700:__init(cmd_id, lv)
	Skill_combat.__init(self, cmd_id, SKILL_GOOD, SKILL_OBJ_1002700, lv)

	self.monster_id = _sk_config._skill_p[SKILL_OBJ_1002700][lv][2]
	self.monster_count = _sk_config._skill_p[SKILL_OBJ_1002700][lv][3]
	self.monster_time = _sk_config._skill_p[SKILL_OBJ_1002700][lv][4]
	self.monster_skill = _sk_config._skill_p[SKILL_OBJ_1002700][lv][5]
	self.sec_att = _sk_config._skill_p[SKILL_OBJ_1002700][lv][6]
end
--param.des_id
function Skill_1002700:effect(sour_id, param)
	local obj_s = g_obj_mgr:get_obj(sour_id)
	local obj_d = g_obj_mgr:get_obj(param.des_id)
	if obj_s == nil or obj_d == nil then 
		return 21101 
	end
	if self.sec_att then
		local obj_d2 = g_obj_mgr:get_obj(obj_s:get_enemy_id_x())
		if obj_d2 and self:is_validate_dis(obj_s, obj_d2) then
			obj_d = obj_d2
		end
	end
	
	local ret = obj_s:on_beskill(self.id, obj_s)
	if ret == 2 then
		--召唤
		local m_param = {self.monster_time, sour_id, self.monster_skill}
		local attack_id = obj_d:get_id()
	
		local scene_d = obj_s:get_scene()

		for i=1,self.monster_count do
			local pos = obj_d:get_pos()
			local obj = g_obj_mgr:create_monster(self.monster_id, pos, scene_d, m_param)
			g_scene_mgr_ex:enter_scene(obj)
			
			if attack_id ~= nil then
				obj:add_enemy_obj(attack_id, nil)
			end
		end

		obj_s:on_useskill(self.id, obj_s, hp)
		self:send_syn(obj_s, obj_s:get_id(), nil, ret)
		return 0
	elseif ret == 1 then
		self:send_syn(obj_s, obj_s:get_id(), nil, ret)
		return 0
	end
	return 21102
end

f_create_monster_skill_class("SKILL_OBJ_10027%02d", "Skill_10027%02d")