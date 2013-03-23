
require("server_info")
require("utils")
require("check")
require("item_random")
require("common")
require("string.include")

local check_o = Check()   --内存检测

require("cmd_sv")
require("mongodb")
require("query")
require("timer")
require("log")
require("global")
require("global_function")
require("add_json")

require("sock_event")
require("server_connection")
require("filter.filter_include")
if MUDRV_VERSION == nil then
	require("svsock_mgr")
else
	require("svsock_mgr_gcc")
end
require("event_mgr")
g_event_mgr = Event_mgr()

require("alarm_clock")
require("click")
require("item.items_include")

SELF_SV_ID = COMMON_ID
local SERVER_IP = SERVER_LIST[COMMON_ID].ip
local SERVER_PORT = SERVER_LIST[COMMON_ID].port
local _sv_l = {WORLD_ID}

Sv_commands = {                                           
	[0] = {},
	[1] = {},
}

if 1 == ENABLE_GATE then
	table.insert(_sv_l, GATE_ID)
	require("world_war.world_war_include")
	g_ww_mgr = World_war_facade()
end

require("include")
g_sock_event_mgr = Sock_event()
g_server_mgr = Server_mgr()

--与world的主动链接
g_svsock_mgr = Svsock_mgr(_sv_l)


require("player_mgr")
g_player_mgr = Player_mgr()
g_player_mgr:load()

--公共服活动查询管理器
require("gm_activity.gm_activity_db_mgr")
g_active_mgr = Common_active_mgr()

require("faction_l.faction_include")
require('faction_bag.bag_include')
require("consignment.consignment_include")
require("lottery.lottery_include")
require("authorize.authorize_include")
require("control_monster.control_monster_include")
require("cmds.common_cmd")
require("marry.marry_include")
--官职 官职include 121113 chendong
--require("officer.officer_include")
require("spec_lottery.slottery_include")
require("collection_activity.collection_activity_include")

-- 帮派仓库
require("faction_warehouse.faction_warehouse_include")
-- 帮派资源互换
require("faction_resource_exchange.faction_resource_exchange_include")

-- 帮派神兽
require("faction_dogz.faction_dogz_include")

-- 累计消费回馈
require("consum_ret.consum_ret_include")

--帮派庭院 屏蔽 121114 chendong （摇钱树，上香）
--[[
-- 帮派庭院
require("faction_courtyard.faction_courtyard_include")
--]]
require("connect_soc")
require("email/email_include")
require("sys_bdc_mgr")
require("cmds.EmailCmdHandler")
g_email_mgr=Email_mgr()

g_control_monster = Control_monster()
--g_email_mgr:load()


--********商城********
require("mall.mall_include")
g_mall_mgr = MallMgr()
require("mall.limit_include")
g_limit_mgr = Limit_mgr()
require("vip.vip_mall_include")
require("mall.gm_mall_include")
--*******vip玩家信息**********
require("vip.vip_play_info")
g_vip_play_inf = Vip_Play_Info()

--***********全服答题**************
require("answer_ex.answer_include")
g_answer_mgr = Answer_mgr()


--兑换
require("gm_exchange.gm_exchange_include")
g_exchange_mgr = Gm_exchange_mgr()

--积分兑换
require("mall.integral_exchange.integral_exchange_include")
g_integral_exchange_mgr = Integral_exchange_mgr()

--验证码
require("identify.identify_include")
g_identify_mgr = Identify_mgr()

--帮派报名
require("app_filter.application_filter_include")

--雕像排行
require("statue.statue_include")
g_statue_mgr = Statue_mgr()

--斗兽场
require("pet_fight.pet_vs_include")

--闯关
require("pet_adventure.pet_adventure_include")

--宠物繁殖
require("pet_breed.pet_breed_include")

--宠物征友
require("pet_friend.pet_friend_include")
g_pet_friend_mgr = Pet_friend_mgr()

--屏蔽人物竞技
--角色竞技
--require("human_fight.human_vs_include")

--养孩子
require("children.char_include")

--激活码
require("active_reward.activation_reward_include")

--官职  官职mgr 121113 chendong
--[[
--官职
require("officer.officer_include")
g_officer_mgr = OfficerMgr()
--]]

--帮派约战
--require("faction_battle.faction_battle_include")
--g_faction_battle_mgr = Faction_battle_mgr()
--local click_faction_battle = Click(60)
--click_faction_battle:regster(g_faction_battle_mgr:get_click_param())
--click_faction_battle:start()

--帮派庄园
require("faction_manor.faction_manor_include")
g_faction_manor_mgr = Faction_manor_mgr()
local click_faction_manor = Click(2)
click_faction_manor:regster(g_faction_manor_mgr:get_click_param())
click_faction_manor:start()

--后台活动管理
require("gm_activity.gm_activity_include")
g_activity_mgr = Gm_activity_mgr()

--世界等级管理
require("world_level.world_lvl_mgr")
g_world_lvl_mgr = World_lvl_mgr()

