
local config = require("offline_compete.compete_config_loader")

local CHALLENGE_HUMANS = 5	--可以挑战的人数
local CD_TIME = config.config.cd.time
local CHALLENGE_TIMES = 10
local RECORD_SIZE = 5

--离线竞技（单人）管理
Offline_compete_mgr = oo.class(nil, "Offline_compete_mgr")

function Offline_compete_mgr:__init()

	self.sort_list = {}
	self.char_info = {}			--key:char_id, value: {排名，id, 名字，等级，职业，性别，战斗力}
	self.challenge_info = {}	--key:char_id, value:{上次挑战时间，已挑战次数，cd开始时间}
	self.record = {}
	self.tomorrow = f_get_tomorrow()
	self.reward = {}
	self.reward_flag = true
	self.reward_time = f_get_today() + config.config.reward.r_time
	if self.reward_time < ev.time then
		self.reward_flag = false
	end
	self.size = 0
end


function Offline_compete_mgr:sign_up(info)
	local char_id = info[2]
	if self.char_info[char_id] ~= nil then
		return 31412
	end
	self.size = self.size + 1
	info[1] = self.size
	self.char_info[char_id] = info
	self.challenge_info[char_id] = {0, 0, 0}
	self.record[char_id] = {}
	table.insert(self.sort_list, char_id)
	return 0
end

function Offline_compete_mgr:update_info(info)
	local entry = self.char_info[info[2]]
	if entry == nil then
		return 31413
	end
	entry[3] = info[3]
	entry[4] = info[4]
	entry[5] = info[5]
	entry[6] = info[6]
	entry[7] = info[7]
	return 0
end


function Offline_compete_mgr:get_info(char_id)
	local entry = self.char_info[char_id]
	if entry == nil then
		return {type = 0}
	end
	local ci = self.challenge_info[char_id]
	local pkt = {}
	pkt.type = 1
	local today_time = f_get_today(ev.time)
	if ci[1] < today_time then
		pkt.info = {entry[1], entry[7], 0, CHALLENGE_TIMES}
	else
		pkt.info = {entry[1], entry[7], math.max(ci[3] + CD_TIME - ev.time, 0), CHALLENGE_TIMES - ci[2]}
	end
	local ranking = entry[1]
	if entry[2] ~= self.sort_list[ranking] then
		print("error : ranking ~= self.sort_list[ranking]", char_id, ranking, entry[2], self.sort_list[ranking])
	end
	pkt.list = {}
	local count = 0
	for i = math.max(1, ranking-CHALLENGE_HUMANS), ranking-1 do
		table.insert(pkt.list, self.char_info[self.sort_list[i]])
		count = count + 1
	end
	if count < CHALLENGE_HUMANS then
		for i = ranking + 1, math.min(self.size, ranking + (CHALLENGE_HUMANS - count) + 1) do
			table.insert(pkt.list, self.char_info[self.sort_list[i]])
			count = count + 1
		end
	end

	pkt.record = self.record[char_id]
	pkt.reward = self.reward[char_id] or 0
	local r_t = self.char_info[char_id][1]
	for k, v in pairs(config.config.reward.rank) do
		if r_t >= v.min and r_t <= v.max then
			pkt.reward_list = v.item_list
			pkt.reward_sp = v.sp
			break
		end
	end
	if pkt.reward_list == nil then
		pkt.reward_list = {}
		pkt.reward_sp = 0
	end
	return pkt
end

--挑战
function Offline_compete_mgr:challenge(challenger_id, be_challenge_id)
	local today_time = f_get_today(ev.time)
	local ci = self.challenge_info[challenger_id]
	if ci[1] < today_time then
		ci[2] = 0
		ci[3] = 0
	end
	if ci[3] + CD_TIME > ev.time then
		return 31414
	end
	if ci[2] >= CHALLENGE_TIMES then
		return 31415
	end
	return 0, be_challenge_id
end

--挑战次数减一
--function Offline_compete_mgr:done_one(char_id)
	--local entry = self.challenge_info[char_id]
	--entry[1] = ev.time
	--entry[2] = entry[2] + 1
--end

--挑战结果
function Offline_compete_mgr:challenge_finish(char_id, winner_id, loser_id)
	--发邮件奖励
	local email_entry = char_id == winner_id and config.config.reward.win or config.config.reward.lose
	local email = {}
	email.sender = -1
	email.recevier = char_id
	email.title = email_entry.title
	email.content = string.format(email_entry.content, char_id == winner_id and self.char_info[loser_id][3] or self.char_info[winner_id][3])
	email.box_title = email_entry.title
	email.money_list = {}
	
	email.item_list = {}
	for k, v in pairs(email_entry.item_list) do
		local item = {}
		item.id = v[1]
		item.count = v[2]
		item.name = v[3]
		table.insert(email.item_list, item)
	end
	g_email_mgr:send_email_interface(email)
	--更新时间
	local entry = self.challenge_info[char_id]
	if char_id == winner_id then
		entry[3] = ev.time
	end
	entry[1] = ev.time
	entry[2] = entry[2] + 1
	-- 记录
	local winner_r = self.record[winner_id]
	local loser_r = self.record[loser_id]
	while #winner_r >= RECORD_SIZE do
		table.remove(winner_r)
	end 
	while #loser_r >= RECORD_SIZE do
		table.remove(loser_r)
	end 
	local record_w = {self.char_info[loser_id][3], char_id == winner_id and 1 or 2, 1, 0} 
	local record_l = {self.char_info[winner_id][3], char_id == loser_id and 1 or 2, 2, 0} 
	table.insert(winner_r, 1, record_w)
	table.insert(loser_r, 1, record_l)
	--更新排名 
	local winner_ranking = self.char_info[winner_id][1]
	local loser_ranking = self.char_info[loser_id][1]
	if winner_ranking <= loser_ranking or char_id == loser_id then
		return
	end

	for i = winner_ranking, loser_ranking + 1, -1 do
		self.sort_list[i] = self.sort_list[i-1]
		self.char_info[self.sort_list[i]][1] = i
	end
	self.sort_list[loser_ranking] = winner_id
	self.char_info[winner_id][1] = loser_ranking
	--
	record_w[4] = loser_ranking
	record_l[4] = loser_ranking + 1

