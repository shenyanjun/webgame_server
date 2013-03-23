
local misson_loader = require("mission_ex.mission_loader")

--庄园任务外包类
local Quest_wrapper_finca = oo.class(Quest_wrapper_base, "Quest_wrapper_finca")

local limit_cnt = 5

function Quest_wrapper_finca:__init(meta, core)
	Quest_wrapper_base.__init(self, meta, core)
	self.char_id = 0
end

function Quest_wrapper_finca:can_accept(char_id)
	local player = g_obj_mgr:get_obj(char_id)
	if not player then return 200101 end

	local level = tonumber(player:get_level())
	if level < 41 then
		return 25019
	end
	
	local faction_obj = g_faction_mgr:get_faction_by_cid(player:get_id())
	if not faction_obj then
		return 200101
	end

	local meta = misson_loader.get_meta(self:get_id())
	if not meta then
		return E_MISSION_INVALID_ID, nil
	end

	return self.core:can_accept(char_id)
end

function Quest_wrapper_finca:on_accept(char_id)
	self.char_id = char_id

	local player = g_obj_mgr:get_obj(char_id)
	if not player then return false end

	local con = player:get_mission_mgr()
	local finca_mission = con:get_param(PARAM_TYPE_FINCA)
	if not finca_mission then
		return 200101
	end

	local today = f_get_today()
	if finca_mission.update_time < today then	
		finca_mission.update_time = ev.time
		finca_mission.count 	  = 0
		con:set_param(PARAM_TYPE_FINCA,finca_mission)
	end

	if finca_mission.count >= limit_cnt then
		return 25021
	end

	if finca_mission.quest_id ~= self:get_id() then
		return 25026
	end

	local e_code = self.core:on_accept(char_id)
	if e_code == E_SUCCESS then
		finca_mission.count = finca_mission.count + 1
	elseif e_code == 25020 then
		--交互类没庄园导致失败，重新随一个
		local ret, quest_id = g_mission_mgr:random_finca_quest(char_id, finca_mission.quest_id)
		if ret ~= 0 then
			return ret
		end
		finca_mission.quest_id 	= quest_id
		con:set_param(PARAM_TYPE_FINCA, finca_mission)
	end

	return e_code
end

--是否能传送别人庄园
local contact_flag_table = {[12] = true, [13] = true}
function Quest_wrapper_finca:get_faction_id()
	local meta = misson_loader.get_meta(self:get_id())
	if not meta then
		return E_MISSION_INVALID_ID
	end
	
	if not contact_flag_table[meta.flag] then
		return 25016
	end

	if not self:get_f_id() then 
		return 25016
	end

	if self:get_status() == MISSION_STATUS_INCOMPLETE and self.core.limit_time and self.core.limit_time > ev.time
			and not self.core.complete_time and not self.core.complete_flag then
		return E_SUCCESS, self:get_f_id()
	end

	return 25023
end

function Quest_wrapper_finca:get_sns_mission_status(f_id)
	local meta = misson_loader.get_meta(self:get_id())
	if not meta then
		return 0
	end
	
	if not contact_flag_table[meta.flag] then
		return 0
	end

	local faction_id = self:get_f_id()
	if not faction_id or faction_id ~= f_id then 
		return 0
	end

	return self:get_status()
end

