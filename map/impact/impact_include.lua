

IMPACT_MIN_TIMER = 1    --最小滴答时间

IMPACT_TYPE = { --效果起作用类型
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
	["SUB_DAMAGE"] = 26,			--减伤害（不分物攻/法攻） 只对怪有效
	["HP"] = 27,					--生命值
	["MP"] = 28,					--魔法值
	["SUB_DAMAGE_H"] = 29,			--减伤害（不分物攻/法攻） 只对人有效
	["ESCORT"] = 30,				--押镖加成
	["JIN"] = 31,					--相克属性：金
	["MU"] = 32,					--相克属性：木
	["SHUI"] = 33,					--相克属性：水
	["HUO"] = 34,					--相克属性：火
	["TU"] = 35,					--相克属性：土
	["YIN"] = 36,					--相克属性：阴
	["YANG"] = 37,					--相克属性：阳
	["LIGHT"] = 38,					--相克属性：光
	["DARK"] = 39,					--相克属性：暗
	["LIFE"] = 40,					--相克属性：生
	["DEATH"] = 41,					--相克属性：死
}


require("impact.impact")

require("impact.impact_object.buff")
require("impact.impact_object.debuff")
require("impact.impact_object.sneer")
require("impact.impact_object.leech")
require("impact.impact_object.stop")
require("impact.impact_object.latent")
require("impact.impact_object.god")
require("impact.impact_object.silence")
require("impact.impact_object.change")
require("impact.impact_object.reflex")
require("impact.impact_object.burning")
require("impact.impact_object.prop")
require("impact.impact_object.timer")
require("impact.impact_object.team_buff")
require("impact.impact_object.element")


require("impact.impact_container")
require("impact.impact_process")
require("impact.impact_mgr")
