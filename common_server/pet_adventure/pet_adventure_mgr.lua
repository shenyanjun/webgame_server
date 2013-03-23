local pet_adventure_reward_loader = require("pet_adventure.pet_adventure_reward_loader")

Pet_adventure_mgr = oo.class(nil, "Pet_adventure")

function Pet_adventure_mgr:__init()
	self.container_list = {}
end

function Pet_adventure_mgr:get_container(char_id)
	return self.container_list[char_id]
end

function Pet_adventure_mgr:set_container(container)
	local char_id = container:get_char_id()
	self.container_list[char_id] = container
end

function Pet_adventure_mgr:create_container(char_id)
	local pet_adventure_con = Pet_adventure_container(char_id)
	pet_adventure_con:load_player()

	self:set_container(pet_adventure_con)
	return pet_adventure_con
end

function Pet_adventure_mgr:update_container(char_id)
	if self.container_list[char_id] ~= nil then
		self.container_list[char_id]:update_player()
	end
end

function Pet_adventure_mgr:can_get_reward(char_id,barrier_id, level)
	local pet_adventure_con = self:get_container(char_id)
	if not pet_adventure_con then return end

	local challenge_level = pet_adventure_con:get_challenge_level(barrier_id)
	if level > challenge_level  then
		return true
	end 

	return false

end

function Pet_adventure_mgr:get_reward_item(char_id,barrier_id,level)
	local pet_barrier = g_pet_barrier_mgr:get_pet_barrier(barrier_id)
	if not pet_barrier then return end

	local barrier_level = pet_barrier:get_barrier_by_level(level)

	local player_exp = barrier_level.reward[2] or 0
	local money = barrier_level.reward[3] or 0
	local pet_exp = barrier_level.reward[4] or 0
	local reward_id = barrier_level.reward[5] or 0
	local pet_bless = barrier_level.reward[6] or 0

	local reward = pet_adventure_reward_loader.item_list[reward_id]

	local pet_adventure_con = self:get_container(char_id)
	if not pet_adventure_con then return end

	local challenge_level = pet_adventure_con:get_challenge_level(barrier_id)
	if level <= challenge_level  then
		local ret_reward = {}
		for k, v in pairs(reward or {}) do
			local item_list = v.item_list
			local item = f_random_wave(v.item, item_list[1])
			table.insert(ret_reward,item)
		end

		return player_exp, money, pet_exp, ret_reward, pet_bless
	else   --第一次闯关 宠物经验为配置3倍 空权值除以2
		local ret_reward = {}
		for k, v in pairs(reward or {}) do
			local item_list = v.item_list
			local item = {}
			for m, n in pairs(v.item) do
				if n[1] ~= 0 then
					table.insert(item,n)
				else
					local ret = {}
					ret[1] = 0
					ret[2] = 0
					ret[3] = math.ceil(n[3] / 2)
					table.insert(item,ret)
				end
			end
			local item_l = f_random_wave(item, item_list[1])
			table.insert(ret_reward,item_l)
		end

		return player_exp, money, pet_exp*3, ret_reward, pet_bless
	end 

end

function Pet_adventure_mgr:get_reward_item2(char_id,barrier_id,level)
	local pet_barrier = g_pet_matrix_barrier_mgr:get_pet_barrier(barrier_id)
	if not pet_barrier then return end

	local barrier_level = pet_barrier:get_barrier_by_level(level)

	local player_exp = barrier_level.reward[2] or 0
	local money = barrier_level.reward[3] or 0
	local pet_exp = barrier_level.reward[4] or 0
	local reward_id = barrier_level.reward[5] or 0
	local pet_bless = barrier_level.reward[6] or 0

	local reward = pet_adventure_reward_loader.item_list[reward_id]

	local pet_adventure_con = self:get_container(char_id)
	if not pet_adventure_con then return end

	local challenge_level = pet_adventure_con:get_challenge_level2(barrier_id)
	if level <= challenge_level  then
		local ret_reward = {}
		for k, v in pairs(reward or {}) do
			local item_list = v.item_list
			local item = f_random_wave(v.item, item_list[1])
			table.insert(ret_reward,item)
		end

		return player_exp, money, pet_exp, ret_reward, pet_bless
	else   --第一次闯关 宠物经验为配置3倍 空权值除以2
		local ret_reward = {}
		for k, v in pairs(reward or {}) do
			local item_list = v.item_list
			local item = {}
			for m, n in pairs(v.item) do
				if n[1] ~= 0 then
					table.insert(item,n)
				else
					local ret = {}
					ret[1] = 0
					ret[2] = 0
					ret[3] = math.ceil(n[3] / 2)
					table.insert(item,ret)
				end
			end
			local item_l = f_random_wave(item, item_list[1])
			table.insert(ret_reward,item_l)
		end

		return player_exp, money, pet_exp*3, ret_reward, pet_bless
	end 

