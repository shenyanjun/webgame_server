
Arena_room = oo.class(nil, "Arena_room")

function Arena_room:__init(arena_obj, room_id, room_name, room_type, room_pwd, req_level)
	self.size = 1										--房间人数上限
	if ROOM_TYPE.TYPE_1V1 == room_type then
		self.size = 1
	elseif ROOM_TYPE.TYPE_2V2 == room_type then
		self.size = 2
	elseif ROOM_TYPE.TYPE_3V3 == room_type then
		self.size = 3
	end

	self.arena_obj = arena_obj							--宿主对象,用于通知状态的改变,多宿主对象时可以考虑重构到观察者
	self.room_id = room_id								--房间ID
	self.type = room_type								--房间类型
	self.name = room_name								--房间名
	self.password = room_pwd							--房间密码,为NIL表示没密码
	self.uuid = crypto.uuid()							--房间的UUID
	self.member_list = {}								--成员列表
	self.ready_list = {}								--准备中成员列表
	self.member_number = 0								--成员数
	self.landlord = nil									--房主的ID
	self.status	= ROOM_STATUS.ROOM_FINE					--房间状态,如果状态复杂,可以考虑用状态模式
	self.key_list = {}
	self.req_level = req_level or 30
end

function Arena_room:get_room_id()
	return self.room_id
end

function Arena_room:get_room_uuid()
	return self.uuid
end

function Arena_room:get_landlord()
	return self.landlord
end

function Arena_room:get_password()
	return self.password
end

function Arena_room:get_room_name()
	return self.name
end

function Arena_room:get_room_type()
	return self.type
end

function Arena_room:get_member_num()
	return self.member_number
end

function Arena_room:get_status()
	return self.status
end

function Arena_room:set_status(status)
	if ROOM_STATUS.ROOM_FINE == status and (ROOM_STATUS.ROOM_LOCK == self.status or ROOM_STATUS.ROOM_WAR == self.status) then
		for char_id, _ in pairs(self.member_list) do
			self.ready_list[char_id] = nil
		end
	end
	self.status = status
end

function Arena_room:is_full()
	return self.member_number >= self.size
end

function Arena_room:is_empty()
	return self.member_number < 1
end

function Arena_room:set_landlord(char_id)
	if not self.member_list[char_id] then
		return E_ARENA_ROOM_INVALID_MEMBER
	end

	self.landlord = char_id
	return E_SUCCESS
end

function Arena_room:add_member(char_id, pwd)		--房间增加成员
	if ROOM_STATUS.ROOM_FINE ~= self:get_status() then
		return E_ARENA_ROOM_IS_LOCK
	end

	if self.password and pwd ~= self.password then
		return E_ARENA_ARENA_INVALID_PASSWORD
	end

	if self:is_full() then
		return E_ARENA_ROOM_IS_FULL
	end

	if self.member_list[char_id] then		--避免重复加入
		return E_SUCCESS
	end

	local obj = g_obj_mgr:get_obj(char_id)
	if not obj then 
		return E_ARENA_PLAYER_OFFLINE
	end
	
	if obj:get_level() < self.req_level then
		return E_ARENA_PLAYER_LEVEL
	end
	
	if obj:get_team() then
		return E_ARENA_PLAYER_ON_TEAM
	end

	if obj:get_room() then
		return E_ARENA_PLAYER_ALREADY_ADD
	end
	
	self.member_list[char_id] = obj
	self.member_number = self.member_number + 1
	
	local target = self
	self.key_list[char_id] = obj:register_unload_event(
		function(human_obj)
			return target:on_char_unload(human_obj)
		end
	)				--注册回调,玩家下线时进行通知
	obj:set_room(self:get_room_uuid())

	if self.arena_obj then
		self.arena_obj:on_room_add_member(self, char_id)
	end

	return E_SUCCESS
end

function Arena_room:pri_remove_member(char_obj, char_id)			--内部调用,外部调用后果自负
	char_obj:set_room(nil)
	char_obj:remove_unload_event_by_key(self.key_list[char_id])

	self.ready_list[char_id] = nil
	self.member_list[char_id] = nil
	self.member_number = self.member_number - 1

	if self.landlord == char_id then
		self.landlord = nil
		for k, v in pairs(self.member_list) do		--获取下一个在房间的用户
			self.landlord = k
		 	break
		end
	end

	self:set_member_ready(self.landlord, nil)
	f_team_kickout(char_obj)
