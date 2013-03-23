
local debug_print = function() end
local _expr = require("config.expr")
local _sk_config = require("config.skill_combat_config")
local _random = crypto.random

--击退
Skill_990400 = oo.class(Skill_combat, "Skill_990400")

function Skill_990400:__init(cmd_id, lv)
	Skill_combat.__init(self, cmd_id, SKILL_GOOD, SKILL_OBJ_990400, lv)
	
	self.dis = _sk_config._skill_p[SKILL_OBJ_990400][lv][1]       --击退距离
end
--param.des_id
function Skill_990400:effect(sour_id, param)
	if param.des_id == nil then return 21101 end
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
	local pos = obj_s:get_pos()
	local des_pos = obj_s:get_des_pos()
	if pos[1] == des_pos[1] and pos[2] == des_pos[2] then
		return 21137
	end
	local ret = obj_d:on_beskill(self.id, obj_s)
	if ret == 2 then
		--击退
		local new_pos = map_obj:find_far_pos(pos, des_pos, self.dis)
		if new_pos ~= nil then
			obj_s:modify_pos(new_pos)
			scene_o:send_move_soon_syn(obj_d:get_id(), obj_d, pos, new_pos, 2)
		end
		--伤害

		debug_print("Skill_990400:effect", sour_id, param.des_id, self.ak)
		return 0
	elseif ret == 1 then
		self:send_syn(obj_s, param.des_id, nil, ret)
		return 0
	end
	return 21102
end

f_create_skill_class("SKILL_OBJ_9904%02d", "Skill_9904%02d")