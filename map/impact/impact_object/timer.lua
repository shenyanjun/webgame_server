local _attr = require("config.attr_config")
--计时效果，时间到了就会消失，不产生其它作用

--铃星复活倒计时
Impact_4001 = oo.class(Impact_s, "Impact_4001")

function Impact_4001:__init(obj_id)
	Impact_s.__init(self, obj_id)
	self.type = IMPACT_TIMER
	self.cmd_id = IMPACT_OBJ_4001
	self.sec_count = 60		  
	self.count = 1
	self.flag = 0  
	self.class_nm = "Impact_4001"
end

function Impact_4001:on_effect(param)
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj ~= nil then
		self:syn(param)

		local impact_con = obj:get_impact_con()
		impact_con:add_impact(self) 
	end
end

function Impact_4001:is_clear()
	return false
end

--人物暴走后的虚弱
Impact_4002 = oo.class(Impact_s, "Impact_4002")

function Impact_4002:__init(obj_id)
	Impact_s.__init(self, obj_id)
	self.type = IMPACT_TIMER
	self.cmd_id = IMPACT_OBJ_4002
	self.sec_count = 1  
	self.count = 1
	self.flag = 0  
	self.class_nm = "Impact_4002"
end

function Impact_4002:on_effect(param)
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj ~= nil then
		self:syn(param)

		local impact_con = obj:get_impact_con()
		impact_con:add_impact(self) 
	end
end

function Impact_4002:is_clear()
	return false
end

function Impact_4002:is_save()
	return false
end
