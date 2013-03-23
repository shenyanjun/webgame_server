
local debug_print = function() end
local _expr = require("config.expr")
local _sk_config = require("config.skill_combat_config")

--挑衅
Skill_110700 = oo.class(Skill_combat, "Skill_110700")

function Skill_110700:__init(cmd_id, lv)
	Skill_combat.__init(self, cmd_id, SKILL_MONSTER, SKILL_OBJ_110700, lv)
	
	self.sec = _sk_config._skill_p[SKILL_OBJ_110700][lv][2]
end
--param nil
function Skill_110700:effect(sour_id, param)
	local obj_s = g_obj_mgr:get_obj(sour_id)
	if obj_s == nil then 
		return 21101 
	end

	local scene_o = obj_s:get_scene_obj()
	local map_obj = scene_o:get_map_obj()
	local obj_list = map_obj:scan_obj_rect(obj_s:get_pos(), 8, OBJ_TYPE_MONSTER, 12)

	obj_s:on_useskill(self.id, obj_s, 0)
	for k,v in pairs(obj_list) do
		local obj_o = g_obj_mgr:get_obj(k)
		if obj_o ~= nil and scene_o:is_attack(sour_id, k) == 0 then
			local ret = obj_o:on_beskill(self.id, obj_s)
			if ret == 2 then
				local impact_o = Impact_1281(k)
				param.sour_id = sour_id
				param.skill_id = self.id
				param.pos = nil
				impact_o:set_count(self.sec)
				impact_o:effect(param)
			end
		end
	end
	self:send_syn(obj_s, nil, nil, ret)
	
	return 0
end

f_create_skill_class("SKILL_OBJ_1107%02d", "Skill_1107%02d")
