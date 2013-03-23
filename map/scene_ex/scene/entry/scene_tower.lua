local tower_config = require("scene_ex.config.tower_config_loader")

Scene_tower = oo.class(Scene_team_copy, "Scene_tower")

function Scene_tower:__init(map_id)
	Scene_team_copy.__init(self, map_id, nil, SCENE_STATUS.CLOSE) 
end

--创建副本实例
function Scene_tower:create_instance(instance_id, obj)
	return self.group:clone(instance_id)
end

function Scene_tower:get_self_config()
	return tower_config.config[self.id]
end

function Scene_tower:get_self_limit_config()
	local config = self:get_self_config()
	return config and config.limit
end

-----------------------------------------------场景实例化----------------------------------------------

function Scene_tower:get_instance(scene_id)
	local instance_id = scene_id and scene_id[2]
	local instance = instance_id and self.instance_list[instance_id]
	return instance and instance:get_instance(scene_id)
end

function Scene_tower:instance()
	self.group = Scene_group(self.id)
	self.group:instance()
end

-----------------------------------------------------------------------------------------------------