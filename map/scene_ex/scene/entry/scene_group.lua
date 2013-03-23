local tower_config = require("scene_ex.config.tower_config_loader")
Scene_group = oo.class(Scene_copy, "Scene_group")

function Scene_group:__init(map_id, instance_id)
	Scene_copy.__init(self, map_id)
	self.instance_id = instance_id
	self.cur_layer = 1
	self.open_layer = 1
	self.is_initial = false
end

function Scene_group:get_self_config()
	return tower_config.config[self.id]
end

function Scene_group:clone(instance_id)
	local obj = Scene_group(self.id, instance_id)
	obj.layer_list = self.layer_list
	obj.map_list = self.map_list
	obj.map_to_layer = self.map_to_layer
	obj.instance_list = {}
	obj.owner_list = {}
	obj.is_initial = true
	obj.has_instance = false
	return obj
end

function Scene_group:instance(args)
	if self.is_initial then
		if args and args.target then
			self.open_layer = args.target
			--self.has_instance = true
			for obj_id, obj in pairs(args.members or {}) do
				local con = obj:get_copy_con()
				con:add_count_copy(self.id)
				self.owner_list[obj_id] = true
				
				f_multi_web_sql(string.format("insert into copy_into set copy_id=%d, char_id=%d, time=%d, char_name='%s'"
							, self.id
							, obj_id
							, ev.time
							, obj:get_name()))
			end
		end
		return
	end
	
	self.layer_list = {}
	self.map_list = {}
	self.instance_list = {}
	self.map_to_layer = {}

	local config = self:get_self_config()
	if not config or not config.layer_list then
		return
	end

	local count = 0
	for _, layer in pairs(config.layer_list) do
		local map_id = layer.id
		table.insert(self.layer_list, map_id)
		count = count + 1
		self.map_to_layer[map_id] = count
		self.map_list[map_id] = g_scene_config_mgr:load_map(map_id, layer.path)
	end
	
	self.is_initial = true
end

function Scene_group:get_instance(scene_id)
	local instance_id = scene_id and scene_id[3]
	return instance_id and self.instance_list[instance_id]
end

function Scene_group:open_next()
	if self.layer_list[self.open_layer + 1] then
		self.open_layer = self.open_layer + 1
	end
end

function Scene_group:close_layer(layer_id)
	self.instance_list[layer_id] = nil
	local map_id = self.layer_list[self.cur_layer]
	if not map_id or map_id == layer_id then
		self:close()
	end
end

function Scene_group:push_current(obj)
	if not obj then
		return SCENE_ERROR.E_SCENE_CHANGE
	end
	
	local map_id = self.layer_list[self.cur_layer]
	if not map_id then
		return SCENE_ERROR.E_SCENE_CHANGE
	end
		
	local instance = self.instance_list[map_id]
	local obj_id = obj:get_id()
	if not instance or instance:get_obj(obj_id) or instance:is_door(obj_id) then
		return SCENE_ERROR.E_SCENE_CHANGE
	end
	
	return instance:carry_scene(obj, nil)
end

function Scene_group:close()
	if self.instance_id then
		local instance_id = self.instance_id
		self.instance_id = nil
		
		for _, instance in pairs(self.instance_list) do
			instance:close()
		end
		
		g_scene_mgr_ex:unregister_instance(instance_id)
	end
end

function Scene_group:carry_scene(obj, pos)
	if not obj then
		return SCENE_ERROR.E_NOT_ON_SCENE, nil
	end
	
	if self.cur_layer < self.open_layer then
		self.cur_layer = self.open_layer
	end

	local map_id = self.layer_list[self.cur_layer]
	if not map_id then
		return SCENE_ERROR.E_NOT_ON_SCENE, nil
	end
	
	local old_scene = obj:get_scene_obj()
	if old_scene and old_scene:get_id() == map_id then
		return SCENE_ERROR.E_NOT_OPEN, nil
	end
		
	local instance = self.instance_list[map_id]
	if not instance then
		local map_obj = self.map_list[map_id]
		if not map_obj then
			return SCENE_ERROR.E_NOT_ON_SCENE, nil
		end
		instance = Scene_layer(self, self.id, map_id, self.instance_id, map_obj:clone(map_id), not self.has_instance)
		self.instance_list[map_id] = instance
		instance:instance()
		
		self.has_instance = true
	end
	
	local obj_id = obj:get_id()
	if not self.owner_list[obj_id] then
		local config = self:get_self_config()
		local cycle_limit = config.limit and config.limit.cycle
		local con = obj:get_copy_con()
		if cycle_limit and con:get_count_copy(self.id) >= cycle_limit then
			return SCENE_ERROR.E_CYCLE_LIMIT, nil
		end
		con:add_count_copy(self.id)
		self.owner_list[obj_id] = true
		
		f_multi_web_sql(string.format("insert into copy_into set copy_id=%d, char_id=%d, time=%d, char_name='%s'"
					, self.id
					, obj_id
					, ev.time
					, obj:get_name()))
	end
	
	local e_code, e_desc = instance:carry_scene(obj, pos)
	if SCENE_ERROR.E_SUCCESS == e_code then
		local args = obj:get_scene_args()
		local id = tostring(self.id)
		local max_layer = args[id] or 0
		if max_layer < self.cur_layer then
			args[id] = self.cur_layer
		end
	end
	
	return e_code, e_desc
end