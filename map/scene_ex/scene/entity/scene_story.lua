Scene_story = oo.class(Scene_instance, "Scene_story")

--副本出口
function Scene_story:get_home_carry(obj)
	local config = g_all_scene_config[self.id]
	local home_carry = config.close and config.close.home
	if not home_carry or not home_carry.id 
		or not home_carry.pos or not home_carry.pos[1] or not home_carry.pos[2] then
		return nil, nil
	end
	return home_carry.id, home_carry.pos
end

function Scene_story:carry_scene(obj, pos)
	if not obj then
		return SCENE_ERROR.E_NOT_ON_SCENE
	end
	
	f_multi_web_sql(string.format("insert into copy_into set copy_id=%d, char_id=%d, time=%d, char_name='%s'"
				, self.id
				, obj:get_id()
				, ev.time
				, obj:get_name()))
	
	return self:push_scene(obj, self.entry_pos)
end

function Scene_story:on_obj_enter(obj)
	if obj:get_type() == OBJ_TYPE_HUMAN then
		if self.not_human then
			local config = g_all_scene_config[self.id]
			local action = config and config.action
			local trigger = action and action.trigger 
			if trigger and trigger.entry and trigger.entry.chapter then
				g_cltsock_mgr:send_client(obj:get_id(), CMD_STORY_PLAY_S, trigger.entry)
				self.status = SCENE_STATUS.FREEZE
			end
			self.not_human = false
		end
	end
end

function Scene_story:on_failed()
	local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
	for obj_id, _ in pairs(con:get_obj_list()) do
		local player = g_obj_mgr:get_obj(obj_id)
		if player then
			local pkt = {}
			pkt.type = 0
			g_cltsock_mgr:send_client(obj_id, CMD_STORY_RESULT_S, pkt)
		end
	end
end

function Scene_story:on_success()
	local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
	for obj_id, _ in pairs(con:get_obj_list()) do
		local player = g_obj_mgr:get_obj(obj_id)
		if player then
			local con = player:get_story_con()
			local pkt = {}
			pkt.type = 1
			pkt.chapter = con:end_story(self.id)
			g_cltsock_mgr:send_client(obj_id, CMD_STORY_RESULT_S, pkt)
		end
	end
end

function Scene_story:on_obj_leave(obj)
	local type = obj:get_type()
	if type == OBJ_TYPE_HUMAN then
		self:close()
	elseif type == OBJ_TYPE_MONSTER and self.instance_id then
		local e = self.dead_event[obj:get_occ()]
		if e then
			local pkt = {chapter = e.chapter}
			for obj_id, _ in pairs(self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN):get_obj_list()) do
				g_cltsock_mgr:send_client(obj_id, CMD_STORY_PLAY_S, pkt)
			end
			self.status = SCENE_STATUS.FREEZE
			if 1 == e.type then
				self:on_success()
			end
		end
	end
end

function Scene_story:get_mode()
	if SCENE_STATUS.OPEN == self.status then
		local config = g_scene_config_mgr:get_config(self.id)
		return config and config.mode
	end
	return SCENE_MODE.NONE
end

function Scene_story:end_play()
	if self.status == SCENE_STATUS.FREEZE then
		self.status = SCENE_STATUS.OPEN
	end
end

function Scene_story:on_timer(tm)
	if self.end_time and self.end_time <= ev.time then
		self:close()
	else
		local con = self.obj_mgr:get_obj_con(OBJ_TYPE_MONSTER)
		if 0 == con:get_obj_count() then
			self:next_sequence()
		end
		self.obj_mgr:on_timer(tm)
	end
end

function Scene_story:instance()
	local config = g_all_scene_config[self.id]
	self.end_time = ev.time + config.init.limit.time
	self.status = SCENE_STATUS.OPEN
	self.entry_pos = config.init.entry
	self.is_over = false
	self.sequence = 1
	self.sequence_list = config.action.update
	self.dead_event = config.action.trigger.dead
	self.obj_mgr:instance(self.map_obj:get_w(), self.map_obj:get_h())
end

function Scene_story:next_sequence()
	if self.is_over then
		return
	end
	
	local sequence = self.sequence_list.sequence[self.sequence]
	if not sequence then
		self.is_over = true
		--通知完成
		return
	end
	
	local map_obj = self:get_map_obj()
	local obj_mgr = g_obj_mgr
	for _, info in ipairs(sequence) do
		for i = 1, info.number do
			local pos = map_obj:find_space(info.area, 20)
			if pos then
				local obj
				if 0 == info.type or 1 == info.type then
					obj = obj_mgr:create_monster(info.id, pos, self.key)
				end
				
				local ret_code = self:enter_scene(obj)
			end
		end
	end
	
	self.sequence = self.sequence + 1
end