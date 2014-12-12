
local _random = crypto.random
local _impact_config = require("config.impact_config")

---------------------------  变形术以及变身卡或加多项属性的buff

--变形术（技能）  被变后不能使用战斗技能
Impact_1501 = oo.class(Impact_s, "Impact_1501")

function Impact_1501:__init(obj_id)
	Impact_s.__init(self, obj_id)
	self.type = IMPACT_CHANGE
	self.cmd_id = IMPACT_OBJ_1501
	self.sec_count = IMPACT_MIN_TIMER  
	self.count = 5
	self.flag = 0  
	self.class_nm = "Impact_1501"
end

function Impact_1501:on_effect(param)
	self.param = param
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj ~= nil then
		self:syn(param)

		local impact_con = obj:get_impact_con()
		impact_con:add_impact(self) 

		obj:set_change(true)
		if Obj_mgr.obj_type(self.obj_id) == OBJ_TYPE_HUMAN then
			obj:set_dress_id(self.param.metamorphosis)
		end
	end
end

function Impact_1501:set_my_dress()
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj ~= nil then
		obj:set_dress_id(self.param.metamorphosis)
	end
end

function Impact_1501:on_stop()
	local obj = g_obj_mgr:get_obj(self.obj_id)
	
	if Obj_mgr.obj_type(self.obj_id) == OBJ_TYPE_HUMAN then
		local impact_con = obj:get_impact_con()
		local impact_o_1501 = impact_con:find_impact(1501)
		local impact_o_1504 = impact_con:find_impact(1504)
		local impact_o_1505 = impact_con:find_impact(1505)
		if impact_o_1501 or impact_o_1504 or impact_o_1505 then
			local _ = impact_o_1501 and impact_o_1501:set_my_dress()
			local _ = impact_o_1504 and impact_o_1504:set_my_dress()
			local _ = impact_o_1505 and impact_o_1505:set_my_dress()			
			return
		end
		obj:set_change(false)
		local impact_o = impact_con:find_impact(1502)
		if impact_o then
			impact_o:set_my_dress()
		else
			obj:set_dress_id(nil)
		end
	end
end

function Impact_1501:on_resume()

	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj ~= nil then
		self:syn(self.param)

		obj:set_change(true)
		if Obj_mgr.obj_type(self.obj_id) == OBJ_TYPE_HUMAN and self.param and self.param.metamorphosis then
			obj:set_dress_id(self.param.metamorphosis)
		end
	end
end

--
Impact_1504 = oo.class(Impact_1501, "Impact_1504")
function Impact_1504:__init(obj_id)
	Impact_s.__init(self, obj_id)
	self.type = IMPACT_CHANGE
	self.cmd_id = IMPACT_OBJ_1504
	self.sec_count = IMPACT_MIN_TIMER  
	self.count = 5
	self.flag = 0  
	self.class_nm = "Impact_1504"
end
function Impact_1504:is_save()
	return false
end

--
Impact_1505 = oo.class(Impact_1501, "Impact_1505")
function Impact_1505:__init(obj_id)
	Impact_s.__init(self, obj_id)
	self.type = IMPACT_CHANGE
	self.cmd_id = IMPACT_OBJ_1505
	self.sec_count = IMPACT_MIN_TIMER  
	self.count = 5
	self.flag = 0  
	self.class_nm = "Impact_1505"
end
function Impact_1505:is_save()
	return false
end

-----------------------------------------------------------------------------

-- 道具变身
Impact_1502 = oo.class(Impact_s, "Impact_1502")

function Impact_1502:__init(obj_id)
	Impact_s.__init(self, obj_id)
	self.type = IMPACT_CHANGE
	self.cmd_id = IMPACT_OBJ_1502
	self.sec_count = IMPACT_MIN_TIMER  
	self.count = 60
	self.flag = 0
	self.class_nm = "Impact_1502"
end

