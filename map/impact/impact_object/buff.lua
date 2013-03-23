

--*********人物属性buff基类************
Impact_attr = oo.class(Impact_s, "Impact_attr")

function Impact_attr:__init(obj_id, ty, impact_id)
	Impact_s.__init(self, obj_id)
	self.type = ty
	self.cmd_id = impact_id
	self.sec_count = 60    --60秒轮询一次
	self.count = 15
	self.flag = 0  
end

--param.per
function Impact_attr:on_effect(param)
	self.param = param
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj ~= nil then
		--self:syn(param)
		local impact_con = obj:get_impact_con()
		self:on_add_effect(impact_con)
		impact_con:add_impact(self)
		local impact_o = impact_con:find_impact(self.cmd_id)
		if impact_o then impact_o:syn(param) end

		local _ = obj.on_update_attribute and obj:on_update_attribute(1)
	end
end

--效果叠加时间
function Impact_attr:splice(item)
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

function Impact_attr:on_stop()
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj ~= nil then
		local impact_con = obj:get_impact_con()
		self:ineffectiveness(impact_con)
		local _ = obj.on_update_attribute and obj:on_update_attribute(1)
	end
end

--取消之前生效的值
function Impact_attr:ineffectiveness(impact_con)
	self:on_ineffectiveness(impact_con)
end

--加入生效的值，子类重写
function Impact_attr:on_add_effect(impact_con)
end

--取消之前生效的值，子类重写
function Impact_attr:on_ineffectiveness(impact_con)
end

function Impact_attr:on_resume()
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj ~= nil then
		local impact_con = obj:get_impact_con()
		self:on_add_effect(impact_con)
		self:syn(self.param)
	end
end

function Impact_attr:get_param()
	return {math.abs(self.param.per or 0)*100, math.abs(self.param.val or 0)}
end

-------------增加物理攻击力-------------
Impact_1400 = oo.class(Impact_attr, "Impact_1400")

function Impact_1400:__init(obj_id, ty, impact_id)
	Impact_attr.__init(self, obj_id, ty, impact_id)
end

function Impact_1400:get_effect()
	return self.param.per or 0, self.param.val or 0
end

function Impact_1400:on_add_effect(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.PHYSICAL_AK, per, val)
end

function Impact_1400:on_ineffectiveness(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.PHYSICAL_AK, -per, -val)
end

--技能效果1
Impact_1401 = oo.class(Impact_1400, "Impact_1401")
function Impact_1401:__init(obj_id, lv)
	Impact_1400.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_1401)
	self.class_nm = "Impact_1401"

	--buff级别
	self.level = lv or 1
end

--[[--技能效果2
Impact_1402 = oo.class(Impact_1400, "Impact_1402")
function Impact_1402:__init(obj_id, lv)
	Impact_1400.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_1402)
	self.class_nm = "Impact_1402"

	--buff级别
	self.level = lv or 1
end]]

--道具效果
Impact_1405 = oo.class(Impact_1400, "Impact_1405")
function Impact_1405:__init(obj_id)
	Impact_1400.__init(self, obj_id, IMPACT_PROP_BUFF, IMPACT_OBJ_1405)
	self.class_nm = "Impact_1405"
end
function Impact_1405:is_clear()
	return false
end

--TD效果
Impact_1406 = oo.class(Impact_1400, "Impact_1406")
function Impact_1406:__init(obj_id, lv)
	Impact_1400.__init(self, obj_id, IMPACT_TD_BUFF, IMPACT_OBJ_1406)
	self.class_nm = "Impact_1406"
	self.sec_count = 5    --5秒轮询一次
	--buff级别
	self.level = lv or 1
end
function Impact_1406:is_clear()
	return false
end

--宠物技能效果
Impact_1407 = oo.class(Impact_1400, "Impact_1407")
function Impact_1407:__init(obj_id, lv)
	Impact_1400.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_1407)
	self.class_nm = "Impact_1407"

	--buff级别
	self.level = lv or 1
end

--TD效果
Impact_1408 = oo.class(Impact_1400, "Impact_1408")
function Impact_1408:__init(obj_id, lv)
	Impact_1400.__init(self, obj_id, IMPACT_TD_BUFF, IMPACT_OBJ_1408)
	self.class_nm = "Impact_1408"
	self.sec_count = 5    --5秒轮询一次
	--buff级别
	self.level = lv or 1
end
function Impact_1408:is_clear()
	return false
end

----------增加魔法攻击力----------------
Impact_1410 = oo.class(Impact_attr, "Impact_1410")

function Impact_1410:__init(obj_id, ty, impact_id)
	Impact_attr.__init(self, obj_id, ty, impact_id)
end
function Impact_1410:get_effect()
	return self.param.per or 0, self.param.val or 0
end


function Impact_1410:on_add_effect(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.MAGIC_AK, per, val)
end

function Impact_1410:on_ineffectiveness(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.MAGIC_AK, -per, -val)
end

--技能效果1
Impact_1411 = oo.class(Impact_1410, "Impact_1411")
function Impact_1411:__init(obj_id, lv)
	Impact_1410.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_1411)
	self.class_nm = "Impact_1411"

	--buff级别
	self.level = lv or 1
end

--技能效果2
--[[Impact_1412 = oo.class(Impact_1410, "Impact_1412")
function Impact_1412:__init(obj_id, lv)
	Impact_1410.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_1412)
	self.class_nm = "Impact_1412"

	--buff级别
	self.level = lv or 1
end]]

--道具效果
Impact_1415 = oo.class(Impact_1400, "Impact_1415")
function Impact_1415:__init(obj_id)
	Impact_1400.__init(self, obj_id, IMPACT_PROP_BUFF, IMPACT_OBJ_1415)
	self.class_nm = "Impact_1415"
end
function Impact_1415:is_clear()
	return false
end

--TD效果
Impact_1416 = oo.class(Impact_1410, "Impact_1416")
function Impact_1416:__init(obj_id, lv)
	Impact_1410.__init(self, obj_id, IMPACT_TD_BUFF, IMPACT_OBJ_1416)
	self.class_nm = "Impact_1416"
	self.sec_count = 5    --5秒轮询一次
	--buff级别
	self.level = lv or 1
end
function Impact_1416:is_clear()
	return false
end

--技能效果3  天机印
Impact_1417 = oo.class(Impact_1410, "Impact_1417")
function Impact_1417:__init(obj_id, lv)
	Impact_1410.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_1417)
	self.class_nm = "Impact_1417"
	--buff级别
	self.level = lv or 1
end

--宠物技能效果1
Impact_1418 = oo.class(Impact_1410, "Impact_1418")
function Impact_1418:__init(obj_id, lv)
	Impact_1410.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_1418)
	self.class_nm = "Impact_1418"

	--buff级别
	self.level = lv or 1
end

--TD效果
Impact_1419 = oo.class(Impact_1410, "Impact_1419")
function Impact_1419:__init(obj_id, lv)
	Impact_1410.__init(self, obj_id, IMPACT_TD_BUFF, IMPACT_OBJ_1419)
	self.class_nm = "Impact_1419"
	self.sec_count = 5    --5秒轮询一次
	--buff级别
	self.level = lv or 1
end
function Impact_1419:is_clear()
	return false
end

----------增加物理防御--------------
Impact_1420 = oo.class(Impact_attr, "Impact_1420")

function Impact_1420:__init(obj_id, ty, impact_id)
	Impact_attr.__init(self, obj_id, ty, impact_id)
end
function Impact_1420:get_effect()
	return self.param.per or 0, self.param.val or 0
end

function Impact_1420:on_add_effect(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.PHYSICAL_DE, per, val)
end

