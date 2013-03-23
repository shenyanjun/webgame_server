require("human_fight.magic_skill.magic_base_skill")
local _config = require("config.obj_config")

local _random = crypto.random

--法宝一 2伤害为等级*系数的冰攻伤害 {概率，系数}
Skill_882000 = oo.class(Magic_skill_damage_add, "Skill_882000")

function Skill_882000:on_effect(param)
	local obj_s = param.obj_s
	local obj_d = param.obj_d
	local factor = param.factor
	--self:send_syn(obj_s, obj_d:get_id(), nil, 2)
	local damage_add = math.max(0, math.floor(obj_s:get_level() * factor - obj_d:get_ice_de_t()))
	return {0, damage_add}
end
f_skill_magic_damage_add_builder(SKILL_OBJ_882000)


--法宝一 3伤害为等级*系数的毒攻伤害 {概率，系数}
Skill_882100 = oo.class(Magic_skill_damage_add, "Skill_882100")

function Skill_882100:on_effect(param)
	local obj_s = param.obj_s
	local obj_d = param.obj_d
	local factor = param.factor
	--self:send_syn(obj_s, obj_d:get_id(), nil, 2)
	local damage_add = math.max(0, math.floor(obj_s:get_level() * factor - obj_d:get_poison_de_t()))
	return {0, damage_add}
end
f_skill_magic_damage_add_builder(SKILL_OBJ_882100)

--法宝一 4伤害为等级*系数的毒攻伤害 {概率，系数}
Skill_882200 = oo.class(Magic_skill_damage_add, "Skill_882200")

function Skill_882200:on_effect(param)
	local obj_s = param.obj_s
	local obj_d = param.obj_d
	local factor = param.factor
	--self:send_syn(obj_s, obj_d:get_id(), nil, 2)
	local damage_add = math.max(0, math.floor(obj_s:get_level() * factor - obj_d:get_fire_de_t()))
	return {0, damage_add}
end
f_skill_magic_damage_add_builder(SKILL_OBJ_882200)

--法宝三 2施放破袭时附加根骨点数*系数的冰攻伤害,并且释放单体嘲讽(对玩家无效) {概率，系数}
Skill_882300 = oo.class(Magic_skill_damage_add, "Skill_882300")

function Skill_882300:on_effect(param)
	local obj_s = param.obj_s
	local obj_d = param.obj_d
	local factor = param.factor
	local damage_add = math.max(0, math.floor(obj_s:get_strengh_t() * factor - obj_d:get_ice_de_t()))
	return {0, damage_add}
end
f_skill_magic_damage_add_builder(SKILL_OBJ_882300)

--法宝三 3施放飞雪狂舞，可以附加根骨点数*系数的冰攻伤害 {概率，系数}
Skill_882400 = oo.class(Magic_skill_damage_add, "Skill_882400")

function Skill_882400:on_effect(param)
	local obj_s = param.obj_s
	local obj_d = param.obj_d
	local factor = param.factor
	local damage_add = math.max(0, math.floor(obj_s:get_strengh_t() * factor - obj_d:get_ice_de_t()))
	return {0, damage_add}
end
f_skill_magic_damage_add_builder(SKILL_OBJ_882400)

--法宝三 5普通攻击会附加额外的自身物攻*系数的物攻伤害 {概率，系数}
Skill_882500 = oo.class(Magic_skill_damage_add, "Skill_882500")

function Skill_882500:on_effect(param)
	local obj_s = param.obj_s
	local obj_d = param.obj_d
	local factor = param.factor
	local attack_min, attack_max = obj_s:get_s_attack_t()
	local attack = _random(attack_min, attack_max)
	local attack_p = _config._attack_param[obj_s:get_occ()][obj_s:get_level()]
	local damage_add = math.max(0, math.floor(attack * factor * (3-2*obj_s:get_hp()/obj_s:get_max_hp()) * attack_p / obj_d:get_s_defense_t()))
	return {0, damage_add}
end
f_skill_magic_damage_add_builder(SKILL_OBJ_882500)

--法宝三 2天雷破空可以附加悟性点数*系数的雷攻伤害 {概率，系数}
Skill_882600 = oo.class(Magic_skill_damage_add, "Skill_882600")

