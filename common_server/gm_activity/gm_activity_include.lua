
require("gm_activity/gm_activity_mgr")
require("gm_activity/gm_activity_process")
--g_activity_mgr = Gm_activity_mgr()

ACTIVITY_TYPE = {
	CONSUME				= 1, --消费返回活动
	ACHIEVE_GOAL		= 2, --达成目标活动
	ACHIEVE_LONG        = 3, --神龙
	ACHIEVE_ZILL        = 4, --大富翁
	ACHIEVE_SEED        = 5, --种子配方
	ACHIEVE_ACHI_TREE   = 6, --成就树活动
	ACHIEVE_RANK		= 7, --排行榜活动
	MAX					= 7,
}

require("gm_activity/gm_activity_item_achi_tree")
