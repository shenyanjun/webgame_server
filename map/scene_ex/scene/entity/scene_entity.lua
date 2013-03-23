local hidden_scene = {
	[MAP_INFO_1] = 50,
	[MAP_INFO_355] = 50
}   --同步限制,限制的地图以及上限


Scene_entity = oo.class(Scene_entry, "Scene_entity")

function Scene_entity:__init(map_id, map_obj)
	Scene_entry.__init(self, map_id)
	self.map_obj = map_obj or g_scene_config_mgr:load_map(map_id)			-- 地图对象
	self.door_obj_mgr = Scene_obj_container()								-- 门管理器 （缓冲作用）
	self.obj_mgr = Scene_obj_mgr()											-- 对象容器管理器 
	self.key = {self.id}
	self.status = SCENE_STATUS.OPEN
end

-----------------------------------------------场景实例化---------------------------------------------

function Scene_entity:instance()
	self.obj_mgr:instance(self.map_obj:get_w(), self.map_obj:get_h())
end

-----------------------------------------------基本属性-----------------------------------------------

function Scene_entity:get_human_count()
	return self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN):get_obj_count() + self.door_obj_mgr:get_obj_count()
end

function Scene_entity:get_key()
	return self.key
end

function Scene_entity:get_status()
	return self.status
end

function Scene_entity:get_status_info()
	return {self.id, self:get_name()
			, self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN):get_obj_count()
			, self:get_limit()
			, self:get_status()}
end

function Scene_entity:get_map_obj()
	return self.map_obj
end

function Scene_entity:is_validate_pos(pos)
	return pos[1] >= 0 and pos[1] < self.map_obj:get_w() and
		pos[2] >= 0 and pos[2] < self.map_obj:get_h()
end

function Scene_entity:can_use(item_id)
	return true
end

function Scene_entity:get_obj(obj_id)
	return self.obj_mgr:get_obj(obj_id)
end

-- 检查一个对象是否在这个场景中
function Scene_entity:find_obj(obj_id)
	local obj = self.obj_mgr:get_obj(obj_id)
	return obj and true or false
end

-- 场景是否能够进入
function Scene_entity:can_carry(obj)
	return SCENE_ERROR.E_CARRY
end

function Scene_entity:get_last_time(obj)
	return nil
end

function Scene_entity:die_event(args)
end

function Scene_entity:get_count_copy(char_id)
	local obj = g_obj_mgr:get_obj(char_id)
	return obj:get_copy_con():get_count_copy(obj:get_map_id())
end
-----------------------------------------------场景入口----------------------------------------------
function Scene_entity:login_scene(obj, pos)
	if not pos or not self:is_validate_pos(pos) then
		local relive_config = g_scene_config_mgr:get_relive_config(self.id)
		if relive_config[1] == self.id then
			pos[1] = relive_config[2]
			pos[2] = relive_config[3]
		end
	end
	return self:push_scene(obj, pos)
end

function Scene_entity:carry_scene(obj, pos)
	local target_config = g_scene_config_mgr:get_config(self.id)
	if not target_config then
		return SCENE_ERROR.E_SCENE_CLOSE
	end
	
	if target_config.level > obj:get_level() then
		return SCENE_ERROR.E_LEVEL_DOWN
	end
	
	return self:push_scene(obj, pos)
end

-- 将一个对象推入场景的pos位置
function Scene_entity:push_scene(obj, pos)
	if not obj then
		return SCENE_ERROR.E_NOT_ON_SCENE
	end

	if not pos or not self:is_validate_pos(pos) then
		return SCENE_ERROR.E_INVALID_POS
	end
	
	local obj_id = obj:get_id()
	local old_scene = obj:get_scene_obj()
	
	if old_scene then
		old_scene:leave_scene(obj_id)
	end
	
	self:push_to_door(obj_id)
	obj:set_scene(self:get_key())
	obj:modify_pos(pos)
	obj:on_push_scene()
	
	return SCENE_ERROR.E_SUCCESS
end

-- 对象进入场景
function Scene_entity:enter_scene(obj)
	if not obj then
		return SCENE_ERROR.E_NOT_ON_SCENE
	end
	local obj_id = obj:get_id()
	local pos = obj:get_pos()
	
	self:pop_to_door(obj_id)
	self.obj_mgr:add_obj(obj)
	self.map_obj:on_obj_enter(obj_id, pos)
	
	obj:on_enter_scene()
	self:on_obj_enter(obj)
	
	self:send_screen_obj_show_em(obj_id)
	return SCENE_ERROR.E_SUCCESS 
end

