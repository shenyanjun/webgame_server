--查看关卡怪物属性

Sv_commands[0][CMD_M2P_PET_ADVENTURE_ATTR_LIST_C] =
function(conn, char_id, pkt)
	if char_id == nil or pkt == nil then return end

	local barrier_id = pkt.barrier_id

	local pet_barrier = g_pet_barrier_mgr:get_pet_barrier(barrier_id)
	if pet_barrier == nil then 
		--print("Error: there is not any pet_barrier" .. barrier_id)
		return 
	end

	local ret = {}
	ret.barrier_id = barrier_id
	ret.fight = {}

	local barrier_list = pet_barrier:get_barrier_list()
	for k, v in ipairs(barrier_list) do

		local monster = pet_barrier:get_barrier_monster(k)
		if monster == nil then 
			--print("Error: there is not any monster" .. k)
			return 
		end
		
		ret.fight[k] = {}
		for m, n in pairs(monster) do
			local occ = n[1]
			local monster_level = n[2]
			local monster_pullulate = n[3]
			local monster_name = n[4]

			local pet_monster = g_pet_monster_mgr:get_pet_monster(occ)
			if pet_monster == nil then
				--print("Error: there is not the monster, the occ is " .. occ)
				return
			end

			pet_monster:init_all_attr(monster_name, monster_level, monster_pullulate)

			local fight = pet_monster:get_fighting()
			
			table.insert(ret.fight[k],fight)

			pet_monster:clear()
		end
	end

	g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_PET_ADVENTURE_ATTR_LIST_S, ret)

end

