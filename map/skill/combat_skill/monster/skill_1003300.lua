
local debug_print = function() end
local _expr = require("config.expr")
local _sk_config = require("config.skill_combat_config")
local _ip = require("impact.impact_process")


--怪物对人加buff技能
Skill_1003300 = oo.class(Skill_combat, "Skill_1003300")

function Skill_1003300:__init(cmd_id, lv)
	local skill_type = SKILL_BAD
	if lv == 3 then
		skill_type = SKILL_GOOD
	end
	Skill_combat.__init(self, cmd_id, skill_type, SKILL_OBJ_1003300, lv)
	-- 范围
	self.buff_id = _sk_config._skill_p[SKILL_OBJ_1003300][lv][2]
	self.time 	= _sk_config._skill_p[SKILL_OBJ_1003300][lv][3]
	self.per 	= _sk_config._skill_p[SKILL_OBJ_1003300][lv][4]
	self.val 	= _sk_config._skill_p[SKILL_OBJ_1003300][lv][5]
	self.sec_att = _sk_config._skill_p[SKILL_OBJ_1003300][lv][6]

end
--param.des_id
function Skill_1003300:effect(sour_id, param)
	--print("Skill_1003300:effect()", sour_id, j_e(param))
	if param.des_id == nil or sour_id == nil then return 21101 end
	local obj_s = g_obj_mgr:get_obj(sour_id)
	local obj_d = g_obj_mgr:get_obj(param.des_id)
	if obj_s == nil or obj_d == nil then 
		return 21101
	end
	if self.sec_att then
		local obj_d2 = g_obj_mgr:get_obj(obj_s:get_enemy_id_x())
		if obj_d2 and self:is_validate_dis(obj_s, obj_d2) then
			obj_d = obj_d2
			param.des_id = obj_d2:get_id()
		end
	end
	if not self:is_validate_dis(obj_s, obj_d) then
		return 21131
	end
	
	if sour_id ~= param.des_id then 
		local scene_o = obj_s:get_scene_obj()
		local md_ret = scene_o:is_attack(sour_id, param.des_id)
		if md_ret ~= 0 then
			return md_ret
		end
	end

	local ret = obj_d:on_beskill(self.id, obj_s)
	if ret == 2 then
		obj_s:on_useskill(self.id, obj_d, 0)

		if _ip.impact_type(self.buff_id) == IMPACT_BUFF then
			f_add_buff_impact(obj_d, param.buff_id or self.buff_id, param.per or self.per, param.val or self.val, param.time or self.time)
		else
			local impact_o = _G[string.format("Impact_%d", self.buff_id)](param.des_id)
			if obj_d:on_beimpact(impact_o:get_cmd_id(), obj_s) == 1 then
				local p2 = {}
				p2.per = self.per
				p2.val = self.val
				impact_o:set_count(self.time / impact_o.sec_count)
				impact_o:effect(p2)
			end
		end
		self:send_syn(obj_s, param.des_id, nil, ret)
		return 0
	--elseif ret == 1 then
		--self:send_syn(obj_s, param.des_id, nil, ret)
		--return 0
	end
	return 21102
end


f_create_monster_skill_class("SKILL_OBJ_10033%02d", "Skill_10033%02d")


