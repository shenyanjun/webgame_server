

local _sk_config = require("config.skill_combat_config")
local _random = crypto.random

--黑洞
Skill_1003400 = oo.class(Skill_combat, "Skill_1003400")

function Skill_1003400:__init(cmd_id, lv)
	Skill_combat.__init(self, cmd_id, SKILL_BAD, SKILL_OBJ_1003400, lv)
	
	self.pos = 			_sk_config._skill_p[SKILL_OBJ_1003400][lv][2]
	self.speed_per = 	_sk_config._skill_p[SKILL_OBJ_1003400][lv][3]       --减速百分比
	self.speed_time = 	_sk_config._skill_p[SKILL_OBJ_1003400][lv][4]       --减速时间
	self.monster_id = 	_sk_config._skill_p[SKILL_OBJ_1003400][lv][5]
	self.monster_time = _sk_config._skill_p[SKILL_OBJ_1003400][lv][6]
	self.bomb_skill = 	_sk_config._skill_p[SKILL_OBJ_1003400][lv][7]
end

--param.des_id
function Skill_1003400:effect(sour_id, param)
	if param.des_id == nil or sour_id == param.des_id then return 21101 end
	local obj_s = g_obj_mgr:get_obj(sour_id)
	local obj_d = g_obj_mgr:get_obj(param.des_id)
	if obj_s == nil or obj_d == nil then 
		return 21101 
	end
	if not self:is_validate_dis(obj_s, obj_d) then
		return 21131
	end
	
	local scene_o = obj_s:get_scene_obj()
	local md_ret = scene_o:is_attack(sour_id, param.des_id)
	if md_ret ~= 0 then
		return md_ret
	end
	if Obj_mgr.obj_type(param.des_id) == OBJ_TYPE_PET then
		local owner_id = obj_d:get_owner_id()
		obj_d = g_obj_mgr:get_obj(owner_id)
	end
	if obj_d == nil or Obj_mgr.obj_type(obj_d:get_id()) ~= OBJ_TYPE_HUMAN then
		return 21101
	end

	local team_id = obj_d:get_team()
	local team_obj = g_team_mgr:get_team_obj(team_id)
	local list
	if team_obj == nil then
		list = {}
		list[param.des_id] = 1
	else
		list = team_obj:get_team_l()
	end

	local ret = obj_d:on_beskill(self.id, obj_s)
	if ret == 2 then
		for k,_ in pairs(list) do
			local obj_p = g_obj_mgr:get_obj(k)
			if obj_p ~= nil and scene_o == obj_p:get_scene_obj() then
				scene_o:transport(obj_p, self.pos)
				self:send_syn(obj_s, k, nil, ret)
				--减速
				local impact_o = Impact_1311(k)
				if obj_d:on_beimpact(impact_o:get_cmd_id(), obj_s) == 1 then
					local p2 = {}
					p2.sp_per = self.speed_per

					impact_o:set_count(self.speed_time)
					impact_o:effect(p2)
				else
					impact_o:immune()
				end
				--召唤
				local scene_d = obj_s:get_scene()
				local m_param = {self.monster_time, sour_id, self.bomb_skill}
				local obj = g_obj_mgr:create_monster(self.monster_id, self.pos, scene_d, m_param)
				g_scene_mgr_ex:enter_scene(obj)

			end
		end
	end
	return 0
end

f_create_monster_skill_class("SKILL_OBJ_10034%02d", "Skill_10034%02d")