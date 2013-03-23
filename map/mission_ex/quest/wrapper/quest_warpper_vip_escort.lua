
local misson_loader = require("mission_ex.mission_loader")

--领地任务外包类
local Quest_wrapper_vip_escort = oo.class(Quest_wrapper_base, "Quest_wrapper_vip_escort")

function Quest_wrapper_vip_escort:__init(meta, core)
	Quest_wrapper_base.__init(self, meta, core)
	self.char_id = 0
end

function Quest_wrapper_vip_escort:can_accept(char_id)
	--local player = g_obj_mgr:get_obj(char_id)
	--if not player then return 200101 end

	if g_vip_mgr:get_vip_info(char_id) ~= 3 then
		return 200097
	end

	return self.core:can_accept(char_id)
end

function Quest_wrapper_vip_escort:on_accept(char_id)
	--self.char_id = char_id
--
	--local player = g_obj_mgr:get_obj(char_id)
	--if not player then return false end
--
	--local con = player:get_mission_mgr()

	if g_vip_mgr:get_vip_info(char_id) ~= 3 then
		return 200097
	end

	return self.core:on_accept(char_id)
end

function Quest_wrapper_vip_escort:serialize_to_net()
	local result = Quest_wrapper_base.serialize_to_net(self)

	return result
end

Mission_mgr.register_wrapper(MISSION_TYPE_VIP_ESCORT, Quest_wrapper_vip_escort)
