math.randomseed(os.time())

require("server_info")
require("utils")
require("check")
require("string.include")

local check_o = Check()   --内存检测

local str = "MAP_ID_"..Map_sv
SELF_SV_ID = _G[str]
if SELF_SV_ID == nil then
	print("error: serverinfo error")
	os.exit(0)
end
local _sv_l = {WORLD_ID, COMMON_ID}
local _switch_l = {SWITCH_ID}

require("cmd_sv")
require("db")
require("mongodb")
require("my_debug")
require("timer")
require("log")
require("toolkit")
g_log = I_Log()
g_log:start(LOG_PATH)

require("server_connection")
require("client_connection")
require("Error")
require("global")
require("global_function")
require("event_mgr")
require("sock_event")
require("mongodb")

require("def.currency")

g_sock_event_mgr = Sock_event()
g_event_mgr = Event_mgr()

require("timeout")
require("map_svsock_mgr")
--require("map_cltsock_mgr")

require("new_map_cltsock_mgr")

g_svsock_mgr = Map_svsock_mgr(_sv_l)

--g_cltsock_mgr = Cltsock_mgr_map()

g_cltsock_mgr = New_cltsock_mgr_map(_switch_l)

g_timeout_mgr = Timeout()

--先要加载物品
require("item.items_include")
require("bags.bag_include")

--角色名过滤
require("filter.filter_include")

require("map_cmd")
--客户端协议处理函数列表
Clt_commands = {      
	[0] = {}, --before login                            
	[1] = {}, --enter map
}   

--服务器协议处理函数列表
Sv_commands = {                                           
	[0] = {},                             
}         

require("pet_bags.pet_bag_include")
require("sort.public_sort_mgr")
require("key_mgr")
require("click")
require("click_timer")
require("map_cmd_func")
require("ai.ai_include")
require("obj.obj_include")
require("impact.impact_include")
require("skill.skill_include")
g_scene_log = Log(g_log, g_log:add("map_" .. SELF_SV_ID .. "_scene"), LOG_LEVEL_LOG)
require("scene_ex.scene_include")
require("item_random")
require("obj.activity.achievement_tree.achievement_tree_include")--成就树活动
g_achi_tree_mgr = achi_tree_mgr()--成就树活动管理器

g_public_sort_mgr = Public_sort_mgr()
g_key_mgr = Key_mgr()
g_obj_mgr = Obj_mgr()
g_impact_mgr = Impact_mgr()
g_skill_mgr = Skill_mgr()

require("obj.activity.activity_rank.activity_rank_include")
g_activity_rank_mgr = activity_rank_mgr()

--帮派效果
require("faction_impact.faction_impact_include")
g_faction_impact_mgr = Faction_impact_mgr()

--渡劫 渡劫 chendong 120925
--[[
--渡劫
require("kalpa.kalpa_include")
g_kalpa_mgr = Kalpa_mgr()
]]

--require("map_client_process")
--require("map_client_listen")
require("map_server_process")
require("map_server_listen")

require("new_map_client_process")
require("new_map_client_listen")

require("cmds.item_process")
require("cmds.misc_process")
require("cmds.email_process")
require("cmds.common_server_cmds")
require("cmds.consignment_FB_process")
require("cmds.consignment_FC_process")
require("cmds.marry_fb_process")
require("cmds.marry_fc_process")
require("cmds.lottery")
require("cmds.faction_process")
require("cmds.congra_process")
require("cmds.treasure_process")
require("obj.soul.soul_include")

require("authorize.authorize_fb_process")
require("authorize.authorize_fc_process")

require("chat_channal.chat_channal_include")
g_soul_mgr = Soul_mgr()
require("obj.stall.stall_include")
require("reward.login_reward_l.reward_include")
g_reward_gift_mgr = Reward_t_mgr()
--消费流水记录
require("consume_log.consume_include")
g_consume_log = Consume_log_mgr()

--黄钻礼包
require("yellow_reward.yellow_reward_include")
g_yellow_reward_mgr = Yellow_reward_mgr()

--daily quest
g_mission_log = Log(g_log, g_log:add("map_" .. SELF_SV_ID .. "_mission"), LOG_LEVEL_LOG)
require("mission_ex.mission_include")

require("npc.npc_include")
g_statue_mgr = Statue_mgr()

--[[
g_goal_log = Log(g_log, g_log:add("map_" .. SELF_SV_ID .. "_goal"), LOG_LEVEL_LOG)
require("goal.goal_include")
]]

NpcContainerMgr = Npc_container_mgr()
--g_daily_reward_mgr = Daily_reward_mgr()
g_random_script = Random_script_mgr()

