

local debug_print = print
local _random = math.random
local question_time = require("answer_ex.answer_time_loader")
local question_config = require("answer_ex.answer_question_loader")
local reward_config = require("answer_ex.answer_reward_loader")
local database="answer_question"
local interval = 23
local one_min = 60
local one_hour = 60 * one_min
local one_day = 24 * one_hour

Answer_mgr = oo.class(nil, "Answer_mgr")

function Answer_mgr:__init()
	self.question_id = nil										--当前题目
	self.answer_id = nil										--当前答案
	self.question_list = {}										--题目列表
	self.question_number = 0									--题目数量
	self.cur_question_number = 0								--当天答第几道
	
	self.char_list = {}											--答题玩家列表
	self.send_list = {}											--发送玩家列表
	self.is_answer_list = self:db_load() or {}					--cycle答过题目的玩家（发奖励时记住）

	self.status = 0												--当前状态
	self.send_rank_time = nil									--发送排行时间
	self.cycle = 0												--当前第几次答题
	self.broadcast_count = 4									--广播开始的次数
	self.begin_time = self:get_begin_time()						--开始答题的时间
	self.time = self.begin_time - 30*one_min					--答题时间
	self.summit_time = nil										--第一个提交答案的时间

	self.rank_number = reward_config.question_reward.number		--排行榜限制人数
	self.cur_rank_number = 0									--当前排行榜人数
	self.ranklist = {}											--排行榜
	self.send_rank_list = {}									--排行榜（发送客户端）
	self.rank_count = 0											--需要排行广播的玩家
	self.min_rank_score = 0										--进入排行最低分数
	self.send_window = nil
end

function Answer_mgr:get_click_param()
	return self, self.on_timer, 3 ,nil
end

function Answer_mgr:on_timer()
	
	if self.status == 0 then
		if ev.time >= self.time and ev.time < (self.begin_time - 1) then
			self:clear_ranklist()
			self:init_question()
			self.time = ev.time + 2*one_min
			self.send_rank_time = self.begin_time + interval - 1
			--print("clear", os.date("%d:%H:%M:%S", ev.time), os.date("%d:%H:%M:%S", self.time), os.date("%d:%H:%M:%S", self.begin_time))
			self.status = 1
		elseif ev.time > self.begin_time then
			self.begin_time = self:get_begin_time()
			self.time = self.begin_time - 30*one_min
			--print("next_start", os.date("%H:%M:%S", ev.time), os.date("%H:%M:%S", self.time))
			
		end
	elseif self.status == 1 then						--准备开始
		if self.begin_time - ev.time <= 30 then
			self.time = self.begin_time
			--print("set_start_time", os.date("%H:%M:%S", ev.time), os.date("%H:%M:%S", self.time))
			
			self.status = 2
		elseif ev.time >= self.time then
			if	self.broadcast_count > 0 then
				self.time = self.time + 30
				self.broadcast_count = self.broadcast_count - 1
				self:broadcast_begin()
				--print("broadcast_begin", os.date("%H:%M:%S", ev.time), os.date("%H:%M:%S", self.time))
			else
				self.time = self.begin_time
				self.status = 2
			end
		end
	elseif self.status == 2 then						--答题状态
		if not self.send_window and self.begin_time - ev.time < 30 then
			self.send_window = true
			--print("%%%%%^^^send_window::::", self.begin_time - ev.time)
			self:send_char_window()
		end
		if ev.time >= self.time then
			self.cur_question_number = self.cur_question_number + 1
			if self.cur_question_number > self.question_number then
				self.time = self.time + 120
				--print("broadcast_finish", os.date("%H:%M:%S", ev.time), os.date("%H:%M:%S", self.time))
				self:broadcast_finish()
				self.status = 3
			else
				self:send_question()
				self.time = self.begin_time + self.cur_question_number*interval
				self.send_rank_time = self.time - 3
				--print("send_question", os.date("%H:%M:%S", ev.time), os.date("%H:%M:%S", self.time))
				
			end
		end
		if ev.time >= self.send_rank_time then
			self.send_rank_time = self.send_rank_time + interval
			--print("sort_rank", os.date("%H:%M:%S", ev.time), os.date("%H:%M:%S", self.time))
			self:sort_rank()
		end
	elseif self.status == 3 then						--答完
		if self.ranking_list_temp == nil then	--并排名的列表
			self:set_ranking_list()
		end
		if ev.time >= self.time then
			if self.rank_count <= 0 then
				self:write_log()
				self:send_reward_email_ex()
				self.begin_time = self:get_begin_time()
				self.time = self.begin_time - 30*one_min
				--print("send_reward", os.date("%H:%M:%S", ev.time), os.date("%H:%M:%S", self.time), os.date("%H:%M:%S", self.begin_time))
				
				self.status = 0
			else
				self:broadcast_ranklist_ex(self.rank_count)
				self.rank_count = self.rank_count - 1
				self.time = self.time + 3
				--print("broadcast_rank", os.date("%H:%M:%S", ev.time), os.date("%H:%M:%S", self.time))
				
			end
		end
	end
