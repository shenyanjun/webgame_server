local copy_config = require("scene_ex.config.copy_bale_loader")
Scene_team_copy = oo.class(Scene_copy, "Scene_team_copy")

function Scene_team_copy:__init(map_id, prototype, status)
	Scene_copy.__init(self, map_id, status)
	self.prototype = prototype
end

function Scene_team_copy:get_self_config()
	return copy_config.config_list.value[self.id]
end

function Scene_team_copy:get_self_limit_config()
	return copy_config.config_list.value[self.id]
end

--副本出口
function Scene_team_copy:get_home_carry(obj)
	local config = self:get_self_config()
	local home_carry = config.home_carry
	if not home_carry or not home_carry.id 
		or not home_carry.pos or not home_carry.pos[1] or not home_carry.pos[2] then
		return nil, nil
	end
	return home_carry.id, home_carry.pos
end

--获取副本实例ID
function Scene_team_copy:get_instance_id(obj)
	local instance_id = obj and obj:get_team()
	return instance_id, instance_id and SCENE_ERROR.E_SUCCESS or SCENE_ERROR.E_INVALID_TEAM
end

--副本创建权限检查
function Scene_team_copy:check_create_access(obj)
	if self.status ~= SCENE_STATUS.OPEN then
		return SCENE_ERROR.E_NOT_OPNE, nil
	end

	local team_id = obj:get_team()
	local team_obj = team_id and g_team_mgr:get_team_obj(team_id)
	if not team_obj then
		return SCENE_ERROR.E_INVALID_TEAM, nil
	end
	
	if g_scene_mgr_ex:exists_instance(team_id) then
		return SCENE_ERROR.E_EXISTS_COPY, nil
	end
	
	local obj_id = obj:get_id()
	if team_obj:get_teamer_id() ~= obj_id then									--检查是否是队长
		return SCENE_ERROR.E_INVALID_CAPTION, nil
	end
	
	local config = self:get_self_limit_config()
	if not config then
		return SCENE_ERROR.E_SCENE_CLOSE, nil
	end
	
	local obj_mgr = g_obj_mgr
	local team_l, team_count = team_obj:get_team_l()
	
	local error_l = {}
	local e_code = SCENE_ERROR.E_SUCCESS
	local member_error_l = {}

	local human_limit = config.human
	if human_limit then
		if human_limit[1] > team_count or human_limit[2] < team_count then
			e_code = SCENE_ERROR.E_SCENE_CHANGE
			table.insert(error_l, SCENE_ERROR.E_HUMAN_LIMIT)
		end
	end
	
	local cycle_limit = config.cycle
	if cycle_limit then
		local has_error = false
		for k, _ in pairs(team_l) do
			local obj = obj_mgr:get_obj(k)
			if obj and obj:get_copy_con():get_count_copy(self.id) >= cycle_limit then
				has_error = true
				local list = member_error_l[k]
				if not list then
					list = {}
					member_error_l[k] = list
				end
				table.insert(list, SCENE_ERROR.E_CYCLE_LIMIT)
			end
		end
		if has_error then
			e_code = SCENE_ERROR.E_SCENE_CHANGE
			table.insert(error_l, SCENE_ERROR.E_CYCLE_LIMIT)
		end
	end
	
	local level_limit = config.level
	if level_limit then
		local has_error = false
		for k, _ in pairs(team_l) do
			local obj = obj_mgr:get_obj(k)
			if obj then
				local level = obj:get_level()
				if level_limit[1] > level or level_limit[2] < level then
					has_error = true
					local list = member_error_l[k]
					if not list then
						list = {}
						member_error_l[k] = list
					end
					table.insert(list, SCENE_ERROR.E_LEVEL_LIMIT)
				end
			end
		end
		
		if has_error then
			e_code = SCENE_ERROR.E_SCENE_CHANGE
			table.insert(error_l, SCENE_ERROR.E_LEVEL_LIMIT)
		end
	end
	
	if SCENE_ERROR.E_SUCCESS ~= e_code then
		local ret = 0
		if member_error_l[obj_id] then
			ret = self:get_next_copy(team_obj)
		end
		if ret ~= 0 then
			local pkt = {}
			pkt.recommend_id = ret
			g_cltsock_mgr:send_client(obj_id, CMD_MAP_TEAM_ENTER_RECOMMEND_COPY_S, pkt, false)
		else
			local member_e_l = {}
			for k, v in pairs(member_error_l) do
				table.insert(member_e_l, {['obj_id'] = k, ['error_l'] = v})
			end
			g_cltsock_mgr:send_client(obj_id, CMD_MAP_TEAM_ENTER_COPY_S, member_e_l, false)
		end
	end

	return e_code, error_l
end

--副本进入权限检查
function Scene_team_copy:check_entry_access(obj)
	local config = self:get_self_limit_config()
	if not config then
		return SCENE_ERROR.E_SCENE_CLOSE, nil
	end
	
	local level_limit = config.level
	if level_limit then
		local level = obj:get_level()
		if level_limit[1] > level or level_limit[2] < level then
			return SCENE_ERROR.E_LEVEL_LIMIT, nil
		end
	end
	
	return SCENE_ERROR.E_SUCCESS, nil
end

--创建副本实例
function Scene_team_copy:create_instance(instance_id, obj)
	return self.prototype(self.id, instance_id, self.map_obj:clone(self.id))
end

function Scene_team_copy:instance()
	self.map_obj = g_scene_config_mgr:load_map(self.id)
end