function Impact_1420:on_ineffectiveness(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.PHYSICAL_DE, -per, -val)
end

--技能效果1
Impact_1421 = oo.class(Impact_1420, "Impact_1421")
function Impact_1421:__init(obj_id, lv)
	Impact_1420.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_1421)
	self.class_nm = "Impact_1421"

	--buff级别
	self.level = lv or 1
end

--[[--技能效果2
Impact_1422 = oo.class(Impact_1420, "Impact_1422")
function Impact_1422:__init(obj_id, lv)
	Impact_1420.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_1422)
	self.class_nm = "Impact_1422"

	--buff级别
	self.level = lv or 1
end]]

--道具效果
Impact_1425 = oo.class(Impact_1420, "Impact_1425")
function Impact_1425:__init(obj_id)
	Impact_1420.__init(self, obj_id, IMPACT_PROP_BUFF, IMPACT_OBJ_1425)
	self.class_nm = "Impact_1425"
end
function Impact_1425:is_clear()
	return false
end

--TD效果
Impact_1426 = oo.class(Impact_1420, "Impact_1426")
function Impact_1426:__init(obj_id)
	Impact_1420.__init(self, obj_id, IMPACT_TD_BUFF, IMPACT_OBJ_1426)
	self.class_nm = "Impact_1426"
	self.sec_count = 5    --5秒轮询一次
end
function Impact_1426:is_clear()
	return false
end

--宠物技能效果
Impact_1427 = oo.class(Impact_1420, "Impact_1427")
function Impact_1427:__init(obj_id, lv)
	Impact_1420.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_1427)
	self.class_nm = "Impact_1427"

	--buff级别
	self.level = lv or 1
end

--法宝技能效果
Impact_4053 = oo.class(Impact_1420, "Impact_4053")
function Impact_4053:__init(obj_id, lv)
	Impact_1420.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_4053)
	self.class_nm = "Impact_4053"
	self.sec_count = 1
	--buff级别
	self.level = lv or 1
end

--------------增加魔法防御-----------------
Impact_1430 = oo.class(Impact_attr, "Impact_1430")

function Impact_1430:__init(obj_id, ty, impact_id)
	Impact_attr.__init(self, obj_id, ty, impact_id)
end
function Impact_1430:get_effect()
	return self.param.per or 0, self.param.val or 0
end

function Impact_1430:on_add_effect(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.MAGIC_DE, per, val)
end

function Impact_1430:on_ineffectiveness(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.MAGIC_DE, -per, -val)
end

--技能效果1
Impact_1431 = oo.class(Impact_1430, "Impact_1431")
function Impact_1431:__init(obj_id, lv)
	Impact_1430.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_1431)
	self.class_nm = "Impact_1431"

	--buff级别
	self.level = lv or 1
end

--[[--技能效果2
Impact_1432 = oo.class(Impact_1430, "Impact_1432")
function Impact_1432:__init(obj_id, lv)
	Impact_1430.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_1432)
	self.class_nm = "Impact_1431"

	--buff级别
	self.level = lv or 1
end]]

--道具效果
Impact_1435 = oo.class(Impact_1430, "Impact_1435")
function Impact_1435:__init(obj_id)
	Impact_1430.__init(self, obj_id, IMPACT_PROP_BUFF, IMPACT_OBJ_1435)
	self.class_nm = "Impact_1435"
end
function Impact_1435:is_clear()
	return false
end

--TD效果
Impact_1436 = oo.class(Impact_1430, "Impact_1436")
function Impact_1436:__init(obj_id)
	Impact_1430.__init(self, obj_id, IMPACT_TD_BUFF, IMPACT_OBJ_1436)
	self.class_nm = "Impact_1436"
	self.sec_count = 5    --5秒轮询一次
end
function Impact_1436:is_clear()
	return false
end

--宠物技能效果1
Impact_1437 = oo.class(Impact_1430, "Impact_1437")
function Impact_1437:__init(obj_id, lv)
	Impact_1430.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_1437)
	self.class_nm = "Impact_1437"

	--buff级别
	self.level = lv or 1
end

--------------增加体魄--------------
Impact_1460 = oo.class(Impact_attr, "Impact_1460")

function Impact_1460:__init(obj_id, ty, impact_id)
	Impact_attr.__init(self, obj_id, ty, impact_id)
end
function Impact_1460:get_effect()
	return self.param.per or 0, self.param.val or 0
end

function Impact_1460:on_add_effect(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.STEMINA, per, val)
end

function Impact_1460:on_ineffectiveness(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.STEMINA, -per, -val)
end

--技能效果
Impact_1461 = oo.class(Impact_1460, "Impact_1461")
function Impact_1461:__init(obj_id, lv)
	Impact_1460.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_1461)
	self.class_nm = "Impact_1461"

	--buff级别
	self.level = lv or 1
end

--道具效果
Impact_1465 = oo.class(Impact_1460, "Impact_1465")
function Impact_1465:__init(obj_id)
	Impact_1460.__init(self, obj_id, IMPACT_PROP_BUFF, IMPACT_OBJ_1465)
	self.class_nm = "Impact_1465"
end
function Impact_1465:is_clear()
	return false
end

--战场附加效果
Impact_1466 = oo.class(Impact_1460, "Impact_1466")
function Impact_1466:__init(obj_id)
	Impact_1460.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_1466)
	self.class_nm = "Impact_1466"
end
function Impact_1466:is_clear()
	return false
end
function Impact_1466:is_save()
	return false
end


-----------增加智力(悟性)--------------
Impact_1470 = oo.class(Impact_attr, "Impact_1470")

function Impact_1470:__init(obj_id, ty, impact_id)
	Impact_attr.__init(self, obj_id, ty, impact_id)
end
function Impact_1470:get_effect()
	return self.param.per or 0, self.param.val or 0
end


function Impact_1470:on_add_effect(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.INTELLIGENCE, per, val)
end

function Impact_1470:on_ineffectiveness(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.INTELLIGENCE, -per, -val)
end

--技能效果
Impact_1471 = oo.class(Impact_1470, "Impact_1471")
function Impact_1471:__init(obj_id, lv)
	Impact_1470.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_1471)
	self.class_nm = "Impact_1471"

	--buff级别
	self.level = lv or 1
end

--道具效果
Impact_1475 = oo.class(Impact_1470, "Impact_1475")
function Impact_1475:__init(obj_id)
	Impact_1470.__init(self, obj_id, IMPACT_PROP_BUFF, IMPACT_OBJ_1475)
	self.class_nm = "Impact_1475"
end
function Impact_1475:is_clear()
	return false
end


------------降伤害(只对怪有效)----------
Impact_1830 = oo.class(Impact_attr, "Impact_1830")

function Impact_1830:__init(obj_id, ty, impact_id)
	Impact_attr.__init(self, obj_id, ty, impact_id)
	self.sec_count = 10
end
function Impact_1830:get_effect()
	return -(self.param.per or 0), -(self.param.val or 0)
end


function Impact_1830:on_add_effect(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.SUB_DAMAGE, per, val)
end

function Impact_1830:on_ineffectiveness(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.SUB_DAMAGE, -per, -val)
end

--技能效果
Impact_1831 = oo.class(Impact_1830, "Impact_1831")
function Impact_1831:__init(obj_id, lv)
	Impact_1830.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_1831)
	self.class_nm = "Impact_1831"

	--buff级别
	self.level = lv or 1
end

--道具效果
Impact_1835 = oo.class(Impact_1830, "Impact_1835")
function Impact_1835:__init(obj_id)
	Impact_1830.__init(self, obj_id, IMPACT_PROP_BUFF, IMPACT_OBJ_1835)
	self.class_nm = "Impact_1835"
