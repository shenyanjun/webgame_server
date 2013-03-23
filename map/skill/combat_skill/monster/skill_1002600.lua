
local debug_print = function() end
local _expr = require("config.expr")
local _sk_config = require("config.skill_combat_config")
local _random = crypto.random

--召唤回血怪
Skill_1002600 = oo.class(Skill_combat, "Skill_1002600")

function Skill_1002600:__init(cmd_id, lv)
	Skill_combat.__init(self, cmd_id, SKILL_GOOD, SKILL_OBJ_1002600, lv)
	self.monster_id = _sk_config._skill_p[SKILL_OBJ_1002600][lv][2]
	self.monster_count = _sk_config._skill_p[SKILL_OBJ_1002600][lv][3]
	self.monster_time = _sk_config._skill_p[SKILL_OBJ_1002600][lv][4]
end
--param.des_id
function Skill_1002600:effect(sour_id, param)
	local obj_s = g_obj_mgr:get_obj(sour_id)
	if obj_s == nil then 
		return 21101 
	end
	
	local ret = obj_s:on_beskill(self.id, obj_s)
	if ret == 2 then
		--召唤
		local scene_d = obj_s:get_scene()
		local map_o = obj_s:get_scene_obj():get_map_obj()
		local cur_pos = obj_s:get_pos()
		local pos_m = {cur_pos[1]-5,cur_pos[1]+5,cur_pos[2]-5,cur_pos[2]+5}
		local m_param = {self.monster_time, sour_id}
		local attack_id = sour_id
		
		for i=1,self.monster_count do
			local pos = map_o:find_pos(pos_m)
			local obj = g_obj_mgr:create_monster(self.monster_id, pos, scene_d, m_param)
			g_scene_mgr_ex:enter_scene(obj)
			
			if attack_id ~= nil then
				obj:add_enemy_obj(attack_id, nil)
			end
		end

		obj_s:on_useskill(self.id, obj_s, hp)
		self:send_syn(obj_s, obj_s:get_id(), nil, ret)
		return 0
	elseif ret == 1 then
		self:send_syn(obj_s, obj_s:get_id(), nil, ret)
		return 0
	end
	return 21102
end

f_create_monster_skill_class("SKILL_OBJ_10026%02d", "Skill_10026%02d")