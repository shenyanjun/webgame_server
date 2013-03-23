
--*********相克属性buff基类(金木水火土阴阳光暗生死)************
Impact_element = oo.class(Impact_s, "Impact_element")

function Impact_element:__init(obj_id, ty, impact_id)
	Impact_s.__init(self, obj_id)
	self.type = ty
	self.cmd_id = impact_id
	self.sec_count = 1
	self.count = 15
	self.flag = 0  		 --0 下线计时，1 下线不计时          
end

--param.per
function Impact_element:on_effect(param)
	self.param = param
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj ~= nil then
		--self:syn(param)
		local impact_con = obj:get_impact_con()
		self:on_add_effect(impact_con)
		impact_con:add_impact(self)
		local impact_o = impact_con:find_impact(self.cmd_id)
		if impact_o then impact_o:syn(param) end
		if param.type >= IMPACT_TYPE.JIN and param.type <= IMPACT_TYPE.TU then
			obj:check_magickey()
		end
		--local _ = obj.on_update_attribute and obj:on_update_attribute(1)
	end
end

--效果叠加时间
function Impact_element:splice(item)
	local obj = g_obj_mgr:get_obj(self.obj_id)
	local impact_con = obj and obj:get_impact_con()

	if item.level >= self.level then        --高级别替换低级别
		self:ineffectiveness(impact_con)
		return item
	else
		item:ineffectiveness(impact_con)
		return self
	end
	return item
end

function Impact_element:on_stop()
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj ~= nil then
		local impact_con = obj:get_impact_con()
		self:ineffectiveness(impact_con)
		--local _ = obj.on_update_attribute and obj:on_update_attribute(1)
		if self.param.type >= IMPACT_TYPE.JIN and self.param.type <= IMPACT_TYPE.TU then
			obj:check_magickey()
		end
	end
end

--取消之前生效的值
function Impact_element:ineffectiveness(impact_con)
	self:on_ineffectiveness(impact_con)
end

function Impact_element:get_effect()
	return self.param.per or 0, self.param.val or 0
end

function Impact_element:get_effect_type()
	if self.param.type and self.param.type >= IMPACT_TYPE.JIN and self.param.type <= IMPACT_TYPE.DEATH then
		return self.param.type
	end
end

--加入生效的值
function Impact_element:on_add_effect(impact_con)
	local per, val = self:get_effect()
	local type = self:get_effect_type()
	if type ~= nil then
		impact_con:add_impact_effect(type, per, val)
	end
end

--取消之前生效的值
function Impact_element:on_ineffectiveness(impact_con)
	local per, val = self:get_effect()
	local type = self:get_effect_type()
	if type ~= nil then
		impact_con:add_impact_effect(type, -per, -val)
	end
end

function Impact_element:on_resume()
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj ~= nil then
		local impact_con = obj:get_impact_con()
		self:on_add_effect(impact_con)
		self:syn(self.param)
	end
end

function Impact_element:get_param()
	local type = self:get_effect_type()
	return {f_get_string(1571 + type - IMPACT_TYPE.JIN), math.abs(self.param.per or 0)*100, math.abs(self.param.val or 0)}
end

function Impact_element:is_clear()
	return true
end

---------------------------------------------------------------

--相克属性：连斩副本内五行buff金
Impact_3501 = oo.class(Impact_element, "Impact_3501")
function Impact_3501:__init(obj_id, lv)
	Impact_element.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_3501)
	self.class_nm = "Impact_3501"
	self.level = lv or 1
end
function Impact_3501:is_save()
	return false
end
function Impact_3501:is_clear()
	return false
end

--相克属性：连斩副本内五行buff木
Impact_3502 = oo.class(Impact_element, "Impact_3502")
function Impact_3502:__init(obj_id, lv)
	Impact_element.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_3502)
	self.class_nm = "Impact_3502"
	self.level = lv or 1
end
function Impact_3502:is_save()
	return false
end
function Impact_3502:is_clear()
	return false
end

--相克属性：连斩副本内五行buff水
Impact_3503 = oo.class(Impact_element, "Impact_3503")
function Impact_3503:__init(obj_id, lv)
	Impact_element.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_3503)
	self.class_nm = "Impact_3503"
	self.level = lv or 1
end
function Impact_3503:is_save()
	return false
end
function Impact_3503:is_clear()
	return false
end

--相克属性：连斩副本内五行buff火
Impact_3504 = oo.class(Impact_element, "Impact_3504")
function Impact_3504:__init(obj_id, lv)
	Impact_element.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_3504)
	self.class_nm = "Impact_3504"
	self.level = lv or 1
end
function Impact_3504:is_save()
	return false
end
function Impact_3504:is_clear()
	return false
end

--相克属性：连斩副本内五行buff土
Impact_3505 = oo.class(Impact_element, "Impact_3505")
function Impact_3505:__init(obj_id, lv)
	Impact_element.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_3505)
	self.class_nm = "Impact_3505"
	self.level = lv or 1
end
function Impact_3505:is_save()
	return false
end
function Impact_3505:is_clear()
	return false
end

--相克属性：连斩副本光暗buff
Impact_3506 = oo.class(Impact_element, "Impact_3506")
function Impact_3506:__init(obj_id, lv)
	Impact_element.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_3506)
	self.class_nm = "Impact_3506"
	self.level = lv or 1
end
function Impact_3506:is_clear()
	return false
end
function Impact_3506:get_param()
	local type = self:get_effect_type()
	return {f_get_string(1571 + type - IMPACT_TYPE.JIN), self.level, math.abs(self.param.val and self.param.val+1 or 0)}
end