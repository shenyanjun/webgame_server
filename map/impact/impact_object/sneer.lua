
local _expr = require("config.expr")

--嘲讽
Impact_1281 = oo.class(Impact_s, "Impact_1281")

function Impact_1281:__init(obj_id)
	Impact_s.__init(self, obj_id)
	self.type = IMPACT_SNEER
	self.cmd_id = IMPACT_OBJ_1281
	self.sec_count = IMPACT_MIN_TIMER  
	self.count = 1
	self.flag = 0 
	self.class_nm = "Impact_1281"
end

--param.sour_id, param.skill_id
function Impact_1281:on_effect(param)
	--print("Impact_1281:effect", param.sour_id, param.des_id)
	self.param = param
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj ~= nil then
		self:syn(param)
		
		obj:add_sneer(param.sour_id, param.skill_id)
		local impact_con = obj:get_impact_con()
		impact_con:add_impact(self) 
	end
end
function Impact_1281:on_stop()
	local obj = g_obj_mgr:get_obj(self.obj_id)
	obj:del_sneer(self.param.sour_id, self.param.skill_id)
end

