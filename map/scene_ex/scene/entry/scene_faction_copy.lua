local invasion_config = require("scene_ex.config.invasion_config_loader")
Scene_faction_copy = oo.class(Scene_copy, "Scene_faction_copy")

--副本出口
function Scene_faction_copy:get_home_carry(obj)
	local config = self:get_self_config()
	local home_carry = config and config.home
	if not home_carry or not home_carry.id or not home_carry.pos or not home_carry.pos[1] or not home_carry.pos[2] then
		return nil, nil
	end
	return home_carry.id, home_carry.pos
end

--获取副本实例ID
function Scene_faction_copy:get_instance_id(obj)
	local obj_id = obj:get_id()
	local faction = g_faction_mgr:get_faction_by_cid(obj_id)	
	local instance_id = faction and faction:get_faction_id()
	return instance_id, instance_id and SCENE_ERROR.E_SUCCESS or SCENE_ERROR.E_INVALID_FACTION
end

function Scene_faction_copy:get_self_config()
	return invasion_config.config[self.id]
end

--副本创建权限检查
function Scene_faction_copy:check_create_access(obj)
	local obj_id = obj:get_id()
	local faction = g_faction_mgr:get_faction_by_cid(obj_id)
	local faction_id = faction and faction:get_faction_id()
	if not faction_id then
		return SCENE_ERROR.E_INVALID_FACTION, nil 
	end
	if g_scene_mgr_ex:exists_instance(faction_id) then
		return SCENE_ERROR.E_EXISTS_COPY, nil
	end
	
	if 0 ~= faction:get_dissolve_flag() then
		return SCENE_ERROR.E_FACTION_DISSOLVE, nil
	end

	local config = self:get_self_config()
	if not config then
		return SCENE_ERROR.E_INVALID_CONFIG, nil
	end

	local limit = config.limit
	if not limit then
		return SCENE_ERROR.E_INVALID_CONFIG, nil
	end

	local faction_level_limit = limit.faction_level
	if faction_level_limit then
		local faction_level = faction:get_level()
		if (faction_level_limit.min and faction_level < faction_level_limit.min)
			or (faction_level_limit.max and faction_level_limit.max < faction_level) then
			return SCENE_ERROR.E_FACTION_LEVEL_LIMIT, nil
		end
	end

	if obj_id ~= faction:get_factioner_id() and 0 ~= faction:is_fb_permission_ok(obj_id) then
		return SCENE_ERROR.E_NOT_PERMISSION, nil
	end

	local cycle_limit = limit.cycle and limit.cycle.number
	
	local con = obj:get_copy_con()
	if cycle_limit
		and (g_faction_mgr:get_fb(obj_id, self.id) >= cycle_limit 
				or (not con) or con:get_count_copy(self.id) >= cycle_limit) then
		return SCENE_ERROR.E_CYCLE_LIMIT, nil
	end

	local error_l = {}
	local e_code = SCENE_ERROR.E_SUCCESS

	local human = limit.human
	if human.min and faction:get_member_count() < human.min then
		e_code = SCENE_ERROR.E_SCENE_CHANGE
		table.insert(error_l, SCENE_ERROR.E_FACTION_HUMAN_MIN)
	end
	
	local level_limit = limit.level
	if level_limit then
		local level = obj:get_level()
		if (level_limit.min and level < level_limit.min) or (level_limit.max and level_limit.max < level) then
			e_code = SCENE_ERROR.E_SCENE_CHANGE
			table.insert(error_l, SCENE_ERROR.E_LEVEL_LIMIT)
		end
	end
	return e_code, error_l
end

--副本进入权限检查
function Scene_faction_copy:check_entry_access(obj)
	local config = self:get_self_config()
	if not config then
		return SCENE_ERROR.E_SCENE_CLOSE, nil
	end

	local level_limit = config.limit and config.limit.level
	if level_limit then
		local level = obj:get_level()
		if (level_limit.min and level < level_limit.min) or (level_limit.max and level_limit.max < level) then
			return SCENE_ERROR.E_LEVEL_LIMIT, nil
		end
	end	

	return SCENE_ERROR.E_SUCCESS, nil
end

--创建副本实例
function Scene_faction_copy:create_instance(instance_id, obj)
	g_faction_mgr:set_fb(obj:get_id(), self.id)
	local pkt = {}
	pkt.faction_id = instance_id
	pkt.switch_flag = 1
	pkt.scene_id = self.id
	g_faction_mgr:switch_fb(pkt)
	return Scene_invasion(self.id, instance_id, self.map_obj:clone(self.id))
end

function Scene_faction_copy:instance()
--[[
	self.map_obj = Scene_map(self.id)
	local config = g_scene_config_mgr:get_config(self.id)
	local path = config and config.map_path
	if not path then
		return
	end
	self.map_obj:load(path)
]]
	self.map_obj = g_scene_config_mgr:load_map(self.id)
end

-----------------------------------------------场景入口----------------------------------------------

function Scene_faction_copy:login_scene(obj, pos)
	local e_code, error_list = self:carry_scene(obj, pos)
	if SCENE_ERROR.E_SUCCESS ~= e_code then
		return Scene_copy.login_scene(self, obj, pos)
	end
	return e_code, error_list
end
