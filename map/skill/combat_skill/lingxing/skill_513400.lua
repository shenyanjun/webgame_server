
local _expr = require("config.expr")
local _sk_config = require("config.skill_combat_config")

--天灵印，增加物攻和魔攻
Skill_513400 = oo.class(Skill_combat, "Skill_513400")

function Skill_513400:__init(cmd_id, lv)
	Skill_combat.__init(self, cmd_id, SKILL_GOOD, SKILL_OBJ_513400, lv)
	
	self.sec = _sk_config._skill_p[SKILL_OBJ_513400][lv][2]
	self.per = _sk_config._skill_p[SKILL_OBJ_513400][lv][3]
end
--param nil
function Skill_513400:effect(sour_id, param)
	if param.des_id == nil then return 21101 end
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
	
	local ret = obj_d:on_beskill(self.id, obj_s)
	if ret == 2 then
		--物攻
		local impact_o = Impact_1401(param.des_id, self:get_level())
		impact_o:set_count(self.sec)  
		param.per = self.per
		impact_o:effect(param)
		
		--[[local impact_con = obj_s:get_impact_con()
		local impact_o_old = impact_con:find_impact(impact_o:get_cmd_id())
		local lv = impact_o_old and impact_o_old:get_level() or self:get_level()
		if lv <= self:get_level() then 
			param.per = self.per
			impact_o:effect(param)
		end]]

		--魔攻
		local impact_o = Impact_1411(param.des_id, self:get_level())
		impact_o:set_count(self.sec)  
		param.per = self.per
		impact_o:effect(param)
		
		--[[local impact_con = obj_s:get_impact_con()
		local impact_o_old = impact_con:find_impact(impact_o:get_cmd_id())
		local lv = impact_o_old and impact_o_old:get_level() or self:get_level()
		if lv <= self:get_level() then 
			param.per = self.per
			impact_o:effect(param)
		end]]

		obj_s:on_useskill(self.id, obj_d, 0)
		self:send_syn(obj_s, param.des_id, nil, ret)
		return 0
	elseif ret == 1 then
		self:send_syn(obj_s, param.des_id, nil, ret)
		return 0
	end
	return 21102
end

f_create_skill_class("SKILL_OBJ_5134%02d", "Skill_5134%02d")