end
function Impact_1835:is_clear()
	return false
end

------------降伤害(只对人有效)----------
Impact_1910 = oo.class(Impact_attr, "Impact_1910")

function Impact_1910:__init(obj_id, ty, impact_id)
	Impact_attr.__init(self, obj_id, ty, impact_id)
	self.sec_count = 1
end
function Impact_1910:get_effect()
	return -(self.param.per or 0), -(self.param.val or 0)
end


function Impact_1910:on_add_effect(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.SUB_DAMAGE_H, per, val)
end

function Impact_1910:on_ineffectiveness(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.SUB_DAMAGE_H, -per, -val)
end

--法宝技能效果
Impact_4052 = oo.class(Impact_1910, "Impact_4052")
function Impact_4052:__init(obj_id, lv)
	Impact_1910.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_4052)
	self.class_nm = "Impact_4052"

	--buff级别
	self.level = lv or 1
end

------------降伤害(对怪对人有效)----------
Impact_1920 = oo.class(Impact_attr, "Impact_1920")

function Impact_1920:__init(obj_id, ty, impact_id)
	Impact_attr.__init(self, obj_id, ty, impact_id)
	self.sec_count = 1
end
function Impact_1920:get_effect()
	return -(self.param.per or 0), -(self.param.val or 0)
end


function Impact_1920:on_add_effect(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.SUB_DAMAGE, per, val)
	impact_con:add_impact_effect(IMPACT_TYPE.SUB_DAMAGE_H, per, val)
end

function Impact_1920:on_ineffectiveness(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.SUB_DAMAGE, -per, -val)
	impact_con:add_impact_effect(IMPACT_TYPE.SUB_DAMAGE_H, -per, -val)
end

--法宝技能效果
Impact_4054 = oo.class(Impact_1920, "Impact_4054")
function Impact_4054:__init(obj_id, lv)
	Impact_1920.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_4054)
	self.class_nm = "Impact_4054"

	--buff级别
	self.level = lv or 1
end

--------------增加冰抗------------
Impact_1700 = oo.class(Impact_attr, "Impact_1700")

function Impact_1700:__init(obj_id, ty, impact_id)
	Impact_attr.__init(self, obj_id, ty, impact_id)
	self.sec_count = 5    --5秒轮询一次
end
function Impact_1700:get_effect()
	return self.param.per or 0, self.param.val or 0
end

function Impact_1700:on_add_effect(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.ICE_DE, per, val)
end

function Impact_1700:on_ineffectiveness(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.ICE_DE, -per, -val)
end

--技能效果
Impact_1701 = oo.class(Impact_1700, "Impact_1701")
function Impact_1701:__init(obj_id, lv)
	Impact_1700.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_1701)
	self.class_nm = "Impact_1701"

	--buff级别
	self.level = lv or 1
end

--TD效果
Impact_1702 = oo.class(Impact_1700, "Impact_1702")
function Impact_1702:__init(obj_id)
	Impact_1700.__init(self, obj_id, IMPACT_TD_BUFF, IMPACT_OBJ_1702)
	self.class_nm = "Impact_1702"
end
function Impact_1702:is_clear()
	return false
end

--道具效果
Impact_1705 = oo.class(Impact_1700, "Impact_1705")
function Impact_1705:__init(obj_id)
	Impact_1700.__init(self, obj_id, IMPACT_PROP_BUFF, IMPACT_OBJ_1705)
	self.class_nm = "Impact_1705"
end
function Impact_1705:is_clear()
	return false
end

--宠物技能效果
Impact_1706 = oo.class(Impact_1700, "Impact_1706")
function Impact_1706:__init(obj_id, lv)
	Impact_1700.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_1706)
	self.class_nm = "Impact_1706"

	--buff级别
	self.level = lv or 1
end

--TD效果
Impact_1707 = oo.class(Impact_1700, "Impact_1707")
function Impact_1707:__init(obj_id)
	Impact_1700.__init(self, obj_id, IMPACT_TD_BUFF, IMPACT_OBJ_1707)
	self.class_nm = "Impact_1707"
end
function Impact_1707:is_clear()
	return false
end

--法宝技能效果
Impact_4062 = oo.class(Impact_1700, "Impact_4062")
function Impact_4062:__init(obj_id, lv)
	Impact_1700.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_4062)
	self.class_nm = "Impact_4062"

	--buff级别
	self.level = lv or 1
end

--------------增加火抗------------
Impact_1710 = oo.class(Impact_attr, "Impact_1710")

function Impact_1710:__init(obj_id, ty, impact_id)
	Impact_attr.__init(self, obj_id, ty, impact_id)
	self.sec_count = 5    --5秒轮询一次
end
function Impact_1710:get_effect()
	return self.param.per or 0, self.param.val or 0
end

function Impact_1710:on_add_effect(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.FIRE_DE, per, val)
end

function Impact_1710:on_ineffectiveness(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.FIRE_DE, -per, -val)
end

--技能效果
Impact_1711 = oo.class(Impact_1710, "Impact_1711")
function Impact_1711:__init(obj_id, lv)
	Impact_1710.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_1711)
	self.class_nm = "Impact_1711"

	--buff级别
	self.level = lv or 1
end

--TD效果
Impact_1712 = oo.class(Impact_1710, "Impact_1712")
function Impact_1712:__init(obj_id)
	Impact_1710.__init(self, obj_id, IMPACT_TD_BUFF, IMPACT_OBJ_1712)
	self.class_nm = "Impact_1712"
end
function Impact_1712:is_clear()
	return false
end

--TD效果
Impact_1713 = oo.class(Impact_1710, "Impact_1713")
function Impact_1713:__init(obj_id)
	Impact_1710.__init(self, obj_id, IMPACT_TD_BUFF, IMPACT_OBJ_1713)
	self.class_nm = "Impact_1713"
end
function Impact_1713:is_clear()
	return false
end


--道具效果
Impact_1715 = oo.class(Impact_1710, "Impact_1715")
function Impact_1715:__init(obj_id)
	Impact_1710.__init(self, obj_id, IMPACT_PROP_BUFF, IMPACT_OBJ_1715)
	self.class_nm = "Impact_1715"
end
function Impact_1715:is_clear()
	return false
end

--宠物技能效果
Impact_1716 = oo.class(Impact_1710, "Impact_1716")
function Impact_1716:__init(obj_id, lv)
	Impact_1710.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_1716)
	self.class_nm = "Impact_1716"

	--buff级别
	self.level = lv or 1
end

--法宝技能效果
Impact_4064 = oo.class(Impact_1710, "Impact_4064")
function Impact_4064:__init(obj_id, lv)
	Impact_1710.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_4064)
	self.class_nm = "Impact_4064"
	self.sec_count = 1
	--buff级别
	self.level = lv or 1
end

--------------增加毒抗------------
Impact_1720 = oo.class(Impact_attr, "Impact_1720")

function Impact_1720:__init(obj_id, ty, impact_id)
	Impact_attr.__init(self, obj_id, ty, impact_id)
	self.sec_count = 5    --5秒轮询一次
end
function Impact_1720:get_effect()
	return self.param.per or 0, self.param.val or 0
end

function Impact_1720:on_add_effect(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.POISON_DE, per, val)
end

function Impact_1720:on_ineffectiveness(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.POISON_DE, -per, -val)
end

--技能效果
Impact_1721 = oo.class(Impact_1720, "Impact_1721")
function Impact_1721:__init(obj_id, lv)
	Impact_1720.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_1721)
	self.class_nm = "Impact_1721"

	--buff级别
	self.level = lv or 1
end