end

--淘汰赛
function Pet_adventure_mgr:eliminate_challenge(pet_list, monster_list)
	local pet_size = table.size(pet_list)
	local monster_size = table.size(monster_list)
	
	local vedio = {}
	local size = pet_size + monster_size
	--if pet_size < monster_size then
		--size = monster_size
	--end
	local pet_flag = 1   --标志宠物到哪一只
	local monster_flag = 1 --标志怪物到哪一只
	local win_flag = 0

	local per_flag = 0   --标志每场打斗谁胜利  1为宠物胜利 2为怪物胜利

	local monster_obj = nil

	for k = 1, size  do
		local pet_obj = pet_list[pet_flag]
		local monster_obj_attr = monster_list[monster_flag]		

		if pet_obj == 0 or pet_obj == nil then
			return vedio, 0
		end

		if monster_obj_attr == nil then
			return vedio, 1
		end

		if per_flag == 1 or per_flag == 0 then
			local occ = monster_obj_attr[1]
			local monster_level = monster_obj_attr[2]
			local monster_pullulate = monster_obj_attr[3]
			local monster_name = monster_obj_attr[4]

			monster_obj = g_pet_monster_mgr:get_pet_monster(occ)
			if monster_obj == nil then
				print("Error: there is not the monster, the occ is " .. occ)
				return
			end

			monster_obj:init_all_attr(monster_name, monster_level, monster_pullulate)
		end

		local pet_attr = {}
		local monster_attr = {}

		if monster_obj ~= 0 and monster_obj ~= nil then
			monster_attr = monster_obj:get_all_att_ex()
		end

		if pet_obj ~= 0 and pet_obj ~= nil then
			pet_attr = pet_obj:get_all_att_ex()
		end

		vedio[k] = {}
		vedio[k][1] = {}
		vedio[k][1][1] = pet_attr
		vedio[k][1][2] = monster_attr
		vedio[k][2] = {}
		vedio[k][3] = {}

		if pet_obj ~= 0 and monster_obj ~= nil then
			local skill_con_pet = pet_obj:get_skill_con()
			local skill_con_monster = monster_obj:get_skill_con()

			skill_con_pet:sub_all_cd()
			skill_con_monster:sub_all_cd()
			
			local flag = 0
			if pet_obj:get_dexterity_t() >= monster_obj:get_dexterity_t() then
				local skill_id, hp, addition_hp = skill_con_pet:use(pet_obj,monster_obj)
				vedio[k][3][1] ={}
				vedio[k][3][1][1]= skill_id
				vedio[k][3][1][2]= hp
				vedio[k][3][1][3]= {pet_obj:get_hp(), monster_obj:get_hp(),addition_hp}
				vedio[k][3][1][4]= 1

				flag =1
			else
				local skill_id, hp,addition_hp = skill_con_monster:use(monster_obj,pet_obj)
				vedio[k][3][1] ={}
				vedio[k][3][1][1]= skill_id
				vedio[k][3][1][2]= hp
				vedio[k][3][1][3]= {pet_obj:get_hp(), monster_obj:get_hp(),addition_hp}
				vedio[k][3][1][4]= 2

				flag =2
			end

			local index = 1
			local count = 0
			while pet_obj:get_hp() >0 and monster_obj:get_hp() >0 do
				if count <= 100 then
					index = index + 1
					if flag == 1 then
						local skill_id, hp, addition_hp = skill_con_monster:use(monster_obj,pet_obj)
						flag = 2

						vedio[k][3][index] ={}
						vedio[k][3][index][1]= skill_id
						vedio[k][3][index][2]= hp
						vedio[k][3][index][3]= {pet_obj:get_hp(), monster_obj:get_hp(),addition_hp}
						vedio[k][3][index][4]= 2
					elseif flag == 2 then
						local skill_id, hp, addition_hp = skill_con_pet:use(pet_obj,monster_obj)
						flag = 1

						vedio[k][3][index] ={}
						vedio[k][3][index][1]= skill_id
						vedio[k][3][index][2]= hp
						vedio[k][3][index][3]= {pet_obj:get_hp(), monster_obj:get_hp(), addition_hp}
						vedio[k][3][index][4]= 1
					end
					count = count + 1
				else
					break
				end
			end

			local pet_hp = pet_obj:get_hp()
			local monster_hp = monster_obj:get_hp()

			if pet_hp >= monster_hp then
				vedio[k][2][1] = 1
				vedio[k][2][2] = 1
				monster_flag = monster_flag + 1
				win_flag = win_flag + 1
				per_flag = 1
			else
				vedio[k][2][1] = 2
				vedio[k][2][2] = 2
				pet_flag = pet_flag + 1
				per_flag = 2
			end
		end

	end
	local flag = 0   --标志胜负 0 为宠物负 1为胜
	if win_flag >= size then
		flag = 1
	end

	return vedio, flag

