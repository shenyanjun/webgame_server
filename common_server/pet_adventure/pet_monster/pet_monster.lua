local pet_expr = require("pet_adventure.pet_monster.pet_monster_expr")
local pet_monster_loader = require("pet_adventure.pet_monster.pet_monster_loader")

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



Pet_monster = oo.class(nil, "Pet_monster")

function Pet_monster:__init(occ)
	self.occ = occ
	self.name = nil
	self.hp = 0
	self.level = 1
	self.pullulate = 1
	self.monster_id = nil

	self.base_attr = {0,0,0,0}

	self.skill_con = nil
	self.type = OBJ_TYPE_PET

end

function Pet_monster:get_element_de_t()
	return 0
end

function Pet_monster:get_d_critical_ef_t()
	return 0
end

function Pet_monster:get_type()
	return self.type
end

function Pet_monster:init_all_attr(name, level, pullulate)
	self.name = name
	self.level = level
	self.pullulate = pullulate
	self:load_skill_con()

	local pet_foundation = pet_monster_loader._pet_foundation
	self:load_base_attr(pet_foundation[self.occ][1],pet_foundation[self.occ][2],pet_foundation[self.occ][3],pet_foundation[self.occ][4])
	self:init_max_hp()
end

function Pet_monster:init_matrix_attr(name, level, pullulate, pack)
	self.name = name
	self.level = level
	self.pullulate = pullulate
	self:load_skill_con()

	self:load_base_attr(pack[1],pack[2],pack[3],pack[4])
	self:init_max_hp()
end

function Pet_monster:clear()
	self.name = nil
	self.level = 1
	self.pullulate = 1
	self.hp = 0
	self.base_attr = {0,0,0,0}

	self.skill_con = nil
end


function Pet_monster:load_skill_con()
	if self.skill_con == nil then
		self.skill_con = Pet_monster_skill_con(self.occ)
		self.skill_con:init_base_skill()
		local skill_list = pet_expr.get_acquired_skill(self.occ)
		self.skill_con:init_effective_skill(skill_list)
		self.skill_con:set_passive_attr()
		self.skill_con:sub_all_cd()
	end
end

function Pet_monster:get_monster_id()
	return self.monster_id
end

function Pet_monster:set_monster_id(monster_id)
	self.monster_id = monster_id
end

--属性
function Pet_monster:set_base_attr(base_attr)
	self.base_attr = base_attr
end

function Pet_monster:get_base_attr()
	return self.base_attr
end

function Pet_monster:load_base_attr(init_strengh, init_intelligence, init_stemina, init_dexterity)
	--分配四大属性
	local list = pet_expr.get_foundation_ratio_calculation(self.level, self.pullulate, 
	init_strengh, init_intelligence, init_stemina, init_dexterity) 

	self:set_base_attr(list)
end

function Pet_monster:get_skill_attr(index)
	local attr = self.skill_con:get_passive_attr()
	return attr[index] or {}
end


function Pet_monster:get_all_attr(index)
	local skill_attr = self:get_skill_attr(index)
	local skill_index_1 = skill_attr[1] or 0
	local skill_index_2 = skill_attr[2] or 0
	local attr = {}
	attr[1] = skill_index_1
	attr[2] = skill_index_2
	return attr
end

function Pet_monster:get_occ()
	return self.occ
end

function Pet_monster:set_occ(occ)
	self.occ = occ
end

function Pet_monster:get_level()
	return self.level
end

function Pet_monster:set_level(level)
	self.level = level
end

function Pet_monster:get_pullulate()
	return self.pullulate
end

function Pet_monster:set_pullulate(pullulate)
	self.pullulate = pullulate
end

function Pet_monster:get_name()
	return self.name
end

function Pet_monster:set_name(name)
	self.name = name
end

function Pet_monster:get_hp()
	return self.hp
end

function Pet_monster:del_hp(hp)
	self.hp = self.hp - hp
	if self.hp <= 0 then
		self.hp = 0
	end
end

function Pet_monster:add_hp(hp)
	self.hp = self.hp + hp
	local max_hp = math.floor(pet_expr.get_hp(self:get_occ(), self:get_stemina_ex(), self:get_level()))
	if self.hp > max_hp then
		self.hp = max_hp
	end
