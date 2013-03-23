-- 帮派神兽
-- CodeBy:cailizhong
-- 2012/8/10

Faction_dogz_container = oo.class(nil, "Faction_dogz_container")

function Faction_dogz_container:__init(faction_id)
	self.faction_id = faction_id -- 帮派id
	self.dogz_obj = nil -- 帮派神兽对象
	self.update_time = os.date("%x", os.time())
	self.data_update_time = ev.time -- 数据定时保存用
end

function Faction_dogz_container:create_dogz_obj(dogz_id)
	self.dogz_obj = Faction_dogz_obj(dogz_id)
end

function Faction_dogz_container:get_faction_id()
	return self.faction_id
end

function Faction_dogz_container:get_dogz_obj()
	return self.dogz_obj
end

function Faction_dogz_container:serialize_to_db()
	local ret = {}
	ret.dogz_info = {}
	if self.dogz_obj then
		table.insert(ret.dogz_info, self.dogz_obj:serialize_to_db())
	end
	ret.update_time = self.update_time
	return ret
end

function Faction_dogz_container:unserialize_to_db(pack)
	if pack.dogz_info then
		self.update_time = pack.update_time
		for k, v in pairs(pack.dogz_info) do
			if v.dogz_id then
				local dogz_obj = Faction_dogz_obj(v.dogz_id)
				dogz_obj:unserialize_to_db(v)
				self.dogz_obj = dogz_obj
				return 0
			end
		end
	end
end

function Faction_dogz_container:get_dogz_info_by_cid(char_id)
	local ret = {}
	if self.dogz_obj then
		ret = self.dogz_obj:get_dogz_info_by_cid(char_id)
	end
	return ret
end

function Faction_dogz_container:can_feed(char_id, soul)
	if self.dogz_obj then
		local cnt = self.dogz_obj:get_last_feed_cnt_by_cid(char_id)
		if cnt < table.getn(soul) then
			return 31306
		else return 0
		end
	else return 31304
	end
end

function Faction_dogz_container:can_play_or_train(char_id)
	if self.dogz_obj then
		if self.dogz_obj:get_last_cold_time_by_cid(char_id) ~= 0 then
			return 31307
		else return 0
		end
	else return 31304
	end
end

function Faction_dogz_container:play_dogz(char_id)
	if self.dogz_obj then
		self.dogz_obj:play(char_id)
	end
end

function Faction_dogz_container:train_dogz(char_id)
	if self.dogz_obj then
		self.dogz_obj:train(char_id)
	end
end

function Faction_dogz_container:feed_dogz(char_id, soulVal, cnt)
	if self.dogz_obj then
		return self.dogz_obj:feed(char_id, soulVal, cnt)
	end
end

function Faction_dogz_container:can_call()
	if self.dogz_obj then
		local level = self.dogz_obj:get_level()
		if level <= 0 then
			return 31310
		else return 0, level
		end
	else return 31304
	end
end

function Faction_dogz_container:get_top_n_list()
	local ret = {}
	if self.dogz_obj then
		ret = self.dogz_obj:get_top_n_list()
	end
	return ret
end

function Faction_dogz_container:call_dogz()
	self.dogz_obj = nil
end

function Faction_dogz_container:get_update_time()
	return self.update_time
end

function Faction_dogz_container:get_data_update_time()
	return self.data_update_time
end

function Faction_dogz_container:clear_record_by_cid(char_id)
	if self.dogz_obj then
		self.dogz_obj:clear_char_in_friendly_list(char_id)
		self.dogz_obj:clear_char_in_feed_list(char_id)
	end
end

function Faction_dogz_container:mood_on_timer()
	if self.dogz_obj then
		local flag = self.dogz_obj:lost_mood_on_timer()
		if flag == true then
			g_faction_dogz_mgr:update_faction_dogz_info(self:get_faction_id())
		end
	end
end

function Faction_dogz_container:data_on_timer()
	if self.dogz_obj then
		if self:get_data_update_time() + crypto.random(1, 180)*3 <= ev.time then
			self.data_update_time = ev.time
			Faction_dogz_db:update(self:get_faction_id()) -- 保存到数据库
		end
	end
end

function Faction_dogz_container:reset_on_timer()
	if self.dogz_obj then
		local update_time = os.date("%x", os.time())
		if self:get_update_time() ~= update_time then
			self.update_time = update_time
			self.dogz_obj:reset_feed_cnt()
			g_faction_dogz_mgr:update_faction_dogz_info(self:get_faction_id())
		end
	end
end

function Faction_dogz_container:exit_save()
	if self.dogz_obj then
		Faction_dogz_db:update(self:get_faction_id()) -- 保存到数据库
	end
end






