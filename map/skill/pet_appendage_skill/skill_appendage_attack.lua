
require("skill.pet_appendage_skill.pet_appendage_skill")
local _random = crypto.random


--冷静 有概率减少目标8/15/25点怒气 {概率，怒气点}
Skill_770100 = oo.class(Skill_appendage, "Skill_770100")

function Skill_770100:on_effect(param)
	--print("Skill_770100:on_effect()")
	local obj_s = param.obj_s
	local obj_d = param.obj_d
	local param = param.param
	if obj_d:get_type() ~= OBJ_TYPE_HUMAN then
		return 0
	end
	local obj_d_id = obj_d:get_id()
	if obj_d:check_occ_levelup() ~= nil then
		obj_d:sub_rage(param[2])
	end

	self:send_syn(obj_s, obj_d_id, nil, 2)
	return 0
end
f_skill_appendage_attack_builder(SKILL_OBJ_770100)

--奋进 有概率增加自己8/15/25点怒气 {概率，怒气点}
Skill_770200 = oo.class(Skill_appendage, "Skill_770200")

function Skill_770200:on_effect(param)
	--print("Skill_770200:on_effect()")
	local obj_s = param.obj_s
	local obj_d = param.obj_d
	local param = param.param
	if obj_d:get_type() ~= OBJ_TYPE_HUMAN then
		return 0
	end
	local obj_d_id = obj_d:get_id()
	if obj_s:check_occ_levelup() ~= nil then
		obj_s:add_rage(param[2])
	end
	self:send_syn(obj_s, obj_d_id, nil, 2)
	return 0
end
f_skill_appendage_attack_builder(SKILL_OBJ_770200)

--神灭阳炎 有概率释放群体伤害技能，造成人物法功*100%/150%/200%+1000/2000/3500的法功伤害{概率，系数，附加攻击}
Skill_770300 = oo.class(Skill_appendage, "Skill_770300")

function Skill_770300:on_effect(param)
	--print("Skill_770300:on_effect()")
	local obj_s = param.obj_s
	local obj_d = param.obj_d
	local param = param.param

	local sour_id = obj_s:get_id()
	local des_id = obj_d:get_id()
	local scene_o = obj_s:get_scene_obj()
	local md_ret = scene_o:is_attack(sour_id, des_id)
	if md_ret ~= 0 then
		return nil
	end

	self:send_syn(obj_s, des_id, nil, 2)  --技能同步
	local map_obj = scene_o:get_map_obj()
	local obj_list = map_obj:scan_obj_rect(obj_s:get_pos(), 12, nil, 6)
	obj_list[sour_id] = nil

	local a_type = 2
	for k,v in pairs(obj_list) do
		local obj_o = g_obj_mgr:get_obj(k)
		if obj_o ~= nil and scene_o:is_attack(sour_id, k) == 0 then
			--local ret = obj_o:on_beskill(self.id, obj_s)
			--if ret == 2 then
				local new_pkt = self:make_hp_pkt(obj_s, obj_o, param[3], a_type)
				if obj_o:on_damage(new_pkt.hp, obj_s, self.id) then
					--self:send_syn(obj_s, k, new_pkt, ret)
				end
			--end
		end
	end

	return 0
end
f_skill_appendage_attack_builder(SKILL_OBJ_770300)

--邪皇杀阵 有概率释放群体伤害技能，造成人物法功*100%/150%/200%+1000/2000/3500的物功伤害{概率，系数，附加攻击}
Skill_770400 = oo.class(Skill_appendage, "Skill_770400")

function Skill_770400:on_effect(param)
	--print("Skill_770400:on_effect()")
	local obj_s = param.obj_s
	local obj_d = param.obj_d
	local param = param.param

	local sour_id = obj_s:get_id()
	local des_id = obj_d:get_id()
	local scene_o = obj_s:get_scene_obj()
	local md_ret = scene_o:is_attack(sour_id, des_id)
	if md_ret ~= 0 then
		return nil
	end

	self:send_syn(obj_s, des_id, nil, 2)  --技能同步
	local map_obj = scene_o:get_map_obj()
	local obj_list = map_obj:scan_obj_rect(obj_s:get_pos(), 12, nil, 6)
	obj_list[sour_id] = nil

	local a_type = 1
	for k,v in pairs(obj_list) do
		local obj_o = g_obj_mgr:get_obj(k)
		if obj_o ~= nil and scene_o:is_attack(sour_id, k) == 0 then
			--local ret = obj_o:on_beskill(self.id, obj_s)
			--if ret == 2 then
				local new_pkt = self:make_hp_pkt(obj_s, obj_o, param[3], a_type)
				if obj_o:on_damage(new_pkt.hp, obj_s, self.id) then
					--self:send_syn(obj_s, k, new_pkt, ret)
				end
			--end
		end
	end

	return 0
end
f_skill_appendage_attack_builder(SKILL_OBJ_770400)

--天霜斩 有概率释放单体伤害技能，造成人物根骨*100%/150%/200%+500/1000/1700的冰功伤害{概率，系数，附加值}
Skill_770500 = oo.class(Skill_appendage, "Skill_770500")

