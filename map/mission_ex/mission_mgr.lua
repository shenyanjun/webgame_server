
local misson_loader = require("mission_ex.mission_loader")
local escort_config = require("config.escort_config")
local max_size = 15
local _builder_list = create_local("misson_mgr._builder_list", {})
local _wrapper_list = create_local("misson_mgr._wrapper_list", {})
local sort_extend_table = "sort_extend"
local sort_extend_index = "{line_id:1, type:1}"
--帮派奖励
local award_t = require("config.xml.npc_function.loop_mission_reward")

Mission_mgr = oo.class(nil, "Mission_mgr")

function Mission_mgr:__init()
	self.quest_list = {}
	self.quest_classification = {}
	self.quest_daily_classification = {}
	self.quest_escort = {}
	self.faction_loop_mission = {}
	self.random_mission = {}
	self.manor_mission = {}
	self.no_manor_mission= {}
	self.vip_quest_escort = {}
	self.quest_finca = {}
	self.faction_scroll = {}
	self.daily_loop_mission = {}
	self:load()
end

--@这个用来干嘛？misson_loader.get_meta(quest_id)
function Mission_mgr:get_quest(quest_id)
	return self.quest_list[id]
end
--注册任务类的构建者，构建者可以是类（是类，不是对象除非是函数对象），函数对象，函数
function Mission_mgr.register_class(type, builder)
	_builder_list[type] = builder
end

--注册任务类的构建者，构建者可以是类（是类，不是对象除非是函数对象），函数对象，函数
function Mission_mgr.register_wrapper(type, wrapper)
	_wrapper_list[type] = wrapper
end

function Mission_mgr:load_prototype(meta)
	local quest_id = meta.id
	local flag = meta.flag
	local type = meta.type
	
	local builder = _builder_list[flag]
	if not builder then
		f_quest_error_log("Mission_mgr:load_prototype(quest_id = %s, flag = %s) Not Exists Builder!"
			, tostring(quest_id)
			, tostring(flag))
		return nil
	end
	local quest = builder(meta)
	if not quest then
		f_quest_error_log("Mission_mgr:load_prototype(quest_id = %s, flag = %s) Build Quest Prototype Failed!"
			, tostring(quest_id)
			, tostring(flag))
	end
	
	local wrapper = _wrapper_list[type]
	if wrapper then
		quest = wrapper(meta, quest)
		if not quest then
			f_quest_error_log("Mission_mgr:load_prototype(quest_id = %s, flag = %s, type = %s) Build Quest Prototype Wrapper Failed!"
				, tostring(quest_id)
				, tostring(flag)
				, tostring(type))
		end
	end
	
	return quest
end