function Scene_entity:leave_scene(obj_id)
	if self:is_door(obj_id) then		--在门内直接离开
		self:pop_to_door(obj_id)
		return SCENE_ERROR.E_SUCCESS
	end
	
	local obj = self:get_obj(obj_id)	--不在场景中
	if not obj then
		return SCENE_ERROR.E_NOT_ON_SCENE
	end
	
	obj:on_leave_scene()
	
	--离屏广播
	local new_pkt = {}
	new_pkt.obj_id = obj_id
	self:send_screen(obj_id, CMD_MAP_OBJ_LEAVE_SCREEN_SYN_S, new_pkt, 1)

	self.obj_mgr:del_obj(obj)
	self.map_obj:on_obj_leave(obj_id, obj:get_pos())
	self:on_obj_leave(obj)
	return SCENE_ERROR.E_SUCCESS
end

--进出传送通道
function Scene_entity:push_to_door(obj_id)
	self.door_obj_mgr:push_obj(obj_id)
end

function Scene_entity:pop_to_door(obj_id)
	self.door_obj_mgr:pop_obj(obj_id)
end

function Scene_entity:is_door(obj_id)
	return self.door_obj_mgr:is_member(obj_id)
end

function Scene_entity:on_obj_enter(obj)
end

function Scene_entity:on_obj_leave(obj)
end

function Scene_entity:transport(obj, pos)
	local obj_id = obj:get_id()
	local old_pos = obj:get_pos()
	obj:modify_pos(pos)
	self:send_move_soon_syn(obj_id, obj, old_pos, pos, 1)
end

---------------------------------------------------广播同步-------------------------------------------------

function Scene_entity:send_human(obj_id, cmd, pkt, is_encoded)
	g_cltsock_mgr:send_client(obj_id, cmd, pkt, is_encoded)
end

--获取对象场景视野信息
function Scene_entity:get_scene_view(obj)
	local obj_id = obj:get_id()
	local pos = obj:get_pos()
	local obj_mgr = g_obj_mgr
	local map_o = self.map_obj
	local hidden_count = hidden_scene[self.id]
	
	local pkt = {}
	pkt.char_l = {}
	pkt.obj_l = {}
	
	local h_l = map_o:scan_screen_human(pos)
	if hidden_count then
		local count = 0
		for k, _ in pairs(h_l) do
			local o = obj_mgr:get_obj(k)
			if k ~= obj_id and o then     --------question
				table.insert(pkt.char_l, o:net_get_info())
				count = count + 1
				if hidden_count < count then
					break
				end
			end
		end
	else
		for k, _ in pairs(h_l) do
			local o = obj_mgr:get_obj(k)
			if k ~= obj_id and o then     --------question
				table.insert(pkt.char_l, o:net_get_info())
			end
		end
	end

	local m_l = map_o:scan_screen_monster(pos)
	for k, _ in pairs(m_l) do
		local o = obj_mgr:get_obj(k)
		if o then
			table.insert(pkt.obj_l, o:net_get_info())
		end
	end
	
	local box_l = map_o:scan_screen_box(pos)
	for k,v in pairs(box_l) do
		local o = obj_mgr:get_obj(k)
		if o then
			table.insert(pkt.obj_l, o:net_get_info())
		end
	end
	
	local npc_l = map_o:scan_screen_npc(pos)
	for k,v in pairs(npc_l) do
		local o = obj_mgr:get_obj(k)
		if o then
			table.insert(pkt.obj_l, o:net_get_info())
		end
	end
	
	local pet_l = map_o:scan_screen_pet(pos)
	for k,v in pairs(pet_l) do
		local o = obj_mgr:get_obj(k)
		if o then
			table.insert(pkt.obj_l, o:net_get_info())
		end
	end
	
	return pkt	
end

--瞬间,击退移动，flag为nil或1 瞬间移动；2 击退移动; 3宠物跳
function Scene_entity:send_move_soon_syn(obj_id, obj, pos, des_pos, flag)
	self:on_obj_move(obj_id, obj, pos, des_pos)

	--玩家广播给其他人
	local new_pkt = {}
	new_pkt.obj_id = obj_id
	new_pkt.x_end = des_pos[1]
	new_pkt.y_end = des_pos[2]
	if flag == nil or flag == 1 then
		self:send_screen(obj_id, CMD_MAP_PLAYER_MOVE_SOON_SYN_S, new_pkt, 1)
	elseif flag == 2 then
		self:send_screen(obj_id, CMD_MAP_OBJ_MOVE_RECEDE_SYN_S, new_pkt, 1)
	elseif flag == 3 then
		self:send_screen(obj_id, CMD_MAP_PET_LEAP_SYN, new_pkt, 1)
	end
	
	--如果玩家没改变zone，不需要广播
	local z_id_s = self.map_obj:pos_zone(pos)
	local z_id_d = self.map_obj:pos_zone(des_pos)
	if z_id_s ~= z_id_d then
		--广播human其他对象离开可视区域
		self:send_screen_leave(obj_id, pos, des_pos)	
		--对象进入可视区域广播给human
		self:send_screen_obj_show(obj_id, pos, des_pos)
	end
