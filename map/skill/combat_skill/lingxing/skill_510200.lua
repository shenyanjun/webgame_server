
--local debug_print = print
local debug_print = function() end
local _expr = require("config.expr")
local _sk_config = require("config.skill_combat_config")

--花尘雨露
Skill_510200 = oo.class(Skill_combat, "Skill_510200")

function Skill_510200:__init(cmd_id, lv)
	Skill_combat.__init(self, cmd_id, SKILL_GOOD, SKILL_OBJ_510200, lv)
	self.hp = _sk_config._skill_p[SKILL_OBJ_510200][lv][2]
end
--param.des_id
function Skill_510200:effect(sour_id, param)
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
	if obj_d:get_type() ~= OBJ_TYPE_HUMAN and obj_d:get_type() ~= OBJ_TYPE_PET then 
		return 21133
	end

	--只对队友或自己有效
	local des_id = param.des_id
	if obj_d:get_type() == OBJ_TYPE_PET then
		des_id = obj_d:get_owner_id()
	end
	if sour_id ~= des_id then
		local team_id = obj_s:get_team()
		local team_obj = g_team_mgr:get_team_obj(team_id)
		local list = {}
		if team_obj == nil then
			list[sour_id] = 1
		else
			list = team_obj:get_team_l()
		end
		if list[des_id] == nil then
			param.des_id = sour_id
			obj_d = obj_s
		end
	end
	
	local ret = obj_d:on_beskill(self.id, obj_s)
	if ret == 2 then
		--local hp = self.hp + obj_d:get_set_effect(SKILL_ADD_DOCTOR, SKILL_OBJ_510200)
		local set_l = obj_s:get_set_effect(SKILL_ADD_DOCTOR, SKILL_OBJ_510200)
		local hp = self.hp + set_l[1] + self.hp*set_l[2]
		hp = _expr.human_doctor(obj_s, obj_d, hp, self.id, self.level)

		local new_pkt = {}
		new_pkt.obj_id = param.des_id
		new_pkt.type = 0
		new_pkt.hp = hp
		new_pkt.mp = 0

		if obj_d:get_type() == OBJ_TYPE_HUMAN and obj_d:get_occ() == OCC_JISI then
			obj_d:add_hp(math.floor(hp*0.6))
			new_pkt.hp = math.floor(hp*0.6)
		else
			obj_d:add_hp(hp)
		end
		obj_s:on_useskill(self.id, obj_d, hp)
		self:send_syn(obj_s, param.des_id, new_pkt, ret)
		debug_print("Skill_510200:effect", sour_id, param.des_id)
		return 0
	elseif ret == 1 then
		self:send_syn(obj_s, param.des_id, nil, ret)
		return 0
	end
	return 21102
end

f_create_skill_class("SKILL_OBJ_5102%02d", "Skill_5102%02d")
