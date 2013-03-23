
require("skill.magic_skill.magic_base_skill")
local _random = crypto.random

--法宝二 5攻击生命力少于50%的目标时，可以使自己暴击效果提高500~2000，持续10秒，冷却4秒
Skill_885100 = oo.class(Skill_magic, "Skill_885100")

function Skill_885100:on_effect(param)
	--print("Skill_885100:on_effect()")
	local obj_s = param.obj_s
	local obj_d = param.obj_d
	local param = param.param
	if obj_d == nil or obj_d:get_hp() / obj_d:get_max_hp() > 0.5 then
		return nil
	end
	local obj_s_id = obj_s:get_id()
	local impact_o = Impact_4051(obj_s_id, self.level)
	impact_o:set_count(param[2])
	impact_o:effect({per = 0, val = param[1]})
	self:send_syn(obj_s, obj_s_id, nil, 2)

	return 0
end
f_skill_magic_attack_builder(SKILL_OBJ_885100)

--法宝三 4施放修罗降世后。伤害减免效果增加10%~30 {减免效果百分比，时间}
Skill_885200 = oo.class(Skill_magic, "Skill_885200")

function Skill_885200:on_effect(param)
	--print("Skill_885200:on_effect()")
	local obj_s = param.obj_s
	local obj_d = param.obj_d
	local param = param.param
	if obj_s == nil then
		return nil
	end
	local obj_s_id = obj_s:get_id()
	local impact_o = Impact_4052(obj_s_id, self.level)
	impact_o:set_count(param[2])
	impact_o:effect({per = param[1], val = 0})
	self:send_syn(obj_s, obj_s_id, nil, 2)

	return 0
end
f_skill_magic_attack_builder(SKILL_OBJ_885200)

--法宝三 3释放地洞星沉会触发法攻50%~100%的一个阳炎形式的范围伤害 {伤害百分比}
Skill_885300 = oo.class(Skill_magic, "Skill_885300")

function Skill_885300:on_effect(param)
	--print("Skill_885200:on_effect()")
	local obj_s = param.obj_s
	local obj_d = param.obj_d
	local param = param.param
	if obj_d == nil or not obj_d:is_alive() then
		return nil
	end

	local sour_id = obj_s:get_id()
	local des_id = obj_d:get_id()
	local scene_o = obj_s:get_scene_obj()
	local md_ret = scene_o:is_attack(sour_id, des_id)
	if md_ret ~= 0 then
		return nil
	end

	self:send_syn(obj_s, des_id, nil, 2)  --技能同步
	local map_obj = scene_o:get_map_obj()
	local obj_list = map_obj:scan_obj_rect(obj_d:get_pos(), 4, nil, 6)
	obj_list[sour_id] = nil

	for k,v in pairs(obj_list) do
		local obj_o = g_obj_mgr:get_obj(k)
		if obj_o ~= nil and scene_o:is_attack(sour_id, k) == 0 then
			--local ret = obj_o:on_beskill(self.id, obj_s)
			--if ret == 2 then
				local new_pkt = self:make_hp_pkt(obj_s, obj_o, 0, 2)
				if obj_o:on_damage(new_pkt.hp, obj_s, self.id) then
					--self:send_syn(obj_s, k, new_pkt, ret)
					--self:send_syn_to_hp(0, obj_o, new_pkt.hp, 0)
				end
			--end
		end
	end

	return 0
end
f_skill_magic_attack_builder(SKILL_OBJ_885300)

--法宝三 4释放碎甲术时减少目标的物理防御 {伤害百分比, 时间}
Skill_885400 = oo.class(Skill_magic, "Skill_885400")

function Skill_885400:on_effect(param)
	--print("Skill_885200:on_effect()")
	local obj_s = param.obj_s
	local obj_d = param.obj_d
	local param = param.param
	if obj_d == nil then
		return nil
	end
	local obj_d_id = obj_d:get_id()
	local impact_o = Impact_4053(obj_d_id, self.level)
	impact_o:set_count(param[2])
	impact_o:effect({per = -param[1], val = 0})
	--self:send_syn(obj_s, obj_s_id, nil, 2)

	return 0
