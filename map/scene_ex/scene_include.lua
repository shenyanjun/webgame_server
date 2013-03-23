--目前功能未全部完成,结构比较乱,待二次重构

--错误码
SCENE_ERROR = {
	E_SUCCESS								= 	0			--成功
	, E_SCENE_CHANGE						=	21001		--切换地图失败
	, E_SCENE_CLOSE							=	21003		--该地图还没有开启
	, E_LEVEL_DOWN							=	21004		--您等级不够，不能进入该地图"
	, E_ADDITION_FULL						=	21005		--加成已经到极限
	, E_INVALID_CONFIG						=	21006		--配置错误
	, E_NOT_ON_SCENE						=	21151		--对象不在当前场景
	, E_ATTACK_SELF							=	21152		--无法攻击自己
	, E_PK_MODE								=	21153		--双方非PK模式
	, E_ATTACK_TEAM							=	21154		--禁止攻击队员
	, E_ATTACK_PARTY						=	21155		--在帮派地图，帮成员之间不允许pk
	, E_ATTACK_BAN							=	21156		--禁止攻击
	, E_ATTACK_HOOK							=	21157		--该地图模式不允许攻击其他玩家
	, E_INVALID_ID							=	21201		--无效的ID
	, E_INVALID_ARGS						=	21202		--无效的参数
	, E_NO_IMPL								=	21203		--派生类未重实现
	, E_INVALID_POS							=	21204		--无效的地图位置
	, E_NOT_OPEN							=	21205		--下层未开放
	, E_HEART								=	21206		--无法攻击任务NPC
	, E_CARRY								=	21207		--禁止传送
	, E_CAPTION_USE							=	21208		--队长才能使用
	, E_NOT_CONFIG							=	21209		--无法使用
	, E_NOT_MANA							=	21210		--灵识不足
	, E_NOT_ITEM							=	21211		--道具不足
	, E_INVALID_FACTION						=	21212		--非帮派成员
	, E_INVALID_FACTIONER					=	21213		--非帮主
	, E_FACTION_DISSOLVE					=	21214		--帮派已经封闭
	, E_FACTION_HUMAN_MIN					=	21215		--帮派人数不足
	, E_FACTION_HUMAN_MAX					=	21216		--副本人数已满
	, E_FACTION_LEVEL_LIMIT					=	21217		--帮派等级不足
	, E_ATTACK_SIDE							=	21218		--无法攻击同一阵营
	, E_NOT_OPNE							=	21219		--开放时间未到
	, E_HAS_TEAM							=	21220		--组队无法进入
	, E_INSTANCE_LIMIT						=	21221		--战场数目达到上限
	, E_WAIT_TIMEOUT						=	21222		--战场进入CD冷却中
	, E_NOT_KILL_BOSS						=	21223		--"消灭当前层的boss,才能进入下一层"
	, E_LACK_FACTION_MONEY					=	21224		--"帮派资金不足"
	, E_NOT_VIP								=	21225		--非VIP
	, E_JUMP_LIMIT							=	21226		--次数上限
	, E_CHEATS_LIMIT						=	21227		--未达到层数条件
	, E_NOT_TERRITOR_APPLY					=	21228		--未报名参加攻防战或已过期
	, E_NOT_YOUR_SIDE						=	21229		--上一层已被攻下，不能进入
	, E_HAD_BE_OCCUPY						=	21230		--领地已被占领，请参加攻防战
	, E_HUMAN_FULL							=	21231		--场景人数已满
	, E_NOT_PERMISSION						=	21232		--权限不足
	, E_UPDATE_OVER							=	21233		--怪物刷新未结束
	, E_FACTION_BATTLE_OVER					=	21234		--这场约战已结束
	, E_INVALID_TEAM						=	21301		--没有组队
	, E_LEVEL_LIMIT							=	21303		--等级不足
	, E_CYCLE_LIMIT							=	21304		--超过进入次数
	, E_HUMAN_LIMIT							=	21305		--人数限制
	, E_INVALID_CAPTION						=	21306		--队长开启
	, E_EXISTS_COPY							=	21307		--存在副本
	, E_NO_SKILL							=	21312		--没有获得此技能
}

SCENE_STATUS = {
	CLOSE									=	0
	, OPEN									=	1
	, IDLE									=	2
	, FREEZE								=	3
	, FULL									=	4
}

SCENE_MODE = {
	PEACE									=	1  		--和平模式
	, FREE									=	2  		--自由模式
	, PARTY									=	3  		--帮派模式
	, KILL									=	4  		--杀戮模式
	, HOOK									=	5  		--挂机模式
	, WAR									=	6		--战场模式
	, SIDE									=	7		--阵营模式
	, NONE									=	8		--停止模式
}

