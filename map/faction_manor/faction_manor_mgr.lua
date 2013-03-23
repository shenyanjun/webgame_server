local _manor_config = require("config.faction_manor_config")

-- 帮派庄园管理类

Faction_manor_mgr = oo.class(nil, "Faction_manor_mgr")

function Faction_manor_mgr:__init()
	self.faction_manor_l = {}			-- 帮派庄园的对象列表

end

function Faction_manor_mgr:get_faction_manor_l()
	return self.faction_manor_l
end

function Faction_manor_mgr:get_manor(f_id)
	return self.faction_manor_l[f_id]
end

function Faction_manor_mgr:get_manor_by_cid(char_id)
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	local f_id = faction and faction:get_faction_id()
	return self:get_manor(f_id)
end

function Faction_manor_mgr:get_faction_other_manor(f_id)
	local manor_array = {}
	for k, v in pairs(self.faction_manor_l) do
		table.insert(manor_array, k)
	end

	local manor_size = #manor_array
	if manor_size <= 1 then
		if manor_size == 1 and manor_array[1] ~= f_id then
			return manor_array[1]
		end
		return nil
	end
	
	local oth_manor = f_id
	local r = 1
	for i = 1, 20 do 
		r = crypto.random(1, manor_size+1)
		oth_manor = manor_array[r]
		if oth_manor ~= f_id then
			break
		end
	end
	if oth_manor == f_id then
		oth_manor = manor_array[r % manor_size +1 ]
	end
	return oth_manor
end


-- type:nil所有，1：庄园升级，2：繁荣值变化，3：灵气值，4：巧匠升级，5：铁匠升级
function Faction_manor_mgr:get_syn_info(f_id, type)
	local info = {}
	if f_id == nil then
		for k, v in pairs(self.faction_manor_l) do
			table.insert(info, v:get_info(type))
		end
	elseif self.faction_manor_l[f_id] then
		info[1] = self.faction_manor_l[f_id]:get_info(type)
	end
	return info		
end

function Faction_manor_mgr:get_syn_info_by_cid(char_id, type)
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	local f_id = faction and faction:get_faction_id()
	local pkt = f_id and self.faction_manor_l[f_id] and self.faction_manor_l[f_id]:get_info(type)
	if pkt ~= nil then
		local cost_l = faction:get_maintenance()
		local cost = 0
		for k, v in ipairs(cost_l) do
			cost = cost + v
		end
		pkt.cost = cost
		pkt.next_rob = self:get_next_rob()
	end
	return pkt
end

--同步到公共服
--type:0增加庄园，1：庄园升级，2：繁荣值变化，3：灵气值，4：巧匠升级，5：铁匠升级
function Faction_manor_mgr:syn_to_common(f_id, type, val)
	if f_id == nil then
		return
	end
	local pkt = {}
	pkt.f_id = f_id
	pkt.type = type
	if type == 0 then
		if self.faction_manor_l[f_id] ~= nil then
			return
		end
	elseif type == 1 then

	elseif type == 2 then
		pkt.flourish = val
	elseif type == 3 then
		pkt.power = val
	elseif type == 8 then
		pkt.building = val
	end
	g_svsock_mgr:send_server_ex(COMMON_ID, 0, CMD_M2C_FACTION_MANOR_SYN_C, pkt)
end

function Faction_manor_mgr:set_syn_info(info)
	for k, v in ipairs(info) do
		if self.faction_manor_l[v.id] == nil then
			self.faction_manor_l[v.id] = Faction_manor(v.id)
		end
		self.faction_manor_l[v.id]:set_info(v)
	end
end

--增加某帮派的庄园
function Faction_manor_mgr:add_manor(f_id)
	if self.faction_manor_l[f_id] ~= nil then
		return
	end
	local faction = g_faction_mgr:get_faction_by_fid(f_id)
	if faction:get_level() < 3 then
		return
	end
	self:syn_to_common(f_id, 0, nil)
end

--是否有庄园
function Faction_manor_mgr:had_manor(f_id)
	return self.faction_manor_l[f_id] ~= nil
end

function Faction_manor_mgr:had_manor_by_cid(char_id)
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	return faction and self.faction_manor_l[faction:get_faction_id()] ~= nil
end

--庄园升级
function Faction_manor_mgr:can_level_up_by_cid(char_id)
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	local f_id = faction and faction:get_faction_id()
	local manor = f_id and self.faction_manor_l[f_id]
	if manor == nil then return 22240 end
	
	return manor:can_level_up(char_id)