end

--积分赛
function Pet_adventure_mgr:integral_challenge(pet_list, monster_list)
	local monster_size = table.size(monster_list)
	
	local vedio = {}

	for k = 1, monster_size do
		local pet_obj = pet_list[k]
		local monster_obj = monster_list[k]

		local pet_obj_attr = {}
		local monster_obj_attr = {}
		if pet_obj ~= 0 and pet_obj ~= nil then
			pet_obj_attr = pet_obj:get_all_att_ex()
		end

		if monster_obj ~= 0 and monster_obj ~=nil then
			monster_obj_attr = monster_obj:get_all_att_ex()
		end

		vedio[k] = {}
		vedio[k][1] = {}
		vedio[k][1][1] = pet_obj_attr
		vedio[k][1][2] = monster_obj_attr
		vedio[k][2] = {}
		vedio[k][3] = {}

		if pet_obj ~= 0 and monster_obj ~= nil then
			local pet_skill_con = pet_obj:get_skill_con()
			local monster_skill_con = monster_obj:get_skill_con()

			pet_skill_con:sub_all_cd()
			monster_skill_con:sub_all_cd()

			local flag = 0
			if pet_obj:get_dexterity_t() >= monster_obj:get_dexterity_t() then
				local skill_id, hp = pet_skill_con:use(pet_obj,monster_obj)
				vedio[k][3][1] ={}
				vedio[k][3][1][1]= skill_id
				vedio[k][3][1][2]= hp
				vedio[k][3][1][3]= {pet_obj:get_hp(), monster_obj:get_hp()}
				vedio[k][3][1][4]= 1

				flag = 1
			else
				local skill_id, hp = monster_skill_con:use(monster_obj,pet_obj)
				vedio[k][3][1] ={}
				vedio[k][3][1][1]= skill_id
				vedio[k][3][1][2]= hp
				vedio[k][3][1][3]= {pet_obj:get_hp(), monster_obj:get_hp()}
				vedio[k][3][1][4]= 2

				flag = 2
			end

			local index = 1
			local count = 0
			while pet_obj:get_hp() >0 and monster_obj:get_hp() >0 do
				if count <= 20 then
					index = index + 1
					if flag == 1 then
						local skill_id, hp = monster_skill_con:use(monster_obj,pet_obj)
						flag = 2

						vedio[k][3][index] ={}
						vedio[k][3][index][1]= skill_id
						vedio[k][3][index][2]= hp
						vedio[k][3][index][3]= {pet_obj:get_hp(), monster_obj:get_hp()}
						vedio[k][3][index][4]= 2
					elseif flag == 2 then
						local skill_id, hp = pet_skill_con:use(pet_obj,monster_obj)
						flag = 1
						vedio[k][3][index] ={}
						vedio[k][3][index][1]= skill_id
						vedio[k][3][index][2]= hp
						vedio[k][3][index][3]= {pet_obj:get_hp(), monster_obj:get_hp()}
						vedio[k][3][index][4]= 1
					end
					count = count + 1
				else
					break
				end
			end

			local pet_hp = pet_obj:get_hp()
			local monster_hp = monster_obj:get_hp()

			if pet_hp >= monster then
				vedio[k][2][1] = 1
			else
				vedio[k][2][1] = 2
			end
		end
	end
	return vedio