end
f_skill_magic_attack_builder(SKILL_OBJ_885400)

--法宝三 5花尘雨露可以给目标施放buff，受到的伤害减少1%~10%。持续10秒 {伤害百分比, 时间}
Skill_885500 = oo.class(Skill_magic, "Skill_885500")

function Skill_885500:on_effect(param)
	--print("Skill_885200:on_effect()")
	local obj_s = param.obj_s
	local obj_d = param.obj_d
	local param = param.param
	if obj_d == nil or not obj_d:is_alive() then
		obj_d = obj_s
	end
	local obj_d_id = obj_d:get_id()
	local impact_o = Impact_4054(obj_d_id, self.level)
	impact_o:set_count(param[2])
	impact_o:effect({per = param[1], val = 0})
	self:send_syn(obj_s, obj_d_id, nil, 2)

	return 0
end
f_skill_magic_attack_builder(SKILL_OBJ_885500)

--法宝四 2攻击中有概率降低对手1~30%的物攻、法攻，持续3秒。冷却10秒 {概率, 减攻百分比, 时间}
Skill_885600 = oo.class(Skill_magic, "Skill_885600")

function Skill_885600:on_effect(param)
	--print("Skill_885600:on_effect()")
	local obj_s = param.obj_s
	local obj_d = param.obj_d
	local param = param.param
	local r = _random(1, 100)
	if obj_d == nil or not obj_d:is_alive() or r > param[1] then
		return nil
	end
	local obj_d_id = obj_d:get_id()
	local impact_o = Impact_4055(obj_d_id, self.level)
	impact_o:set_count(param[3])
	impact_o:effect({per = -param[2], val = 0})
	self:send_syn(obj_s, obj_d_id, nil, 2)

	return 0
end
f_skill_magic_attack_builder(SKILL_OBJ_885600)

--法宝四 3攻击中有概率降低对手1~30%的物防、法防，持续3秒。冷却10秒 {概率, 减防百分比, 时间}
Skill_885700 = oo.class(Skill_magic, "Skill_885700")

function Skill_885700:on_effect(param)
	--print("Skill_885700:on_effect()")
	local obj_s = param.obj_s
	local obj_d = param.obj_d
	local param = param.param
	local r = _random(1, 100)
	if obj_d == nil or not obj_d:is_alive() or r > param[1] then
		return nil
	end
	local obj_d_id = obj_d:get_id()
	local impact_o = Impact_4056(obj_d_id, self.level)
	impact_o:set_count(param[3])
	impact_o:effect({per = -param[2], val = 0})
	self:send_syn(obj_s, obj_d_id, nil, 2)

	return 0
end
f_skill_magic_attack_builder(SKILL_OBJ_885700)


--法宝四 5攻击中有概率对目标施放群攻技能，伤害为玩家物攻或法攻*50~100%的物攻或者法攻伤害。冷却10秒，耗蓝2000 {攻击系数, 概率}
Skill_885800 = oo.class(Skill_magic, "Skill_885800")

function Skill_885800:on_effect(param)
	--print("Skill_885800:on_effect()")
	local obj_s = param.obj_s
	local obj_d = param.obj_d
	local param = param.param
	local r = _random(1, 100)
	if obj_d == nil or not obj_d:is_alive() or r > param[2] then
		return nil
	end

	local sour_id = obj_s:get_id()
	local des_id = obj_d:get_id()
	local scene_o = obj_s:get_scene_obj()
	local md_ret = scene_o:is_attack(sour_id, des_id)
	if md_ret ~= 0 then
		return nil
	end

	self:send_syn(obj_s, des_id, nil, 2)  --技能同步
	local map_obj = scene_o:get_map_obj()
	local obj_list = map_obj:scan_obj_rect(obj_d:get_pos(), 12, nil, 12)
	obj_list[sour_id] = nil

	local a_type = obj_s:get_occ() == 11 and 1 or 2
	for k,v in pairs(obj_list) do
		local obj_o = g_obj_mgr:get_obj(k)
		if obj_o ~= nil and scene_o:is_attack(sour_id, k) == 0 then
			--local ret = obj_o:on_beskill(self.id, obj_s)
			--if ret == 2 then
				local new_pkt = self:make_hp_pkt(obj_s, obj_o, 0, a_type)
				if obj_o:on_damage(new_pkt.hp, obj_s, self.id) then
					--self:send_syn(obj_s, k, new_pkt, ret)
					--self:send_syn_to_hp(0, obj_o, new_pkt.hp, 0)
				end
			--end
		end
	end

	return 0
