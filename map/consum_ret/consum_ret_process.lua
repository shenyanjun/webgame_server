
-- 累计消费回馈

--获取累计消费数据
Clt_commands[1][CMD_GET_CONSUM_RET_INFO_B] = 
function(conn, pkt)
	if conn and conn.char_id then
		g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id, CMD_GET_CONSUM_RET_INFO_M, pkt)
	end
end

Sv_commands[0][CMD_GET_CONSUM_RET_INFO_C] = 
function(conn, char_id, pkt)
	g_cltsock_mgr:send_client(char_id, CMD_GET_CONSUM_RET_INFO_S, pkt)
end

--领取累计消费奖励
Clt_commands[1][CMD_GET_CONSUM_RET_REWARD_B] = 
function(conn, pkt)
	if conn and conn.char_id then
		local player = g_obj_mgr:get_obj(conn.char_id)
		if not player then return end
		local pack_con = player:get_pack_con()
		if not pack_con then return end
		if pack_con:get_bag_free_slot_cnt() < 1 then
			return g_cltsock_mgr:send_client(conn.char_id, CMD_GET_CONSUM_RET_REWARD_S, {["result"] = 43004})
		end
		g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id, CMD_GET_CONSUM_RET_REWARD_M, pkt)
	end
end

Sv_commands[0][CMD_GET_CONSUM_RET_REWARD_C] = 
function(conn, char_id, pkt)
	if conn and char_id and pkt then
		if pkt.result and pkt.result~=0 then
			return g_cltsock_mgr:send_client(char_id, CMD_GET_CONSUM_RET_REWARD_S, pkt)
		end

		local item_id = pkt.reward and pkt.reward.item_id
		local item_cnt = pkt.reward and pkt.reward.item_cnt

		local ret = pkt
		g_sock_event_mgr:set_event_id(char_id, pkt, ret)

		if not item_id or not item_cnt then
			ret.result = 27767 -- 奖励物品错误
			return g_svsock_mgr:send_server_ex(COMMON_ID,char_id, CMD_GET_CONSUM_RET_CHECK_S, ret)
		end
		
		local item_list = {}
		item_list[1] = {}
		item_list[1].type = 1
		item_list[1].item_id = item_id
		item_list[1].number = item_cnt

		local player = g_obj_mgr:get_obj(char_id)
		if not player then
			ret.result = 27768 -- 获取不到人物
			return g_svsock_mgr:send_server_ex(COMMON_ID,char_id, CMD_GET_CONSUM_RET_CHECK_S, ret)
		end
		local pack_con = player:get_pack_con()
		if not pack_con then
			ret.result = 27769 -- 获取不到背包
			return g_svsock_mgr:send_server_ex(COMMON_ID,char_id, CMD_GET_CONSUM_RET_CHECK_S, ret)
		end
		
		local e_code = pack_con:add_item_l(item_list,{['type'] = ITEM_SOURCE.CONSUM_RET_JADE})
		
		ret.result = e_code

		if e_code ~= 0 then
			return g_svsock_mgr:send_server_ex(COMMON_ID,char_id, CMD_GET_CONSUM_RET_CHECK_S, ret)
		end

		g_svsock_mgr:send_server_ex(COMMON_ID,char_id, CMD_GET_CONSUM_RET_CHECK_S, ret)

		local ret = {}
		ret.result = e_code
		ret.id = pkt.id
		return g_cltsock_mgr:send_client(char_id, CMD_GET_CONSUM_RET_REWARD_S, ret)
	end
end



