
local _expr = require("config.expr")
local _sk_config = require("config.skill_combat_config")


--神剑御雷
Skill_310100 = oo.class(Skill_combat, "Skill_310100")

function Skill_310100:__init(cmd_id, lv)
	Skill_combat.__init(self, cmd_id, SKILL_BAD, SKILL_OBJ_310100, lv)
	self.ak = _sk_config._skill_p[SKILL_OBJ_310100][lv][2]
end
--param.des_id
function Skill_310100:effect(sour_id, param)
	local obj_s = g_obj_mgr:get_obj(sour_id)
	if obj_s == nil or param.pos == nil then 
		return 21101 
	end
	
	local scene_o = obj_s:get_scene_obj()
	local map_obj = scene_o:get_map_obj()
	if map_obj:distance(obj_s:get_pos(), param.pos) > self.distance + 3 then
		return 21131
	end

	local obj_list = map_obj:scan_obj_rect(param.pos, 2, nil, 6)
	obj_list[sour_id] = nil

	obj_s:on_useskill(self.id, nil, 0)
	self:send_syn_by_pos(obj_s, param.pos)

	--套装附加攻击
	--local ak = self.ak + obj_s:get_set_effect(SKILL_ADD_ATTACK, SKILL_OBJ_310100)
	local set_l = obj_s:get_set_effect(SKILL_ADD_ATTACK, SKILL_OBJ_310100)
	local ak = self.ak + set_l[1] + self.ak*set_l[2]
	for k,v in pairs(obj_list) do
		local obj_o = g_obj_mgr:get_obj(k)
		if obj_o ~= nil and scene_o:is_attack(sour_id, k) == 0 then
			local ret = obj_o:on_beskill(self.id, obj_s)
			if ret == 2 then
				local new_pkt = self:make_hp_pkt(obj_s, obj_o, ak)
				if obj_o:on_damage(new_pkt.hp, obj_s, self.id) then
					self:send_syn(obj_s, k, new_pkt, ret)
				end
			end
		elseif ret == 1 then
			--self:send_syn(obj_s, k, nil, ret)
		end
	end

	return 0
end

f_create_skill_class("SKILL_OBJ_3101%02d", "Skill_3101%02d")
