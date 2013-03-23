
local misson_loader = require("mission_ex.mission_loader")

--无领地任务外包类
local Quest_wrapper_no_manor = oo.class(Quest_wrapper_base, "Quest_wrapper_no_manor")

function Quest_wrapper_no_manor:__init(meta, core)
	Quest_wrapper_base.__init(self, meta, core)
	self.char_id = 0
end

function Quest_wrapper_no_manor:can_accept(char_id)
	local player = g_obj_mgr:get_obj(char_id)
	if not player then return 200101 end

	local level = player:get_level()
	if level < 35 then
		return 200123
	end
	
	local error = f_is_owner_territory(char_id)
	if error == 0 then
		return 200126
	end
	if error == 1 then
		return 200124
	end
	if error == 3 then
		return 200121
	end

	local meta = misson_loader.get_meta(self:get_id())
	if not meta then
		return E_MISSION_INVALID_ID, nil
	end

	return self.core:can_accept(char_id)
end

function Quest_wrapper_no_manor:on_accept(char_id)
	self.char_id = char_id

	local player = g_obj_mgr:get_obj(char_id)
	if not player then return false end

	local error = f_is_owner_territory(char_id)
	if error == 0 then
		return 200126
	end
	if error == 1 then
		return 200124
	end
	if error == 3 then
		return 200121
	end

	local con = player:get_mission_mgr()
	local manor_no_mission = con:get_param(PARAM_TYPE_NO_MANOR_MISSION)
	if not manor_no_mission then
		manor_no_mission = {}
		manor_no_mission.update_time = ev.time
		manor_no_mission.count 	  = 0
		con:set_param(PARAM_TYPE_NO_MANOR_MISSION,manor_no_mission)
	end

	local today = f_get_today()
	if manor_no_mission.update_time < today then	
		manor_no_mission.update_time = ev.time
		manor_no_mission.count 	  = 0
		con:set_param(PARAM_TYPE_NO_MANOR_MISSION,manor_no_mission)
	end

	if manor_no_mission.count > 0 then
		return 200122
	end

	return self.core:on_accept(char_id)
end

function Quest_wrapper_no_manor:on_complete(char_id, select_list)	
	local player = g_obj_mgr:get_obj(char_id)
	if not player then return false end

	local error = f_is_owner_territory(char_id)
	if error == 0 then
		return 200126
	end
	if error == 1 then
		return 200124
	end

	local meta = misson_loader.get_meta(self:get_id())
	if not meta then
		return E_MISSION_INVALID_ID, nil
	end

	local con = player:get_mission_mgr()
	local manor_no_mission = con:get_param(PARAM_TYPE_NO_MANOR_MISSION)
	if not manor_no_mission then
		manor_no_mission = {}
		manor_no_mission.update_time = ev.time
		manor_no_mission.count 	  = 1
		con:set_param(PARAM_TYPE_NO_MANOR_MISSION,manor_no_mission)
	end

	local today = f_get_today()
	if manor_no_mission.update_time < today then	
		manor_no_mission.update_time = ev.time
		manor_no_mission.count 	  = 0
		con:set_param(PARAM_TYPE_NO_MANOR_MISSION,manor_no_mission)
	end

	local ret, list = self.core:on_complete(char_id, select_list)
	--特殊加成

	if ret == 0 then
		local faction_obj = g_faction_mgr:get_faction_by_cid(char_id)

		if faction_obj then	
			if meta.reward.faction_reward then
				for _, v in pairs(meta.reward.faction_reward) do
					local s_pkt = {}
					s_pkt.type = 10
					if v.type == M_FACTION_REWARD_CONTRIBUTION then
						s_pkt.param	= math.floor(v.counts)
						s_pkt.flag	= 6--FACTION.contribution 
						g_faction_mgr:update_faction_level( char_id, s_pkt)
					elseif v.type == M_FACTION_REWARD_BUILD_POINT then
						s_pkt.param	= math.floor(v.counts )
						s_pkt.flag	= 4--FACTION.construct_point 
						g_faction_mgr:update_faction_level( char_id, s_pkt)
					elseif v.type == M_FACTION_REWARD_TECHNOLOGY_POINT then
						s_pkt.param	= math.floor(v.counts )
						s_pkt.flag	= 5--FACTION.technology_point 
						g_faction_mgr:update_faction_level( char_id, s_pkt) 
					elseif v.type == M_FACTION_REWARD_FUND then
						s_pkt.param	= math.floor(math.floor(v.counts ))
						s_pkt.flag	= 8--FACTION.faction_money
						g_faction_mgr:update_faction_level( char_id, s_pkt)
					end
				end	
			end
		end

		print("spectral =", j_e(meta.reward.spectral_reward))
		for _, v in pairs(meta.reward.spectral_reward or {}) do
			print("counts =",v.counts)
			f_add_territory_power(v.type, v.counts)
		end

		manor_no_mission.count = 1
		con:set_param(PARAM_TYPE_NO_MANOR_MISSION,manor_no_mission)
	end

	return ret ,list
end

--从数据库构造
function Quest_wrapper_no_manor:construct(con)
	Quest_wrapper_base.construct(self,con)
	self.char_id = con.char_id
end

function Quest_wrapper_no_manor:serialize_to_net()
	local result = Quest_wrapper_base.serialize_to_net(self)

	return result
end

Mission_mgr.register_wrapper(MISSION_TYPE_NO_MANOR, Quest_wrapper_no_manor)