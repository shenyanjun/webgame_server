
require("impact.impact_object.buff")


--防御力(物理和魔法)
Impact_4101 = oo.class(Impact_2020, "Impact_4101")
function Impact_4101:__init(obj_id, lv)
	Impact_2020.__init(self, obj_id, IMPACT_TEAM_BUFF, IMPACT_OBJ_4101)
	self.class_nm = "Impact_4101"
	--buff级别
	self.level = lv or 1
end

function Impact_4101:is_clear()
	return false
end
function Impact_4101:is_save()
	return false
end

--效果叠加时间
function Impact_4101:splice(item)
	self.param.per = self.param.per + item.param.per
	self.param.val = self.param.val + item.param.val
	return self
end

---------------------------------------------------------------
--攻击力(物理和魔法)
Impact_4102 = oo.class(Impact_2000, "Impact_4102")
function Impact_4102:__init(obj_id, lv)
	Impact_2000.__init(self, obj_id, IMPACT_TEAM_BUFF, IMPACT_OBJ_4102)
	self.class_nm = "Impact_4102"
	self.level = lv or 1
end

function Impact_4102:is_clear()
	return false
end
function Impact_4102:is_save()
	return false
end

--效果叠加时间
function Impact_4102:splice(item)
	self.param.per = self.param.per + item.param.per
	self.param.val = self.param.val + item.param.val
	return self
end


---------------------------------------------------------------
--加冰抗，雷抗，毒抗
Impact_4103 = oo.class(Impact_1950, "Impact_4103")
function Impact_4103:__init(obj_id, lv)
	Impact_1950.__init(self, obj_id, IMPACT_TEAM_BUFF, IMPACT_OBJ_4103)
	self.class_nm = "Impact_4103"
	self.level = lv or 1
end

function Impact_4103:is_clear()
	return false
end
function Impact_4103:is_save()
	return false
end

--效果叠加时间
function Impact_4103:splice(item)
	self.param.per = self.param.per + item.param.per
	self.param.val = self.param.val + item.param.val
	return self
end


---------------------------------------------------------------
--加冰，毒，雷属性
Impact_4104 = oo.class(Impact_1960, "Impact_4104")
function Impact_4104:__init(obj_id, lv)
	Impact_1960.__init(self, obj_id, IMPACT_TEAM_BUFF, IMPACT_OBJ_4104)
	self.class_nm = "Impact_4104"
	self.level = lv or 1
end

function Impact_4104:is_clear()
	return false
end
function Impact_4104:is_save()
	return false
end

--效果叠加时间
function Impact_4104:splice(item)
	self.param.per = self.param.per + item.param.per
	self.param.val = self.param.val + item.param.val
	return self
end


---------------------------------------------------------------
--增加根骨悟性体魄身法
Impact_4105 = oo.class(Impact_1970, "Impact_4105")
function Impact_4105:__init(obj_id, lv)
	Impact_1970.__init(self, obj_id, IMPACT_TEAM_BUFF, IMPACT_OBJ_4105)
	self.class_nm = "Impact_4105"
	self.level = lv or 1
end

function Impact_4105:is_clear()
	return false
end
function Impact_4105:is_save()
	return false
end

--效果叠加时间
function Impact_4105:splice(item)
	self.param.per = self.param.per + item.param.per
	self.param.val = self.param.val + item.param.val
	return self
end