--腾讯货币管理
require("currency.currency_include")
g_currency_mgr = Currency_mgr()

require('activity_achi_tree.activity_achi_tree_include')
--成就树排行
g_achi_tree_mgr = activity_achi_tree_mgr()
g_achi_tree_mgr:db_load()

require("activity_rank.activity_rank_include")
g_activity_rank_mgr = activity_rank_mgr()
local click_activity_rank = Click(10)
click_activity_rank:regster(g_activity_rank_mgr:get_click_param())
click_activity_rank:regster(g_activity_rank_mgr:get_click_serialized_param())
click_activity_rank:start()

--全服成就
require("global_achi.global_achi_include")
g_global_achi_mgr = Global_achi_mgr()

--公测礼包
require("beta_test_reward.beta_test_reward_mgr")
g_beta_test_reward_mgr = Beta_test_reward_mgr()
g_beta_test_reward_mgr:load()

--单人离线竞技
require("offline_compete.offline_compete_include")
g_offline_compete_mgr = Offline_compete_mgr()
local click_offline_compete = Click(5)
click_offline_compete:regster(g_offline_compete_mgr:get_click_param())
click_offline_compete:start()

g_web_sql = I_Sql()
g_log = I_Log()
g_log:start(LOG_PATH)

g_common_log = Log(g_log, g_log:add("common_log"), LOG_LEVEL_LOG)
g_faction_log = Log(g_log, g_log:add("faction_log"),LOG_LEVEL_LOG)
g_chat_log = Log(g_log, g_log:add("email"))
g_statue_log = Log(g_log, g_log:add("statue_log"), LOG_LEVEL_LOG)
g_pet_adventure_log = Log(g_log, g_log:add("g_pet_adventure_log"), LOG_LEVEL_LOG)
g_pet_breed_log = Log(g_log, g_log:add("g_pet_breed_log"), LOG_LEVEL_LOG)
g_children_log = Log(g_log, g_log:add("g_children_log"), LOG_LEVEL_LOG)
g_check_log = Log(g_log, g_log:add("common" .. "_check"), LOG_LEVEL_ERROR)
g_debug_log = g_common_log  --timer需要g_debug_log

local click_game = Click(0.5)
click_game:regster(g_sock_event_mgr:get_click_param())
click_game:start()

local pulse_click = Click(3)
pulse_click:regster(g_svsock_mgr:get_click_param())
pulse_click:regster(g_authorize:get_click_param())
pulse_click:regster(g_lottery_mgr:get_click_param())
pulse_click:regster(g_spec_lottery_mgr:get_click_param())
pulse_click:regster(g_answer_mgr:get_click_param())
pulse_click:regster(g_consignment:get_click_param())
pulse_click:regster(g_marry:get_click_param())
--官职  官职res_click 121026 chendong
--pulse_click:regster(g_officer_mgr:get_click_param())
pulse_click:regster(g_control_monster:get_click_param())
--屏蔽人物竞技
--pulse_click:regster(g_human_vs_mgr:get_click_param())
pulse_click:regster(g_identify_mgr:get_click_param())
pulse_click:regster(g_collection_activity_mgr:get_click_param())
pulse_click:regster(g_activity_mgr:get_click_param())
pulse_click:regster(g_world_lvl_mgr:get_click_param())
pulse_click:regster(g_char_mgr:get_click_param())
pulse_click:regster(g_char_mgr:get_click_param_ex())
pulse_click:start()


local click_faction = Click(2)
click_faction:regster(g_faction_mgr:get_click_param())
click_faction:regster(g_faction_mgr:get_click_seralize_param(60))
click_faction:regster(g_faction_mgr:get_click_money_param(60*60*2))--60
click_faction:regster(g_pet_vs_mgr:get_click_param())
click_faction:regster(g_pet_vs_mgr:get_click_serialize_param())
click_faction:regster(g_pet_adventure_mgr:get_click_serialize_param())
click_faction:regster(g_currency_mgr:get_click_param())

--宠物繁殖
click_faction:regster(g_pet_breed_mgr:get_click_serialize_param())
click_faction:regster(g_email_mgr:get_click_param_email_ex())
click_faction:regster(Gm_email:gm_gift_param_ex())
click_faction:regster(g_faction_bag_mgr:get_click_param())
click_faction:regster(g_faction_bag_mgr:get_click_param2())
click_faction:regster(g_achi_tree_mgr:get_click_param())
click_faction:start()

-- 帮派神兽定时器
local click_faction_dogz = Click(3)
click_faction_dogz:regster(g_faction_dogz_mgr:get_click_mood_param()) -- 心情定时掉落
click_faction_dogz:regster(g_faction_dogz_mgr:get_click_data_param(60)) -- 定时保存
click_faction_dogz:regster(g_faction_dogz_mgr:get_click_reset_param(60)) -- 隔天重置
click_faction_dogz:start()

g_alarm_clock = Alarm_clock()

