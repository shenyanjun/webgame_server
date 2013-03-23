--2012-8-8
--zhengyg
--activity_rank_mgr in common_server

local _rank_cfg = require("activity_rank.activity_rank_loader")
local _builder_list = create_local("activity_rank._builder_list", {})

ACTIVITY_RANK_TYPE = { --对于同一种排行 同一时刻只能存在一个
	RANK_CHARM = 1, --魅力排行
	RANK_MAX = 1
}


function register_activity_rank_builder(type,cls)
	_builder_list[type] = cls
end

function get_activity_rank_builder(type)
	return _builder_list[type]
end

activity_rank_mgr = oo.class(nil,"activity_rank_mgr")

function activity_rank_mgr:__init()
	self.activity_list = {}
	--build rank obj
	for type = 1 ,  ACTIVITY_RANK_TYPE.RANK_MAX do
		self.activity_list[type] = get_activity_rank_builder(type)()
	end
end

function activity_rank_mgr:syn_map_config(server_id) --广播活动配置(开关配置)
	for type, activity_o in pairs(self.activity_list) do
		activity_o:syn_map_config(server_id)
	end
end

function activity_rank_mgr:get_click_param()
	return self, self.on_timer, 21, nil
end

function activity_rank_mgr:on_timer()
	self:do_timer()
end

function activity_rank_mgr:do_timer()
	for type, activity in pairs(self.activity_list) do
		activity:do_timer()
	end
	self:syn_map_config()
end

function activity_rank_mgr:get_click_serialized_param()
	return self, self.on_timer_serialize, 17*60, nil --到时发版本要再调一下时间,调长一点 
end

function activity_rank_mgr:on_timer_serialize()
	self:do_timer_serialize()
end

function activity_rank_mgr:do_timer_serialize()
	for type, activity in pairs(self.activity_list) do --所有类型的活动数据存盘
		activity:serialize()
	end
end

function activity_rank_mgr:on_app_exit()
	self:do_timer_serialize()
end

function activity_rank_mgr:syn_map_rank_data(server_id)
	for type, activity in pairs(self.activity_list) do
		if activity.turn_on then
			activity:syn_map_rank_data(server_id)
		end
	end
end

function activity_rank_mgr:update_rank_info(pkt)
	if self.activity_list[pkt.type].turn_on and self.activity_list[pkt.type].id == pkt.id then
		self.activity_list[pkt.type]:update_rank_info(pkt)
	else
		self:syn_map_config()
	end
end

--[[
排行活动数据表结构

表一：
activity_rank 排行活动玩家信息表
索引: char_id:1
字段 
	char_id:
	activity_list:活动数据表，以活动类型为键(魅力榜为1),
	值:
		tm,上一次魅力值发生改变的时候， 
		charm，活动期间内累计的魅力值
		today,玩家上一次退出游戏当天的开始时间戳（f_get_today(ev.time)）
		today_charm,当天的魅力累积值
		id,活动id
合服，从服数据转换char_id后直接拷贝到主服。

表二:
activity_rank_sum 排行活动统计总表
索引 type:1
字段:
	type:排行类型，1表示魅力排行活动 2其他
	id:	活动id，
	reward:储存已经发过的奖励id
	sort:数组，总榜元素结构{char_id, cnt, timestamp}
	sort_pre:数组，昨日榜结构{char_id, cnt, timestamp, day_begin_timestamp}
	sort_today:数组，今日榜 结构与昨日榜一至
	today:时间戳 启动服务器时判断这个值来重置昨日榜与今日榜的数据
合服：保留 type id reward today

--]]
