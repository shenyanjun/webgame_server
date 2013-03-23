Scene_entry = oo.class(nil, "Scene_entry")

function Scene_entry:__init(map_id)
	self.id = map_id
	self.status = SCENE_STATUS.OPEN
end

-----------------------------------------------场景实例化----------------------------------------------

function Scene_entry:instance(args)
end

function Scene_entry:unregister_instance(instance_id, args)
end

function Scene_entry:get_instance(scene_id)
	return self
end

-----------------------------------------------基本属性-----------------------------------------------

function Scene_entry:get_id()
	return self.id
end

function Scene_entry:get_name()
	local config = g_scene_config_mgr:get_config(self.id)
	return config and config.name
end

function Scene_entry:get_mode()
	local config = g_scene_config_mgr:get_config(self.id)
	return config and config.mode
end

function Scene_entry:get_type()
	local config = g_scene_config_mgr:get_config(self.id)
	return config and config.type
end

function Scene_entry:get_limit()
	local config = g_scene_config_mgr:get_config(self.id)
	return (config and config.limit) or 0
end

-----------------------------------------------场景入口----------------------------------------------

function Scene_entry:login_scene(obj, pos)
end

function Scene_entry:carry_scene(obj, pos, args)
end

function Scene_entry:push_scene(obj, pos)
end

-------------------------------------------------时间轮询处理------------------------------------------

function Scene_entry:on_timer(tm)
end

function Scene_entry:on_slow_timer(tm)
end

function Scene_entry:on_serialize_timer(tm)
end

----------------------------------------------------------------------------------------------------