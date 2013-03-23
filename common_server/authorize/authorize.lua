
-----------------------------------寄售行-----------------------------
--local Authorize_db = 
require("authorize.authorize_db")
require("authorize.authorize_mission")
local authorize_loader = require("config.loader.authorize_loader")


--定时存盘时间
local update_time = 120

Authorize = oo.class(nil, "Authorize")


--定时器1   定时存盘
function Authorize:save_time_authorize()
	local f = function()
		self:update_current_authorize()
		ev:timeout(update_time, self:save_time_authorize())	
	end
	return f
end

function Authorize:__init()
	self.day_begin	= f_get_today()
	self.list  		= {}
	self:load()
	self.update_time = ev.time + update_time
	--ev:timeout(update_time , self:save_time_authorize())
end

function Authorize:get_click_param()
	return self, self.on_timer,3,nil
end

function Authorize:on_timer()
	for k , v in pairs(self.list) do
		v:audit()
	end

	if ev.time > self.update_time then
		self:update_current_authorize()
		self.update_time = self.update_time + update_time
	end
end

-------------------------------------与map交互命令---------
function Authorize:get_player_today_authorize(char_id)
	local pk = {}
	for k , v in pairs(self.list) do
		pk[k] = v:get_player_today_authorize(char_id)
	end

	return pk
end

function Authorize:get_player_authorize(char_id)
	local pk = {}
	for k , v in pairs(self.list) do
		pk[k] = v:get_player_authorize(char_id)
	end
	return pk
end


function Authorize:get_all_authorize()
	local pk = {}
	for k , v in pairs(self.list) do
		pk[k] = v:get_authorize_count()
	end

	return pk
end

function Authorize:get_reward(char_id,authorize_id)
	local pk = {}
	if not self.list[authorize_id] then
		pk.result = 20521
		return pk
	end
	pk.count = self.list[authorize_id]:get_reward(char_id)
	pk.authorize_id = authorize_id
	pk.result = 0

	return pk
end

function Authorize:get_all_reward(id)
	local char_id = tostring(id)
	local flags = false
	local pk = {}
	for k, v in pairs(self.list) do
		local count = v:get_reward(char_id)
		if count ~= 0 then
			flags = true
			pk[k] = count
		end
	end
	if flags then
		pk.result = 0
	else
		pk.result = 20524
	end

	return pk
end

function Authorize:entrust_authorize(char_id,s_pkt)
	local pk = {}
	if not self.list[s_pkt.authorize_id] then
		pk.result = 20521
		return pk
	end
	local pkt = {}
	pkt.char_id = char_id
	pkt.count   = s_pkt.count
	self.list[s_pkt.authorize_id]:authorize(pkt)

	pk.result = 0
	pk.authorize_id = s_pkt.authorize_id
	pk.count	    = s_pkt.count
	return pk
end

function Authorize:get_authorize_mission(char_id,authorize_id)
	local pk = {}
	if not self.list[authorize_id] then
		pk.result = 20521
		return pk
	end

	pk.result, pk.authorizer = self.list[authorize_id]:get_authorize()
	pk.authorize_id = authorize_id

	return pk
end

function Authorize:authorize_compensation(pkt)
	local pk = {}
	if not self.list[pkt.authorize_id] then
		pk.result = 20521
		return pk
	end
	local s_pkt = {}
	s_pkt.char_id = pkt.authorizer
	s_pkt.count   = 1
	self.list[s_pkt.authorize_id]:authorize(s_pkt)
end

function Authorize:complete_authorize(authorize_id)
	local pk = {}
	if not self.list[authorize_id] then
		pk.result = 20521
		return pk
	end
	self.list[authorize_id]:complete_authorize()
end


-------------------------------------数据库操作----------
function Authorize:load()
	local rs= Authorize_db:Load()
	if rs then
		for k , v in pairs(rs) do
			self.day_begin = v.day_begin
			for k1 , v1 in pairs(v.list) do
				self.list[k1] = Authorize_mission(k1, v1)
				self.list[k1]:audit()
			end
		end
	end

	local authorize_config = authorize_loader.get_authorizet_meta_list()
	for k, v in pairs(authorize_config) do
		if not self.list[k] then
			self.list[k] = Authorize_mission(k)
		end
	end

	return
end


function Authorize:update_current_authorize()
	local db_data = self:serialize_to_db()
	Authorize_db:update_authorize(db_data)

	return
end

function Authorize:serialize_to_db()
	local pkt = {}
	pkt.day_begin = self.day_begin
	pkt.list 	  = {}
	for k , v in pairs(self.list) do
		pkt.list[k] = v:serialize_to_db()
	end
	return pkt
end

--------------------------------------发送到map，更新中奖者信息
--function Authorize:serialize_to_map()
	--local pkt = {}
	--pkt = self.lottery_winners:spec_serialize_to_map()
	--return pkt
--end
--
