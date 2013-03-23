local debug_print = print 

require("reward.buffer_reward.buffer_reward_mgr")         


Sv_commands[0][CMD_G2W_BUFFER_REWARD_ACK] = 
function(conn, char_id, pkt)
	debug_print("buffer_reward_start")
	if pkt == nil or pkt.time ==nil  or pkt.type == nil or pkt.start_date == nil or pkt.start_time == nil or pkt.end_date==nil or pkt.end_time ==nil then
	 	return
	end

	local reward = g_buffer_reward_mgr:create_reward(pkt)
	if reward ~=nil then
		g_buffer_reward_mgr:add_reward(reward)
	end
end

Sv_commands[0][CMD_G2W_BUFFER_REWARD_STOP_ACK] = 
function(conn, char_id, pkt)
	debug_print("buffer_reward_stop")
	if pkt == nil or pkt.type==nil then	return end
	local type =pkt.type

	local reward =g_buffer_reward_mgr:find_reward(type)
	if reward ~=nil then
		g_buffer_reward_mgr:del_reward(reward)
	end
end