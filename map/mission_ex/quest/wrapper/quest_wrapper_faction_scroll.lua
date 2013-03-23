
local misson_loader = require("mission_ex.mission_loader")


--帮派任务外包类
local Quest_wrapper_scroll = oo.class(Quest_wrapper_base, "Quest_wrapper_scroll")

function Quest_wrapper_scroll:__init(meta, core)
	Quest_wrapper_base.__init(self, meta, core)
	self.char_id = 0
end

function Quest_wrapper_scroll:can_accept(char_id)
	local player = g_obj_mgr:get_obj(char_id)
	if not player then return 200101 end

	local level = tonumber(player:get_level())
	if level < 40 then
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

function Quest_wrapper_scroll:on_accept(char_id)
	self.char_id = char_id

	local player = g_obj_mgr:get_obj(char_id)
	if not player then return false end

	local con = player:get_mission_mgr()
	local faction_scroll_mission = con:get_param(PARAM_TYPE_FACTION_SCROLL)
	if not faction_scroll_mission or not faction_scroll_mission.flag then
		return 200101
	end

	if faction_scroll_mission.flag ~= 1 then
		return 200101
	end

	return self.core:on_accept(char_id)
end

function Quest_wrapper_scroll:on_complete(char_id, select_list, p_bonus, param_l)	
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
	local faction_scroll_mission = con:get_param(PARAM_TYPE_FACTION_SCROLL)
	if not faction_scroll_mission then
		return 200101
	end

	if faction_scroll_mission.quest_id ~= self:get_id() then
		con:delete_quest(self:get_id())
		return 200105
	end

	--计算加成
	local step_award = g_mission_mgr:get_faction_scroll_bonus(faction_scroll_mission.color)

	local ret, list = self.core:on_complete(char_id, select_list,step_award, param_l)

	if ret == 0 then
		if meta.reward.faction_reward then
			local s_pkt = {}
			
			s_pkt.type_log = 10
			s_pkt.io = 1
			if faction_scroll_mission.color == 3 or faction_scroll_mission.color == 4 then
				s_pkt.type = 30
				s_pkt.color = faction_scroll_mission.color
				s_pkt.char_id = self.char_id
			end

			for _, v in pairs(meta.reward.faction_reward) do
				if v.type == M_FACTION_REWARD_CONTRIBUTION then
					s_pkt.construct_point = math.floor(v.counts * step_award)
				elseif v.type == M_FACTION_REWARD_BUILD_POINT then
					s_pkt.contribution = {}
					s_pkt.contribution[1] = {self.char_id, math.floor(v.counts * step_award)}
				elseif v.type == M_FACTION_REWARD_TECHNOLOGY_POINT then
					s_pkt.technology_point = math.floor(v.counts * step_award)
				elseif v.type == M_FACTION_REWARD_FUND then
					s_pkt.money	= math.floor(math.floor(v.counts * step_award))
				end
			end	

			g_faction_mgr:add_content(faction_obj:get_faction_id(), s_pkt)
		end
			
	end

	return ret ,list
end

--从数据库构造
function Quest_wrapper_scroll:construct(con)
	Quest_wrapper_base.construct(self,con)
	self.char_id = con.char_id
end

function Quest_wrapper_scroll:serialize_to_net()
	local result = Quest_wrapper_base.serialize_to_net(self)
	local player = g_obj_mgr:get_obj(self.char_id)
	if player then
		local con = player:get_mission_mgr()
		local faction_scroll_mission = con:get_param(PARAM_TYPE_FACTION_SCROLL)
		if faction_scroll_mission then
			result.base[4] = g_mission_mgr:get_faction_scroll_bonus(faction_scroll_mission.color)
			result.base[6] = faction_scroll_mission.count or 1
			result.color = faction_scroll_mission.color
		end
	end
	return result
end

Mission_mgr.register_wrapper(MISSION_TYPE_FACTION_SCROLL, Quest_wrapper_scroll)
