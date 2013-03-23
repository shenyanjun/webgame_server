--每日活动面板类

local activity_loader = require("function.activity_loader")

local database = "func"
local ONE_DAY = 86400
local limit_minlv = 30

Function_container = oo.class(nil,"Function_container")

function Function_container:__init(char_id)
	self.char_id = char_id
	self.lv_up   = {}   --升级
	self.money   = {}	--赚钱
	self.ability = {}	--实力
	self.daren   = {}	--达人
	self.login_time = self:get_day_time()
	self.sign = 0

	self.act_lv = 0
	self.level  = 0
end

function Function_container:load()
	local player = g_obj_mgr:get_obj(self.char_id)
	if not player then return end	
	self.level = player:get_level()
	if self.level < limit_minlv then return 0 end
	self.act_lv = self:get_act_lv()

	local dbh = f_get_db()
	local query = string.format("{char_id:%d}",self.char_id)
	local rows, e_code = dbh:select(database, nil, query)
	if e_code == 0 and rows ~= nil then
		for i,v in pairs(rows or {}) do
			if v.lv_up and v.money and v.ability and v.daren and v.sign then
				self.login_time = v.login_time or self:get_day_time()
				self.lv_up		= v.lv_up	
				self.money		= v.money
				self.ability	= v.ability
				self.daren		= v.daren
				self.sign       = v.sign or 0

				if self.sign ~= activity_loader.get_sign() then
					self:updata_activity(activity_loader.get_sign())
				end
				self:login()
			else
				self:refresh_data(self.act_lv,1)
			end
		end
	else
		self:refresh_data(self.act_lv,1)
	end
	return 0
end

function Function_container:level_up_init()
	local player = g_obj_mgr:get_obj(self.char_id)
	if not player then return end	
	self.level = player:get_level()
	self.act_lv = self:get_act_lv()
	self:refresh_data(self.act_lv,1)

	return 0
end

function Function_container:get_day_time()
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

--同步数据
function Function_container:get_net_info()
	local ret = {}
	ret.daily_list = {}
	ret.daily_flag = {}
	self:com_net_list_info(self.lv_up,   ret.daily_list,   ret.daily_flag,   activity_loader.ACT_LV_UP)
	self:com_net_list_info(self.money,   ret.daily_list,   ret.daily_flag,   activity_loader.ACT_MK_MONEY)
	self:com_net_list_info(self.ability, ret.daily_list,   ret.daily_flag,   activity_loader.ACT_UP_AB)
	self:com_net_list_info(self.daren,   ret.daily_list,   ret.daily_flag,   activity_loader.ACT_DAREN)
	return ret
end

function Function_container:com_net_list_info(data,list,flag,act_type)
	for i,v in pairs(data) do
		if i ~= "flag" then
			list[i] = v
		else
			flag[act_type] = v
		end
	end
end

function Function_container:com_db_info(data)
	for i,v in pairs(data) do
		if i ~= "flag" then
			data1[i] = v.count
		end
	end
end

--下线保存
function Function_container:save()
	self:update_char()
end

--读写数据
function Function_container:update_char()
	if self.level < limit_minlv then return end
	local result = {} 
	result.lv_up 	= self.lv_up or {}
	result.money	= self.money or {}
	result.ability  = self.ability or {}
	result.daren	= self.daren  or {}
	result.login_time = self.login_time or self:get_day_time()
	result.sign     = self.sign
	

	local dbh = f_get_db()
	local query = string.format("{char_id:%d}",self.char_id)
	local err_code = dbh:update(database,query,Json.Encode(result),true)
end

--刷新数据
function Function_container:refresh_data(lv,type)
	self.lv_up   = self:clear_info(activity_loader.get_currer_activity(activity_loader.ACT_LV_UP,   lv))
	self.money   = self:clear_info(activity_loader.get_currer_activity(activity_loader.ACT_MK_MONEY,lv))
	self.ability = self:clear_info(activity_loader.get_currer_activity(activity_loader.ACT_UP_AB,   lv))
	self.daren   = self:clear_info(activity_loader.get_currer_activity(activity_loader.ACT_DAREN,   lv))
	self.login_time 	= self:get_day_time()
	if type then
		self.sign		= activity_loader.get_sign()
	end
end

--更新人物活动内容
function Function_container:updata_activity(sign)
	if sign then
		self.sign = sign 
	end

	self.lv_up = self:updata_activity_info(self.lv_up,     activity_loader.get_currer_activity(activity_loader.ACT_LV_UP,   self.act_lv))
	self.money = self:updata_activity_info(self.money,     activity_loader.get_currer_activity(activity_loader.ACT_MK_MONEY,self.act_lv))
	self.ability = self:updata_activity_info(self.ability, activity_loader.get_currer_activity(activity_loader.ACT_UP_AB,   self.act_lv))
	self.daren = self:updata_activity_info(self.daren,     activity_loader.get_currer_activity(activity_loader.ACT_DAREN,   self.act_lv))
	
end

function Function_container:clear_info(end_data)
	local temp = {}
	for i,v in pairs(end_data) do
		temp[i] = 0
	end
	temp.flag = 0
	return temp
