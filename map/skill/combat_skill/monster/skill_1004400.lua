local _expr = require("config.expr")
local _sk_config = require("config.skill_combat_config")


--加怒气
Skill_1004400 = oo.class(Skill_combat, "Skill_1004400")

function Skill_1004400:__init(cmd_id, lv)
	Skill_combat.__init(self, cmd_id, SKILL_BAD, SKILL_OBJ_1004400, lv)
	-- 范围
	self.range		= _sk_config._skill_p[SKILL_OBJ_1004400][lv][2]
	--self.per 		= _sk_config._skill_p[SKILL_OBJ_1004400][lv][3]
	self.rage		= _sk_config._skill_p[SKILL_OBJ_1004400][lv][4]
end


function Skill_1004400:effect(sour_id, param)
	local obj_s = g_obj_mgr:get_obj(sour_id)
	if obj_s == nil then 
		return 21101 
	end

	local scene_o = obj_s:get_scene_obj()
	local map_obj = scene_o:get_map_obj()
	local scene_mode = scene_o:get_mode()
	local obj_list = {}
	if scene_mode == SCENE_MODE.SIDE then
		obj_list = map_obj:monster_scan_obj_side(obj_s:get_pos(), self.range, 6, obj_s:get_side())
	else
		obj_list = map_obj:monster_scan_obj_rect(obj_s:get_pos(), self.range, 6)
	end
	obj_s:on_useskill(self.id, nil, 0)
	self:send_syn(obj_s, obj_s:get_id(), nil, 2)  --技能同步
	
	for k,v in pairs(obj_list) do
		local obj_o = g_obj_mgr:get_obj(k)
		if obj_o ~= nil and scene_o:is_attack(sour_id, k) == 0 and obj_o:get_type() == OBJ_TYPE_HUMAN then
			local ret = obj_o:on_beskill(self.id, obj_s)
			if ret == 2 then
				local rage = self.rage 
				if rage >= 0 then
					obj_o:add_rage(rage)      --增加怒气
				else
					obj_o:sub_rage(-rage)      --减少怒气
				end
				self:send_syn(obj_s, k, nil, ret)
				return 0
			elseif ret == 1 then
				self:send_syn(obj_s, k, nil, ret)
				return 0
			end
		end
	end
	return 21102
end

f_create_monster_skill_class("SKILL_OBJ_10044%02d", "Skill_10044%02d")