--TD效果
Impact_1722 = oo.class(Impact_1720, "Impact_1722")
function Impact_1722:__init(obj_id)
	Impact_1720.__init(self, obj_id, IMPACT_TD_BUFF, IMPACT_OBJ_1722)
	self.class_nm = "Impact_1722"
end
function Impact_1722:is_clear()
	return false
end

--TD效果
Impact_1723 = oo.class(Impact_1720, "Impact_1723")
function Impact_1723:__init(obj_id)
	Impact_1720.__init(self, obj_id, IMPACT_TD_BUFF, IMPACT_OBJ_1723)
	self.class_nm = "Impact_1723"
end
function Impact_1723:is_clear()
	return false
end

--道具效果
Impact_1725 = oo.class(Impact_1720, "Impact_1725")
function Impact_1725:__init(obj_id)
	Impact_1720.__init(self, obj_id, IMPACT_PROP_BUFF, IMPACT_OBJ_1725)
	self.class_nm = "Impact_1725"
end
function Impact_1725:is_clear()
	return false
end

--宠物技能效果
Impact_1726 = oo.class(Impact_1720, "Impact_1726")
function Impact_1726:__init(obj_id, lv)
	Impact_1720.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_1726)
	self.class_nm = "Impact_1726"

	--buff级别
	self.level = lv or 1
end

--法宝技能效果
Impact_4065 = oo.class(Impact_1720, "Impact_4065")
function Impact_4065:__init(obj_id, lv)
	Impact_1720.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_4065)
	self.class_nm = "Impact_4065"
	self.sec_count = 1
	--buff级别
	self.level = lv or 1
end


--------------增加暴击--------------
Impact_1800 = oo.class(Impact_attr, "Impact_1800")

function Impact_1800:__init(obj_id, ty, impact_id)
	Impact_attr.__init(self, obj_id, ty, impact_id)
end
function Impact_1800:get_effect()
	return self.param.per or 0, self.param.val or 0
end

function Impact_1800:on_add_effect(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.CRITICAL, per, val)
end

function Impact_1800:on_ineffectiveness(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.CRITICAL, -per, -val)
end

--技能效果
Impact_1801 = oo.class(Impact_1800, "Impact_1801")
function Impact_1801:__init(obj_id, lv)
	Impact_1800.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_1801)
	self.class_nm = "Impact_1801"

	--buff级别
	self.level = lv or 1
end

--道具效果
Impact_1805 = oo.class(Impact_1800, "Impact_1805")
function Impact_1805:__init(obj_id)
	Impact_1800.__init(self, obj_id, IMPACT_PROP_BUFF, IMPACT_OBJ_1805)
	self.class_nm = "Impact_1805"
end
function Impact_1805:is_clear()
	return false
end

--------------增加暴击效果--------------
Impact_1900 = oo.class(Impact_attr, "Impact_1900")

function Impact_1900:__init(obj_id, ty, impact_id)
	Impact_attr.__init(self, obj_id, ty, impact_id)
	self.sec_count = 1
end
function Impact_1900:get_effect()
	return self.param.per or 0, self.param.val or 0
end

function Impact_1900:on_add_effect(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.CRITICAL_EF, per, val)
end

function Impact_1900:on_ineffectiveness(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.CRITICAL_EF, -per, -val)
end

--法宝技能效果
Impact_4051 = oo.class(Impact_1900, "Impact_4051")
function Impact_4051:__init(obj_id, lv)
	Impact_1900.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_4051)
	self.class_nm = "Impact_4051"

	--buff级别
	self.level = lv or 1
end

--------------增加命中--------------
Impact_1810 = oo.class(Impact_attr, "Impact_1810")

function Impact_1810:__init(obj_id, ty, impact_id)
	Impact_attr.__init(self, obj_id, ty, impact_id)
end
function Impact_1810:get_effect()
	return self.param.per or 0, self.param.val or 0
end

function Impact_1810:on_add_effect(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.POINT, per, val)
end

function Impact_1810:on_ineffectiveness(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.POINT, -per, -val)
end

--技能效果
Impact_1811 = oo.class(Impact_1810, "Impact_1811")
function Impact_1811:__init(obj_id, lv)
	Impact_1810.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_1811)
	self.class_nm = "Impact_1811"

	--buff级别
	self.level = lv or 1
end

--技能效果
Impact_1812 = oo.class(Impact_1810, "Impact_1812")
function Impact_1812:__init(obj_id, lv)
	Impact_1810.__init(self, obj_id, IMPACT_TD_BUFF, IMPACT_OBJ_1812)
	self.class_nm = "Impact_1812"

	--buff级别
	self.level = lv or 1
end

--道具效果
Impact_1815 = oo.class(Impact_1810, "Impact_1815")
function Impact_1815:__init(obj_id)
	Impact_1810.__init(self, obj_id, IMPACT_PROP_BUFF, IMPACT_OBJ_1815)
	self.class_nm = "Impact_1815"
end
function Impact_1815:is_clear()
	return false
end

--宠物技能效果
Impact_1816 = oo.class(Impact_1810, "Impact_1816")
function Impact_1816:__init(obj_id, lv)
	Impact_1810.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_1816)
	self.class_nm = "Impact_1816"

	--buff级别
	self.level = lv or 1
end

--------------增加闪避--------------
Impact_1820 = oo.class(Impact_attr, "Impact_1820")

function Impact_1820:__init(obj_id, ty, impact_id)
	Impact_attr.__init(self, obj_id, ty, impact_id)
end
function Impact_1820:get_effect()
	return self.param.per or 0, self.param.val or 0
end


function Impact_1820:on_add_effect(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.DODGE, per, val)
end

function Impact_1820:on_ineffectiveness(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.DODGE, -per, -val)
end

--技能效果
Impact_1821 = oo.class(Impact_1820, "Impact_1821")
function Impact_1821:__init(obj_id, lv)
	Impact_1820.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_1821)
	self.class_nm = "Impact_1821"

	--buff级别
	self.level = lv or 1
end

--道具效果
Impact_1825 = oo.class(Impact_1820, "Impact_1825")
function Impact_1825:__init(obj_id)
	Impact_1820.__init(self, obj_id, IMPACT_PROP_BUFF, IMPACT_OBJ_1825)
	self.class_nm = "Impact_1825"
end
function Impact_1825:is_clear()
	return false
end

--宠物技能效果
Impact_1826 = oo.class(Impact_1820, "Impact_1826")
function Impact_1826:__init(obj_id, lv)
	Impact_1820.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_1826)
	self.class_nm = "Impact_1826"

	--buff级别
	self.level = lv or 1
end

--法宝技能效果
Impact_4063 = oo.class(Impact_1820, "Impact_4063")
function Impact_4063:__init(obj_id, lv)
	Impact_1820.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_4063)
	self.class_nm = "Impact_4063"
	self.sec_count = 1
	--buff级别
	self.level = lv or 1
end

------------加速----------------
Impact_1451 = oo.class(Impact_s, "Impact_1451")

function Impact_1451:__init(obj_id, lv)
	Impact_s.__init(self, obj_id)
	self.type = IMPACT_BUFF
	self.cmd_id = IMPACT_OBJ_1451
	self.sec_count = 5    --5秒轮询一次
	self.count = 1
	self.flag = 0  
	self.class_nm = "Impact_1451"

	--buff级别
	self.level = lv or 1
end

--返回速度
function Impact_1451:get_effect()
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj ~= nil then
		local sp = obj:get_speed()
		return math.max(1, math.floor(sp*(self.param.per or 0) ))
	end
	return 1
end
--param.per
function Impact_1451:on_effect(param)
	self.param = param
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj ~= nil then
		self:syn(param)
		local impact_con = obj:get_impact_con()
		impact_con:add_impact(self) 

		local _ = obj.on_update_instant and obj:on_update_instant(4,0)
	end
