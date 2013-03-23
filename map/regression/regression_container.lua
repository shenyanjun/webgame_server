
require("regression.regression_db")
local authorize_loader = require("config.loader.authorize_loader")
local integral_func=require("mall.integral_func")

Regression_container = oo.class(nil, "Regression_container")

local need_jade = 25
local need_gold = 20000
local embrace_limit = 20
local accumulate = 30

local lvl_exp = {}
lvl_exp[30] = 1049800
lvl_exp[37] = 1197048
lvl_exp[45] = 2161080
lvl_exp[55] = 3986520
lvl_exp[65] = 6810800
lvl_exp[70] = 10917200
lvl_exp[90] = 10917200
lvl_exp[110] = 10917200
local lvl_cord = {30, 37, 45, 55, 65, 70, 90, 110}

local authorize_list = {"HELP_0001", "HELP_0002", "HELP_0003", "HELP_0004"}
-----------------------------------回归-----------------------------
--定时存盘时间
local update_time = 20


function Regression_container:__init(char_id, first_login)
	self.char_id	= char_id
	--self:load(first_login)
end

function Regression_container:load(first_login)
	local player = g_obj_mgr:get_obj(self.char_id)
	local level = player:get_level()

	local rows
	if not first_login then
		rows = Regression_db:select_regression(self.char_id)
	end

	if rows then
		for k, v in pairs(rows) do
			self.leave = v.leave
			self.days = v.days
			for kk, vv in ipairs(authorize_list) do
				self[vv] = v[vv]
			end
			if not self.leave then
				 self.leave = Regression_db:get_record_time()
			end
			break
		end
	else
		self.leave 	= Regression_db:get_record_time()
	end
	if not self.days then
		self.days = 0
	end
	if not self.update_time then
		self.update_time = f_get_today()
		self.embrace_cnt = 0
	else
		if self.update_time < f_get_today() then
			self.update_time = f_get_today()
			self.embrace_cnt = 0
		end
	end
	if player:get_level() >= 35 then
		local day = self:get_leave_day()
		if day > 0 then			--需要补偿
			self.days = self.days + day
			if self.days > accumulate then
				self.days = accumulate
			end
			self:update()
			
			local sql_str = string.format("insert log_free set char_id = %d, char_name='%s', project=%d, days=%d, time=%d",
					self.char_id, player:get_name(), 4, day, os.time())
			f_multi_web_sql(sql_str)
		end
		--屏蔽回归拥抱
		--if day >= 3 then
			--local t_pkt = {}
			--t_pkt.char_id = self.char_id
			--g_svsock_mgr:send_server_ex(COMMON_ID, self.char_id, CMD_OLDPLAYER_REGRESSION_M, t_pkt)
		--end
	end

end

function Regression_container:get_leave_day()
	return math.floor((f_get_today(ev.time) - f_get_tomorrow(self.leave)) /86400)
end

--存盘
function Regression_container:update()
	local tmp_table = {}
	tmp_table.leave = self.leave
	tmp_table.days	= self.days
	tmp_table.char_id = self.char_id
	tmp_table.update_time = self.update_time
	tmp_table.embrace_cnt = self.embrace_cnt
	for k, v in ipairs(authorize_list) do
		tmp_table[v] = self[v]
	end
	
	Regression_db:update_regression(tmp_table)
end

--离线保存
function Regression_container:save()
	local player = g_obj_mgr:get_obj(self.char_id)
	--if player:get_level() < 35 then
		--return
	--end
	self.leave = ev.time

	self:update()

	return
end

-------------------------------------与map交互命令---------
--获取等级对应的活动经验
function Regression_container:get_activity_exp(lvl)
	local tmp_lvl = 30
	for i = 1, table.getn(lvl_cord) do
		if lvl <= lvl_cord[i] then
			tmp_lvl = lvl_cord[i]
			break
		end
	end
	
	return lvl_exp[tmp_lvl] or 0
end