--online reward
require("reward.reward_include")
g_reward_mgr = Reward_mgr()

--require("reward/login_reward/reward_handler")
--g_reward_login_mgr=reward_login_mgr()
--g_reward_login_mgr:load()
require("reward.buffer_reward.buffer_reward_handler")
g_buffer_reward_mgr = buffer_reward_mgr()
g_buffer_reward_mgr:load()

--g_reward_exp = Reward_exp()   --在线领经验

--保护锁
require("obj.protect_lock.lock_include")
require("obj.refresh_shop.refresh_shop_include")

--回归
require("regression.regression_include")

require("team.team_include")
g_team_mgr = Team_mgr()

require("trade.trade_include")
g_trade_mgr = Trade_mgr()

require("compete.compete_include")
g_compete_mgr = Compete_mgr()

require("offline.offline_practice_include")
g_off_mgr = Off_pr_mgr()


require("faction.faction_include")
g_faction_mgr = Faction_mgr()

-- 帮派仓库
require("faction_warehouse.faction_warehouse_include")
-- 帮派资源互换
require("faction_resource_exchange.faction_resource_exchange_include")

-- 帮派神兽
require("faction_dogz.faction_dogz_include")

--帮派庭院 屏蔽 121114 chendong
--[[
-- 帮派庭院
--require("faction_courtyard.faction_courtyard_include")
--]]

-- 累计消费回馈
require("consum_ret.consum_ret_include")

require("marry.marry_include")
g_marry_mgr = Marry()

require("meditation.meditation_include")

require("function.function_include")
local _cmd = require("map_cmd_func")

require("obj.achievement.achievement_include")

require("obj.pet_soul_fresh.fresh_include")
g_fresh_mgr = Fresh_mgr()

require("faction_territory.faction_territory_include")
if f_is_line_faction() then
--帮派领地
g_faction_territory = Faction_territory()
g_faction_territory:unserialize()
local click_faction_territory = Click(60)
click_faction_territory:regster(g_faction_territory:get_click_param())
click_faction_territory:start()
end
--require("config.loader.collection_activity_loader")
--帮派报名
require("faction_territory.app_include")

--vip卡
require("vip.vip_include")
g_vip_mgr=Vip_mgr()

--商城
require("cmds.mall_process")
require("cmds.vip_mall_process")


--积分兑换礼券
require("mall.integral_exchange.integral_exchange_include")

--全服答题
require("cmds.answer_process")

--内网命令
require("chat_cmd.chat_cmd_include")

--累计在线奖励
require("reward.gm_function_reward.gm_reward_include")

--后台兑换活动
require("npc.gm_exchange.gm_exchange_include")

--坐骑
require("obj.ride.ride_include")

-- 坐骑进阶
require("obj.mount_advanced.mountadv_include")
-- 时装衣柜
require("obj.wardrobe.wardrobe_include")

--法宝
require("magic_key.magickey_include")

--经验找回
require("retrieve.retrieve_include")

--验证码
require("identify.identify_include")
g_identify_con = Identify_container()

--实物抽奖
require("spec_lottery.slottery_include")

--春节收集活动
require("activity_reward.activity_reward_include")

--养孩子
require("obj.children.children_include")

--藏宝图
require("treasure_map.treasure_include")

--后台活动
require("obj.activity.gm_function.gm_function_include")
g_gm_function_con = Gm_function_mgr()

--单人离线竞技
require("offline_compete.offline_compete_process")

--QQ任务集市
require("qq_quest_market.qq_quest_market_include")


if 1 == ENABLE_GATE then
	require("world_war.world_war_include")
	g_ww_mgr = World_war_mgr()
end

require("function.gm_function.refresh_mgr")
g_refresh_mgr = Refresh_mgr()

require("world_level.world_lvl_mgr")
g_world_lvl_mgr = World_lvl_mgr()


--npc
g_npc_mgr = Obj_npc_mgr()
--boss
g_boss_mgr = Obj_boss_mgr()
--box
g_box_mgr = Obj_box_mgr()

g_chat_channal_mgr = Chat_channal_mgr()
--开宝箱
--require("chests.chests_include")
--g_chests_mgr = Chests_mgr()
g_treasure_mgr = Treasure_mgr()

--称号
g_reigns_log = Log(g_log, g_log:add("map_" .. SELF_SV_ID .. "_reigns"), LOG_LEVEL_LOG)
require("obj.reigns.reigns_include")

