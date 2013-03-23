
local debug_print = function () end
local _sk_config = require("config.skill_combat_config")


--回城技能
Skill_91001 = oo.class(Skill_combat,"Skill_91001")

function Skill_91001:__init()
	Skill_combat.__init(self, SKILL_OBJ_91001, SKILL_GOOD, SKILL_OBJ_91000, 1)
end

function Skill_91001:effect(sour_id, param)
	local obj_s = g_obj_mgr:get_obj(sour_id)
	if obj_s == nil then
		return 21101
	end

	local ret = obj_s:is_carry()
	if ret ~= 0 then
		return ret
	end

	local ret = obj_s:on_beskill(self.id, obj_s)
	if ret == 2 then
		obj_s:on_useskill(self.id, obj_s, 0)
		self:send_syn(obj_s, nil, nil, ret)

		g_scene_mgr_ex:convey_to_relive(obj_s)

		return 0
	elseif ret == 1 then
		self:send_syn(obj_s, nil, nil, ret)
		return 0
	end
	return 21002
end



--基本攻击
Skill_base_attack = oo.class(Skill_combat,"Skill_base_attack")

function Skill_base_attack:__init(skill_id, skill_cmd, attack_type)		--技能类ID, 技能等级
	Skill_combat.__init(self, skill_id, SKILL_BAD, skill_cmd, 1)
	self.ak = _sk_config._skill_p[skill_cmd][1][2]
	self.attack_type = attack_type
end

function Skill_base_attack:effect(sour_id, param)
	--判断目标是否存在
	if param.des_id == nil or sour_id == param.des_id then
		return 21101
	end
	local obj_s = g_obj_mgr:get_obj(sour_id)			--获取技能使用者
	local obj_d = g_obj_mgr:get_obj(param.des_id)		--获取技能的目标
	if obj_s == nil or obj_d == nil then
		return 21101
	end

	--判断是否在技能的有效范围内
	if not self:is_validate_dis(obj_s, obj_d) then
		return 21131
	end

	--判断该场景下是否能进行攻击
	local scene_o = obj_s:get_scene_obj()
	local md_ret = scene_o:is_attack(sour_id, param.des_id)
	if md_ret ~= 0 then
		return md_ret
	end

	return self:do_effect(sour_id, param, obj_s, obj_d)
end

function Skill_base_attack:do_effect(sour_id, param, obj_s, obj_d)
	--被使用技能，返回0，不能使用技能，1，可以使用技能，但不产生伤害， 2使用技能，产生伤害
	local ret = obj_d:on_beskill(self.id, obj_s)
	if ret == 2 then
		local new_pkt = self:make_hp_pkt(obj_s, obj_d, self.ak, self.attack_type)  --计算伤害
		obj_s:on_useskill(self.id, obj_d, new_pkt.hp)
		if obj_d:on_damage(new_pkt.hp, obj_s, self.id) then
			self:send_syn(obj_s, param.des_id, new_pkt, ret)
		end
		return 0
	elseif ret == 1 then
		self:send_syn(obj_s, param.des_id, nil, ret)
		return 0
	end

	return 21002
end

--生成基本攻击类
local _base_skill_l = {
[SKILL_OBJ_90001]={cmd=SKILL_OBJ_90000,attack_type=1},
[SKILL_OBJ_90101]={cmd=SKILL_OBJ_90100,attack_type=1},
[SKILL_OBJ_90201]={cmd=SKILL_OBJ_90200,attack_type=1},
[SKILL_OBJ_90301]={cmd=SKILL_OBJ_90300,attack_type=2},
[SKILL_OBJ_90401]={cmd=SKILL_OBJ_90400,attack_type=2},
}
local create_base_attack_skill = function()
	for sk_id,attr_l in pairs(_base_skill_l) do
		local str = string.format("Skill_%d", sk_id)
		_G[str] = oo.class(Skill_base_attack, str)
		_G[str].__init = function (self)
			Skill_base_attack.__init(self, sk_id, attr_l.cmd, attr_l.attack_type)
		end
	end
end

create_base_attack_skill()

