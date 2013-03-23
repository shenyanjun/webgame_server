

--全服成就类型
GLOBAL_ACHI_TYPE = {
	KILL_BOSS		= 1				--杀boss
	, LEVEL			= 2				--人物升级
	, SOUL			= 3				--元神等级
	, SOUL_INTENSIFY= 4				--元神强化等级
	, PET_PULLULATE = 5				--宠物成长
	, PET_SKILL		= 6				--宠物技能
	, INTENSIFY		= 7				--装备强化
	, EQUIP_COUNT	= 8				--装备强化数量
	, ARTIFACTS		= 9				--神器数量
	, RANKING		= 10			--排行榜
	, PET_FIGHT		= 11			--宠物闯关
	, BATTLEFIELD	= 12			--战场杀人数
	, GOBANG		= 13			--五子棋得分
}

require("global_achi.global_achi_mgr")
require("global_achi.global_achi_process")