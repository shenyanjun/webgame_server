
local g_u = function(val) return val end  --iconv("gbk", "utf-8")
local _arena = require("config.arena_config")
local _scene = require("config.scene_config")
local _sf = require("scene.scene_process")

local level_range = {30, 60}
local seg_len = 3


Wait_queue = oo.class(nil, "Wait_queue")

function Wait_queue:__init(match_method)
	self.wait_list = {}
	self.weight_map = {}
	self.match_method = match_method
end

function Wait_queue:pri_weight_to_group(weight)
	return math.floor(weight / 5) + 1
end

function Wait_queue:push_to_queue(room_id, weight)
	local group_id = self:pri_weight_to_group(weight)
	self.wait_list[room_id] = group_id
	if not self.weight_map[group_id] then
		self.weight_map[group_id] = {}
	end
	self.weight_map[group_id][room_id] = weight
end

function Wait_queue:pop_to_queue(room_id)
	local group_id = self.wait_list[room_id]
	if group_id then
		self.weight_map[group_id][room_id] = nil
	end
end

function Wait_queue:update_queue()
	for group_id, group in pairs(self.weight_map) do
		for room_id, weight in pairs(group) do
			group[room_id] = weight + 1
		end
	end

--[[	
	for room_id, value in pairs(update_list) do
		local group_id = value[1]
		local new_id = value[2]
		local up_method = self.weight_map[group_id][room_id]
		self.weight_map[group_id][room_id] = nil
		self.weight_map[new_id][room_id] = up_method
		self.wait_list[room_id] = new_id
	end
]]
end

function Wait_queue:to_match()
	local remove_list = {}
	local prev_id = nil
	local prev_group_limit = nil
	for group_id, group in pairs(self.weight_map) do
		for room_id, weight in pairs(group) do
			if not remove_list[room_id] then
				if (not prev_id) or (prev_group_limit < group_id) then
					prev_id = room_id
					prev_group_limit = self:pri_weight_to_group(weight)
				else
					local ret = self.match_method(prev_id, room_id)
					if 0 == ret then
						remove_list[prev_id] = group_id
						remove_list[room_id] = group_id
						prev_id = nil
					elseif 1 == ret then					--关闭左边的房间
						remove_list[prev_id] = group_id
						prev_id = room_id
						prev_group_limit = self:pri_weight_to_group(weight)
					elseif 2 == ret then					--关闭右边的房间
						remove_list[room_id] = group_id
					end
				end
			end
		end
	end
	
	for room_id, group_id in pairs(remove_list) do
		self:pop_to_queue(room_id)
	end
end


--******************************************
Arena = oo.class(nil, "Arena")


function Arena:__init()
	self.status = ARENA_STATUS.ARENA_CLOSE
	--self.mode = ARENA_MODE.MODE_FREEDOM

	self.room_list = {}

	self.access_room_list = {}
	self.access_room_list[1] = {}
	self.access_room_list[2] = {}

	self.uuid_to_room = {}
	self.type_to_room = {}

	self.type_filter = {}

	self.wait_to_match = {}
	--self.scene_to_room = {}
	
	--self.home = {}
	self.seg_size = math.floor((level_range[2] - level_range[1]) / seg_len)
	
	self.timeout_list = {}
	self.item_list = {}
	
	self.record_list = {}
	
	self.war_list = {}
	self.war_room_list = {}
end

-------------------------------------------------------设置属性--------------------------------------------------------
--[[
function Arena:set_home(map_id, pos)
	self.home.map_id = map_id
	self.home.pos = table.copy(pos)
end
]]

