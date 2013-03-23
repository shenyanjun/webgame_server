
require("config.impact_cmd")
_impact_config = require("config.impact_config")

local debug_print = print

--双倍经验(minu:分钟)
function f_prop_double_exp(obj, minu, per)
	if obj:get_type() == OBJ_TYPE_HUMAN then
		local impact_o = Impact_3001(obj:get_id(), per * 10)
		impact_o:set_count(minu)
		local param = {}
		param.per = per
		return impact_o:effect(param)
	end
	return 1
end

--无敌(sec:秒 必须大于5秒)
function f_prop_god(obj, sec)
	if obj:get_type() == OBJ_TYPE_HUMAN then
		local impact_o = Impact_1271(obj:get_id())
		impact_o:set_count(math.floor(sec))
		impact_o:effect(param)
		return 0
	end
	return 1
end

--沉默(sec:秒 必须大于5秒)
function f_prop_silence(obj, sec)
	if obj:get_type() == OBJ_TYPE_HUMAN then
		local impact_o = Impact_1291(obj:get_id())
		impact_o:set_count(math.floor(sec))
		impact_o:effect(param)
		return 0
	end
	return 1
end

--加100w冰攻(sec:秒 必须大于5秒, point:冰攻点数, per:冰攻百分比)
function f_prop_add_ice_ak(obj, sec, point, per)
	if obj:get_type() == OBJ_TYPE_HUMAN then
		local impact_o = Impact_1845(obj:get_id())
		impact_o:set_count(math.floor(sec/5))
		local param = {}
		param.val = point
		param.per = per
		impact_o:effect(param)
		return 0
	end
	return 1
end

--加冰攻--冰雪之刺(sec:秒 必须大于5秒, point:冰攻点数, per:冰攻百分比)
function f_prop_add_ice_ak_2(obj, sec, point, per)
	if obj:get_type() == OBJ_TYPE_HUMAN then
		local impact_o = Impact_1846(obj:get_id())
		impact_o:set_count(math.ceil(sec/impact_o.sec_count))
		local param = {}
		param.val = point
		param.per = per
		impact_o:effect(param)
		return 0
	end
	return 1
end

--加红，蓝buff(ty:1加红 2加蓝  total_val:总值  val:每次增加最大值)
function f_prop_human_resume(obj, ty, total_val, val)
	if obj:get_type() == OBJ_TYPE_HUMAN then
		local impact_o
		if ty == 1 then
			impact_o = Impact_3011(obj:get_id())
		elseif ty == 2 then
			impact_o = Impact_3021(obj:get_id())
		end

		local param = {}
		param.total_val = total_val
		param.cur_val = total_val
		param.val = val
		impact_o:effect(param)
		return 0
	end
	return 1
end

--pet加红，蓝buff(ty:1加红 2加蓝  total_val:总值  val:每次增加最大值)
function f_prop_pet_resume(obj, ty, total_val, val)
	if obj:get_type() == OBJ_TYPE_HUMAN then
		local impact_o
		if ty == 1 then
			impact_o = Impact_3015(obj:get_id())
		elseif ty == 2 then
			impact_o = Impact_3025(obj:get_id())
		end

		local param = {}
		param.total_val = total_val
		param.cur_val = total_val
		param.val = val
		impact_o:effect(param)
		return 0
	end
	return 1
end

-- 删除Impact
function f_del_impact(obj, impact_id)
	local impact_con = obj:get_impact_con()
	if impact_con then
		impact_con:del_impact(impact_id)
	end
end

-- 检查人物身上是否有某个Impact, 有返回true, 没有返回false
function f_check_impact(obj, impact_id)
	local impact_con = obj:get_impact_con()
	if impact_con then
		local impact_o = impact_con:find_impact(impact_id)
		return impact_o ~= nil
	end
	return false
end