end


function Answer_mgr:count_begin_time(date, week, cycle)
	week = week % 7 + 1
	local time_config = question_time.time_config
	local hour = time_config.ord[week][cycle].hour
	local min = time_config.ord[week][cycle].min
	ret = hour*one_hour + min*one_min
	local now = ev.time - date
	return now < ret, ret + date
end

---计算每天开始时间
function Answer_mgr:get_begin_time()
	local week = tonumber(os.date("%w" ,ev.time))
	local today = f_get_today()
	--第一轮答题
	local ret, time = self:count_begin_time(today, week, 1)
	if ret == true then
		self.cycle = 1
		return time
	end
	--第二轮答题
	local ret, time = self:count_begin_time(today, week, 2)
	if ret == true then
		self.cycle = 2
		return time
	end
	--第二天答题第一轮
	self:clear_answer_list()
	local ret, time = self:count_begin_time(f_get_tomorrow(), week + 1, 1)
	if ret == true then
		self.cycle = 1
		return time
	end
end


function Answer_mgr:db_load()
	local date = f_get_today()
	local week = tonumber(os.date("%w" ,ev.time))
	local _, cycle1 = self:count_begin_time(date, week, 1)
	local _, cycle2 = self:count_begin_time(date, week, 2)
	if ev.time < cycle1 or ev.time > cycle2 then 
		return 
	end

	local dbh = f_get_db()
	local create_id = tonumber(os.date("%Y%m%d", date))
	local query = string.format("{create_id:%d}", create_id)
	local data = "{sort_list:1}"

	local row, e_code = dbh:select_one(database, data, query)
	local list = {}
	if e_code == 0 and row ~= nil then
		for k, v in pairs(row.sort_list) do
			list[v] = v
		end
	end
	return list
end

function Answer_mgr:clear_answer_list()
	self.is_answer_list = {}
end

---清理排行
function Answer_mgr:clear_ranklist()
	self.question_id = nil
	self.answer_id = nil
	self.question_list = {}
	self.cur_question_number = 0
	self.broadcast_count = 4
	self.cur_rank_number = 0
	self.char_list = {}
	self.send_list = {}
	self.ranklist = {}
	self.rank_count = 0
	self.min_rank_score = 0
	self.send_rank_list = {}
	self.send_window = nil
	self.ranking_list_temp = nil
end

function Answer_mgr:send_char_window()
	local server_mgr = g_server_mgr
	local player_mgr = g_player_mgr
	local online_l = player_mgr:get_online_player()
	local pkt = {}
	for k,v in pairs(online_l or {}) do
		if not self.is_answer_list[k] then
			local line = player_mgr:get_char_line(k)
			if line then
				server_mgr:send_to_server(line, k, CMD_M2C_ANSWER_SEND_WINDOW_S, pkt)
			end
		end
	end
end

----广播开始
function Answer_mgr:broadcast_begin()
	local pkt = {}
	local content  = {}
	f_construct_content(content,f_get_string(1901),14,nil)
	pkt.say = content
	pkt.msg_type = 3
	pkt = Json.Encode(pkt)
	local online_l = g_player_mgr:get_online_player()
	local svsock_mgr = g_svsock_mgr
	for k,v in pairs(online_l or {}) do
		svsock_mgr:send_server_ex(WORLD_ID, k, CMD_C2W_QUESTION_BROADCAST_S, pkt, true)
	end
end

