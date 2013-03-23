

require("config.pet_expr")
require("config.expr")

local _expr = require("config.expr")
local _pet_expr = require("config.pet_expr")
local _pet_exp = require("config.pet_config")
local pet_skill_config = require("config.loader.pet_combat_skill_load")
--buff技能:减物防、减法防、减物攻、减法攻、减命中、减闪避
local impact_buff_skill = {Impact_1427,Impact_1437,Impact_1407,Impact_1418,Impact_1816,Impact_1826}

--伤害类技能
BadSkill = oo.class(Skill_combat,"BadSkill")

function BadSkill:__init(skill_type, level)									--技能类ID, 技能等级
	level = level or 1
	Skill_combat.__init(self, skill_type + level, SKILL_BAD, skill_type, level)
	self.ak = pet_skill_config.skill_param[skill_type][level][2]			--攻击力
	self.ak_class = pet_skill_config.skill_config[skill_type][4]			--技能伤害类型
end

function BadSkill:effect(sour_id, param)
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

function BadSkill:do_effect(sour_id, param, obj_s, obj_d)
	--被使用技能，返回0，不能使用技能，1，可以使用技能，但不产生伤害， 2使用技能，产生伤害
	local ret = obj_d:on_beskill(self.id, obj_s)
	if ret == 2 then
		local new_pkt = self:make_hp_pkt(obj_s, obj_d, self.ak, self.ak_class)  --计算伤害
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

--obj_s:技能使用者
--obj_d:技能的目标
--ak:技能使用者的攻击力
--dg_type:技能伤害类型
function BadSkill:make_hp_pkt(obj_s, obj_d, ak, dg_type)
	local damage_pet_expr
	if dg_type == nil or dg_type == 1 then		--物理伤害
		damage_pet_expr = _pet_expr.pet_s_damage
	elseif dg_type == 2 then					--魔法伤害
		damage_pet_expr = _pet_expr.pet_m_damage
	elseif dg_type == 3 then 					--冰攻伤害
		damage_pet_expr = _pet_expr.pet_ice_damage
	elseif dg_type == 4 then					--雷攻伤害
		damage_pet_expr = _pet_expr.pet_fire_damage
	elseif dg_type == 5 then					--毒攻伤害
		damage_pet_expr = _pet_expr.pet_poison_damage
	end

	local new_pkt = {}
	--[[new_pkt.obj_id = obj_d:get_id()
	new_pkt.type = 0
	new_pkt.hp = 0
	new_pkt.mp = 0]]

	new_pkt[1] = 0
	new_pkt[2]= obj_d:get_id()
	new_pkt[3] = 0
	new_pkt[4] = 0

	if _expr.human_miss(obj_s, obj_d) then
		new_pkt[1] = 1
	else
		ak = math.floor(ak)
		new_pkt[3],new_pkt[1] = damage_pet_expr(obj_s, obj_d, ak, self.level, self.cmd_id)
	end

	new_pkt.hp = new_pkt[3]  --兼容老代码

	local addition_hp = 0
	--吸血被动技能
	local hp = obj_s:get_vampire_hp()
	if hp ~= 0 and hp ~= nil then
		addition_hp = hp *  (-new_pkt.hp)
	end

	if addition_hp ~= 0 then
		obj_s:add_hp(addition_hp)
	end

	return new_pkt,new_pkt[3]
end


--飞雪狂舞类
--物理攻击，攻击自身范围5*5格内所有目标，1次性伤害，对每个目标攻击力均为50
RangeBadSkill = oo.class(BadSkill,"RangeBadSkill")

function RangeBadSkill:__init(skill_type, level)		--技能类ID, 技能等级
	BadSkill.__init(self, skill_type, level)
	self.range = pet_skill_config.skill_param[skill_type][level][7]		--技能范围大小
end

function RangeBadSkill:effect(sour_id, param)
	local obj_s = g_obj_mgr:get_obj(sour_id)	--获取使用者对象
	if not obj_s then
		return 21101
	end

	local scene_o = obj_s:get_scene_obj();
	if not scene_o then
		print("RangeBadSkill:effect Error Not scene_o")
		return 21101
	end

	obj_s:on_useskill(self.id, nil, 0)
	self:send_syn(obj_s, obj_s:get_id(), nil, 2)  --技能同步

	return self:do_effect(obj_s, scene_o, self:get_range(obj_s, scene_o));