end

function Faction_manor_mgr:get_level(f_id)
	local manor = self.faction_manor_l[f_id]
	return manor and manor.level or 0
end

--增加繁荣值
function Faction_manor_mgr:add_flourish(f_id, val)
	local manor = self.faction_manor_l[f_id]
	if manor == nil then return end
	
	self:syn_to_common(f_id, 2, val)
end

function Faction_manor_mgr:get_flourish(f_id)
	local manor = self.faction_manor_l[f_id]
	return manor and manor.flourish
end

function Faction_manor_mgr:get_flourish_by_cid(char_id)
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	return faction and self:get_flourish(faction:get_faction_id())
end

--增加灵气值
function Faction_manor_mgr:add_power(f_id, val)
	local manor = self.faction_manor_l[f_id]
	if manor == nil then return end
	
	self:syn_to_common(f_id, 3, val)
end

function Faction_manor_mgr:get_power(f_id)
	local manor = self.faction_manor_l[f_id]
	return manor and manor.power
end

function Faction_manor_mgr:get_power_by_cid(char_id)
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	return faction and self:get_power(faction:get_faction_id())
end

--能否升级巧匠
function Faction_manor_mgr:can_craftsman_up_by_cid(char_id)
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	local f_id = faction and faction:get_faction_id()
	local manor = f_id and self.faction_manor_l[f_id]
	if manor == nil then return 22240 end
	
	return manor:can_craftsman_up(char_id)
end



function Faction_manor_mgr:get_craftsman_level(f_id)
	local manor = self.faction_manor_l[f_id]
	return manor and manor.craftsman
end

function Faction_manor_mgr:get_craftsman_level_by_cid(char_id)
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	return faction and self:get_craftsman_level(faction:get_faction_id())
end

--升级铁匠
function Faction_manor_mgr:can_blacksmith_up_by_cid(char_id)
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	local f_id = faction and faction:get_faction_id()
	local manor = f_id and self.faction_manor_l[f_id]
	if manor == nil then return 22240 end
	
	return manor:can_blacksmith_up(char_id)
end

function Faction_manor_mgr:get_blacksmith_level(f_id)
	local manor = self.faction_manor_l[f_id]
	return manor and manor.blacksmith
end

function Faction_manor_mgr:get_blacksmith_level_by_cid(char_id)
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	return faction and self:get_blacksmith_level(faction:get_faction_id())
end

--升级秘境
function Faction_manor_mgr:can_realm_up_by_cid(char_id)
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	local f_id = faction and faction:get_faction_id()
	local manor = f_id and self.faction_manor_l[f_id]
	if manor == nil then return 22240 end
	
	return manor:can_realm_up(char_id)
end

function Faction_manor_mgr:get_realm_level(f_id)
	local manor = self.faction_manor_l[f_id]
	return manor and manor.realm
end

function Faction_manor_mgr:get_blacksmith_level_by_cid(char_id)
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	return faction and self:get_realm_level(faction:get_faction_id())
end

--返回相应帮派巧匠配方列表
function Faction_manor_mgr:get_formula_list(f_id)
	local manor = self.faction_manor_l[f_id]
	return manor and manor.formula
end

--返回自己帮派巧匠配方列表
function Faction_manor_mgr:get_formula_list_by_cid(char_id)
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	return faction and self:get_formula_list(faction:get_faction_id())
end

function Faction_manor_mgr:can_study_formula(f_id, char_id)
	local manor = f_id and self.faction_manor_l[f_id]
	if manor == nil then return 22240 end
	
	return manor:can_study_formula(char_id)
end

function Faction_manor_mgr:can_study_formula_by_cid(char_id)
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	local f_id = faction and faction:get_faction_id()
	
	return self:can_study_formula(f_id, char_id)
end

--检查某帮派是否研究了该配方
function Faction_manor_mgr:check_formula(f_id, formula_id)
	local manor = self.faction_manor_l[f_id]
	return manor and manor:check_formula(formula_id)
end

--检查自己帮派是否研究了该配方
function Faction_manor_mgr:check_formula_by_cid(char_id, formula_id)
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	return faction and self:check_formula(faction:get_faction_id(), formula_id)
end

--设置标识
function Faction_manor_mgr:set_reflash_flag(f_id, flag)
	local manor = self.faction_manor_l[f_id]
	return manor and manor:set_reflash_flag(flag)