function Impact_1502:on_effect(param)
	self.param = param
	self.param.val = _random(1, #_impact_config._t_c[self.param.sel][1] + 1)
	--print("=>Impact_1502:on_effect, val, random", self.param.val)
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj ~= nil then
		local impact_con = obj:get_impact_con()
		self:add_effect(impact_con, true)
		impact_con:add_impact(self) 
		self:syn(param)
		obj:set_dress_id(_impact_config._t_c[self.param.sel][1][self.param.val])
		local _ = obj.on_update_attribute and obj:on_update_attribute(1)
	end
end


function Impact_1502:on_stop()
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj ~= nil then
		local impact_con = obj:get_impact_con()
		self:ineffectiveness(impact_con)
		if not impact_con:find_impact(1501) and not impact_con:find_impact(1504) and not impact_con:find_impact(1505) then
			obj:set_dress_id(nil)
		end
		local _ = obj.on_update_attribute and obj:on_update_attribute(1)
	end
end

function Impact_1502:on_resume()

	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj ~= nil then
		local impact_con = obj:get_impact_con()
		self:add_effect(impact_con, false)
		if not impact_con:find_impact(1501) and not impact_con:find_impact(1504) and not impact_con:find_impact(1505) then
			obj:set_dress_id(_impact_config._t_c[self.param.sel][1][self.param.val])
		end
		self:syn(self.param)
	end
end

--效果叠加时间
function Impact_1502:splice(item)
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

function Impact_1502:get_param()
	return {f_get_string(_impact_config._t_c[self.param.sel][2][1]), f_get_string(_impact_config._t_c[self.param.sel][2][2])}
end

--加入生效的属性值
function Impact_1502:add_effect(impact_con, is_update)
	--print("===>Impact_1502:add_effect")
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj == nil then return end
	local hp_per
	local mp_per
	if is_update then
		hp_per = obj:get_hp() / obj:get_max_hp();
		mp_per = obj:get_mp() / obj:get_max_mp();
	end
	local attr_change = _impact_config._t_c[self.param.sel]
	--1.模型列表,2.属性名称,3.体魄,4.身法,5.根骨,6.悟性,7.物防,8.法防,9.闪避值,10.命中值,
	--11.暴击值,12.暴击效果值,13.冰攻,14.雷攻,15.毒攻,16.冰抗,17.雷炕,18.毒抗
	impact_con:add_impact_effect(IMPACT_TYPE.STEMINA, 	  attr_change[3][1],  attr_change[3][2])
	impact_con:add_impact_effect(IMPACT_TYPE.DEXTERITY,   attr_change[4][1],  attr_change[4][2])
	impact_con:add_impact_effect(IMPACT_TYPE.STRENGH, 	  attr_change[5][1],  attr_change[5][2])
	impact_con:add_impact_effect(IMPACT_TYPE.INTELLIGENCE,attr_change[6][1],  attr_change[6][2])
	impact_con:add_impact_effect(IMPACT_TYPE.PHYSICAL_DE, attr_change[7][1],  attr_change[7][2])
	impact_con:add_impact_effect(IMPACT_TYPE.MAGIC_DE,	  attr_change[8][1],  attr_change[8][2])
	impact_con:add_impact_effect(IMPACT_TYPE.DODGE, 	  attr_change[9][1],  attr_change[9][2])
	impact_con:add_impact_effect(IMPACT_TYPE.POINT,		  attr_change[10][1], attr_change[10][2])
	impact_con:add_impact_effect(IMPACT_TYPE.CRITICAL,	  attr_change[11][1], attr_change[11][2])
	impact_con:add_impact_effect(IMPACT_TYPE.CRITICAL_EF, attr_change[12][1], attr_change[12][2])
	impact_con:add_impact_effect(IMPACT_TYPE.ICE_AK, 	  attr_change[13][1], attr_change[13][2])
	impact_con:add_impact_effect(IMPACT_TYPE.FIRE_AK,	  attr_change[14][1], attr_change[14][2])
	impact_con:add_impact_effect(IMPACT_TYPE.POISON_AK,   attr_change[15][1], attr_change[15][2])
	impact_con:add_impact_effect(IMPACT_TYPE.ICE_DE, 	  attr_change[16][1], attr_change[16][2])
	impact_con:add_impact_effect(IMPACT_TYPE.FIRE_DE, 	  attr_change[17][1], attr_change[17][2])
	impact_con:add_impact_effect(IMPACT_TYPE.POISON_DE,	  attr_change[18][1], attr_change[18][2])
	
	if is_update and Obj_mgr.obj_type(self.obj_id) == OBJ_TYPE_HUMAN then
		obj:update_all_attr()
		obj:set_hp(math.floor(obj:get_max_hp() * hp_per))
		obj:set_mp(math.floor(obj:get_max_mp() * mp_per))
	end
end

--取消之前生效属性值
function Impact_1502:ineffectiveness(impact_con)
	--print("===>Impact_1502:ineffectiveness")
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj == nil then return end
	local hp_per = obj:get_hp() / obj:get_max_hp();
	local mp_per = obj:get_mp() / obj:get_max_mp();
	local attr_change = _impact_config._t_c[self.param.sel]
	--1.模型列表,2.属性名称,3.体魄,4.身法,5.根骨,6.悟性,7.物防,8.法防,9.闪避值,10.命中值,
	--11.暴击值,12.暴击效果值,13.冰攻,14.雷攻,15.毒攻,16.冰抗,17.雷炕,18.毒抗
	impact_con:add_impact_effect(IMPACT_TYPE.STEMINA, 	  -attr_change[3][1],  -attr_change[3][2])
	impact_con:add_impact_effect(IMPACT_TYPE.DEXTERITY,   -attr_change[4][1],  -attr_change[4][2])
	impact_con:add_impact_effect(IMPACT_TYPE.STRENGH, 	  -attr_change[5][1],  -attr_change[5][2])
	impact_con:add_impact_effect(IMPACT_TYPE.INTELLIGENCE,-attr_change[6][1],  -attr_change[6][2])
	impact_con:add_impact_effect(IMPACT_TYPE.PHYSICAL_DE, -attr_change[7][1],  -attr_change[7][2])
	impact_con:add_impact_effect(IMPACT_TYPE.MAGIC_DE,	  -attr_change[8][1],  -attr_change[8][2])
	impact_con:add_impact_effect(IMPACT_TYPE.DODGE, 	  -attr_change[9][1],  -attr_change[9][2])
	impact_con:add_impact_effect(IMPACT_TYPE.POINT,		  -attr_change[10][1], -attr_change[10][2])
	impact_con:add_impact_effect(IMPACT_TYPE.CRITICAL,	  -attr_change[11][1], -attr_change[11][2])
	impact_con:add_impact_effect(IMPACT_TYPE.CRITICAL_EF, -attr_change[12][1], -attr_change[12][2])
	impact_con:add_impact_effect(IMPACT_TYPE.ICE_AK, 	  -attr_change[13][1], -attr_change[13][2])
	impact_con:add_impact_effect(IMPACT_TYPE.FIRE_AK,	  -attr_change[14][1], -attr_change[14][2])
	impact_con:add_impact_effect(IMPACT_TYPE.POISON_AK,   -attr_change[15][1], -attr_change[15][2])
	impact_con:add_impact_effect(IMPACT_TYPE.ICE_DE, 	  -attr_change[16][1], -attr_change[16][2])
	impact_con:add_impact_effect(IMPACT_TYPE.FIRE_DE, 	  -attr_change[17][1], -attr_change[17][2])
	impact_con:add_impact_effect(IMPACT_TYPE.POISON_DE,	  -attr_change[18][1], -attr_change[18][2])

	if Obj_mgr.obj_type(self.obj_id) == OBJ_TYPE_HUMAN then
		obj:update_all_attr()
		obj:set_hp(math.floor(obj:get_max_hp() * hp_per))
		obj:set_mp(math.floor(obj:get_max_mp() * mp_per))
	end
end

function Impact_1502:set_my_dress()
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj ~= nil then
		obj:set_dress_id(_impact_config._t_c[self.param.sel][1][self.param.val])
	end
end



-----------------------------------------------------------------------------
-- 战场buff
Impact_1503 = oo.class(Impact_s, "Impact_1503")

function Impact_1503:__init(obj_id)
	Impact_s.__init(self, obj_id)
	self.type = IMPACT_CHANGE
	self.cmd_id = IMPACT_OBJ_1503
	self.sec_count = IMPACT_MIN_TIMER  
	self.count = 60
	self.flag = 0
	self.class_nm = "Impact_1503"
end

function Impact_1503:on_effect(param)
	self.param = param
	--print("=>Impact_1503:on_effect, val, random", self.param.val)
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj ~= nil then
		local impact_con = obj:get_impact_con()
		self:add_effect(impact_con, true)
		impact_con:add_impact(self) 
		self:syn(param)
		local _ = obj.on_update_attribute and obj:on_update_attribute(1)
	end
end


function Impact_1503:on_stop()
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj ~= nil then
		local impact_con = obj:get_impact_con()
		self:ineffectiveness(impact_con)
		local _ = obj.on_update_attribute and obj:on_update_attribute(1)
	end
end

function Impact_1503:on_resume()
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj ~= nil then
		local impact_con = obj:get_impact_con()
		self:add_effect(impact_con, false)
		self:syn(self.param)
	end
end

--效果叠加时间
function Impact_1503:splice(item)
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

function Impact_1503:get_param()
	return {f_get_string(_impact_config._t_w[self.param.sel][1][1]), f_get_string(_impact_config._t_w[self.param.sel][1][2])}
end

--加入生效的属性值
function Impact_1503:add_effect(impact_con, is_update)
	--print("===>Impact_1503:add_effect")
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj == nil then return end
	local hp_per
	local mp_per
	if is_update then
		hp_per = obj:get_hp() / obj:get_max_hp();
		mp_per = obj:get_mp() / obj:get_max_mp();
	end
	local attr_change = _impact_config._t_w[self.param.sel]
	--1.{名称,描述} 2.体魄{百分比,附加值}, 3.物攻, 4.法攻, 5.物防, 6.法防
	impact_con:add_impact_effect(IMPACT_TYPE.STEMINA, 	  attr_change[2][1],  attr_change[2][2])
	impact_con:add_impact_effect(IMPACT_TYPE.PHYSICAL_AK, attr_change[3][1],  attr_change[3][2])
	impact_con:add_impact_effect(IMPACT_TYPE.MAGIC_AK,	  attr_change[4][1],  attr_change[4][2])
	impact_con:add_impact_effect(IMPACT_TYPE.PHYSICAL_DE, attr_change[5][1],  attr_change[5][2])
	impact_con:add_impact_effect(IMPACT_TYPE.MAGIC_DE,	  attr_change[6][1],  attr_change[6][2])

	if is_update and Obj_mgr.obj_type(self.obj_id) == OBJ_TYPE_HUMAN then
		obj:update_all_attr()
		obj:set_hp(math.floor(obj:get_max_hp() * hp_per))
		obj:set_mp(math.floor(obj:get_max_mp() * mp_per))
	end
end

--取消之前生效属性值
function Impact_1503:ineffectiveness(impact_con)
	--print("===>Impact_1503:ineffectiveness")
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj == nil then return end
	local hp_per = obj:get_hp() / obj:get_max_hp();
	local mp_per = obj:get_mp() / obj:get_max_mp();
	local attr_change = _impact_config._t_w[self.param.sel]
	--1.{名称,描述} 2.体魄{百分比,附加值}, 3.物攻, 4.法攻, 5.物防, 6.法防
	impact_con:add_impact_effect(IMPACT_TYPE.STEMINA, 	  -attr_change[2][1],  -attr_change[2][2])
	impact_con:add_impact_effect(IMPACT_TYPE.PHYSICAL_AK, -attr_change[3][1],  -attr_change[3][2])
	impact_con:add_impact_effect(IMPACT_TYPE.MAGIC_AK,	  -attr_change[4][1],  -attr_change[4][2])
	impact_con:add_impact_effect(IMPACT_TYPE.PHYSICAL_DE, -attr_change[5][1],  -attr_change[5][2])
	impact_con:add_impact_effect(IMPACT_TYPE.MAGIC_DE,	  -attr_change[6][1],  -attr_change[6][2])

	if Obj_mgr.obj_type(self.obj_id) == OBJ_TYPE_HUMAN then
		obj:update_all_attr()
		obj:set_hp(math.floor(obj:get_max_hp() * hp_per))
		obj:set_mp(math.floor(obj:get_max_mp() * mp_per))
	end
end

function Impact_1503:is_save()
	return false
end
function Impact_1503:is_clear()
	return true
end

function Impact_1503:is_net_serialize()
	return false
end


----------------------------- 帮派领地buff
-- 蚩尤天赐战鼓
Impact_1506 = oo.class(Impact_1503, "Impact_1506")

function Impact_1506:__init(obj_id)
	Impact_1503.__init(self, obj_id)
	self.cmd_id = IMPACT_OBJ_1506
	self.class_nm = "Impact_1506"
end

-- 蚩尤天赐战鼓
Impact_1507 = oo.class(Impact_1503, "Impact_1507")

function Impact_1507:__init(obj_id)
	Impact_1503.__init(self, obj_id)
	self.cmd_id = IMPACT_OBJ_1507
	self.class_nm = "Impact_1507"
end

-- 新战场（采集资源）buff
Impact_1508 = oo.class(Impact_1503, "Impact_1508")

function Impact_1508:__init(obj_id)
	Impact_1503.__init(self, obj_id)
	self.cmd_id = IMPACT_OBJ_1508
	self.class_nm = "Impact_1508"
end
function Impact_1508:is_clear()
	return false
end