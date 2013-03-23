
--local debug_print = print
local debug_print = function() end
local _expr = require("config.expr")
local _sk_config = require("config.skill_combat_config")

--烟雨还魂
Skill_510300 = oo.class(Skill_combat, "Skill_510300")

function Skill_510300:__init(cmd_id, lv)
	Skill_combat.__init(self, cmd_id, SKILL_GOOD, SKILL_OBJ_510300, lv)
	self.hp = _sk_config._skill_p[SKILL_OBJ_510300][lv][2]
	self.dis = _sk_config._skill_p[SKILL_OBJ_510300][lv][3]
end
--param.des_id
function Skill_510300:effect(sour_id, param)
	local obj_s = g_obj_mgr:get_obj(sour_id)
	if obj_s == nil then 
		return 21101 
	end

	local team_id = obj_s:get_team()
	local team_obj = g_team_mgr:get_team_obj(team_id)
	--if team_obj == nil then return 21134 end
	
	local scene_o = obj_s:get_scene_obj()
	local map_obj = scene_o:get_map_obj()

	obj_s:on_useskill(self.id, nil, 0)
	--local hp = self.hp + obj_s:get_set_effect(SKILL_ADD_DOCTOR, SKILL_OBJ_510300)
	local set_l = obj_s:get_set_effect(SKILL_ADD_DOCTOR, SKILL_OBJ_510300)
	local hp = self.hp + set_l[1] + self.hp*set_l[2]
	hp = _expr.human_doctor(obj_s, nil, hp, self.id, self.level)

	--烟雨还魂增加治疗效果(法宝技能)
	local extra_per, extra_val = obj_s:get_passive_effect(EXTRA_DOCTOR_MAGIC, nil)
	hp = math.floor(hp * (1+extra_per) + extra_val)

	local list
	if team_obj == nil then
		list = {}
		list[sour_id] = 1
	else
		list = team_obj:get_team_l()
	end

	for k,_ in pairs(list) do
		local obj_d = g_obj_mgr:get_obj(k)
		if obj_d ~= nil and obj_d:get_scene_obj() == scene_o and map_obj:distance(obj_s:get_pos(), obj_d:get_pos()) < self.dis + 3 then
			local ret = obj_d:on_beskill(self.id, obj_s)
			if ret == 2 then
				--human
				local new_pkt = {}
				new_pkt.obj_id = k
				new_pkt.type = 0
				new_pkt.mp = 0
				if obj_d:get_type() == OBJ_TYPE_HUMAN and obj_d:get_occ() == OCC_JISI then
					local hp_per = math.floor(hp*0.7)
					obj_d:add_hp(hp_per)
					new_pkt.hp = hp_per
				else
					obj_d:add_hp(hp)
					new_pkt.hp = hp
				end
				self:send_syn(obj_s, k, new_pkt, ret)

				--pet
				local pet_con = obj_d:get_pet_con()
				local pet_obj = pet_con and pet_con:get_combat_pet()
				if pet_obj ~= nil then
					local new_pkt = {}
					new_pkt.obj_id = pet_obj:get_id()
					new_pkt.type = 0
					new_pkt.hp = hp
					new_pkt.mp = 0
					pet_obj:add_hp(hp)
					self:send_syn(obj_s, pet_obj:get_id(), new_pkt, ret)
				end
			elseif ret == 1 then
				self:send_syn(obj_s, k, nil, ret)
			end
		end
	end

	return 0
end

f_create_skill_class("SKILL_OBJ_5103%02d", "Skill_5103%02d")
