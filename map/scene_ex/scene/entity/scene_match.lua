local config = require("config.world_war.config_loader")

Scene_match = oo.class(Scene_entity, "Scene_match")

function Scene_match:__init(map_id, instance_id, entry)
	Scene_entity.__init(self, map_id)
	self.entry = entry
	self.instance_id = instance_id
	self.key = {map_id, instance_id}
end

function Scene_match:on_obj_enter(obj)
	if obj:get_type() == OBJ_TYPE_HUMAN then
		obj:do_relive(1, true)
		if not obj:is_alive() then
			obj:send_relive(3)	--复活
		end
		self.entry:enter_match(obj)
	end
end

function Scene_match:on_obj_leave(obj)
	if obj:get_type() == OBJ_TYPE_HUMAN then
		self.entry:leave_match(obj)
	end
end

function Scene_match:carry_scene(obj, pos)
	pos = config.config.ground[self.id].entry
	return self:push_scene(obj, pos)
end

function Scene_match:close()
end