end

function RangeBadSkill:get_range(obj_s, scene_o)
	local map_obj = scene_o:get_map_obj()
	local obj_list = map_obj:scan_obj_rect(obj_s:get_pos(), self.range, nil, nil)
	obj_list[obj_s:get_id()] = nil
	return obj_list
end

function RangeBadSkill:do_effect(obj_s, scene_o, obj_list)
	local sour_id = obj_s:get_id();

	for k,v in pairs(obj_list) do
		local obj_o = g_obj_mgr:get_obj(k)
		if obj_o and scene_o:is_attack(sour_id, k) == 0 then
			--被使用技能，返回0，不能使用技能，1，可以使用技能，但不产生伤害， 2使用技能，产生伤害
			if obj_o:on_beskill(self.id, obj_s) == 2 then
				local new_pkt = self:make_hp_pkt(obj_s, obj_o, self.ak, self.ak_class)
				if obj_o:on_damage(new_pkt.hp, obj_s, self.id) then
					self:send_syn(obj_s, k, new_pkt, ret)
				end
			end
		end
	end

	return 0
end

--凛风冲击类
--物理攻击，对自身与选定目标之间扇形区域内的所有目标造成1次性伤害，攻击力为500，攻击距离为5
SectorBadSkill = oo.class(RangeBadSkill,"SectorBadSkill")

function SectorBadSkill:effect(sour_id, param)
	if param.des_id == nil or sour_id == param.des_id then
		return 21101
	end
	local obj_s = g_obj_mgr:get_obj(sour_id)	--获取使用者对象
	local obj_d = g_obj_mgr:get_obj(param.des_id)	--获取目标对象
	if not obj_s or not obj_d then
		return 21101
	end

	if not self:is_validate_dis(obj_s, obj_d) then	--判断是否在有效攻击距离
		return 21131
	end

	local scene_o = obj_s:get_scene_obj();
	if not scene_o then
		print("RangeBadSkill:effect Error Not scene_o")
		return 21101
	end

	local md_ret = scene_o:is_attack(sour_id, param.des_id)
	if md_ret ~= 0 then
		return md_ret
	end

	obj_s:on_useskill(self.id, nil, 0)

	return self:do_effect(obj_s, scene_o, self:get_range(obj_s, obj_d, scene_o));
end

function SectorBadSkill:get_range(obj_s, obj_d,scene_o)
	local map_obj = scene_o:get_map_obj()
	local obj_list = map_obj:scan_sector_rect(obj_s:get_pos(), obj_d:get_pos(), self.range, nil)
	obj_list[obj_s:get_id()] = nil
	return obj_list
end

--阳炎类
--物理攻击，对目标与选定目标周围之间区域内的所有目标造成1次性伤害
Exploded_around = oo.class(RangeBadSkill, "Exploded_around")

function Exploded_around:__init(skill_type, level)
	RangeBadSkill.__init(self, skill_type, level)
	self.range = pet_skill_config.skill_param[skill_type][level][7]		--技能范围大小
end

function Exploded_around:effect(sour_id, param)

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

	obj_s:on_useskill(self.id, nil, 0)
	self:send_syn(obj_s, param.des_id, nil, 2)

	return self:do_effect(obj_s, scene_o, self:get_range(obj_s, obj_d, scene_o))
end

function Exploded_around:get_range(obj_s, obj_d, scene_o)
	local map_obj = scene_o:get_map_obj()
	local obj_list = map_obj:scan_obj_rect(obj_d:get_pos(), self.range, nil, nil)
	obj_list[obj_s:get_id()] = nil
	return obj_list
end

--主动非伤害技能
--为主人宠物补血补篮技能

Skill_add_blood_magic = oo.class(Skill_combat,"Skill_add_blood_magic")

