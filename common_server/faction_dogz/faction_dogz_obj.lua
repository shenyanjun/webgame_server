-- 帮派神兽
-- CodeBy:cailizhong
-- 2012/8/10

local faction_dogz_config = require("config.xml.faction_dogz.faction_dogz_config")

Faction_dogz_obj = oo.class(nil, "Faction_dogz_obj")

function Faction_dogz_obj:__init(dogz_id)
	self.dogz_id = dogz_id
	self.mood = 0
	self.pullulate = 0
	self.friendly_list = {} -- char_id: {char_id, degree, time}
	self.feed_list = {} -- char_id:{char_id, cnt, time}
	self.update_time = ev.time -- 心情掉落
end

function Faction_dogz_obj:get_dogz_info_by_cid(char_id)
	local ret = {}
	ret[1] = self:get_dogz_id()
	ret[2] = self:get_mood()
	ret[3] = self:get_maxMood()
	ret[4] = self:get_pullulate()
	ret[5] = self:get_maxPullulate()
	ret[6] = self:get_level()
	ret[7] = self:get_net_friendly_list()
	ret[8] = self:get_last_cold_time_by_cid(char_id)
	ret[9] = self:get_last_feed_cnt_by_cid(char_id)
	return ret
end

-- 剩余喂养次数
function Faction_dogz_obj:get_last_feed_cnt_by_cid(char_id)
	local cnt = (self.feed_list[char_id] and self.feed_list[char_id][2]) or 0
	return math.max(0, faction_dogz_config.FEED_CNT - cnt)
end

-- 互动冷却剩余时间
function Faction_dogz_obj:get_last_cold_time_by_cid(char_id)
	local time = (self.friendly_list[char_id] and self.friendly_list[char_id][3]) or 0
	return math.max(0, faction_dogz_config.PLAY_TIME_LEN + time - ev.time)
end

-- 亲密度列表 char_id:{char_id, degree, time}
function Faction_dogz_obj:get_net_friendly_list()
	local ret = {}
	local all_player_list = g_player_mgr:get_all_char() -- 获取所有玩家列表
	for _, v in pairs(self.friendly_list or {}) do
		local char_id = v[1]
		local faction = g_faction_mgr:get_faction_by_cid(char_id)
		if faction then
			local degree = v[2]
			local post = faction:get_post(char_id) -- 获取职位
			local post_name = faction:get_post_name(post) -- 获取职位名称
			local name = all_player_list[char_id]["char_nm"] -- 获取玩家名字
			local player = {name, degree, post_name}
			table.insert(ret, player)
		end
	end
	return ret
end

function Faction_dogz_obj:get_update_time()
	return self.update_time
end

function Faction_dogz_obj:set_update_time(update_time)
	self.update_time = update_time
end

function Faction_dogz_obj:get_maxPullulate()
	return faction_dogz_config.MAXPULLULATE
end

function Faction_dogz_obj:get_pullulate()
	return self.pullulate
end

function Faction_dogz_obj:get_maxMood()
	return faction_dogz_config.MAXMOOD
end

function Faction_dogz_obj:get_mood()
	return self.mood
end

function Faction_dogz_obj:get_dogz_id()
	return self.dogz_id
end

function Faction_dogz_obj:get_level()
	local level = 0
	for _, v in ipairs(faction_dogz_config.dogz_pullulate[self.dogz_id] or {}) do
		if v <= self:get_pullulate() then
			level = level + 1
		else break
		end
	end
	return level
end

function Faction_dogz_obj:unserialize_to_db(pack)
	if pack then
		self.mood = pack.mood
		self.pullulate = pack.pullulate
		self.friendly_list = self:spec_unserialize_friendly_list_to_db(pack.friendly_list)
		self.feed_list = self:spec_unserialize_feed_list_to_db(pack.feed_list)
		self.update_time = pack.update_time
	end
end

-- 喂养列表 char_id:{char_id, cnt, time} 数据库格式{char_id, cnt, time}
function Faction_dogz_obj:spec_unserialize_feed_list_to_db(feed_list)
	local ret = {}
	for _, v in pairs(feed_list or {}) do
		ret[v[1]] = v
	end
	return ret
end

-- 亲密度列表 char_id:{char_id, degree, time} 数据库格式{char_id, degree, time}
function Faction_dogz_obj:spec_unserialize_friendly_list_to_db(friendly_list)
	local ret = {}
	for _, v in pairs(friendly_list or {}) do
		ret[v[1]] = v
	end
	return ret
end

 -- char_id: {char_id, degree, time}