--获取信息
function Regression_container:get_regression_info()
	local tmp_table = {}
	local player = g_obj_mgr:get_obj(self.char_id)
	local lvl = player and player:get_level()
	if lvl == nil or lvl < 35 then
		tmp_table.result = 0
		return tmp_table
	end

	tmp_table.exp = self:get_activity_exp(lvl)
	tmp_table.days = self.days or 0

	tmp_table.list = {}
	for k, v in ipairs(authorize_list) do
		tmp_table.list[v] = self[v]
	end
	tmp_table.result = 0

	return tmp_table
end

--免费获取委托补偿
function Regression_container:get_authorize_reward(pkt)
	local flags = false
	local authorize_id 
	local counts = 0

	local player = g_obj_mgr:get_obj(self.char_id)
	local lvl = player:get_level()
	if lvl < 35 then
		return 20771
	end

	for k, v in pairs(pkt) do
		authorize_id = k
		counts = v
		break
	end
	for i = 1, table.getn(authorize_list) do
		if authorize_list[i] == authorize_id then
			flags = true
			break
		end
	end
	if not flags then 
		return 20772
	end  
	if counts < 1 or not self[authorize_id] or counts > self[authorize_id] then 
		return 20773
	end

	local reward = authorize_loader.get_authorize_reward(authorize_id)
	local exp = reward.exp * counts * 0.5
	if player:is_add_exp(exp) then
		self[authorize_id] = self[authorize_id] - counts
		if self[authorize_id] < 0 then
			self[authorize_id] = 0
		end
		self:update()
		player:add_exp(exp)

		local sql_str = string.format("insert log_free set char_id = %d, char_name='%s', faction_id='%s', project=%d, type=%d, num=%d, exp=%d, time=%d",
					self.char_id, player:get_name(), authorize_loader.get_authorize_scene(authorize_id), 1, 1, counts, exp, os.time())
		f_multi_web_sql(sql_str)
	else
		return 20774
	end

	return 0
end

--获取活动补偿
function Regression_container:get_activity_reward(pkt)
	local player = g_obj_mgr:get_obj(self.char_id)
	local pack_con = player:get_pack_con()
	local lvl = player:get_level()
	if lvl < 35 then
		return 20771
	end
  	local days = pkt.days
	if days < 1 or not self.days or days > self.days then 
		return 20775
	end

	local total_exp = self:get_activity_exp(lvl) * days
	local exp = 0
	local moneylist = {}
	local flags = false
	local FL = 0
	local need_money = 0
	if pkt.type == 1 then
		exp = total_exp * 0.5
	elseif pkt.type == 2 then
		moneylist[1] = days * need_gold
		need_money = days * need_gold
		exp = total_exp * 0.8
		flags = true
	elseif pkt.type == 3 then
		moneylist[3] = days * need_jade
		need_money = days * need_jade
		exp = total_exp
		flags = true
		FL = days * need_jade
	else
		return 1
	end
	if not player:is_add_exp(exp) then
		return 20774
	end

	if flags then
		local e_code = pack_con:dec_money_l_inter_face(moneylist, {['type']=MONEY_SOURCE.REGRESSION})
		if e_code ~= 0 then
			return e_code
		end
		if FL ~= 0 then
			integral_func.add_bonus(self.char_id, FL, {['type']=MONEY_SOURCE.REGRESSION})
		end
	end

	self.days = self.days - days
	self:update()
	
	player:add_exp(exp)

	local sql_str
	if pkt.type == 1 then
		sql_str = string.format("insert log_free set char_id = %d, char_name='%s', project=%d, type=%d, exp=%d, days=%d, time=%d",
				self.char_id, player:get_name(), 2, 1, exp, days, os.time())
	elseif pkt.type == 2 then
		sql_str = string.format("insert log_free set char_id = %d, char_name='%s', project=%d, type=%d, money=%d, num=%d,exp=%d, days=%d, time=%d",
				self.char_id, player:get_name(), 2, 2, 1, need_money, exp, days, os.time())
	else
		sql_str = string.format("insert log_free set char_id = %d, char_name='%s', project=%d, type=%d, money=%d, num=%d, exp=%d, days=%d, time=%d",
				self.char_id, player:get_name(), 2, 3, 3, need_money, exp, days, os.time())	
	end
	f_multi_web_sql(sql_str)
	return 0