--帮派庭院 屏蔽 121114 chendon
--[[
local click_faction_courtyard = Click(5)
click_faction_courtyard:regster(g_faction_courtyard_mgr:get_reset_click_param(60)) -- 定时器
click_faction_courtyard:regster(g_faction_courtyard_mgr:get_data_click_param(60)) -- 定时保存数据
click_faction_courtyard:start()
--]]

--email
local click_email = Click(60)
click_email:regster(g_email_mgr:get_click_param())
--宠物繁殖
click_email:regster(g_pet_breed_mgr:get_click_serialize_param_email())
click_email:start()

local click_gift = Click(30)
click_gift:regster(Gm_email:get_click_param_gift())
click_gift:regster(g_statue_mgr:get_click_param())
click_gift:regster(check_o:get_click_param())
click_gift:start()

--一开始启动加载数据
g_email_mgr:load()
g_control_monster:load()
g_faction_mgr:load_faction()
g_faction_mgr:load_relation()
--g_faction_battle_mgr:unserialize()
g_faction_manor_mgr:unserialize()
g_pet_friend_mgr:load()
--屏蔽人物竞技
--g_human_vs_mgr:load()
g_char_mgr:load()
g_faction_bag_mgr:db_load()
--官职 官职mgrload 121113 chendong
--g_officer_mgr:load()
g_faction_dogz_mgr:load_faction_dogz() -- 加载所有帮派神兽容器信息
--帮派庭院 屏蔽 121114 chendong
--[[
g_faction_courtyard_mgr:load_db() -- 加载帮派庭院所有信息
--]]
g_global_achi_mgr:load()
g_offline_compete_mgr:load_all()

--链接其他服务器
g_svsock_mgr:connect_allserver()
local function server_start()
end

function exit_handler(signum)
	pulse_click:stop()
	click_email:stop()
	--click_gift:stop()
	--屏蔽人物竞技
	--g_human_vs_mgr:serialize_to_db()
	g_player_mgr:clear()
	g_faction_mgr:seralize_faction_ex()
	g_consignment:seralize_consignment_db()
	g_lottery_mgr:update_current_lottery()
	g_spec_lottery_mgr:update_number()
	g_collection_activity_mgr:update_all()
	g_authorize:update_current_authorize()
	g_control_monster:update_control_monster()
	g_pet_vs_mgr:serialize_to_db_ex()
	g_pet_adventure_mgr:serialize_to_db_ex()
	--g_faction_battle_mgr:serialize_all()
	g_faction_manor_mgr:serialize_all()
	--宠物繁殖
	g_pet_breed_mgr:serialize_to_db_ex()
	g_pet_friend_mgr:serialize_to_db()
	g_email_mgr:serialize_to_db()
	--官职  exit_handler 121113 chendong
	--g_officer_mgr:seralize_bid_db()
	--g_officer_mgr:seralize_officer_db()

	g_char_mgr:serialize_to_db()
	g_answer_mgr:serialize_to_db()
	g_faction_bag_mgr:timer_save(true)
	g_faction_bag_mgr:timer_save_record(true)
	g_achi_tree_mgr:do_timer(true)
	g_faction_dogz_mgr:serialize_to_db() -- 帮派神兽
	--帮派庭院 屏蔽 121114 chendon
	--[[
	g_faction_courtyard_mgr:exit_save_faction_courtyard() -- 帮派庭院
	--]]
	g_activity_rank_mgr:on_app_exit()
	g_global_achi_mgr:save()
	g_offline_compete_mgr:save_all()
	
    f_info_log("Handler Signal %d!", signum)
    ev:stop()
    g_web_sql:stop()
    g_log:stop()
	ev:sleep(3)
	f_info_log("Server Stop!")
end

function main()
	f_info_log("Server Start Running!")

	g_web_sql:start(WEB_DB_IP, WEB_DB_PORT, WEB_DB_USR, WEB_DB_PWD, WEB_DB_NAME)
	
	f_info_log("World Start Server Listen : %s:%d!", SERVER_IP, SERVER_PORT)
	if not g_server_mgr:start(SERVER_IP, SERVER_PORT) then
		f_error_log("World Server Listen %s:%d Failed!", SERVER_IP, SERVER_PORT)
		os.exit(1)
	end
	g_alarm_clock:start()

	g_alarm_clock:register(g_server_mgr, g_server_mgr.on_timer, 30, nil)
	
	if 1 == ENABLE_GATE then
		g_ww_mgr:init()
		g_alarm_clock:register(g_ww_mgr, g_ww_mgr.on_timer, 3, nil)
	end
		
	--注册热更新log函数
	register_hot_update_log_function(function(str) 
		g_common_log:write(str)
	end
	)
	print("------------>")
	ev:signal(15, exit_handler)
	ev:signal(2, exit_handler)
	g_log:start(LOG_PATH)
	
	check_o:set_log_function(function(str) g_check_log:write(str) end)
	if not _DEBUG then
		check_o:set_time_point(4)   --每天4点检测一次
	end

	ev:start()
end

main()
