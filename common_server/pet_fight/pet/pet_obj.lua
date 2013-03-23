


--1,物最小攻击，2物最大攻击，3物防，4魔最小攻击，5魔最大攻击，6魔防，
--7冰攻，8冰防，9火攻，10，火防，11毒攻，12毒防，
--13暴击，14暴击效率，15命中，16闪避
--17根骨，18悟性，19体魄，20身法 21生命 22法力 23速度      (24增加宠物自动回血的比例 25增加宠物自动回魔的比例)

local percent = 
{0,  --最小物理攻击
0,				 --最大物理攻击	
10,				 --物防
0,  				 --最小法术攻击
0,				 --最大法术攻击
10,				 --法防
5,					 --冰伤害
3,					 --冰抗性
5,					 --雷伤害
3,					 --雷抗性
5,					 --毒伤害
3,					 --毒抗性
5,					 --暴击
5,					 --暴击效果
5,					 --命中
5,					 --闪避
40,					 --根骨
40,					 --悟性
40,					 --体魄
20,					 --身法
}

local pet_expr = require("config.pet_fight_expr")

Pet_obj = oo.class(nil,"Pet_obj")

function Pet_obj:__init(pet_id,owner_id)
	self.owner_id = owner_id
	
	--宠物id
	self.pet_id = pet_id

	--血值
	self.hp = 0

	--当前hp
	self.cur_hp =0

	--魔值
	--self.mp = 0

	--当前魔值
	self.cur_mp = 0

	--基本属性
	self.base_attr = {0,0,0,0}

	--装备属性
	self.equip_con = nil

	--技能对象容器
	self.skill_con = nil

	--效果对象容器
	self.impact_con = nil

	--策略
	self.strategy_obj = nil

	--等级
	self.level = 0

	--成长
	self.pullulate = 0

	--战斗力
	self.fighting = 0

	--职业
	self.occ = nil

	--经验
	self.exp = 0

	--名字
	self.name = nil

	--是否绑定
	self.bind = 0

	--
	self.type = OBJ_TYPE_PET

	--战斗状态
	self.combat_status = 0

	--初始四大属性
	self.init_strengh = 0
	self.init_intelligence = 0
	self.init_stemina = 0
	self.init_dexterity = 0

	--附体
	self.possess = {0,0,0,0}


end

function Pet_obj:get_possess()
	return self.possess
end

function Pet_obj:set_possess(possess)
	self.possess = possess or {0,0,0,0,0}
end

function Pet_obj:get_element_de_t()
	return 0
end

function Pet_obj:get_d_critical_ef_t()
	return 0
end

function Pet_obj:get_init_strengh()
	return self.init_strengh
end

function Pet_obj:set_init_strengh(strengh)
	self.init_strengh = strengh
end

function Pet_obj:get_init_intelligence()
	return self.init_intelligence
end

function Pet_obj:set_init_intelligence(intelligence)
	self.init_intelligence = intelligence
end

function Pet_obj:get_init_stemina()
	return self.init_stemina
end

function Pet_obj:set_init_stemina(stemina)
	self.init_stemina = stemina
end


function Pet_obj:get_init_dexterity()
	return self.init_dexterity
end

function Pet_obj:set_init_dexterity(dexterity)
	self.init_dexterity = dexterity
end

function Pet_obj:get_combat_status()
	return self.combat_status
end

function Pet_obj:set_combat_status(combat_status)
	self.combat_status = combat_status
end

function Pet_obj:get_base_skill_id()
	return pet_expr.get_base_skill(self.occ)
end

function Pet_obj:get_occ_level()
	return pet_expr.pet_get_info(self:get_occ(), 1)
end

function Pet_obj:get_max_exp()
	return pet_expr.pet_exp(self:get_level())
end

function Pet_obj:get_current_hp()
	return self.cur_hp
end

function Pet_obj:set_current_hp(hp)
	self.cur_hp = hp
end

function Pet_obj:get_current_mp()
	return self.cur_mp
end

function Pet_obj:set_current_mp(mp)
	self.cur_mp = mp
end

function Pet_obj:get_bind()
	return self.bind
end

function Pet_obj:set_bind(bind)
	self.bind = bind
end

function Pet_obj:set_hp(hp)
	local hp_n = hp or pet_expr.get_hp(self:get_occ(), self:get_stemina_ex(), self:get_level()) + self:get_equip_attr(21)
	self.hp  = math.floor(hp_n)
end

function Pet_obj:get_mp()
	return pet_expr.get_mp(self:get_occ(), self:get_intelligence_ex(), self:get_level()) + self:get_equip_attr(22)
