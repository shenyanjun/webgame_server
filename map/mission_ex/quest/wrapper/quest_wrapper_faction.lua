
local misson_loader = require("mission_ex.mission_loader")

--帮派奖励
local award_t = require("config.xml.npc_function.loop_mission_reward")

--帮派任务外包类
local Quest_wrapper_faction = oo.class(Quest_wrapper_base, "Quest_wrapper_faction")

function Quest_wrapper_faction:__init(meta, core)
	Quest_wrapper_base.__init(self, meta, core)
	self.char_id = 0
end

function Quest_wrapper_faction:can_accept(char_id)
	local player = g_obj_mgr:get_obj(char_id)
	if not player then return 200101 end

	local level = tonumber(player:get_level())
	if level < 30 then
		return 200102
	end
	
	local faction_obj = g_faction_mgr:get_faction_by_cid(player:get_id())
	if not faction_obj then
		return 200101
	end
	local action_lvl = faction_obj:get_action_level()
	local book_lvl	 = faction_obj:get_book_level()
	local gold_lvl   = faction_obj:get_gold_level()
	local need_lvl = {action_lvl,book_lvl,gold_lvl}
	local meta = misson_loader.get_meta(self:get_id())
	if not meta then
		return E_MISSION_INVALID_ID, nil
	end

	local building = meta.precondition.faction_building[1].id
	local lvl = meta.precondition.faction_building[1].lvl

	if need_lvl[building] < lvl then
		return 200102
	end
	return self.core:can_accept(char_id)
end

function Quest_wrapper_faction:on_accept(char_id)
	self.char_id = char_id

	local player = g_obj_mgr:get_obj(char_id)
	if not player then return false end

	local con = player:get_mission_mgr()
	local loop_faction_mission = con:get_param(PARAM_TYPE_LOOP_INDIVIDUAL)
	if not loop_faction_mission then
		return 200101
	end

	local today = f_get_today()
	if loop_faction_mission.update_time < today then	
		loop_faction_mission.update_time = ev.time
		loop_faction_mission.count 		 = 1
		con:set_param(PARAM_TYPE_LOOP_INDIVIDUAL,loop_faction_mission)
	end

	if loop_faction_mission.count > FACTION_COMPLETE_TIME then
		return false
	end

	return self.core:on_accept(char_id)
end

