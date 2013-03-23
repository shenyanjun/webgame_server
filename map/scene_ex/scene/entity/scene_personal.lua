-- 个人副本
Scene_personal = oo.class(Scene_instance, "Scene_personal")

function Scene_personal:on_obj_enter(obj)
	if obj:get_type() == OBJ_TYPE_HUMAN then
		if self.not_human then
			self.not_human = false
		end 
	end
end

function Scene_personal:on_timer(tm)
	
	self:check_close()

	self.obj_mgr:on_timer(tm)
end

function Scene_personal:instance()
	local config = self:get_self_config()
	self.end_time = ev.time + config.time
	self.class_type = config.class
	if self.class_type == 1 then
		self.check_close_time = ev.time + 60
	end

	self.obj_mgr = Scene_obj_mgr_ex(Scene_monster_layout(self.key, false), Scene_monster_copy_mgr())
	self.obj_mgr:instance(self.map_obj:get_w(), self.map_obj:get_h())
end

function Scene_personal:check_close()
	
	if self.class_type == 1 then
		if self.check_close_time < ev.time and self.obj_mgr then
			local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
			if con == nil or table.is_empty(con:get_obj_list()) then
				self:close()
			end
			self.check_close_time = ev.time + 60
		end
	else
		if self.end_time and self.end_time <= ev.time then
			self:close()
		end
	end
end