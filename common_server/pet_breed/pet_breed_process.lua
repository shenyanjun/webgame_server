
--配偶关系同步
Sv_commands[0][CMD_M2P_PET_BREED_SYN_C] =
function(conn, char_id, pkt)
	if char_id == nil then return end

	local flag = pkt.flag
	local list = pkt.list

	if flag == 1 then  --添加配偶关系
		g_pet_breed_syn_mgr:add_spouse_id(list[1],list[2])
	elseif flag == 2 then --减去配偶关系
		g_pet_breed_syn_mgr:del_spouse_id(list[1])
	end

	local syn_info = g_pet_breed_syn_mgr:get_breed_info()
	g_server_mgr:send_to_all_map(0,CMD_P2M_PET_BREED_SYN_S,Json.Encode(syn_info), true)

end

--开始繁殖
Sv_commands[0][CMD_M2P_PET_BREED_START_C] = 
function(conn, char_id, pkt)
	if char_id == nil or pkt == nil then return end

	local spouse_list = pkt.spouse_list   --配偶关系列表
	local breed_list = pkt.breed_list	--主人添加的宠物蛋列表

	--g_pet_breed_syn_mgr:add_spouse_id(spouse_list[1],spouse_list[2]) --spouse_id_s, spouse_id_d
	--local syn_info = g_pet_breed_syn_mgr:get_breed_info()

	local ret = {}
	for k,v in pairs(breed_list or {}) do
		local container = g_pet_breed_mgr:get_container(v[1]) --char_id
		if not container then 
			container = g_pet_breed_mgr:create_container(v[1])
		end
		container:add_breed(v[2],v[3],v[4],v[5],v[6],v[7])  -- occ, bind ,time, attr_sum,skill_percent,count（特殊技能个数）
		table.insert(ret, container:get_breed_list())
	end

	g_server_mgr:send_to_server(conn.id,0, CMD_P2M_PET_BREED_START_S, pkt)

	--g_server_mgr:send_to_all_map(0,CMD_P2M_PET_BREED_SYN_S,syn_info)

	g_server_mgr:send_to_all_map(0,CMD_P2M_PET_BREED_SINGLE_SYN_S,Json.Encode(ret),true)


	local str = ev.time .. " pet_breed " .. Json.Encode(breed_list)
	g_pet_breed_log:write(str)

end

--系统繁殖
Sv_commands[0][CMD_M2P_PET_BREED_SYS_START_C] = 
function(conn, char_id, pkt)
	if char_id == nil or pkt == nil then return end
	local breed_list = pkt.breed_list	--主人添加的宠物蛋列表

	local ret = {}
	for k,v in pairs(breed_list or {}) do
		local container = g_pet_breed_mgr:get_container(v[1]) --char_id
		if not container then 
			container = g_pet_breed_mgr:create_container(v[1])
		end
		container:add_breed(v[2],v[3],v[4],v[5],v[6],v[7])  -- occ, bind ,time, attr_sum,skill_percent,count（特殊技能个数）
		table.insert(ret, container:get_breed_list())
	end

	g_server_mgr:send_to_server(conn.id,0, CMD_P2M_PET_BREED_SYS_START_S, pkt)

	g_server_mgr:send_to_all_map(0,CMD_P2M_PET_BREED_SINGLE_SYN_S,Json.Encode(ret),true)


	local str = ev.time .. " pet_sys_breed " .. Json.Encode(breed_list)
	g_pet_breed_log:write(str)

end


--领取宠物蛋
Sv_commands[0][CMD_M2P_PET_BREED_FETCH_C] =
function(conn, char_id, pkt)
	if char_id == nil then return end
	local container = g_pet_breed_mgr:get_container(char_id)
	if not container then 
		print("warning: there is no container")
		return 
	end

	local new_pkt = {}
	new_pkt.breed_list = container:del_breed()
	new_pkt.result = 0
	g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_PET_BREED_FETCH_S, new_pkt)

	local syn_info = container:get_breed_list()
	local ret = {}
	table.insert(ret, syn_info)
	g_server_mgr:send_to_all_map(0,CMD_P2M_PET_BREED_SINGLE_SYN_S,Json.Encode(ret),true)

	local str = ev.time .. " pet_breed " .. " char_id" .. char_id .." del_breed:" .. Json.Encode(new_pkt) .. " left_breed:" .. Json.Encode(ret)
	g_pet_breed_log:write(str)
end