function Mission_mgr:load()
	self.quest_list = {}
	self.quest_daily_classification = {}
	self.quest_classification = {}
	self.quest_escort = {}
	self.faction_loop_mission = {}
	self.manor_mission = {}
	self.no_manor_mission= {}
	self.vip_quest_escort = {}
	self.quest_finca = {}
	self.faction_scroll = {}
	self.daily_loop_mission = {}

	local all_occ = {11, 21, 31, 41, 51}	--职业
	for _, v in pairs(all_occ) do
		self.quest_classification[v] = {}
		self.quest_daily_classification[v] = {}
		self.quest_escort[v] = {}
		self.vip_quest_escort[v] = {}
	end
	
	local meta_list = misson_loader.get_meta_list()
	for id, meta in pairs(meta_list or {}) do
		local quest = self:load_prototype(meta)
		if quest then
			self.quest_list[id] = quest
			local level = 0
			local occ = 0
			if meta.precondition then
				level = meta.precondition.min_level or 0
				occ = meta.precondition.req_class or 0
			end
			
			local classification = self.quest_classification

			if MISSION_TYPE_DAILY == meta.type or MISSION_TYPE_BATTLE_DAY_LOOP == meta.type or MISSION_TYPE_BATTLE_LOOP == meta.type 
			   or MISSION_TYPE_NINE_PVP == meta.type or MISSION_TYPE_NINE_PVP_MONSTER == meta.type then
			    if meta.flag == MISSION_FLAG_KILL and MISSION_TYPE_DAILY == meta.type 
				or meta.flag == MISSION_FLAG_SPEAK and MISSION_TYPE_DAILY == meta.type 
				 then
					classification = self.daily_loop_mission
				else
					classification = self.quest_daily_classification
				end
			elseif  MISSION_TYPE_ESCORT == meta.type then
				classification = self.quest_escort
			elseif  MISSION_TYPE_LOOP_NEW == meta.type then
				classification = self.faction_loop_mission
			elseif  MISSION_TYPE_RANDOM == meta.type then
				classification = self.random_mission
			elseif  MISSION_TYPE_MANOR == meta.type then
				classification = self.manor_mission
			elseif  MISSION_TYPE_NO_MANOR == meta.type then
				classification = self.no_manor_mission	
			elseif  MISSION_TYPE_VIP_ESCORT == meta.type then
				classification = self.vip_quest_escort
			elseif  MISSION_TYPE_FINCA == meta.type then
				classification = self.quest_finca
			elseif  MISSION_TYPE_FACTION_SCROLL == meta.type then
				classification = self.faction_scroll
			end

			if MISSION_TYPE_LOOP_NEW == meta.type or MISSION_TYPE_MANOR == meta.type or MISSION_TYPE_NO_MANOR == meta.type
				or MISSION_TYPE_RANDOM == meta.type or MISSION_TYPE_FACTION_SCROLL == meta.type 
				or (MISSION_TYPE_DAILY == meta.type and MISSION_FLAG_KILL == meta.flag)
				or meta.flag == MISSION_FLAG_SPEAK and MISSION_TYPE_DAILY == meta.type
				then
				table.insert(classification, id)
			elseif MISSION_TYPE_AUTHORIZE == meta.type then
			elseif MISSION_TYPE_FINCA == meta.type then
				local flag_type = meta.flag
				if not classification[flag_type] then
					classification[flag_type] = {}
				end
				table.insert(classification[flag_type], id)
			else
				if 0 == occ then
					for _, v in pairs(all_occ) do
						local list = classification[v][level]
						if not list then
							list = {}
							classification[v][level] = list
						end
						table.insert(list, id)
					end
				else
					local list = classification[occ][level]
					if not list then
						list = {}
						classification[occ][level] = list
					end
					table.insert(list, id)
				end
			end
		end
	end
	--for k, v in pairs(self.quest_finca) do
		--print("self.quest_finca =", j_e(k))
	--end
end

function Mission_mgr:get_wait_accept_escort(char_id, type)
	local player = char_id and g_obj_mgr:get_obj(char_id)
	local level = player:get_level()
	local occ = player:get_occ()
	local con = player and player:get_mission_mgr()
	assert(con)
	
	local occ_quest_list
	if type == 1 then
		occ_quest_list = self.quest_escort[occ]
	elseif type == 2 then
		if g_vip_mgr:get_vip_info(char_id) ~= 3 then
			return nil
		end
		occ_quest_list = self.vip_quest_escort[occ]
	end

	if occ_quest_list then
		for lv = level, 0, -1 do
			if occ_quest_list[lv] then
				for _, v in pairs(occ_quest_list[lv]) do
					local quest_obj = self.quest_list[v]
					if quest_obj and E_SUCCESS == quest_obj:can_accept(char_id) then
						return quest_obj
					end 
				end
			end
		end
	end
	
	return nil
end

