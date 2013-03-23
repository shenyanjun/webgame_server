
--local debug_print = print
local debug_print = function() end
local _expr = require("config.expr")
local _sk_config = require("config.skill_combat_config")

--群体复活
Skill_513700 = oo.class(Skill_combat, "Skill_513700")

function Skill_513700:__init(cmd_id, lv)
	Skill_combat.__init(self, cmd_id, SKILL_GOOD, SKILL_OBJ_513700, lv)
	self.hp_per = _sk_config._skill_p[SKILL_OBJ_513700][lv][2]
	self.sec = _sk_config._skill_p[SKILL_OBJ_513700][lv][3]
	self.sec_timer = _sk_config._skill_p[SKILL_OBJ_513700][lv][4]
	debug_print("===>Skill_513700:__init(cmd_id, lv):", cmd_id, lv)
end

--param.des_id
function Skill_513700:effect(sour_id, param)
	debug_print("===>Skill_513700:effect")
	local obj_s = g_obj_mgr:get_obj(sour_id)
	if obj_s == nil then 
		return 21101 
	end

	local team_id = obj_s:get_team()
	local team_obj = g_team_mgr:get_team_obj(team_id)
	if team_obj == nil then return 21134 end
	
	local list = team_obj:get_team_l()

	obj_s:on_useskill(self.id, nil, 0)


	for k,_ in pairs(list or {}) do
		local obj_d = g_obj_mgr:get_obj(k)
		if k ~= sour_id and obj_d ~= nil then
			local ret = obj_d:on_beskill(self.id, obj_d)
			local impact_con = obj_d:get_impact_con()
			ret = impact_con:find_impact(4001) and 1 or 2
			if ret == 2 and obj_d:get_scene_obj() == obj_s:get_scene_obj() and self:is_validate_dis(obj_s, obj_d) then
				if not obj_d:is_alive() then
					obj_d:set_relive_flag(true)
					obj_d:relive(2, self.hp_per)
				end

				--无敌效果
				local impact_o = Impact_1271(k)
				impact_o:set_sec_count(self.sec)
				impact_o:effect(param)

				--计时效果
				local impact_o = Impact_4001(k)
				impact_o:set_sec_count(self.sec_timer)
				impact_o:effect(param)

				self:send_syn(obj_s, k, nil, ret)
			elseif ret == 1 then
				self:send_syn(obj_s, k, nil, ret)
			end
		end
	end
	return 0
end

f_create_skill_class("SKILL_OBJ_5137%02d", "Skill_5137%02d")
