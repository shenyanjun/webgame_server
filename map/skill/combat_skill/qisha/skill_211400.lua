
--local debug_print = print
local debug_print = function() end
local _expr = require("config.expr")
local _sk_config = require("config.skill_combat_config")

--如影随形 
Skill_211400 = oo.class(Skill_combat, "Skill_211400")

function Skill_211400:__init(cmd_id, lv)
	Skill_combat.__init(self, cmd_id, SKILL_GOOD, SKILL_OBJ_211400, lv)
	self.va_dis = _sk_config._skill_p[SKILL_OBJ_211400][lv][2]       --有效距离
end
--param.des_id
function Skill_211400:effect(sour_id, param)
	if param.des_id == nil or sour_id == param.des_id then return 21101 end
	local obj_s = g_obj_mgr:get_obj(sour_id)
	local obj_d = g_obj_mgr:get_obj(param.des_id)
	if obj_s == nil or obj_d == nil then 
		return 21101 
	end
	
	local scene_o = obj_s:get_scene_obj()
	local map_obj = scene_o:get_map_obj()
	local ret = obj_d:on_beskill(self.id, obj_s)
	if ret == 2 then
		debug_print("Skill_211400:effect", sour_id, param.des_id)

		local pos = obj_s:get_pos()
		local des_pos = obj_d:get_pos()
		if map_obj:distance(pos, des_pos) > self.va_dis + 3 then
			return 21131
		end

		--解除定身效果
		local impact_con = obj_s:get_impact_con()
		impact_con:blow_impact(IMPACT_OBJ_1211)
		impact_con:blow_impact(IMPACT_OBJ_1212)

		--移动坐标
		obj_s:modify_pos(des_pos)
		scene_o:send_move_soon_syn(sour_id, obj_s, pos, des_pos, 1)

		obj_s:on_useskill(self.id, obj_s, 0)
		self:send_syn(obj_s, param.des_id, nil, ret)
		return 0
	elseif ret == 1 then
		self:send_syn(obj_s, param.des_id, nil, ret)
		return 0
	end
	return 21002
end

f_create_skill_class("SKILL_OBJ_2114%02d", "Skill_2114%02d")