end

--对象切地图时进入可视区域
function Scene_entity:send_screen_obj_show_em(obj_id)
	local obj = self:get_obj(obj_id)
	if obj then
		local new_pkt = obj:net_get_info()
		self:send_screen(obj_id, CMD_MAP_OBJ_ENTER_SCREEN_SYN_S, new_pkt, nil, 1)
	end
end

--广播obj_id信息给屏内其他human, flag:nil 不广播自己
function Scene_entity:send_screen(obj_id, cmd, pkt, flag, type, isencode)
	local obj = g_obj_mgr:get_obj(obj_id)
	if not obj then
		return
	end
	
	local pos = obj:get_pos()
	if not pos then
		return
	end
	
	local owner_id = obj_id
	if OBJ_TYPE_PET == obj:get_type() and not type then
		owner_id = obj:get_owner_id()
	end
	
	local pkt_t = pkt
	if not isencode then
		pkt_t = Json.Encode(pkt or {})
	end
	
	local hidden_count = hidden_scene[self.id]
	if hidden then
		local z_id = obj:get_zone()		--先广播zone内的
		local human_l = self.map_obj:scan_human_l(z_id)
		local c = 0
		if human_l then
			for o_id, _ in pairs(human_l) do
				if flag or o_id ~= owner_id then
					c = c + 1
					g_cltsock_mgr:send_client(o_id, cmd, pkt_t, true)
				end
			end
		end
	
		--周边8个zone
		local z_l = self.map_obj:scan_screen_zone(pos)
		for k,v in pairs(z_l) do
			if k ~= z_id then
				local human_l = self.map_obj:scan_human_l(k) or {}
				for o_id,_ in pairs(human_l) do
					if c >= hidden_count then
						return
					else
						if flag or o_id ~= owner_id then
							c = c + 1
							g_cltsock_mgr:send_client(o_id, cmd, pkt_t, true)
						end
					end
				end
			end
		end
	else
		local z_l = self.map_obj:scan_screen_zone(pos)
		for k,v in pairs(z_l) do
			local human_l = self.map_obj:scan_human_l(k)
			if human_l then
				for o_id,_ in pairs(human_l) do
					if flag or o_id ~= owner_id then
						g_cltsock_mgr:send_client(o_id, cmd, pkt_t, true)
					end
				end
			end
		end
	end
end

--对象行走同步
function Scene_entity:send_move_syn(obj_id, obj, pos, des_pos, pkt, isencode)
	self:on_obj_move(obj_id, obj, pos, des_pos)
	--对象广播给其他对象
	self:send_screen(obj_id, CMD_MAP_PLAYER_MOVE_SYN_S, pkt, nil, nil, isencode)
	--如果对象没改变zone，不需要广播
	local z_id_s = self.map_obj:pos_zone(pos)
	local z_id_d = self.map_obj:pos_zone(des_pos)

	if z_id_s ~= z_id_d then
		--广播human其他对象离开可视区域
		self:send_screen_leave(obj_id, pos, des_pos)
		--对象进入可视区域广播给human
		self:send_screen_obj_show(obj_id, pos, des_pos)
	end
end

function Scene_entity:on_obj_move(obj_id, obj, pos, des_pos)
	self.map_obj:on_obj_move(obj_id, obj, pos, des_pos)
	self.obj_mgr:on_obj_move(obj_id, obj, pos, des_pos)  
end