function Answer_mgr:get_random_s(sum_type)
	local sequence = {}
	local list = {}
	for i = 1, sum_type do
		list[i] = i
	end
	local last = sum_type
	for i = 1, sum_type do
		local num = _random(1, last + 1);
       	sequence[i] = list[num];
        list[num] = list[last];
        last = last - 1
	end
	return sequence
end

function Answer_mgr:question_init(count_type, sum_type, type)
	local config = question_config.question_config
	local sequence = self:get_random_s(sum_type)
	for i = 1, count_type do
		local question = {}
		local random = sequence and sequence[i]
		--print("type, random", type, random)
		if config[type].topic[random] == nil then
			print("error question_init", type, random, count_type, sum_type)
		end
		question.question_id = config[type].topic[random].question
		question.answer_id = config[type].topic[random].answer
		table.insert(self.question_list, question)
	end
end

---初始化题目
function Answer_mgr:init_question()
	local config = question_config.question_config
	local count_gametype = config[0].number
	local sum_gametype = config[0].count
	local count_commontype = config[1].number
	local sum_commontype = config[1].count

	local game_question_list = {}
	local common_question_list= {}
	--控制题目
	self.question_number = count_commontype + count_gametype
	self:question_init(count_gametype, sum_gametype, 0)
	self:question_init(count_commontype, sum_commontype, 1)
end

---发送题目
function Answer_mgr:send_question()
	self.summit_time = nil
	for k,v in pairs(self.char_list) do
		v:clear_obj_status()
	end
	self.question_id = self.question_list[self.cur_question_number].question_id
	self.answer_id = self.question_list[self.cur_question_number].answer_id
	--print("question:", self.question_id, "answer:", self.answer_id)
	local next_send_time = self.begin_time + self.cur_question_number*interval
	local pkt = {}
	pkt[1] = {}
	pkt[1][1] = self.question_id
	pkt[1][2] = math.max(next_send_time - ev.time,0)
	pkt[1][3] = 0
	pkt[1][4] = math.max(self.question_number - self.cur_question_number,0)
	local server_mgr = g_server_mgr
	local player_mgr = g_player_mgr
	for k, v in pairs(self.send_list or {}) do
		local line = player_mgr:get_char_line(v)
		if line then
			server_mgr:send_to_server(line ,v, CMD_C2M_ANSWER_GET_SUBJECT_S, pkt)
		end
	end
end


--process
--获取面板信息
function Answer_mgr:get_all_info(char_id)
	local obj = self.char_list[char_id]
	local ret = {}
	if not obj then return ret end
	ret = obj:get_all_info()
	ret[4] = self.question_id and math.max(self.question_number - self.cur_question_number, 0) or 0
	ret[6] = obj:get_max_dec_count()
	ret[7] = obj:get_max_dou_count()
	return ret
end

--拿题目
function Answer_mgr:get_question(server_id,char_id)
	local ret = {}
	if self.cycle == 2 and self.is_answer_list[char_id] then
		ret.result = 20754
		g_server_mgr:send_to_server(server_id, char_id, CMD_C2M_ANSWER_GET_SUBJECT_S, ret)
		return
	end
	if not self.send_list[char_id] then
		self.send_list[char_id] = char_id
	end
	if not self.char_list[char_id] then
		self:init_obj(char_id)
	end
	
	if self.status == 0 then
		ret.result = 20753
	elseif self.status == 1 then
		ret.result = 20752
		local time = self.begin_time - ev.time
		if time < 0 then
			time = 0
		end
		ret.time = time
	elseif self.status == 2  then
		if not self.question_id then
			ret.result = 20752
			local time = self.begin_time - ev.time
			if time < 0 then
				time = 0
			end
			ret.time = time
		else 
			local next_send_time = self.begin_time + self.cur_question_number*interval
			ret[1] = {}
			ret[1][1] = self.question_id
			ret[1][2] = math.max(next_send_time - ev.time,0)
			ret[1][3] = self.question_id and self.char_list[char_id] and self.char_list[char_id]:get_answer_status() or 0
			ret[1][4] = math.max(self.question_number - self.cur_question_number ,0)
		end
	elseif self.status == 3 then
		ret.result = 20753
	end
	g_server_mgr:send_to_server(server_id, char_id, CMD_C2M_ANSWER_GET_SUBJECT_S, ret)
