

--激活码领取礼包活动

--local debug_print = print
local debug_print = function() end

--获取激活码领取礼包
Clt_commands[1][CMD_NPC_ACTIACTION_C] =
function(conn, pkt)
	if conn.char_id == nil or pkt.genkey == nil then return end

	--local char_id = conn.char_id
	--local key = pkt.genkey
	--local pkt = {}
	--pkt.result = 0
	--local result,type = Activation_obj:can_be_fetch(char_id,key)
	--if result ~= 0 then
		--pkt.result = result 
		--g_cltsock_mgr:send_client(char_id, CMD_NPC_ACTIACTION_S, pkt)
		--return
	--end
--
	--result = Activation_obj:fetch_item(char_id,key,type)
	--pkt.result = result
	--
	--g_cltsock_mgr:send_client(char_id, CMD_NPC_ACTIACTION_S, pkt)

	local player = g_obj_mgr:get_obj(conn.char_id)
	if not player then return end

	local pack_con = player:get_pack_con()
	if not pack_con then return end

	local free_slot = pack_con:get_bag_free_slot_cnt()
	if free_slot <=0  then
		return g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_ACTIACTION_S, {["result"] = 43004 })
	end

	g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id, CMD_M2P_NPC_ACTIVATION_C, pkt)
end

--
Sv_commands[0][CMD_P2M_NPC_ACTIVATION_S] =
function(conn, char_id, pkt)
	if char_id == nil then return end

	local result = pkt.result

	if result == 0 then
		local player = g_obj_mgr:get_obj(char_id)
		if not player then return end

		local pack_con = player:get_pack_con()
		if not pack_con then return end

		pack_con:add_item_l(pkt.item_id_list, {['type']=ITEM_SOURCE.NOVICE})
	end

	g_cltsock_mgr:send_client(char_id, CMD_NPC_ACTIACTION_S, {["result"] = result })
end



--通知重新load_reward
Sv_commands[0][CMD_B2M_ACTIVE_REWARD_C] =
function(conn, char_id, pkt)
	print("=======CMD_B2M_ACTIVE_REWARD_C")
	--Activation_obj:load_reward()
	g_svsock_mgr:send_server_ex(COMMON_ID,0, CMD_M2P_ACTIVATION_REWARD_C, pkt)
end