end

function Pet_obj:get_max_exp()
	return pet_expr.pet_exp(self:get_level())
end

function Pet_obj:get_name()
	return self.name
end

function Pet_obj:set_name(name)
	self.name = name
end

function Pet_obj:get_type()
	return self.type
end

function Pet_obj:get_exp()
	return self.exp
end

function Pet_obj:set_exp(exp)
	self.exp = exp
end

function Pet_obj:get_pet_id()
	return self.pet_id
end

function Pet_obj:del_hp(hp)
	self.hp = self.hp - hp
	if self.hp < 0 then
		self.hp = 0
	end
end

function Pet_obj:add_hp(hp)
	self.hp = self.hp + hp
	local max_hp = math.floor(pet_expr.get_hp(self:get_occ(), self:get_stemina_ex(), self:get_level()) + self:get_equip_attr(21))
	if self.hp > max_hp then
		self.hp = max_hp
	end
end

function Pet_obj:get_hp()
	return self.hp
end

function Pet_obj:get_max_hp()
	return math.floor(pet_expr.get_hp(self:get_occ(), self:get_stemina_ex(), self:get_level()) + self:get_equip_attr(21))
end


--宠物
function Pet_obj:update_attr(attr_list)

end

--技能
function Pet_obj:set_skill_con(skill_con)
	self.skill_con = skill_con
end

function Pet_obj:get_skill_con()
	return self.skill_con
end

--属性
function Pet_obj:set_base_attr(base_attr)
	self.base_attr = base_attr
end

function Pet_obj:get_base_attr()
	return self.base_attr
end

--效果
function Pet_obj:set_impact_con(impact_con)
	self.impact_con = impact_con
end

function Pet_obj:get_impact_con()
	return self.impact_con
end

--背包
function Pet_obj:set_equip_con(equip_con)
	self.equip_con = equip_con
end

function Pet_obj:get_equip_con()
	return self.equip_con
end

--策略
function Pet_obj:set_strategy_obj(strategy_obj)
	self.strategy_obj = strategy_obj
end

function Pet_obj:get_strategy_obj()
	return self.strategy_obj
end

function Pet_obj:init_load()
	self:load_skill_con()
	self:load_impact_con()
	self:load_equip_con()
end

function Pet_obj:load_skill_con()
	if self.skill_con == nil then
		self.skill_con = Skill_container(self.pet_id,self.owner_id)
		self.skill_con:load()
		self.skill_con:init_base_skill(self.occ)
		self.skill_con:set_passive_attr()
	end
end

function Pet_obj:load_impact_con()
	if self.impact_con == nil then
		--self.impact_con = Impact_container(self.pet_id,self.owner_id)
		--self.impact_con:load()
	end
end

function Pet_obj:load_equip_con()
	if self.equip_con == nil then
		self.equip_con = Pet_bag(self.pet_id, self.owner_id)
		self.equip_con:load()
	end
end

function Pet_obj:load_base_attr(init_strengh, init_intelligence, init_stemina, init_dexterity)
	--分配四大属性
	local list = pet_expr.get_foundation_ratio_calculation(self.level, self.pullulate, 
	init_strengh, init_intelligence, init_stemina, init_dexterity) 

	self:set_base_attr(list)
end

function Pet_obj:get_level()
	return self.level
end

function Pet_obj:set_level(level)
	self.level = level
end

function Pet_obj:get_pullulate()
	return self.pullulate
end

function Pet_obj:set_pullulate(pullulate)
	self.pullulate = pullulate
end

function Pet_obj:get_fighting()
	return self.fighting
end

function Pet_obj:set_fighting(fighting)
	self.fighting = fighting
end

function Pet_obj:get_occ()
	return self.occ
end

function Pet_obj:set_occ(occ)
	self.occ = occ
end

function Pet_obj:get_equip_attr(index)
	local attr = self.equip_con:get_attr()
	return attr[index] or 0
end

function Pet_obj:get_skill_attr(index)
	local attr = self.skill_con:get_passive_attr()
	return attr[index] or {}
end

function Pet_obj:get_strategy_attr(index)
	if self.strategy_obj == nil then
		return {}
	end
	local t_index = self.strategy_obj:get_index(self.pet_id)
	if t_index == nil then return {} end

	local attr = self.strategy_obj:get_attr(t_index)
	return attr[index] or {}
end

