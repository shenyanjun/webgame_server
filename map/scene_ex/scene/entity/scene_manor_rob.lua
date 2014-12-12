-- 帮派庄园强盗副本
Scene_manor_rob = oo.class(Scene_instance, "Scene_manor_rob")

--副本出口
function Scene_manor_rob:get_home_carry(obj)
	local config = g_all_scene_config[self.id]
	local home_carry = config.close and config.close.home
	if not home_carry or not home_carry.id 
		or not home_carry.pos or not home_carry.pos[1] or not home_carry.pos[2] then
		return nil, nil
	end
	return home_carry.id, home_carry.pos
end


function Scene_manor_rob:can_carry(obj)
	local obj_id = obj:get_id()
	if not self.owner_list[obj_id] then
		local config = g_all_scene_config[self.id].init.limit
		
		local cycle_limit = config.cycle
		local con = obj:get_copy_con()
		if cycle_limit and con:get_count_copy(self.id) >= cycle_limit then
			return SCENE_ERROR.E_CYCLE_LIMIT
		end

		local level_limit = config.level
		if level_limit then
			local level = obj:get_level()
			if level_limit[1] > level or level_limit[2] < level then
				return SCENE_ERROR.E_LEVEL_LIMIT, nil
			end
		end
	end

	return SCENE_ERROR.E_SUCCESS
end

function Scene_manor_rob:on_timer(tm)
	if self.check_succeed_time == nil or self.check_succeed_time < ev.time then
		self:check_succeed()
		self.check_succeed_time = ev.time + 5
	end

	if self.end_time and self.end_time <= ev.time then
		self:check_succeed()
		self:close()
	else
		self.obj_mgr:on_timer(tm)
	end
end

function Scene_manor_rob:check_succeed()
	--print("Scene_manor_rob:check_scceed()")
	if self.is_succeed then return end
	local con = self.obj_mgr:get_obj_con(OBJ_TYPE_MONSTER)
	if con and not table.is_empty(con:get_obj_list()) then
		return
	end

	local map_id = 2901000
	local manor_copy = g_scene_mgr_ex:get_prototype(map_id)
	local team = g_team_mgr:get_team_obj(self.instance_id)
	local teamer_id = team and team:get_teamer_id()
	local _ = manor_copy and teamer_id and manor_copy:notify_rob_succeed(teamer_id)
	self.is_succeed = true
	self.end_time = ev.time + 5
end
-----------------------------------------------场景入口----------------------------------------------

function Scene_manor_rob:update_sequence(sequence)
	local map_obj = self:get_map_obj()
	local obj_mgr = g_obj_mgr

	for _, info in pairs(sequence) do

		for i=1, info.number do
			local pos = map_obj:find_space(info.area, 20)
			if pos then
				local obj = obj_mgr:create_monster(info.occ, pos, self.key)
				self:enter_scene(obj)
			end
		end
	end
end

function Scene_manor_rob:carry_scene(obj, pos)
	if not obj then
		return SCENE_ERROR.E_NOT_ON_SCENE
	end
	
	local obj_id = obj:get_id()
	if not self.owner_list[obj_id] then
		local config = g_all_scene_config[self.id].init.limit
		
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
	
	if self.not_human then
		local config = g_all_scene_config[self.id]
		local level = obj:get_level()
		
		local target = {}
		for _, sequence in ipairs(config.action.update.sequence) do
			target = sequence.item_list		--找到玩家等级小于等于的那个段，如果没有就用最后一个
			if level <= sequence.limit then
				break
			end
		end
		
		self:update_sequence(target)
	end
	
	return self:push_scene(obj, pos)
end

function Scene_manor_rob:instance()
	local config = g_all_scene_config[self.id]
	self.end_time = ev.time + config.init.limit.time
	self.check_succeed_time = ev.time + 30
	self.obj_mgr:instance(self.map_obj:get_w(), self.map_obj:get_h())
	--
	local map_id = 2901000
	local manor_copy = g_scene_mgr_ex:get_prototype(map_id)
	local team = g_team_mgr:get_team_obj(self.instance_id)
	local teamer_id = team and team:get_teamer_id()
	local _ = manor_copy and teamer_id and manor_copy:notify_rob_start(teamer_id)
end