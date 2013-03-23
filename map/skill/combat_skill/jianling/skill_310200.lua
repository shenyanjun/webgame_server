
local _expr = require("config.expr")
local _sk_config = require("config.skill_combat_config")

--剑荡八荒 
Skill_310200 = oo.class(Skill_combat, "Skill_310200")

function Skill_310200:__init(cmd_id, lv)
	Skill_combat.__init(self, cmd_id, SKILL_BAD, SKILL_OBJ_310200, lv)
	self.ak = _sk_config._skill_p[SKILL_OBJ_310200][lv][2]
end
--param.des_id
function Skill_310200:effect(sour_id, param)
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
	local map_obj = scene_o:get_map_obj()
	local obj_list = map_obj:scan_sector_rect(obj_s:get_pos(), obj_d:get_pos(), 8)
	obj_list[sour_id] = nil

	obj_s:on_useskill(self.id, nil, 0)
	for k,v in pairs(obj_list) do
		local obj_o = g_obj_mgr:get_obj(k)
		if obj_o ~= nil and scene_o:is_attack(sour_id, k) == 0 then
			local ret = obj_o:on_beskill(self.id, obj_s)
			if ret == 2 then
				local new_pkt = self:make_hp_pkt(obj_s, obj_o, self.ak)
				if obj_o:on_damage(new_pkt.hp, obj_s, self.id) then
					self:send_syn(obj_s, k, new_pkt, ret)
				end
			elseif ret == 1 then
				--self:send_syn(obj_s, k, nil, ret)
			end
		end
	end

	return 0
end


f_create_skill_class("SKILL_OBJ_3102%02d", "Skill_3102%02d")