g_ach_log = Log(g_log, g_log:add("map_" .. SELF_SV_ID .. "_ach"), LOG_LEVEL_LOG)
require("obj.achievement.achievement_include")
--全服成就
g_global_achi_mgr = Global_achi_mgr()

--结婚
g_marry_log = Log(g_log, g_log:add("map_" .. SELF_SV_ID .. "_ach"), LOG_LEVEL_LOG)
require("marry.marry_include")

--家园
g_home_log = Log(g_log, g_log:add("map_" .. SELF_SV_ID .. "_ach"), LOG_LEVEL_LOG)
require("obj.home.home_include")

--大富翁
g_zillionaire_log = Log(g_log, g_log:add("map_" .. SELF_SV_ID .. "_ach"), LOG_LEVEL_LOG)
require("obj.activity.zillionaire.zillionaire_include")

--战场官职系统
g_officer_log = Log(g_log, g_log:add("map_" .. SELF_SV_ID .. "_ach"), LOG_LEVEL_LOG)
require("obj.officer.officer_include")
g_officer_mgr_ex = OfficerMgr_ex()
require("obj.officer.officer_base.officer_include")
g_officer_mgr_ex:loadOfficer()

require("mall.integral_include")
--世界产出
require("whole.whole_produce")
g_whole_mgr = Whole_produce()
g_whole_mgr:load()

--帮派约战
--require("faction_battle.faction_battle_include")
--g_faction_battle_mgr = Faction_battle_mgr()

--帮派庄园
require("faction_manor.faction_manor_include")
g_faction_manor_mgr = Faction_manor_mgr()

--宠物繁殖
require("obj.pet_breed.pet_breed_include")

--剧情副本
require("story.story_include")

--后台达标活动
require("obj.activity.goal.activity_goal_include")

-- cailizhong
-- 手机绑定礼包
require("bind_gift.bind_gift_include")

-- 坐骑进阶图谱
require("obj.mount_advanced.mountadv_include")
-- 时装衣柜
require("obj.wardrobe.wardrobe_include")

--log and sql
g_web_sql = I_Sql()
g_web_multi_sql = I_Sql_multi()


g_scene_config_mgr = Scene_config_mgr()
g_scene_config_mgr:load()

g_i_scene = I_Scene()

g_scene_mgr_ex = Scene_mgr()
if not g_scene_mgr_ex:load() then
	print("Error Load Scene Failes!")
	os.exit()
end

local function scene_mgr_extractor(char_id)
	return g_scene_mgr_ex
end

g_event_mgr:register_event(
	EVENT_SET.EVENT_DEL_TEAM
	, scene_mgr_extractor
	, Scene_mgr.notify_del_team_event)

g_event_mgr:register_event(
	EVENT_SET.EVENT_DIE
	, scene_mgr_extractor
	, Scene_mgr.notify_die_event)		

g_event_mgr:register_event(
	EVENT_SET.EVENT_TEAM_CAPTAIN
	, scene_mgr_extractor
	, Scene_mgr.notify_team_caption_event)

g_event_mgr:register_event(
	EVENT_SET.EVENT_OUT_FACTION
	, scene_mgr_extractor
	, Scene_mgr.notify_out_faction_event)
	
g_event_mgr:register_event(
	EVENT_SET.EVENT_KILL_MONSTER
	, scene_mgr_extractor
	, Scene_mgr.notify_kill_event)

g_event_mgr:register_event(
	EVENT_SET.EVENT_KILL_GHOST
	, scene_mgr_extractor
	, Scene_mgr.notify_kill_ghost)


--神秘商人清理
g_event_mgr:register_event(
	EVENT_SET.EVENT_DEL_TEAM
	, function(char_id)
		return g_random_script
	end
	, g_random_script.event_del_team)

--创建副本事件
g_event_mgr:register_event(
	EVENT_SET.EVENT_CREATE_COPY_SCENE, 
	function(char_id) return g_team_mgr end, 
	g_team_mgr.on_event_open_copy)

g_dynamic_npc_mgr = Dynamic_npc_mgr()

--初始雕像等级信息
g_activity_reward_mgr = Activity_reward_mgr()
--test
--Scene_map.test(10000)

--场景短滴答
local click_game = Click(0.5)
click_game:regster(g_scene_mgr_ex, g_scene_mgr_ex.on_timer, 0.5, nil)
click_game:regster(g_sock_event_mgr:get_click_param())
click_game:start()

--impact
local click_impact = Click(1)
click_impact:regster(g_impact_mgr:get_click_param())
click_impact:regster(g_dynamic_npc_mgr, g_dynamic_npc_mgr.on_timer, 1, nil)
click_impact:start()

