

--隐身
Impact_1261 = oo.class(Impact_s, "Impact_1261")

function Impact_1261:__init(obj_id)
	Impact_s.__init(self, obj_id)
	self.type = IMPACT_LATENT
	self.cmd_id = IMPACT_OBJ_1261
	self.sec_count = 5    --5秒轮询一次
	self.count = 2
	self.flag = 0  
	self.class_nm = "Impact_1261"
end

--param nil
function Impact_1261:on_effect(param)
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj ~= nil then
		self:syn(param)

		local impact_con = obj:get_impact_con()
		impact_con:add_impact(self) 

		obj:set_latent(true)
	end
end
function Impact_1261:on_stop()
	local obj = g_obj_mgr:get_obj(self.obj_id)
	obj:set_latent(false)
end