--挑战
Sv_commands[0][CMD_M2P_PET_ADVENTURE_FIGHT_C] =
function(conn, char_id, pkt)
	if char_id == nil or pkt == nil then return end

	local barrier_id = pkt.barrier_id
	local level = pkt.level
	local vip = pkt.vip
	if level > 5 then
		level = 5
	end

	local pet_adventure_con = g_pet_adventure_mgr:get_container(char_id)
	if not pet_adventure_con then 
		pet_adventure_con = g_pet_adventure_mgr:create_container(char_id)
	end

	--设置是否vip等加成挑战次数
	pet_adventure_con:set_max_count(vip)

	local result = pet_adventure_con:can_challenge_barrier(barrier_id, level)
	if result ~= 0 then 
		--print("Error: this is not allowed to challenge barrier" .. barrier_id, level)
		g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_PET_ADVENTURE_FIGHT_S, {["result"] = result})
		return
	end

	local pet_barrier = g_pet_barrier_mgr:get_pet_barrier(barrier_id)
	if pet_barrier == nil then 
		--print("Error: there is not any pet_barrier" .. barrier_id)
		return 
	end

	local battle_type = pet_barrier:get_battle_type()

	local monster = pet_barrier:get_barrier_monster(level)
	if monster == nil then 
		--print("Error: there is not any monster" .. level)
		return 
	end

	pet_adventure_con:is_other_day()

	--同步宠物
	local pet_container = pet_adventure_con:get_pet_con()
	if not pet_container then 
		--print("Error: there is no pet_container")
		return 
	end
	pet_container:update_pet_list(pkt.syn_info)

	--宠物出战顺序
	local pet_list = pet_adventure_con:get_real_fight_pet_list()

	local pet_occ_list = {}
	local pet_challenge_list = {}
	local pet_count = 0
	for k, v in pairs(pet_list) do
		if v == 0 or v == nil then
			--table.insert(pet_challenge_list, 0)
			table.insert(pet_occ_list, 0)
			pet_count = pet_count + 1
		else
			local pet_obj = pet_container:get_pet_obj(v)
			if not pet_obj then
				print("Error: there is not pet_obj, id is ".. v)
				table.insert(pet_occ_list, 0)
			else
				table.insert(pet_occ_list, pet_obj:get_occ())
			end
			table.insert(pet_challenge_list, pet_obj or 0)
		end
	end

	if table.size(pet_list) == pet_count then return g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_PET_ADVENTURE_FIGHT_S, {["result"] = 22105}) end

	local challenge_list = {}
	challenge_list[1] = pet_occ_list
	challenge_list[2] = {}
	for i = 1, 6 do
		if monster[i] ~= nil then
			local occ = monster[i][1]
			local monster_obj = g_pet_monster_mgr:get_pet_monster(occ)
			table.insert(challenge_list[2], monster_obj:get_monster_id())
		else
			table.insert(challenge_list[2], 0 )
		end
	end

	local vedio = {}
	local flag = 0
	if battle_type == 1 then  --比分赛
		vedio,flag = g_pet_adventure_mgr:integral_challenge(pet_challenge_list, monster)
	elseif battle_type == 2 then --淘汰赛
		vedio,flag = g_pet_adventure_mgr:eliminate_challenge(pet_challenge_list, monster)
	end

	--奖励
	local reward = {}
	local player_exp = 0 
	local money = 0
	local pet_exp = 0
	local pet_bless = 0
	if flag == 1 then
		local ret = {}
		player_exp,money,pet_exp,reward,pet_bless = g_pet_adventure_mgr:get_reward_item(char_id,barrier_id,level)
		ret.player_exp = player_exp
		ret.money = money
		ret.pet_exp = pet_exp
		ret.reward = reward
		--ret.pet_bless = 0

		g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_PET_ADVENTURE_REWARD_S, ret)

		--local log_str = string.format(" pet_adventure_reward: player_exp=%d money=%d pet_exp=%d, reward='%s', pet_bless=%d, challenge_time=%d ",player_exp,money, pet_exp,Json.Encode(reward),pet_bless,ev.time)
		--g_pet_adventure_log:write(log_str)
	end

	--设置关卡状态
	local lvl_before = pet_adventure_con:get_player_info(barrier_id)
	pet_adventure_con:challenge(barrier_id, level, flag)
	local player_info = {}
	local first_flag = 0
	if flag == 1 then
		local list = pet_adventure_con:set_status(barrier_id)
		player_info = pet_adventure_con:get_change_info(list)

		local lvl_after = pet_adventure_con:get_player_info(barrier_id)
		if lvl_after > lvl_before then
			first_flag = 1
		end
	end

	local new_pkt = {}
	new_pkt.result = 0
	new_pkt.battle_type = battle_type
	new_pkt.player_info = player_info
	new_pkt.vedio = vedio
	new_pkt.count = pet_adventure_con:get_count()
	new_pkt.challenge_list = challenge_list
	new_pkt.max_count = pet_adventure_con:get_max_count()

	local item_list = {}
	for m, n in pairs(reward) do
		for k,v in pairs(n) do
			if v[1] ~= nil and v[1] ~= 0 then
				local item = {v[1],v[2]}
				table.insert(item_list,item)
			end
		end
	end
	new_pkt.reward = item_list
	new_pkt.player_exp = player_exp
	new_pkt.money = money
	new_pkt.pet_exp = pet_exp
	new_pkt.pet_bless = pet_bless
	new_pkt.barrier_id = barrier_id
	new_pkt.level = level
	new_pkt.first_flag = first_flag
	new_pkt.win_flag = flag

	g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_PET_ADVENTURE_FIGHT_S, new_pkt)

	local str = string.format("insert pet_adventure set char_id =%d  ,char_name = '%s', gate_id=%d, gate_name= '%s', type=%d, result=%d, item_reward = '%s', create_time=%d",
							char_id, g_player_mgr.all_player_l[char_id].char_nm, barrier_id,pet_barrier:get_barrier_name(), level,flag,Json.Encode(reward or {}),ev.time)
			g_web_sql:write(str)

end

--保存挑战列表
Sv_commands[0][CMD_M2P_PET_ADVENTURE_SAVE_LIST_C] =
function(conn, char_id, pkt)
	if char_id == nil then return end
	local pet_list = pkt.pet_list

	local pet_adventure_container = g_pet_adventure_mgr:get_container(char_id)
	if not pet_adventure_container then 
		pet_adventure_container = g_pet_adventure_mgr:create_container(char_id)
	end

	pet_adventure_container:set_pet_list(pet_list)

	local ret = {}
	ret.result = 0
	ret.pet_list = pet_adventure_container:get_pet_list()

	g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_PET_ADVENTURE_SAVE_LIST_S, ret)

