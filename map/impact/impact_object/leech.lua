

--吸血
Impact_1251 = oo.class(Impact_s, "Impact_1251")

function Impact_1251:__init(obj_id)
	Impact_s.__init(self, obj_id)
	self.type = IMPACT_LEECH
	self.cmd_id = IMPACT_OBJ_1251
	self.sec_count = 1    
	self.count = 3
	self.flag = 0  
	self.class_nm = "Impact_1251"
end

--伤害转为血量, param.damage
function Impact_1251:get_effect()
	return self.param.dg_per
end

--param.dg_per
function Impact_1251:on_effect(param)
	--print("Impact_1251:on_effect")
	self.param = param
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj ~= nil then

		local impact_con = obj:get_impact_con()
		impact_con:add_impact(self) 
		self:syn(param)
	end
end

--附加参数,给客户端
function Impact_1251:get_param()
	return {math.abs(self.param.dg_per * 100)}
end

Impact_1252 = oo.class(Impact_1251, "Impact_1252")
function Impact_1252:__init(obj_id)
	Impact_1251.__init(self, obj_id)
	self.type = IMPACT_LEECH
	self.cmd_id = IMPACT_OBJ_1252
	self.sec_count = 5    
	self.count = 6
	self.flag = 0  
	self.class_nm = "Impact_1252"
end
