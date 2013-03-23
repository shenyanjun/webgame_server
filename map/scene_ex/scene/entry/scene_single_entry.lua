Scene_single_entry = oo.class(Scene_copy, "Scene_single_entry")

function Scene_single_entry:__init(map_id, prototype, status)
	Scene_copy.__init(self, map_id, status)
	self.prototype = prototype
end

--副本出口
function Scene_single_entry:get_home_carry(obj)
	local config = g_all_scene_config[self.id]
	local home_carry = config.close and config.close.home
	if not home_carry or not home_carry.id 
		or not home_carry.pos or not home_carry.pos[1] or not home_carry.pos[2] then
		return nil, nil
	end
	return home_carry.id, home_carry.pos
end

--获取副本实例ID
function Scene_single_entry:get_instance_id(obj)
	local instance_id = obj and obj:get_id()
	return instance_id, instance_id and SCENE_ERROR.E_SUCCESS or SCENE_ERROR.E_NOT_ON_SCENE
end

--副本创建权限检查
function Scene_single_entry:check_create_access(obj)
	if self.status ~= SCENE_STATUS.OPEN then
		return SCENE_ERROR.E_NOT_OPNE, nil
	end
	
	local instance_id = self:get_instance_id(obj)
	
	if g_scene_mgr_ex:exists_instance(instance_id) then
		return SCENE_ERROR.E_EXISTS_COPY, nil
	end
	
	local config = g_all_scene_config[self.id]
	if not config then
		return SCENE_ERROR.E_SCENE_CLOSE, nil
	end
	
	local limit_config = config.init and config.init.limit
	if not limit_config then
		return SCENE_ERROR.E_SCENE_CLOSE, nil
	end
	
	local error_l = {}
	local e_code = SCENE_ERROR.E_SUCCESS
	
	local level_limit = limit_config.level
	if level_limit then
		local level = obj:get_level()
		if level_limit[1] > level or level_limit[2] < level then
			table.insert(list, SCENE_ERROR.E_LEVEL_LIMIT)
			e_code = SCENE_ERROR.E_SCENE_CHANGE
		end
	end
	
	return e_code, error_l
end

--副本进入权限检查
function Scene_single_entry:check_entry_access(obj)
	return SCENE_ERROR.E_SUCCESS
end

--创建副本实例
function Scene_single_entry:create_instance(instance_id, obj)
	return self.prototype(self.id, instance_id, self.map_obj:clone(self.id))
end

function Scene_single_entry:instance()
	self.map_obj = g_scene_config_mgr:load_map(self.id)
end