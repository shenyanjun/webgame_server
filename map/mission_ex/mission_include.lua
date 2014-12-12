--错误码
E_SUCCESS								= 	0			--成功
E_MISSION_INVALID_ID					=	25001		--无效的任务ID
E_MISSION_INVALID_TYPE					=	25002		--无效的任务类型
E_MISSION_UNKNOWN						=	25003		--未知错误
E_MISSION_PREQUEST						=	25004		--前置任务未完成
E_MISSION_ALREADY_ACCEPT				=	25005		--重复接受任务
E_MISSION_OCC_NO_MATCH					=	25006		--职业不匹配
E_MISSION_LEVEL_LOW						=	25007		--玩家等级低于任务要求
E_MISSION_LEVEL_HIG						=	25008		--玩家等级高于任务要求
E_MISSION_INCOMPLETE					=	25009		--任务未完成
E_MISSION_INVALID_DATA					=	25010		--无效的任务数据
E_MISSION_GIVE_UP_INVALID				=	25011		--任务无法放弃
E_MISSION_BAD_ESCORT					=	25012		--非正常的押镖任务
E_MISSION_BAD_SCENE						=	25013		--所在地图错误
E_MISSION_NO_ACCEPT_LIST				=	25014		--不需要在可接列表显示

--人物身上的存盘
PARAM_TYPE_FACTION_SCROLL			= 1
PARAM_TYPE_FINCA					= 2
PARAM_TYPE_RANDOM					= 3
PARAM_TYPE_NO_MANOR_MISSION			= 4
PARAM_TYPE_ESCORT					= 5
PARAM_TYPE_MANOR_MISSION			= 6
PARAM_TYPE_LOOP_INDIVIDUAL			= 7
PARAM_TYPE_LOOP_DAILY				= 8

--任务分类定义
MISSION_TYPE_MAIN				= 1		--主线任务
MISSION_TYPE_BRANCH				= 2		--支线任务
MISSION_TYPE_LOOP				= 3		--环任务
MISSION_TYPE_DAILY				= 4		--日常固定任务
MISSION_TYPE_ESCORT				= 5		--押镖任务
MISSION_TYPE_LOOP_NEW			= 6		--帮派环任务
MISSION_TYPE_AUTHORIZE			= 7		--委托任务
MISSION_TYPE_MANOR				= 8		--领地任务
MISSION_TYPE_NO_MANOR			= 9		--没领地任务
MISSION_TYPE_MIX				= 10	--杂类任务
MISSION_TYPE_RANDOM				= 11	--随机任务
MISSION_TYPE_VIP_ESCORT			= 12	--VIP押镖任务
MISSION_TYPE_FINCA				= 13	--庄园任务
MISSION_TYPE_FACTION_SCROLL		= 14	--帮派卷轴任务
MISSION_TYPE_BATTLE_DAY_LOOP	= 15    --战场任务(一天只能做一次)
MISSION_TYPE_BATTLE_LOOP        = 16    --战场任务(一天能做多次)
MISSION_TYPE_NINE_PVP			= 17    --九幽PVP 采集 杀人
MISSION_TYPE_NINE_PVP_MONSTER   = 18    --九幽 普通杀怪
MISSION_TYPE_QUEST_TYPE			= 19    --引导完成任务类型任务
MISSION_TYPE_SHEEP_RUN			= 20    --小羊快跑
MISSION_TYPE_COUNT				= 21    --计数任务



--任务类型定义
MISSION_FLAG_SPECIAL			= 0		--特殊
MISSION_FLAG_DELIVER 			= 1		--送信
MISSION_FLAG_SPEAK 				= 2		--对话
MISSION_FLAG_KILL 				= 3		--杀怪
MISSION_FLAG_COLLECT 			= 4		--收集
MISSION_FLAG_LEVEL_FINISH 		= 5		--等级完成
MISSION_FLAG_ANSWER 			= 6		--答题
MISSION_FLAG_USE_ITEM			= 7		--使用物品
MISSION_FLAG_INTENSIFY			= 8		--强化装备
MISSION_FLAG_ESCORT				= 9		--押镖任务
MISSION_FLAG_COLOR_EQUI			= 10	--获得特定类型装备
MISSION_FLAG_AUTHORIZE			= 11	--委托任务
MISSION_FLAG_STEAL				= 12	--偷取任务
MISSION_FLAG_COLLECT_VISIT		= 13	--采集拜访任务
MISSION_FLAG_KILL_HUMAN			= 14	--战场中杀人
MISSION_FLAG_ASSIST_ATTACK		= 15	--战场中协助助攻
MISSION_FLAG_OVER_RESOURCES		= 16	--战场中上缴资源
MISSION_FLAG_NINE_PVP			= 17    --九幽PVP 采集 杀人
MISSION_FLAG_NINE_PVP_MONSTER   = 18    --九幽 普通杀怪
MISSION_FLAG_QUEST_TYPE			= 19    --引导完成任务类型任务
MISSION_FLAG_SHEEP_RUN			= 20    --小羊快跑
MISSION_FLAG_COUNT				= 21    --场景计数任务
MISSION_FLAG_MAX				= 21	--任务类型最大值