end

--挑战次数减一
function Offline_compete_mgr:get_sort_page(page)
	local info = {}
	info.page = page
	info.t_page = math.ceil(self.size / 10)
	info.list = {}
	for i = (page - 1) * 10 + 1, math.min(self.size, page * 10) do
		table.insert(info.list, self.char_info[self.sort_list[i]])
	end
	return info
end

function Offline_compete_mgr:get_click_param()
	return self, self.on_timer, 5, nil
end

function Offline_compete_mgr:on_timer()
	self:on_timer_impl()
end

function Offline_compete_mgr:on_timer_impl()
	if ev.time > self.tomorrow then
		self.reward_flag = true
		self.tomorrow = f_get_tomorrow()
		self.reward_time = f_get_today() + config.config.reward.r_time
	end
	if self.reward_flag and ev.time > self.reward_time then
		print("on_timer_impl", ev.time)
		self.reward_flag = false
		self.reward = {}
		local content = config.config.broadcast.content
		local email_entry = config.config.reward.notice
		local today = os.date("*t")
		local next_day = os.date("*t", ev.time + 86400)
		--print("next_day", j_e(today), j_e(next_day))
		local title = string.format(email_entry.title, today.month, today.day)
		for k, v in ipairs(self.sort_list) do
			if k <= 5 then
				local msg = {}
				f_construct_content(msg, self.char_info[v][3], 53)
				f_construct_content(msg, string.format(content, k), 12)
				f_send_bdc(3, 3, msg)
			end
			if k <= 100 then
				--发邮件通知
				local content2 = string.format(email_entry.content, k, next_day.month, next_day.day)
				local email = {}
				email.sender = -1
				email.recevier = v
				email.title = title
				email.content = content2
				email.box_title = title
				email.money_list = {}
				
				email.item_list = {}
				for k, v in pairs(email_entry.item_list) do
					local item = {}
					item.id = v[1]
					item.count = v[2]
					item.name = v[3]
					table.insert(email.item_list, item)
				end
				g_email_mgr:send_email_interface(email)
			end
			self.reward[v] = k
		end
	end
end

function Offline_compete_mgr:get_reward(char_id)
	local ret = {}
	ret.rank = self.reward[char_id] or 0
	self.reward[char_id] = 0
	for k, v in pairs(config.config.reward.rank) do
		if ret.rank >= v.min and ret.rank <= v.max then
			ret.entry = v.item_list
			ret.sp = v.sp
			break
		end
	end
	self:save(char_id)
	return ret
end

function Offline_compete_mgr:set_reward(char_id, rank)
	self.reward[char_id] = rank
end

function Offline_compete_mgr:kill_cd(char_id)
	local entry = self.challenge_info[char_id]
	entry[3] = 0
	return 0
end

function Offline_compete_mgr:send_all_officer_info(server_id)
	
end

------------- 保存
function Offline_compete_mgr:save(char_id)
	
	local char_info = self.char_info[char_id]
	if char_info == nil then
		return
	end
	local data = {}
	data.char_id = char_id
	data.char_info = char_info
	data.challenge_info = self.challenge_info[char_id]
	data.record = self.record[char_id]
	data.reward = self.reward[char_id]

	local m_db = f_get_db()
	local query = string.format("{char_id:%d}", char_id)
	m_db:update("offline_compete", query, Json.Encode(data), true)

end

function Offline_compete_mgr:save_all()
	for k, v in pairs(self.char_info) do
		self:save(k)
	end
end

function Offline_compete_mgr:load_all()
	local m_db = f_get_db()
	local rows, e_code = m_db:select("offline_compete")
	if rows ~= nil and e_code == 0 then
		for k, v in pairs(rows) do
			local char_id = v.char_id
			self.char_info[char_id] = v.char_info
			self.challenge_info[char_id] = v.challenge_info
			self.record[char_id] = v.record
			self.reward[char_id] = v.reward
		end
	end
	self.size = 0
	local repetitive = {}
	for k, v in pairs(self.char_info) do
		if self.sort_list[v[1]] == nil then
			self.sort_list[v[1]] = v[2]
			self.size = self.size + 1
		else
			repetitive[v[2]] = 1
		end
	end
	--check
	for k, v in pairs(repetitive) do
		print("warning Offline_compete_mgr:load_all", k, self.char_info[k][1], self.size + 1)
		self.size = self.size + 1
		table.insert(self.sort_list, k)
		self.char_info[k][1] = self.size
	end
	for i = 1, self.size do
		if self.char_info[self.sort_list[i]] == nil then
			print("error Offline_compete_mgr:load_all()", i, self.sort_list[i])
		end
	end
end