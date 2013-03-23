
--获取累计消费数据
Sv_commands[0][CMD_GET_CONSUM_RET_INFO_M] = 
function(conn, char_id, pkt)
	if conn and char_id and pkt.id then -- 检查参数
		g_consum_ret_mgr:get_char_info_by_type(pkt.id, char_id)
	end
end

Sv_commands[0][CMD_GET_CONSUM_RET_REWARD_M] = 
function(conn, char_id, pkt)
	if conn and char_id and pkt and pkt.id and pkt.index then
		g_consum_ret_mgr:get_reward_by_type(pkt.id, char_id, pkt.index)
	end
end