function Pet_obj:get_all_attr(index)
	local skill_attr = self:get_skill_attr(index)
	local strategy_attr = self:get_strategy_attr(index)
	
	local skill_index_1 = skill_attr[1] or 0
	local skill_index_2 = skill_attr[2] or 0
	local strategy_index_1 = strategy_attr[1] or 0
	local strategy_index_2 = strategy_attr[2] or 0
	local attr = {}
	attr[1] = skill_index_1 + strategy_index_1
	attr[2] = skill_index_2 + strategy_index_2
	return attr

end

----------战斗属性---------
function Pet_obj:get_strengh()
	return self.base_attr[1] + self:get_equip_attr(17)
end

function Pet_obj:get_intelligence()
	return self.base_attr[2] + self:get_equip_attr(18)
end

function Pet_obj:get_stemina()
	return self.base_attr[3] + self:get_equip_attr(19)
end

function Pet_obj:get_dexterity()
	return self.base_attr[4] + self:get_equip_attr(20)
end

--根骨
function Pet_obj:get_strengh_ex()
	local attr = self:get_all_attr(1)
	return (self:get_strengh() + attr[1]) * (1+attr[2])
end

--悟性
function Pet_obj:get_intelligence_ex()
	local attr = self:get_all_attr(2)
	return (self:get_intelligence() + attr[1]) * (1+attr[2]);
end

--体魄
function Pet_obj:get_stemina_ex()
	local attr = self:get_all_attr(3)
	return (self:get_stemina() + attr[1]) * (1+attr[2]);
end

--身法
function Pet_obj:get_dexterity_ex()
	local attr = self:get_all_attr(4)
	return (self:get_dexterity()+attr[1]) * (1+attr[2]);
end

--暴击
function Pet_obj:get_critical()
	local attr = self:get_all_attr(6)
	return (pet_expr.get_crit(self:get_occ(), self:get_dexterity_t(), self:get_level()) + self:get_equip_attr(13) + attr[1]) * (1 + attr[2])
end

--暴击效果
function Pet_obj:get_critical_ef()
	local attr = self:get_all_attr(7)
	return (pet_expr.base_info(self:get_occ(), 10) + self:get_equip_attr(13) + attr[1]) * (1 + attr[2])
end

--命中率
function Pet_obj:get_point()
	local attr = self:get_all_attr(8)
	return (pet_expr.get_point(self:get_occ(), self:get_dexterity_t(), self:get_level()) + self:get_equip_attr(15) + attr[1])  * (1 + attr[2]) 
end

--闪避率
function Pet_obj:get_dodge()
	local attr =  self:get_all_attr(5)
	return (pet_expr.get_dodge(self:get_occ(), self:get_dexterity_t(), self:get_level()) + self:get_equip_attr(16)+attr[1]) * (1 + attr[2])
end

--11冰攻
function Pet_obj:get_ice_ak()
	local attr = self:get_all_attr(9)
	return (pet_expr.get_attributes_attack(self:get_occ(), self:get_level(), self:get_pullulate(), 11) + self:get_equip_attr(7)+attr[1])* (1 + attr[2])
end

--14冰抗
function Pet_obj:get_ice_de()
	local attr = self:get_all_attr(12)
	return (pet_expr.get_attributes_attack(self:get_occ(), self:get_level(), self:get_pullulate(), 14) + self:get_equip_attr(8)+ attr[1])* (1 + attr[2])
end

--12雷攻
function Pet_obj:get_fire_ak()
	local attr = self:get_all_attr(10)
	return (pet_expr.get_attributes_attack(self:get_occ(), self:get_level(), self:get_pullulate(), 12) + self:get_equip_attr(9) + attr[1])* (1 + attr[2])
end

--16雷抗
function Pet_obj:get_fire_de()
	local attr = self:get_all_attr(13)
	return (pet_expr.get_attributes_attack(self:get_occ(), self:get_level(), self:get_pullulate(), 16) + self:get_equip_attr(10) + attr[1])* (1 + attr[2])
end

--13毒攻
function Pet_obj:get_poison_ak()
	local attr = self:get_all_attr(11)
	return (pet_expr.get_attributes_attack(self:get_occ(), self:get_level(), self:get_pullulate(), 13) + self:get_equip_attr(11) + attr[1])* (1 + attr[2])
end

--15毒抗
function Pet_obj:get_poison_de()
	local attr = self:get_all_attr(14)
	return (pet_expr.get_attributes_attack(self:get_occ(), self:get_level(), self:get_pullulate(), 15) + self:get_equip_attr(12) + attr[1])* (1 + attr[2])
end

--物理防御
function Pet_obj:get_s_defense()
	local attr = self:get_all_attr(15)
	return (pet_expr.get_s_defense(self:get_occ(), self:get_stemina_ex(), self:get_level()) + self:get_equip_attr(3) + attr[1]) * (1+attr[2])
