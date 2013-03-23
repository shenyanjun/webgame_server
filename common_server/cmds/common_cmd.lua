
--与map的交互
--pkt.type 1改人名；2改帮派名；3改职业；4变性
Sv_commands[0][CMD_M2C_CHANGENAME_ITEM_M] =
function(conn,char_id,pkt)
	if not pkt or not pkt.type or not pkt.char_id then return end

	if pkt.type == 1 and pkt.name then
		g_player_mgr:change_name(pkt.char_id, pkt.name)
		g_faction_mgr:change_player_name(pkt.char_id, pkt.name)

		--给world发改人名
		g_svsock_mgr:send_server_ex(WORLD_ID, pkt.char_id, CMD_C2W_CHANGENAME_ITEM_C, pkt)

		--给chat发
		g_svsock_mgr:send_server_ex(WORLD_ID, pkt.char_id, CMD_C2CH_CHANGENAME_ITEM_C, pkt)
	end

	--帮派改名
	if pkt.type == 2 and pkt.name then
		g_faction_mgr:change_name(pkt.char_id,pkt.name)
	end

	--改职业
	if pkt.type == 3 and pkt.class then
		g_player_mgr:change_occ(pkt.char_id, pkt.class)
		g_faction_mgr:change_player_occ(pkt.char_id, pkt.class)

		g_svsock_mgr:send_server_ex(WORLD_ID, pkt.char_id, CMD_C2W_CHANGENAME_ITEM_C, pkt)
		g_svsock_mgr:send_server_ex(WORLD_ID, pkt.char_id, CMD_C2CH_CHANGENAME_ITEM_C, pkt)
	end
	
	--变性
	if pkt.type == 4 and pkt.gender then
		g_player_mgr:change_gender(pkt.char_id, pkt.gender)
		g_faction_mgr:change_player_gender(pkt.char_id, pkt.gender)

		g_svsock_mgr:send_server_ex(WORLD_ID, pkt.char_id, CMD_C2W_CHANGENAME_ITEM_C, pkt)
		g_svsock_mgr:send_server_ex(WORLD_ID, pkt.char_id, CMD_C2CH_CHANGENAME_ITEM_C, pkt)		
	end
end

----------------------------老玩家回归拥抱----------------------
local regression_list = {}
local embrace_cnt = 20

Sv_commands[0][CMD_OLDPLAYER_REGRESSION_M] =
function(conn,char_id,pkt)
	if not pkt or not pkt.char_id then return end

	--if regression_list[pkt.char_id] then return end
	
	regression_list[pkt.char_id] = {}

	local s_pkt = {}
	s_pkt.char_id = pkt.char_id
	s_pkt.char_name = g_player_mgr.all_player_l[pkt.char_id]["char_nm"]
	local tmp = Json.Encode(s_pkt)
	for k , v in pairs(g_player_mgr.online_player_l) do
		g_svsock_mgr:send_server_ex(WORLD_ID, k, CMD_REGRESSION_BROADCAST_W, tmp, true)
	end
end

Sv_commands[0][CMD_REGRESSION_EMBRACE_M] =
function(conn,char_id,pkt)
	if not pkt or not pkt.char_id or not pkt.embrace_id then return end
	local s_pkt = {}
	s_pkt.char_id = pkt.char_id

	if not regression_list[pkt.embrace_id] then 
		s_pkt.result  = 20776
		s_pkt.type = 2
		g_server_mgr:send_to_server(conn.id,char_id, CMD_REGRESSION_EMBRACE_C,s_pkt)
		return 
	end
	
	local flags = true
	local counts = table.getn(regression_list[pkt.embrace_id])
	if counts < embrace_cnt then
		for i = 1, counts do
			if regression_list[pkt.embrace_id][i] == pkt.char_id then
				s_pkt.result  = 20777
				g_server_mgr:send_to_server(conn.id,char_id, CMD_REGRESSION_EMBRACE_C,s_pkt)
				return
			end
		end
		
		local t_pkt = {}
		local target_player =  g_player_mgr.all_player_l[pkt.char_id]
		t_pkt.char_name = target_player.char_nm
		t_pkt.char_id = pkt.char_id
		t_pkt.lineid = g_player_mgr:get_char_line(pkt.char_id) or 0
		t_pkt.vip =	 g_vip_play_inf:get_vip_type(pkt.char_id)
		t_pkt.gender = target_player.gender
		t_pkt.occ =  target_player.occ
		t_pkt.level =  target_player.level
		g_svsock_mgr:send_server_ex(WORLD_ID, pkt.embrace_id, CMD_CON_REGRESSION_W, t_pkt)

		table.insert(regression_list[pkt.embrace_id], pkt.char_id)
		counts = counts + 1		
		s_pkt.result  = 0
		s_pkt.type = 2
		g_server_mgr:send_to_server(conn.id, char_id, CMD_REGRESSION_EMBRACE_C,s_pkt)

		--被抱也加经验
		local new_pkt = {}
		new_pkt.result = 0
		new_pkt.char_id = pkt.embrace_id
		new_pkt.type = 1
		g_server_mgr:send_to_all_map(0,CMD_REGRESSION_EMBRACE_C,new_pkt)
		flags = false
	end



	if counts >= embrace_cnt then
		local t_pkt = {}
		t_pkt.embrace_id = pkt.embrace_id
		local tmp = Json.Encode(t_pkt)
		for k , v in pairs(g_player_mgr.online_player_l) do
			g_svsock_mgr:send_server_ex(WORLD_ID, k, CMD_REGRESSION_BROADCAST_W, tmp, true)
		end
		regression_list[pkt.embrace_id] = nil
	end
	
	if flags then
		s_pkt.result  = 20776
		g_server_mgr:send_to_server(conn.id,char_id, CMD_REGRESSION_EMBRACE_C,s_pkt)
	end

	return