function Skill_770500:on_effect(param)
	--print("Skill_770500:on_effect()")
	local obj_s = param.obj_s
	local obj_d = param.obj_d
	local param = param.param
	local sour_id = obj_s:get_id()
	local des_id = obj_d:get_id()
	local factor = param[2]
	local damage_add = math.max(0, math.floor(obj_s:get_strengh_t() * factor + param[3] - obj_d:get_ice_de_t()))
	local new_pkt = self:make_hp_pkt_2(des_id, -damage_add)
	if obj_d:on_damage(new_pkt.hp, obj_s, self.id) then
		self:send_syn(obj_s, des_id, nil, 2)
	end
	
	return 0
end
f_skill_appendage_attack_builder(SKILL_OBJ_770500)

--轰雷闪 有概率释放单体伤害技能，造成人物悟性*100%/150%/200%+500/1000/1700的雷功伤害{概率，系数，附加值}
Skill_770600 = oo.class(Skill_appendage, "Skill_770600")

function Skill_770600:on_effect(param)
	--print("Skill_770600:on_effect()")
	local obj_s = param.obj_s
	local obj_d = param.obj_d
	local param = param.param
	local sour_id = obj_s:get_id()
	local des_id = obj_d:get_id()

	local factor = param[2]
	local damage_add = math.max(0, math.floor(obj_s:get_intelligence_t() * factor + param[3] - obj_d:get_fire_de_t()))
	local new_pkt = self:make_hp_pkt_2(des_id, -damage_add)
	if obj_d:on_damage(new_pkt.hp, obj_s, self.id) then
		self:send_syn(obj_s, des_id, nil, 2)
	end
	return 0
end
f_skill_appendage_attack_builder(SKILL_OBJ_770600)

--幻境风暴 有概率释放群体伤害技能，造成人物法功*系数的法功伤害，并且减少被怪攻击的概率{概率，系数，减小仇恨}
Skill_770700 = oo.class(Skill_appendage, "Skill_770700")

function Skill_770700:on_effect(param)
	--print("Skill_770700:on_effect()")
	local obj_s = param.obj_s
	local obj_d = param.obj_d
	local param = param.param

	local sour_id = obj_s:get_id()
	local des_id = obj_d:get_id()
	local scene_o = obj_s:get_scene_obj()
	local md_ret = scene_o:is_attack(sour_id, des_id)
	if md_ret ~= 0 then
		return nil
	end

	self:send_syn(obj_s, des_id, nil, 2)  --技能同步
	local map_obj = scene_o:get_map_obj()
	local obj_list = map_obj:scan_obj_rect(obj_s:get_pos(), 12, nil, 6)
	obj_list[sour_id] = nil

	local a_type = 2
	for k,v in pairs(obj_list) do
		local obj_o = g_obj_mgr:get_obj(k)
		if obj_o ~= nil and scene_o:is_attack(sour_id, k) == 0 then
			--local ret = obj_o:on_beskill(self.id, obj_s)
			--if ret == 2 then
				local new_pkt = self:make_hp_pkt(obj_s, obj_o, 0, a_type)
				if obj_o:on_damage(new_pkt.hp, obj_s, self.id) then
					--self:send_syn(obj_s, k, new_pkt, ret)
				end
			--end
		end
	end
	if obj_d:get_type() == OBJ_TYPE_MONSTER then
		obj_d:sub_percent_enemy(sour_id, param[3])
	end
	return 0
end
f_skill_appendage_attack_builder(SKILL_OBJ_770700)

--七伤拳 有概率释放群体伤害技能，造成人物物功*系数的物功伤害，并且减少被怪攻击的概率{概率，系数，减小仇恨}
Skill_770800 = oo.class(Skill_appendage, "Skill_770800")

function Skill_770800:on_effect(param)
	--print("Skill_770800:on_effect()")
	local obj_s = param.obj_s
	local obj_d = param.obj_d
	local param = param.param

	local sour_id = obj_s:get_id()
	local des_id = obj_d:get_id()
	local scene_o = obj_s:get_scene_obj()
	local md_ret = scene_o:is_attack(sour_id, des_id)
	if md_ret ~= 0 then
		return nil
	end

	self:send_syn(obj_s, des_id, nil, 2)  --技能同步
	local map_obj = scene_o:get_map_obj()
	local obj_list = map_obj:scan_obj_rect(obj_s:get_pos(), 12, nil, 6)
	obj_list[sour_id] = nil

	local a_type = 1
	for k,v in pairs(obj_list) do
		local obj_o = g_obj_mgr:get_obj(k)
		if obj_o ~= nil and scene_o:is_attack(sour_id, k) == 0 then
			--local ret = obj_o:on_beskill(self.id, obj_s)
			--if ret == 2 then
				local new_pkt = self:make_hp_pkt(obj_s, obj_o, 0, a_type)
				if obj_o:on_damage(new_pkt.hp, obj_s, self.id) then
					--self:send_syn(obj_s, k, new_pkt, ret)
				end
			--end
		end
	end
	if obj_d:get_type() == OBJ_TYPE_MONSTER then
		obj_d:sub_percent_enemy(sour_id, param[3])
	end
	return 0
end
f_skill_appendage_attack_builder(SKILL_OBJ_770800)