end

--初始化玩家
function Answer_mgr:init_obj(char_id)
	local name = g_player_mgr:char_id2nm(char_id)
	self.char_list[char_id] = Answer_obj(char_id,name)
	
	local obj = self.char_list[char_id]
	obj:set_max_answer_count(self.question_number)

	local vip = g_vip_play_inf
	local pkt = {}
	pkt.exc = vip:get_vip_field(char_id, VIPATTR.EXCADD)
	pkt.dou = vip:get_vip_field(char_id, VIPATTR.DOUADD)
	obj:set_vip_addition(pkt)
	
end

--使用道具 排错 积分加倍
function Answer_mgr:use_vip_props(char_id,pkt)
	if ev.time > self.begin_time + self.question_number*interval then
		ret.result = 20753
	end
	if self:time_limit(23, 3) == false then return end
	if not pkt then return end
	local obj = self.char_list[char_id]
	if not obj then return ret end
	local use_flag = 0
	if pkt.type == 1 then
		local dec = obj:get_decrease_count()
		if obj:get_decrease_flag() == 1 or dec < 1 then
			use_flag = 0
		else
			use_flag = 1
			obj:set_decrease_flag(1)
			obj:dec_decrease_count(1)
		end
	elseif pkt.type == 2 then
		local dou = obj:get_double_count()
		if obj:get_double_flag() == 1 or dou < 1 then
			use_flag = 0
		else
			use_flag = 1
			obj:set_double_flag(1)
			obj:dec_double_count(1)
		end
	end
	local ret = {}
	ret[1] = pkt.type
	ret[2] = use_flag
	ret[3] = obj:get_decrease_count()
	ret[4] = obj:get_double_count()
	return ret
end

--时间限制（be开始 en结束）
function Answer_mgr:time_limit(be, en)
	local next_send_time = self.begin_time + self.cur_question_number*interval
	if next_send_time - ev.time <= be and next_send_time - ev.time >= en then
		return true
	else
		return false
	end
end

--提交问题计算积分
function Answer_mgr:submit_question(char_id, pkt)
	local next_send_time = self.begin_time + self.cur_question_number*interval
	if self:time_limit(13, 1) == false then
		return
	end
	if not self.summit_time then
		local time = math.max(ev.time + 13 - next_send_time, 0)
		if time > 2 then
			self.summit_time = next_send_time - 13
		else 
			self.summit_time = ev.time
		end
	end
	local ret = {}
	local obj = self.char_list[char_id]
	if not obj then 
		return 
	end
	
	obj:add_answer_count(1)

	if obj:get_answer_count() < 2 then  --每日必做 答题通知 
		local line = g_player_mgr:get_char_line(char_id)
		g_server_mgr:send_to_server(line, char_id, CMD_M2C_ANSWER_SEND_STATE_S, {})
	end

	local answer_status = obj:get_answer_status()
	if answer_status == 1 or tonumber(pkt[2]) ~= self.answer_id then
		ret = obj:get_all_info()
		ret[4] = self.question_number - self.cur_question_number
		ret[6] = 0
		--print(" error answer:", pkt[1], pkt[2], self.answer_id)
		return ret
	end
	local time = math.max(ev.time - self.summit_time + 1, 0)
	local score = tonumber(obj:calculate_score(time))
	obj:add_right_count(1)
	obj:set_answer_status(1)
	ret = obj:get_all_info()
	ret[4] = self.question_number - self.cur_question_number
	ret[6] = score
	--print(" right answer:", pkt[1], pkt[2], self.answer_id)
	return ret
end


---插入排行----------------------
function insertSort(container, size, value)
	local is_insert = false
	local last = size
	for i = 1, size do
		local element = container[i]
		if not element then
			container[i] = value
			last = i
			is_insert = true
			break
		elseif element.score < value.score then
			container[i] = value
			is_insert = true
			for j = i + 1, size do
				local temp = container[j]
				container[j] = element
				if not temp then
					last = j
					break
				else
					element = temp
				end
			end
			break
		end
	end
	return container[last].score, is_insert
end

