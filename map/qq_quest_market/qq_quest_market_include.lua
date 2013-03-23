


require("qq_quest_market.qq_quest_base")
require("qq_quest_market.qq_quest_level")
require("qq_quest_market.qq_quest_scene")
require("qq_quest_market.qq_quest_kill")

require("qq_quest_market.qq_quest_market_con")


local function get_qq_queest_con(char_id)
	local player = char_id and g_obj_mgr:get_obj(char_id)
	return player and player:get_qq_quest_con()
end

g_event_mgr:register_event(EVENT_SET.EVENT_LEVEL_UP, get_qq_queest_con, QQ_quest_market_con.notify_level_up_event)
g_event_mgr:register_event(EVENT_SET.EVENT_KILL_MONSTER, get_qq_queest_con, QQ_quest_market_con.notify_kill_event)
g_event_mgr:register_event(EVENT_SET.EVENT_ENTER_COPY, get_qq_queest_con, QQ_quest_market_con.notify_scene)


--获取QQ集市任务状态
Clt_commands[1][CMD_MAP_QQ_QUEST_STATE_C] =
function(conn, pkt)
	local player = g_obj_mgr:get_obj(conn.char_id)
	if player then
		local mission_con = player:get_qq_quest_con()
		if not mission_con then return end		
		local qq_quest = mission_con:get_quest()
		if qq_quest	then	
			qq_quest:send_to_net()
		end
	end
end