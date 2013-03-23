--2010-01-20
--laojc
--奖励基类

local ONE_DAY = 86400
local database = "reward"

Reward = oo.class(nil,"Reward")

function Reward:__init(obj_id)
	self.char_id = obj_id
	self.type = 0             --登录奖励类型
	self.day = 0              --连续登录天数
	self.flag = 0             --是否已领取 0 为未领取
	self.login_time = self:get_day_time()
	self.item_list = self:get_random_item()
end


--------------------------------------基本操作-------------------------------------------

function Reward:get_random_item()

end

function Reward:get_flag()
	return self.flag
end

function Reward:set_flag(flag)
	self.flag = flag
	self:update_char()
end

function Reward:is_fetch()
	if self.flag == 1 then
		return true
	end
	return false
end

function Reward:can_be_fetch()
	if self:is_fetch() then return 27601 end
	return 0
end

function Reward:fetch_item()
	local item = self.item_list
	if item == nil then return end ----------------没到制定节日时间

	local player = g_obj_mgr:get_obj(self.char_id)
	local pack_con = player:get_pack_con()
	
	local item_id_list = {}
	--for k,v in pairs(item or {})do
		item_id_list[1] = {}
		item_id_list[1].type = 1
		item_id_list[1].item_id = item[1]
		item_id_list[1].number = item[2]
	--end

	local free_slot = pack_con:get_bag_free_slot_cnt()
	if free_slot <=0  then
		return 43004
	end

	if pack_con:add_item_l(item_id_list, {['type']=ITEM_SOURCE.HOLIDAY}) ~= 0 then
		return 27003
	end
	self:set_flag(1)
	return 0
end

function Reward:get_day_time()
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

function Reward:is_other_day(num)     --上线时判断
	if num == nil then num = 1 end
	if ev.time >= self.login_time + num * ONE_DAY then
		return true
	end
	return false
end

------------------------------------------滴答------------------------------------------------------
function Reward:on_timer(time_span)
	
end

function Reward:get_click_param()
end

--登录
function Reward:login()
	if self:is_other_day() then
		self.login_time = self:get_day_time()
		self:set_flag(0)
		self.item_list = self:get_random_item()
		self:update_char()
	end		
end

--下线
function Reward:leave()
	self:update_char()
end

----------------------------------------数据读写-----------------------------------------------------

function Reward:select_char()
	local dbh = f_get_db()
	--local data = "{flag:1}"
	local query =string.format("{char_id:%d,type:%d}",self.char_id,self.type)

	local row, e_code = dbh:select_one(database, nil, query)
	if e_code == 0 then
		return row
	end 
	return nil
end

function Reward:insert_char()
	local dbh = f_get_db()
	local t_list = {}
	t_list.char_id = self.char_id
	t_list.flag = self.flag
	t_list.type = self.type
	t_list.day = self.day
	t_list.login_time = self.login_time
	t_list.item_list = self.item_list
	
	local err_code = dbh:insert(database,Json.Encode(t_list))       
	if err_code == 0 then
		return true
	end
	return false
end

function Reward:update_char()
	local dbh = f_get_db()
	local data = {} --string.format("{flag:%d,day:%d,login_time:%d,item_list:'%s'}",self.flag,self.day,self.login_time,Json.Encode(self.item_list or {}))
	data.flag = self.flag
	data.day = self.day
	data.login_time = self.login_time
	data.item_list = self.item_list or {}
	data.type = self.type 
	data.char_id = self.char_id


	local query = string.format("{type:%d,char_id:%d}",self.type,self.char_id)

	local err_code = dbh:update(database,query,Json.Encode(data),true)
	if err_code == 0 then
		return true
	end
	return false
end


-----------------------------------------------基本信息------------------------------------------------------

function  Reward:get_net_info()
	local ret = {}
	ret[1] = self.type
	ret[2] = self.flag
	if self.item_list == nil then
		ret[3] = 0
		ret[4] = 0
	else
		if self.flag == 0 and self.item_list ~= nil and table.size(self.item_list) == 0 then
			self.item_list = self:get_random_item() or {}
		end
		ret[3] = self.item_list[1] or 0
		ret[4] = self.item_list[2] or 0
	end
	ret[5] = self.day or 0

	return ret
end