end

--上线取数据
Sv_commands[0][CMD_M2P_PET_ADVENTURE_ONLINE_C] =
function(conn, char_id, pkt)
	if char_id == nil then return end
	local pet_list = pkt.pet_list
	local vip = pkt.vip

	local pet_adventure_container = g_pet_adventure_mgr:get_container(char_id)
	if not pet_adventure_container then 
		pet_adventure_container = g_pet_adventure_mgr:create_container(char_id)
		pet_adventure_container:set_pet_list(pet_list)
	end

	pet_adventure_container:is_other_day()

	--设置是否vip等加成挑战次数
	pet_adventure_container:set_max_count(vip)
	pet_adventure_container:set_matrix_max_count(vip)

	local ret = {}
	ret.count = pet_adventure_container:get_count()
	ret.player_info = pet_adventure_container:get_net_info()
	ret.pet_list = pet_adventure_container:get_pet_list()
	ret.max_count = pet_adventure_container:get_max_count()
	ret.matrix_data = pet_adventure_container:get_matrix_data()
	ret.matrix_count = pet_adventure_container:get_left_matrix_count()
	ret.strategy = pet_adventure_container:get_strategy_con():get_strategy()

	g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_PET_ADVENTURE_ONLINE_S, ret)

end


---------------------------------设置阵法-------------------------------------------------------------------------------------
--宠物阵法闯关 设置阵法 chendong 120924
--[[
Sv_commands[0][CMD_M2P_PET_ADVENTURE_STRATEGY_C] =
function(conn, char_id, pkt)
	if char_id == nil or pkt == nil then return end

	local pet_adventure_container = g_pet_adventure_mgr:get_container(char_id)
	if not pet_adventure_container then 
		pet_adventure_container = g_pet_adventure_mgr:create_container(char_id)
	end

	local pet_strategy_container = pet_adventure_container:get_strategy_con()
	if not pet_strategy_container then return end

	--同步宠物
	local pet_container = pet_adventure_container:get_pet_con()
	if not pet_container then return end

	pet_container:update_pet_list(pkt.syn_info)
	pet_strategy_container:reset_pet(pkt.strategy)

	local ret = {}
	ret.strategy = pet_strategy_container:get_strategy()
	ret.result = 0

	g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_PET_ADVENTURE_STRATEGY_S, ret)
end
--]]

