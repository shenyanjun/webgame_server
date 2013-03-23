
require("skill.magic_skill.magic_base_skill")
local _random = crypto.random

--法宝四 骨灵幽冥火 被攻击时，产生吸血buff，有概率回复造成伤害1%~5%的生命力 {概率，回复百分比, 时间}
Skill_888000 = oo.class(Skill_magic, "Skill_888000")

function Skill_888000:on_effect(param)
	--print("Skill_888000:on_effect()")
	local obj_s = param.obj_s
	local obj_d = param.obj_d
	local param = param.param
	local r = _random(1, 100)
	if obj_d == nil or r > param[1] then
		return nil
	end
	local obj_d_id = obj_d:get_id()
	local impact_o = Impact_1251(obj_d_id)
	impact_o:set_count(param[3])
	impact_o:effect({dg_per = param[2]})
	self:send_syn(obj_d, obj_d_id, nil, 2)

	return 0
end
f_skill_magic_be_attack_builder(SKILL_OBJ_888000)

--法宝五 2受到伤害时有概率提升100~2000点物防、法防持续10秒 {概率，提升值, 时间}
Skill_888100 = oo.class(Skill_magic, "Skill_888100")

function Skill_888100:on_effect(param)
	--print("Skill_888100:on_effect()")
	local obj_s = param.obj_s
	local obj_d = param.obj_d
	local param = param.param
	local r = _random(1, 100)
	if obj_d == nil or r > param[1] then
		return nil
	end
	local obj_d_id = obj_d:get_id()
	local impact_o = Impact_4057(obj_d_id, self.level)
	impact_o:set_count(param[3])
	impact_o:effect({per = 0, val = param[2]})
	self:send_syn(obj_d, obj_d_id, nil, 2)

	return 0
end
f_skill_magic_be_attack_builder(SKILL_OBJ_888100)

--法宝五 3受到伤害时有概率提升100~2000点物攻、法攻持续10秒 {概率，提升值, 时间}
Skill_888200 = oo.class(Skill_magic, "Skill_888200")

function Skill_888200:on_effect(param)
	--print("Skill_888100:on_effect()")
	local obj_s = param.obj_s
	local obj_d = param.obj_d
	local param = param.param
	local r = _random(1, 100)
	if obj_d == nil or r > param[1] then
		return nil
	end
	local obj_d_id = obj_d:get_id()
	local impact_o = Impact_4058(obj_d_id, self.level)
	impact_o:set_count(param[3])
	impact_o:effect({per = 0, val = param[2]})
	self:send_syn(obj_d, obj_d_id, nil, 2)

	return 0
end
f_skill_magic_be_attack_builder(SKILL_OBJ_888200)

--法宝五 4受到攻击时候有概率触发伤害反弹。反弹造成伤害30%~60%的伤害，持续5秒。冷却30秒 {概率，反弹百分比, 时间}
Skill_888300 = oo.class(Skill_magic, "Skill_888300")

function Skill_888300:on_effect(param)
	--print("Skill_888100:on_effect()")
	local obj_s = param.obj_s
	local obj_d = param.obj_d
	local param = param.param
	local r = _random(1, 100)
	if obj_d == nil or r > param[1] then
		return nil
	end
	local obj_d_id = obj_d:get_id()
	local impact_o = Impact_1521(obj_d_id)
	impact_o:set_count(param[3])
	impact_o:effect({per = param[2], val = 0})
	self:send_syn(obj_d, obj_d_id, nil, 2)

	return 0
end
f_skill_magic_be_attack_builder(SKILL_OBJ_888300)

--法宝六 3受到伤害时有1%~5%的概率回复100~1000点生命值 {概率，回复生命值}
Skill_888400 = oo.class(Skill_magic, "Skill_888400")

function Skill_888400:on_effect(param)
	--print("Skill_888400:on_effect()")
	local obj_s = param.obj_s
	local obj_d = param.obj_d
	local param = param.param
	local r = _random(1, 100)
	if obj_d == nil or r > param[1] then
		return nil
	end
	
	obj_d:add_hp(param[2])
	--self:send_syn(obj_d, obj_d_id, nil, 2)

	return 0
end
f_skill_magic_be_attack_builder(SKILL_OBJ_888400)