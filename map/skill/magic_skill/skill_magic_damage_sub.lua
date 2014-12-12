
require("skill.magic_skill.magic_base_skill")

--法宝五 5受到的所有伤害减少5%~15% {概率，减少伤害百份比}
Skill_883500 = oo.class(Skill_magic_damage_sub, "Skill_883500")

function Skill_883500:on_effect(param)
	--local obj_s = param.obj_s
	--local obj_d = param.obj_d
	local factor = param.factor
	return {factor, 0}
end
f_skill_magic_damage_sub_builder(SKILL_OBJ_883500)

--法宝八 3法力值少于20%时被攻击、所受伤害减少50% {概率，减少伤害百份比}
Skill_883600 = oo.class(Skill_magic_damage_sub, "Skill_883600")

function Skill_883600:on_effect(param)
	local obj_s = param.obj_s
	local obj_d = param.obj_d
	if obj_d:get_mp() / obj_d:get_max_mp() > 0.2 then
		return {0, 0}
	end
	local factor = param.factor
	return {factor, 0}
end
f_skill_magic_damage_sub_builder(SKILL_OBJ_883600)

--法宝八 5减少100~1000点的伤害，每点伤害由x点法力值抵消，魔法低于20%时无效 {概率，减伤害点数, 1点伤害抵几点法力}
Skill_883700 = oo.class(Skill_magic_damage_sub, "Skill_883700")

function Skill_883700:on_effect(param)
	local obj_s = param.obj_s
	local obj_d = param.obj_d
	if obj_d:get_mp() / obj_d:get_max_mp() < 0.2 then
		return {0, 0}
	end
	local factor = param.factor
	local trouble = param.trouble
	local sub_mp = math.floor(factor * trouble)
	obj_d:add_mp(-sub_mp)
	return {0, factor}
end
f_skill_magic_damage_sub_builder(SKILL_OBJ_883700)

