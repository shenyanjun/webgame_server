local copy_config = require("scene_ex.config.copy_bale_loader")

Scene_instance = oo.class(Scene_entity, "Scene_instance")

function Scene_instance:__init(map_id, instance_id, map_obj)
	Scene_entity.__init(self, map_id, map_obj)
	self.end_time = ev.time
	self.instance_id = instance_id
	self.key = {map_id, instance_id}
	self.owner_list = {}
	self.not_human = true
end

function Scene_instance:get_self_config()
	return copy_config.config_list.value[self.id]
end

function Scene_instance:get_self_limit_config()
	return copy_config.config_list.value[self.id]
end

--副本出口
function Scene_instance:get_home_carry(obj)
	local config = self:get_self_config()
	local home_carry = config.home_carry
	if not home_carry or not home_carry.id
		or not home_carry.pos or not home_carry.pos[1] or not home_carry.pos[2] then
		return nil, nil
	end
	return home_carry.id, home_carry.pos
end

-----------------------------------------------场景入口----------------------------------------------

function Scene_instance:carry_scene(obj, pos)
	if not obj then
		return SCENE_ERROR.E_NOT_ON_SCENE
	end
	
	local obj_id = obj:get_id()
	if not self.owner_list[obj_id] then
		local config = self:get_self_limit_config()
		local level = obj:get_level()
		if config.level and (level < config.level[1] or level > config.level[2]) then
			return SCENE_ERROR.E_LEVEL_LIMIT
		end
		local cycle_limit = config.cycle
		local con = obj:get_copy_con()
		if cycle_limit and con:get_count_copy(self.id) >= cycle_limit then
			return SCENE_ERROR.E_CYCLE_LIMIT
		end
		con:add_count_copy(self.id)
		self.owner_list[obj_id] = true
		
		f_multi_web_sql(string.format("insert into copy_into set copy_id=%d, char_id=%d, time=%d, char_name='%s'"
					, self.id
					, obj_id
					, ev.time
					, obj:get_name()))
	end
	
	return self:push_scene(obj, pos)
end

function Scene_instance:kickout(obj_id)
	local obj = self:get_obj(obj_id)
	if not obj and self:is_door(obj_id) then
		obj = g_obj_mgr:get_obj(obj_id)
	end
	
	if obj then
		if not obj:is_alive() then
			obj:do_relive(nil, true)	--复活
			obj:send_relive(3)
		end
		
		local scene_id, pos = self:get_home_carry(obj)
		g_scene_mgr_ex:push_scene(scene_id, pos, obj)
	end
end

function Scene_instance:clean_scene_obj()
	if self.obj_mgr then
		local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
		if con then
			for obj_id, _ in pairs(con:get_obj_list()) do
				self:kickout(obj_id)
			end
		end
		
		local con = self.obj_mgr:get_obj_con(OBJ_TYPE_MONSTER)
		if con then
			local obj_mgr = g_obj_mgr
			for obj_id, _ in pairs(con:get_obj_list()) do
				local obj = obj_mgr:get_obj(obj_id)
				if obj then
					obj:leave()
				end
			end
		end
		
		local con = self.obj_mgr:get_obj_con(OBJ_TYPE_BOX)
		if con then
			local obj_mgr = g_obj_mgr
			for obj_id, _ in pairs(con:get_obj_list()) do
				local obj = obj_mgr:get_obj(obj_id)
				if obj and obj.leave then
					obj:leave()
				end
			end
		end
		
		local con = self.obj_mgr:get_obj_con(OBJ_TYPE_PET)
		if con then
			local obj_mgr = g_obj_mgr
			for obj_id, _ in pairs(con:get_obj_list()) do
				local obj = obj_mgr:get_obj(obj_id)
				if obj and obj.leave then
					obj:leave()
				end
			end
		end
		
		local con = self.obj_mgr:get_obj_con(OBJ_TYPE_NPC)
		if con then
			local obj_mgr = g_obj_mgr
			for obj_id, _ in pairs(con:get_obj_list()) do
				local obj = obj_mgr:get_obj(obj_id)
				if obj and obj.leave then
					obj:leave()
				end
			end
		end
	end
	
	if self.door_obj_mgr then
		for obj_id, _ in pairs(self.door_obj_mgr:get_obj_list()) do
			self:kickout(obj_id)
		end
	end
end

function Scene_instance:close()
	if self.instance_id then
		local instance_id = self.instance_id
		self.instance_id = nil
		self:clean_scene_obj()
		g_scene_mgr_ex:unregister_instance(instance_id)
	end
end

function Scene_instance:on_timer(tm)
	if self.end_time and self.end_time <= ev.time then
		self:close()
	else
		self.obj_mgr:on_timer(tm)
	end
end

function Scene_instance:instance()
	local config = self:get_self_config()
	self.end_time = ev.time + config.time
	
	self.obj_mgr = Scene_obj_mgr_ex(Scene_monster_layout(self.key, false), Scene_monster_copy_mgr())
	self.obj_mgr:instance(self.map_obj:get_w(), self.map_obj:get_h())
end

function Scene_instance:get_last_time(obj)
	return math.max(self.end_time - ev.time, 0)
end

function Scene_instance:on_obj_enter(obj)
	if obj:get_type() == OBJ_TYPE_HUMAN then
		g_scene_mgr_ex:register_event(EVENT_SET.EVENT_DEL_TEAM, obj:get_id(), self, self.del_team_event)
		if self.not_human then
			self.not_human = false
			f_team_gather(obj, 2)
		end 
	end
end

function Scene_instance:on_obj_leave(obj)
	if obj:get_type() == OBJ_TYPE_HUMAN then
		g_scene_mgr_ex:unregister_event(EVENT_SET.EVENT_DEL_TEAM, obj:get_id())
	elseif self:get_type() == MAP_TYPE_COPY and obj:get_type() == OBJ_TYPE_MONSTER and obj:is_boss() then
		--if self.obj_mgr:get_obj_con(OBJ_TYPE_MONSTER):get_obj_count() <= 0 then
			local obj_list = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN):get_obj_list()
			for k, v in pairs(obj_list or {}) do
				g_cltsock_mgr:send_client(k, CMD_MAP_COPY_END_S, {})
				--print("CMD_MAP_COPY_END_S:", k)
			end
		--end
	end
end

function Scene_instance:del_team_event(team_id, char_id)
	if char_id then
		self:kickout(char_id)
	end
end

function Scene_instance:reset_end_time(t)
	self.end_time = t
	local pkt = {}
	pkt.time = self.end_time - ev.time
	local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
	if con then
		for obj_id, _ in pairs(con:get_obj_list()) do
			self:send_human(obj_id, CMD_MAP_SCENE_RESET_END_TIME_S, pkt)
		end
	end
end