function Arena:add_type_filter(room_type)
	if self:pri_check_type(room_type) then
		self.type_filter[room_type] = true
		
		if self:is_close() then
			self:set_status(ARENA_STATUS.ARENA_OPEN)
		end
		
		if not self.record_list[room_type] then
			self.record_list[room_type] = {}
		end
		
		if not self.item_list[room_type] then
			local item_list = {}
			for _, item_id in pairs(_arena.regulation[room_type].item_list or {}) do
				item_list[item_id] = true
			end
			self.item_list[room_type] = item_list
		end
		
		local target = self
		self.wait_to_match[room_type] = Wait_queue(
		function(r_id, b_id)					
			local r_obj = target:pri_get_room(r_id)
			if not r_obj then
				return 1
			end
			local b_obj = target:pri_get_room(b_id)
			if not b_obj then
				return 2
			end
			if not target:pri_match_handler(r_obj, b_obj) then
				r_obj:close()
				b_obj:close()
			end
			return 0
		end
		)
	end
end

function Arena:close()
	for _, value in pairs(self.war_list) do
		value.scene:to_remove(nil)
	end
	self:set_status(ARENA_STATUS.ARENA_CLOSE)
end

function Arena:set_status(status)
	if not self:is_close() and ARENA_STATUS.ARENA_CLOSE == status then
		local remove_list = {}
		for room_id, room_obj in pairs(self.room_list) do
			if ROOM_STATUS.ROOM_WAR ~= room_obj:get_status() then
				remove_list[room_id] = room_obj
			end
		end
		
		for room_id, room_obj in pairs(remove_list) do
			room_obj:close()
		end
	end
	self.status = status
end

--function Arena:set_mode(mode)
--	self.mode = mode
--end

-----------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------获取属性--------------------------------------------------------

function Arena:is_close()
	return ARENA_STATUS.ARENA_CLOSE == self.status
end

function Arena:is_member(room_obj)
	local room_id = room_obj:get_room_id()
	if not room_id or room_obj ~= self:pri_get_room(room_id) then
		return false
	end
	return true
end

function Arena:get_status()
	return self.status
end

--function Arena:get_mode()
--	return self.mode
--end

function Arena:del_type_filter(room_type)
	if self:pri_check_type(room_type) then
		self.type_filter[room_type] = nil
		
		local is_empty = true
		for _, _ in pairs(self.type_filter) do
			is_empty = false
			break
		end
		
		if is_empty and not self:is_close() then
			self:set_status(ARENA_STATUS.ARENA_CLOSE)
		end
		
--[[
		local number = 0
		for _, _ in pairs(self.type_filter) do
			number = number + 1
		end
		if 0 == number then
			self.status = ARENA_STATUS.ARENA_CLOSE
		end
]]
	end
end

-----------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------私有函数--------------------------------------------------------

function Arena:pri_check_type(room_type)
	if ROOM_TYPE.TYPE_MIN < room_type and room_type < ROOM_TYPE.TYPE_MAX then
		return true
	end
	return false
end

function Arena:pri_get_room(room_id)
	return self.room_list[room_id]
end

function Arena:pri_filter_type(room_type)
	local new_type = nil
	--if ARENA_MODE.MODE_FREEDOM == self.mode then
	for type, _ in pairs(self.type_filter) do
		if type == room_type then
			new_type = type
			break
		end
	end
	--else
	--	new_type = self.mode
	--end
	return new_type
end

function Arena:pri_serialize_room(room_obj)
	local info = {}
	info[1] = room_obj:get_room_id()
	info[2] = room_obj:get_landlord()
	info[3] = room_obj:get_password() and 1 or 0
	info[4] = room_obj:get_room_name()
	info[5] = room_obj:get_room_type()
	info[6] = room_obj:get_member_num()
	info[7] = room_obj:is_full() and 1 or 0
	return info
end

function Arena:pri_remove_room(room_id)
	local room_obj = self:pri_get_room(room_id)
	if room_obj then
		self.room_list[room_id] = nil
		self.access_room_list[1][room_id] = nil
		self.access_room_list[2][room_id] = nil
		
		local room_uuid = room_obj:get_room_uuid()
		if room_uuid then
			self.uuid_to_room[room_uuid] = nil
		end

		local room_type = room_obj:get_room_type()
		if room_type then
			if self.type_to_room[room_type] then
				self.type_to_room[room_type][room_id] = nil
			end
			self.wait_to_match[room_type]:pop_to_queue(room_id)
		end
	end
end

