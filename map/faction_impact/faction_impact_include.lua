local debug_print = function() end

FACTION_IMPACT_TYPE = { --群体效果起作用类型
	["STRENGH"] = 1,				--根骨
	["INTELLIGENCE"] = 2,			--悟性
	["STEMINA"] = 3,				--体魄
	["DEXTERITY"] = 4,				--身法
	
	["DODGE"] = 5,					--闪避率
	["CRITICAL"] = 6,				--暴击率
	["CRITICAL_EF"] = 7,			--暴击效果
	["POINT"] = 8,					--命中率
	
	["ICE_AK"] = 9,					--冰攻
	["FIRE_AK"] = 10,				--雷攻
	["POISON_AK"] = 11,				--毒攻
	
	["ICE_DE"] = 12,				--冰防
	["FIRE_DE"] = 13,				--雷防
	["POISON_DE"] = 14,				--毒防
	
	["SUB_PHYSICAL_DAMAGE"] = 15,	--物理减伤
	["SUB_MAGIC_DAMAGE"] = 16,		--魔法减伤
	
	["SUB_MP"] = 17,				--减魔
	["ATTACK"] = 18,				--攻击(物攻+法攻)
	["DOCTOR"] = 19,				--增加治疗效果
	["SUB_CD"] = 20,				--减CD
	
	["PHYSICAL_AK"] = 21,			--增加物理攻击
	["MAGIC_AK"] = 22,				--增加魔法攻击
	["PHYSICAL_DE"] = 23,			--增加物理防御
	["MAGIC_DE"] = 24,				--增加魔法防御
	["KILL_MONSTER"] = 25,			--增加杀怪经验加成
}

require("faction_impact.faction_impact_obj.faction_buff")
require("faction_impact.faction_impact_base")
require("faction_impact.faction_impact_container")
require("faction_impact.faction_impact_mgr")