SCENE_TYPE = {
	COMMON									=	MAP_TYPE_COMMON
	, ORG									=	MAP_TYPE_ORG
	, COPY									=	MAP_TYPE_COPY
	, ARENA									=	MAP_TYPE_ARENA
	, WAR									=	MAP_TYPE_WAR
	, SPA									=	MAP_TYPE_SPA
	, TOWER									=	MAP_TYPE_TOWER
	, TD									=	MAP_TYPE_TD
	, TD_EX									=	MAP_TYPE_TD_EX
	, INVASION								=	MAP_TYPE_INVASION
	, PUBLIC								=	MAP_TYPE_PUBLIC
	, FRENZY								=	MAP_TYPE_FRENZY			-- 战场
	, DESERT								=	MAP_TYPE_DESERT 
	, TERRITORY								=	MAP_TYPE_TERRITORY		-- 领地争夺战
	, TERRITORY_BATTLE						=	MAP_TYPE_TERRITORY_BATTLE-- 领地攻防战
	, LEVEL									=	MAP_TYPE_LEVEL
	, FACTION_BATTLE						=	MAP_TYPE_FACTION_BATTLE	-- 帮派约战
	, FACTION_MANOR							=	MAP_TYPE_FACTION_MANOR	-- 帮派庄园
	, MANOR_ROB								=	MAP_TYPE_MANOR_ROB		-- 庄园强盗副本
	, PERSONAL								=	MAP_TYPE_PERSONAL		-- 个人副本(采集)
	, CHESS									=	MAP_TYPE_CHESS			-- 棋局副本
	, WORLD_WAR								=	MAP_TYPE_WORLD_WAR		-- 跨服战场
	, VIP									=	MAP_TYPE_VIP			-- vip挂机场景
	, MARRY									=	MAP_TYPE_MARRY			-- 结婚场景
	, MARRY_MONSTER							=	MAP_TYPE_MARRY_MONSTER	-- 仙缘副本
	, MORE_KILL								=	MAP_TYPE_MORE_KILL		-- 连斩副本
	, STORY									=	MAP_TYPE_STORY			-- 剧情副本
	, TOWER_EX								=	MAP_TYPE_TOWER_EX		-- 单人爬塔副本
	, TOWER_RAGE							=	MAP_TYPE_TOWER_RAGE		-- 怒气副本
	, BATTLEFIELD							=	MAP_TYPE_BATTLEFIELD	-- 新战场
	, FACTION								=	MAP_TYPE_FACTION		-- 新帮派副本
	, PVP_BATTLE							=	MAP_TYPE_PVP_BATTLE		-- 九幽封印
	, GOBANG								=	MAP_TYPE_GOBANG			-- 五子棋
	, WILD_BOSS								=	MAP_TYPE_WILD_BOSS		-- 野外boss
	, SHEEP									=	MAP_TYPE_SHEEP			-- 狼羊
	, FISH									=	MAP_TYPE_FISH			-- 钓鱼 
	, COMPETE								=	MAP_TYPE_COMPETE		-- 离线竞技
}

function f_scene_error_log(fmt, ...)
	local err_msg = string.format(" Error: %s", string.format(tostring(fmt), ...))
	g_scene_log:write(err_msg)
	debug_print(err_msg)
	return err_msg
end

function f_scene_warning_log(fmt, ...)
	local err_msg = string.format(" Warning: %s", string.format(tostring(fmt), ...))
	g_scene_log:write(err_msg)
	debug_print(err_msg)
	return err_msg
end

function f_scene_info_log(fmt, ...)
	local err_msg = string.format(" Info: %s", string.format(tostring(fmt), ...))
	g_scene_log:write(err_msg)
	debug_print(err_msg)
	return err_msg
end

g_all_scene_config = create_local("scene_ex.g_all_scene_config", {})

require("min_heap")
require("timer_heap")
require("scene_ex.exp_reward")
require("scene_ex.summon_mgr")
require("scene_ex.broadcast_timer")
require("timer_queue")
require("scene_ex.config.config_include")
require("scene_ex.scene_mgr")
require("scene_ex.scene_obj_mgr")
require("scene_ex.scene_obj_mgr_ex")
require("scene_ex.sector")
require("scene_ex.map")
require("scene_ex.zone")
require("scene_ex.small_zone")
require("scene_ex.scene.scene_include")
require("scene_ex.scene_mode.mode_include")
require("scene_ex.layout.layout_include")
require("scene_ex.monster.monster_include")