function Arena:pri_select_map(type)
	local map_list = _arena.regulation[type].map_list
	local i = crypto.random(1, table.getn(map_list) + 1)
	return map_list[i]
end

function Arena:pri_room_to_team(room_obj)
	local landlord_id = room_obj:get_landlord()
	local member_list = room_obj:get_member_list()
	local team_obj = g_team_mgr:create_team(landlord_id)
	for char_id, char_obj in pairs(member_list) do
		if landlord_id ~= char_id then
			team_obj:add_obj(char_id)
		end
	end
	team_obj:syn()
	return team_obj
end

function Arena:pri_match_handler(source_obj, target_obj)
	local s_members = source_obj:get_member_list()
	local t_members = target_obj:get_member_list()
	
	source_obj:set_status(ROOM_STATUS.ROOM_WAR)
	target_obj:set_status(ROOM_STATUS.ROOM_WAR)
	
	if not s_members or not t_members then
		return false
	end
	
	local type = source_obj:get_room_type()
	local map_id = self:pri_select_map(type)
	if not map_id then
		print("Error: This is bug or not config?")
		return false
	end
	
	local s_team = self:pri_room_to_team(source_obj)
	local t_team = self:pri_room_to_team(target_obj)
	
	local mgr_obj = g_scene_mgr:get_mgr_by_id(map_id)
	if not mgr_obj then
		print("Error: Invalid map ", map_id)
		return false
	end
	
	local scene_obj = mgr_obj:alloc_scene(map_id, s_team:get_id(), t_team:get_id())
	if not scene_obj then
		return false
	end
	
	if not self.record_list[type] then
		self.record_list[type] = {}
	end
	
	
	local index = table.freeindex(self.war_list)
	
	self.war_room_list[source_obj:get_room_id()] = index
	self.war_room_list[target_obj:get_room_id()] = index
	
	self.war_list[index] = {}
	self.war_list[index].scene = scene_obj
	
	self.war_list[index].red = source_obj:get_room_uuid()
	self.war_list[index].red_name = source_obj:get_room_name()
	self.war_list[index].red_score = {}
	for char_id, char_obj in pairs(s_members) do
		self.war_list[index].red_score[char_id] = {char_obj:get_name(), char_obj:get_occ(), char_obj:get_level(), 0, 0, 0} --名称， 职业， 等级， 杀人数， 被杀数, 得分
	end
	
	self.war_list[index].blue = target_obj:get_room_uuid()
	self.war_list[index].blue_name = target_obj:get_room_name()
	self.war_list[index].blue_score = {}
	for char_id, char_obj in pairs(t_members) do
		self.war_list[index].blue_score[char_id] = {char_obj:get_name(), char_obj:get_occ(), char_obj:get_level(), 0, 0, 0} --名称， 职业， 等级， 杀人数， 被杀数, 得分
	end
	
	local reg = _arena.regulation[type]
	local target = self
	scene_obj:start(
		function(scene_obj)
			return target:on_scene_timeout(index)
		end
		, function(char_id, killer_id)
			return target:on_score_update(index, char_id, killer_id)
		end
		, reg.life_cycle, reg.relive_time, reg.frezzing_time, self.item_list[type])
	--local map_info = f_scene_config()[map_id]
	local map_info = _scene._config[map_id]
	
	local pkt = {}
	pkt[1] = source_obj:get_room_name()
	pkt[2] = target_obj:get_room_name()
	pkt[3] = reg.frezzing_time
	pkt[4] = reg.life_cycle
	
	for char_id, char_obj in pairs(s_members) do
		g_cltsock_mgr:send_client(char_id, CMD_MAP_ARENA_NOTICE_MATCH_S, pkt)
		_sf.change_scene_cm(char_id, map_id, map_info.entry[1])
		if self.record_list[type][char_id] then
			self.record_list[type][char_id] = self.record_list[type][char_id] + 1
		else
			self.record_list[type][char_id] = 1
		end
	end

	for char_id, char_obj in pairs(t_members) do
		g_cltsock_mgr:send_client(char_id, CMD_MAP_ARENA_NOTICE_MATCH_S, pkt)
		_sf.change_scene_cm(char_id, map_id, map_info.entry[2])
		if self.record_list[type][char_id] then
			self.record_list[type][char_id] = self.record_list[type][char_id] + 1
		else
			self.record_list[type][char_id] = 1
		end
		local str = string.format("Arena match %d, char_id: %d, count: %d", type,char_id, self.record_list[type][char_id])
		g_arena_log:write(str)
	end
	
	return true
