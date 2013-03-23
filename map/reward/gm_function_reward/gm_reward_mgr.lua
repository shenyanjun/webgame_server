
local database = "gm_reward_char"
local _gm_reward = require("reward.gm_function_reward.gm_reward_loader")

Reward_gm_mgr = oo.class(nil,"Reward_gm_mgr")


function Reward_gm_mgr:__init()
	self.function_id = nil
	self.start_time = nil
	self.end_time = nil
	self.char_l = {}
end

--玩家登陆
function Reward_gm_mgr:login(char_id)	
	self:init_obj(char_id)
	if not self.char_l[char_id] then return end
	local ret = {}
	ret = self.char_l[char_id]:serialize_to_net()
	ret.result = 0
	g_cltsock_mgr:send_client(char_id,CMD_MAP_GET_ONLINE_FUNCTION_S,ret)
end

function Reward_gm_mgr:init_obj(char_id)
	if not self.function_id then return end
	local player = g_obj_mgr:get_obj(char_id)
	local level = player:get_level()
	local list = _gm_reward.OnlineRewardTable[self.function_id]
	if level <= list.min_level and level >= list.max_level then return end

	if not self.char_l[char_id] then
		if not self:load_char_db(char_id) then
			self.char_l[char_id] = Reward_gm_obj(char_id,self.function_id,self.start_time,self.end_time,ev.time)
		end
	end
end

--玩家下线
function Reward_gm_mgr:logout(char_id)
	if not self.char_l[char_id] then return end
	self.char_l[char_id]:logout()
	self.char_l[char_id] = nil
end

--清空
function Reward_gm_mgr:clear()
	self.function_id = nil
	self.start_time = nil
	self.end_time = nil
	self.char_l = {}
end

--滴答
function Reward_gm_mgr:on_timer()
	self:timer_handler()
end

function Reward_gm_mgr:timer_handler()
	if self.function_id == nil then
		for k,v in pairs(_gm_reward.OnlineRewardTable or {}) do
			if ev.time >= v.start_time and ev.time <= v.end_time then
				self:clear()
				self.function_id = k
				self.start_time = v.start_time
				self.end_time = v.end_time
				self:set_function_start()
				break
			end	
		end
	end
	for k,v in pairs(self.char_l or {}) do
		if v then
			v:on_timer()
		end
	end
	if self.function_id and ev.time >= _gm_reward.OnlineRewardTable[self.function_id].end_time then
		self:set_function_end()
	end
end

--活动结束
function Reward_gm_mgr:set_function_end()
	local ret = {}
	ret.type = 1
	for k,v in pairs(self.char_l or {}) do
		if k and v then
			g_cltsock_mgr:send_client(k,CMD_MAP_FUNCTION_END_NOTIFY_S,ret)
		end
	end
	self:clear()
end

--活动开始前，清空
function Reward_gm_mgr:set_function_start()
	local start_time = ev.time
	local ret = {}
	ret.online_time = 1
	ret.total_time = 1
	ret.result = 0
	local online_l = g_obj_mgr:get_list(OBJ_TYPE_HUMAN)
	for k,v in pairs(online_l or {}) do
		local level = v:get_level()
		if level >= _gm_reward.OnlineRewardTable[self.function_id].min_level and level <= _gm_reward.OnlineRewardTable[self.function_id].max_level then
			self.char_l[k] = Reward_gm_obj(k,self.function_id,self.start_time,self.end_time,start_time)
			g_cltsock_mgr:send_client(k,CMD_MAP_GET_ONLINE_FUNCTION_S,ret)
		end
	end
end

--后台更新
function Reward_gm_mgr:gm_update()
	local list = _gm_reward.OnlineRewardTable[self.function_id]
	if not list then
		self:set_function_end()
	else
		if list.start_time ~= self.start_time or list.end_time ~= self.end_time then
			self:set_function_end()
		end
	end
end

--装载数据
function Reward_gm_mgr:load_char_db(char_id,function_id)
	local dbh = f_get_db()
	local qurey = string.format("{char_id:%d}",char_id)
	local field = "{char_id:1,list:1}"
	local row,err = dbh:select_one(database,field,qurey)
	if not row or err ~= 0 then return false end
	if row.list.function_id ~= self.function_id or row.list.start_time ~= self.start_time or 
	row.list.end_time ~= self.end_time or row.list.date ~= tonumber(os.date("%Y%m%d")) then return false end
	local curren_time = row.list.login_time
	if (ev.time-row.list.logout_time) > 60 then
		curren_time = ev.time
	end	
	local data = {}
	data.char_id = row.char_id
	data.list = row.list
	local obj = Reward_gm_obj(char_id,self.function_id,self.start_time,self.end_time,curren_time)
	obj:clone(data)
	self.char_l[char_id] = obj
	return true
end

--启动
function Reward_gm_mgr:create_function()
	for k,v in pairs(_gm_reward.OnlineRewardTable or {}) do
		if ev.time >= v.start_time and ev.time <= v.end_time then
			self:clear()
			self.function_id = k
			self.start_time = v.start_time
			self.end_time = v.end_time
			break
		end	
	end	
end