end
f_skill_magic_attack_builder(SKILL_OBJ_885800)

--法宝六 4对目标造成伤害为玩家物攻或法攻*50~100%的物攻或者法攻伤害,有10%的概率让目标沉默3秒 {攻击系数, 概率}
Skill_885900 = oo.class(Skill_magic, "Skill_885900")

function Skill_885900:on_effect(param)
	--print("Skill_885900:on_effect()")
	local obj_s = param.obj_s
	local obj_d = param.obj_d
	local param = param.param
	local r = _random(1, 100)
	if obj_d == nil or not obj_d:is_alive() or r > param[2] then
		return nil
	end
	
	local a_type = obj_s:get_occ() == 11 and 1 or 2
	local new_pkt = self:make_hp_pkt(obj_s, obj_d, 0, a_type)
	if obj_o:on_damage(new_pkt.hp, obj_s, self.id) then
		self:send_syn(obj_s, obj_d:get_id(), new_pkt, 2)
	end

	local obj_d_id = obj_d:get_id()
	local impact_o = Impact_1291(obj_d_id)
	impact_o:set_count(param[3])
	impact_o:effect({})

	return 0
end
f_skill_magic_attack_builder(SKILL_OBJ_885900)

--法宝六 5攻击中有2%概率对目标施单体攻击技能，伤害为玩家物攻或法攻*50~100%的物攻或者法攻伤害。同时回复伤害100%的生命值冷却10秒，耗蓝1000 {攻击系数, 概率}
Skill_886000 = oo.class(Skill_magic, "Skill_886000")

function Skill_886000:on_effect(param)
	--print("Skill_886000:on_effect()")
	local obj_s = param.obj_s
	local obj_d = param.obj_d
	local param = param.param
	local r = _random(1, 100)
	if obj_d == nil or not obj_d:is_alive() or r > param[2] then
		return nil
	end
	
	local a_type = obj_s:get_occ() == 11 and 1 or 2
	local new_pkt = self:make_hp_pkt(obj_s, obj_d, 0, a_type)
	if obj_o:on_damage(new_pkt.hp, obj_s, self.id) then
		self:send_syn(obj_s, obj_d:get_id(), new_pkt, 2)
	end
	obj_s:add_hp(new_pkt.hp)

	return 0
end
f_skill_magic_attack_builder(SKILL_OBJ_886000)

--法宝八 3夺魂怒号可以降低周围的攻击力5%~15%。持续5秒 {降低百分比，时间}
Skill_886200 = oo.class(Skill_magic, "Skill_886200")

function Skill_886200:on_effect(param)
	--print("Skill_886200:on_effect()")
	local obj_s = param.obj_s
	local param = param.param
	
	local sour_id = obj_s:get_id()
	local scene_o = obj_s:get_scene_obj()
	local map_obj = scene_o:get_map_obj()
	local obj_list = map_obj:scan_obj_rect(obj_s:get_pos(), 10, nil, 12)
	obj_list[sour_id] = nil

	self:send_syn(obj_s, sour_id, nil, 2)  --技能同步
	for k,v in pairs(obj_list) do
		local obj_o = g_obj_mgr:get_obj(k)
		if obj_o ~= nil and scene_o:is_attack(sour_id, k) == 0 then
			local impact_o = Impact_4061(k, self.level)
			impact_o:set_count(param[2])
			impact_o:effect({per = -param[1], val = 0})
			--self:send_syn(obj_s, k, nil, 2)  --技能同步
		end
	end

	return 0
end
f_skill_magic_attack_builder(SKILL_OBJ_886200)

