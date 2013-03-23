

local config = require("config.identify_config")

Identify_mgr = oo.class(nil, "Identify_mgr")

function Identify_mgr:__init()
	self.on_identify_list = {}
	self.sence_list = {}
	self.cache_list = {}	--离开缓存
end

function Identify_mgr:get_click_param()
	return self, self.on_timer, 3, nil
end

function Identify_mgr:on_timer()
	--验证中
	for k, v in pairs(self.on_identify_list or {}) do
		for kk, vv in pairs(v or {}) do
			if ev.time >= vv:get_time() then--验证超时，踢人
				local letters = self:generate_letter()
				self.on_identify_list[k][kk]:set_letters(letters)
				self.on_identify_list[k][kk]:set_time(ev.time+config._interval)
				local pkt = {}
				pkt.identify_code = letters
				pkt.remain_time = config._interval
				pkt.result = 0
				pkt.sence_id = k
				g_server_mgr:send_to_all_map(kk, CMD_C2M_IDENTIFY_CODE_C, Json.Encode(pkt), true)				
			end 
		end
	end
	--已验证
	for k, v in pairs(self.sence_list or {}) do
		for kk, vv in pairs(v or {}) do
			if ev.time >= vv then
				local obj = Identify_obj(kk)
				self.on_identify_list[k] = self.on_identify_list[k] or {}
				self.on_identify_list[k][kk] = obj
				self.sence_list[k][kk] = nil
				local pkt = {}
				local letters = self:generate_letter()
				pkt.identify_code = letters
				pkt.remain_time = config._interval or 60
				pkt.sence_id = k
				pkt.result = 0
				obj:set_letters(letters)
				obj:set_time(ev.time+config._interval)
				g_server_mgr:send_to_all_map(kk, CMD_C2M_IDENTIFY_CODE_C, Json.Encode(pkt), true)
			end
		end
	end
end

function Identify_mgr:generate_letter()
	local list = ""
	for i=1, 4 do
		local off = crypto.random(1, #config._letters)
		list = list..config._letters[off]
	end
	return list
end

--玩家进入
function Identify_mgr:enter(char_id, sence_id)
	local sence_list = self.on_identify_list[sence_id]
	if sence_list and sence_list[char_id] then	--没有答完列表
		local letters = sence_list[char_id]:get_letters()
		local pkt = {}
		pkt.identify_code = letters
		pkt.remain_time = math.max(0,sence_list[char_id]:get_time()-ev.time)
		pkt.result = 0
		pkt.sence_id = sence_id
		g_server_mgr:send_to_all_map(char_id, CMD_C2M_IDENTIFY_CODE_C, Json.Encode(pkt), true)
		return 
	end

	self.sence_list[sence_id] = self.sence_list[sence_id] or {}	--场景列表
	if self.cache_list[sence_id] and self.cache_list[sence_id][char_id] then
		self.sence_list[sence_id][char_id] = self.cache_list[sence_id][char_id]
		self.cache_list[sence_id][char_id] = nil
	end

	if not self.sence_list[sence_id][char_id] then
		local off = crypto.random(config._first_interval[1], config._first_interval[2]+1)
		self.sence_list[sence_id][char_id] = ev.time+off
	end
end

--玩家离开,不进行定时
function Identify_mgr:leave(char_id, sence_id)
	local list = self.sence_list[sence_id]
	self.cache_list[sence_id] = self.cache_list[sence_id] or {}
	if list and list[char_id] then
		self.cache_list[sence_id][char_id] = list[char_id]
		self.sence_list[sence_id][char_id] = nil
	end
	if self.on_identify_list[sence_id] and self.on_identify_list[sence_id][char_id] then
		self.on_identify_list[sence_id][char_id] = nil
		self.cache_list[sence_id][char_id] = ev.time
	end
end

--玩家验证
function Identify_mgr:authorize(char_id, sence_id, answer)
	local sence_list = self.on_identify_list[sence_id]
	if not sence_list or not sence_list[char_id] then
		local ret = {}
		g_svsock_mgr:send_server_ex(WORLD_ID, char_id, CMD_IDENTIFY_CLOSE_S, Json.Encode(ret), true)	--关闭面板
		local pkt = {}
		pkt.result = 22713
		g_svsock_mgr:send_server_ex(WORLD_ID, char_id, CMD_IDENTIFY_ANSWER_S, Json.Encode(pkt), true)
		return 
	end

	if answer and answer ~= "" and string.lower(sence_list[char_id]:get_letters()) == string.lower(answer) then
		self.on_identify_list[sence_id][char_id] = nil
		local off = crypto.random(config._fresh_interval[1], config._fresh_interval[2]+1)
		self.sence_list[sence_id][char_id] = ev.time+off
		local ret = {}
		g_svsock_mgr:send_server_ex(WORLD_ID, char_id, CMD_IDENTIFY_CLOSE_S, Json.Encode(ret), true)	--关闭面板
		local ret = {}
		ret.result = 0
		g_svsock_mgr:send_server_ex(WORLD_ID, char_id, CMD_IDENTIFY_ANSWER_S, Json.Encode(ret), true)	--通知答对
		local pkt = {}
		pkt.sence_id = sence_id
		g_server_mgr:send_to_all_map(char_id, CMD_C2M_IDENTIFY_ADD_EXP_C, Json.Encode(pkt), true)	--加经验
	else
		local letters = self:generate_letter()
		self.on_identify_list[sence_id][char_id]:set_letters(letters)
		self.on_identify_list[sence_id][char_id]:set_time(ev.time+config._interval)
		local pkt = {}
		pkt.identify_code = letters
		pkt.remain_time = config._interval
		pkt.result = 0
		pkt.sence_id = sence_id
		g_server_mgr:send_to_all_map(char_id, CMD_C2M_IDENTIFY_CODE_C, Json.Encode(pkt), true)
	end
end

--刷新
function Identify_mgr:refresh(char_id, sence_id)
	local sence_list = self.on_identify_list[sence_id]
	if not sence_list or not sence_list[char_id] then
		local pkt = {}
		pkt.result = 22713
		g_svsock_mgr:send_server_ex(WORLD_ID, char_id, CMD_IDENTIFY_ANSWER_S, Json.Encode(pkt), true)
		return 
	end
	local letters = self:generate_letter()
	self.on_identify_list[sence_id][char_id]:set_letters(letters)
	local pkt = {}
	pkt.identify_code = letters
	pkt.remain_time = math.max(0, sence_list[char_id]:get_time()-ev.time)
	pkt.result = 0
	pkt.sence_id = sence_id
	g_server_mgr:send_to_all_map(char_id, CMD_C2M_IDENTIFY_CODE_C, Json.Encode(pkt), true)
end
