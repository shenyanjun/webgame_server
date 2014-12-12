
local debug_print = function() end
local _sk_config = require("config.skill_combat_config")


--变羊(单个)
Skill_1003500 = oo.class(Skill_combat, "Skill_1003500")

function Skill_1003500:__init(cmd_id, lv)
	Skill_combat.__init(self, cmd_id, SKILL_BAD, SKILL_OBJ_1003500, lv)
	self.impact_id =_sk_config._skill_p[SKILL_OBJ_1003500][lv][2]	
	self.time = 	_sk_config._skill_p[SKILL_OBJ_1003500][lv][3]
	self.pattern = _sk_config._skill_p[SKILL_OBJ_1003500][lv][4]       --减速百分比

end

--param.des_id
function Skill_1003500:effect(sour_id, param)
	if param.des_id == nil or sour_id == nil then return 21101 end
	local obj_s = g_obj_mgr:get_obj(sour_id)
	local obj_d = g_obj_mgr:get_obj(param.des_id)
	if obj_s == nil or obj_d == nil then 
		return 21101 
	end
	if not self:is_validate_dis(obj_s, obj_d) then
		return 21131
	end
	
	local scene_o = obj_s:get_scene_obj()

	obj_s:on_useskill(self.id, nil, 0)
	self:send_syn(obj_s, sour_id, nil, 2)  --技能同步

	if scene_o:is_attack(sour_id, param.des_id) == 0 then
		local ret = obj_d:on_beskill(self.id, obj_d)
		if ret == 2 then
			--变形效果
			local impact_id = string.format("Impact_%d", self.impact_id)
			local impact_o = _G[impact_id](param.des_id)
			if obj_d:on_beimpact(impact_o:get_cmd_id(), obj_d) == 1 then
				param.metamorphosis = self.pattern
				impact_o:set_count(self.time)   
				impact_o:effect(param)
			else
				impact_o:immune()
			end
			self:send_syn(obj_s, param.des_id, nil, ret)
		elseif ret == 1 then
			self:send_syn(obj_s, param.des_id, nil, ret)
		end
	end

	return 0
end

f_create_monster_skill_class("SKILL_OBJ_10035%02d", "Skill_10035%02d")