end

--魔法防御
function Pet_obj:get_m_defense()
	local attr = self:get_all_attr(16)
	return (pet_expr.get_m_defense(self:get_occ(), self:get_stemina_ex(), self:get_level()) + self:get_equip_attr(6)+ attr[1]) * (1+attr[2])
end

--物理攻击
function Pet_obj:get_s_attack()
	return pet_expr.get_max_s_attack(self:get_occ(), self:get_strengh_ex())
end

--魔法攻击
function Pet_obj:get_m_attack()
	return pet_expr.get_max_m_attack(self:get_occ(), self:get_intelligence_ex())
end

--获取吸血被动技能
function Pet_obj:get_vampire_hp()
	local attr = self:get_all_attr(17)
	return attr[1] or 0
end

--获取冰伤强化
function Pet_obj:get_ice_addition()
	local attr = self:get_all_attr(18)
	return attr[1] or 0
end

--获取毒伤强化
function Pet_obj:get_poison_addition()
	local attr = self:get_all_attr(19)
	return attr[1] or {}
end

--获取冰伤强化
function Pet_obj:get_fire_addition()
	local attr = self:get_all_attr(20)
	return attr[1] or 0
end

--获取复仇
function Pet_obj:get_sub_hp()
	local attr = self:get_all_attr(21)
	return attr[1] or 0
end



--根骨
function Pet_obj:get_strengh_t()
	return self:get_strengh_ex()
end

--悟性
function Pet_obj:get_intelligence_t()
	return self:get_intelligence_ex()
end

--体魄
function Pet_obj:get_stemina_t()
	return self:get_stemina_ex()
end

--身法
function Pet_obj:get_dexterity_t()
	return self:get_dexterity_ex()
end

--最小,最大物攻
function Pet_obj:get_s_attack_t()
	local min, max = 0.5 * self:get_s_attack(), self:get_s_attack()
	return math.floor(min), math.floor(max)
end

--最小,最大法攻
function Pet_obj:get_m_attack_t()
	local min, max = 0.5 * self:get_m_attack(), self:get_m_attack()
	return math.floor(min), math.floor(max)
end

--物防
function Pet_obj:get_s_defense_t()
	return self:get_s_defense()
end

--魔防
function Pet_obj:get_m_defense_t()
	return self:get_m_defense()
end

--雷防
function Pet_obj:get_fire_de_t()
	return self:get_fire_de()
end

--冰防
function Pet_obj:get_ice_de_t()
	return self:get_ice_de()
end

--毒防
function Pet_obj:get_poison_de_t()
	return self:get_poison_de()
end

--雷攻
function Pet_obj:get_fire_ak_t()
	return self:get_fire_ak()
end

--冰攻
function Pet_obj:get_ice_ak_t()
	return self:get_ice_ak()
end

--毒攻
function Pet_obj:get_poison_ak_t()
	return self:get_poison_ak()
end

--闪避
function Pet_obj:get_dodge_t()
	return self:get_dodge()
end

--暴击
function Pet_obj:get_critical_t()
	return math.floor(self:get_critical())
end

--暴击效果
function Pet_obj:get_critical_ef_t()
	return math.floor(self:get_critical_ef())
end

--命中
function Pet_obj:get_point_t()
	return self:get_point()
end


function Pet_obj:get_all_att_ex()
	local ret = {}
	ret[1] = self:get_name()
	ret[2] = self:get_level()
	ret[3] = self:get_pullulate()
	ret[4] = math.floor(self:get_strengh_t())
	ret[5] = math.floor(self:get_intelligence_t())
	ret[6] = math.floor(self:get_stemina_t())
	ret[7] = math.floor(self:get_dexterity_t())
	ret[8] = math.floor(self:get_s_defense_t())
	ret[9] = math.floor(self:get_m_defense_t())
	ret[10] = math.floor(self:get_critical_t())
	ret[11] = math.floor(self:get_critical_ef_t())
	ret[12] = math.floor(self:get_point_t())
	ret[13] = math.floor(self:get_dodge_t())
	ret[14] = self:get_occ()
	ret[15] = self:get_hp()

	return ret
end