end

--阵法闯关
function Pet_adventure_mgr:matrix_challenge(strategy_con_s, strategy_con_d)
	local attr_s = strategy_con_s:get_pet_attr()
	local attr_d = strategy_con_d:get_pet_attr()

	local vedio = {}
	vedio[1] = {attr_s, attr_d}
	vedio[2] = {1}
	vedio[3] = {}

	local pet_s_flag = 1
	local pet_d_flag = 1
	local flag = 1
	local huihe = 0
	local s_size = strategy_con_s:get_pet_count()
	if s_size == 0 then
		--local line = g_player_mgr:get_char_line(self.obj_id) 
		return 20917, vedio--g_server_mgr:send_to_server(line, self.obj_id, CMD_P2M_PET_ADVENTURE_MATRIX_CHALLENGE_S, {["result"]=20917})
	end

	while true do
		if flag == 1 then
			local pet_obj_s = nil
			local index = 1
			for i = pet_s_flag, 9 do
				local pet_obj = strategy_con_s:get_pet(i)
				if pet_obj and pet_obj:get_hp() > 0 then
					pet_obj_s = pet_obj
					index = i
					if i == 9 then
						pet_s_flag = 1
					else
						pet_s_flag = i + 1
					end
					break
				end
			end

			if pet_obj_s == nil then
				for i = 1, pet_s_flag do
					local pet_obj = strategy_con_s:get_pet(i)
					if pet_obj and pet_obj:get_hp() > 0 then
						pet_obj_s = pet_obj
						index = i
						if i == 9 then
							pet_s_flag = 1
						else
							pet_s_flag = i + 1
						end

						huihe = huihe + 1
						strategy_con_s:sud_all_cd()
						strategy_con_d:sud_all_cd()
						break
					end
				end
			else
				if s_size == 1 then
					huihe = huihe + 1
					strategy_con_s:sud_all_cd()
					strategy_con_d:sud_all_cd()
				end
			end

			if pet_obj_s == nil then
				break
			end

			local skill_con = pet_obj_s:get_skill_con()
			local skill_id, info,dead_info, addition_hp = skill_con:use_ex(pet_obj_s, strategy_con_s, strategy_con_d, index)
			local attr_s, attr_s_2 = strategy_con_s:get_pet_attr()
			local attr_d, attr_d_2 = strategy_con_d:get_pet_attr()

			local table_s = {flag, index, skill_id, info, {attr_s_2, attr_d_2}}
			if pet_obj_s:get_hp() > 0 then
				table_s[6] = {{},dead_info}
			else
				table_s[6] = {{index},dead_info}
			end
			table_s[7] = addition_hp
			table.insert(vedio[3], table_s)

			local size_s = table.size(attr_s)
			local size_d = table.size(attr_d)
			if size_d == 0 then
				vedio[2][1] = 1
				break
			elseif size_s == 0 then
				vedio[2][1] = 2
				break
			end

			flag = 2
		else
			local pet_obj_d = nil
			local index = 1
			for i = pet_d_flag, 9 do
				local pet_obj = strategy_con_d:get_pet(i)
				if pet_obj and pet_obj:get_hp() > 0 then
					pet_obj_d = pet_obj
					index = i
					if i == 9 then
						pet_d_flag = 1
					else
						pet_d_flag = i + 1
					end
					break
				end
			end

			if pet_obj_d == nil then
				for i = 1, pet_d_flag do
					local pet_obj = strategy_con_d:get_pet(i)
					if pet_obj and pet_obj:get_hp() > 0 then
						pet_obj_d = pet_obj
						index = i
						if i == 9 then
							pet_d_flag = 1
						else
							pet_d_flag = i + 1
						end
						break
					end
				end
			end

			if pet_obj_d == nil then
				break
			end

			local skill_con = pet_obj_d:get_skill_con()
			local skill_id, info,dead_info, addition_hp = skill_con:use_ex(pet_obj_d, strategy_con_d, strategy_con_s, index)
			local attr_s, attr_s_2 = strategy_con_s:get_pet_attr()
			local attr_d, attr_d_2 = strategy_con_d:get_pet_attr()

			local table_s = {flag, index, skill_id, info, {attr_s_2, attr_d_2}}
			if pet_obj_d:get_hp() > 0 then
				table_s[6] = {dead_info, {}}
			else
				table_s[6] = {dead_info,{index}}
			end
			table_s[7] = addition_hp
			table.insert(vedio[3], table_s)

			local size_s = table.size(attr_s)
			local size_d = table.size(attr_d)
			if size_d == 0 then
				vedio[2][1] = 1
				break
			elseif size_s == 0 then
				vedio[2][1] = 2
				break
			end

			flag = 1
		end
	end

	--vedio[2][2] = huihe
	--print("33333333",j_e(vedio))
	return 0, vedio