--buffer设置
local click_buffer = Click(2)
click_buffer:regster(g_buffer_reward_mgr:get_click_param(2))
click_buffer:regster(g_soul_mgr:get_click_param())
click_buffer:regster(g_meditation_mgr:get_click_param())
click_buffer:regster(g_fresh_mgr:get_click_param())
click_buffer:start()


--click timeout
local click_timeout = Click(3)
click_timeout:regster(g_scene_mgr_ex, g_scene_mgr_ex.on_slow_timer, 3, nil)
click_timeout:regster(g_timeout_mgr:get_click_param())
click_timeout:regster(g_svsock_mgr:get_click_param())
click_timeout:regster(g_cltsock_mgr:get_click_param())
click_timeout:regster(g_spec_lottery_mgr:get_click_param())
click_timeout:regster(g_activity_reward_mgr:get_click_param())
--click_timeout:regster(g_home_mgr:get_click_param())
click_timeout:regster(g_achi_tree_mgr:get_click_param())
click_timeout:regster(g_whole_mgr:get_click_param())

--test
--click_impact:regster(g_treasure_mgr:get_click_param())
if 1 == ENABLE_GATE then
	click_timeout:regster(g_ww_mgr, g_ww_mgr.on_timer, 3, nil)
end
click_timeout:start()

--长滴答
local click_slow = Click(5)
--click_slow:regster(g_team_mgr:get_click_param())
--click_slow:regster(g_compete_mgr:get_click_param())
click_slow:regster(g_scene_mgr_ex, g_scene_mgr_ex.on_serialize_timer, 5, nil)
click_slow:start()


--特长滴答
local click_long = Click(30)
click_long:regster(g_npc_mgr:get_click_param())
click_long:regster(g_boss_mgr:get_click_param())
click_long:regster(g_box_mgr:get_click_param())
click_long:regster(check_o:get_click_param())
click_long:regster(g_public_sort_mgr, g_public_sort_mgr.on_timer, 30, nil)
click_long:regster(g_online_reward,g_online_reward.on_timer,30,nil)
click_long:regster(g_refresh_mgr,g_refresh_mgr.on_timer,30,nil)
click_long:start()


--时间点定时器
local click_timer = Click_timer(20)
click_timer:start()

--debug
function set_debug()
	local f = function (event)
			local info = debug.getinfo(2)
			if info.currentline > -1 and
				info.name ~= nil and
				string.find(info.short_src, "client") ~= nil then
				print("----debugline:",info.currentline, "func:", info.name, "source:", info.short_src)
			end
			--[[for k,v in pairs(info) do
				print("------", k,v)
			end
			print("\n\n")]]--
		end
	debug.sethook(f, "c")
end
--set_debug()

local my_debug = require("my_debug")
--my_debug.begin_debug()



--链接其他服务器
g_svsock_mgr:connect_allserver()
--链接网关
g_cltsock_mgr:connect_allserver()

local function server_start()
end

-- 进程关闭，保存数据
local function server_close(signum)
	print("****************server closing...")
	click_game:stop()
	click_buffer:stop()
	click_timeout:stop()
	click_slow:stop()
	click_timer:stop()
	--click_serialize:stop()
	click_long:stop()

	g_obj_mgr:serialize()
	g_whole_mgr:updateWholeproduce()
	--g_reward_mgr:serialize()
	local _ = g_faction_territory and g_faction_territory:serialize()

	ev:stop()
	g_log:stop()
	g_web_sql:stop()
	g_web_multi_sql:stop()

	print("************************server_close", signum)
end

server_start()
ev:signal(15, server_close)
ev:signal(2, server_close)

--日志
g_player_log = Log(g_log, g_log:add("map_"..SELF_SV_ID.."_player_info"), LOG_LEVEL_LOG)
g_pet_log = Log(g_log, g_log:add("map_"..SELF_SV_ID.."_pet_info"), LOG_LEVEL_LOG)
g_item_log = Log(g_log, g_log:add("map_"..SELF_SV_ID.."_consume_info"), LOG_LEVEL_LOG)
g_money_log = Log(g_log, g_log:add("map_"..SELF_SV_ID.."_gold_info"), LOG_LEVEL_LOG)
g_item_record_log = Log(g_log, g_log:add("map_"..SELF_SV_ID.."_item_info"), LOG_LEVEL_LOG)
g_stall_log = Log(g_log, g_log:add("map_"..SELF_SV_ID.."_stall_info"), LOG_LEVEL_LOG)
g_faction_log = Log(g_log, g_log:add("map" .. SELF_SV_ID .. "_faction_info"), LOG_LEVEL_LOG)
g_email_log = Log(g_log, g_log:add("map" .. SELF_SV_ID .. "_email_info"), LOG_LEVEL_LOG)
g_arena_log = Log(g_log, g_log:add("map" .. SELF_SV_ID .. "_arema_info"), LOG_LEVEL_LOG)
g_equip_log = Log(g_log, g_log:add("map" .. SELF_SV_ID .. "_equip_info"), LOG_LEVEL_LOG)

