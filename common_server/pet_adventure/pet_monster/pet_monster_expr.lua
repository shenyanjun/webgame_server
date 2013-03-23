local _random = crypto.random
--**********************宠物**********************

local pet_xml_config = require("pet_adventure.pet_monster.pet_monster_loader")
--local _expr = require("config.expr")
--local _pet_exp = require("config.pet_config")
--local pet_skill_config = require("config.loader.pet_combat_skill_load")
module("pet_adventure.pet_monster.pet_monster_expr", package.seeall)

--基本参数
--off:1hp生命 2mp法力 3s_attack物理攻击 4m_attack法术攻击 5s_defense物理防御 6m_defense法术防御 7critical暴击率 8dodge闪避率
--9point命中率 10critical_ef暴击效果 11ice_attack冰攻 12fire_attack雷攻 13poison_attack毒攻 14ice_defense冰抗
--15poison_defence毒抗 16fire_defense雷抗
base_info = function (occ, off)
	return pet_xml_config._pet_base[occ][off]
end

--宠物的四大属性之和=(（等级-1）*成长率^2) /40 +30
calculation_sum_attributes = function(pullulate, level)
	return	( (level - 1) * pullulate * pullulate ) / 40 + 30
end

--分配四大属性
--off:等级level, 成长率pullulate, 四大初始属性:strengh, intelligence, stemina, dexterity
get_foundation_ratio_calculation = function (level, pullulate, strengh, intelligence, stemina, dexterity)	
	local ago_sum_attributes = strengh + intelligence + stemina + dexterity
	local sum_attributes = calculation_sum_attributes(pullulate, level)

	local attribute = {}
	attribute[1] = math.floor( sum_attributes * (strengh / ago_sum_attributes) )
	attribute[2] = math.floor( sum_attributes * (intelligence / ago_sum_attributes) )
	attribute[3] = math.floor( sum_attributes * (stemina / ago_sum_attributes) )
	attribute[4] = math.floor( sum_attributes * (dexterity / ago_sum_attributes) )

	return attribute
end


--最大物理攻击=（tlt_pa根骨(tlt_pa)） *2+初始最大物理攻击
get_max_s_attack = function (occ, tlt_pa)
	return tlt_pa * 2 + pet_xml_config._pet_base[occ][3]
end

--最大魔法攻击=(tlt_pa悟性(tlt_pa)) *2+初始最大魔法攻击
get_max_m_attack = function (occ, tlt_pa)
	return tlt_pa * 2 + pet_xml_config._pet_base[occ][4]
end

--物理防御=（等级/2+体魄点数(tlt_pa)）*2+初始物理防御
get_s_defense = function (occ, tlt_pa, level)
	return (level/2 + tlt_pa)*2 + pet_xml_config._pet_base[occ][5]
end

--魔法防御=（等级/2+体魄点数(tlt_pa)）*2+初始魔法防御
get_m_defense = function (occ, tlt_pa, level)
	return (level/2 + tlt_pa)*2 + pet_xml_config._pet_base[occ][6]
end

--生命值=（等级*3+体魄点数(tlt_pa)/3）*30+初始生命值
get_hp = function (occ, tlt_pa, level)
	return (level*3+(tlt_pa)/3)*30 + pet_xml_config._pet_base[occ][1]
end

--魔法值=（等级+悟性点数(tlt_pa)）*10+初始魔法值
get_mp = function (occ, tlt_pa, level)
	return (level+tlt_pa)*10 + pet_xml_config._pet_base[occ][2]
end

--闪避=身法点数(tlt_pa)*2 + 等级(level)*4
get_dodge = function (occ, tlt_pa, level)
	return tlt_pa * 2 + level*4
end

--命中=身法点数(tlt_pa)*2 + 等级(level) * 6 + 200
get_point = function (occ, tlt_pa, level)
	return tlt_pa * 2+level*6 + 200
end

--暴击=身法点数(tlt_pa)*3 + 等级(level)*2
get_crit = function (occ, tlt_pa, level)
	return tlt_pa * 3 + level * 2
end

--冰攻、雷攻、毒攻、冰抗、毒抗、雷抗
--growth:成长率
--level:等级
--off:1hp生命 2mp法力 3s_attack物理攻击 4m_attack法术攻击 5s_defense物理防御 6m_defense法术防御 7critical暴击率 8dodge闪避率
--9point命中率 10critical_ef暴击效果 11ice_attack冰攻 12fire_attack雷攻 13poison_attack毒攻 14ice_defense冰抗
--15poison_defence毒抗 16fire_defense雷抗
--属性攻击、属性防御=成长率*成长率*初值（等级-1）/1500+初值
get_attributes_attack = function (occ, level, growth, off)
	return (base_info(occ, off) * growth * growth * (level - 1)) / 1500 + base_info(occ, off)
end

--先天技能
get_base_skill = function (occ)
	return pet_xml_config._pet_base_skill[occ][1]
end

--后天技能列表
get_acquired_skill = function (occ)
	return pet_xml_config._pet_acquired_skill[occ]
end