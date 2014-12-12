
local _im = require("impact.impact_process")

--角色效果实现类
Impact_container = oo.class(nil, "Impact_container")

function Impact_container:__init(obj_id)
	self.obj_id = obj_id
	--click
	self.click_sec = 1
	self.click_count = nil
	--impact
	--self.impact_obj_l = Impact_base.format_list()
	self.impact_obj_l = _im.impact_format_list()

	self.extra = {}
	self.extra[IMPACT_TYPE.STRENGH] = {0, 0}				--根骨{百分比，固定值}
	self.extra[IMPACT_TYPE.INTELLIGENCE] = {0, 0}			--悟性
	self.extra[IMPACT_TYPE.STEMINA] = {0, 0}				--体魄
	self.extra[IMPACT_TYPE.DEXTERITY] = {0, 0}				--身法

	self.extra[IMPACT_TYPE.DODGE] = {0, 0}					--闪避率
	self.extra[IMPACT_TYPE.CRITICAL] = {0, 0}				--暴击率
	self.extra[IMPACT_TYPE.CRITICAL_EF] = {0, 0}			--暴击效果
	self.extra[IMPACT_TYPE.POINT] = {0, 0}					--命中率
		
	self.extra[IMPACT_TYPE.ICE_AK] = {0, 0}					--冰攻
	self.extra[IMPACT_TYPE.FIRE_AK] = {0, 0}				--雷攻
	self.extra[IMPACT_TYPE.POISON_AK] = {0, 0}				--毒攻

	self.extra[IMPACT_TYPE.ICE_DE] = {0, 0}					--冰防
	self.extra[IMPACT_TYPE.FIRE_DE] = {0, 0}				--雷防
	self.extra[IMPACT_TYPE.POISON_DE] = {0, 0}				--毒防
	
	self.extra[IMPACT_TYPE.SUB_PHYSICAL_DAMAGE] = {0, 0}	--物理减伤
	self.extra[IMPACT_TYPE.SUB_MAGIC_DAMAGE] = {0, 0}		--魔法减伤

	self.extra[IMPACT_TYPE.SUB_MP] = {0, 0}				--减魔
	self.extra[IMPACT_TYPE.ATTACK] = {0, 0}				--攻击
	self.extra[IMPACT_TYPE.DOCTOR] = {0, 0}				--增加治疗效果
	self.extra[IMPACT_TYPE.SUB_CD] = {0, 0}				--减CDs
	
	self.extra[IMPACT_TYPE.PHYSICAL_AK] = {0, 0}		--增加物理攻击
	self.extra[IMPACT_TYPE.MAGIC_AK] = {0, 0}			--增加魔法攻击
	self.extra[IMPACT_TYPE.PHYSICAL_DE] = {0, 0}		--增加物理防御
	self.extra[IMPACT_TYPE.MAGIC_DE] = {0, 0}			--增加魔法防御	
	self.extra[IMPACT_TYPE.SUB_DAMAGE] = {0, 0}			--减伤害（不分物攻/法攻） 只对怪有效
	self.extra[IMPACT_TYPE.HP] = {0, 0}					--生命值
	self.extra[IMPACT_TYPE.MP] = {0, 0}					--魔法值
	self.extra[IMPACT_TYPE.SUB_DAMAGE_H] = {0, 0}		--减伤害（不分物攻/法攻） 只对人有效
	self.extra[IMPACT_TYPE.ESCORT] = {0, 0}				--押镖加成
	self.extra[IMPACT_TYPE.JIN] = {0, 0}				--相克属性：金
	self.extra[IMPACT_TYPE.MU] = {0, 0}					--相克属性：木
	self.extra[IMPACT_TYPE.SHUI] = {0, 0}				--相克属性：水
	self.extra[IMPACT_TYPE.HUO] = {0, 0}				--相克属性：火
	self.extra[IMPACT_TYPE.TU] = {0, 0}					--相克属性：土
	self.extra[IMPACT_TYPE.YIN] = {0, 0}				--相克属性：阴
	self.extra[IMPACT_TYPE.YANG] = {0, 0}				--相克属性：阳
	self.extra[IMPACT_TYPE.LIGHT] = {0, 0}				--相克属性：光
	self.extra[IMPACT_TYPE.DARK] = {0, 0}				--相克属性：暗
	self.extra[IMPACT_TYPE.LIFE] = {0, 0}				--相克属性：生
	self.extra[IMPACT_TYPE.DEATH] = {0, 0}				--相克属性：死
end	

function Impact_container:add_impact(impact_o)
	if impact_o ~= nil then
		local ty = impact_o:get_type()
		local cmd_id = impact_o:get_cmd_id()

		local old_o = self.impact_obj_l[ty][cmd_id]
		if old_o == nil then
			self.impact_obj_l[ty][cmd_id] = impact_o
		else
			self.impact_obj_l[ty][cmd_id] = old_o:splice(impact_o)
		end

		g_impact_mgr:add_timer(self.obj_id, cmd_id, self.impact_obj_l[ty][cmd_id])
	end
