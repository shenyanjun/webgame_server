

local _gm_reward = require("reward.gm_function_reward.gm_reward_loader")
local database = "gm_reward_char"

Reward_gm_obj = oo.class(nil,"Reward_gm_obj")


function Reward_gm_obj:__init(char_id,function_id,start_time,end_time,curr_time)
	
	self.char_id = char_id
	self.function_id = function_id
	self.f_start = start_time
	self.f_end = end_time

	self.start_time = curr_time
	self.logout_time = ev.time
	self.current_time = ev.time
	self.total_time = 0

	self.online_index = 1
	self.total_index = 1
	self.date = tonumber(os.date("%Y%m%d"))
	self.reward_online = {}
	self.reward_total = {}
	self:update_char()
end

function Reward_gm_obj:on_timer()
	if tonumber(os.date("%Y%m%d")) > self.date then
		self.date = tonumber(os.date("%Y%m%d"))
		self.reward_online = {}
		self.reward_total = {}
		self.start_time = ev.time
		self.logout_time = ev.time
		self.current_time = ev.time
		self.total_time = 0
		self.online_index = 1
		self.total_index = 1

		local ret = {}
		ret.online_time = 1
		ret.total_time = 1
		ret.result = 0
		g_cltsock_mgr:send_client(self.char_id,CMD_MAP_GET_ONLINE_FUNCTION_S,ret)
	end
	local list = _gm_reward.OnlineRewardTable[self.function_id]
	if self.start_time and list and list.online[self.online_index] and list.online[self.online_index].need_time 
	and (ev.time-self.start_time) >= list.online[self.online_index].need_time then
		local reward_time = 0
		reward_time = list.online[self.online_index].need_time
		reward_time = math.floor(reward_time/60)
		if not self.reward_online[self.online_index] then
			self:give_reward(1,reward_time)
			self.reward_online[self.online_index] = true
		end
		self.online_index = self.online_index+1
		self:update_char()
	end
	
	if self.start_time and list and list.total[self.total_index] and list.total[self.total_index].need_time 
	and self:get_total_time() >= list.total[self.total_index].need_time then
		local reward_time = 0
		reward_time = list.total[self.total_index].need_time
		reward_time = math.floor(reward_time/60)
		if not self.reward_total[self.total_index] then
			self:give_reward(2,reward_time)
			self.reward_total[self.total_index] = true
		end
		self.total_index = self.total_index+1
		self:update_char()
	end
end

--发奖励,防止多次领取
function Reward_gm_obj:give_reward(type,time)
	--print("--------", self.char_id, type, time)	
	local pkt = {}
	pkt.recevier = self.char_id
	pkt.sender = 0
	pkt.money_list = {}
	pkt.item_list = {}
	
	local info = nil
	if type == 1 then
		pkt.title = f_get_string(2141) or ""
		pkt.content = string.format(f_get_string(2142),time) or ""
		pkt.box_title = f_get_string(2143) or ""
		
		local list = _gm_reward.OnlineRewardTable[self.function_id]
		info = list and list.online[self.online_index]
	elseif type == 2 then
		pkt.title = f_get_string(2144) or ""
		pkt.content = string.format(f_get_string(2142),time) or ""
		pkt.box_title = f_get_string(2145) or ""
		
		local list = _gm_reward.OnlineRewardTable[self.function_id]
		info = list and list.total[self.total_index]
	else
		return 
	end
	
	if info then
		pkt.money_list = info.money_l
		
		for _, item in pairs(info.item_l or {}) do
			table.insert(pkt.item_list, item)
		end
		
		if info.occ_item_l then
			local obj = g_obj_mgr:get_obj(self.char_id)
			if obj then
				local occ = obj:get_occ()
				for _, v in pairs(info.occ_item_l[occ] or {}) do
					table.insert(pkt.item_list, v)
				end
			end
		end	
	end

	--table.print(pkt)	
	g_svsock_mgr:send_server_ex(COMMON_ID,0,CMD_M2P_SEND_EMAIL_S,pkt)
end

--下线
function Reward_gm_obj:logout()
	if not self.start_time then return end
	self:update_char()
end

--克隆
function Reward_gm_obj:clone(data)
	self.total_index = data.list.total_index
	self.online_index = data.list.online_index

	self.total_time = data.list.total_time
	self.date = data.list.date
	self.reward_online = data.list.reward_online
	self.reward_total = data.list.reward_total		
end

--入库序列化
function Reward_gm_obj:serialize_to_db()
	self.logout_time = ev.time
	local list = {}
	list.total_index = self.total_index
	list.online_index = self.online_index
	list.total_time = self.total_time+ev.time-self.current_time+30
	list.start_time = self.f_start
	list.end_time = self.f_end
	list.login_time = self.start_time
	list.logout_time = self.logout_time
	list.function_id = self.function_id
	list.date = self.date
	list.reward_online = self.reward_online
	list.reward_total = self.reward_total
	return list
end

--存盘
function Reward_gm_obj:update_char()
	local dbh = f_get_db()
	local query = string.format("{char_id:%d}",self.char_id)
	local field = "{list:1}"
	local data = {}
	data.char_id = self.char_id
	data.list = self:serialize_to_db()
	local row,err = dbh:select_one(database,field,qurey)
	if row and err == 0 then
		dbh:update(database,query,Json.Encode(data),true)
	else
		dbh:insert(database,Json.Encode(data))
	end
end

--累计在线
function Reward_gm_obj:get_total_time()
	return self.total_time+ev.time-self.current_time
end

function Reward_gm_obj:serialize_to_net()
	local list = {}
	list.online_time = ev.time - self.start_time
	list.total_time	= self.total_time+ev.time-self.current_time
	return list
end