end
function Impact_1451:on_stop()
	--self:serialize()
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj ~= nil then
		local _ = obj.on_update_instant and obj:on_update_instant(4,0)
	end
end

function Impact_1451:get_param()
	return {(self.param.per or 0)*100}
end


-----------------增加冰攻点(100w秒杀)------------
Impact_1840 = oo.class(Impact_attr, "Impact_1840")

function Impact_1840:__init(obj_id, ty, impact_id)
	Impact_attr.__init(self, obj_id, ty, impact_id)
	self.sec_count = 5    --5秒轮询一次
end
function Impact_1840:get_effect()
	return self.param.per or 0, self.param.val or 0
end

function Impact_1840:on_add_effect(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.ICE_AK, per, val)
end

function Impact_1840:on_ineffectiveness(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.ICE_AK, -per, -val)
end

--技能效果
Impact_1841 = oo.class(Impact_1840, "Impact_1841")
function Impact_1841:__init(obj_id, lv)
	Impact_1840.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_1841)
	self.class_nm = "Impact_1841"

	--buff级别
	self.level = lv or 1
end

--TD效果
Impact_1842 = oo.class(Impact_1840, "Impact_1842")
function Impact_1842:__init(obj_id, lv)
	Impact_1840.__init(self, obj_id, IMPACT_TD_BUFF, IMPACT_OBJ_1842)
	self.class_nm = "Impact_1842"

	--buff级别
	self.level = lv or 1
end
function Impact_1842:is_clear()
	return false
end

--道具效果
Impact_1845 = oo.class(Impact_1840, "Impact_1845")
function Impact_1845:__init(obj_id)
	Impact_1840.__init(self, obj_id, IMPACT_PROP_BUFF, IMPACT_OBJ_1845)
	self.class_nm = "Impact_1845"
end
function Impact_1845:is_clear()
	return false
end

--道具效果 冰雪之刺
Impact_1846 = oo.class(Impact_1840, "Impact_1846")
function Impact_1846:__init(obj_id)
	Impact_1840.__init(self, obj_id, IMPACT_PROP_BUFF, IMPACT_OBJ_1846)
	self.class_nm = "Impact_1846"
end
function Impact_1846:is_clear()
	return false
end

--TD效果
Impact_1847 = oo.class(Impact_1840, "Impact_1847")
function Impact_1847:__init(obj_id, lv)
	Impact_1840.__init(self, obj_id, IMPACT_TD_BUFF, IMPACT_OBJ_1847)
	self.class_nm = "Impact_1847"

	--buff级别
	self.level = lv or 1
end
function Impact_1847:is_clear()
	return false
end

-----------------增加火攻--------------------
Impact_1850 = oo.class(Impact_attr, "Impact_1850")

function Impact_1850:__init(obj_id, ty, impact_id)
	Impact_attr.__init(self, obj_id, ty, impact_id)
	self.sec_count = 5    --5秒轮询一次
end
function Impact_1850:get_effect()
	return self.param.per or 0, self.param.val or 0
end

function Impact_1850:on_add_effect(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.FIRE_AK, per, val)
end

function Impact_1850:on_ineffectiveness(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.FIRE_AK, -per, -val)
end

--技能效果
Impact_1851 = oo.class(Impact_1850, "Impact_1851")
function Impact_1851:__init(obj_id, lv)
	Impact_1850.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_1851)
	self.class_nm = "Impact_1851"

	--buff级别
	self.level = lv or 1
end

--TD效果
Impact_1852 = oo.class(Impact_1850, "Impact_1852")
function Impact_1852:__init(obj_id, lv)
	Impact_1850.__init(self, obj_id, IMPACT_TD_BUFF, IMPACT_OBJ_1852)
	self.class_nm = "Impact_1852"

	--buff级别
	self.level = lv or 1
end
function Impact_1852:is_clear()
	return false
end

--TD效果
Impact_1853 = oo.class(Impact_1850, "Impact_1853")
function Impact_1853:__init(obj_id, lv)
	Impact_1850.__init(self, obj_id, IMPACT_TD_BUFF, IMPACT_OBJ_1853)
	self.class_nm = "Impact_1853"

	--buff级别
	self.level = lv or 1
end
function Impact_1853:is_clear()
	return false
end

--道具效果
Impact_1855 = oo.class(Impact_1850, "Impact_1855")
function Impact_1855:__init(obj_id)
	Impact_1850.__init(self, obj_id, IMPACT_PROP_BUFF, IMPACT_OBJ_1855)
	self.class_nm = "Impact_1855"
end
function Impact_1855:is_clear()
	return false
end

-----------------增加毒攻--------------------
Impact_1860 = oo.class(Impact_attr, "Impact_1860")

function Impact_1860:__init(obj_id, ty, impact_id)
	Impact_attr.__init(self, obj_id, ty, impact_id)
	self.sec_count = 5    --5秒轮询一次
end
function Impact_1860:get_effect()
	return self.param.per or 0, self.param.val or 0
end

function Impact_1860:on_add_effect(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.POISON_AK, per, val)
end

function Impact_1860:on_ineffectiveness(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.POISON_AK, -per, -val)
end

--技能效果
Impact_1861 = oo.class(Impact_1860, "Impact_1861")
function Impact_1861:__init(obj_id, lv)
	Impact_1860.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_1861)
	self.class_nm = "Impact_1861"

	--buff级别
	self.level = lv or 1
end

--TD效果
Impact_1862 = oo.class(Impact_1860, "Impact_1862")
function Impact_1862:__init(obj_id, lv)
	Impact_1860.__init(self, obj_id, IMPACT_TD_BUFF, IMPACT_OBJ_1862)
	self.class_nm = "Impact_1862"

	--buff级别
	self.level = lv or 1
end
function Impact_1862:is_clear()
	return false
end

--TD效果
Impact_1863 = oo.class(Impact_1860, "Impact_1863")
function Impact_1863:__init(obj_id, lv)
	Impact_1860.__init(self, obj_id, IMPACT_TD_BUFF, IMPACT_OBJ_1863)
	self.class_nm = "Impact_1863"

	--buff级别
	self.level = lv or 1
end
function Impact_1863:is_clear()
	return false
end

--道具效果
Impact_1865 = oo.class(Impact_1860, "Impact_1865")
function Impact_1865:__init(obj_id)
	Impact_1860.__init(self, obj_id, IMPACT_PROP_BUFF, IMPACT_OBJ_1865)
	self.class_nm = "Impact_1865"
end
function Impact_1865:is_clear()
	return false
end

-------------攻击力(物理和魔法)-------------
Impact_2000 = oo.class(Impact_attr, "Impact_2000")

function Impact_2000:__init(obj_id, ty, impact_id)
	Impact_attr.__init(self, obj_id, ty, impact_id)
end

function Impact_2000:get_effect()
	return self.param.per or 0, self.param.val or 0
end

function Impact_2000:on_add_effect(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.PHYSICAL_AK, per, val)
	impact_con:add_impact_effect(IMPACT_TYPE.MAGIC_AK, per, val)
end

function Impact_2000:on_ineffectiveness(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.PHYSICAL_AK, -per, -val)
	impact_con:add_impact_effect(IMPACT_TYPE.MAGIC_AK, -per, -val)
end

function Impact_2000:is_clear()
	return true
end
function Impact_2000:is_save()
	return false
end

--怪物释放1
Impact_2001 = oo.class(Impact_2000, "Impact_2001")
function Impact_2001:__init(obj_id, lv)
	Impact_2000.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_2001)
	self.class_nm = "Impact_2001"
	self.level = lv or 1
end

