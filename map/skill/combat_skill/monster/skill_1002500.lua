
local debug_print = function() end
local _expr = require("config.expr")
local _sk_config = require("config.skill_combat_config")
local _random = crypto.random

--定身
Skill_1002500 = oo.class(Skill_combat, "Skill_1002500")

function Skill_1002500:__init(cmd_id, lv)
	Skill_combat.__init(self, cmd_id, SKILL_BAD, SKILL_OBJ_1002500, lv)
	
	self.ak = _sk_config._skill_p[SKILL_OBJ_1002500][lv][2] 
	self.sec = _sk_config._skill_p[SKILL_OBJ_1002500][lv][3] 
	self.dg_type = _sk_config._skill_p[SKILL_OBJ_1002500][lv][4]
end
--param.des_id
function Skill_1002500:effect(sour_id, param)
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
		--定身效果
		local impact_o = Impact_1211(param.des_id)
		if obj_d:on_beimpact(impact_o:get_cmd_id(), obj_s) == 1 then
			impact_o:set_count(self.sec)
			impact_o:effect(param)
		else
			impact_o:immune()
		end

		--伤害
		local new_pkt = self:make_hp_pkt(obj_s, obj_d, self.ak or 0, self.dg_type)
		obj_s:on_useskill(self.id, obj_d, new_pkt.hp)
		if obj_d:on_damage(new_pkt.hp, obj_s, self.id) then
			self:send_syn(obj_s, param.des_id, new_pkt, ret)
		end

		debug_print("Skill_1002500:effect", sour_id, param.des_id, self.ak)
		return 0
	elseif ret == 1 then
		self:send_syn(obj_s, param.des_id, nil, ret)
		return 0
	end
	return 21102
end

f_create_monster_skill_class("SKILL_OBJ_10025%02d", "Skill_10025%02d")