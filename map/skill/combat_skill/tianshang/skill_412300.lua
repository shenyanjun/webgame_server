
local _expr = require("config.expr")
local _sk_config = require("config.skill_combat_config")

--阳炎
Skill_412300 = oo.class(Skill_combat, "Skill_412300")

function Skill_412300:__init(cmd_id, lv)
	Skill_combat.__init(self, cmd_id, SKILL_BAD, SKILL_OBJ_412300, lv)
	self.ak = _sk_config._skill_p[SKILL_OBJ_412300][lv][2]
end
--param.des_id
function Skill_412300:effect(sour_id, param)
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

	obj_s:on_useskill(self.id, nil, 0)
	self:send_syn(obj_s, param.des_id, nil, 2)  --技能同步

	local map_obj = scene_o:get_map_obj()
	local obj_list = map_obj:scan_obj_rect(obj_d:get_pos(), 4, nil, 6)
	obj_list[sour_id] = nil

	for k,v in pairs(obj_list) do
		local obj_o = g_obj_mgr:get_obj(k)
		if obj_o ~= nil and scene_o:is_attack(sour_id, k) == 0 then
			local ret = obj_o:on_beskill(self.id, obj_s)
			if ret == 2 then
				local new_pkt = self:make_hp_pkt(obj_s, obj_o, self.ak, 2)
				if obj_o:on_damage(new_pkt.hp, obj_s, self.id) then
					--self:send_syn(obj_s, k, new_pkt, ret)
					--self:send_syn_to_hp(0, obj_o, new_pkt.hp, 0)
				end
			elseif ret == 1 then
			end
		end
	end

	return 0
end

f_create_skill_class("SKILL_OBJ_4123%02d", "Skill_4123%02d")


