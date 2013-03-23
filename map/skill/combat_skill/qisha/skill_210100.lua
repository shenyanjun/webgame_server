
--local debug_print = print
local debug_print = function() end
local _expr = require("config.expr")
local _sk_config = require("config.skill_combat_config")

--残月无双 
Skill_210100 = oo.class(Skill_combat, "Skill_210100")

function Skill_210100:__init(cmd_id, lv)
	Skill_combat.__init(self, cmd_id, SKILL_BAD, SKILL_OBJ_210100, lv)
	self.ak = _sk_config._skill_p[SKILL_OBJ_210100][lv][2] 
end
--param.des_id
function Skill_210100:effect(sour_id, param)
	if param.des_id == nil or sour_id == param.des_id then return 21101 end
	local obj_s = g_obj_mgr:get_obj(sour_id)
	local obj_d = g_obj_mgr:get_obj(param.des_id)
	if obj_s == nil or obj_d == nil then 
		return 21101 
	end
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
		--被动技能附加攻击
		--local ak = self.ak + obj_s:get_set_effect(SKILL_ADD_ATTACK, SKILL_OBJ_210100)
		local set_l = obj_s:get_set_effect(SKILL_ADD_ATTACK, SKILL_OBJ_210100)
		local ak = self.ak + set_l[1] + self.ak*set_l[2]

		local new_pkt = self:make_hp_pkt(obj_s, obj_d, ak)
		obj_s:on_useskill(self.id, obj_d, new_pkt.hp)
		if obj_d:on_damage(new_pkt.hp, obj_s, self.id) then
			self:send_syn(obj_s, param.des_id, new_pkt, ret)
		end
		
		debug_print("Skill_210100:effect", sour_id, param.des_id, ak)
		return 0
	elseif ret == 1 then
		self:send_syn(obj_s, param.des_id, nil, ret)
		return 0
	end
	return 21002
end

f_create_skill_class("SKILL_OBJ_2101%02d", "Skill_2101%02d")
