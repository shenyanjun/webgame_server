local g_u = function(val) return val end   --iconv("gbk", "utf-8")
local _arena = require("config.arena_config")

Arena_mgr = oo.class(nil, "Arena_mgr")

function Arena_mgr:__init()
	self.arena_list = {}
	self.open_event = nil
	self.close_event = nil
	self.notify_events = {}
	self.click_timer = nil
	self:build_from_config()
end

function Arena_mgr:build_from_config()
	local home = _arena.arena_home
	g_scene_mgr:get_scene_mgr(MAP_TYPE_ARENA):set_home(home[1], home[2])
	local arena_freedom = Arena()
--	arena_freedom:add_type_filter(ROOM_TYPE.TYPE_1V1)
--	arena_freedom:add_type_filter(ROOM_TYPE.TYPE_3V3)
--	arena_freedom:set_status(ARENA_STATUS.ARENA_OPEN)
	self:pri_register_arena(0, arena_freedom)
	return E_SUCCESS
end

function Arena_mgr:init_event(click_timer)
	self.click_timer = click_timer
	self:on_new_day()
end

function Arena_mgr:on_new_day()
	if not f_is_pvp() then
		return 
	end
	
	local today = os.date("*t")
	today.hour = 0
	today.min = 0
	today.sec = 0
	local tomorrow = os.time(date) + 86400
	self:pri_add_event(today)

	self.click_timer:regster(self, self.on_new_day, tomorrow)
end

function Arena_mgr:pri_add_notify_event(config, start)		--配置信息，比赛开始时间
	for _, v in pairs(config.notify) do
		local msg = {}
		f_construct_content(msg, g_u(v[1]), 16)
		self.click_timer:regster(
			self
			, function(mgr_obj)
				if config.is_open then
					f_cmd_sysbd(msg)
				end
			end
			, start + (v[2] * 60)
			, 60
		)
	end
end

function Arena_mgr:pri_add_open_event(type, config, time, offset)
	self.open_event = self.click_timer:regster(
		self
		, function(mgr_obj)
			arena_obj = mgr_obj:get_arena(0)
			if arena_obj and config.is_open then
				arena_obj:add_type_filter(type)
				self.open_event = nil
				mgr_obj:pri_add_close_event(type, config, time + offset)
			end
		end
		, time
		, offset
	)
end

function Arena_mgr:pri_add_close_event(type, config, time)
	self.close_event = self.click_timer:regster(
		self
		, function(mgr_obj)
			arena_obj = mgr_obj:get_arena(0)
			if arena_obj and config.is_open then
				self.close_event = nil
				arena_obj:del_type_filter(type)
			end
		end
		, time
	)
end

function Arena_mgr:pri_add_reward_event(type, config, time)
	self.click_timer:regster(
		self
		, function(mgr_obj)
			arena_obj = mgr_obj:get_arena(0)
			if arena_obj then
				local record_list = arena_obj.record_list[type]
				if record_list then
					arena_obj.record_list[type] = {}
					local pkt = {}
					pkt.char_lst = {}
					local reward_config = config.reward
					local count = reward_config[1][4]
					for char_id, v in pairs(record_list) do
						if v >= count then
							local val = {}
							val.char_id = char_id
							val.email_id = 0
							table.insert(pkt.char_lst, val)
						end
					end
					pkt.email_title = g_u(reward_config[1][1])
					pkt.email_content = g_u(reward_config[1][2])
					local item_list = {}
					for k, v in pairs(reward_config[1][3]) do
						local item = {}
						item.item_id = v[1]
						item.count = v[2]
						table.insert(item_list, item)
					end
					pkt.item = f_gift_bag_build({}, item_list)
					g_svsock_mgr:send_server_ex(WORLD_ID, 0, CMD_M2W_ADD_GOODS_ACK, pkt)
				end
			end
		end
		, time
	)
end

function Arena_mgr:pri_add_event(today)
	local index = today.wday
	local time = os.time(today)
	for type, config in pairs(_arena.regulation) do
		if config.is_open and config.open_time[index] then
			local hour = config.open_time[index][1][1]
			local min = config.open_time[index][1][2]
			local start_time = time + hour * 3600 + min * 60
			local offset = config.open_time[index][2] * 60
			self:pri_add_notify_event(config, start_time)
			self:pri_add_open_event(type, config, start_time, offset)
			self:pri_add_reward_event(type, config, start_time + offset + 30 * 60)
		end
	end
end

function Arena_mgr:get_click_param()
	return self, self.on_timer, 3, nil
end

function Arena_mgr:on_timer(tm)
	for _, arena_obj in pairs(self.arena_list) do
		arena_obj:on_timer(tm)
	end
end

function Arena_mgr:pri_register_arena(arena_id, arena_obj)
	if self.arena_list[arena_id] then
		return E_ARENA_ARENA_ALREADY_REGISTER
	end

	self.arena_list[arena_id] = arena_obj
	return E_SUCCESS
end

function Arena_mgr:pri_unregister_arena(arena_id)
	self.arena_list[arena_id] = nil
	return E_SUCCESS
end

function Arena_mgr:get_arena(arena_id)
	return self.arena_list[arena_id]
end 

function Arena_mgr:get_arena_list()
	return self.arena_list
end

function Arena_mgr:get_arena(arena_id)
	return self.arena_list[arena_id]
end

function Arena_mgr:get_active_arena(arena_id)
	local error = E_SUCCESS
	local arena_obj = self.arena_list[arena_id]
	if not arena_obj then
		error = E_ARENA_ARENA_INVALID_ID
	elseif ARENA_STATUS.ARENA_OPEN ~= arena_obj:get_status() then
		error = E_ARENA_ARENA_CLOSE
	end
	return error, arena_obj
end

function Arena_mgr:start()
	for type, config in pairs(_arena.regulation) do
		config.is_open = true
	end
end

function Arena_mgr:stop()
	for type, config in pairs(_arena.regulation) do
		config.is_open = false
	end

	for _, arena_obj in pairs(self.arena_list) do
		arena_obj:close()
	end
end

function Arena_mgr:close()
end
