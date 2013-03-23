
local marry_config = require("scene_ex.config.marry_config_loader")
Scene_marry_entry = oo.class(Scene_copy, "Scene_marry_entry")

-- 结婚场景
function Scene_marry_entry:get_self_config()
	return marry_config.config[self.id]
end

--副本出口
function Scene_marry_entry:get_home_carry(obj)
	local config = self:get_self_config()
	local home_carry = config and config.home
	if not home_carry or not home_carry.id or not home_carry.pos or not home_carry.pos[1] or not home_carry.pos[2] then
		return nil, nil
	end
	return home_carry.id, home_carry.pos
end

--获取副本实例ID
function Scene_marry_entry:get_instance_id(obj)
	print("Error Scene_marry_entry:get_instance_id")
	return nil, SCENE_ERROR.E_INVALID_ID
end

function Scene_marry_entry:get_enter_pos()
	local config = self:get_self_config()
	return config.entry[crypto.random(#config.entry, #config.entry + 1)]
end

--副本创建权限检查
function Scene_marry_entry:check_create_access(obj, marry)
	--print("Scene_marry_entry:check_create_access()", obj:get_id())
	
	if marry.m_o ~= 0 then
		if ev.time > marry.m_o + marry.m_n or marry.m_f == false then
			return 22586
		end
		if marry.m_f == true then
			return 22585, marry.m_x
		end
	end

	local obj_id = obj:get_id()
	local instance_id = marry.uuid
	if g_scene_mgr_ex:exists_instance(instance_id) then
		return SCENE_ERROR.E_EXISTS_COPY
	end

	if obj_id ~= marry.char_id and obj_id ~= marry.mate_id then
		return 22583
	end
	
	return SCENE_ERROR.E_SUCCESS
end

--副本进入权限检查
function Scene_marry_entry:check_entry_access(obj, marry)
	--debug_print("Scene_marry_entry:check_entry_access()", obj:get_id())
	--[[
	local config = self:get_self_config()
	if not config then
		return SCENE_ERROR.E_SCENE_CLOSE, nil
	end
	]]
	if marry.m_y == 1 then
		return SCENE_ERROR.E_SUCCESS
	end

	local obj_id = obj:get_id()
	if obj_id == marry.char_id or obj_id == marry.mate_id then
		return SCENE_ERROR.E_SUCCESS
	end

	for k, v in ipairs(marry.m_l or {}) do                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
		if v == obj_id then
			return SCENE_ERROR.E_SUCCESS
		end
	end
	
	return 22584
end

--创建副本实例
function Scene_marry_entry:create_instance(instance_id, obj)
	--debug_print("Scene_marry_entry:create_instance()", instance_id)
	f_scene_info_log("create marry scene char_id:%d, instance_id:%s ", obj:get_id(), instance_id)
	g_marry_mgr:set_fb_open(instance_id, ev.time, SELF_SV_ID)
	return Scene_marry(self.id, instance_id, self.map_obj:clone(self.id))
end

function Scene_marry_entry:instance()

	self.map_obj = g_scene_config_mgr:load_map(self.id)
end

function Scene_marry_entry:carry_scene(obj, pos, args)
	local instance_id = args.marry.uuid
	if not obj or not instance_id then
		return SCENE_ERROR.E_NOT_ON_SCENE, nil
	end
	
	local instance = self.instance_list[instance_id]
	if not instance then
		local e_code, error_describe = self:check_create_access(obj, args.marry)
		if SCENE_ERROR.E_SUCCESS ~= e_code then
			return e_code, error_describe
		end
		
		instance = self:create_instance(instance_id, obj)
		self.instance_list[instance_id] = instance
		g_scene_mgr_ex:register_instance(instance_id, self)
		instance:instance(obj)

	else
		local e_code, error_describe = self:check_entry_access(obj, args.marry)
		if SCENE_ERROR.E_SUCCESS ~= e_code then
			return e_code, error_describe
		end
	end
	return instance:carry_scene(obj, pos, args)
end