end

-----------------------------------送花功能------
----查询是否在线
Sv_commands[0][CMD_FLOWER_CHECK_ON_LINE_M] =
function(conn,char_id,pkt)
	if not pkt or not pkt.sender or not pkt.receiver then return end

	if g_player_mgr:is_online_char(pkt.receiver) then	--在线  加入所在线信息
		local line = g_player_mgr:get_char_line(pkt.receiver)
		pkt.line = line
		--pkt.receiver_n = g_player_mgr:char_id2nm(pkt.receiver)
		pkt.result = 0

		--g_server_mgr:send_to_server(conn.id, char_id, CMD_C2M_REQUEST_HUMAN_ATTR_ACK, pkt) 
	else
		pkt.result = 10019
	end

	g_server_mgr:send_to_server(conn.id, char_id, CMD_FLOWER_CHECK_ON_LINE_C, pkt)
end

----送花过程中的中转
Sv_commands[0][CMD_FLOWER_PRE_SEND_M] =
function(conn,char_id,pkt)
	if not pkt or not pkt.sender or not pkt.receiver then return end

	if g_player_mgr:is_online_char(pkt.receiver) then	--在线  刷新所在线信息
		local line = g_player_mgr:get_char_line(pkt.receiver)
		pkt.line = line
		pkt.sender_l = conn.id
		g_server_mgr:send_to_server(line, char_id, CMD_FLOWER_SEND_C, pkt) 
	else
		pkt.result = 10019
		g_server_mgr:send_to_server(conn.id, char_id, CMD_FLOWER_SEND_READY_C, pkt)
	end

	return
end

----送完花后的总结
Sv_commands[0][CMD_FLOWER_SEND_M] =
function(conn,char_id,pkt)
	if not pkt or not pkt.sender or not pkt.receiver then return end

	g_server_mgr:send_to_server(pkt.sender_l, char_id, CMD_FLOWER_SEND_READY_C, pkt)

	return
end

assert(Sv_commands[0][CMD_M2C_FORBID_SAY] == nil )
Sv_commands[0][CMD_M2C_FORBID_SAY] =
function(conn,char_id,pkt)
	--pkt.map_line = conn.id
	--pkt.char_id= char_id
	assert(conn.id)
	g_svsock_mgr:send_server_ex(WORLD_ID,char_id,CMD_C2W_FORBID_SAY,pkt)
	
	return
end

assert(Sv_commands[1][CMD_W2C_FORBID_SAY] == nil)
Sv_commands[1][CMD_W2C_FORBID_SAY] =
function(conn,char_id,pkt)
	local line = g_player_mgr:get_char_line(pkt.char_id)
	--g_server_mgr:send_to_server(pkt.map_line,pkt.char_id,CMD_C2M_FORBID_SAY,pkt)
	g_server_mgr:send_to_server(line,pkt.char_id,CMD_C2M_FORBID_SAY,pkt)
	return
end

----挖宝
Sv_commands[0][CMD_M2C_TREASURE_BROADCAST_M] =
function(conn,char_id,pkt)
	if not pkt or not pkt.type then return end
	local player_mgr = g_player_mgr
	local online_l = player_mgr:get_online_player()
	for k,v in pairs(online_l or {}) do
		local line = player_mgr:get_char_line(k)
		if line then
			g_server_mgr:send_to_server(line, k, CMD_C2M_TREASURE_BROADCAST_C, pkt)
		end
	end
end
