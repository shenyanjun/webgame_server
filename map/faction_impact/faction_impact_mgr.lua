--local debug_print = print
local debug_print = function() end

-- 帮派效果管理类
Faction_impact_mgr = oo.class(nil, "Faction_impact_mgr")

--obj_id 为所有对象id，包括角色，怪物
function Faction_impact_mgr:__init()

	self.faction_impact_con_l = {}
end

function Faction_impact_mgr:get_faction_impact_con(faction_id)
	return self.faction_impact_con_l[faction_id] and self.faction_impact_con_l[faction_id]:get_faction_impact_list()
end

function Faction_impact_mgr:add_faction_impact_container(obj)
	self.faction_impact_con_l[obj:get_id()] = obj
end

-- 删除某个帮派的所有帮派效果
function Faction_impact_mgr:del_faction_impact_container(faction_id)
	self.faction_impact_con_l[faction_id] = nil
end


-- 返回帮派效果对基本属性的加成
function Faction_impact_mgr:get_effect(player_id, type)
	--帮派效果只能加在人物身上
	if Obj_mgr.obj_type(player_id) ~= OBJ_TYPE_HUMAN then
		return 0, 0
	end
	local faction_o = g_faction_mgr:get_faction_by_cid(player_id)
	if faction_o then
		if self.faction_impact_con_l[faction_o:get_faction_id()] then
			return self.faction_impact_con_l[faction_o:get_faction_id()]:get_effect(type)
		end
	end
	return 0, 0
end

-- 对某个帮派加入某个效果(这个效果只改变属性值)
-- faction_id：帮派id, impact_id:效果id, lv:效果等级, per：属性百分比, val：属性附加值
function Faction_impact_mgr:add_attribute_impact(faction_id, impact_id, lv, per, val)

	if self.faction_impact_con_l[faction_id] == nil then
		self.faction_impact_con_l[faction_id] = Faction_impact_container(faction_id)
	end

	--print("===>add_attribute_impact",faction_id, impact_id, lv, per, val)
	local impact_o = _G[string.format("Impact_%d", impact_id)](faction_id, lv, per, val)
	self.faction_impact_con_l[faction_id]:add_impact(impact_o)
end


-- 对某个帮派删除某个效果
-- faction_id：帮派id, impact_id:效果id
-- 返回删除的impact的对象
function Faction_impact_mgr:del_attribute_impact(faction_id, impact_id)

	if self.faction_impact_con_l[faction_id] then
		return self.faction_impact_con_l[faction_id]:del_impact(impact_id)
	end
end

--设置帮派封闭
function Faction_impact_mgr:set_dissolve(faction_id, is_dissolve)
	if is_dissolve == 1 then
		is_dissolve = true
	else
		is_dissolve = false
	end
	if self.faction_impact_con_l[faction_id] then
		return self.faction_impact_con_l[faction_id]:set_dissolve(is_dissolve)
	end
end

----------网络通信--------------
--flag:nil显示所有，1只显示需要同步的
function Faction_impact_mgr:net_get_info(list, player_id, flag, impact_id)
	list = list or {}
	local faction_o = g_faction_mgr:get_faction_by_cid(player_id)
	if faction_o then
		if self.faction_impact_con_l[faction_o:get_faction_id()] then
			return self.faction_impact_con_l[faction_o:get_faction_id()]:net_get_info(list, player_id, flag, impact_id)
		end
	end
	return list
end

--同步帮派效果，只要是人物上线时用
function Faction_impact_mgr:syn_faction_impact(player_id)
	--print("===>syn_faction_impact:player_id",player_id)
	local faction_o = g_faction_mgr:get_faction_by_cid(player_id)
	if faction_o then
		local faction_impact_list = self:get_faction_impact_con(faction_o:get_faction_id())
		for k, impact_o in pairs(faction_impact_list or {}) do
			impact_o:syn(player_id)
		end
	end
end