function Quest_wrapper_finca:on_complete(char_id, select_list, p_bonus, param_l)	
	local player = g_obj_mgr:get_obj(char_id)
	if not player then return false end

	local meta = misson_loader.get_meta(self:get_id())
	if not meta then
		return E_MISSION_INVALID_ID, nil
	end
	
	local faction_id = player:get_id()
	local faction_obj = g_faction_mgr:get_faction_by_cid(faction_id)
	if not faction_obj then
		return 200101
	end
	local my_f_name = faction_obj:get_faction_name()

	local my_f_id = faction_obj:get_faction_id()
	local other_f_id = self.core:get_f_id()
	local other_f_obj
	if other_f_id then
		 other_f_obj = g_faction_mgr:get_faction_by_fid(other_f_id)
	end

	local con = player:get_mission_mgr()
	local finca_mission = con:get_param(PARAM_TYPE_FINCA)
	if not finca_mission then
		return 200101
	end

	if finca_mission.quest_id ~= self:get_id() then
		con:delete_quest(self:get_id())
		return 200105
	end

	--计算加成(被设完成的减半)
	local step_award = self.core:get_quest_bonus()

	local ret, list = self.core:on_complete(char_id, select_list,p_bonus, param_l)

	if ret == 0 then
		local sret, quest_id = g_mission_mgr:random_finca_quest(char_id,finca_mission.quest_id)
		if sret ~= 0 then
			local s_pkt = {}
			s_pkt.result = sret
			f_quest_error_log("On completing err~! char_id = %s, e_code = %s.", tostring(char_id), tostring(sret))
			g_cltsock_mgr:send_client(char_id, CMD_MISION_GET_FINCA_INFO_S, s_pkt)
			return
		end

		finca_mission.quest_id 	= quest_id
		con:set_param(PARAM_TYPE_FINCA, finca_mission)

		--加自己帮派
		if faction_obj then	
			if meta.reward.faction_reward then
				for _, v in pairs(meta.reward.faction_reward) do
					local s_pkt = {}
					s_pkt.type = 10
					if v.type == M_FACTION_REWARD_CONTRIBUTION then
						s_pkt.param	= math.floor(v.counts * step_award)
						s_pkt.flag	= 6--FACTION.contribution 
						g_faction_mgr:update_faction_level( faction_id, s_pkt)
					elseif v.type == M_FACTION_REWARD_BUILD_POINT then
						s_pkt.param	= math.floor(v.counts * step_award)
						s_pkt.flag	= 4--FACTION.construct_point 
						g_faction_mgr:update_faction_level( faction_id, s_pkt)
					elseif v.type == M_FACTION_REWARD_TECHNOLOGY_POINT then
						s_pkt.param	= math.floor(v.counts * step_award)
						s_pkt.flag	= 5--FACTION.technology_point 
						g_faction_mgr:update_faction_level( faction_id, s_pkt) 
					elseif v.type == M_FACTION_REWARD_FUND then
						s_pkt.param	= math.floor(math.floor(v.counts * step_award))
						s_pkt.flag	= 8--FACTION.faction_money
						g_faction_mgr:update_faction_level( faction_id, s_pkt)
					end
				end	
			end
		end

		--加自己领地繁荣
		local flourish = meta.reward.flourish 
		if flourish then
			g_faction_manor_mgr:add_flourish(my_f_id, flourish * step_award)
		end 

		--加对方繁荣
		local add_type = {}
		local add_flourish = meta.reward.add_flourish 
		if add_flourish and other_f_id then
			add_type[1] = 27
			add_type[2] = ev.time
			add_type[3] = my_f_name
			add_type[4] = math.floor(add_flourish * step_award)
			g_faction_manor_mgr:add_flourish(other_f_id, add_type[3])
		end 

		--加对方帮派
		if other_f_obj then	
			if meta.reward.add_faction_reward then
				add_type[1] = 27
				add_type[2] = ev.time
				add_type[3] = my_f_name
				local s_pkt = {}
				s_pkt.type_log = 13
				s_pkt.io   = 1
				for _, v in pairs(meta.reward.add_faction_reward) do
					if v.type == M_FACTION_REWARD_CONTRIBUTION then
						s_pkt.construct_point = math.floor(v.counts * step_award)
					elseif v.type == M_FACTION_REWARD_BUILD_POINT then
						s_pkt.construct_point	= math.floor(v.counts * step_award)
						add_type[5]	= s_pkt.construct_point
					elseif v.type == M_FACTION_REWARD_TECHNOLOGY_POINT then
						s_pkt.technology_point	= math.floor(v.counts * step_award)
						add_type[7]	= s_pkt.technology_point
					elseif v.type == M_FACTION_REWARD_FUND then
						s_pkt.money	= math.floor(v.counts * step_award)
						add_type[6]	= s_pkt.money
					end
				end	

				g_faction_mgr:add_content( other_f_id, s_pkt)
			end
			if add_type[1] then
				local new_pkt = {}
				new_pkt.pkt = add_type
				new_pkt.f_id = other_f_id
				new_pkt.type = 27
				g_svsock_mgr:send_server_ex(COMMON_ID, 0, CMD_M2C_FACTION_MANOR_SET_HISTORY_C, new_pkt)
			end 
		end

		--减对方繁荣
		local sub_type = {}
		local sub_flourish = meta.reward.sub_flourish 
		if sub_flourish and other_f_id then
			sub_type[1] = 26
			sub_type[2] = ev.time
			sub_type[3] = my_f_name
			sub_type[4] = math.floor(sub_flourish * step_award)
			g_faction_manor_mgr:add_flourish(other_f_id, -sub_type[3])
		end 

		--减对方帮派
		if other_f_obj then	
			if meta.reward.sub_faction_reward then
				sub_type[1] = 26
				sub_type[2] = ev.time
				sub_type[3] = my_f_name
				if not sub_type[4] then sub_type[4] = 0 end

				local s_pkt = {}
				s_pkt.type_log = 13
				s_pkt.io   = 0
				for _, v in pairs(meta.reward.sub_faction_reward) do
					if v.type == M_FACTION_REWARD_CONTRIBUTION then
						s_pkt.construct_point = -math.floor(v.counts * step_award)
					elseif v.type == M_FACTION_REWARD_BUILD_POINT then
						s_pkt.construct_point = -math.floor(v.counts * step_award)
						sub_type[5] = -s_pkt.construct_point
					elseif v.type == M_FACTION_REWARD_TECHNOLOGY_POINT then
						s_pkt.technology_point = -math.floor(v.counts * step_award)
						sub_type[7] = -s_pkt.technology_point
					elseif v.type == M_FACTION_REWARD_FUND then
						s_pkt.money	= -math.floor(v.counts * step_award)
						sub_type[6] = -s_pkt.money
					end
				end	

				g_faction_mgr:add_content( other_f_id, s_pkt)
			end
			if sub_type[1] then
				local new_pkt = {}
				new_pkt.pkt = sub_type
				new_pkt.f_id = other_f_id
				new_pkt.type = 26
				g_svsock_mgr:send_server_ex(COMMON_ID, 0, CMD_M2C_FACTION_MANOR_SET_HISTORY_C, new_pkt)
			end 
		end
	end

	return ret ,list
end

--从数据库构造
function Quest_wrapper_finca:construct(con)
	Quest_wrapper_base.construct(self,con)
	self.char_id = con.char_id
end

function Quest_wrapper_finca:serialize_to_net()
	local result = Quest_wrapper_base.serialize_to_net(self)
	local player = g_obj_mgr:get_obj(self.char_id)
	if player then
		local con = player:get_mission_mgr()
		local finca_mission = con:get_param(PARAM_TYPE_FINCA)
		if finca_mission then
			result.base[6] = finca_mission.count or 0
		end
	end
	return result
end

Mission_mgr.register_wrapper(MISSION_TYPE_FINCA, Quest_wrapper_finca)