function Skill_add_blood_magic:__init(skill_type, level)
	level = level or 1
	Skill_combat.__init(self, skill_type + level, SKILL_BAD, skill_type, level)

	--skill_param格式:
	--1耗魔 2作用在人物{ 1生命hp:{加点数、根骨比率、悟性比率、体魄比率、身法比率} 2魔法mp:{加点数、根骨比率、悟性比率、体魄比率、身法比率} }
	--3作用在宠物{ 1生命hp:{加点数、根骨比率、悟性比率、体魄比率、身法比率} 2魔法mp:{加点数、根骨比率、悟性比率、体魄比率、身法比率} }
	self.man_param = pet_skill_config.skill_param[skill_type][level][2]
	self.pet_param = pet_skill_config.skill_param[skill_type][level][3]
end

function Skill_add_blood_magic:get_effect(skill_param,list)
	local temp = {}
	temp.strengh = skill_param[2] * list.strengh
	temp.intelligence = skill_param[3] * list.intelligence
	temp.stemina = skill_param[4] * list.stemina
	temp.dexterity = skill_param[5] * list.dexterity
	return (temp.strengh+temp.intelligence+temp.stemina+temp.dexterity + skill_param[1])
end

function Skill_add_blood_magic:effect(sour_id, param, owner_id)

	local obj_s = g_obj_mgr:get_obj(sour_id)		--获取技能宠物对象
	if obj_s == nil then
		return 21101
	end

	local player = g_obj_mgr:get_obj(owner_id)		--宠物的主人
	local pet_con = player:get_pet_con()

	local hu_ef_attr_hp,hu_ef_attr_mp,pet_ef_attr_hp,pet_ef_attr_hp
	--宠物属性:根骨、悟性、体魄、身法
	local list = {}
	list.strengh = obj_s:get_strengh_t()
	list.intelligence = obj_s:get_intelligence_t()
	list.stemina = obj_s:get_stemina_t()
	list.dexterity = obj_s:get_dexterity_t()

	--生效属性:1hp、2mp
	--human
	if self.man_param[1] ~= nil then		--hp
		hu_ef_attr_hp = self:get_effect(self.man_param[1],list)
		player:add_hp(hu_ef_attr_hp)
	end
	if self.man_param[2] ~= nil then		--mp
		hu_ef_attr_mp = self:get_effect(self.man_param[2],list)
		player:add_mp(hu_ef_attr_mp)
	end
	--pet
	if self.pet_param[1] ~= nil then		--hp
		pet_ef_attr_hp = self:get_effect(self.pet_param[1],list)
		obj_s:add_hp(pet_ef_attr_hp)
	end
	if self.pet_param[2] ~= nil then		--mp
		pet_ef_attr_mp = self:get_effect(self.pet_param[2],list)
		obj_s:add_mp(pet_ef_attr_mp)
	end

	return 0
end

--buff技能
Skill_pet_buff = oo.class(Skill_combat, "Skill_pet_buff")

function Skill_pet_buff:__init(skill_type, level)
	level = level or 1
	Skill_combat.__init(self, skill_type + level, SKILL_BAD, skill_type, level)

	self.buff_type = pet_skill_config.skill_config[skill_type].buff_type
	self.sec = pet_skill_config.skill_param[skill_type][level]["time"]
	self.per = -(pet_skill_config.skill_param[skill_type][level]["buff_ratio"][1])			
	self.val = -(pet_skill_config.skill_param[skill_type][level]["buff_point"][1])
	
	--print(">>>>>>>>>>>>>>>> skill_type,self.buff_type,self.sec,self.per,self.val:",skill_type,self.buff_type,self.sec,self.per,self.val)
end


function Skill_pet_buff:effect(sour_id, param)
	--print("Skill_pet_buff:",sour_id, j_e(param))

	if param.des_id == nil then return 21101 end
	local obj_s = g_obj_mgr:get_obj(sour_id)
	local obj_d = g_obj_mgr:get_obj(param.des_id)

	if obj_s == nil or obj_d == nil then return 21101 end
	if sour_id ~= param.des_id and not self:is_validate_dis(obj_s, obj_d) then return 21131 end

	local scene_o = obj_s:get_scene_obj()
	local md_ret = scene_o:is_attack(sour_id, param.des_id)
	if md_ret ~= 0 then
		return md_ret
	end

	local ret = obj_d:on_beskill(self.id, obj_s)
	if ret == 2 then
		--print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ self.buff_type:",self.buff_type)
		local Impact = impact_buff_skill[self.buff_type]
		local impact_o = Impact(param.des_id, self:get_level())
		impact_o:set_count(1)
		impact_o:set_sec_count(self.sec)
		local impact_con = obj_s:get_impact_con()
		param.per = self.per
		param.val = self.val
		--print("param.per,param.val,self.sec:",param.per,param.val,type(param.per),type(param.val),self.sec,type(self.sec))
		impact_o:effect(param)

		obj_s:on_useskill(self.id, obj_d, 0)
		self:send_syn(obj_s, param.des_id, nil, ret)
		return 0
	elseif ret == 1 then
		self:send_syn(obj_s, param.des_id, nil, ret)
		return 0
	end
	return 21102