--任务状态定义
MISSION_STATUS_NONE         	= 0  
MISSION_STATUS_FINISH     		= 1  --完成(已经领取了奖励)
MISSION_STATUS_UNAVAILABLE  	= 2  --不可接
MISSION_STATUS_INCOMPLETE   	= 3  --进行中
MISSION_STATUS_AVAILABLE    	= 4  --可接
MISSION_STATUS_FAILED       	= 5  --失败
MISSION_STATUS_COMMIT  			= 6  --可交

--任务事件
MISSION_EVENT_KILL			= EVENT_SET.EVENT_KILL_MONSTER		--杀死对象
MISSION_EVENT_USE_ITEM		= EVENT_SET.EVENT_USE_ITEM			--使用物品
MISSION_EVENT_ADD_ITEM		= EVENT_SET.EVENT_ADD_ITEM			--增加物品
MISSION_EVENT_DEL_ITEM		= EVENT_SET.EVENT_DEL_ITEM			--减少物品
MISSION_EVENT_LEVEL_UP		= EVENT_SET.EVENT_LEVEL_UP			--升级
MISSION_EVENT_FACTION		= EVENT_SET.EVENT_FACTION			--帮派通知
MISSION_EVENT_INTENSIFY		= EVENT_SET.EVENT_INTENSIFY			--强化装备
MISSION_EVENT_CLIENT		= EVENT_SET.EVENT_CLIENT			--客户端通知
MISSION_EVENT_NEW_DAY		= EVENT_SET.EVENT_NEW_DAY			--新一天通知
MISSION_EVENT_DIE			= EVENT_SET.EVENT_DIE				--人物死亡通知
MISSION_EVENT_KILL_HUMAN    = EVENT_SET.EVENT_BATTLE_KILL		--战场中杀人通知
MISSION_EVENT_ASSIST_ATTACK = EVENT_SET.EVENT_ASSIST_ATTACK		--战场中协助助攻事件
MISSION_EVENT_OVER_RESOURCES= EVENT_SET.EVENT_OVER_RESOURCES	--战场中上缴资源
MISSION_EVENT_NINE_PVP_COLL = EVENT_SET.EVENT_NINE_PVP_COLL		--九幽PVP 任务 采集 and 杀怪
MISSION_EVENT_NINE_PVP_DIE  = EVENT_SET.EVENT_NINE_PVP_DIE		--九幽PVP 人物死亡
MISSION_EVENT_SHEEP_RUN		= EVENT_SET.EVENT_SHEEP_RUN			--小羊快跑
MISSION_EVENT_COUNT			= EVENT_SET.EVENT_COUNT				--场景计数任务


--帮派建筑类型
MISSION_BUILDING_ACTION		= 1		--演武厅
MISSION_BUILDING_PAVILION	= 2		--观星阁
MISSION_BUILDING_COFFER		= 3		--金库

--帮派奖励类型
M_FACTION_REWARD_CONTRIBUTION		= 1		--贡献度
M_FACTION_REWARD_BUILD_POINT		= 2		--建设点
M_FACTION_REWARD_TECHNOLOGY_POINT	= 3		--科技点
M_FACTION_REWARD_FUND				= 4		--帮派基金

--帮派任务每日可完成次数
FACTION_COMPLETE_TIME				= 10
DAILY_COMPLETE_TIME					= 20

function f_quest_error_log(fmt, ...)
	local err_msg = string.format(" Error: %s", string.format(tostring(fmt), ...))
	g_mission_log:write(err_msg)
	debug_print(err_msg)
	return err_msg
end

function f_quest_warning_log(fmt, ...)
	local err_msg = string.format(" Warning: %s", string.format(tostring(fmt), ...))
	g_mission_log:write(err_msg)
	debug_print(err_msg)
	return err_msg
end

function f_quest_info_log(fmt, ...)
	local err_msg = string.format(" Info: %s", string.format(tostring(fmt), ...))
	g_mission_log:write(err_msg)
	debug_print(err_msg)
	return err_msg