end

function Pet_monster:init_max_hp()
	self.hp = math.floor(pet_expr.get_hp(self:get_occ(), self:get_stemina_ex(), self:get_level()))
end

function Pet_monster:get_max_hp()
	return math.floor(pet_expr.get_hp(self:get_occ(), self:get_stemina_ex(), self:get_level()))
end

function Pet_monster:get_skill_con()
	return self.skill_con
end

----------战斗属性---------
function Pet_monster:get_strengh()
	return self.base_attr[1]
end

function Pet_monster:get_intelligence()
	return self.base_attr[2]
end

function Pet_monster:get_stemina()
	return self.base_attr[3]
end

function Pet_monster:get_dexterity()
	return self.base_attr[4]
end

--根骨
function Pet_monster:get_strengh_ex()
	local attr = self:get_all_attr(1)
	return (self:get_strengh() + attr[1]) * (1+attr[2])
end

--悟性
function Pet_monster:get_intelligence_ex()
	local attr = self:get_all_attr(2)
	return (self:get_intelligence() + attr[1]) * (1+attr[2]);
end

--体魄
function Pet_monster:get_stemina_ex()
	local attr = self:get_all_attr(3)
	return (self:get_stemina() + attr[1]) * (1+attr[2]);
end

--身法
function Pet_monster:get_dexterity_ex()
	local attr = self:get_all_attr(4)
	return (self:get_dexterity()+attr[1]) * (1+attr[2]);
end

--暴击
function Pet_monster:get_critical()
	local attr = self:get_all_attr(6)
	return (pet_expr.get_crit(self:get_occ(), self:get_dexterity_t(), self:get_level()) + attr[1]) * (1 + attr[2])
end

--暴击效果
function Pet_monster:get_critical_ef()
	local attr = self:get_all_attr(7)
	return (pet_expr.base_info(self:get_occ(), 10) + attr[1]) * (1 + attr[2])
end

--命中率
function Pet_monster:get_point()
	local attr = self:get_all_attr(8)
	return (pet_expr.get_point(self:get_occ(), self:get_dexterity_t(), self:get_level()) + attr[1])  * (1 + attr[2]) 
end

--闪避率
function Pet_monster:get_dodge()
	local attr =  self:get_all_attr(5)
	return (pet_expr.get_dodge(self:get_occ(), self:get_dexterity_t(), self:get_level())+attr[1]) * (1 + attr[2])
end

--11冰攻
function Pet_monster:get_ice_ak()
	local attr = self:get_all_attr(9)
	return (pet_expr.get_attributes_attack(self:get_occ(), self:get_level(), self:get_pullulate(), 11)+attr[1])* (1 + attr[2])
end

--14冰抗
function Pet_monster:get_ice_de()
	local attr = self:get_all_attr(12)
	return (pet_expr.get_attributes_attack(self:get_occ(), self:get_level(), self:get_pullulate(), 14)+ attr[1])* (1 + attr[2])
end

--12雷攻
function Pet_monster:get_fire_ak()
	local attr = self:get_all_attr(10)
	return (pet_expr.get_attributes_attack(self:get_occ(), self:get_level(), self:get_pullulate(), 12) + attr[1])* (1 + attr[2])
end

--16雷抗
function Pet_monster:get_fire_de()
	local attr = self:get_all_attr(13)
	return (pet_expr.get_attributes_attack(self:get_occ(), self:get_level(), self:get_pullulate(), 16) + attr[1])* (1 + attr[2])
end

--13毒攻
function Pet_monster:get_poison_ak()
	local attr = self:get_all_attr(11)
	return (pet_expr.get_attributes_attack(self:get_occ(), self:get_level(), self:get_pullulate(), 13) + attr[1])* (1 + attr[2])
end

--15毒抗
function Pet_monster:get_poison_de()
	local attr = self:get_all_attr(14)
	return (pet_expr.get_attributes_attack(self:get_occ(), self:get_level(), self:get_pullulate(), 15) + attr[1])* (1 + attr[2])
end