g_soul_log = Log(g_log, g_log:add("map" .. SELF_SV_ID .. "_soul_info"), LOG_LEVEL_LOG)
g_festival_log = Log(g_log, g_log:add("map" .. SELF_SV_ID .. "_festival_info"), LOG_LEVEL_LOG)
g_offline_log = Log(g_log, g_log:add("map" .. SELF_SV_ID .. "_offline_info"), LOG_LEVEL_LOG)
g_reward_log = Log(g_log, g_log:add("map" .. SELF_SV_ID .. "_reward_info"), LOG_LEVEL_LOG)

g_chests_log = Log(g_log, g_log:add("map_" .. SELF_SV_ID .. "_chests_info"), LOG_LEVEL_LOG)
g_authorize_log = Log(g_log, g_log:add("map_" .. SELF_SV_ID .. "_authorize_info"), LOG_LEVEL_LOG)
g_lottery_log = Log(g_log, g_log:add("map_" .. SELF_SV_ID .. "_lottery_info"), LOG_LEVEL_LOG)
g_mall_log = Log(g_log, g_log:add("map_" .. SELF_SV_ID .. "_mall"), LOG_LEVEL_LOG)
g_date_count_log = Log(g_log, g_log:add("map_" .. SELF_SV_ID .. "_date_count"), LOG_LEVEL_LOG)
g_boss_log = Log(g_log, g_log:add("map_" .. SELF_SV_ID .. "_boss"), LOG_LEVEL_LOG)
g_bosslost_log = Log(g_log, g_log:add("map_" .. SELF_SV_ID .. "_bosslost"), LOG_LEVEL_LOG)
g_box_log = Log(g_log, g_log:add("map_" .. SELF_SV_ID .. "_box"), LOG_LEVEL_LOG)
g_fresh_shop_log = Log(g_log, g_log:add("map_" .. SELF_SV_ID .. "_fresh_shop"), LOG_LEVEL_LOG)
g_petdie_log = Log(g_log, g_log:add("map_" .. SELF_SV_ID .. "_petdie"), LOG_LEVEL_LOG)
g_pet_breed_log = Log(g_log, g_log:add("map_" .. SELF_SV_ID .. "_pet_breed"), LOG_LEVEL_LOG)
g_pet_skill_fresh_log = Log(g_log, g_log:add("map_" .. SELF_SV_ID .. "_pet_skill_fresh"), LOG_LEVEL_LOG)
g_children_log = Log(g_log, g_log:add("map_" .. SELF_SV_ID .. "_children"), LOG_LEVEL_LOG)

g_debug_log = Log(g_log, g_log:add("map_" .. SELF_SV_ID .. "_debug"), LOG_LEVEL_ERROR)
g_warning_log = Log(g_log, g_log:add("map_" .. SELF_SV_ID .. "_warning"), LOG_LEVEL_ERROR)
g_check_log = Log(g_log, g_log:add("map_" .. SELF_SV_ID .. "_check"), LOG_LEVEL_ERROR)
g_honor_log = Log(g_log, g_log:add("map_" .. SELF_SV_ID .. "_honor"), LOG_LEVEL_ERROR)

--数据库
if g_web_sql:start(WEB_DB_IP, WEB_DB_PORT, WEB_DB_USR, WEB_DB_PWD, WEB_DB_NAME) ~= 0 then
	print("g_web_sql can't connect db!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
	os.exit(1)
end
if g_web_multi_sql:start(WEB_DB_IP, WEB_DB_PORT, WEB_DB_USR, WEB_DB_PWD, WEB_DB_NAME) ~= 0 then
	print("g_web_multi_sql can't connect db!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
	os.exit(1)
end

--注册mongodb错误回调函数
f_mongo_register(_cmd.f_kill_all_char)
--注册热更新log函数
register_hot_update_log_function(function(str) 
	g_warning_log:write(str)
end
)

check_o:set_log_function(function(str) 
	g_check_log:write(str)
end)
if not _DEBUG then
	check_o:set_time_point(4)   --每天4点检测一次
end

ev:start()
