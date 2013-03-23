
TYPE_ITEM_CONSUME = 0  --物品消费
TYPE_MONEY_CONSUME = 1 --金钱消费

RECEIVE_CONSUME = 0 --领取
PAY_CONSUME = 1 --消耗

--消费点类型
Consume_Type = {
CONSUME_NPC_TRANS_ACTIONS= 1,--npc买卖
CONSUME_REPAIR			=2,	--修理装备
CONSUME_INTENSIFY		=3,	--强化
CONSUME_DRILL			=4,	--打孔
CONSUME_ENCHASE			=5,	--镶嵌
CONSUME_STRIP			=6,	--拆卸
CONSUME_QUEST			=7,	--任务得到(主线任务、日常任务、环任务、押镖任务)
CONSUME_TRADE			=8,	--交易
CONSUME_MAIL_PAY		=9,	--附件支付
CONSUME_MAIL_OBTAIN		=10,--邮件获得
CONSUME_STUDY_SKILL		=11,--技能学习
CONSUME_FACTION_CREATE	=12,--帮派创建
CONSUME_STALL			=13,--摆摊
CONSUME_ACTIVITY		=14,--活动
CONSUME_ONLINE_REWARD	=15,--在线领取
CONSUME_BANK_SLOT		=16,--银行开格
CONSUME_FAST_SALE		=17,--快速出售
CONSUME_NPC_EXCHANGE	=18,--npc兑换
}
MAX_CONSUME_TYPE = 19

--jtxm_web.mall_trade_log表中type类型的定义(针对礼券和元宝的消费点定义)
--PAY_  (前缀的表示 支付,付款)
--GAIN_ (前缀的表示 获得,收入)

Money_Consume_Type = {
CONSUME_TYPE_NONE		= 0, --未知消费类型
PAY_MALL_BUY			= 1, --商城购买支付
GAIN_PLAYER_TRADE		= 2, --玩家交易获得
PAY_PLAYER_TRADE		= 3, --玩家交易支付
GAIN_STALL				= 4, --摆摊获得
PAY_STALL				= 5, --摆摊支付
GAIN_GIFT_BAG			= 6, --系统礼包获得(玩家背包中的礼包打开获得,包括后台发放和系统赠送礼包)
PAY_BANK_OPEN_SLOT		= 7, --银行开格支付
GAIN_NPC_EXCHANGE		= 8, --Npc兑换获得
PAY_NPC_EXCHANGE		= 9, --Npc兑换支付
GAIN_QUEST				= 10,--任务获得
GAIN_RECHARGE			= 11,--充值获得
PAY_QUEST				= 12,--任务委托支付
PAY_DAILY_QUEST_REFRESH	= 13,--环任务刷新支付
PAY_CHEST				= 14,--降妖支付
PAY_AUTO_FINISH_QUEST	= 15,--自动完成任务支付
GAIN_GIFT_CARD			= 16,--礼券卡获得
PAY_OFFLINE_PRACTICE	= 17,--离线修炼支付
PAY_PET_ADD_SKILL_LIMIT	= 18,--增加宠物技能上限
}

require("consume_log.item_consume_log")
require("consume_log.money_consume_log")
require("consume_log.consume_log_mgr")
require("consume_log.db_money_log")