----排行---------------------
function Answer_mgr:sort_rank(sort_table, count)
	local min_score = self.min_rank_score
	local container = {}
	local length = 0
	local size = self.rank_number
	for k, v in pairs(self.char_list) do
		local value = v
		if (length < size and value.score > 0) or value.score > min_score then
			local is_insert = false
			local min = 0
			min, is_insert = insertSort(container, size, value)
			if is_insert and length < size then
				length = length + 1
			elseif length >= size then
				min_score = min
			end
		end
	end
	self.ranklist = container
	self.min_rank_score = min_score
	self.cur_rank_number = length

	local ret = {}
	for i = 1, length do
		ret[i] = {[1] = i, [2] = container[i].name, [3] = container[i].score}
	end
	self.send_rank_list = ret
	local player_mgr = g_player_mgr
	local server_mgr = g_server_mgr
	for k, v in pairs(self.send_list or {}) do
		local line = player_mgr:get_char_line(v)
		if line then
			server_mgr:send_to_server(line, v, CMD_C2M_ANSWER_SORT_S, ret)
		end
	end
end

--获取排行
function Answer_mgr:get_ranklist()
	return self.send_rank_list
end

--广播完成
function Answer_mgr:broadcast_finish()
	local config = reward_config.question_reward
	local pkt = {}
	local content  = {}
	f_construct_content(content,f_get_string(1902),14,nil)
	f_construct_content(content,f_get_string(1903),56,nil)
	f_construct_content(content,f_get_string(1904),14,nil)
	f_construct_content(content,f_get_string(1905),56,nil)
	pkt.say = content
	pkt.msg_type = 3
	pkt = Json.Encode(pkt)
	local online_l = g_player_mgr:get_online_player()
	for k,v in pairs(online_l or {}) do
		g_svsock_mgr:send_server_ex(WORLD_ID,k,CMD_C2W_QUESTION_BROADCAST_S,pkt,true)
	end
	local reward_count = config.broadcast
	self.rank_count = math.min(reward_count, self.cur_rank_number)
end

function Answer_mgr:set_ranking_list()
	self.ranking_list_temp = {}
	local last_score = nil
	local last_pos = 1
	for k, v in ipairs(self.ranklist) do
		if v.score ~= last_score then
			if self.ranking_list_temp[k] == nil then
				self.ranking_list_temp[k] = {}
			end
			table.insert(self.ranking_list_temp[k], v)
			last_score = v.score
			last_pos = k
		else
			table.insert(self.ranking_list_temp[last_pos], v)
		end
	end
end

--并排名广播
function Answer_mgr:broadcast_ranklist_ex(count)
	local ranking_list = self.ranking_list_temp[count]
	if count <= 0 or ranking_list == nil then return end
	local pkt = {}
	local content  = {}
	local name = ""
	local score = 0
	for k, v in ipairs(ranking_list) do
		name = name .. v.name .. ","
		score = v.score
	end
	f_construct_content(content,f_get_string(1906),14,nil)
	f_construct_content(content,name,56,nil)
	f_construct_content(content,f_get_string(1907),14,nil)
	f_construct_content(content,score,56,nil)
	f_construct_content(content,f_get_string(1908),14,nil)
	f_construct_content(content,f_get_string(1909),56,nil)
	f_construct_content(content,tostring(count),56,nil)
	f_construct_content(content,f_get_string(1910),56,nil)
	pkt.say = content
	pkt.msg_type = 3
	pkt = Json.Encode(pkt)
	local online_l = g_player_mgr:get_online_player()
	for k,v in pairs(online_l or {}) do
		g_svsock_mgr:send_server_ex(WORLD_ID,k,CMD_C2W_QUESTION_BROADCAST_S,pkt,true)
	end
end

--广播排行
function Answer_mgr:broadcast_ranklist(count)
	if count <= 0 then return -1 end
	local pkt = {}
	local content  = {}
	local name = self.ranklist[count].name
	local score = tostring(self.ranklist[count].score)
	f_construct_content(content,f_get_string(1906),14,nil)
	f_construct_content(content,name,56,nil)
	f_construct_content(content,f_get_string(1907),14,nil)
	f_construct_content(content,score,56,nil)
	f_construct_content(content,f_get_string(1908),14,nil)
	f_construct_content(content,f_get_string(1909),56,nil)
	f_construct_content(content,tostring(count),56,nil)
	f_construct_content(content,f_get_string(1910),56,nil)
	pkt.say = content
	pkt.msg_type = 3
	pkt = Json.Encode(pkt)
	local online_l = g_player_mgr:get_online_player()
	for k,v in pairs(online_l or {}) do
		g_svsock_mgr:send_server_ex(WORLD_ID,k,CMD_C2W_QUESTION_BROADCAST_S,pkt,true)
	end
