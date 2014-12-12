
local marry_config = require("scene_ex.config.marry_config_loader")
Scene_marry_monster_entry = oo.class(Scene_copy, "Scene_marry_monster_entry")

-- 结婚场景
function Scene_marry_monster_entry:get_self_config()
	return marry_config.config[self.id]
end

--副本出口
function Scene_marry_monster_entry:get_home_carry(obj)
	local config = self:get_self_config()
	local home_carry = config and config.home
	if not home_carry or not home_carry.id or not home_carry.pos or not home_carry.pos[1] or not home_carry.pos[2] then
		return nil, nil
	end
	return home_carry.id, home_carry.pos
end

--获取副本实例ID
function Scene_marry_monster_entry:get_instance_id(obj)
	local instance_id = obj and obj:get_team()
	return instance_id, instance_id and SCENE_ERROR.E_SUCCESS or SCENE_ERROR.E_INVALID_TEAM
end

function Scene_marry_monster_entry:get_enter_pos()
	local config = self:get_self_config()
	return config.entry[crypto.random(#config.entry, #config.entry + 1)]
end

--副本创建权限检查
function Scene_marry_monster_entry:check_create_access(obj, marry)
	--print("Scene_marry_monster_entry:check_create_access()", obj:get_id())

	if not g_marry_mgr:get_fb_count(marry.uuid, self.id) then
		return 22601
	end

	local team_id = obj:get_team()
	local team_obj = team_id and g_team_mgr:get_team_obj(team_id)
	if not team_obj then
		return SCENE_ERROR.E_INVALID_TEAM, nil
	end

	if g_scene_mgr_ex:exists_instance(team_id) then
		return SCENE_ERROR.E_EXISTS_COPY
	end

	local obj_id = obj:get_id()
	if team_obj:get_teamer_id() ~= obj_id then									--检查是否是队长
		return SCENE_ERROR.E_INVALID_CAPTION, nil
	end

	if obj_id ~= marry.char_id and obj_id ~= marry.mate_id then
		return 22597
	end

	local config = self:get_self_config()
	local cycle_limit = config.cycle
	local con = obj:get_copy_con()
	if cycle_limit and con:get_count_copy(self.id) >= cycle_limit then
		return SCENE_ERROR.E_CYCLE_LIMIT
	end
	
	local obj_mgr = g_obj_mgr
	local team_l, team_count = team_obj:get_team_l()
	if team_count < 2 then
		return 22598
	end

	local error_l = {}
	local e_code = SCENE_ERROR.E_SUCCESS
	local member_error_l = {}

	for k, _ in pairs(team_l) do
		if k ~= marry.char_id and k ~= marry.mate_id then
			member_error_l[k] = {22599}
			e_code = 22599
		end
	end

	if SCENE_ERROR.E_SUCCESS ~= e_code then
		local member_e_l = {}
		for k, v in pairs(member_error_l) do
			table.insert(member_e_l, {['obj_id'] = k, ['error_l'] = v})
		end
		g_cltsock_mgr:send_client(obj_id, CMD_MAP_TEAM_ENTER_COPY_S, member_e_l, false)
	end

	return e_code, error_l
end

--副本进入权限检查
function Scene_marry_monster_entry:check_entry_access(obj, marry)
	--debug_print("Scene_marry_monster_entry:check_entry_access()", obj:get_id())

	local obj_id = obj:get_id()
	if obj_id == marry.char_id or obj_id == marry.mate_id then
		return SCENE_ERROR.E_SUCCESS
	end
	
	return 22584
end

--创建副本实例
function Scene_marry_monster_entry:create_instance(instance_id, obj)
	--debug_print("Scene_marry_monster_entry:create_instance()", instance_id)
	return Scene_marry_monster(self.id, instance_id, self.map_obj:clone(self.id))
end

function Scene_marry_monster_entry:instance()

	self.map_obj = g_scene_config_mgr:load_map(self.id)
end

function Scene_marry_monster_entry:carry_scene(obj, pos)
	local marry = g_marry_mgr:get_marry_info(obj:get_id())
	if marry == nil then
		return 22597
	end
	local instance_id = self:get_instance_id(obj)
	if not obj or not instance_id then
		return SCENE_ERROR.E_INVALID_TEAM, nil
	end
	
	local pos = self:get_enter_pos()
	local instance = self.instance_list[instance_id]
	if not instance then
		local e_code, error_describe = self:check_create_access(obj, marry)
		if SCENE_ERROR.E_SUCCESS ~= e_code then
			return e_code, error_describe
		end
		instance = self:create_instance(instance_id, obj)
		self.instance_list[instance_id] = instance
		g_scene_mgr_ex:register_instance(instance_id, self)
		local args = {}
		args.marry = marry
		args.obj = obj
		instance:instance(args)
	else
		local e_code, error_describe = self:check_entry_access(obj, marry)
		if SCENE_ERROR.E_SUCCESS ~= e_code then
			return e_code, error_describe
		end
	end
	return instance:carry_scene(obj, pos, args)
end