end

function Arena:pri_get_avg_lv(room_type, room_obj)
	local members = room_obj:get_member_list()
	local total_lv = 0
	for char_id, char_obj in pairs(members) do
		total_lv = total_lv + char_obj:get_level()
	end
	return math.max(math.floor(total_lv / room_obj:get_member_num()) - _arena.regulation[room_type].level, 0)
end

function Arena:on_timer(tm)
	local time = ev.time
	for k, value in pairs(self.timeout_list) do
		if value[1] <= ev.time then
			self.timeout_list[k] = nil
			value[2]()
		end
	end

	for type, queue in pairs(self.wait_to_match) do
--[[
		for group_id, group in pairs(queue.weight_map) do
			print("----", group_id)
			for room_id, w in pairs(group) do
				print("-----------", room_id, queue:pri_weight_to_group(w))
			end
		end
]]--
		queue:to_match()
		queue:update_queue()
	end
end

function Arena:pri_room_to_match(room_obj)
	local room_id = room_obj:get_room_id()
	local type = room_obj:get_room_type()

	room_obj:set_status(ROOM_STATUS.ROOM_LOCK)
	local lv = self:pri_get_avg_lv(type, room_obj)
	local now = ev.time
	self.wait_to_match[type]:push_to_queue(room_id, lv)
end 

function Arena:pri_remove_from_match(room_obj)
	local room_id = room_obj:get_room_id()
	local type = room_obj:get_room_type()
	self.wait_to_match[type]:pop_to_queue(room_id)
	room_obj:set_status(ROOM_STATUS.ROOM_FINE)
end

-----------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------序列化函数------------------------------------------------------

function Arena:serialize_room(room_id)
	local room_obj = self:pri_get_room(room_id)
	if not room_obj then
		return E_ARENA_ARENA_INVALID_ROOM, nil
	end
	local info = {}
	info.room = self:pri_serialize_room(room_obj)
	info.list = room_obj:serialize_members()
	return E_SUCCESS, info
end

function Arena:serialize_to_net()
	local info_list = {}
	for room_id, room_obj in pairs(self.room_list) do
		table.insert(info_list, self:pri_serialize_room(room_obj))		
	end
	return info_list
end

-----------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------搜索函数--------------------------------------------------------

function Arena:get_char_room(char_id)
	local char_obj = g_obj_mgr:get_obj(char_id)
	if not char_obj then 
		return E_ARENA_PLAYER_OFFLINE, nil
	end
	
	local room_uuid = char_obj:get_room()
	if not room_uuid then
		return E_ARENA_PLAYER_NO_ROOM, nil
	end

	local room_obj = self.uuid_to_room[room_uuid]
	if not room_obj then
		char_obj:set_room(nil)
		return E_ARENA_PLAYER_NO_ROOM, nil
	end

	return E_SUCCESS, room_obj:get_room_id()
end

-----------------------------------------------------------------------------------------------------------------------

function Arena:set_ready(char_id, is_ready)
	local error, room_id = self:get_char_room(char_id)
	if E_SUCCESS == error then
		local room_obj = self:pri_get_room(room_id)
		if room_obj then
			error = room_obj:set_member_ready(char_id, is_ready)
		else
			error = E_ARENA_PLAYER_NO_ROOM
		end
	end
	return error
end

function Arena:add_to_room(room_id, char_id, pwd)
	local room_obj = self:pri_get_room(room_id)
	if not room_obj then
		return E_ARENA_ARENA_INVALID_ROOM
	end
	return room_obj:add_member(char_id, pwd)
end

