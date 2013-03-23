_im = require("impact.impact_process")

--角色效果实现类
Faction_impact_container = oo.class(nil, "Faction_impact_container")

function Faction_impact_container:__init(id)
	self.id = id	-- 对应帮派的id
	self.is_dissolve = false  -- 是否已封闭
	self.faction_impact_obj_l = {}
	self.faction_impact_obj_l[IMPACT_FACTION_BUFF] = {}
end

function Faction_impact_container:set_dissolve(is_dissolve)
	self.is_dissolve = is_dissolve
end

function Faction_impact_container:get_faction_impact_list()
	local faction_impact_list = self.faction_impact_obj_l[IMPACT_FACTION_BUFF]

	return faction_impact_list
end

function Faction_impact_container:get_id()
	return self.id
end

function Faction_impact_container:add_impact(impact_o)
	--print("===> add_impact:", impact_o:get_cmd_id(), "per:", impact_o.param.per, "val", impact_o.param.val)
	if impact_o ~= nil then
		local ty = impact_o:get_type()
		if ty ~= IMPACT_FACTION_BUFF then
			print("===>ERROR: Faction_impact_container:add_impact is not IMPACT_FACTION_BUFF")
		end
		local cmd_id = impact_o:get_cmd_id()

		local old_o = self.faction_impact_obj_l[ty][cmd_id]
		if old_o == nil then
			self.faction_impact_obj_l[ty][cmd_id] = impact_o
			-- 更新帮派效果
			self.faction_impact_obj_l[ty][cmd_id]:syn(nil)
		else
			--self.faction_impact_obj_l[ty][cmd_id] = old_o:splice(impact_o)
			if impact_o:get_level() > self.faction_impact_obj_l[ty][cmd_id]:get_level() then
				self.faction_impact_obj_l[ty][cmd_id] = impact_o
				-- 更新帮派效果
				self.faction_impact_obj_l[ty][cmd_id]:syn(nil)
			end
		end
		
	end
end

function Faction_impact_container:del_impact(impact_id)
	local ty = _im.impact_type(impact_id)
	if ty ~= nil then
		local o = self.faction_impact_obj_l[ty][impact_id]
		self.faction_impact_obj_l[ty][impact_id] = nil
		o:stop()
		return o
	end
end

function Faction_impact_container:find_impact(impact_id)
	local ty = _im.impact_type(impact_id)
	if ty ~= nil then
		return self.faction_impact_obj_l[ty][impact_id]
	end
end

function Faction_impact_container:blow_impact(impact_id)
	local impact_o = self:find_impact(impact_id)
	if impact_o ~= nil then
		impact_o:stop()
		return true
	end
	return false
end



----------网络通信--------------
--flag:nil显示所有，1只显示需要同步的
function Faction_impact_container:net_get_info(list, player_id, flag, impact_id)
	if self.is_dissolve then
		return list
	end
	local count = #list + 1
	if impact_id == nil then
		for k,v in pairs(self.faction_impact_obj_l) do
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
			list[count] = impact_o:net_get_info()
		end
	end

	return list
end

--[[
--click
--click回调，返回-1则移出click池
function Faction_impact_container:on_timer(tm)
	for tp,l in pairs(self.faction_impact_obj_l) do
		for k,v in pairs(l) do
			if v:on_timer(tm) == -1 then
				--print("###########Faction_impact_container:on_timer", v.cmd_id)
				self:del_impact(v:get_cmd_id())
				v:stop()
				v:clear()
			end
		end
	end
end
]]


-------------------------------------------------------------
function Faction_impact_container:get_effect(type)
	if self.is_dissolve then
		return 0, 0
	end

	if type == FACTION_IMPACT_TYPE.STRENGH then	--根骨
		return self:get_strengh_effect()

	elseif type == FACTION_IMPACT_TYPE.INTELLIGENCE then
		return self:get_intelligence_effect()

	elseif type == FACTION_IMPACT_TYPE.PHYSICAL_AK then
		return self:get_physical_ak_effect()

	elseif type == FACTION_IMPACT_TYPE.MAGIC_AK then
		return self:get_magic_ak_effect()

	elseif type == FACTION_IMPACT_TYPE.PHYSICAL_DE then
		return self:get_physical_de_effect()

	elseif type == FACTION_IMPACT_TYPE.MAGIC_DE then
		return self:get_magic_de_effect()

	elseif type == FACTION_IMPACT_TYPE.KILL_MONSTER then
		return self:get_kill_monster_effect()
	end

	return 0, 0
end

function Faction_impact_container:get_impact_list_effect(impact_id_list)
	--获取对根骨产生影响的帮派效果
	local effect_per, effect_val = 0, 0
	local per, val = 0, 0
	
	for _, v in pairs(impact_id_list) do
		local impact_o = self:find_impact(v)
		if impact_o ~= nil then
			per, val = impact_o:get_effect()
			effect_per = effect_per + per
			effect_val = effect_val + val
		end
	end

	return effect_per, effect_val
end

--获取对根骨产生影响的帮派效果
function Faction_impact_container:get_strengh_effect()
	local t = {}
	return self:get_impact_list_effect(t)
end

--获取对悟性产生影响的帮派效果
function Faction_impact_container:get_intelligence_effect()
	local t = {}
	return self:get_impact_list_effect(t)
end

--获取对物理攻击产生影响的帮派效果
function Faction_impact_container:get_physical_ak_effect()
	local t = {IMPACT_OBJ_5001}
	return self:get_impact_list_effect(t)
end

--获取对魔法攻击产生影响的帮派效果
function Faction_impact_container:get_magic_ak_effect()
	local t = {IMPACT_OBJ_5001}
	return self:get_impact_list_effect(t)
end

--获取对物理防御产生影响的帮派效果
function Faction_impact_container:get_physical_de_effect()
	local t = {IMPACT_OBJ_5002}
	return self:get_impact_list_effect(t)
end

--获取对魔法防御产生影响的帮派效果
function Faction_impact_container:get_magic_de_effect()
	local t = {IMPACT_OBJ_5002}
	return self:get_impact_list_effect(t)
end

--杀怪经验加成
function Faction_impact_container:get_kill_monster_effect()
	local t = {IMPACT_OBJ_5003}
	return self:get_impact_list_effect(t)
end