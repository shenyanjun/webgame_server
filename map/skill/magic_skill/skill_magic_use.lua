
require("skill.magic_skill.magic_base_skill")
local _random = crypto.random

--法宝一 5主动释放。提升100%~200%的物攻，法攻，冰攻、毒攻、雷攻、暴击。，减少自身60~30%的物防法防。持续15秒、冷却360秒
Skill_884100 = oo.class(Skill_magic, "Skill_884100")

function Skill_884100:on_effect(param)
	--print("Skill_884100:on_effect()")
	local obj_s = param.obj_s
	local obj_d = param.obj_d
	local param = param.param
	if obj_s == nil then
		return nil
	end
	local obj_s_id = obj_s:get_id()
	local impact_o = Impact_4059(obj_s_id)
	impact_o:set_count(param[3])
	impact_o:effect({per = param[1], val = -param[2]})
	self:send_syn(obj_s, obj_s_id, nil, 2)

	return 0
end
f_skill_magic_use_builder(SKILL_OBJ_884100)


--法宝三 5每3秒损失1500点法力值。同时法攻提升20%~40%。法力值不够后效果消失 {损失法力值，提升百分比，时间}
Skill_884200 = oo.class(Skill_magic, "Skill_884200")

function Skill_884200:on_effect(param)
	--print("Skill_884200:on_effect()")
	local obj_s = param.obj_s
	local obj_d = param.obj_d
	local param = param.param
	if obj_s == nil then
		return nil
	end
	if obj_s:get_mp() < param[1] then
		return 21115
	end
	local obj_s_id = obj_s:get_id()
	local impact_o = Impact_4060(obj_s_id)
	impact_o:set_count(math.floor(param[3]/3))
	impact_o:effect({per = param[2], val = param[1]})
	self:send_syn(obj_s, obj_s_id, nil, 2)

	return 0
end
f_skill_magic_use_builder(SKILL_OBJ_884200)


--法宝一 定身 造成物攻或法攻伤害.伤害等于物攻(法攻)*系数{系数，定身时间}
Skill_884300 = oo.class(Skill_magic, "Skill_884300")

function Skill_884300:on_effect(param)
	--print("Skill_884300:on_effect()")
	local obj_s = param.obj_s
	local obj_d = g_obj_mgr:get_obj(param.des_id)
	if obj_s == nil or obj_d == nil then 
		return 21101 
	end
	local sour_id = obj_s:get_id()
	local des_id = obj_d:get_id()
	if not self:is_validate_dis(obj_s, obj_d) then
		return 21131
	end
	
	local scene_o = obj_s:get_scene_obj()
	local md_ret = scene_o:is_attack(sour_id, des_id)
	if md_ret ~= 0 then
		return md_ret
	end
	local ret = obj_d:on_beskill(self.id, obj_s)
	if ret == 2 then
		local a_type = obj_s:get_occ() == 11 and 1 or 2
		local new_pkt = self:make_hp_pkt(obj_s, obj_d, a_type)
		obj_s:on_useskill(self.id, obj_d, new_pkt.hp)
		if obj_d:on_damage(new_pkt.hp, obj_s, self.id) then
			if obj_d:is_alive() and obj_d:on_beimpact(IMPACT_OBJ_1211, obj_s) == 1 then
				local per, val = 0, 0
				if obj_d:get_type() == OBJ_TYPE_HUMAN then
					per, val = obj_d:get_passive_effect(EXTRA_STOP_DE, nil)
				end
				local count_time = math.floor(param.param[2] - val)
				local impact_o = Impact_1211(des_id)
				impact_o:set_count(math.max(2, count_time))
				impact_o:effect()
			end
			self:send_syn(obj_s, des_id, new_pkt, ret)
		end
		return 0
	elseif ret == 1 then
		self:send_syn(obj_s, des_id, nil, ret)
		return 0
	end
	return 21002
end
f_skill_magic_use_builder(SKILL_OBJ_884300)


--法宝二 沉默 造成物攻或法攻伤害.伤害等于物攻(法攻)*系数{系数，沉默时间}
Skill_884400 = oo.class(Skill_magic, "Skill_884400")

function Skill_884400:on_effect(param)
	--print("Skill_884400:on_effect()")
	local obj_s = param.obj_s
	local obj_d = g_obj_mgr:get_obj(param.des_id)
	if obj_s == nil or obj_d == nil then 
		return 21101 
	end
	local sour_id = obj_s:get_id()
	local des_id = obj_d:get_id()
	if not self:is_validate_dis(obj_s, obj_d) then
		return 21131
	end
	
	local scene_o = obj_s:get_scene_obj()
	local md_ret = scene_o:is_attack(sour_id, des_id)
	if md_ret ~= 0 then
		return md_ret
	end
	local ret = obj_d:on_beskill(self.id, obj_s)
	if ret == 2 then
		local a_type = obj_s:get_occ() == 11 and 1 or 2
		local new_pkt = self:make_hp_pkt(obj_s, obj_d, a_type)
		obj_s:on_useskill(self.id, obj_d, new_pkt.hp)
		if obj_d:on_damage(new_pkt.hp, obj_s, self.id) then
			if obj_d:is_alive() and obj_d:on_beimpact(IMPACT_OBJ_1291, obj_s) == 1 then
				local per, val = 0, 0
				if obj_d:get_type() == OBJ_TYPE_HUMAN then
					per, val = obj_d:get_passive_effect(EXTRA_SILENCE_DE, nil)
				end
				local count_time = math.floor(param.param[2] - val)
				local impact_o = Impact_1291(des_id)
				impact_o:set_count(math.max(2, count_time))
				impact_o:effect()
			end
			self:send_syn(obj_s, des_id, new_pkt, ret)
		end
		return 0
	elseif ret == 1 then
		self:send_syn(obj_s, des_id, nil, ret)
		return 0
	end
	return 21002
end
f_skill_magic_use_builder(SKILL_OBJ_884400)