-- 添加Impact_buff
function f_add_buff_impact(obj, impact_id, per, val, time)
	local impact_o = _G[string.format("Impact_%d", impact_id)](obj:get_id())
	if not impact_o then
		print("error: invalid buff id", impact_id)
		return 1
	end
	if impact_o:get_type() == IMPACT_BUFF then
		impact_o:set_count(time)
		impact_o:set_sec_count(1)
		local param = {}
		param.per = per
		param.val = val
		impact_o:effect(param)
		return 0
	elseif impact_o:get_type() == IMPACT_TIMER then
		impact_o:set_count(time)
		local param = {}
		impact_o:effect(param)
		return 0
	end
	print("error: invalid buff type", impact_o:get_type())
	return 1
end

--增加某个impact的时间
function f_add_buff_time(obj, impact_id, time)
	local impact_con = obj:get_impact_con()
	if impact_con then
		local impact_o = impact_con:find_impact(impact_id)
		if impact_o == nil then
			return 22635
		end
		impact_o:add_count(math.ceil(time / impact_o.sec_count))
		local new_pkt = {}
		new_pkt.list = impact_con:net_get_info()
		new_pkt.obj_id = obj:get_id()
		g_cltsock_mgr:send_client(obj:get_id(), CMD_MAP_GET_IMPACT_LIST_S, new_pkt)
		return 0
	end
	return 22636
end

-- TD生成buff接口
-- obj_id：人物ID，impact_entry_id：对应配置id
function f_td_add_impact(obj_id, impact_entry_id)
	--print("===>f_td_add_impact:obj_id", obj_id, "impact_entry_id:", impact_entry_id)
	if _impact_config._i_c[impact_entry_id] and Obj_mgr.obj_type(obj_id) == OBJ_TYPE_HUMAN then
		local impact_o = _G[string.format("Impact_%d", _impact_config._i_c[impact_entry_id][1])](obj_id)
		if impact_o:get_type() == IMPACT_TD_BUFF then
			impact_o:set_count(math.floor(_impact_config._i_c[impact_entry_id][2]/5))
		else
			impact_o:set_count(math.floor(_impact_config._i_c[impact_entry_id][2]))
		end
		local param = {}
		param.per = _impact_config._i_c[impact_entry_id][3]
		param.val = _impact_config._i_c[impact_entry_id][4]
		
		impact_o:effect(param)
		return 0
	end
	return 1
end

-- 单人井生成buff接口
-- obj_id：人物ID，buff_id：对应配置id
function f_td_ex_add_impact(obj_id, buff_id)
	--print("===>f_td_add_impact:obj_id", obj_id, "buff_id:", buff_id)
	if _impact_config._td_ex[buff_id] and Obj_mgr.obj_type(obj_id) == OBJ_TYPE_HUMAN then
		local buff_o = _impact_config._td_ex[buff_id]
		local impact_name = string.format("Impact_%d", buff_o[1])
		local impact_o = _G[impact_name](obj_id)
		impact_o:set_sec_count(buff_o[2])
		impact_o:set_count(buff_o[3])
		local param = {}
		param.per = _impact_config._td_ex[buff_id][4]
		param.val = _impact_config._td_ex[buff_id][5]
		param.dg_per = param.per
		impact_o:effect(param)
		return 0
	end
	return 1
end

--道具变身接口
function f_prop_change(obj, val)
	if obj:get_type() == OBJ_TYPE_HUMAN then
		local impact_o = Impact_1502(obj:get_id())
		local param = {}
		param.sel = val
		impact_o:set_count(_impact_config._t_t[param.sel])
		impact_o:effect(param)
		return 0
	end
	return 1
end

--元神变身接口
function f_soul_change(obj, val)
	local skill_con = obj:get_skill_con()
	local param = {}
	param.des_id = obj:get_id()
	local ret = skill_con:use(120, param)
	if ret ~= 0 then return ret end

	return f_prop_change(obj, val)
end

--战场加buff
function f_war_add_buff(obj, val, time)
	if obj:get_type() == OBJ_TYPE_HUMAN then
		local impact_o = Impact_1503(obj:get_id())
		local param = {}
		param.sel = val
		impact_o:set_count(time)
		impact_o:effect(param)
		return 0
	end
	return 1
end

--加多种属性的buff
function f_add_change_buff(buff_id, obj, val, time)
	if obj:get_type() == OBJ_TYPE_HUMAN then
		local impact_o = _G[string.format("Impact_%d", buff_id)](obj:get_id())
		local param = {}
		param.sel = val
		impact_o:set_count(time)
		impact_o:effect(param)
		return 0
	end
	return 1