--物理防御
function Pet_monster:get_s_defense()
	local attr = self:get_all_attr(15)
	return (pet_expr.get_s_defense(self:get_occ(), self:get_stemina_ex(), self:get_level()) + attr[1]) * (1+attr[2])
end

--魔法防御
function Pet_monster:get_m_defense()
	local attr = self:get_all_attr(16)
	return (pet_expr.get_m_defense(self:get_occ(), self:get_stemina_ex(), self:get_level())+ attr[1]) * (1+attr[2])
end

--物理攻击
function Pet_monster:get_s_attack()
	return pet_expr.get_max_s_attack(self:get_occ(), self:get_strengh_ex())
end

--魔法攻击
function Pet_monster:get_m_attack()
	return pet_expr.get_max_m_attack(self:get_occ(), self:get_intelligence_ex())
end

--获取吸血被动技能
function Pet_monster:get_vampire_hp()
	local attr = self:get_all_attr(17)
	return attr[1] or 0
end

--获取冰伤强化
function Pet_monster:get_ice_addition()
	local attr = self:get_all_attr(18)
	return attr[1] or 0
end

--获取毒伤强化
function Pet_monster:get_poison_addition()
	local attr = self:get_all_attr(19)
	return attr[1] or {}
end

--获取冰伤强化
function Pet_monster:get_fire_addition()
	local attr = self:get_all_attr(20)
	return attr[1] or 0
end

--获取复仇
function Pet_monster:get_sub_hp()
	local attr = self:get_all_attr(21)
	return attr[1] or 0
end



--根骨
function Pet_monster:get_strengh_t()
	return self:get_strengh_ex()
end

--悟性
function Pet_monster:get_intelligence_t()
	return self:get_intelligence_ex()
end

--体魄
function Pet_monster:get_stemina_t()
	return self:get_stemina_ex()
end

--身法
function Pet_monster:get_dexterity_t()
	return self:get_dexterity_ex()
end

--最小,最大物攻
function Pet_monster:get_s_attack_t()
	local min, max = 0.5 * self:get_s_attack(), self:get_s_attack()
	return math.floor(min), math.floor(max)
end

--最小,最大法攻
function Pet_monster:get_m_attack_t()
	local min, max = 0.5 * self:get_m_attack(), self:get_m_attack()
	return math.floor(min), math.floor(max)
end

--物防
function Pet_monster:get_s_defense_t()
	return self:get_s_defense()
end

--魔防
function Pet_monster:get_m_defense_t()
	return self:get_m_defense()
end

--雷防
function Pet_monster:get_fire_de_t()
	return self:get_fire_de()
end

--冰防
function Pet_monster:get_ice_de_t()
	return self:get_ice_de()
end

--毒防
function Pet_monster:get_poison_de_t()
	return self:get_poison_de()
end

--雷攻
function Pet_monster:get_fire_ak_t()
	return self:get_fire_ak()
end

--冰攻
function Pet_monster:get_ice_ak_t()
	return self:get_ice_ak()
end

--毒攻
function Pet_monster:get_poison_ak_t()
	return self:get_poison_ak()
end

--闪避
function Pet_monster:get_dodge_t()
	return self:get_dodge()
end

--暴击
function Pet_monster:get_critical_t()
	return math.floor(self:get_critical())
end

--暴击效果
function Pet_monster:get_critical_ef_t()
	return math.floor(self:get_critical_ef())
end

--命中
function Pet_monster:get_point_t()
	return self:get_point()
end



function Pet_monster:get_all_att_ex()
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
	ret[14] = self:get_monster_id()
	ret[15] = self:get_max_hp()

	return ret
end

function Pet_monster:get_attribute()
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

function Pet_monster:get_fighting()
	local ret = self:get_attribute()
	local result = 0
	for k,v in pairs(ret) do
		result = result + v * percent[k]
	end
	local effective_skill = self:get_skill_con():get_effective_list() or {}
	for m, n in pairs(effective_skill) do
		if n ~= 0 and n ~= nil then
			result = result + 20 * (n:get_skill_id()%100) * self:get_level()
		end
	end
	
	local fight = (result/10) - 5000
	if fight < 0 then
		return 0
	end
	return math.floor(fight)
end