--怪物释放2
Impact_2002 = oo.class(Impact_2000, "Impact_2002")
function Impact_2002:__init(obj_id, lv)
	Impact_2000.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_2002)
	self.class_nm = "Impact_2002"
	self.level = lv or 1
end

--蚩尤战鼓
Impact_2003 = oo.class(Impact_2000, "Impact_2003")
function Impact_2003:__init(obj_id, lv)
	Impact_2000.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_2003)
	self.class_nm = "Impact_2003"
	self.level = lv or 1
end

--雷霆神力
Impact_2004 = oo.class(Impact_2000, "Impact_2004")
function Impact_2004:__init(obj_id, lv)
	Impact_2000.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_2004)
	self.class_nm = "Impact_2004"
	self.level = lv or 1
end

--风暴神力
Impact_2005 = oo.class(Impact_2000, "Impact_2005")
function Impact_2005:__init(obj_id, lv)
	Impact_2000.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_2005)
	self.class_nm = "Impact_2005"
	self.level = lv or 1
end

--轩辕战鼓
Impact_2006 = oo.class(Impact_2000, "Impact_2006")
function Impact_2006:__init(obj_id, lv)
	Impact_2000.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_2006)
	self.class_nm = "Impact_2006"
	self.level = lv or 1
end

--一般技能使用
Impact_2007 = oo.class(Impact_2000, "Impact_2007")
function Impact_2007:__init(obj_id, lv)
	Impact_2000.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_2007)
	self.class_nm = "Impact_2007"
	self.level = lv or 1
end

--副本使用
Impact_2008 = oo.class(Impact_2000, "Impact_2008")
function Impact_2008:__init(obj_id, lv)
	Impact_2000.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_2008)
	self.class_nm = "Impact_2008"
	self.level = lv or 1
end
function Impact_2008:is_clear()
	return false
end

--副本使用
Impact_2009 = oo.class(Impact_2000, "Impact_2009")
function Impact_2009:__init(obj_id, lv)
	Impact_2000.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_2009)
	self.class_nm = "Impact_2009"
	self.level = lv or 1
end
function Impact_2009:is_clear()
	return false
end

--副本使用
Impact_2010 = oo.class(Impact_2000, "Impact_2010")
function Impact_2010:__init(obj_id, lv)
	Impact_2000.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_2010)
	self.class_nm = "Impact_2010"
	self.level = lv or 1
end
function Impact_2010:is_clear()
	return false
end

--法宝技能
Impact_4055 = oo.class(Impact_2000, "Impact_4055")
function Impact_4055:__init(obj_id, lv)
	Impact_2000.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_4055)
	self.class_nm = "Impact_4055"
	self.level = lv or 1
	self.sec_count = 1
end

--法宝技能
Impact_4058 = oo.class(Impact_2000, "Impact_4058")
function Impact_4058:__init(obj_id, lv)
	Impact_2000.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_4058)
	self.class_nm = "Impact_4058"
	self.level = lv or 1
	self.sec_count = 1
end

--法宝技能
Impact_4061 = oo.class(Impact_2000, "Impact_4061")
function Impact_4061:__init(obj_id, lv)
	Impact_2000.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_4061)
	self.class_nm = "Impact_4061"
	self.level = lv or 1
	self.sec_count = 1
end

-------------防御力(物理和魔法)-------------
Impact_2020 = oo.class(Impact_attr, "Impact_2020")

function Impact_2020:__init(obj_id, ty, impact_id)
	Impact_attr.__init(self, obj_id, ty, impact_id)
end

function Impact_2020:get_effect()
	return self.param.per or 0, self.param.val or 0
end

function Impact_2020:on_add_effect(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.PHYSICAL_DE, per, val)
	impact_con:add_impact_effect(IMPACT_TYPE.MAGIC_DE, per, val)
end

function Impact_2020:on_ineffectiveness(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.PHYSICAL_DE, -per, -val)
	impact_con:add_impact_effect(IMPACT_TYPE.MAGIC_DE, -per, -val)
end

function Impact_2020:is_clear()
	return true
end
function Impact_2020:is_save()
	return false
end

--怪物释放1
Impact_2021 = oo.class(Impact_2020, "Impact_2021")
function Impact_2021:__init(obj_id, lv)
	Impact_2020.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_2021)
	self.class_nm = "Impact_2021"

	--buff级别
	self.level = lv or 1
end

--怪物释放2
Impact_2022 = oo.class(Impact_2020, "Impact_2022")
function Impact_2022:__init(obj_id, lv)
	Impact_2020.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_2022)
	self.class_nm = "Impact_2022"

	--buff级别
	self.level = lv or 1
end

--怪物释放3
Impact_2023 = oo.class(Impact_2020, "Impact_2023")
function Impact_2023:__init(obj_id, lv)
	Impact_2020.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_2023)
	self.class_nm = "Impact_2023"

	--buff级别
	self.level = lv or 1
end

--怪物释放4
Impact_2024 = oo.class(Impact_2020, "Impact_2024")
function Impact_2024:__init(obj_id, lv)
	Impact_2020.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_2024)
	self.class_nm = "Impact_2024"

	--buff级别
	self.level = lv or 1
end

--副本使用
Impact_2025 = oo.class(Impact_2020, "Impact_2025")
function Impact_2025:__init(obj_id, lv)
	Impact_2020.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_2025)
	self.class_nm = "Impact_2025"

	--buff级别
	self.level = lv or 1
end

--副本使用
Impact_2026 = oo.class(Impact_2020, "Impact_2026")
function Impact_2026:__init(obj_id, lv)
	Impact_2020.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_2026)
	self.class_nm = "Impact_2026"

	--buff级别
	self.level = lv or 1
end

--法宝技能
Impact_4056 = oo.class(Impact_2020, "Impact_4056")
function Impact_4056:__init(obj_id, lv)
	Impact_2020.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_4056)
	self.class_nm = "Impact_4056"
	self.sec_count = 1
	--buff级别
	self.level = lv or 1
end

--法宝技能
Impact_4057 = oo.class(Impact_2020, "Impact_4057")
function Impact_4057:__init(obj_id, lv)
	Impact_2020.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_4057)
	self.class_nm = "Impact_4057"
	self.sec_count = 1
	--buff级别
	self.level = lv or 1
end

-------------法宝一 5专用-------------
Impact_1930 = oo.class(Impact_attr, "Impact_1930")

function Impact_1930:__init(obj_id, ty, impact_id)
	Impact_attr.__init(self, obj_id, ty, impact_id)
	self.sec_count = 1
end

function Impact_1930:get_effect()
	return self.param.per or 0, self.param.val or 0
end

function Impact_1930:on_add_effect(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.PHYSICAL_AK, per, 0)
	impact_con:add_impact_effect(IMPACT_TYPE.MAGIC_AK, per, 0)
	impact_con:add_impact_effect(IMPACT_TYPE.ICE_AK, per, 0)
	impact_con:add_impact_effect(IMPACT_TYPE.FIRE_AK, per, 0)
	impact_con:add_impact_effect(IMPACT_TYPE.POISON_AK, per, 0)
	impact_con:add_impact_effect(IMPACT_TYPE.CRITICAL, per, 0)

	impact_con:add_impact_effect(IMPACT_TYPE.PHYSICAL_DE, val, 0)
	impact_con:add_impact_effect(IMPACT_TYPE.MAGIC_DE, val, 0)
end

