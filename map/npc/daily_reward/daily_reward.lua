--2011-03-17
--laojc
--npc每日奖励

local database = "npc_reward"
local ONE_DAY = 86400
local ACTION_ID_LIST = {"AC_26001"}

Daily_reward = oo.class(nil,"Daily_reward")


function Daily_reward:__init(obj_id)
	self.char_id = obj_id
	self.login_time = self:get_day_time()
	self.action_list = {}
	for k,v in pairs(ACTION_ID_LIST) do
		self.action_list[k] = 0
	end
end

function Daily_reward:set_flag(index,flag)
	self.action_list[index] = flag
	self:update_char()
end

function Daily_reward:get_flag(index)
	return self.action_list[index]
end

function Daily_reward:init_action()
	
end

function Daily_reward:get_day_time()
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


function Daily_reward:can_be_fetch(action_id)
	local index = 0
	for k,v in pairs(ACTION_ID_LIST) do
		if action_id == v then
			index = k
			break
		end
	end

	if self.action_list[index] == 0 then
		return 0
	end
	return 27601
end


function Daily_reward:fetch_item(action_id,item)
	local index = 0
	for k,v in pairs(ACTION_ID_LIST) do
		if action_id == v then
			index = k
			break
		end
	end
	if index ~= 0 then
		local player = g_obj_mgr:get_obj(self.char_id)
		local pack_con = player:get_pack_con()
		
		local item_id_list = {}
		for k,v in pairs(item or {})do
			item_id_list[k] = {}
			item_id_list[k].type = 1
			item_id_list[k].item_id = v[1]
			item_id_list[k].number = v[2]
		end

		--local free_slot = pack_con:get_bag_free_slot_cnt()
		--if free_slot <=0  then
			--return 43004
		--end

		
		if pack_con:add_item_l(item_id_list, {['type']=ITEM_SOURCE.NPC_DAILY_REWARD}) ~= 0 then
			return 27003
		end

		self:set_flag(index,1)
		return 0
	end
	return ERROR_NPC_ACTION_NOT_RIGHT
end


function Daily_reward:is_other_day(num)     --上线时判断
	if num == nil then num = 1 end
	if ev.time >= self.login_time + num * ONE_DAY then
		return true
	end
	return false
end



--登录
function Daily_reward:login()
	
	for k,v in pairs(ACTION_ID_LIST) do
		if self.action_list[k] == nil then
			self.action_list[k] = 0
		end
	end

	if self:is_other_day() then
		self.login_time = self:get_day_time()
		for k,v in pairs(self.action_list) do
			self.action_list[k] = 0
		end
		self:update_char()
	end		
end


----------------------------------------数据读写-----------------------------------------------------

function Daily_reward:insert_char()
	local dbh = f_get_db()
	local t_list = {}
	t_list.char_id = self.char_id
	t_list.login_time = self.login_time
	t_list.action_list = self.action_list or {}
	
	local err_code = dbh:insert(database,Json.Encode(t_list))       
	if err_code == 0 then
		return true
	end
	return false
end

function Daily_reward:update_char()
	local dbh = f_get_db()
	local data = {} --string.format("{flag:%d,day:%d,login_time:%d,item_list:'%s'}",self.flag,self.day,self.login_time,Json.Encode(self.item_list or {}))
	data.login_time = self.login_time
	data.action_list = self.action_list or {}


	local query = string.format("{char_id:%d}",self.char_id)

	local err_code = dbh:update(database,query,Json.Encode(data),true)
	if err_code == 0 then
		return true
	end
	return false
end