end

--双击道具增加的buff
function f_prop_add_buff(buff_id, char_id, time, rate, val, level)
	if g_obj_mgr.obj_type(char_id) == OBJ_TYPE_HUMAN then
		local impact_o = _G[string.format("Impact_%d", buff_id)](char_id, level)
		if impact_o == nil then
			return 22636
		end
		if impact_o:get_type() == IMPACT_BUFF then
			local obj = g_obj_mgr:get_obj(char_id)
			local impact_con = obj:get_impact_con()
			local old_impact = impact_con:find_impact(buff_id)
			if old_impact ~= nil and old_impact:get_level() > level then
				return 22637
			end
			local param = {}
			param.sel = rate
			param.val = val
			if buff_id == 3506 then
				param.type = IMPACT_TYPE.LIGHT
			end
			impact_o:set_count(math.ceil(time / impact_o.sec_count))
			impact_o:effect(param)
			return 0
		end
	end
	return 22636
end
module("impact.impact_process", package.seeall)

--local impact_func = {}

get_list = function(char_id, obj_id)
	local obj = g_obj_mgr:get_obj(obj_id)
	if obj ~= nil then 
		local ty = Obj_mgr.obj_type(obj_id)
		if ty == OBJ_TYPE_HUMAN and --[[obj_id == char_id and]] obj:is_enter_scene() then
			local impact_con = obj:get_impact_con()

			local new_pkt = {}
			new_pkt.list = impact_con:net_get_info()
			new_pkt.obj_id = obj_id
			g_cltsock_mgr:send_client(char_id, CMD_MAP_GET_IMPACT_LIST_S, new_pkt)
		elseif ty == OBJ_TYPE_PET then 
			local pet_con = obj:get_pet_con()
			local pet_obj = pet_con:get_pet_obj(obj_id)
			if pet_obj ~= nil then
				local impact_con = pet_obj:get_impact_con()

				local new_pkt = {}
				new_pkt.list = impact_con:net_get_info()
				new_pkt.obj_id = obj_id
				g_cltsock_mgr:send_client(char_id, CMD_MAP_GET_IMPACT_LIST_S, new_pkt)
			end
		end
	end
end

--暂停
pause = function(char_id, obj_id, impact_id, flag)
	local obj = g_obj_mgr:get_obj(char_id)
	if obj ~= nil then 
		local ty = Obj_mgr.obj_type(obj_id)
		if ty == OBJ_TYPE_HUMAN and obj_id == char_id and obj:is_enter_scene() then
			local impact_con = obj:get_impact_con()
			local impact_o = impact_con:find_impact(impact_id)
			if impact_o ~= nil and impact_o:is_pause() then
				local new_pkt = {}
				new_pkt.result = 0
				new_pkt.flag = impact_o:pause(flag)
				new_pkt.obj_id = self.obj_id
				g_cltsock_mgr:send_client(char_id, CMD_MAP_IMPACT_PAUSE_S, new_pkt)
			end
		elseif ty == OBJ_TYPE_PET then 
		end
	end
end


--效果id对应类型
local _impact = {}
_impact[IMPACT_OBJ_1211] = IMPACT_STOP
_impact[IMPACT_OBJ_1212] = IMPACT_STOP
_impact[IMPACT_OBJ_1251] = IMPACT_LEECH
_impact[IMPACT_OBJ_1252] = IMPACT_LEECH
_impact[IMPACT_OBJ_1261] = IMPACT_LATENT
_impact[IMPACT_OBJ_1271] = IMPACT_GOD
_impact[IMPACT_OBJ_1281] = IMPACT_SNEER
_impact[IMPACT_OBJ_1291] = IMPACT_SILENCE
_impact[IMPACT_OBJ_1292] = IMPACT_SILENCE
_impact[IMPACT_OBJ_1501] = IMPACT_CHANGE
_impact[IMPACT_OBJ_1502] = IMPACT_CHANGE
_impact[IMPACT_OBJ_1503] = IMPACT_CHANGE
_impact[IMPACT_OBJ_1504] = IMPACT_CHANGE
_impact[IMPACT_OBJ_1505] = IMPACT_CHANGE
_impact[IMPACT_OBJ_1506] = IMPACT_CHANGE
_impact[IMPACT_OBJ_1507] = IMPACT_CHANGE
_impact[IMPACT_OBJ_1508] = IMPACT_CHANGE
_impact[IMPACT_OBJ_1509] = IMPACT_CHANGE
_impact[IMPACT_OBJ_1511] = IMPACT_BURNING
_impact[IMPACT_OBJ_1512] = IMPACT_BURNING
_impact[IMPACT_OBJ_1513] = IMPACT_BURNING
_impact[IMPACT_OBJ_1521] = IMPACT_REFLEX
_impact[IMPACT_OBJ_1522] = IMPACT_REFLEX