--宠物阵法闯关 阵法挑战 chendong 120924
--[[
--阵法挑战
Sv_commands[0][CMD_M2P_PET_ADVENTURE_MATRIX_CHALLENGE_C] =
function(conn, char_id, pkt)
	if char_id == nil or pkt.barrier_id == nil or pkt.level == nil then return end
	local pet_adventure_container = g_pet_adventure_mgr:get_container(char_id)
	if not pet_adventure_container then 
		pet_adventure_container = g_pet_adventure_mgr:create_container(char_id)
	end

	pet_adventure_container:is_other_day()
	--设置是否vip等加成挑战次数
	pet_adventure_container:set_matrix_max_count(pkt.vip)

	local result = pet_adventure_container:can_matrix_challenge(pkt.barrier_id, pkt.level)
	if result ~= 0 then
		return g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_PET_ADVENTURE_MATRIX_CHALLENGE_S, {["result"] = result})
	end

	local pet_strategy_container = pet_adventure_container:get_strategy_con()
	if not pet_strategy_container then return end

	--同步宠物
	local pet_container = pet_adventure_container:get_pet_con()
	if not pet_container then return end

	local pet_matrix_barrier = g_pet_matrix_barrier_mgr:get_pet_barrier(pkt.barrier_id)
	if pet_matrix_barrier == nil then 
		return 
	end

	pet_container:update_pet_list(pkt.syn_info)

	local strategy_con_d = pet_matrix_barrier:get_strategy(pkt.level)
	pet_strategy_container:init_set()

	local result, vedio = g_pet_adventure_mgr:matrix_challenge(pet_strategy_container, strategy_con_d)
	if result ~= 0 then
		return g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_PET_ADVENTURE_MATRIX_CHALLENGE_S, {["result"] = result})
	end

	local item_reward = {}
	if vedio[2][1] == 1 then
		local flag = pet_adventure_container:matrix_change(pkt.barrier_id, pkt.level)
		local ret = {}
		local player_exp,money,pet_exp,reward,pet_bless = g_pet_adventure_mgr:get_reward_item2(char_id,pkt.barrier_id,pkt.level)
		vedio[2][2] = pet_adventure_container:get_left_matrix_count()
		vedio[2][3] = pet_exp
		item_reward = reward
		local item_list = {}
		for m, n in pairs(reward) do
			for k,v in pairs(n) do
				if v[1] ~= nil and v[1] ~= 0 then
					local item = {v[1],v[2]}
					table.insert(item_list,item)
				end
			end
		end
		vedio[2][4] = item_list
		vedio[2][5] = flag
		vedio[2][6] = {pkt.barrier_id, pkt.level}
	else
		vedio[2][2] = pet_adventure_container:get_left_matrix_count()
		vedio[2][3] = 0
		vedio[2][4] = {}
		vedio[2][5] = 0
		vedio[2][6] = {pkt.barrier_id, pkt.level}
	end

	local ret = {}
	ret.vedio = vedio
	ret.result = 0
	ret.matrix_data = pet_adventure_container:get_matrix_data()
	ret.matrix_count = pet_adventure_container:get_left_matrix_count()

	g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_PET_ADVENTURE_MATRIX_CHALLENGE_S, ret)

	local flag = 1
	if vedio[2][1] == 1 then
		flag = 1
	else
		flag = 0
	end
	local str = string.format("insert pet_adventure set char_id =%d  ,char_name = '%s', gate_id=%d, gate_name= '%s', type=%d, result=%d, item_reward = '%s', create_time=%d, adventure_type =%d",
							char_id, g_player_mgr.all_player_l[char_id].char_nm, pkt.barrier_id,pet_matrix_barrier:get_barrier_name(), pkt.level,flag,Json.Encode(item_reward or {}),ev.time,2)
			g_web_sql:write(str)
end
--]]

--怪物信息
Sv_commands[0][CMD_M2P_PET_ADVENTURE_MATRIX_MONSTER_C] =
function(conn, char_id, pkt)
	if char_id == nil or pkt == nil then return end
	local barrier_id = pkt.barrier_id

	local pet_barrier = g_pet_matrix_barrier_mgr:get_pet_barrier(barrier_id)
	if pet_barrier == nil then 
		--print("Error: there is not any pet_barrier" .. barrier_id)
		return 
	end

	local ret = {}
	ret.barrier_id = barrier_id
	ret.fight = {}
	local barrier_list = pet_barrier:get_barrier_list()
	for k, v in ipairs(barrier_list) do

		local monster = pet_barrier:get_barrier_monster(k)
		if monster == nil then 
			--print("Error: there is not any monster" .. k)
			return 
		end
		
		ret.fight[k] = {}
		for m, n in pairs(monster) do
			local occ = n[1]
			local monster_level = n[2]
			local monster_pullulate = n[3]
			local monster_name = n[4]
			local pack = {n[6], n[7], n[8], n[9]}

			local pet_monster = g_pet_monster_mgr:get_pet_monster(occ)
			if pet_monster == nil then
				--print("Error: there is not the monster, the occ is " .. occ)
				return
			end

			pet_monster:init_matrix_attr(monster_name, monster_level, monster_pullulate, pack)

			local fight = pet_monster:get_fighting()
			
			table.insert(ret.fight[k],fight)

			pet_monster:clear()
		end
	end

	g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_PET_ADVENTURE_MATRIX_MONSTER_S, ret)
end

--宠物阵法闯关 增加闯关次数 chendong 120924
--[[
--增加次数
Sv_commands[0][CMD_M2P_PET_ADVENTURE_MATRIX_ADD_COUNT_C] =
function(conn, char_id, pkt)
	local pet_adventure_container = g_pet_adventure_mgr:get_container(char_id)
	if not pet_adventure_container then 
		pet_adventure_container = g_pet_adventure_mgr:create_container(char_id)
	end
	
	g_pet_adventure_mgr:add_count(char_id)
end
--]]