function Mission_mgr:get_wait_accept_list(char_id)
	local player = char_id and g_obj_mgr:get_obj(char_id)
	local level = player:get_level()
	local occ = player:get_occ()
	local con = player and player:get_mission_mgr()
	assert(con)
	
	local result = {}
	
	local occ_quest_list = self.quest_escort[occ]
	if occ_quest_list then
		for lv = level, 0, -1 do
			if occ_quest_list[lv] then
				for _, v in pairs(occ_quest_list[lv]) do
					local quest_obj = self.quest_list[v]
					if quest_obj and E_SUCCESS == quest_obj:can_accept(char_id) then
						result[v] = quest_obj
					end 
				end
			end
		end
	end
	
	local occ_quest_list = self.vip_quest_escort[occ]
	if occ_quest_list then
		for lv = level, 0, -1 do
			if occ_quest_list[lv] then
				for _, v in pairs(occ_quest_list[lv]) do
					local quest_obj = self.quest_list[v]
					if quest_obj and E_SUCCESS == quest_obj:can_accept(char_id) then
						result[v] = quest_obj
					end 
				end
			end
		end
	end

	local occ_quest_list = self.quest_daily_classification[occ]
	if occ_quest_list then
		for lv = level, 0, -1 do
			if occ_quest_list[lv] then
				for _, v in pairs(occ_quest_list[lv]) do
					local quest_obj = self.quest_list[v]
					if quest_obj and E_SUCCESS == quest_obj:can_accept(char_id) then
						result[v] = quest_obj
					end 
				end
			end
		end
	end
	
	local count = 0
	local occ_quest_list = self.quest_classification[occ]
	if occ_quest_list then
		for lv = level, 0, -1 do
			if occ_quest_list[lv] then
				for _, v in pairs(occ_quest_list[lv]) do
					local quest_obj = self.quest_list[v]
					if quest_obj and quest_obj:get_type() ~= MISSION_TYPE_MIX and E_SUCCESS == quest_obj:can_accept(char_id) then
						count = count + 1
						result[v] = quest_obj
						if count >= max_size then
							return result
						end
					end 
				end
			end
		end
	end
	return result
end

function Mission_mgr:load_quest(quest_id, record)
	if not record then
		return nil, E_MISSION_INVALID_DATA
	end
	
	local prototype = quest_id and self.quest_list[quest_id]
	if not prototype then
		return nil, E_MISSION_INVALID_ID
	end
	
	return prototype:clone(record)
end

function Mission_mgr:build_quest(quest_id)	
	local prototype = quest_id and self.quest_list[quest_id]
	if not prototype then
		return nil, E_MISSION_INVALID_ID
	end
	
	return prototype:clone(nil)
end

function Mission_mgr:random_faction_quest(char_id, quest_id)
	local player = g_obj_mgr:get_obj(char_id)
	if not player then return  end

	local level = tonumber(player:get_level())
	if level < 30 then
		return 200102
	end

	local faction_obj = g_faction_mgr:get_faction_by_cid(player:get_id())
	if not faction_obj then
		return 200101
	end
	
	local mission_list = {}
	local s_count = 1
	for k , v in pairs(self.faction_loop_mission) do
		local quest = self.quest_list[v]
		local e_error = quest:can_accept(char_id)
		if E_SUCCESS == e_error then
			if not quest_id or quest_id ~= quest:get_id() then
				mission_list[s_count] = quest:get_id()
				s_count = s_count + 1
			end
		end
	end
	local i = crypto.random(1, table.getn(mission_list) + 1)
	if not mission_list[i] then
		return 200104
	end
	return 0, mission_list[i]
end

function Mission_mgr:random_faction_scroll(char_id, quest_id)
	local player = g_obj_mgr:get_obj(char_id)
	if not player then return  end

	local level = tonumber(player:get_level())
	if level < 40 then
		return 200141
	end
	
	local mission_list = {}
	local s_count = 1
	for k , v in pairs(self.faction_scroll) do
		local quest = self.quest_list[v]
		local e_error = quest:can_accept(char_id)
		if E_SUCCESS == e_error then
			if not quest_id or quest_id ~= quest:get_id() then
				mission_list[s_count] = quest:get_id()
				s_count = s_count + 1
			end
		end
	end
	local i = crypto.random(1, table.getn(mission_list) + 1)
	if not i or not mission_list[i] then
		return 200104
	end
	return 0, mission_list[i]
end