end


--入库
function Answer_mgr:serialize_to_db()
	if table.is_empty(self.is_answer_list) then
		return 
	end

	local date = f_get_today()
	local week = tonumber(os.date("%w" ,ev.time))
	local _, cycle1 = self:count_begin_time(date, week, 1)
	local _, cycle2 = self:count_begin_time(date, week, 2)
	if ev.time < cycle1 or ev.time > cycle2 then 
		return 
	end

	local ret = {}
	for k, v in pairs(self.is_answer_list) do
		table.insert(ret, k)
	end
	local dbh = f_get_db()
	local data = {}
	local date = tonumber(os.date("%Y%m%d",ev.time))
	local query = string.format("{create_id:%d}",date)
   	data.create_id = date
	data.sort_list = ret
	local err=dbh:update(database,query,Json.Encode(data), true)
end

--日志
function Answer_mgr:write_log()
	local str = "insert into log_answer(char_id,join_count,\
	right_count,is_answer,is_finish,time) \
	values(%d,%d,%d,%d,%d,%d)"
	local str_log
	for k,v in pairs(self.char_list or {}) do
		if v then
			str_log = string.format(str, k, v:get_answer_count(),
			v:get_right_count(),v:is_answer(),v:is_finish(),ev.time)
			g_web_sql:write(str_log)
		end
	end
	return
end

--发并行排名奖励
function Answer_mgr:send_reward_email_ex()
	--排行奖
	local rank_number = reward_config.question_reward.number
	for i = 1, self.cur_rank_number do
		for k, v in ipairs(self.ranking_list_temp[i] or {}) do
			local obj = v
			local char_id = obj:get_id()
			if obj and obj:get_answer_count() > 0 then
				self.char_list[char_id] = nil
				--print("&&&&&email_rank:", i, char_id)
				self:create_email(i,char_id)
				self.is_answer_list[char_id] = char_id
			end
		end
	end

	--参与奖
	local reward_lvl = rank_number + 1
	for k,v in pairs(self.char_list or {}) do
		if v and v:get_answer_count() > 0 then
			local char_id = v:get_id()
			--print("&&&&&&email_nomal:", reward_lvl, char_id)
			self:create_email(reward_lvl,v:get_id())
			self.is_answer_list[k] = k
		end
	end

end

--发奖励
function Answer_mgr:send_reward_email()
	--排行奖
	local rank_number = reward_config.question_reward.number
	for i = 1, self.cur_rank_number do
		local obj = self.ranklist[i]
		local char_id = obj:get_id()
		if obj and obj:get_answer_count() > 0 then
			self.char_list[char_id] = nil
			--print("&&&&&email_rank:", i, char_id)
			self:create_email(i,char_id)
			self.is_answer_list[char_id] = char_id
		end
	end

	--参与奖
	local reward_lvl = rank_number + 1
	for k,v in pairs(self.char_list or {}) do
		if v and v:get_answer_count() > 0 then
			local char_id = v:get_id()
			--print("&&&&&&email_nomal:", reward_lvl, char_id)
			self:create_email(reward_lvl,v:get_id())
			self.is_answer_list[k] = k
		end
	end

end

--获取物品发送物品
function Answer_mgr:create_email(level,char_id)
	local config = reward_config.question_reward.rank
	local money_l = config[level].money or {}
	local item_l = config[level].item or {}
	local title = f_get_string(1911)
	local content = f_get_string(1912)
	local pkt = {}
	pkt.sender = 0
	pkt.recevier = char_id
	pkt.title = title
	pkt.content = content
	pkt.item_list = item_l
	pkt.money_list = money_l	pkt.box_title = f_get_string(1913)
	local _ = g_email_mgr:send_email_interface(pkt)
end


--关闭面板
function Answer_mgr:close_panel(char_id)
	self.send_list[char_id] = nil
end