end

function Pet_adventure_mgr:serialize_to_db()
	for k, v in pairs(self.container_list or {}) do
		if v:is_time_ok() then
			v:update_player()
			v:set_db_time(ev.time)
		end
	end
end

function Pet_adventure_mgr:serialize_to_db_ex()
	for k, v in pairs(self.container_list or {}) do
		v:update_player()
	end
end

function Pet_adventure_mgr:get_click_serialize_param()
	return self,self.serialize_to_db,30,nil
end

function Pet_adventure_mgr:out_line(char_id)
	if self.container_list[char_id] ~= nil then
		self.container_list[char_id]:update_player()
		self.container_list[char_id] = nil
	end
end


--增加次数
function Pet_adventure_mgr:add_count(char_id)
	local pet_adventure_container = self:get_container(char_id)

	local add_count = pet_adventure_container:get_add_count()
	if add_count >= 20 then
		local line = g_player_mgr:get_char_line(char_id)
		return g_server_mgr:send_to_server(line,char_id, CMD_P2M_PET_ADVENTURE_MATRIX_ADD_COUNT_S, {["result"] = 22110})
	end

	if pet_adventure_container.open_flag == nil and g_player_mgr:is_online_char(char_id) then
		local node = {}
		node.result = 0
		node.char_id = char_id
		pet_adventure_container.open_flag = 1
		local line = g_player_mgr:get_char_line(char_id)

		g_sock_event_mgr:add_event_count(char_id, CMD_M2P_PET_ADVENTURE_MATRIX_CHECK_S, self, self.call_back_open, self.failed_open, node, 3, node)
		g_server_mgr:send_to_server(line, char_id, CMD_P2M_PET_ADVENTURE_MATRIX_CHECK_C, node)
	end
end

function Pet_adventure_mgr:call_back_open(node, pkt)
	local pet_adventure_container = self:get_container(node.char_id)
	if not pet_adventure_container then return end
	pet_adventure_container.open_flag = nil

	if pkt.result == 0 then
		pet_adventure_container:is_other_day()
		pet_adventure_container:set_add_count()
		--设置是否vip等加成挑战次数
		pet_adventure_container:set_matrix_max_count(pkt.vip)

		local line = g_player_mgr:get_char_line(node.char_id)
		local ret = {}
		ret.result = 0
		ret.matrix_count = pet_adventure_container:get_left_matrix_count()
		g_server_mgr:send_to_server(line, node.char_id, CMD_P2M_PET_ADVENTURE_MATRIX_ADD_COUNT_S, ret)
	end
end

function Pet_adventure_mgr:failed_open(node, pkt)
	local container = self:get_container(node.char_id)
	if not container then return end
	container.open_flag = nil
end