end

require("mission_ex.mission_loader")
require("mission_ex.mission_mgr")
require("mission_ex.quest.quest_include")

require("mission_ex.mission_container")
require("mission_ex.mission_process")
g_mission_mgr = Mission_mgr()


local function get_mission_con(char_id)
	local player = char_id and g_obj_mgr:get_obj(char_id)
	return player and player:get_mission_mgr()
end

--目的,为了热更新的时候可以把旧注册的事件也弄掉
mission_event_mgr = oo.class(nil,'mission_event_mgr')
function mission_event_mgr:__init()
	self.event_list = {}
end
--注册事件，先把旧的注册干掉
function mission_event_mgr:reg_event(event_id, callback1, callback2)
	if self.event_list[event_id] then --热更时，先干掉旧的
		g_event_mgr:unregister_event(event_id, self.event_list[event_id])
	end
	self.event_list[event_id] = g_event_mgr:register_event(event_id, callback1, callback2)
end

if g_mission_event_mgr==nil then --热更新的时候 不为空
	g_mission_event_mgr = mission_event_mgr()
end

--监听杀死怪物事件
g_mission_event_mgr:reg_event(EVENT_SET.EVENT_KILL_MONSTER, get_mission_con, Mission_container.notify_kill_event)
--监听使用物品事件
g_mission_event_mgr:reg_event(EVENT_SET.EVENT_USE_ITEM, get_mission_con, Mission_container.notify_use_item_event)
--监听增加物品事件
g_mission_event_mgr:reg_event(EVENT_SET.EVENT_ADD_ITEM, get_mission_con, Mission_container.notify_add_item_event)
--监听删除物品事件
g_mission_event_mgr:reg_event(EVENT_SET.EVENT_DEL_ITEM, get_mission_con, Mission_container.notify_del_item_event)
--监听等级提升事件
g_mission_event_mgr:reg_event(EVENT_SET.EVENT_LEVEL_UP, get_mission_con, Mission_container.notify_level_up_event)
--监听加入帮派事件
g_mission_event_mgr:reg_event(EVENT_SET.EVENT_FACTION, get_mission_con, Mission_container.notify_add_faction_event)
--监听强化成功事件
g_mission_event_mgr:reg_event(EVENT_SET.EVENT_INTENSIFY, get_mission_con, Mission_container.notify_intensify_event)
--监听客户端事件
g_mission_event_mgr:reg_event(EVENT_SET.EVENT_CLIENT, get_mission_con, Mission_container.notify_client_event)
--监听新一天事件
g_mission_event_mgr:reg_event(EVENT_SET.EVENT_NEW_DAY, get_mission_con, Mission_container.notify_new_day_event)
--监听人物死亡事件
g_mission_event_mgr:reg_event(EVENT_SET.EVENT_DIE, get_mission_con, Mission_container.notify_die_event)
--监听任务完成事件
--g_mission_event_mgr:reg_event(EVENT_SET.EVENT_COMPLETE_QUEST, get_mission_con, Mission_container.notify_complete_faction_quest_event)
--监听战场杀敌事件
g_mission_event_mgr:reg_event(EVENT_SET.EVENT_BATTLE_KILL, get_mission_con, Mission_container.notify_battle_kill_event)
--监听战场协助助攻事件
g_mission_event_mgr:reg_event(EVENT_SET.EVENT_ASSIST_ATTACK, get_mission_con, Mission_container.notify_assist_attack_event)
--监听战场上交资源事件
g_mission_event_mgr:reg_event(EVENT_SET.EVENT_OVER_RESOURCES, get_mission_con, Mission_container.notify_over_resources)
--九幽PVP采集
g_mission_event_mgr:reg_event(EVENT_SET.EVENT_NINE_PVP_COLL, get_mission_con, Mission_container.notify_nine_pvp_coll)
--九幽PVP采集死亡
g_mission_event_mgr:reg_event(EVENT_SET.EVENT_NINE_PVP_DIE, get_mission_con, Mission_container.notify_nine_pvp_die)
--完成任务
g_mission_event_mgr:reg_event(EVENT_SET.EVENT_COMPLETE_QUEST, get_mission_con, Mission_container.notify_complete_quest_event)
--小羊快跑
g_mission_event_mgr:reg_event(EVENT_SET.EVENT_SHEEP_RUN, get_mission_con, Mission_container.notify_sheep_run)
--钓鱼
g_mission_event_mgr:reg_event(EVENT_SET.EVENT_ENTER_COPY, get_mission_con, Mission_container.notify_scene)