--通知human其他人离开可视区域
function Scene_entity:send_screen_leave(obj_id, cur_pos, des_pos)
	local z_l = self:get_map_obj():scan_far_zone(cur_pos, des_pos)
	local flag = Obj_mgr.obj_type(obj_id) == OBJ_TYPE_HUMAN and true or false

	local owner_id = obj_id
	local new_pkt = {}
	new_pkt.obj_id = obj_id
	new_pkt = Json.Encode(new_pkt or {})
	for k,v in pairs(z_l) do
		local pkt_l = {}

		local obj_l = self:get_map_obj():scan_obj_l(k)
		for o_id,_ in pairs(obj_l) do
			--相互通知
			if Obj_mgr.obj_type(o_id) == OBJ_TYPE_HUMAN and o_id ~= owner_id then
				self:send_human(o_id, CMD_MAP_OBJ_LEAVE_SCREEN_SYN_S, new_pkt, true)
			end

			if flag and o_id ~= owner_id then
				local pkt = {["obj_id"]=o_id}
				g_cltsock_mgr:send_client(obj_id, CMD_MAP_OBJ_LEAVE_SCREEN_SYN_S, pkt)
			end
		end

		--掉落包,npc
		if flag then
			local obj_l = self:get_map_obj():scan_box_l(k)
			for o_id,_ in pairs(obj_l) do
				local pkt = {["obj_id"]=o_id}
				g_cltsock_mgr:send_client(obj_id, CMD_MAP_OBJ_LEAVE_SCREEN_SYN_S, pkt)
			end

			local obj_l = self:get_map_obj():scan_npc_l(k)
			for o_id,_ in pairs(obj_l) do
				local pkt = {["obj_id"]=o_id}
				g_cltsock_mgr:send_client(obj_id, CMD_MAP_OBJ_LEAVE_SCREEN_SYN_S, pkt)
			end
		end
	end
end

--对象移动进入他人可视区域
function Scene_entity:send_screen_obj_show(obj_id, cur_pos, des_pos)
	local obj_s = self:get_obj(obj_id)
	if not obj_s then
		local debug = Debug(g_debug_log)
		debug:trace("Scene_entity:send_screen_obj_show")
		return
	end
	local flag = Obj_mgr.obj_type(obj_id) == OBJ_TYPE_HUMAN and true or false

	local owner_id = obj_id
	local z_l = self:get_map_obj():scan_far_zone(des_pos, cur_pos)
	local new_pkt = obj_s:net_get_info()
	new_pkt = Json.Encode(new_pkt or {})
	for k,v in pairs(z_l) do
		local pkt_l = {}
		local count = 1

		local obj_l = self:get_map_obj():scan_obj_l(k)
		for o_id,_ in pairs(obj_l) do
			--相互通知
			if Obj_mgr.obj_type(o_id) == OBJ_TYPE_HUMAN and o_id ~= owner_id then
				self:send_human(o_id, CMD_MAP_OBJ_ENTER_SCREEN_SYN_S, new_pkt, true)
			end

			local obj = self:get_obj(o_id)
			if obj and flag then
				--if Obj_mgr.obj_type(o_id) == OBJ_TYPE_MONSTER then
					local pkt = obj:net_get_info_str()
					g_cltsock_mgr:send_client(obj_id, CMD_MAP_OBJ_ENTER_SCREEN_SYN_S, pkt, true)
				--else
					--local pkt = obj:net_get_info()
					--g_cltsock_mgr:send_client(obj_id, CMD_MAP_OBJ_ENTER_SCREEN_SYN_S, pkt)
				--end
			end
		end

		if flag then
			--box
			local _l = self:get_map_obj():scan_box_l(k)
			for o_id,_ in pairs(_l) do
				local obj = self:get_obj(o_id)
				if obj then
					local pkt = obj:net_get_info_str()
					g_cltsock_mgr:send_client(obj_id, CMD_MAP_OBJ_ENTER_SCREEN_SYN_S, pkt, true)
				end
			end

			--npc
			local _l = self:get_map_obj():scan_npc_l(k)
			for o_id,_ in pairs(_l) do
				local obj = self:get_obj(o_id)
				if obj then
					local pkt = obj:net_get_info_str()
					g_cltsock_mgr:send_client(obj_id, CMD_MAP_OBJ_ENTER_SCREEN_SYN_S, pkt, true)
				end
			end
		end
	end
end

----------------------------------------------------------------------------------------------------
-- attcckter 是否能攻击 defender
function Scene_entity:is_attack(attacker_id, defender_id)
	local scene_mode = g_scene_config_mgr:get_mode(self:get_mode())
	if not scene_mode then
		return SCENE_ERROR.E_INVALID_ID
	end
	
	local attacker = self:get_obj(attacker_id)
	if not attacker then
		return SCENE_ERROR.E_NOT_ON_SCENE
	end
	
	local defender = self:get_obj(defender_id)
	if not defender then
		return SCENE_ERROR.E_NOT_ON_SCENE
	end
	
	return scene_mode:can_attack(attacker, defender)
end

----------------------------------------------------------------------------------------------------

function Scene_entity:on_timer(tm)
	self.obj_mgr:on_timer(tm)
end

function Scene_entity:on_slow_timer(tm)
	self.obj_mgr:on_slow_timer(tm)
end

function Scene_entity:on_serialize_timer(tm)
	self.obj_mgr:on_serialize_timer(tm)
end