--[[	
	local team_id = char_obj:get_team()
	if team_id then
		local team_obj = g_team_mgr:get_team_obj(team_id)
		if team_obj then
			team_obj:del_obj(char_id)
			if 0 == team_obj:get_line_count() then
				g_team_mgr:del_team(team_id)
				team_obj:remove()
			else
				team_obj:syn()
			end
		end
	end
]]	
	if self.arena_obj then							--成员删除通知
		self.arena_obj:on_room_remove_member(self, char_id)
	end
end

function Arena_room:remove_member(char_id)
	if ROOM_STATUS.ROOM_FINE ~= self:get_status() then
		return E_ARENA_ROOM_IS_LOCK
	end

	local char_obj = self.member_list[char_id]
	if not char_obj then
		return E_ARENA_NO_PLAYER
	end

	self:pri_remove_member(char_obj, char_id)

	return E_SUCCESS
end

function Arena_room:on_char_unload(char_obj)	--玩家下线回调
	if not char_obj then
		return
	end
	self:pri_remove_member(char_obj, char_obj:get_id())
end

function Arena_room:close()
	if ROOM_STATUS.ROOM_CLOSE == self:get_status() then
		return
	end
	self:set_status(ROOM_STATUS.ROOM_CLOSE)										--防止重复进行关闭

	for obj_id, obj in pairs(self.member_list) do								--断开与所有玩家的关联
		print("Warning: Arena_room:close buf player %d on room", obj_id)
		obj:set_room(nil)
		obj:remove_unload_event_by_key(self.key_list[obj_id])
		--obj:remove_unload_event(self)
	end
	
	if self.arena_obj then														--通知宿主关闭事件
		self.arena_obj:on_room_close(self)
		self.arena_obj = nil
	end

	self.member_list = {}
	self.member_number = 0
end

function Arena_room:get_member_list()
	return self.member_list
end

function Arena_room:serialize_members()
	local member_list = self:get_member_list()
	local info_list = {}
	for char_id, char_obj in pairs(member_list or {}) do
		local member_info = {}
		member_info[1] = char_id									--成员ID
		member_info[2] = (self.landlord == char_id) and 1 or 0		--成员状态: 0为普通,1代表房主
		member_info[3] = char_obj:get_occ()							--成员职业
		member_info[4] = char_obj:get_level()						--成员等级
		member_info[5] = self:is_ready(char_id) and 1 or 0			--是否准备
		member_info[6] = char_obj:get_sex()							--性别
		member_info[7] = char_obj:get_name()						--名称
		table.insert(info_list, member_info)
	end
	return info_list
end

function Arena_room:is_ready(char_id)
	return self.ready_list[char_id] and true or false
end

function Arena_room:set_member_ready(char_id, is_ready)
	--if ROOM_STATUS.ROOM_FINE ~= self:get_status() then
		--return E_ARENA_ROOM_IS_LOCK
	--end

	local char_obj = self.member_list[char_id]
	if not char_obj then
		return E_ARENA_NO_PLAYER
	end

	if char_id ~= self.landlord and self:is_all_ready() then
		return E_ARENA_PLAYER_NO_ACCESS
	end

	self.ready_list[char_id] = is_ready
	if char_id == self.landlord and is_ready then
		if not self:is_all_ready() then
			self.ready_list[char_id] = nil
			return E_ARENA_NOT_ALL_READY
		end
	end

	if self.arena_obj then
		self.arena_obj:on_room_member_set_ready(self, char_id, is_ready)
	end

	return E_SUCCESS
end

function Arena_room:is_all_ready()
	if not self:is_full() then
		return false
	end
	for char_id, _ in pairs(self.member_list or {}) do
		if not self.ready_list[char_id] then
			return false
		end
	end
	return true
end

function Arena_room:kickout(source_id, target_id)
	local error = E_SUCCESS
	if self.landlord ~= source_id or source_id == target_id then
		error = E_ARENA_PLAYER_NO_ACCESS
	else
		error = self:remove_member(target_id)
	end
	return error
end