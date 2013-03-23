

local _sk_config = require("config.skill_combat_config")
local _random = crypto.random

--牵引
Skill_1003900 = oo.class(Skill_combat, "Skill_1003900")

function Skill_1003900:__init(cmd_id, lv)
	Skill_combat.__init(self, cmd_id, SKILL_BAD, SKILL_OBJ_1003900, lv)
	
	self.pos = _sk_config._skill_p[SKILL_OBJ_1003900][lv][2]

end

--param.des_id
function Skill_1003900:effect(sour_id, param)
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
		local pos = self.pos or obj_s:get_pos()
		for k,_ in pairs(list) do
			local obj_p = g_obj_mgr:get_obj(k)
			if obj_p ~= nil and scene_o == obj_p:get_scene_obj() and self:is_validate_dis(obj_s, obj_p) then
				scene_o:transport(obj_p, pos)
				self:send_syn(obj_s, k, nil, ret)
			end
		end
	end
	return 0
end

f_create_monster_skill_class("SKILL_OBJ_10039%02d", "Skill_10039%02d")