end

--吸血攻击
Skill_vampire = oo.class(BadSkill, "Skill_vampire")

function Skill_vampire:__init(skill_type, level)
	BadSkill.__init(self, skill_type, level)
	self.level = level or 1

	self.enrich_ratio =  pet_skill_config.skill_param[skill_type][level][8]
	self.range = pet_skill_config.skill_param[skill_type][level][7]		--技能范围大小
end

function Skill_vampire:effect(sour_id, param)
	if param.des_id == nil then return 21101 end

	local obj_s = g_obj_mgr:get_obj(sour_id)
	local obj_d = g_obj_mgr:get_obj(param.des_id)

	if obj_s == nil or obj_d == nil then return 21101 end
	if sour_id ~= param.des_id and not self:is_validate_dis(obj_s, obj_d) then return 21131 end

	local scene_o = obj_s:get_scene_obj()
	local md_ret = scene_o:is_attack(sour_id, param.des_id)
	if md_ret ~= 0 then
		return md_ret
	end

	obj_s:on_useskill(self.id, nil, 0)
	self:send_syn(obj_s, param.des_id, nil, 2)

	return self:do_effect(obj_s, scene_o, self:get_range(obj_s, obj_d, scene_o))
end

function Skill_vampire:get_range(obj_s, obj_d, scene_o)
	if self.range > 0 then
		local map_obj = scene_o:get_map_obj()
		local obj_list = map_obj:scan_obj_rect(obj_d:get_pos(), self.range, nil, nil)
		obj_list[obj_s:get_id()] = nil
		return obj_list
	elseif self.range == 0 then
		local obj_list = {}
		obj_list[obj_d:get_id()] = 1
		return obj_list
	end
end

function Skill_vampire:do_effect(obj_s, scene_o, obj_list)
	local sour_id = obj_s:get_id();

	for k,v in pairs(obj_list) do
		local obj_o = g_obj_mgr:get_obj(k)
		if obj_o and scene_o:is_attack(sour_id, k) == 0 then
			--被使用技能，返回0，不能使用技能，1，可以使用技能，但不产生伤害， 2使用技能，产生伤害
			if obj_o:on_beskill(self.id, obj_s) == 2 then
				local new_pkt = self:make_hp_pkt(obj_s, obj_o, self.ak, self.ak_class)
				local hp = new_pkt.hp 
				obj_s:add_hp((-hp) * self.enrich_ratio)
				if obj_o:on_damage(hp, obj_s, self.id) then
					self:send_syn(obj_s, k, new_pkt, ret)
				end
			end
		end
	end

	return 0
end

--幻境风暴
Skill_indifferent = oo.class(RangeBadSkill, "Skill_indifferent")

function Skill_indifferent:__init(skill_type, level)
	RangeBadSkill.__init(self, skill_type, level)
	self.level = level or 1

	self.indifferent_ratio =  pet_skill_config.skill_param[skill_type][level][9]
	self.range = pet_skill_config.skill_param[skill_type][level][7]		--技能范围大小
end

function Skill_indifferent:effect(sour_id, param)
	if param.des_id == nil then return 21101 end

	local obj_s = g_obj_mgr:get_obj(sour_id)
	local obj_d = g_obj_mgr:get_obj(param.des_id)

	if obj_s == nil or obj_d == nil then return 21101 end
	if sour_id ~= param.des_id and not self:is_validate_dis(obj_s, obj_d) then return 21131 end

	local scene_o = obj_s:get_scene_obj()
	local md_ret = scene_o:is_attack(sour_id, param.des_id)
	if md_ret ~= 0 then
		return md_ret
	end

	obj_s:on_useskill(self.id, nil, 0)
	self:send_syn(obj_s, param.des_id, nil, 2)

	return self:do_effect(obj_s, scene_o, self:get_range(obj_s, obj_d, scene_o))
