
local copy_config = require("scene_ex.config.compete_config_loader")

-- 个本副本
Scene_compete_copy = oo.class(Scene_copy, "Scene_compete_copy")

function Scene_compete_copy:__init(map_id)
	Scene_copy.__init(self, map_id, SCENE_STATUS.OPEN)
	
end

function Scene_compete_copy:get_self_config()
	return copy_config.config[self.id]
end

function Scene_compete_copy:get_self_limit_config()
	return copy_config.config[self.id].init.limit
end

--副本出口
function Scene_compete_copy:get_home_carry(obj)
	local config = self:get_self_config()
	local home_carry = config.init.home
	if not home_carry or not home_carry.id 
		or not home_carry.pos or not home_carry.pos[1] or not home_carry.pos[2] then
		return nil, nil
	end
	return home_carry.id, home_carry.pos
end

--获取副本实例ID
function Scene_compete_copy:get_instance_id(obj)
	local instance_id = "compete" .. obj:get_id()
	return instance_id, instance_id and SCENE_ERROR.E_SUCCESS or SCENE_ERROR.E_INVALID_TEAM
end

--副本创建权限检查
function Scene_compete_copy:check_create_access(obj)
	--print("Scene_compete_copy:check_create_access()", obj:get_id())
	if self.status ~= SCENE_STATUS.OPEN then
		return SCENE_ERROR.E_NOT_OPNE, nil
	end

	local obj_id = obj:get_id()
	if g_scene_mgr_ex:exists_instance(obj_id) then
		return SCENE_ERROR.E_EXISTS_COPY, nil
	end
	

	local config = self:get_self_limit_config()
	if not config then
		return SCENE_ERROR.E_SCENE_CLOSE, nil
	end
	
	
	local cycle_limit = config.cycle
	if cycle_limit then
		if obj:get_copy_con():get_count_copy(self.id) >= cycle_limit then
			return SCENE_ERROR.E_CYCLE_LIMIT, nil
		end
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

--副本进入权限检查
function Scene_compete_copy:check_entry_access(obj)
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
function Scene_compete_copy:create_instance(instance_id, obj)
	return Scene_compete(self.id, instance_id, self.map_obj:clone(self.id))
end

function Scene_compete_copy:instance()
	self.map_obj = g_scene_config_mgr:load_map(self.id)
end