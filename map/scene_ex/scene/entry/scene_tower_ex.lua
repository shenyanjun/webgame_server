local tower_ex_config = require("scene_ex.config.tower_ex_loader")

-- 单人爬塔副本
Scene_tower_ex = oo.class(Scene_team_copy, "Scene_tower_ex")

function Scene_tower_ex:__init(map_id, layer_name)
	Scene_team_copy.__init(self, map_id, nil, SCENE_STATUS.CLOSE) 
	self.layer_name = layer_name
end

--创建副本实例
function Scene_tower_ex:create_instance(instance_id, obj)
	return self.group:clone(instance_id)
end

function Scene_tower_ex:get_self_config()
	return tower_ex_config.config[self.id]
end

function Scene_tower_ex:get_self_limit_config()
	local config = self:get_self_config()
	return config and config.limit
end

-----------------------------------------------场景实例化----------------------------------------------

function Scene_tower_ex:get_instance(scene_id)
	local instance_id = scene_id and scene_id[2]
	local instance = instance_id and self.instance_list[instance_id]
	return instance and instance:get_instance(scene_id)
end

function Scene_tower_ex:instance()
	self.group = Scene_group_ex(self.id, nil, self.layer_name)
	self.group:instance()
end

-----------------------------------------------------------------------------------------------------