end

function Skill_indifferent:get_range(obj_s, obj_d, scene_o)
	if self.range > 0 then
		local map_obj = scene_o:get_map_obj()
		local obj_list = map_obj:scan_obj_rect(obj_d:get_pos(), self.range, nil, nil)
		obj_list[obj_s:get_id()] = nil
		return obj_list
	elseif self.range == 0 then
		local obj_list = {}
		obj_list[obj_d:get_id()] = 1
		return obj_list
	end
end

function Skill_indifferent:do_effect(obj_s, scene_o, obj_list)
	local sour_id = obj_s:get_id();

	for k,v in pairs(obj_list) do
		local obj_o = g_obj_mgr:get_obj(k)
		if obj_o and scene_o:is_attack(sour_id, k) == 0 then
			--被使用技能，返回0，不能使用技能，1，可以使用技能，但不产生伤害， 2使用技能，产生伤害
			if obj_o:on_beskill(self.id, obj_s) == 2 then
				local new_pkt = self:make_hp_pkt(obj_s, obj_o, self.ak, self.ak_class)
				local hp = new_pkt.hp 
				if obj_o:get_type() == OBJ_TYPE_MONSTER then
					obj_o:sub_percent_enemy(sour_id, self.indifferent_ratio)
				end
				if obj_o:on_damage(hp, obj_s, self.id) then
					self:send_syn(obj_s, k, new_pkt, ret)
				end
			end
		end
	end

	return 0
end

--七伤
Skill_qishang = oo.class(BadSkill, "Skill_qishang")

function Skill_qishang:__init(skill_type, level)
	BadSkill.__init(self, skill_type, level)
	self.damage_ex =  pet_skill_config.skill_param[skill_type][level][10]
	self.strengh_ex_ratio = pet_skill_config.skill_param[skill_type][level][11]
	self.intelligence_ex_ratio = pet_skill_config.skill_param[skill_type][level][12]
	self.stemina_ex_ratio = pet_skill_config.skill_param[skill_type][level][13]
	self.dexterity_ex_ratio = pet_skill_config.skill_param[skill_type][level][14]
end

function Skill_qishang:do_effect(sour_id, param, obj_s, obj_d)
	--被使用技能，返回0，不能使用技能，1，可以使用技能，但不产生伤害， 2使用技能，产生伤害
	local ret = obj_d:on_beskill(self.id, obj_s)
	if ret == 2 then
		local new_pkt = self:make_hp_pkt(obj_s, obj_d, self.ak, self.ak_class)  --计算伤害
		--额外伤害 ：概率=（1.2-目标当前生命/目标最大生命）*50%   不受闪避影响
		local percent = math.floor((1.2 - obj_d:get_hp()/obj_d:get_max_hp()) * 0.5 * 100)
		local ex_hp = 0
		if percent <= math.random(1,100) then
			local strengh_ex = obj_s:get_strengh_t() * self.strengh_ex_ratio
			local intelligence_ex = obj_s:get_intelligence_t() * self.intelligence_ex_ratio
			local stemina_ex = obj_s:get_stemina_t() * self.stemina_ex_ratio
			local dexterity_ex = obj_s:get_dexterity_t() * self.dexterity_ex_ratio

			if strengh_ex ~= 0 then
				ex_hp = self.damage_ex + strengh_ex
			end

			if intelligence_ex ~= 0 then
				ex_hp = self.damage_ex + intelligence_ex
			end

			if stemina_ex ~= 0 then
				ex_hp = self.damage_ex + stemina_ex
			end

			if dexterity_ex ~= 0 then
				ex_hp = self.damage_ex + dexterity_ex
			end

			local pet_attack_param_l = _pet_exp.pet_attack_param[self.level]
			if self.ak_class == nil or self.ak_class == 1 then		--物理伤害
				ex_hp = pet_attack_param_l * ex_hp / obj_d:get_s_defense_t()
			elseif self.ak_class == 2 then					--魔法伤害
				ex_hp = pet_attack_param_l * ex_hp / obj_d:get_m_defense_t()
			elseif self.ak_class == 3 then 					--冰攻伤害
				
			elseif self.ak_class == 4 then					--雷攻伤害
				
			elseif self.ak_class == 5 then					--毒攻伤害
				
			end
		end
		if new_pkt[1] ~= 1 then
			new_pkt[3] = new_pkt.hp - ex_hp
			new_pkt.hp = new_pkt[3]
			obj_s:on_useskill(self.id, obj_d, new_pkt.hp)
			if obj_d:on_damage(new_pkt.hp, obj_s, self.id) then
				self:send_syn(obj_s, param.des_id, new_pkt, ret)
			end
		else
			if ex_hp ~= 0 then
				local p_new_pkt = {}
				p_new_pkt[1] = 0
				p_new_pkt[2]= obj_d:get_id()
				p_new_pkt[3] = - ex_hp
				p_new_pkt[4] = 0

				p_new_pkt.hp = - ex_hp
				obj_s:on_useskill(self.id, obj_d, p_new_pkt.hp)
				if obj_d:on_damage(p_new_pkt.hp, obj_s, self.id) then
					self:send_syn(obj_s, param.des_id, p_new_pkt, ret)
				end
			end
		end
		return 0
	elseif ret == 1 then
		self:send_syn(obj_s, param.des_id, nil, ret)
		return 0
	end

	return 21002