function Quest_wrapper_faction:on_complete(char_id, select_list, p_bonus, param_l)	
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

	local con = player:get_mission_mgr()
	local loop_faction_mission = con:get_param(PARAM_TYPE_LOOP_INDIVIDUAL)
	if not loop_faction_mission then
		return 200101
	end

	if loop_faction_mission.quest_id ~= self:get_id() then
		con:delete_quest(self:get_id())
		return 200105
	end
	local today = f_get_today()
	if loop_faction_mission.update_time < today then	
		loop_faction_mission.update_time = ev.time
		loop_faction_mission.count 		 = 1
		con:set_param(PARAM_TYPE_LOOP_INDIVIDUAL,loop_faction_mission)
	end

	if loop_faction_mission.count > FACTION_COMPLETE_TIME then
		return
	end

	--计算加成
	local step_award = g_mission_mgr:get_bonus(loop_faction_mission.step, loop_faction_mission.count)
	step_award = step_award + player:get_addition(HUMAN_ADDITION.faction_reward)

	local ret, list = self.core:on_complete(char_id, select_list,step_award, param_l)

	local b_pkt = {}
	b_pkt.type		= 32
	b_pkt.char_id	= char_id
	b_pkt.char_name	= player:get_name()
	b_pkt.count		= {}
	b_pkt.count[1]	= math.floor(meta.reward.exp * step_award) or 0
	b_pkt.count[2]	= math.floor(step_award * meta.reward.gold) or 0
	b_pkt.count[3]	= math.floor(step_award * meta.reward.gift_gold) or 0
	b_pkt.count[4]	= 0
	b_pkt.count[5]	= 0
	b_pkt.count[6]	= 0
	b_pkt.count[7]	= 0

	if ret == 0 then
		local sret, quest_id = g_mission_mgr:random_faction_quest(char_id,loop_faction_mission.quest_id)
		if sret ~= 0 then
			local s_pkt = {}
			s_pkt.result = sret
			f_quest_error_log("On completing err~! char_id = %s, e_code = %s.", tostring(char_id), tostring(sret))
			g_cltsock_mgr:send_client(char_id, CMD_MISION_FACTION_INFO_S, s_pkt)
			return
		end

		loop_faction_mission.quest_id 	= quest_id
		loop_faction_mission.count 		= loop_faction_mission.count + 1

		if loop_faction_mission.step >= 10 then
			loop_faction_mission.step = 1
		else 
			loop_faction_mission.step = loop_faction_mission.step + 1
		end

		con:set_param(PARAM_TYPE_LOOP_INDIVIDUAL,loop_faction_mission)

		if faction_obj then	
			if meta.reward.faction_reward then
				for _, v in pairs(meta.reward.faction_reward) do
					local s_pkt = {}
					s_pkt.type = 10
					if v.type == M_FACTION_REWARD_CONTRIBUTION then
						s_pkt.param	= math.floor(v.counts * step_award)
						s_pkt.flag	= 6--FACTION.contribution 
						b_pkt.count[4]	= math.floor(v.counts * step_award)
						g_faction_mgr:update_faction_level( faction_id,s_pkt)
					elseif v.type == M_FACTION_REWARD_BUILD_POINT then
						s_pkt.param	= math.floor(v.counts * step_award)
						s_pkt.flag	= 4--FACTION.construct_point 
						b_pkt.count[7]	= math.floor(v.counts * step_award)
						g_faction_mgr:update_faction_level( faction_id,s_pkt)
					elseif v.type == M_FACTION_REWARD_TECHNOLOGY_POINT then
						s_pkt.param	= math.floor(v.counts * step_award)
						s_pkt.flag	= 5--FACTION.technology_point 
						b_pkt.count[6]	= math.floor(v.counts * step_award)
						g_faction_mgr:update_faction_level( faction_id,s_pkt) 
					elseif v.type == M_FACTION_REWARD_FUND then
						s_pkt.param	= math.floor(math.floor(v.counts * step_award))
						s_pkt.flag	= 8--FACTION.faction_money
						b_pkt.count[5]	= math.floor(v.counts * step_award)
						g_faction_mgr:update_faction_level( faction_id,s_pkt)
					end
				end
			end
		end
		if loop_faction_mission.step == 1 then
			g_svsock_mgr:send_server_ex(WORLD_ID, char_id, CMD_C2W_FACTION_ITEM_MISSION_S, b_pkt)
		end

	end

	return ret ,list
end

--从数据库构造
function Quest_wrapper_faction:construct(con)
	Quest_wrapper_base.construct(self,con)
	self.char_id = con.char_id
end

function Quest_wrapper_faction:serialize_to_net()
	local result = Quest_wrapper_base.serialize_to_net(self)
	local player = g_obj_mgr:get_obj(self.char_id)
	if player then
		local con = player:get_mission_mgr()
		local loop_faction_mission = con:get_param(PARAM_TYPE_LOOP_INDIVIDUAL)
		if loop_faction_mission then
			result.base[4] = g_mission_mgr:get_bonus(loop_faction_mission.step, loop_faction_mission.count, self.char_id)
							 + player:get_addition(HUMAN_ADDITION.faction_reward) or 1
			result.base[5] = loop_faction_mission.step or 1
			result.base[6] = loop_faction_mission.count or 1
		end
	end
	return result
end

Mission_mgr.register_wrapper(MISSION_TYPE_LOOP_NEW, Quest_wrapper_faction)