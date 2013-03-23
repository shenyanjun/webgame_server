require("scene_ex.scene.entry.scene_group")
local tower_ex_config = require("scene_ex.config.tower_ex_loader")

-- 70级单人爬塔副本
Scene_group_ex = oo.class(Scene_group, "Scene_group_ex")

function Scene_group_ex:__init(map_id, instance_id, layer_name)
	Scene_group.__init(self, map_id, instance_id)
	self.layer_name = layer_name
	--self.open_layer = 7
end

function Scene_group_ex:get_self_config()
	return tower_ex_config.config[self.id]
end

function Scene_group_ex:clone(instance_id)
	local obj = Scene_group_ex(self.id, instance_id, self.layer_name)
	obj.layer_list = self.layer_list
	obj.map_list = self.map_list
	obj.map_to_layer = self.map_to_layer
	obj.instance_list = {}
	obj.owner_list = {}
	obj.is_initial = true
	obj.has_instance = false
	return obj
end

function Scene_group_ex:carry_scene(obj, pos)
	--print("Scene_group_ex:carry_scene()", pos[1], pos[2])
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
		
	local obj_id = obj:get_id()	
	if self.char_id ~= nil and self.char_id ~= obj_id then
		return SCENE_ERROR.E_EXISTS_COPY
	end
	self.char_id = obj_id

	local instance = self.instance_list[map_id]
	if not instance then
		local map_obj = self.map_list[map_id]
		if not map_obj then
			return SCENE_ERROR.E_NOT_ON_SCENE, nil
		end
		local layer_id = map_id % 100
		local scene_layer_str = self.layer_name .. layer_id
		local scene_layer_obj = _G[scene_layer_str]
		if scene_layer_obj == nil then
			print("Error: not exist:", scene_layer_str)
			scene_layer_obj = Scene_layer
		end
		instance = scene_layer_obj(self, self.id, map_id, self.instance_id, map_obj:clone(map_id), not self.has_instance)
		self.instance_list[map_id] = instance
		instance:instance()
		
		self.has_instance = true
	end
	
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