end

--设置刷新配方标识
function Faction_manor_mgr:set_reflash_flag_by_cid(char_id, flag)
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	return faction and self:set_reflash_flag(faction:get_faction_id(), flag)
end

--获取标识
function Faction_manor_mgr:get_reflash_flag(f_id)
	local manor = self.faction_manor_l[f_id]
	return manor and manor:get_reflash_flag()
end

--获取刷新配方标识
function Faction_manor_mgr:get_reflash_flag_by_cid(char_id)
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	return faction and self:get_reflash_flag(faction:get_faction_id())
end


--判断能否刷强盗
function Faction_manor_mgr:can_rob(f_id)
	local manor = self.faction_manor_l[f_id]
	if manor == nil then return false end
	return manor:can_rob()
end

function Faction_manor_mgr:get_next_rob()
	local today = os.date("*t")
	today.hour = 0
	today.min = 0
	today.sec = 0
	local today_time = os.time(today)

	local config = g_all_scene_config[2901000]
	local freq_list = config and config.day_list and config.day_list[today.wday]
	
	if not freq_list or not freq_list.open_time then
		return {0, 0}
	end

	for _, time_span in ipairs(freq_list.open_time) do
		local hour = time_span.hour or 0
		local minu = time_span.minu or 0
		local start_time = today_time + hour * 3600 + minu * 60
		if start_time > ev.time then
			return {hour, minu}
		end
	end

	return {0, 0}
end

--
function Faction_manor_mgr:sub_building_time(obj_id, pkt)
	local faction = g_faction_mgr:get_faction_by_cid(obj_id)
	local f_id = faction and faction:get_faction_id()
	if not f_id then
		return 200101
	end
	local manor = self.faction_manor_l[f_id]
	if manor == nil then
		return 22240
	end

	local old_time = 0
	local need_time = 0
	if pkt.building_id == 1 then
		if manor.level_time <= 0 then return 22255 end
		old_time = manor.level_time
		need_time = _manor_config._manor_level[manor.level][8]
	elseif pkt.building_id == 2 then
		if manor.craftsman_time <= 0 then return 22255 end
		old_time = manor.craftsman_time
		need_time = _manor_config._craftsman_level[manor.craftsman][8]
	elseif pkt.building_id == 3 then
		if manor.realm_time <= 0 then return 22255 end
		old_time = manor.realm_time
		need_time = _manor_config._realm_level[manor.realm][6]
	end

	local item_list = pkt.item_list
	local player = g_obj_mgr:get_obj(obj_id)

	if player and item_list then
		local pack_con = player:get_pack_con()
		local e_code, sys_pack = pack_con:get_bag(SYSTEM_BAG)
		local time = 0
	
		local num = 1
		local tmp_list = {}
		for k , v in pairs(item_list) do
			if v ~= 0 then
				if pack_con:check_item_lock_by_bag_slot(SYSTEM_BAG,v) then
					return -1
				end
				local slot = sys_pack:get_item_by_slot(v)
				local item = slot and slot.item
				if not item then
					return 43001
				end
				if item:get_m_class() ~= 1 or item:get_s_class() ~= 35 then
					return 43064
				end
				time = time + item.proto.value.subtime
				tmp_list[num] = {SYSTEM_BAG,v,1}
				num = num +1
			end
		end

		time = time * 3600
		pack_con:del_item_by_bags_slots(tmp_list, {['type']=ITEM_SOURCE.FACTION_SUBTIME}, 1)

		self:syn_to_common(f_id, 8, {pkt.building_id, time})
		return 0, math.max(0, (old_time - time + need_time - ev.time))
	end
	return -1
end

--取维护相关信息
function Faction_manor_mgr:get_maintenance(f_id)
	local manor = self.faction_manor_l[f_id]
	return manor and manor:get_maintenance() or {0, 0, 0}
end

function Faction_manor_mgr:can_change_rob_state(char_id)
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	local f_id = faction and faction:get_faction_id()
	local manor = f_id and self.faction_manor_l[f_id]
	if manor == nil then return 22240 end
	
	return manor:auth(char_id)
end

function Faction_manor_mgr:debug_print()
	print("=====================================================")
	for k, v in pairs(self.faction_manor_l) do
		print(Json.Encode(v:get_info(nil)))
		print("-----------------------------------------------------")
	end
end