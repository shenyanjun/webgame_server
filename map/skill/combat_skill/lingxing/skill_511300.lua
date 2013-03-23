
--local debug_print = print
local debug_print = function() end
local _expr = require("config.expr")
local _sk_config = require("config.skill_combat_config")

--往生诀
Skill_511300 = oo.class(Skill_combat, "Skill_511300")

function Skill_511300:__init(cmd_id, lv)
	Skill_combat.__init(self, cmd_id, SKILL_GOOD, SKILL_OBJ_511300, lv)
end
--param.des_id
function Skill_511300:effect(sour_id, param)
	if param.des_id == nil or sour_id == param.des_id then return 21101 end
	local obj_s = g_obj_mgr:get_obj(sour_id)
	local obj_d = g_obj_mgr:get_obj(param.des_id)
	if obj_s == nil or obj_d == nil then 
		return 21101 
	end
	if sour_id ~= param.des_id and not self:is_validate_dis(obj_s, obj_d) then
		return 21131
	end

	--对怪无效
	if obj_d:get_type() ~= OBJ_TYPE_HUMAN then 
		return 21133
	end

	--对象在死亡状态
	if obj_d:is_alive() then
		return 21135
	end
	
	local ret = obj_d:on_beskill(self.id, obj_s)
	if ret == 2 then
		obj_d:set_relive_flag(true)
		obj_s:on_useskill(self.id, obj_d, hp)
		self:send_syn(obj_s, param.des_id, new_pkt, ret)
		return 0
	elseif ret == 1 then
		self:send_syn(obj_s, param.des_id, nil, ret)
		return 0
	end
	return 21102
end

f_create_skill_class("SKILL_OBJ_5113%02d", "Skill_5113%02d")
