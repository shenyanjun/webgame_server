

--无敌
Impact_1271 = oo.class(Impact_s, "Impact_1271")

function Impact_1271:__init(obj_id)
	Impact_s.__init(self, obj_id)
	self.type = IMPACT_GOD
	self.cmd_id = IMPACT_OBJ_1271
	self.sec_count = IMPACT_MIN_TIMER   
	self.count = 1
	self.flag = 0  
	self.class_nm = "Impact_1271"
end

function Impact_1271:on_effect(param)
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj ~= nil then
		self:syn(param)

		local impact_con = obj:get_impact_con()
		impact_con:add_impact(self) 
		obj:set_god(true)
	end
end
function Impact_1271:on_stop()
	local obj = g_obj_mgr:get_obj(self.obj_id)
	obj:set_god(false)
end

