

Impact_stop = oo.class(Impact_s, "Impact_stop")

function Impact_stop:__init(obj_id)
	Impact_s.__init(self, obj_id)
end

function Impact_stop:on_resume()
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj ~= nil then
		obj:set_active(false)
	end
	self:syn(self.param)
end

function Impact_stop:on_effect(param)
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj ~= nil then
		self:syn(param)

		local impact_con = obj:get_impact_con()
		impact_con:add_impact(self) 
		
		obj:set_active(false)
	end
end
function Impact_stop:on_stop()
	local obj = g_obj_mgr:get_obj(self.obj_id)
	local _ = obj and obj:set_active(true)
end

function Impact_stop:is_save()
	return false
end

--效果叠加时间
function Impact_stop:splice(item)
	local obj = g_obj_mgr:get_obj(self.obj_id)
	local _ = obj and obj:set_active(true)
	if item.level >= self.level then        --高级别替换低级别
		return item
	else
		return self
	end
end

--定身
Impact_1211 = oo.class(Impact_stop, "Impact_1211")

function Impact_1211:__init(obj_id)
	Impact_stop.__init(self, obj_id)
	self.type = IMPACT_STOP
	self.cmd_id = IMPACT_OBJ_1211
	self.count = 5
	self.flag = 1  
	self.class_nm = "Impact_1211"
end

--昏迷
Impact_1212 = oo.class(Impact_stop, "Impact_1212")

function Impact_1212:__init(obj_id)
	Impact_stop.__init(self, obj_id)
	self.type = IMPACT_STOP
	self.cmd_id = IMPACT_OBJ_1212
	self.count = 5
	self.flag = 1  
	self.class_nm = "Impact_1212"
end