_impact[IMPACT_OBJ_1301] = IMPACT_DEBUFF
_impact[IMPACT_OBJ_1311] = IMPACT_DEBUFF
_impact[IMPACT_OBJ_1321] = IMPACT_DEBUFF

_impact[IMPACT_OBJ_1401] = IMPACT_BUFF
--_impact[IMPACT_OBJ_1402] = IMPACT_BUFF
_impact[IMPACT_OBJ_1405] = IMPACT_PROP_BUFF
_impact[IMPACT_OBJ_1407] = IMPACT_BUFF

_impact[IMPACT_OBJ_1411] = IMPACT_BUFF
--_impact[IMPACT_OBJ_1412] = IMPACT_BUFF
_impact[IMPACT_OBJ_1415] = IMPACT_PROP_BUFF
_impact[IMPACT_OBJ_1417] = IMPACT_BUFF
_impact[IMPACT_OBJ_1418] = IMPACT_BUFF

_impact[IMPACT_OBJ_1421] = IMPACT_BUFF
--_impact[IMPACT_OBJ_1422] = IMPACT_BUFF
_impact[IMPACT_OBJ_1425] = IMPACT_PROP_BUFF
_impact[IMPACT_OBJ_1427] = IMPACT_BUFF

_impact[IMPACT_OBJ_1431] = IMPACT_BUFF
--_impact[IMPACT_OBJ_1432] = IMPACT_BUFF
_impact[IMPACT_OBJ_1435] = IMPACT_PROP_BUFF
_impact[IMPACT_OBJ_1437] = IMPACT_BUFF

_impact[IMPACT_OBJ_1451] = IMPACT_BUFF

_impact[IMPACT_OBJ_1461] = IMPACT_BUFF
_impact[IMPACT_OBJ_1465] = IMPACT_PROP_BUFF
_impact[IMPACT_OBJ_1466] = IMPACT_BUFF

_impact[IMPACT_OBJ_1471] = IMPACT_BUFF
_impact[IMPACT_OBJ_1475] = IMPACT_PROP_BUFF

_impact[IMPACT_OBJ_1701] = IMPACT_BUFF
_impact[IMPACT_OBJ_1705] = IMPACT_PROP_BUFF
_impact[IMPACT_OBJ_1706] = IMPACT_BUFF

_impact[IMPACT_OBJ_1711] = IMPACT_BUFF
_impact[IMPACT_OBJ_1715] = IMPACT_PROP_BUFF
_impact[IMPACT_OBJ_1716] = IMPACT_BUFF

_impact[IMPACT_OBJ_1721] = IMPACT_BUFF
_impact[IMPACT_OBJ_1725] = IMPACT_PROP_BUFF
_impact[IMPACT_OBJ_1726] = IMPACT_BUFF

_impact[IMPACT_OBJ_1801] = IMPACT_BUFF
_impact[IMPACT_OBJ_1805] = IMPACT_PROP_BUFF

_impact[IMPACT_OBJ_1811] = IMPACT_BUFF
_impact[IMPACT_OBJ_1815] = IMPACT_PROP_BUFF
_impact[IMPACT_OBJ_1816] = IMPACT_BUFF

_impact[IMPACT_OBJ_1821] = IMPACT_BUFF
_impact[IMPACT_OBJ_1825] = IMPACT_PROP_BUFF
_impact[IMPACT_OBJ_1826] = IMPACT_BUFF

