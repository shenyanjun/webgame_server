

---------------------------------接收抽奖，与map交互---------------------

--打开基本界面
Sv_commands[0][CMD_COLLECTION_ACTIVITY_OPEN_BASE_M] =
function(conn,char_id,pkt)
	if pkt==nil then return end

	if char_id ~= nil then
		local s_pkt = {}
		s_pkt.item_l = g_collection_activity_mgr:get_items_info()	or {}
		g_server_mgr:send_to_server(conn.id, char_id, CMD_COLLECTION_ACTIVITY_OPEN_BASE_C, s_pkt)
		return
	end
end

--通知公共服增加捐赠
Sv_commands[0][CMD_COLLECTION_ACTIVITY_DONATE_M] =
function(conn,char_id,pkt)
	if pkt==nil then return end

	if char_id ~= nil then
		g_collection_activity_mgr:add_collection_item(pkt.index, pkt.count)
		return
	end
end

--通知公共服抽中贵重物品
Sv_commands[0][CMD_COLLECTION_ACTIVITY_EXP_M] =
function(conn,char_id,pkt)
	if pkt==nil then return end

	if char_id ~= nil then
		g_collection_activity_mgr:broadcast_items(pkt)
		return
	end
end

--获取公共服贵重物品列表
Sv_commands[0][CMD_COLLECTION_ACTIVITY_GET_EXP_M] =
function(conn,char_id,pkt)
	if pkt==nil then return end

	if char_id ~= nil then
		local s_pkt = {}
		s_pkt = g_collection_activity_mgr:get_records_info() or {}
		g_server_mgr:send_to_server(conn.id, char_id, CMD_COLLECTION_ACTIVITY_GET_EXP_C, s_pkt)
		return
	end
end

