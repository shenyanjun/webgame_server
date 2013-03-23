
local _sk_config = require("config.skill_combat_config")


--怪物物理群体攻击
Skill_1002100 = oo.class(Skill_combat, "Skill_1002100")

function Skill_1002100:__init(cmd_id, lv)
	Skill_combat.__init(self, cmd_id, SKILL_BAD, SKILL_OBJ_1002100, lv)
	-- 范围
	self.scope 		= _sk_config._skill_p[SKILL_OBJ_1002100][lv][2]
	self.ak 		= _sk_config._skill_p[SKILL_OBJ_1002100][lv][3]
	self.addition 	= _sk_config._skill_p[SKILL_OBJ_1002100][lv][4]
end
--param.des_id
function Skill_1002100:effect(sour_id, param)
	local obj_s = g_obj_mgr:get_obj(sour_id)
	if obj_s == nil then 
		return 21101 
	end

	local scene_o = obj_s:get_scene_obj()
	local map_obj = scene_o:get_map_obj()
	local scene_mode = scene_o:get_mode()
	local obj_list = {}
	if scene_mode == SCENE_MODE.SIDE then
		obj_list = map_obj:monster_scan_obj_side(obj_s:get_pos(), self.scope, 6, obj_s:get_side())
	else
		obj_list = map_obj:monster_scan_obj_rect(obj_s:get_pos(), self.scope, 6)
	end
	obj_list[sour_id] = nil

	obj_s:on_useskill(self.id, nil, 0)
	self:send_syn(obj_s, obj_s:get_id(), nil, 2)  --技能同步

	for k,v in pairs(obj_list) do
		local obj_o = g_obj_mgr:get_obj(k)
		if obj_o ~= nil and scene_o:is_attack(sour_id, k) == 0 then
			local ret = obj_o:on_beskill(self.id, obj_s)
			if ret == 2 then
				local new_pkt = self:make_hp_pkt(obj_s, obj_o, self.ak or 0)
				-- 附加伤害
				new_pkt[3] = new_pkt[3] - self.addition
				new_pkt.hp = new_pkt.hp - self.addition
				if obj_o:on_damage(new_pkt.hp, obj_s, self.id) then
					self:send_syn(obj_s, k, new_pkt, ret)
				end
			elseif ret == 1 then
			end
		end
	end
	return 0
end


f_create_monster_skill_class("SKILL_OBJ_10021%02d", "Skill_10021%02d")