end
function Impact_container:del_impact(impact_id)
	local ty = _im.impact_type(impact_id)
	if ty ~= nil and self.impact_obj_l[ty][impact_id] then
		local o = self.impact_obj_l[ty][impact_id]
		self.impact_obj_l[ty][impact_id] = nil
		g_impact_mgr:del_timer(self.obj_id, impact_id)
		o:stop()
		return o
	end
end
function Impact_container:find_impact(impact_id)
	local ty = _im.impact_type(impact_id)
	if ty ~= nil then
		return self.impact_obj_l[ty][impact_id]
	end
end
function Impact_container:blow_impact(impact_id)
	local impact_o = self:find_impact(impact_id)
	if impact_o ~= nil then
		impact_o:stop()
		return true
	end
	return false
end

function Impact_container:add_impact_effect(impact_effect_type, per, val)
	self.extra[impact_effect_type][1] = self.extra[impact_effect_type][1] + per
	self.extra[impact_effect_type][2] = self.extra[impact_effect_type][2] + val
end

function Impact_container:get_impact_effect(impact_effect_type)
	return self.extra[impact_effect_type][1], self.extra[impact_effect_type][2]
end

--玩家死亡，清理效果
function Impact_container:clear()
	if Obj_mgr.obj_type(self.obj_id) == OBJ_TYPE_MONSTER then
		self.impact_obj_l = _im.impact_format_list()
		self:out_line()
		return
	end
	for k,v in pairs(self.impact_obj_l) do
		for cmd,o in pairs(v) do
			if o:is_clear() then
				--o:clear()
				self.impact_obj_l[k][cmd] = nil
				g_impact_mgr:del_timer(self.obj_id, cmd)
				o:stop()
			end
		end
	end
end

--玩家下线，怪物死亡
function Impact_container:out_line()
	g_impact_mgr:clear_impact_list(self.obj_id)
end

--清除所有组队buff
function Impact_container:clear_team_buff()
	local team_buff_l = self.impact_obj_l[IMPACT_TEAM_BUFF]
	for cmd, o in pairs(team_buff_l) do
		g_impact_mgr:del_timer(self.obj_id, cmd)
		o:stop()
	end
	self.impact_obj_l[IMPACT_TEAM_BUFF] = {}
end

--[[function Impact_container:destroy()
	for k,v in pairs(self.impact_obj_l) do
		for cmd,o in pairs(v) do
			g_impact_mgr:del_timer(self.obj_id, cmd)
		end
	end
end]]

function Impact_container:serialize()
	if Obj_mgr.obj_type(self.obj_id) == OBJ_TYPE_HUMAN then
		local item_l = {}
		local c = 0
		for k,v in pairs(self.impact_obj_l) do
			for _,obj in pairs(v) do
				--[[if obj.serialize then
					obj:serialize()
				end]]
				if obj:is_save() then
					c = c + 1
					item_l[c] = obj:serialize_to_db()
				end
			end
		end

		--serialize
		local m_db = f_get_db()
		local info = {["impact_list"] = item_l}
		local query = string.format("{owner_id:%d}", self.obj_id)
		m_db:update("impact", query, Json.Encode(info), true)
	end
end

function Impact_container:unserialize()
	if Obj_mgr.obj_type(self.obj_id) == OBJ_TYPE_HUMAN then
		local m_db = f_get_db()
		local fields = Json.Encode({impact_list=1})
		local query = string.format("{owner_id:%d}", self.obj_id)
		local rows, e_code = m_db:select_one("impact", fields, query, nil, "{owner_id:1}")
		if rows ~= nil then
			for _,v in pairs(rows.impact_list or {}) do
				local item = v
				local impact_o = item.class_nm and _G[item.class_nm](self.obj_id)
				impact_o = impact_o and impact_o:clone(item)
				if impact_o ~= nil then
					local ty = impact_o:get_type()
					local cmd_id = impact_o:get_cmd_id()
					self.impact_obj_l[ty][cmd_id] = impact_o 
					g_impact_mgr:add_timer(self.obj_id, cmd_id, impact_o)
				end
			end
		end
	end
end

----------网络通信--------------
--flag:nil显示所有，1只显示需要同步的
function Impact_container:net_get_info(flag, impact_id)
	local list = {}
	if impact_id == nil then
		local count = 1
		for k,v in pairs(self.impact_obj_l) do
			for _,o in pairs(v) do
				local tm = o:get_last_time()
				if tm > 0 and (flag == nil or o:is_net_serialize())then
					list[count] = o:net_get_info()
					count = count + 1
				end
			end
		end
	else
		local impact_o = self:find_impact(impact_id)
		if impact_o ~= nil then	
			list[1] = impact_o:net_get_info()
		end
	end
	g_faction_impact_mgr:net_get_info(list, self.obj_id, flag, nil) --帮派效果，合并到tb[2]
	--print("===>net_get_show:impact list:", Json.Encode(list))
	return list
end

--click
--click回调，返回-1则移出click池
function Impact_container:on_timer(tm)
	--[[for tp,l in pairs(self.impact_obj_l) do
		for k,v in pairs(l) do
			if v:on_timer(tm) == -1 then
				--print("###########Impact_container:on_timer", v.cmd_id)
				if not self:del_impact(v:get_cmd_id()) then
					v:stop()
				end
				--v:clear()
			end
		end
	end]]
end
