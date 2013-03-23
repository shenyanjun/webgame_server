
--查看征友信息
Sv_commands[0][CMD_M2P_PET_FRIEND_NET_INFO_C] =
function(conn, char_id, pkt)
	if char_id == nil then return end

	local ret = g_pet_friend_mgr:get_net_info()
	g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_PET_FRIEND_NET_INFO_S, ret)
end

--开始征友或延长时间
Sv_commands[0][CMD_M2P_PET_FRIEND_START_C] =
function(conn, char_id, pkt)
	if char_id == nil then return end
	local pet_friend_container = g_pet_friend_mgr:get_container(char_id)

	local pet_id = pkt[3]
	local time = pkt[7]
	local content = pkt[8]
	--if time < 12 or time > 72 then return end

	local pet = pet_friend_container:get_pet(pet_id)
	if pet == nil then
		if time > 72 or time < 12 then return end
		pet_friend_container:add_pet(pkt)
	else
		local result = pet_friend_container:is_friend_time_ok(pet_id,time)
		if not result then 
			return g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_PET_FRIEND_START_S, {["result"] = 22383}) 
		end
		
		pet_friend_container:add_pet(pkt) 
	end

	g_pet_friend_mgr:serialize_to_db()

	local ret = {}
	ret.result = 0
	ret.data = g_pet_friend_mgr:get_net_info()
	ret.time = time

	g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_PET_FRIEND_START_S, ret)
end

--删除宠物同步
Sv_commands[0][CMD_P2M_PET_FRIEND_DELETE_SYN_C] =
function(conn, char_id, pkt)
	if char_id == nil or pkt == nil then return end

	local pet_friend_container = g_pet_friend_mgr:get_container_ex(char_id)
	if pet_friend_container then
		pet_friend_container:del_pet(pkt.pet_id)
		g_pet_friend_mgr:serialize_to_db()
	end
end

--更新同步技能个数和成长
Sv_commands[0][CMD_M2P_PET_FRIEND_SYN_INFO_C] =
function(conn, char_id, pkt)
	if char_id == nil then return end
	local pet_friend_container = g_pet_friend_mgr:get_container_ex(char_id)
	if pet_friend_container then
		pet_friend_container:update_info(pkt.pet_id,pkt.skill_count,pkt.pullulate)
		--g_pet_friend_mgr:serialize_to_db()
	end
end