function Arena:fast_add_to_room(char_id, room_type)
	if not self:pri_check_type(room_type) then
		return E_ARENA_ARENA_INVALID_TYPE, nil
	end

	if ROOM_TYPE.TYPE_1V1 == room_type then
		local error, room_id = self:build_room(char_id, nil, ROOM_TYPE.TYPE_1V1, ROOM_ACCESS.ACCESS_PUBLIC, nil)
		if E_SUCCESS == error then
			local room_obj = self:pri_get_room(room_id)
			if room_obj then
				room_obj:set_member_ready(char_id, true)
			end
		end
		return error, room_id
	else
		if self.type_to_room[room_type] then
			for room_id, room_obj in pairs(self.type_to_room[room_type]) do
				local error = room_obj:add_member(char_id, nil)
				if E_SUCCESS == error then
					return error, room_id
				end
			end
		end
	end

	return E_ARENA_NOT_COMPATIBLE_ROOM, nil 
end

function Arena:kickout_player_from_room(source_id, target_id)
	local error, room_id = self:get_char_room(source_id)
	if E_SUCCESS == error then
		local room_obj = self:pri_get_room(room_id)
		if room_obj then
			error = room_obj:kickout(source_id, target_id)
			if E_SUCCESS == error then
				self:notice_kickout(room_id, source_id, target_id)
			end
		else
			error = E_ARENA_ARENA_INVALID_ROOM
		end
	end
	return error, room_id
end

function Arena:remove_player_from_room(char_id)
	local error, room_id = self:get_char_room(char_id)
	if E_SUCCESS == error then
		local room_obj = self:pri_get_room(room_id)
		if room_obj then
			error = room_obj:remove_member(char_id)
		else
			error = E_ARENA_ARENA_INVALID_ROOM
		end
	end
	return error, room_id
end

function Arena:build_room(char_id, room_name, room_type, room_access, room_pwd)
	if self:is_close() then																--关闭状态不能创建房间
		return E_ARENA_ARENA_CLOSE, nil
	end

	room_type = self:pri_filter_type(room_type)
	if not room_type then
		return E_ARENA_ARENA_INVALID_TYPE, nil
	end

	if ROOM_ACCESS.ACCESS_PROTECTED ~= room_access then
		room_pwd = nil
	elseif not room_pwd then
		return E_ARENA_ARENA_INVALID_PASSWORD, nil
	end

	local char_obj = g_obj_mgr:get_obj(char_id)
	if not char_obj then 
		return E_ARENA_PLAYER_OFFLINE, nil
	end
	
	if char_obj:get_level() < _arena.regulation[room_type].level then
		return E_ARENA_PLAYER_LEVEL, nil
	end

	if not room_name then
		room_name = string.format(g_u("%s的队伍"), char_obj:get_name())
	end

	local room_id = table.freeindex(self.room_list)
	local room_obj = Arena_room(self, room_id, room_name, room_type, room_pwd, _arena.regulation[room_type].level)
	local error = room_obj:add_member(char_id, room_pwd)
	if E_SUCCESS == error then
		error = room_obj:set_landlord(char_id)
		if E_SUCCESS == error then
			self.room_list[room_id] = room_obj
			if ROOM_ACCESS.ACCESS_PROTECTED ~= room_access then
				self.access_room_list[1][room_id] = room_obj
			else
				self.access_room_list[2][room_id] = room_obj
			end

			self.uuid_to_room[room_obj:get_room_uuid()] = room_obj
			if not self.type_to_room[room_type] then
				self.type_to_room[room_type] = {}
			end
			self.type_to_room[room_type][room_id] = room_obj
		end
	end

	return error, room_id
end

-----------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------回调函数--------------------------------------------------------

function Arena:on_room_add_member(room_obj, add_member_id)						--房间增加成员通知
	if room_obj then
		if self:is_member(room_obj) then
			self:notice_room_update(room_obj:get_room_id())
		end
	end
end

