
--反弹
Impact_1521 = oo.class(Impact_s, "Impact_1521")

function Impact_1521:__init(obj_id)
	Impact_s.__init(self, obj_id)
	self.type = IMPACT_REFLEX
	self.cmd_id = IMPACT_OBJ_1521
	self.sec_count = IMPACT_MIN_TIMER  
	self.count = 5
	self.flag = 0  
	self.class_nm = "Impact_1521"
end

function Impact_1521:on_effect(param)
	self.param = param
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj ~= nil then
		self:syn(param)

		local impact_con = obj:get_impact_con()
		impact_con:add_impact(self) 

		obj:set_reflex(true, self.param.per)
	end
end

function Impact_1521:on_stop()
	local obj = g_obj_mgr:get_obj(self.obj_id)
	obj:set_reflex(false)
end

function Impact_1521:get_param()
	return {math.abs(self.param.per or 0)*100, math.abs(self.param.val or 0)}
end

--反弹
Impact_1522 = oo.class(Impact_1521, "Impact_1522")

function Impact_1522:__init(obj_id)
	Impact_1521.__init(self, obj_id)
	self.type = IMPACT_REFLEX
	self.cmd_id = IMPACT_OBJ_1522
	self.sec_count = 5  
	self.count = 6
	self.flag = 0  
	self.class_nm = "Impact_1522"
end
