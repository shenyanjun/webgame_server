
local filter_loader = require("config.loader.filter_loader")

App_filter = oo.class(nil, "App_filter")

function App_filter:__init()
	self.sort_list = {}

	self.faction_id = nil
end

function App_filter:get_faction_id()
	return self.faction_id
end

function App_filter:set_faction_id(f_id)
	self.faction_id = f_id
end

function App_filter:set_sort_list(sort_list)
	self.sort_list = sort_list
end

function App_filter:syn_info(faction_id,sort_list)
	self:set_faction_id(faction_id)
	self:set_sort_list(sort_list)
end

--对外接口 判断玩家可以进入战场
function App_filter:is_on_application(char_id)
	for k,v in pairs(self.sort_list or {}) do
		if v == char_id then
			return true
		end
	end
	return false
end

--报名条件
function App_filter:is_application_ok(char_id)
	--是否有帮派
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	if faction == nil then return 20850 end

	if self.faction_id == faction:get_faction_id() then return 20851 end
	if self.faction_id == nil or self.faction_id == "" then return 20852 end

	local player = g_obj_mgr:get_obj(char_id)
	if not player then return end
	local pack_con = player:get_pack_con()
	
	--金钱
	local app_money = filter_loader.condition.money
	if app_money > pack_con:get_money().gold then return 20853 end

	--等级
	local app_level = filter_loader.condition.level
	local player_level = player:get_level()
	if app_level > player_level then return 20854 end

	--时间段
	local start_time = filter_loader.start_time
	local end_time = filter_loader.end_time
	local l_time = ev.time
	local hour = os.date("%H",l_time)
	local minute = os.date("%M",l_time)
	local second = os.date("%S",l_time)

	local sec_sum = second + minute * 60 + hour * 3600
	local sec_start = start_time.sec + start_time.min * 60 + start_time.hour * 3600
	local sec_end = end_time.sec + end_time.min * 60 + end_time.hour * 3600

	if sec_sum >= sec_start and sec_sum <= sec_end then return 20855 end

	return 0

end

--报名
function App_filter:get_application_info(char_id)
	local player = g_obj_mgr:get_obj(char_id)
	if not player then return end
	local pack_con = player:get_pack_con()

	local ret = {}
	ret.money = pack_con:get_money().gold
	ret.fight = player:get_fighting()
	ret.vip = g_vip_mgr:get_vip_info(char_id)

	--扣钱
	local app_money = filter_loader.condition.money
	pack_con:dec_money(MoneyType.GOLD, app_money, {['type']=MONEY_SOURCE.FACTION_APPLICATION})
	return ret
end


--战场开始广播
function App_filter:war_begin_bdc()
	if self.faction_id == "" or self.faction_id == nil then return end

	local pkt = {}
	pkt.type = 1

	local faction = g_faction_mgr:get_faction_by_fid(self.faction_id)
	if faction == nil then return end
	local player_list = faction:get_faction_player_list()
	local obj_mgr = g_obj_mgr
	for k, v in pairs(player_list or {}) do
		local player = obj_mgr:get_obj(k)
		if player then
			g_cltsock_mgr:send_client(k,CMD_M2B_APPLICATION_WAR_C ,pkt)
		end
	end

	for m, n in pairs(self.sort_list or {}) do
		local player = obj_mgr:get_obj(n)
		if player then
			g_cltsock_mgr:send_client(n,CMD_M2B_APPLICATION_WAR_C ,pkt)
		end
	end

end

App_filter:__init()