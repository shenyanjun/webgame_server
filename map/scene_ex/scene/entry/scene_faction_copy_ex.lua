local faction_copy_config = require("scene_ex.config.faction_copy_loader")
Scene_faction_copy_ex = oo.class(Scene_faction_copy, "Scene_faction_copy_ex")

--副本出口
function Scene_faction_copy_ex:get_home_carry(obj)
	local config = self:get_self_config()
	local home_carry = config and config.home
	if not home_carry or not home_carry.id or not home_carry.pos or not home_carry.pos[1] or not home_carry.pos[2] then
		return nil, nil
	end
	return home_carry.id, home_carry.pos
end

function Scene_faction_copy_ex:get_self_config()
	return faction_copy_config.config[self.id]
end

--创建副本实例
function Scene_faction_copy_ex:create_instance(instance_id, obj)
	local config = self:get_self_config()
	if config == nil then
		return
	end
	g_faction_mgr:set_fb(obj:get_id(), self.id)
	local pkt = {}
	pkt.faction_id = instance_id
	pkt.switch_flag = 1
	pkt.scene_id = self.id
	g_faction_mgr:switch_fb(pkt)
	--
	if self.map_list == nil then
		self.map_list = {}
	end
	local layer_id = g_faction_mgr:get_fb_level(instance_id)
	local layer_choose = g_faction_mgr:get_choose_fb_level(instance_id) or layer_id
	if layer_id == 0 then
		layer_id = 1
		g_faction_mgr:set_fb_level(instance_id, 1)
	end
	if layer_choose < 1 then
		layer_choose = 1
	end
	layer_id = math.min(layer_id, #config.layer, layer_choose)
	local map_id = config.layer[layer_id].map_id
	local map_obj = self.map_list[map_id]
	if map_obj == nil then
		map_obj = g_scene_config_mgr:load_map(map_id, config.layer[layer_id].path)
		self.map_list[map_id] = map_obj
	end
	
	return Scene_faction(self.id, map_id, instance_id, layer_id, map_obj:clone(map_id))
end