function Pet_obj:get_net_attr_info()
	local ret = {}

	ret[1] = self:get_current_hp()
	ret[2] = self:get_hp()
	ret[3] = self:get_current_mp()
	ret[4] = self:get_mp()
	ret[5] = self:get_exp()
	ret[6] = self:get_max_exp()
	ret[7] = self:get_strengh_t()		
	ret[8] = self:get_intelligence_t()	
	ret[9] = self:get_stemina_t()		
	ret[10] = self:get_dexterity_t()
	ret[11] = self:get_init_strengh()		
	ret[12] = self:get_init_intelligence()
	ret[13] = self:get_init_stemina()
	ret[14] = self:get_init_dexterity()
	ret[15],ret[16] = self:get_s_attack_t()
	ret[17],ret[18] = self:get_m_attack_t()
	ret[19] = self:get_s_defense_t()
	ret[20] = self:get_m_defense_t()
	ret[21] = self:get_fire_de_t()	
	ret[22] = self:get_ice_de_t()	
	ret[23] = self:get_poison_de_t()
	ret[24] = self:get_fire_ak_t()	
	ret[25] = self:get_ice_ak_t()	
	ret[26] = self:get_poison_ak_t()
	ret[27] = self:get_pet_id()
	ret[28] = self:get_pullulate()
	ret[29] = self:get_bind()
	ret[30] = self:get_base_skill_id()
	ret[31] = self:get_dodge_t()		
	ret[32] = self:get_critical_t()	
	ret[33] = self:get_point_t()		
	ret[34] = self:get_fighting()	
	local occ_lvl = self:get_occ_level()
	local pet_lvl = self:get_level()
	local req_lvl = pet_lvl > 5 and (pet_lvl - 5) or 1
	ret[35] = occ_lvl > req_lvl and occ_lvl or req_lvl		--最低使用等级

	ret[36] = self:get_critical_ef_t()

	ret[37] = ""
	ret[38] = 0
	ret[39] = 0
	ret[40] = 0
	ret[41] = {}
	ret[42] = 0
	ret[43] = self:get_skill_con():get_last_special_skill()
	ret[44] = 0
	ret[45] = self:get_possess()

	return ret

end

function Pet_obj:get_attribute()
	local ret = {}
	ret[1],ret[2] = self:get_s_attack_t()
	ret[3] = self:get_s_defense_t()
	ret[4],ret[5] = self:get_m_attack_t()
	ret[6] = self:get_m_defense_t()
	ret[7] = self:get_ice_ak_t()
	ret[8] = self:get_ice_de_t()
	ret[9] = self:get_fire_ak_t()
	ret[10] = self:get_fire_de_t()
	ret[11] = self:get_poison_ak_t()
	ret[12] = self:get_poison_de_t()
	ret[13] = self:get_critical_t()
	ret[14] = self:get_critical_ef_t()
	ret[15] = self:get_point_t()
	ret[16] = self:get_dodge_t()
	ret[17] = self:get_strengh_t()
	ret[18] = self:get_intelligence_t()
	ret[19]	= self:get_stemina_t()
	ret[20]	= self:get_dexterity_t()
	return ret
end

function Pet_obj:get_fighting()
	local ret = self:get_attribute()
	local result = 0
	for k,v in pairs(ret) do
		result = result + v * percent[k]
	end
	local effective_skill = self:get_skill_con():get_effective_list() or {}
	for m, n in pairs(effective_skill) do
		if n ~= 0 and n ~= nil then
			result = result + 20 * (n%100) * self:get_level()
		end
	end
	
	local fight = (result/10) - 5000
	if fight < 0 then
		return 0
	end
	return math.floor(fight)
end


function Pet_obj:get_pet_info()
	local s_pkt = {}
	local skill_con = self:get_skill_con()
	local skill_list = skill_con:get_skill_list()
	local effective_skill = skill_con:get_effective_list()

	s_pkt.list = {}
	s_pkt.list[1] = {
		self:get_combat_status(),		--combat
		self:get_pet_id(),					--obj_id
		self:get_name(),					--name
		self:get_occ(),					--occ
		self:get_level(),					--level
		skill_con.addition_effective_skill or {0,0,0,0,0}
	}
	s_pkt.list[2] = self:get_net_attr_info()
	s_pkt.list[3] = {}
	local count = 1
	--技能列表
	for k,v in ipairs(effective_skill or {}) do
		for k1,v1 in ipairs(skill_list[k] or {}) do
			s_pkt.list[3][count] = v1 or 0
			count = count + 1
		end

		s_pkt.list[3][count] = v:get_skill_id() or 0
		count = count + 1
	end
	s_pkt.list[4] = {}
	local pack_con = self:get_equip_con()
	if pack_con ~= nil then
		s_pkt.list[4] = pack_con:net_get_bag_info()
	end


	s_pkt.result = 0

	--print("other_pet_info:",j_e(s_pkt))

	return s_pkt
end