--法宝八 4飞雪狂舞可以减少目标200~2000点冰抗。持续5秒 {减抗值，时间}
Skill_886300 = oo.class(Skill_magic, "Skill_886300")

function Skill_886300:on_effect(param)
	--print("Skill_886300:on_effect()")
	local obj_s = param.obj_s
	local param = param.param

	local sour_id = obj_s:get_id()
	local scene_o = obj_s:get_scene_obj()
	local map_obj = scene_o:get_map_obj()
	local obj_list = map_obj:scan_obj_rect(obj_s:get_pos(), 10, nil, 12)
	obj_list[sour_id] = nil

	self:send_syn(obj_s, sour_id, nil, 2)  --技能同步
	for k,v in pairs(obj_list) do
		local obj_o = g_obj_mgr:get_obj(k)
		if obj_o ~= nil and scene_o:is_attack(sour_id, k) == 0 then
			local impact_o = Impact_4062(k, self.level)
			impact_o:set_count(param[2])
			impact_o:effect({per = 0, val = -param[1]})
			--self:send_syn(obj_s, k, nil, 2)  --技能同步
		end
	end

	return 0
end
f_skill_magic_attack_builder(SKILL_OBJ_886300)

--法宝八 5释放风驰电骋时闪避提高200~2000。持续5秒。冷却30秒 {提高闪避值，时间}
Skill_886400 = oo.class(Skill_magic, "Skill_886400")

function Skill_886400:on_effect(param)
	--print("Skill_886400:on_effect()")
	local obj_s = param.obj_s
	local param = param.param

	local impact_o = Impact_4063(obj_s:get_id(), self.level)
	impact_o:set_count(param[2])
	impact_o:effect({per = 0, val = param[1]})
	self:send_syn(obj_s, obj_s:get_id(), nil, 2)  --技能同步

	return 0
end
f_skill_magic_attack_builder(SKILL_OBJ_886400)

--法宝八 2释放碎心决可以减少目标的法力值，同时回复自身的法力值 {减小目标值，回复自身值}
Skill_886500 = oo.class(Skill_magic, "Skill_886500")

function Skill_886500:on_effect(param)
	--print("Skill_886500:on_effect()")
	local obj_s = param.obj_s
	local obj_d = param.obj_d
	local param = param.param
	if obj_d == nil or not obj_d:is_alive() then
		return nil
	end
	obj_d:add_mp(-param[1])
	obj_s:add_mp(param[2])
	return 0
end
f_skill_magic_attack_builder(SKILL_OBJ_886500)

--法宝八 4释放天雷破空会减少目标200~2000点雷抗 {减雷抗值，时间}
Skill_886600 = oo.class(Skill_magic, "Skill_886600")

function Skill_886600:on_effect(param)
	--print("Skill_886600:on_effect()")
	local obj_s = param.obj_s
	local obj_d = param.obj_d
	local param = param.param
	if obj_d == nil or not obj_d:is_alive() then
		return nil
	end

	local impact_o = Impact_4064(obj_d:get_id(), self.level)
	impact_o:set_count(param[2])
	impact_o:effect({per = 0, val = -param[1]})
	self:send_syn(obj_s, obj_d:get_id(), nil, 2)  --技能同步

	return 0
end
f_skill_magic_attack_builder(SKILL_OBJ_886600)

--法宝八 3苍龙映月可以减少目标200~2000点毒抗 {减毒抗值，时间}
Skill_886700 = oo.class(Skill_magic, "Skill_886700")

function Skill_886700:on_effect(param)
	--print("Skill_886700:on_effect()")
	local obj_s = param.obj_s
	local obj_d = param.obj_d
	local param = param.param
	if obj_d == nil or not obj_d:is_alive() then
		return nil
	end

	local impact_o = Impact_4065(obj_d:get_id(), self.level)
	impact_o:set_count(param[2])
	impact_o:effect({per = 0, val = -param[1]})
	self:send_syn(obj_s, obj_d:get_id(), nil, 2)  --技能同步

	return 0
end
f_skill_magic_attack_builder(SKILL_OBJ_886700)