function Impact_1930:on_ineffectiveness(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.PHYSICAL_AK, -per, 0)
	impact_con:add_impact_effect(IMPACT_TYPE.MAGIC_AK, -per, 0)
	impact_con:add_impact_effect(IMPACT_TYPE.ICE_AK, -per, 0)
	impact_con:add_impact_effect(IMPACT_TYPE.FIRE_AK, -per, 0)
	impact_con:add_impact_effect(IMPACT_TYPE.POISON_AK, -per, 0)
	impact_con:add_impact_effect(IMPACT_TYPE.CRITICAL, -per, 0)

	impact_con:add_impact_effect(IMPACT_TYPE.PHYSICAL_DE, -val, 0)
	impact_con:add_impact_effect(IMPACT_TYPE.MAGIC_DE, -val, 0)
end

function Impact_1930:get_param()
	return {math.abs(self.param.per or 0)*100, math.abs(self.param.val or 0)*100}
end

function Impact_1930:is_clear()
	return true
end
function Impact_1930:is_save()
	return false
end

--法宝技能
Impact_4059 = oo.class(Impact_1930, "Impact_4059")
function Impact_4059:__init(obj_id, lv)
	Impact_1930.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_4059)
	self.class_nm = "Impact_4059"
	self.sec_count = 1
	--buff级别
	self.level = lv or 1
end

-------------法宝三 5专用-------------
Impact_1940 = oo.class(Impact_attr, "Impact_1940")

function Impact_1940:__init(obj_id, ty, impact_id)
	Impact_attr.__init(self, obj_id, ty, impact_id)
	self.sec_count = 3
end

function Impact_1940:get_effect()
	return self.param.per or 0, self.param.val or 0
end

function Impact_1940:on_add_effect(impact_con)
	local per, val = self:get_effect()

	impact_con:add_impact_effect(IMPACT_TYPE.MAGIC_AK, per, 0)
end

function Impact_1940:on_ineffectiveness(impact_con)
	local per, val = self:get_effect()

	impact_con:add_impact_effect(IMPACT_TYPE.MAGIC_AK, -per, 0)
end

function Impact_1940:get_param()
	return {math.abs(self.param.per or 0)*100, math.abs(self.param.val or 0)*100}
end

function Impact_1940:is_clear()
	return true
end
function Impact_1940:is_save()
	return false
end

function Impact_1940:get_event_time()
	return self.sec_count + ev.time
end

function Impact_1940:on_process()
	--print("Impact_1940:on_process()")
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj ~= nil and obj:is_alive() then
		local mp = obj:get_mp()
		if mp < self.param.val then
			return -1
		end
		obj:add_mp(-self.param.val)
		
		if ev.time >= self.tm_start + self.count*self.sec_count or not obj:is_alive() then
			return -1
		end
	else
		return -1
	end
end
--法宝技能
Impact_4060 = oo.class(Impact_1940, "Impact_4060")
function Impact_4060:__init(obj_id, lv)
	Impact_1940.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_4060)
	self.class_nm = "Impact_4060"
	--buff级别
	self.level = lv or 1
end


--------------增加冰，毒，雷抗性------------
Impact_1950 = oo.class(Impact_attr, "Impact_1950")

function Impact_1950:__init(obj_id, ty, impact_id)
	Impact_attr.__init(self, obj_id, ty, impact_id)
	self.sec_count = 1
end
function Impact_1950:get_effect()
	return self.param.per or 0, self.param.val or 0
end

function Impact_1950:on_add_effect(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.ICE_DE, per, val)
	impact_con:add_impact_effect(IMPACT_TYPE.FIRE_DE, per, val)
	impact_con:add_impact_effect(IMPACT_TYPE.POISON_DE, per, val)
end

function Impact_1950:on_ineffectiveness(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.ICE_DE, -per, -val)
	impact_con:add_impact_effect(IMPACT_TYPE.FIRE_DE, -per, -val)
	impact_con:add_impact_effect(IMPACT_TYPE.POISON_DE, -per, -val)
end


--------------增加冰，毒，雷属性------------
Impact_1960 = oo.class(Impact_attr, "Impact_1960")

function Impact_1960:__init(obj_id, ty, impact_id)
	Impact_attr.__init(self, obj_id, ty, impact_id)
	self.sec_count = 1
end
function Impact_1960:get_effect()
	return self.param.per or 0, self.param.val or 0
end

function Impact_1960:on_add_effect(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.ICE_AK, per, val)
	impact_con:add_impact_effect(IMPACT_TYPE.FIRE_AK, per, val)
	impact_con:add_impact_effect(IMPACT_TYPE.POISON_AK, per, val)
end

function Impact_1960:on_ineffectiveness(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.ICE_AK, -per, -val)
	impact_con:add_impact_effect(IMPACT_TYPE.FIRE_AK, -per, -val)
	impact_con:add_impact_effect(IMPACT_TYPE.POISON_AK, -per, -val)
end


--------------增加根骨悟性体魄身法------------
Impact_1970 = oo.class(Impact_attr, "Impact_1970")

function Impact_1970:__init(obj_id, ty, impact_id)
	Impact_attr.__init(self, obj_id, ty, impact_id)
	self.sec_count = 1
end
function Impact_1970:get_effect()
	return self.param.per or 0, self.param.val or 0
end

function Impact_1970:on_add_effect(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.STRENGH, per, val)
	impact_con:add_impact_effect(IMPACT_TYPE.INTELLIGENCE, per, val)
	impact_con:add_impact_effect(IMPACT_TYPE.STEMINA, per, val)
	impact_con:add_impact_effect(IMPACT_TYPE.DEXTERITY, per, val)
end

function Impact_1970:on_ineffectiveness(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.STRENGH, -per, -val)
	impact_con:add_impact_effect(IMPACT_TYPE.INTELLIGENCE, -per, -val)
	impact_con:add_impact_effect(IMPACT_TYPE.STEMINA, -per, -val)
	impact_con:add_impact_effect(IMPACT_TYPE.DEXTERITY, -per, -val)
end

--------------神龙活动押镖buff------------
Impact_1991 = oo.class(Impact_attr, "Impact_1991")

function Impact_1991:__init(obj_id, level)
	Impact_attr.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_1991)
	self.sec_count = 1
	self.class_nm = "Impact_1991"
	self.level = level or 1
	self.flag = 0  
	self.flag_splice = 0       --0 不叠加 1叠加
end
function Impact_1991:get_effect()
	return self.param.per or 0, self.param.val or 0
end

function Impact_1991:on_add_effect(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.ESCORT, per, val)
end

function Impact_1991:on_ineffectiveness(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.ESCORT, -per, -val)
end
function Impact_1991:is_clear()
	return false
end

--效果叠加时间
function Impact_1991:splice(item)
	local obj = g_obj_mgr:get_obj(self.obj_id)
	local impact_con = obj and obj:get_impact_con()

	if item.level > self.level then        --高级别替换低级别
		self:ineffectiveness(impact_con)
		return item
	elseif item.level == self.level then        --高级别替换低级别
		item:ineffectiveness(impact_con)
		self.count = self.count + item.count
		return self
	else
		item:ineffectiveness(impact_con)
		return self
	end
	return item
end

function Impact_1991:get_param()
	return {math.abs(self.param.per or 0)*100, self.level}
end



------------破军暴走:根骨提升，速度提升--------------
Impact_3601 = oo.class(Impact_attr, "Impact_3601")

function Impact_3601:__init(obj_id, lv)
	Impact_attr.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_3601)
	self.sec_count = 1
	self.class_nm = "Impact_3601"
	self.level = lv or 1
end

function Impact_3601:get_effect()
	return self.param.per or 0, self.param.val or 0
end

function Impact_3601:on_add_effect(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.STRENGH, per, 0)
	local obj = g_obj_mgr:get_obj(self.obj_id)
	obj:add_speed(val)
	obj:on_dress_update(16)
end