end

function Function_container:updata_activity_info(res_data,end_data)
	local temp = {}
	for i,v in pairs(end_data) do
		temp[i] = 0
	end

	for c,d in pairs(res_data) do
		if temp[c] then
			temp[c] = d
		end
	end
	temp.flag = res_data.flag or 0	
	return temp
end

--上线时判断
function Function_container:is_other_day(num)     
	if num == nil then num = 1 end
	if ev.time >= self.login_time + num * ONE_DAY then
		return true
	end
	return false
end

--登陆判断是否隔天
function Function_container:login()
	if self.level < limit_minlv then return end
	if not self:is_other_day() then return end
	self:refresh_data(self.act_lv)
end

--玩家升级通知
function Function_container:level_up(args)
	self.level = args and args.level
	self.act_lv = self:get_act_lv() 
	if self.level < limit_minlv then return end 
	self:updata_activity(activity_loader.get_sign())
end

--押镖
function Function_container:task(args)
	local is_done = false
	if args.type == 5 then
		self:add_act_count("day003", args.count)
		is_done = true
	elseif args.type == 4 and args.flag == 3 
		or args.type == 4 and args.flag == 2 then
		self:add_act_count("day002", args.count)
		is_done = true
	elseif args.type == 6 then
		self:add_act_count("day001", args.count)
		is_done = true
	end
	if is_done then
		local ret = self:get_net_info()
		ret.result = 0
		g_cltsock_mgr:send_client(self.char_id, CMD_M2B_FUNC_DAILY_S, ret)
	end
end

--进战场 温泉
function Function_container:war_in(args)
	--print("war_in :",j_e(args))
	if not args.map_id then return end
	local act_type = activity_loader.get_act_sceneid(args.map_id)
	if act_type == 0 then return end
	self:add_act_count(act_type)
end

--进副本
function Function_container:enter_copy(args)
	--print("Function_container:enter_copy", args.scene_id)
	if not args.scene_id then return end
	local act_type = activity_loader.get_act_mapid(args.scene_id)
	if act_type == 0 then return end
	self:add_act_count(act_type)
end

--答题
function Function_container:anwser()  --day008
	self:add_act_count("day008")
end

--宠物闯关
function Function_container:pet_doushou()  --day004
	self:add_act_count("day004")
end

--添加次数
function Function_container:add_act_count(act_type, num)
	local count = num or 1
	local flag = 0
	if self.lv_up[act_type] then
		self.lv_up[act_type] = self.lv_up[act_type] + count
	elseif self.money[act_type] then
		self.money[act_type] = self.money[act_type] + count
	elseif self.ability[act_type] then
		self.ability[act_type] = self.ability[act_type] + count
	elseif self.daren[act_type] then
		self.daren[act_type] = self.daren[act_type] + count
	end
end

function Function_container:do_reward(id)
	if id == activity_loader.ACT_LV_UP then
		if self:can_do_reward(self.lv_up,id) then
			return self:send_reward(activity_loader.get_reward(id,self.act_lv),activity_loader.ACT_LV_UP,self.lv_up)
		end
	elseif id == activity_loader.ACT_MK_MONEY then
		if self:can_do_reward(self.money,id) then
			return self:send_reward(activity_loader.get_reward(id,self.act_lv),activity_loader.ACT_MK_MONEY,self.money)
		end
	elseif id == activity_loader.ACT_UP_AB then
		if self:can_do_reward(self.ability,id) then
			return self:send_reward(activity_loader.get_reward(id,self.act_lv),activity_loader.ACT_UP_AB,self.ability)
		end
	elseif id == activity_loader.ACT_DAREN then
		if self:can_do_reward(self.daren,id) then
			return self:send_reward(activity_loader.get_reward(id,self.act_lv),activity_loader.ACT_DAREN,self.daren)
		end
	end
	return 27003
end

function Function_container:can_do_reward(table,type)
	if not table.flag or table.flag ~= 0 then return false end
	local temp = activity_loader.get_currer_activity(type,self.act_lv)
	for i,v in pairs(temp) do
		if i ~= "flag" and table[i] < temp[i] then
			return false
		end
	end
	return true
end

function Function_container:send_reward(item_list,type_t,table)
	local player = g_obj_mgr:get_obj(self.char_id)
	if not player then return end			
	local pack_con = player:get_pack_con()
	if pack_con then
		local new_item_list = {}
		local count = 1
		for k,v in pairs(item_list or {})do
			new_item_list[count] = {}
			new_item_list[count]["item_id"]= k
			new_item_list[count]["type"]   = 1
			new_item_list[count]["number"] = v
			count = count + 1
		end
		if pack_con:add_item_l(new_item_list,{['type']=ITEM_SOURCE.FUNCTION_GIFT}) ~= 0 then  
			return 27003
		end
		table.flag = 1
		f_multi_web_sql(string.format("insert into log_everyday_do set char_id = %d, char_name = '%s', level = %d, type = %d, time = %d",
		self.char_id, player:get_name(), player:get_level(), type_t, os.time()))
	end
	return 0
end

function Function_container:get_act_lv()
	return activity_loader.get_currer_lv(self.level)
end