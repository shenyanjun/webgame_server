
local _sk_config = require("config.skill_combat_config")

local str = {}
str[1211] = "dingshen"
str[1451] = "jiasu"

--对自己
Skill_1004700 = oo.class(Skill_combat, "Skill_1004700")

function Skill_1004700:__init(cmd_id, lv)
	Skill_combat.__init(self, cmd_id, SKILL_BAD, SKILL_OBJ_1004700, lv)
	-- 范围
	self.buff_id = _sk_config._skill_p[SKILL_OBJ_1004700][lv][1]
	self.time 	= _sk_config._skill_p[SKILL_OBJ_1004700][lv][2]
	self.speed_a 	= _sk_config._skill_p[SKILL_OBJ_1004700][lv][3]

end
--param.des_id
function Skill_1004700:effect(sour_id, param)
	--print("Skill_1004700:effect()", sour_id, j_e(param))
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
	local map_obj = scene_o:get_map_obj()

	obj_s:on_useskill(self.id, nil, 0)
	self:send_syn(obj_s, obj_s:get_id(), nil, 2)  --技能同步
	
	local ret = obj_d:on_beskill(self.id, obj_s)
	if ret == 2 then
		local string = string.format("Impact_%d", self.buff_id)
		local impact_o = _G[string.format("Impact_%d", self.buff_id)](sour_id)
		if obj_s:on_beimpact(impact_o:get_cmd_id(), obj_s) == 1 then
			
			local p2 = {}
			p2.per = self.speed_a
			impact_o:set_sec_count(1)
			impact_o:set_count(self.time)
			--print("obj_s:on_beimpact(impact_o:get_cmd_id(), obj_s) ", str[self.buff_id])
			impact_o:effect(p2)
		end
	else
		self:send_syn(obj_s, obj_s:get_id(), nil, ret)
	end
				
	return 0
end


f_create_monster_skill_class("SKILL_OBJ_10047%02d", "Skill_10047%02d")


