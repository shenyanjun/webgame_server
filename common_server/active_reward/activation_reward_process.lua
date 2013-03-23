
--获取激活码礼包
Sv_commands[0][CMD_M2P_NPC_ACTIVATION_C] =
function(conn, char_id, pkt)
	if char_id == nil or pkt.genkey == nil then return end

	local key = pkt.genkey
	local pkt = {}
	pkt.result = 0
	local result,type = Activation_obj:can_be_fetch(char_id,key)
	if result ~= 0 then
		pkt.result = result 
		g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_NPC_ACTIVATION_S, pkt)
		return
	end

	result,item_id_list = Activation_obj:fetch_item(char_id,key,type)
	pkt.result = result
	pkt.item_id_list = item_id_list
	
	g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_NPC_ACTIVATION_S, pkt)
end

--重新加载reward
Sv_commands[0][CMD_G2C_ACTIVATION_REWARD_C] =
function(conn, char_id, pkt)
	Activation_obj:load_key()
	Activation_obj:load_reward()
end