function Arena:on_room_member_set_ready(room_obj, char_id, is_ready)			--房间成员改变准备状态通知
	if room_obj then
		if self:is_member(room_obj) then
			self:notice_room_update(room_obj:get_room_id())
			if is_ready then
				if room_obj:is_all_ready() then
					self:pri_room_to_match(room_obj)
				end
			elseif ROOM_STATUS.ROOM_LOCK == room_obj:get_status() then
				self:pri_remove_from_match(room_obj)
			end
		end
	end
end

function Arena:on_room_remove_member(room_obj, remove_member_id)				--房间删除成员通知
	if room_obj then
		if self:is_member(room_obj) then
			if room_obj:is_empty() then
				room_obj:close()
			else
				self:notice_room_update(room_obj:get_room_id())
			end
		end
	end
end

function Arena:on_room_close(room_obj)											--房间关闭通知
	if room_obj then
		self:notice_room_close(room_obj)
		if self:is_member(room_obj) then
			local room_id = room_obj:get_room_id()
			local index = self.war_room_list[room_id]
			if index then
				local war = self.war_list[index]
				if war then
					local scene_obj = war.scene
					if scene_obj then
						scene_obj:to_remove(nil)
					end
				end
			end
			self:pri_remove_room(room_id)
		end
	end
end

function Arena:on_result_timeout(scene_obj, r_obj, b_obj)
	if not scene_obj then
		return
	end
	
	if r_obj then
		r_obj:set_status(ROOM_STATUS.ROOM_FINE)
	end
	
	if b_obj then
		b_obj:set_status(ROOM_STATUS.ROOM_FINE)
	end
	
	local mgr_obj = g_scene_mgr:get_mgr_by_id(scene_obj:get_id())
	mgr_obj:delete_copy_by_id(scene_obj:get_copy_id())
	self:notice_room_return(b_obj)
	self:notice_room_return(r_obj)
end

function Arena:on_scene_timeout(index)
	local war = self.war_list[index]
	self.war_list[index] = nil
	if not war then
		return
	end
	
	local scene_obj = war.scene
	if not scene_obj then
		return
	end
	local r_obj = war.red and self.uuid_to_room[war.red]
	local b_obj = war.blue and self.uuid_to_room[war.blue]
	local result_pkt = {}
	
	result_pkt.list = {}
	result_pkt.list[1] = {}
	result_pkt.list[1][1] = war.red_name
	result_pkt.list[1][2] = {}
	for _, list in pairs(war.red_score) do
		table.insert(result_pkt.list[1][2], table.copy(list))
	end
	
	result_pkt.list[2] = {}
	result_pkt.list[2][1] = war.blue_name
	result_pkt.list[2][2] = {}
	for _, list in pairs(war.blue_score) do
		table.insert(result_pkt.list[2][2], table.copy(list))
	end
	
	result_pkt.timeout = 6
	
	local red_score = 0
	for _, list in pairs(war.red_score or {}) do
		red_score = red_score + list[4] 
	end
	
	local blue_score = 0
	for _, list in pairs(war.blue_score or {}) do
		blue_score = blue_score + list[4] 
	end
	
	if r_obj and b_obj then
		if red_score > blue_score then
			result_pkt.win = 1
		elseif red_score < blue_score then
			result_pkt.win = 2
		else
			result_pkt.win = 0
		end
	elseif r_obj then
		result_pkt.win = 1
	elseif b_obj then
		result_pkt.win = 2
	end
	
	if r_obj then
		self.war_room_list[r_obj:get_room_id()] = nil
		self:notice_room_end(r_obj, result_pkt)
	end
	
	if b_obj then
		self.war_room_list[b_obj:get_room_id()] = nil
		self:notice_room_end(b_obj, result_pkt)
	end
	
	table.insert(
		self.timeout_list
		, {
			ev.time + 5
			, function()
				if r_obj then
					r_obj:set_status(ROOM_STATUS.ROOM_FINE)
				end
				if b_obj then
					b_obj:set_status(ROOM_STATUS.ROOM_FINE)
				end
				
				local mgr_obj = g_scene_mgr:get_mgr_by_id(scene_obj:get_id())
				mgr_obj:delete_copy_by_id(scene_obj:get_copy_id())
				self:notice_room_return(b_obj)
				self:notice_room_return(r_obj)
				if ARENA_STATUS.ARENA_CLOSE == self.status then
					if b_obj then b_obj:close() end
					if r_obj then r_obj:close() end
				end
			end
		}
	)