function Skill_882600:on_effect(param)
	local obj_s = param.obj_s
	local obj_d = param.obj_d
	local factor = param.factor
	local damage_add = math.max(0, math.floor(obj_s:get_intelligence_t() * factor - obj_d:get_fire_de_t()))
	return {0, damage_add}
end
f_skill_magic_damage_add_builder(SKILL_OBJ_882600)

--法宝三 4释放碎心决会附加自身法力值*系数的雷攻伤害 {概率，系数}
Skill_882700 = oo.class(Magic_skill_damage_add, "Skill_882700")

function Skill_882700:on_effect(param)
	local obj_s = param.obj_s
	local obj_d = param.obj_d
	local factor = param.factor
	local damage_add = math.max(0, math.floor(obj_s:get_mp() * factor - obj_d:get_fire_de_t()))
	return {0, damage_add}
end
f_skill_magic_damage_add_builder(SKILL_OBJ_882700)

--法宝三 2苍龙映月可以附加悟性点数*系数的毒攻伤害 {概率，系数}
Skill_882800 = oo.class(Magic_skill_damage_add, "Skill_882800")

function Skill_882800:on_effect(param)
	local obj_s = param.obj_s
	local obj_d = param.obj_d
	local factor = param.factor
	local damage_add = math.max(0, math.floor(obj_s:get_intelligence_t() * factor - obj_d:get_poison_de_t()))
	return {0, damage_add}
end
f_skill_magic_damage_add_builder(SKILL_OBJ_882800)

--法宝三 3逆水花澜攻击生命值高于50%的目标时，额外附加法攻*系数的法攻伤害 {概率，系数}
Skill_882900 = oo.class(Magic_skill_damage_add, "Skill_882900")

function Skill_882900:on_effect(param)
	local obj_s = param.obj_s
	local obj_d = param.obj_d
	local factor = param.factor
	if obj_d:get_hp() / obj_d:get_max_hp() < 0.5 then
		return {0, 0}
	end
	local attack_min, attack_max = obj_s:get_m_attack_t()
	local attack = _random(attack_min, attack_max)
	local attack_p = _config._attack_param[obj_s:get_occ()][obj_s:get_level()]
	local damage_add = math.max(0, math.floor(attack * factor * attack_p / obj_d:get_m_defense_t()))
	return {0, damage_add}
end
f_skill_magic_damage_add_builder(SKILL_OBJ_882900)

--法宝八 2使用破袭的时候减少x%的生命，造成所减少生命*系数的伤害，血量少于30%时无效 {概率，减少生命百分比，系数}
Skill_883000 = oo.class(Magic_skill_damage_add, "Skill_883000")

function Skill_883000:on_effect(param)
	local obj_s = param.obj_s
	local obj_d = param.obj_d
	if obj_d == nil or obj_s:get_hp() / obj_s:get_max_hp() < 0.3 then
		return {0, 0}
	end
	local factor = math.floor(param.factor * obj_s:get_hp())
	local damage_add = math.floor(param.trouble * factor)
	obj_s:del_hp(factor)
	return {0, damage_add}
end
f_skill_magic_damage_add_builder(SKILL_OBJ_883000)

--法宝八 4魔音摄魂攻击生命力低于50%的目标时，额外附加法攻*系数的伤害 {概率，系数}
Skill_883100 = oo.class(Magic_skill_damage_add, "Skill_883100")

function Skill_883100:on_effect(param)
	local obj_s = param.obj_s
	local obj_d = param.obj_d
	if obj_d:get_hp() / obj_d:get_max_hp() > 0.5 then
		return {0, 0}
	end
	local factor = param.factor
	local attack_min, attack_max = obj_s:get_m_attack_t()
	local attack = _random(attack_min, attack_max)
	local attack_p = _config._attack_param[obj_s:get_occ()][obj_s:get_level()]
	local damage_add = math.max(0, math.floor(attack * factor * attack_p / obj_d:get_m_defense_t()))
	return {0, damage_add}
end
f_skill_magic_damage_add_builder(SKILL_OBJ_883100)