function Faction_dogz_obj:play(char_id)
	if self.friendly_list[char_id] == nil then
		self.friendly_list[char_id] = {char_id, 0, ev.time}
	end
	local degree = crypto.random(faction_dogz_config.add_friendly_range[1], faction_dogz_config.add_friendly_range[2]) -- 计算随机增加的亲密度值
	self.friendly_list[char_id][2] = self.friendly_list[char_id][2] + degree
	self.friendly_list[char_id][3] = ev.time
	self.mood = self.mood + faction_dogz_config.ADD_MOOD_BY_PLAY -- 心情值累加
	if self:get_mood() > self:get_maxMood() then
		self.mood = self:get_maxMood()
	end
end

function Faction_dogz_obj:train(char_id)
	if self.friendly_list[char_id] == nil then
		self.friendly_list[char_id] = {char_id, 0, ev.time}
	end
	local degree = crypto.random(faction_dogz_config.add_friendly_range[1], faction_dogz_config.add_friendly_range[2]) -- 计算随机增加的亲密度值
	self.friendly_list[char_id][2] = self.friendly_list[char_id][2] + degree
	self.friendly_list[char_id][3] = ev.time
	self.mood = self.mood + faction_dogz_config.ADD_MOOD_BY_TRAIN -- 心情值累加
	if self:get_mood() > self:get_maxMood() then
		self.mood = self:get_maxMood()
	end
end

-- char_id:{char_id, cnt, time}
function Faction_dogz_obj:feed(char_id, soulVal, cnt)
	if self.feed_list[char_id] == nil then
		self.feed_list[char_id] = {char_id, 0, ev.time}
	end
	self.feed_list[char_id][2] = self.feed_list[char_id][2] + cnt
	self.feed_list[char_id][3] = ev.time
	local val = math.floor(soulVal/2 + self.mood/5) -- 计算喂养增加的成长值
	if self:get_pullulate() >= self:get_maxPullulate() then
		val = 0
	end
	self.pullulate = self.pullulate + val -- 成长值累加
	if self:get_pullulate() > self:get_maxPullulate() then
		self.pullulate = self:get_maxPullulate()
	end
	return val
end

function Faction_dogz_obj:get_top_n_list()
	local ret = {}
	local tmp_list = {}
	for _, v in pairs(self.friendly_list or {}) do
		table.insert(tmp_list, v)
	end
	table.sort(tmp_list, function(a, b) return a[2]>b[2] end)
	local i = 0
	local n = faction_dogz_config.TOP_N
	local top_n_list = {}
	local top_n_degree = {}
	for k, v in pairs(tmp_list) do
		if v[2] and v[2]~=top_n_degree[i] then
			i = i + 1
			if i > n then
				return top_n_list
			end
			top_n_degree[i] = v[2]
			if top_n_list[i] == nil then
				top_n_list[i] = {}
			end
			table.insert(top_n_list[i], v[1])
		else
			if top_n_list[i] == nil then
				top_n_list[i] = {}
			end
			table.insert(top_n_list[i], v[1])
		end
	end
	return top_n_list
end

function Faction_dogz_obj:clear_char_in_friendly_list(char_id)
	self.friendly_list[char_id] = nil
end

function Faction_dogz_obj:clear_char_in_feed_list(char_id)
	self.feed_list[char_id] = nil
end

function Faction_dogz_obj:lost_mood_on_timer()
	if self:get_update_time() + faction_dogz_config.MOOD_LOST_TIME <= ev.time then
		self.update_time = ev.time
		local val = faction_dogz_config.MOOD_LOST_VAL
		self.mood = self.mood - val
		if self:get_mood() < 0 then
			self.mood = 0
		end
		return true
	end
end

-- char_id:{char_id, cnt, time}
function Faction_dogz_obj:reset_feed_cnt()
	for k, v in pairs(self.feed_list or {}) do
		self.feed_list[k][2] = 0
	end
end

function Faction_dogz_obj:serialize_to_db()
	local ret = {}
	ret.dogz_id = self:get_dogz_id()
	ret.mood = self:get_mood()
	ret.pullulate = self:get_pullulate()
	ret.friendly_list = self:spec_serialize_friendly_list_to_db()
	ret.feed_list = self:spec_serialize_feed_list_do_db()
	ret.update_time = self.update_time
	ret.calling = false -- 保证之前的数据而且，暂时留着
	return ret
end

function Faction_dogz_obj:spec_serialize_friendly_list_to_db()
	local ret = {}
	for _, v in pairs(self.friendly_list or {}) do
		table.insert(ret, v)
	end
	return ret
end

function Faction_dogz_obj:spec_serialize_feed_list_do_db()
	local ret = {}
	for _, v in pairs(self.feed_list or {}) do
		table.insert(ret, v)
	end
	return ret
end