end

--获取拥抱经验
function Regression_container:get_embrace_exp()
	local player = g_obj_mgr:get_obj(self.char_id)

	if not self.update_time then
		self.update_time = f_get_today()
		self.embrace_cnt = 0
	else
		if self.update_time < f_get_today() then
			self.update_time = f_get_today()
			self.embrace_cnt = 0
		end
	end

	if self.embrace_cnt >= embrace_limit then
		return 20778
	end

	local lv = player:get_level()
	local exp = 2000 * math.floor(lv/5)

	if player:is_add_exp(exp) then
		player:add_exp(exp)
		self.embrace_cnt = self.embrace_cnt + 1
		self:update()
		return 0, exp
	else
		return 20774
	end
end

--获取被拥抱经验
function Regression_container:get_embraced_exp()
	local player = g_obj_mgr:get_obj(self.char_id)
	local lv = player:get_level()
	local exp = 2000 * math.floor(lv/5)

	if player:is_add_exp(exp) then
		player:add_exp(exp)
		return 0, exp
	else
		return 20774
	end
end

--花费获取委托补偿
function Regression_container:authorize_entrust(pkt)
	local flags = false
	local authorize_id = pkt.authorize_id
	local counts = pkt.count

	local player = g_obj_mgr:get_obj(self.char_id)
	local pack_con = player:get_pack_con()
	local lvl = player:get_level()
	if lvl < 35 then
		return 20771
	end

	for i = 1, table.getn(authorize_list) do
		if authorize_list[i] == authorize_id then
			flags = true
			break
		end
	end
	if not flags then 
		return 20772
	end  

	--检查次数
	if counts < 1 or not self[authorize_id] or counts > self[authorize_id] then 
		return 20773
	end

	local reward = authorize_loader.get_authorize_reward(authorize_id)
	local exp = reward.exp * counts
	if player:is_add_exp(exp) then
		--检查委托令
		local contracts = authorize_loader.get_authorize_contract(authorize_id) * counts
		local e_code = pack_con:del_item_by_item_id_inter_face(202001606041, contracts, {['type'] = ITEM_SOURCE.DO_AUTHORIZE}, 1)
		if e_code ~= 0 then return e_code end

		self[authorize_id] = self[authorize_id] - counts
		if self[authorize_id] < 0 then
			self[authorize_id] = 0
		end
		self:update()	

		player:add_exp(exp)

		local args = {}
		args.count = counts
		g_event_mgr:notify_event(EVENT_SET.EVENT_AUTHORIZE, self.char_id, args)

		sql_str = string.format("insert log_free set char_id = %d, char_name='%s', project=%d, type=%d, faction_id='%s', num=%d, exp=%d, time=%d",
				self.char_id, player:get_name(), 1, 4, authorize_loader.get_authorize_scene(authorize_id), counts, exp, os.time())	
		f_multi_web_sql(sql_str)

		return 0, pkt
	else
		return 20774
	end
end

--获取需要的的钱跟奖励经验
function Regression_container:get_all_activity_reward(type)
	if self.char_id == 0 then
		return 0, 0
	end
	local player = g_obj_mgr:get_obj(self.char_id)
	local pack_con = player:get_pack_con()
	local lvl = player:get_level()
	local exp = 0
	local need_money = 0

	if lvl < 35 then
		return need_money,exp
	end
	if not self.days or self.days == 0 then 
		return need_money,exp
	end
	local total_exp = self:get_activity_exp(lvl) * self.days
	local flags = false
	local FL = 0	

	if type == 2 then
		need_money = self.days * need_gold
		exp = total_exp * 0.8
	elseif type == 3 then
		need_money = self.days * need_jade
		exp = total_exp
	end
	return need_money,exp
end

function Regression_container:updatedb_days()
	self.days = 0
	self:update()
end