function Impact_3601:on_ineffectiveness(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.STRENGH, -per, 0)
	local obj = g_obj_mgr:get_obj(self.obj_id)
	obj:add_speed(-val)
	obj:on_dress_update(16)
end

function Impact_3601:is_save()
	return false
end

------------天殇暴走:悟性提升，速度提升--------------
Impact_3602 = oo.class(Impact_attr, "Impact_3602")

function Impact_3602:__init(obj_id, lv)
	Impact_attr.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_3602)
	self.sec_count = 1
	self.class_nm = "Impact_3602"
	self.level = lv or 1
end

function Impact_3602:get_effect()
	return self.param.per or 0, self.param.val or 0
end

function Impact_3602:on_add_effect(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.INTELLIGENCE, per, 0)
	local obj = g_obj_mgr:get_obj(self.obj_id)
	obj:add_speed(val)
	obj:on_dress_update(16)
end

function Impact_3602:on_ineffectiveness(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.INTELLIGENCE, -per, 0)
	local obj = g_obj_mgr:get_obj(self.obj_id)
	obj:add_speed(-val)
	obj:on_dress_update(16)
end

function Impact_3602:is_save()
	return false
end

------------铃星暴走:悟性提升，速度提升--------------
Impact_3603 = oo.class(Impact_attr, "Impact_3603")

function Impact_3603:__init(obj_id, lv)
	Impact_attr.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_3603)
	self.sec_count = 1
	self.class_nm = "Impact_3603"
	self.level = lv or 1
end

function Impact_3603:get_effect()
	return self.param.per or 0, self.param.val or 0
end

function Impact_3603:on_add_effect(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.INTELLIGENCE, per, 0)
	local obj = g_obj_mgr:get_obj(self.obj_id)
	obj:add_speed(val)
	obj:on_dress_update(16)
end

function Impact_3603:on_ineffectiveness(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.INTELLIGENCE, -per, 0)
	local obj = g_obj_mgr:get_obj(self.obj_id)
	obj:add_speed(-val)
	obj:on_dress_update(16)
end

function Impact_3603:is_save()
	return false
end


--------------------神职buff
--天罚
Impact_3611 = oo.class(Impact_attr, "Impact_3611")

function Impact_3611:__init(obj_id, lv)
	Impact_attr.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_3611)
	self.sec_count = 1
	self.class_nm = "Impact_3611"
	self.level = lv or 1
end

function Impact_3611:get_effect()
	return self.param.per or 0, self.param.val or 0
end
function Impact_3611:get_param()
	return {math.abs(self.param.per or 0)*100, math.abs(self.param.val or 0)*100}
end

function Impact_3611:on_add_effect(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.ICE_DE, 	  -per, 0)
	impact_con:add_impact_effect(IMPACT_TYPE.FIRE_DE, 	  -per, 0)
	impact_con:add_impact_effect(IMPACT_TYPE.POISON_DE,	  -per, 0)
	impact_con:add_impact_effect(IMPACT_TYPE.PHYSICAL_DE, -val, 0)
	impact_con:add_impact_effect(IMPACT_TYPE.MAGIC_DE,	  -val, 0)
	impact_con:add_impact_effect(IMPACT_TYPE.STEMINA, 	  -val, 0)
	local obj = g_obj_mgr:get_obj(self.obj_id)
	obj:set_punishment_show(1)
end

function Impact_3611:on_ineffectiveness(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.ICE_DE, 	  per, 0)
	impact_con:add_impact_effect(IMPACT_TYPE.FIRE_DE, 	  per, 0)
	impact_con:add_impact_effect(IMPACT_TYPE.POISON_DE,	  per, 0)
	impact_con:add_impact_effect(IMPACT_TYPE.PHYSICAL_DE, val, 0)
	impact_con:add_impact_effect(IMPACT_TYPE.MAGIC_DE,	  val, 0)
	impact_con:add_impact_effect(IMPACT_TYPE.STEMINA, 	  val, 0)
	local obj = g_obj_mgr:get_obj(self.obj_id)
	obj:set_punishment_show(0)
end

function Impact_3611:on_effect(param)
	Impact_attr.on_effect(self, param)
	local obj = g_obj_mgr:get_obj(self.obj_id)
	obj:set_punishment_show(1)
end

function Impact_3611:on_stop()
	Impact_attr.on_stop(self)
	local obj = g_obj_mgr:get_obj(self.obj_id)
	obj:set_punishment_show(0)
end

function Impact_3611:is_clear()
	return false
end

--天赐
Impact_3612 = oo.class(Impact_attr, "Impact_3612")

function Impact_3612:__init(obj_id, lv)
	Impact_attr.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_3612)
	self.sec_count = 1
	self.class_nm = "Impact_3612"
	self.level = lv or 1
end

function Impact_3612:get_effect()
	return self.param.per or 0, self.param.val or 0
end
function Impact_3612:get_param()
	return {math.abs(self.param.per or 0)*100, math.abs(self.param.val or 0)*100}
end

function Impact_3612:on_add_effect(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.ICE_DE, 	  per, 0)
	impact_con:add_impact_effect(IMPACT_TYPE.FIRE_DE, 	  per, 0)
	impact_con:add_impact_effect(IMPACT_TYPE.POISON_DE,	  per, 0)
	impact_con:add_impact_effect(IMPACT_TYPE.PHYSICAL_DE, val, 0)
	impact_con:add_impact_effect(IMPACT_TYPE.MAGIC_DE,	  val, 0)
	impact_con:add_impact_effect(IMPACT_TYPE.STEMINA, 	  val, 0)
	local obj = g_obj_mgr:get_obj(self.obj_id)
end

function Impact_3612:on_ineffectiveness(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.ICE_DE, 	  -per, 0)
	impact_con:add_impact_effect(IMPACT_TYPE.FIRE_DE, 	  -per, 0)
	impact_con:add_impact_effect(IMPACT_TYPE.POISON_DE,	  -per, 0)
	impact_con:add_impact_effect(IMPACT_TYPE.PHYSICAL_DE, -val, 0)
	impact_con:add_impact_effect(IMPACT_TYPE.MAGIC_DE,	  -val, 0)
	impact_con:add_impact_effect(IMPACT_TYPE.STEMINA, 	  -val, 0)
	local obj = g_obj_mgr:get_obj(self.obj_id)
end

function Impact_3612:on_effect(param)
	Impact_attr.on_effect(self, param)
	local obj = g_obj_mgr:get_obj(self.obj_id)
	obj:set_punishment_show(2)
end

function Impact_3612:on_stop()
	Impact_attr.on_stop(self)
	local obj = g_obj_mgr:get_obj(self.obj_id)
	obj:set_punishment_show(0)
end

function Impact_3612:is_clear()
	return false
end

--禁言
Impact_3613 = oo.class(Impact_attr, "Impact_3613")

function Impact_3613:__init(obj_id, lv)
	Impact_attr.__init(self, obj_id, IMPACT_BUFF, IMPACT_OBJ_3613)
	self.sec_count = 1
	self.class_nm = "Impact_3613"
	self.level = lv or 1
end

function Impact_3613:get_effect()
	return 0, 0
end
function Impact_3613:get_param()
	return {0, 0}
end

function Impact_3613:on_add_effect(impact_con)

end

function Impact_3613:on_ineffectiveness(impact_con)
	
end

function Impact_3613:on_effect(param)
	Impact_attr.on_effect(self, param)
	local obj = g_obj_mgr:get_obj(self.obj_id)
	obj:set_punishment_show(3)
end

function Impact_3613:on_stop()
	Impact_attr.on_stop(self)
	local obj = g_obj_mgr:get_obj(self.obj_id)
	obj:set_punishment_show(0)
end

function Impact_3613:is_clear()
	return false
end