end

function Arena:on_score_update(index, char_id, killer_id)
	local war = self.war_list[index]
	if not war then
		return
	end
	
	if war.red_score[char_id] then
		war.red_score[char_id][5] = war.red_score[char_id][5] + 1
		if not war.blue_score[killer_id] then
			print("Error: not score record ", killer_id) 
		else
			war.blue_score[killer_id][4] = war.blue_score[killer_id][4] + 1
		end
	elseif war.blue_score[char_id] then
		war.blue_score[char_id][5] = war.blue_score[char_id][5] + 1
		if not war.red_score[killer_id] then
			print("Error: not score record ", killer_id) 
		else
			war.red_score[killer_id][4] = war.red_score[killer_id][4] + 1
		end
	else
		print("Error: not score record ", char_id) 
	end
	
	local red_score = 0
	for _, list in pairs(war.red_score or {}) do
		red_score = red_score + list[4] 
	end
	
	local blue_score = 0
	for _, list in pairs(war.blue_score or {}) do
		blue_score = blue_score + list[4] 
	end
	
	self:notice_score_update(war.red and self.uuid_to_room[war.red], red_score, blue_score)
	self:notice_score_update(war.blue and self.uuid_to_room[war.blue], red_score, blue_score)
end

-----------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------通知函数--------------------------------------------------------

function Arena:notice_room_update(room_id)
	local room_obj = self:pri_get_room(room_id)
	if room_obj then
		local error, result_pkt = self:serialize_room(room_id)
		if E_SUCCESS == error then
			result_pkt.result = E_SUCCESS
			local member_list = room_obj:get_member_list()
			for char_id, _ in pairs(member_list or {}) do 
				g_cltsock_mgr:send_client(char_id, CMD_MAP_ARENA_GET_ROOM_INFO_S, result_pkt)
			end
		end
	end
end

function Arena:notice_kickout(room_id, source_id, target_id)
	local result_pkt = {}
	result_pkt.room_id = room_id
	result_pkt.char_id = source_id
	g_cltsock_mgr:send_client(target_id, CMD_MAP_ARENA_NOTICE_REMOVE_S, result_pkt)
end

function Arena:notice_room_close(room_obj)
	if room_obj then
		local member_list = room_obj:get_member_list()
		local result_pkt = {}
		result_pkt.room_id = room_obj:get_room_id()
		for char_id, _ in pairs(member_list or {}) do
			g_cltsock_mgr:send_client(char_id, CMD_MAP_ARENA_ROOM_CLOSE_S, result_pkt)
		end
	end
end

function Arena:notice_room_end(room_obj, result_pkt)
	if room_obj then
		local member_list = room_obj:get_member_list()	
		for char_id, _ in pairs(member_list or {}) do
			g_cltsock_mgr:send_client(char_id, CMD_MAP_ARENA_NOTICE_END_S, result_pkt)
		end
	end
end

function Arena:notice_room_return(room_obj)
	if room_obj then
		local member_list = room_obj:get_member_list()
		local result_pkt = {}
		result_pkt.room_id = room_obj:get_room_id()
		for char_id, _ in pairs(member_list or {}) do
			g_cltsock_mgr:send_client(char_id, CMD_MAP_ARENA_NOTICE_RETURN_S, result_pkt)
		end
	end
end

function Arena:notice_score_update(room_obj, red_score, blue_score)
	if room_obj then
		local member_list = room_obj:get_member_list()
		local result_pkt = {}
		result_pkt[1] = red_score
		result_pkt[2] = blue_score
		for char_id, _ in pairs(member_list or {}) do
			g_cltsock_mgr:send_client(char_id, CMD_MAP_ARENA_SCORE_UPDATE_S, result_pkt)
		end
	end
end