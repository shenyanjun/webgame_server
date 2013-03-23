
local debug_print = function() end
local _expr = require("config.expr")
local _sk_config = require("config.skill_combat_config")
local _random = crypto.random

--加速
Skill_990300 = oo.class(Skill_combat, "Skill_990300")

function Skill_990300:__init(cmd_id, lv)
	Skill_combat.__init(self, cmd_id, SKILL_GOOD, SKILL_OBJ_990300, lv)
	
	self.per = _sk_config._skill_p[SKILL_OBJ_990300][lv][1]
	self.time = _sk_config._skill_p[SKILL_OBJ_990300][lv][2]
end
--param.des_id
function Skill_990300:effect(sour_id, param)
	--print("Skill_990300:effect(sour_id, param)")
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
	
	local ret = obj_d:on_beskill(self.id, obj_s)
	if ret == 2 then
		local impact_o = Impact_1451(sour_id, self:get_level())

		param.per = self.per
		impact_o:set_sec_count(1)
		impact_o:set_count(self.time)
		impact_o:effect(param)

		debug_print("Skill_990300:effect", sour_id, param.des_id, self.ak)
		return 0
	elseif ret == 1 then
		self:send_syn(obj_s, param.des_id, nil, ret)
		return 0
	end
	return 21102
end

f_create_skill_class("SKILL_OBJ_9903%02d", "Skill_9903%02d")