_impact[IMPACT_OBJ_1831] = IMPACT_BUFF
_impact[IMPACT_OBJ_1835] = IMPACT_PROP_BUFF

_impact[IMPACT_OBJ_1841] = IMPACT_BUFF
_impact[IMPACT_OBJ_1845] = IMPACT_PROP_BUFF
_impact[IMPACT_OBJ_1846] = IMPACT_PROP_BUFF

_impact[IMPACT_OBJ_1851] = IMPACT_BUFF
_impact[IMPACT_OBJ_1855] = IMPACT_PROP_BUFF

_impact[IMPACT_OBJ_1861] = IMPACT_BUFF
_impact[IMPACT_OBJ_1865] = IMPACT_PROP_BUFF

--神龙押镖活动buff
_impact[IMPACT_OBJ_1991] = IMPACT_BUFF
 
--prop
_impact[IMPACT_OBJ_3001] = IMPACT_PROP_EXPERIENCE
_impact[IMPACT_OBJ_3002] = IMPACT_PROP_EXPERIENCE
_impact[IMPACT_OBJ_3003] = IMPACT_PROP_EXPERIENCE
_impact[IMPACT_OBJ_3011] = IMPACT_PROP_RESUME
_impact[IMPACT_OBJ_3015] = IMPACT_PROP_RESUME
_impact[IMPACT_OBJ_3021] = IMPACT_PROP_RESUME
_impact[IMPACT_OBJ_3025] = IMPACT_PROP_RESUME

--faction buff
_impact[IMPACT_OBJ_5001] = IMPACT_FACTION_BUFF
_impact[IMPACT_OBJ_5002] = IMPACT_FACTION_BUFF
_impact[IMPACT_OBJ_5003] = IMPACT_FACTION_BUFF

--td buff
_impact[IMPACT_OBJ_1406] = IMPACT_TD_BUFF
_impact[IMPACT_OBJ_1416] = IMPACT_TD_BUFF
_impact[IMPACT_OBJ_1842] = IMPACT_TD_BUFF
_impact[IMPACT_OBJ_1852] = IMPACT_TD_BUFF
_impact[IMPACT_OBJ_1862] = IMPACT_TD_BUFF
_impact[IMPACT_OBJ_1702] = IMPACT_TD_BUFF
_impact[IMPACT_OBJ_1712] = IMPACT_TD_BUFF
_impact[IMPACT_OBJ_1722] = IMPACT_TD_BUFF
_impact[IMPACT_OBJ_1426] = IMPACT_TD_BUFF
_impact[IMPACT_OBJ_1436] = IMPACT_TD_BUFF

_impact[IMPACT_OBJ_1847] = IMPACT_TD_BUFF
_impact[IMPACT_OBJ_1707] = IMPACT_TD_BUFF
_impact[IMPACT_OBJ_1863] = IMPACT_TD_BUFF
_impact[IMPACT_OBJ_1723] = IMPACT_TD_BUFF
_impact[IMPACT_OBJ_1853] = IMPACT_TD_BUFF
_impact[IMPACT_OBJ_1713] = IMPACT_TD_BUFF
_impact[IMPACT_OBJ_1408] = IMPACT_TD_BUFF
_impact[IMPACT_OBJ_1419] = IMPACT_TD_BUFF
_impact[IMPACT_OBJ_1812] = IMPACT_TD_BUFF


--
_impact[IMPACT_OBJ_2001] = IMPACT_BUFF
_impact[IMPACT_OBJ_2002] = IMPACT_BUFF
_impact[IMPACT_OBJ_2003] = IMPACT_BUFF
_impact[IMPACT_OBJ_2004] = IMPACT_BUFF
_impact[IMPACT_OBJ_2005] = IMPACT_BUFF
_impact[IMPACT_OBJ_2006] = IMPACT_BUFF
_impact[IMPACT_OBJ_2007] = IMPACT_BUFF
_impact[IMPACT_OBJ_2008] = IMPACT_BUFF
_impact[IMPACT_OBJ_2009] = IMPACT_BUFF
_impact[IMPACT_OBJ_2010] = IMPACT_BUFF

