
--根据等级每小时获得的经验
local lvl_expr = {}
lvl_expr[1] = {8028,30,39}        --30到39级 经验为8028（每小时）
lvl_expr[2] = {13612,40,49}       --40到49级
lvl_expr[3] = {20393,50,59}		  --50到59级
lvl_expr[4] = {71086,60,69}		  --60到69级
lvl_expr[5] = {71086,70,79}		  --70到79级	
lvl_expr[6] = {71086,80,89}		  --80到89级	
lvl_expr[7] = {71086,90,99}		  --90到99级	

--最大修练点
local MAX_POINT = 240

--玩家每天最多修练点 8点
local MAX_POINT_DAILY = 8

--玩家获取修炼点的开始等级
local B_LEVEL = 31

local ONE_DAY = 86400

local GOLD = 10000
local THIRTY_JADE = 34

--倍数
local time_p = {1,2,4,8}


Off_pr_obj = oo.class(nil,"Off_pr_obj")

function Off_pr_obj:__init(obj_id)
	self.char_id = obj_id
	self.point = 0
	self.login_time = self:get_day_time()
	self.flag = 0                 --当天是否领取 0 为未领取，1为领取
end

function Off_pr_obj:get_day_time()
	local l_time = ev.time
	local time_today ={}
	time_today.year = os.date("%Y",l_time)
	time_today.month = os.date("%m",l_time)
	time_today.day = os.date("%d",l_time)
	time_today.hour = 0
	time_today.minute = 0
	time_today.second = 0
	local t_time = os.time(time_today)
	return t_time
end

function Off_pr_obj:is_other_day(num)     --上线时判断
	if num == nil then num = 1 end
	if ev.time >= self.login_time + num * ONE_DAY then
		return true
	end
	return false
end

function Off_pr_obj:get_point()
	return self.point
end

function Off_pr_obj:set_point(point)
	self.point = point
	if self.point >= MAX_POINT then
		self.point = MAX_POINT
	end
	self:update_char()
end

function Off_pr_obj:get_expr_cmp_level(player_level)   --获取基础经验值
	if player_level < B_LEVEL then return 0 end

	for k,v in pairs(lvl_expr or {}) do
		if player_level >= v[2] and player_level <= v[3] then
			return v[1]
		end
	end
	return 0
end

function Off_pr_obj:get_level()
	if self.char_id == 0 then
		return 1
	end
	local player = g_obj_mgr:get_obj(self.char_id)
	return player:get_level()
end

function Off_pr_obj:get_expr()
	local level = self:get_level()
	return  self.point * self:get_expr_cmp_level(level)
end


function Off_pr_obj:can_be_fetch()
	if self.point <= 0 or self.point ==nil then
		return nil
	end
	return 0
end

function Off_pr_obj:fetch_point(type)
	local time = time_p[type]
	if time ~= nil then
		local player = g_obj_mgr:get_obj(self.char_id)
		if not player then return end

		local addition = player:get_addition(HUMAN_ADDITION.offline_exp)
		if addition < 0 then return end
		local expr = math.floor(time * self:get_expr() * (addition + 1))
		player:add_exp(expr)
		self:set_point(0)
		return expr
	end
	return 0
end

function Off_pr_obj:get_fetch_expr()
	local time = time_p[1]
	if time ~= nil then
		local player = g_obj_mgr:get_obj(self.char_id)
		if not player then return end

		local addition = player:get_addition(HUMAN_ADDITION.offline_exp)
		if addition < 0 then return end
		local expr = math.floor(time * self:get_expr() * (addition + 1))
		return expr
	end
	return 0
end


function Off_pr_obj:update_level()
	if self:get_level() == B_LEVEL then
		self:set_point(self.point + MAX_POINT_DAILY)
		self:update_char()
	end
end


function Off_pr_obj:login()
	if self:is_other_day() then
		if self:get_level() > B_LEVEL then
			local time_l = ev.time - self.login_time
			local num = math.floor(time_l / ONE_DAY)
			self:set_point(self.point + num * MAX_POINT_DAILY)
		end
		self.login_time = self:get_day_time()
		self.flag = 1
		self:update_char()
	else
		if self.flag == 0 then
			if self:get_level() > B_LEVEL then
				self:set_point(self.point + MAX_POINT_DAILY)
			end
			self.flag = 1
			self:update_char()
		end
	end	
end

function Off_pr_obj:get_net_info()
	local ret = {}
	if self.point == nil or self.point < 0 then
		self.point = 0
	end

	ret.point = self:get_point() / 8
	ret.expr  = self:get_expr()
	return ret
end

--获取所需钱
function Off_pr_obj:get_monye(type)
	if type == 2 then
		return GOLD
	elseif type == 3 then
		return THIRTY_JADE
	end
	return 0
end

--获取经验倍数
function Off_pr_obj:get_expmu(type)
	if time_p[type] then
		return time_p[type]
	else
		return 1
	end
end

------------------------------数据库---------------------------
function Off_pr_obj:insert_char()
	local dbh = f_get_db()
	local data = {}
	data.char_id = self.char_id
	data.point = self.point or 0
	data.login_time = self.login_time or 0
	data.flag = self.flag or 0

	local err_code = dbh:insert("offline_practice",Json.Encode(data))

end

function Off_pr_obj:update_char()
	local dbh = f_get_db()
	local data = {} --string.format("{left_time:%d,leave_time:%d}",left_time,leave_time)
	data.point = self.point or 0
	data.login_time =  self.login_time or 0
	data.flag = self.flag or 0
	local query = string.format("{char_id:%d}",self.char_id)

	dbh:update("offline_practice",query,Json.Encode(data),true)

end
