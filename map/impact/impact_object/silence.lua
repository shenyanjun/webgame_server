
--沉默
Impact_1291 = oo.class(Impact_s, "Impact_1291")

function Impact_1291:__init(obj_id)
	Impact_s.__init(self, obj_id)
	self.type = IMPACT_SILENCE
	self.cmd_id = IMPACT_OBJ_1291
	self.sec_count = IMPACT_MIN_TIMER 
	self.count = 1
	self.flag = 0  
	self.class_nm = "Impact_1291"
end

function Impact_1291:on_effect(param)
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj ~= nil then
		self:syn(param)

		local impact_con = obj:get_impact_con()
		impact_con:add_impact(self) 

		obj:set_silence(true)
	end
end
function Impact_1291:on_stop()
	local obj = g_obj_mgr:get_obj(self.obj_id)
	obj:set_silence(false)
end

function Impact_1291:is_save()
	return false
end

--半沉默(只能用攻击技能)
Impact_1292 = oo.class(Impact_s, "Impact_1292")

function Impact_1292:__init(obj_id)
	Impact_s.__init(self, obj_id)
	self.type = IMPACT_SILENCE
	self.cmd_id = IMPACT_OBJ_1292
	self.sec_count = IMPACT_MIN_TIMER 
	self.count = 1
	self.flag = 0  
	self.class_nm = "Impact_1292"
end

function Impact_1292:on_effect(param)
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj ~= nil then
		self:syn(param)

		local impact_con = obj:get_impact_con()
		impact_con:add_impact(self) 

		obj:set_unable_helpful(true)
	end
end
function Impact_1292:on_stop()
	local obj = g_obj_mgr:get_obj(self.obj_id)
	obj:set_unable_helpful(false)
end

function Impact_1292:is_save()
	return false
end