_impact[IMPACT_OBJ_2021] = IMPACT_BUFF
_impact[IMPACT_OBJ_2022] = IMPACT_BUFF
_impact[IMPACT_OBJ_2023] = IMPACT_BUFF
_impact[IMPACT_OBJ_2024] = IMPACT_BUFF
_impact[IMPACT_OBJ_2025] = IMPACT_BUFF
_impact[IMPACT_OBJ_2026] = IMPACT_BUFF

--
_impact[IMPACT_OBJ_3501] = IMPACT_BUFF
_impact[IMPACT_OBJ_3502] = IMPACT_BUFF
_impact[IMPACT_OBJ_3503] = IMPACT_BUFF
_impact[IMPACT_OBJ_3504] = IMPACT_BUFF
_impact[IMPACT_OBJ_3505] = IMPACT_BUFF
_impact[IMPACT_OBJ_3506] = IMPACT_BUFF

--人物暴走
_impact[IMPACT_OBJ_3601] = IMPACT_BUFF
_impact[IMPACT_OBJ_3602] = IMPACT_BUFF
_impact[IMPACT_OBJ_3603] = IMPACT_BUFF

--神职惩罚buff
_impact[IMPACT_OBJ_3611] = IMPACT_BUFF
_impact[IMPACT_OBJ_3612] = IMPACT_BUFF
_impact[IMPACT_OBJ_3613] = IMPACT_BUFF

--timer
_impact[IMPACT_OBJ_4001] = IMPACT_TIMER
_impact[IMPACT_OBJ_4002] = IMPACT_TIMER

--法宝技能产生的效果
_impact[IMPACT_OBJ_4051] = IMPACT_BUFF
_impact[IMPACT_OBJ_4052] = IMPACT_BUFF
_impact[IMPACT_OBJ_4053] = IMPACT_BUFF
_impact[IMPACT_OBJ_4054] = IMPACT_BUFF
_impact[IMPACT_OBJ_4055] = IMPACT_BUFF
_impact[IMPACT_OBJ_4056] = IMPACT_BUFF
_impact[IMPACT_OBJ_4057] = IMPACT_BUFF
_impact[IMPACT_OBJ_4058] = IMPACT_BUFF
_impact[IMPACT_OBJ_4059] = IMPACT_BUFF
_impact[IMPACT_OBJ_4060] = IMPACT_BUFF
_impact[IMPACT_OBJ_4061] = IMPACT_BUFF
_impact[IMPACT_OBJ_4062] = IMPACT_BUFF
_impact[IMPACT_OBJ_4063] = IMPACT_BUFF
_impact[IMPACT_OBJ_4064] = IMPACT_BUFF
_impact[IMPACT_OBJ_4065] = IMPACT_BUFF

_impact[IMPACT_OBJ_4101] = IMPACT_TEAM_BUFF
_impact[IMPACT_OBJ_4102] = IMPACT_TEAM_BUFF


--接口函数
function impact_format_list()
	local list = {}
	--技能效果
	list[IMPACT_LEECH] = {}
	list[IMPACT_STOP] = {}
	list[IMPACT_LATENT] = {}
	list[IMPACT_SNEER] = {}
	list[IMPACT_GOD] = {}
	list[IMPACT_SILENCE] = {}
	list[IMPACT_CHANGE] = {}
	list[IMPACT_BURNING] = {}
	list[IMPACT_REFLEX] = {}
	list[IMPACT_BUFF] = {}
	list[IMPACT_DEBUFF] = {}
	--道具效果
	list[IMPACT_PROP_BUFF] = {}
	list[IMPACT_PROP_EXPERIENCE] = {}
	list[IMPACT_PROP_RESUME] = {}
	--帮派效果
	--list[IMPACT_FACTION_BUFF] = {} 帮派效果效果不挂到人物上
	--TD效果
	list[IMPACT_TD_BUFF] = {}
	--计时器
	list[IMPACT_TIMER] = {}
	--组队
	list[IMPACT_TEAM_BUFF] = {}
	return list
end

function impact_type(impact_id)
	return _impact[impact_id]
end


--接口函数
--[[function f_get_impact_func()
	return impact_func
end]]