local finca_rate = {[12] = 20, [13] = 20}
function Mission_mgr:random_finca_quest(char_id, quest_id)
	local player = g_obj_mgr:get_obj(char_id)
	if not player then return  end

	local level = tonumber(player:get_level())
	if level < 41 then
		return 25019
	end
	
	local tmp_table = {}
	local rate = 0
	local faction_obj = g_faction_mgr:get_faction_by_cid(player:get_id())
	local faction_id
	if faction_obj then
		faction_id = faction_obj:get_faction_id()
	end

	for i = 1, MISSION_FLAG_MAX do
		if self.quest_finca[i] then
			if (i == 12 and faction_id and g_faction_mgr:random_hostility_manor(faction_id) and level >= 46) 
			 or (i == 13 and faction_id and  g_faction_mgr:random_friend_manor(faction_id)) 
			 or i ~= 12 or i ~= 13 then	

				local tmp = {}
				tmp.flag = i
				rate = rate + (finca_rate[i] or 100)
				tmp.rate = rate
				table.insert(tmp_table, tmp)
			end
		end
	end

	--最多循环3次
	for cnt = 1, 3 do
		--先随机任务flag
		local random_rate = crypto.random(1, rate + 1)
		local tmp = {}
		for i = 1, table.getn(tmp_table) do
			if tmp_table[i].rate >= random_rate then
				tmp = self.quest_finca[tmp_table[i].flag]
				break
			end
		end

		--随机具体任务
		local mission_list = {}
		local s_count = 1
		for k , v in pairs(tmp) do
			local quest = self.quest_list[v]
			local e_error = quest:can_accept(char_id)
			if E_SUCCESS == e_error then
				if not quest_id or quest_id ~= v then
					mission_list[s_count] = quest:get_id()
					s_count = s_count + 1
				end
			end
		end

		local i = crypto.random(1, table.getn(mission_list) + 1)
		if mission_list[i] then
			return  0, mission_list[i]
		end
	end

	--3次都没能随到，默认没有符合条件的
	return 25017
end

function Mission_mgr:get_bonus(step,count, char_id)
	if (step and step < 1) or (count and count < 1) then
		return 1
	end
	local step_award = award_t.faction_award[step] or 1
	if count <= 10 then
		step_award = step_award * 5
	end
	return step_award
end

local faction_scroll_bonus = {1, 5, 25, 125}
function Mission_mgr:get_faction_scroll_bonus(color)
	return faction_scroll_bonus[color] or 1
end

function Mission_mgr:accept_faction_scroll(player, color)
	local con = player:get_mission_mgr()
	if not con then return 1 end

	local faction_scroll_mission = con:get_param(PARAM_TYPE_FACTION_SCROLL)
	if not faction_scroll_mission then
		faction_scroll_mission = {}
		faction_scroll_mission.count = 0
		faction_scroll_mission.update = ev.time
	else
		if faction_scroll_mission.update < f_get_today() then
			faction_scroll_mission.count = 0
			faction_scroll_mission.update = ev.time
		else
			if faction_scroll_mission.count >= 10 then
				return 200142
			end
		end
	end

	if faction_scroll_mission.quest_id and con:get_accept_mission(faction_scroll_mission.quest_id) then
		return 200143
	end

	local e_code, quest_id = self:random_faction_scroll(player:get_id(), faction_scroll_mission.quest_id)

	if e_code ~= E_SUCCESS then return e_code end

	local old_color = faction_scroll_mission.color
	local old_cnt = faction_scroll_mission.count

	faction_scroll_mission.color = color
	faction_scroll_mission.count = faction_scroll_mission.count + 1
	faction_scroll_mission.flag = 1				--保证该类任务只能从这里接,接成功后任务自己置会
	con:set_param(PARAM_TYPE_FACTION_SCROLL, faction_scroll_mission)

	e_code = con:accept_quest(quest_id)

	if e_code == E_SUCCESS then 
		if faction_scroll_mission.quest_id then
			con:delete_quest(faction_scroll_mission.quest_id)
		end
		faction_scroll_mission.color 	= color
		faction_scroll_mission.quest_id = quest_id
	else
		faction_scroll_mission.count = old_cnt
		faction_scroll_mission.color = old_color
	end

	faction_scroll_mission.flag = 0
	con:set_param(PARAM_TYPE_FACTION_SCROLL, faction_scroll_mission)

	return e_code 
end

--随机获得一个可接的日常环任务
function Mission_mgr:random_daily_quest(char_id)
	local player = g_obj_mgr:get_obj(char_id)
	if not player then return  end
	
	local level = tonumber(player:get_level())
	if level < 30 then
		return 
	end
	
	local mission_list = {}
	local s_count = 1
	for k , v in pairs(self.daily_loop_mission) do
		local quest = self.quest_list[v]
		local e_error = quest:can_accept(char_id)
		if E_SUCCESS == e_error then
			if not quest_id or quest_id ~= quest:get_id() then
				mission_list[s_count] = quest:get_id()
				s_count = s_count + 1
			end
		end
	end
	local i = crypto.random(1, table.getn(mission_list) + 1)
	if not mission_list[i] then
		return 200104
	end
	return 0, mission_list[i]
end