
local _expr = require("config.expr")
local _sk_config = require("config.skill_combat_config")

--金刚之躯，增加物防
Skill_110600 = oo.class(Skill_combat, "Skill_110600")

function Skill_110600:__init(cmd_id, lv)
	Skill_combat.__init(self, cmd_id, SKILL_GOOD, SKILL_OBJ_110600, lv)
	
	self.sec = _sk_config._skill_p[SKILL_OBJ_110600][lv][2] 
	self.per = _sk_config._skill_p[SKILL_OBJ_110600][lv][3] 
	self.dis = _sk_config._skill_p[SKILL_OBJ_110600][lv][4]
end
--param nil
function Skill_110600:effect(sour_id, param)
	local obj_s = g_obj_mgr:get_obj(sour_id)
	if obj_s == nil then 
		return 21101 
	end

	--获取组成员
	local team_obj = g_team_mgr:get_team_obj(obj_s:get_team())
	local list
	if team_obj == nil then
		list = {}
		list[sour_id] = 1
	else
		list = team_obj:get_team_l()
	end

	obj_s:on_useskill(self.id, nil, 0)
	--增加buff
	local scene_o = obj_s:get_scene_obj()
	local map_obj = scene_o:get_map_obj()
	for k,_ in pairs(list) do
		local obj_d = g_obj_mgr:get_obj(k)
		if obj_d ~= nil and map_obj:distance(obj_s:get_pos(), obj_d:get_pos()) < self.dis + 3 then
			local ret = obj_d:on_beskill(self.id, obj_s)
			if ret == 2 then
				--物防效果
				local impact_o = Impact_1421(k, self:get_level())
				impact_o:set_count(self.sec)  
				param.per = self.per
				impact_o:effect(param)

				self:send_syn(obj_s, k, nil, ret)
			elseif ret == 1 then
				self:send_syn(obj_s, k, nil, ret)
			end
		end
	end

	return 0
end

f_create_skill_class("SKILL_OBJ_1106%02d", "Skill_1106%02d")