end

--万杀

Skill_wansha = oo.class(BadSkill, "Skill_wansha")

function Skill_wansha:__init(skill_type, level)
	BadSkill.__init(self, skill_type, level)
	self.impact_time = pet_skill_config.skill_param[skill_type][level]["impact_time"] or 0
end

function Skill_wansha:do_effect(sour_id, param, obj_s, obj_d)
	--被使用技能，返回0，不能使用技能，1，可以使用技能，但不产生伤害， 2使用技能，产生伤害
	local ret = obj_d:on_beskill(self.id, obj_s)
	if ret == 2 then
		local new_pkt = self:make_hp_pkt(obj_s, obj_d, self.ak, self.ak_class)  --计算伤害
		obj_s:on_useskill(self.id, obj_d, new_pkt.hp)
		if obj_d:on_damage(new_pkt.hp, obj_s, self.id) then
			self:send_syn(obj_s, param.des_id, new_pkt, ret)

			--定身效果			local impact_o = Impact_1211(obj_d:get_id())			if obj_d:on_beimpact(impact_o:get_cmd_id(), obj_s) == 1 then				impact_o:set_count(self.impact_time)				impact_o:effect()			else				impact_o:immune()			end
		end
		return 0
	elseif ret == 1 then
		self:send_syn(obj_s, param.des_id, nil, ret)
		return 0
	end

	return 21002
end

--影舞
Skill_yingwu = oo.class(BadSkill, "Skill_yingwu")

function Skill_yingwu:__init(skill_type, level)
	BadSkill.__init(self, skill_type, level)
	self.impact_time = pet_skill_config.skill_param[skill_type][level]["impact_time"] or 0
end

function Skill_yingwu:do_effect(sour_id, param, obj_s, obj_d)
	--被使用技能，返回0，不能使用技能，1，可以使用技能，但不产生伤害， 2使用技能，产生伤害
	local ret = obj_d:on_beskill(self.id, obj_s)
	if ret == 2 then
		local new_pkt = self:make_hp_pkt(obj_s, obj_d, self.ak, self.ak_class)  --计算伤害
		obj_s:on_useskill(self.id, obj_d, new_pkt.hp)
		if obj_d:on_damage(new_pkt.hp, obj_s, self.id) then
			self:send_syn(obj_s, param.des_id, new_pkt, ret)

			--定身效果			local impact_o = Impact_1211(obj_d:get_id())			if obj_d:on_beimpact(impact_o:get_cmd_id(), obj_s) == 1 then				impact_o:set_count(self.impact_time)				impact_o:effect()			else				impact_o:immune()			end
		end
		return 0
	elseif ret == 1 then
		self:send_syn(obj_s, param.des_id, nil, ret)
		return 0
	end

	return 21002
end



