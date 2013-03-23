
Scene_vip_entry = oo.class(Scene_team_copy, "Scene_vip_entry")

function Scene_vip_entry:__init(map_id, status)
	Scene_team_copy.__init(self, map_id, Scene_vip, SCENE_STATUS.OPEN)

end

--副本进入权限检查
function Scene_vip_entry:check_entry_access(obj)
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
	
	local bang_time = obj:get_vip_bang_time()
	if bang_time <= 0 then
		return 21311, nil
	end

	return SCENE_ERROR.E_SUCCESS, nil
end