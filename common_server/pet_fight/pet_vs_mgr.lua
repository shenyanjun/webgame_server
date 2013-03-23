
local reward = require("config.loader.pet_fight_reward_loader")

Pet_vs_mgr = oo.class(nil,"Pet_vs_mgr")

function Pet_vs_mgr:__init()
	--对象列表
	self.container_list = {}

	--排序列表
	self.sort_list = {}
	self.char_list = {}

	--名称判断
	self.team_name_list = {}

	--上周冠军
	self.last_winner = {}

	--发奖励时间
	self.submit_time = f_get_sunday() + 8 * 24 * 3600 + 1

	self.valid_time = f_get_sunday() + 8 * 24 * 3600 + 10 * 3600

	--奖励
	self.reward_item = {}
end

function Pet_vs_mgr:add_container(container)
	local char_id = container:get_char_id()
	self.container_list[char_id] = container
	self:insert_char(char_id)

	container:insert_container()
end

function Pet_vs_mgr:is_create_ok(team_name)
	if self.team_name_list[team_name] == nil then
		return true
	end

	return false
	
	--for k,v in pairs(self.container_list) do
		--if v:get_team_name() == team_name then
			--return false
		--end
	--end
	--return true
end

function Pet_vs_mgr:add_container_ex(container)
	local char_id = container:get_char_id()
	self.container_list[char_id] = container
	self:insert_char(char_id)
end

function Pet_vs_mgr:del_container(char_id)
	self.container_list[char_id] = nil
	self:delete_con(char_id)
end

function Pet_vs_mgr:delete_con(char_id)
	local dbh = f_get_db()
	local query = string.format("{char_id:%d}",char_id)
	dbh:delete("pet_fight",query)

	--流水
	local monday = f_get_sunday() + 24 * 3600 + 1
	local t_time = os.date("%y%m%d",monday,monday,monday)
	local str = string.format("insert log_pet_battle set date ='%s',attack_id = %d,attack_name='%s',time=%d,type=%d",
				t_time, char_id, g_player_mgr.all_player_l[char_id].char_nm,ev.time,-1)
		g_web_sql:write(str)

end

function Pet_vs_mgr:get_container(char_id)
	if self.container_list[char_id] == nil then return end
	return self.container_list[char_id]
end

function Pet_vs_mgr:get_last_winner()
	return self.last_winner
end

function Pet_vs_mgr:set_last_winner(winner)
	self.last_winner = winner
end

function Pet_vs_mgr:insert_char(char_id)
	if table.size(self.sort_list) == 0 then
		table.insert(self.sort_list, char_id)
	else
		local point = self.container_list[char_id]:get_point()
		local index = 0
		for k,v in pairs(self.sort_list) do
			local point_s = self.container_list[v]:get_point()
			if point_s < point then
				table.insert(self.sort_list,k,char_id)
				--print("22",k)
				break
			elseif k == table.size(self.sort_list) then
				table.insert(self.sort_list, char_id)
				--print("11",k)
				break
			end
		end
	end

	self.char_list= {}
	for k, v in pairs(self.sort_list) do
		self.char_list[v] = k
	end
	

	--print("=============",char_id, self.char_list[char_id])
end

function Pet_vs_mgr:del_char(char_id)
	--for k,v in pairs(self.sort_list or {}) do
		--if v == char_id then
			--table.remove(self.sort_list, k)
			--break
		--end
	--end
	local index = self.char_list[char_id]
	table.remove(self.sort_list, index)

	self.char_list= {}
	for k, v in pairs(self.sort_list) do
		self.char_list[v] = k
	end
	
end

function Pet_vs_mgr:create_container(char_id, team_name,syn_info)
	local container = Pet_vs_container(char_id, team_name)
	container:load()
	self:add_container(container)
	--self:update_info(char_id,syn_info)

	return container
end

--排行榜
function Pet_vs_mgr:get_all_info()
	local ret = {}
	local count = 1
	for k,v in pairs(self.sort_list or {}) do
		if count <= 100 then
			local content = self:get_single_info(v)
			table.insert(ret,content)
			count = count + 1
		end
	end

	return ret
end

--列表基本信息
function Pet_vs_mgr:get_single_info(char_id)
	local container = self.container_list[char_id]
	local content = {}
	content[1] = container:get_team_name()
	content[2] = g_player_mgr.all_player_l[char_id].char_nm
	content[3] = container:get_sum()
	content[4] = container:get_point()
	content[5] = char_id
	content[6] = self:get_rank_by_id(char_id)

	return content
end

--第一名的信息
function Pet_vs_mgr:get_first_info()
	local container = self.container_list[self.sort_list[1]]
	local content = {}
	content[1] = container:get_team_name()
	content[2] = container:get_point()
	content[3] = container:get_sum()

	return content
end

--列表
function Pet_vs_mgr:get_char_info(char_id)
	--local ret = {}
	--local flag = 0
	--for k, v in pairs(self.sort_list or {}) do
		--if v ~= char_id then
			--table.insert(ret,v)
			--if flag == 1 and table.size(ret) >= 7 then
				--break
			--end
		--elseif v == char_id and table.size(ret) >= 7 then
			--break
		--elseif v == char_id and table.size(ret) < 7 then
			--flag = 1
		--end
	--end
--
	--local content = {}
	--local size = table.size(ret)
	--if size <= 7 then 
		--for m, n in pairs(ret or {}) do
			--table.insert(content, self:get_single_info(n))
		--end
	--else
		--for i = size - 7 ,size - 1 do
			--table.insert(content, self:get_single_info(ret[i]))
		--end 
	--end
--
	--return content

	local content = {}
	local index = self.char_list[char_id]
	if index > 10 then
		for i = index - 9, index do
			if self.sort_list[i] ~= nil then
				table.insert(content, self:get_single_info(self.sort_list[i]))
			end
		end
	elseif index <= 10 then
		for i = 1, 10 do
			if self.sort_list[i] ~= nil then
				table.insert(content, self:get_single_info(self.sort_list[i]))
			end
		end
	end

	return content
end

function Pet_vs_mgr:get_rank_by_id(char_id)
	return self.char_list[char_id]
end

--挑战2
function Pet_vs_mgr:challenge_ex(char_id_s, char_id_d)
--print("333")
	local container_d = self:get_container(char_id_d)
	local container_s = self:get_container(char_id_s)
	if not container_d or not container_s then return end

	if container_s:is_count_full() or container_s:get_left_time() ~= 0 then return end

	local vedio_con_s = container_s:get_vedio_con()
	local vedio_con_d = container_d:get_vedio_con()

	local strategy_con_s = container_s:get_strategy_con()
	local strategy_con_d = container_d:get_strategy_con()

	strategy_con_s:init_set()
	strategy_con_d:init_set()

	local pet_list_s = strategy_con_s:get_all_pet()
	local pet_list_d = strategy_con_d:get_all_pet()

	local char_name_s = g_player_mgr.all_player_l[char_id_s].char_nm
	local char_name_d = g_player_mgr.all_player_l[char_id_d].char_nm
	local attr_s = strategy_con_s:get_pet_attr()
	local attr_d = strategy_con_d:get_pet_attr()

	local s_count = table.size(attr_s)
	local d_count = table.size(attr_d)
	if s_count == 0 then
		local line = g_player_mgr:get_char_line(char_id_s) 
		return g_server_mgr:send_to_server(line, char_id_s, CMD_P2M_PET_FIGHT_CHALLENGE_S, {["result"]=20917}) 
	end

	local level_s = 0
	local level_d = 0
	local index_s = 0
	local index_d = 0
	for k, v in pairs(pet_list_s) do
		level_s = level_s + v:get_level()
		index_s = index_s + 1
	end

	level_s = math.floor(level_s / index_s)

	for k, v in pairs(pet_list_d) do
		level_d = level_d + v:get_level()
		index_d = index_d + 1
	end

	level_d = math.floor(level_d / index_d)

	local vedio = {}
	vedio[1] = {attr_s, attr_d}
	vedio[2] = {}
	vedio[2][1] = char_id_s
	vedio[2][2] = char_name_s 
	vedio[2][3] = 0 
	vedio[2][4] = char_name_d 
	vedio[2][5] = 0 
	vedio[2][6] = 0
	vedio[2][7] = {}
	vedio[3] = {}

	local pet_s_flag = 1
	local pet_d_flag = 1
	local flag = 1
	local huihe = 0
	local s_size = table.size(pet_list_s)
	local d_size = table.size(pet_list_d)
	
	if d_count ~= 0 then
		while true do
			if flag == 1 then
				local pet_obj = nil
				local index = 1
				if s_size == 1 then
					for i = pet_s_flag, s_size do
						local pet_obj_s = pet_list_s[i]
						if pet_obj_s == nil or pet_obj_s:get_hp() > 0 then
							index = strategy_con_s:get_index(pet_obj_s:get_pet_id())
							pet_obj = pet_obj_s
							if i == s_size then
								pet_s_flag = 1
							else
								pet_s_flag = i + 1
							end
							huihe = huihe + 1
							break
						end
					end
				else
					for i = pet_s_flag, s_size do
						local pet_obj_s = pet_list_s[i]
						if pet_obj_s == nil or pet_obj_s:get_hp() > 0 then
							index = strategy_con_s:get_index(pet_obj_s:get_pet_id())
							pet_obj = pet_obj_s
							if pet_s_flag == 1 then
								huihe = huihe + 1
							end
							if i == s_size then
								pet_s_flag = 1
							else
								pet_s_flag = i + 1
							end
							break
						end
					end

					if pet_obj == nil then
						for i = 1, pet_s_flag do
							local pet_obj_s = pet_list_s[i]
							if pet_obj_s == nil or pet_obj_s:get_hp() > 0 then
								index = strategy_con_s:get_index(pet_obj_s:get_pet_id())
								pet_obj = pet_obj_s
								if i == pet_s_flag then
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
					end
				end

				if pet_obj == nil then
					break
				end
				
				local skill_con = pet_obj:get_skill_con()
				local skill_id, info,dead_info, addition_hp = skill_con:use(pet_obj, strategy_con_s, strategy_con_d)
				local attr_s, attr_s_2 = strategy_con_s:get_pet_attr()
				local attr_d, attr_d_2 = strategy_con_d:get_pet_attr()

				local table_s = {flag, index, skill_id, info, {attr_s_2, attr_d_2}}
				if pet_obj:get_hp() > 0 then
					table_s[6] = {{},dead_info}
				else
					table_s[6] = {{index},dead_info}
				end
				--print("55555555",addition_hp,j_e(table_s))
				table_s[7] = addition_hp
				table.insert(vedio[3], table_s)
				
				local size_s = table.size(attr_s)
				local size_d = table.size(attr_d)
				if size_d == 0 then
					vedio[2][1] = char_id_s
					break
				elseif size_s == 0 then
					vedio[2][1] = char_id_d
					break
				end

				flag = 2
			else
				local pet_obj = nil
				local index = 1
				for i = pet_d_flag, d_size do
					local pet_obj_d = pet_list_d[i]
					if pet_obj_d == nil or pet_obj_d:get_hp() > 0 then
						index = strategy_con_d:get_index(pet_obj_d:get_pet_id())
						pet_obj = pet_obj_d
						if i == d_size then
							pet_d_flag = 1
						else
							pet_d_flag = i + 1
						end
						break
					end
				end

				if pet_obj == nil then
					for i = 1, pet_d_flag do
						local pet_obj_d = pet_list_d[i]
						if pet_obj_d == nil or pet_obj_d:get_hp() > 0 then
							index = strategy_con_d:get_index(pet_obj_d:get_pet_id())
							pet_obj = pet_obj_d
							if i == pet_d_flag then
								pet_d_flag = 1
							else
								pet_d_flag = i + 1
							end
							break
						end
					end
				end

				if pet_obj == nil then
					break
				end
				
				local skill_con = pet_obj:get_skill_con()
				local skill_id, info, dead_info, addition_hp = skill_con:use(pet_obj, strategy_con_d, strategy_con_s)
				local attr_s, attr_s_2 = strategy_con_s:get_pet_attr()
				local attr_d, attr_d_2 = strategy_con_d:get_pet_attr()

				local table_s = {flag, index, skill_id, info, {attr_s_2, attr_d_2}}
				if pet_obj:get_hp() > 0 then
					table_s[6] = {dead_info,{}}
				else
					table_s[6] = {dead_info, {index}}
				end
				table_s[7] = addition_hp
				table.insert(vedio[3], table_s)

				local size_s = table.size(attr_s)
				local size_d = table.size(attr_d)
				if size_d == 0 then
					vedio[2][1] = char_id_s
					break
				elseif size_s == 0 then
					vedio[2][1] = char_id_d
					break
				end

				flag = 1
			end
		end
	else
		huihe = 1
	end

	vedio[2][6] = huihe
	
	local vedio_obj = g_vedio_mgr:create_vedio(1)
	
	vedio_obj:set_char_id_s(char_id_s)
	vedio_obj:set_char_id_d(char_id_d)
	vedio_obj:set_huihe(huihe)

	local win_point = 0
	local lost_point = 0
	local s_percent = math.floor(container_s:get_sum())
	local d_percent = math.floor(container_d:get_sum())
	local s_level = g_player_mgr.all_player_l[char_id_s]["level"]
	local d_level = g_player_mgr.all_player_l[char_id_d]["level"]
	local char_win_exp = 0
	local char_lost_exp = 0
	local win_flag = 1
	if vedio[2][1] == char_id_s then
		if huihe > 10 then
			win_point = math.ceil(level_s * (1 + d_percent/100))
		else
			win_point = math.ceil(level_s * (1 + d_percent/100) + (10 - huihe) * 2)
		end
		lost_point = 0
		container_s:set_point(win_point)
		--container_d:set_point(lost_point)
		container_s:set_winning(1)
		container_d:set_winning(2)
		vedio_obj:set_win_flag(char_id_s)
		vedio[2][3] = win_point
		vedio[2][5] = lost_point
		local percent_s, percent_d = math.floor(container_s:get_sum()), math.floor(container_d:get_sum())
		vedio[2][7] = {percent_s, percent_d}
		vedio_obj:set_shenglv({percent_s, percent_d})
		char_win_exp = math.floor((s_level-20)*5000*(0.5+percent_d/100))
		vedio[2][8] = char_win_exp
		--char_lost_exp = math.floor((d_level-20)*2000*(0.5+percent_s/100))
		self:reward(char_id_s, char_win_exp)
	else
		win_flag = 0
		win_point = 0 --math.floor(level_d * (1 + s_percent/100))

		lost_point = math.ceil(level_s*( 1 + s_percent / 100) / 5)
		--container_d:set_point(win_point)
		container_s:set_point(lost_point)
		container_d:set_winning(1)
		container_s:set_winning(2)
		vedio_obj:set_win_flag(char_id_d)

		vedio[2][3] = lost_point
		vedio[2][5] = win_point

		local percent_s, percent_d = math.floor(container_s:get_sum()), math.floor(container_d:get_sum())
		vedio[2][7] = {percent_d, percent_s}
		vedio_obj:set_shenglv({percent_d, percent_s})

		--char_win_exp = math.floor((d_level-20)*5000*(0.5+percent_s/100))
		char_lost_exp = math.floor((s_level-20)*2000*(0.5+percent_d/100))
		vedio[2][8] = char_lost_exp
		self:reward(char_id_s, char_lost_exp)
	end

	vedio_obj:set_vedio_list_ex(vedio)

	--设置次数和时间
	local count_index = container_s:get_count()
	container_s:set_count(count_index + 1)
	container_s:set_time_span(ev.time)
	container_s:set_flag(0)

	vedio_con_s:set_vedio(vedio_obj)
	vedio_con_d:set_vedio(vedio_obj)

	self:del_char(char_id_s)
	self:del_char(char_id_d)
	self:insert_char(char_id_s)
	self:insert_char(char_id_d)

	if g_player_mgr:is_online_char(char_id_s) then
		local line = g_player_mgr:get_char_line(char_id_s)
		local ret = container_s:get_net_info()
		g_server_mgr:send_to_server(line,char_id_s, CMD_P2M_PET_FIGHT_INFO_S, ret)

		local ret = {}
		ret.result = 0
		ret.vedio = vedio
		--print("=====",j_e(ret))
		g_server_mgr:send_to_server(line,char_id_s, CMD_P2M_PET_FIGHT_CHALLENGE_S, ret)
	end

	if g_player_mgr:is_online_char(char_id_d) then
		local line = g_player_mgr:get_char_line(char_id_d)
		local ret = container_d:get_net_info()
		g_server_mgr:send_to_server(line,char_id_d, CMD_P2M_PET_FIGHT_INFO_S, ret)

		--g_server_mgr:send_to_server(line,char_id_d, CMD_P2M_PET_FIGHT_CHALLENGE_S, vedio)
	end

	--流水

	local monday = f_get_sunday() + 24 * 3600 + 1
	local t_time = os.date("%y%m%d",monday,monday,monday)
	local str = string.format("insert log_pet_battle set date ='%s'  ,attack_id = %d, attack_name='%s', attack_pet=%d, defend_id=%d, defend_name = '%s', defend_pet=%d, time=%d,type=%d,result='%s', cur_score=%d, total_score=%d",
				t_time, char_id_s, g_player_mgr.all_player_l[char_id_s].char_nm, s_count, char_id_d,g_player_mgr.all_player_l[char_id_d].char_nm, d_count, ev.time,0,win_flag,vedio[2][3],container_s:get_point())
		g_web_sql:write(str)
end

--奖励
function Pet_vs_mgr:reward(char_id, char_exp)
	if g_player_mgr:is_online_char(char_id) then
		--宠物奖励
		local pet_exp = 0-- math.floor(pet_win_exp * 0.02 *(0.5 + lost_percent))

		local line = g_player_mgr:get_char_line(char_id)

		local ret = {}
		ret.char_exp = char_exp
		g_server_mgr:send_to_server(line,char_id, CMD_P2M_PET_FIGHT_REWARD_C, ret)
	end
	--if g_player_mgr:is_online_char(char_id_d) then
--
		--local line = g_player_mgr:get_char_line(char_id_d)
--
		--local ret = {}
		--ret.char_exp = char_d_exp
		--g_server_mgr:send_to_server(line,char_id_d, CMD_P2M_PET_FIGHT_REWARD_C, ret)
	--end
end

--同步数据
function Pet_vs_mgr:syn_info(char_id_s, char_id_d)
	local id = Pet_syn_mgr:create_id()

	local node = {}
	node.id = id
	if g_player_mgr:is_online_char(char_id_d) then
		node.flag = 2
		local line = g_player_mgr:get_char_line(char_id_d)
		if line == nil then
			print("Error: syn_info_1",char_id_s,char_id_d)
		end

		g_sock_event_mgr:add_event_count(char_id_d, CMD_M2P_PET_FIGHT_SYN_S, self, self.call_back_challenge, nil, node, 3, node)
		g_server_mgr:send_to_server(line, char_id_d, CMD_P2M_PET_FIGHT_SYN_C, node)
	else
		Pet_syn_mgr:insert_char(id, char_id_d,2)
	end
	node.flag = 1
	local line = g_player_mgr:get_char_line(char_id_s)
	if line == nil then
		print("Error: syn_info_2",char_id_s,char_id_d)
	end
	g_sock_event_mgr:add_event_count(char_id_s, CMD_M2P_PET_FIGHT_SYN_S, self, self.call_back_challenge, nil, node, 3, node)
	g_server_mgr:send_to_server(line, char_id_s, CMD_P2M_PET_FIGHT_SYN_C, node)
end

function Pet_vs_mgr:call_back_challenge(node, pkt)

	local id = pkt.id
	local flag = pkt.flag
	local obj_id = pkt.obj_id

	--进行同步信息
	self:update_info(obj_id,pkt.item_l)

	--判断是否可以进行战斗
	Pet_syn_mgr:insert_char(id, obj_id, flag)
	if Pet_syn_mgr:get_size(id) == 2 then
		local char_id_s = Pet_syn_mgr:get_char(id, 1)    --挑战者
		local char_id_d = Pet_syn_mgr:get_char(id, 2)    --被挑战者
		self:challenge_ex(char_id_s, char_id_d)
		Pet_syn_mgr:clear(id)
	end
end

function Pet_vs_mgr:update_info(char_id, pkt)
	local container = self:get_container(char_id)
	local pet_con = container:get_pet_con()
	pet_con:update_pet_list(pkt)
end

--幸运奖
function Pet_vs_mgr:luck_reward()
	local size = table.size(self.sort_list)
	local list = self:create_item(104090000550, 1)
	if list == nil then return end

	local title = f_get_string(2065)
	local content = f_get_string(2066)
	if size <= 10 then
		for k, v in pairs(self.sort_list) do
			self:insert_email_ex(v, title, content, list)
		end
	else
		local ret = {}
		local table_s = table.copy(self.sort_list)
		local count = 0
		while true do
			local size_s = table.size(table_s)
			if size_s == 0 then break end
			local num = crypto.random(1, size_s + 1)
			if ret[table_s[num]] == nil then
				ret[table_s[num]] = 1
				count = count + 1
				table.remove(table_s, num)
			else
				table.remove(table_s, num)
			end

			if count >= 10 then
				break
			end
		end

		for k, v in pairs(ret) do
			self:insert_email_ex(k, title, content, list)
		end
	end

	
end

--参与奖
function Pet_vs_mgr:join_reward()
	local list = self:create_item(104090000010, 1)
	if list == nil then return end

	local title = f_get_string(2067)
	local content = f_get_string(2068)
	for k, v in pairs(self.container_list or {}) do
		self:insert_email_ex(k, title, content, list)
	end
end

--排名奖
function Pet_vs_mgr:sort_reward()
	local count = table.size(reward.sort_list)
		self.reward_item = {}
		local flag = 0
		local max = reward.sort_list[count][2]
		if max == 0 then
			for k,v in pairs(self.sort_list) do
				local t = {}
				t[1] = v
				t[2] = g_player_mgr.all_player_l[v].char_nm
				t[3] = self.container_list[v]:get_point()
				t[4] = self.container_list[v]:get_team_name()

				table.insert(self.reward_item,t)
			end		
		else
			for k, v in pairs(self.sort_list or {}) do
				if k <= max then
					local t = {}
					t[1] = v
					t[2] = g_player_mgr.all_player_l[v].char_nm
					t[3] = self.container_list[v]:get_point()
					t[4] = self.container_list[v]:get_team_name()

					table.insert(self.reward_item,t)
				end
			end
		end
		
		self:update_pet_fight()

		for k,v in pairs(self.reward_item or {}) do
			for m, n in pairs(reward.sort_list or {}) do
				if m ~= count then
					if k <= n[2] then
						local item_l = reward.reward_list[m]
						for b,c in pairs(item_l) do
							self:insert_email(v[1], c[1],c[2])
						end
						break
					end
				elseif m == count then
					if n[2] == 0 then
						local item_l = reward.reward_list[m]
						for b,c in pairs(item_l) do
							self:insert_email(v[1], c[1],c[2])
						end
						break
					elseif k<= n[2] then
						local item_l = reward.reward_list[m]
						for b,c in pairs(item_l) do
							self:insert_email(v[1], c[1],c[2])
						end
						break
					end
				end
			end
		end

		if self.sort_list[1] ~= nil then
			local char_id = self.sort_list[1]
			local ret = {}
			ret[1] = self.container_list[char_id]:get_team_name()
			ret[2] = g_player_mgr.all_player_l[char_id].char_nm
			ret[3] = self.container_list[char_id]:get_point()
			self.last_winner = ret
		end

		local char_id_list = {}
		for k, v in pairs(self.container_list or {}) do
			if v:get_point() == 0 then
				local team_name = v:get_team_name()
				local char_id = v:get_char_id()
				table.insert(char_id_list,char_id)
				self.team_name_list[team_name] = nil
				--队伍邮件通知
				local title = f_get_string(2062)
				local content = string.format(f_get_string(2061),team_name)
				g_email_mgr:create_email(-1,char_id,title,content,0,Email_type.type_common,Email_sys_type.type_normal,nil)
			else
				local vedio_con = v:get_vedio_con()
				vedio_con:clear()
				local point = v:get_point()
				v:set_point(- point)
				local vs_list = {0,0}
				v:set_vs_list(vs_list)
			end
		end
		for m, n in pairs(char_id_list) do
			self:del_container(n)
			self:del_char(n)
		end
end

function Pet_vs_mgr:on_timer()
	if ev.time >= self.submit_time then
		self.submit_time = f_get_sunday() + 8 * 24 * 3600 + 1

		--幸运奖
		self:luck_reward()

		--参与奖
		self:join_reward()

		--排名奖
		self:sort_reward()
	end
end

function Pet_vs_mgr:ontimer()
	self:on_timer()
end

function Pet_vs_mgr:get_click_param()
	return self, self.ontimer,10,nil
end


function Pet_vs_mgr:serialize_to_db()
	for k, v in pairs(self.container_list or {}) do
		if v:is_time_ok() then
			v:update_container()
			v:set_db_time(ev.time)
		end
	end
end

function Pet_vs_mgr:serialize_to_db_ex()
	for k, v in pairs(self.container_list or {}) do
		v:update_container()
	end
end

function Pet_vs_mgr:get_click_serialize_param()
	return self,self.serialize_to_db,75,nil
end

function Pet_vs_mgr:insert_email_ex(char_id, title, content, list)
	g_email_mgr:create_email(-1,char_id,title,content,0,Email_type.type_gold,Email_sys_type.type_sys,list)
end 

function Pet_vs_mgr:create_item(item_id, count)
	local e_code ,item_l = Item_factory.create(item_id)
	if e_code ~= 0 then
		return
	end

	local list = {}
	list[1] = {}
	list[1]["item_id"] = item_l:get_item_id()
	list[1]["item_obj"] = item_l:serialize_to_db()
	list[1]["number"] = count

	return list
end

function Pet_vs_mgr:insert_email(char_id,item_id,count)
	local title = f_get_string(2063)
	local content = f_get_string(2064)
	local e_code ,item_l = Item_factory.create(item_id)
	if e_code ~= 0 then
		return
	end

	local list = {}
	list[1] = {}
	list[1]["item_id"] = item_l:get_item_id()
	list[1]["item_obj"] = item_l:serialize_to_db()
	list[1]["number"] = count

	g_email_mgr:create_email(-1,char_id,title,content,0,Email_type.type_gold,Email_sys_type.type_sys,list)
end

function Pet_vs_mgr:on_timer_1()
	if ev.time >= self.valid_time then
		self.valid_time = f_get_sunday() + 8 * 24 * 3600 + 10 * 3600
		local count = table.size(reward.sort_list)
		for k,v in pairs(self.reward_item or {}) do
			for m, n in pairs(reward.sort_list or {}) do
				if m ~= count then
					if k <= n[2] then
						local item_l = reward.reward_list[m]
						print()
						for b,c in pairs(item_l) do
							self:insert_email(v[1], c[1],c[2])
						end
						break
					end
				elseif m == count then
					if n[2] == 0 then
						local item_l = reward.reward_list[m]
						for b,c in pairs(item_l) do
							self:insert_email(v[1], c[1],c[2])
						end
						break
					elseif k<= n[2] then
						local item_l = reward.reward_list[m]
						for b,c in pairs(item_l) do
							self:insert_email(v[1], c[1],c[2])
						end
						break
					end
				end
			end
		end
	end
end

function Pet_vs_mgr:ontimer1()
	self:on_timer_1()
end

function Pet_vs_mgr:get_click_serialize_param_ex()
	return self, self.ontimer1,3,nil
end


function Pet_vs_mgr:update_pet_fight()
	local db = f_get_db()
	local t_time = self.submit_time - 7 * 24 * 3600 + 1
	local query = string.format("{time:%d}",tonumber(os.date("%y%m%d",t_time,t_time,t_time)))
	local ret ={}
	ret.data = self.reward_item
	local e_code = db:update("pet_fight_winner", query, Json.Encode(ret), true)
end

--数据加载
function Pet_vs_mgr:load()
	local db = f_get_db()
	local rows, e_code = db:select("pet_fight")
	if 0 == e_code and rows then
		for k, v in pairs(rows) do
			--加载数据
			local team_name = v.team_name
			local char_id = v.char_id
			local con = Pet_vs_container(char_id, team_name)
			con:set_count(v.count)
			con:set_time_span(v.time_span)
			con:set_vs_list(v.vs_list)
			con:set_point(v.point)
			con:set_challenge_time(v.challenge_time)
			con:set_worship_time(v.worship_time or 0)
			con:load(v)
			self.team_name_list[v.team_name] = 1
			--print("==========",v.char_id)
			self:add_container_ex(con)

			--初始化
			con:get_strategy_con():init_set()
		end
	end

	local db = f_get_db()
	local time_t = ev.time
	local data = "{data:1}" --char_id,char_name:1,point:1,team_name:1
	local monday = f_get_sunday() + 24 * 3600 + 1
	local t_time = tonumber(os.date("%y%m%d",monday,monday,monday))
	local condition = string.format("{time:%d}",t_time)
	local row, e_code = db:select_one("pet_fight_winner",data,condition)
	if 0 == e_code and row then
		local data = row.data
		self.reward_item = data
		if tonumber(os.date("%w",ev.time)) == 0 then
			self.submit_time = f_get_today(ev.time) + 24 * 3600 + 1
			self.valid_time = f_get_sunday() + 24 * 3600 + 10 * 3600
		else
			self.submit_time = f_get_sunday() + 8 * 24 * 3600 + 1
			self.valid_time = f_get_sunday() + 8 * 24 * 3600 + 10 * 3600
		end
		if table.size(data) == 0 then
			self.last_winner = {"","",0}
		else
			self.last_winner = {data[1][4],data[1][2],data[1][3]}
		end
	else
		self.last_winner = {"","",0}
		local ret = {}
		ret.time = t_time
		ret.data = {}

		if tonumber(os.date("%w",ev.time)) == 0 then
			self.submit_time = f_get_today(ev.time) + 24 * 3600 + 1
			self.valid_time = f_get_sunday() + 24 * 3600 + 10 * 3600
		else
			self.submit_time = f_get_sunday() + 8 * 24 * 3600 + 1
			self.valid_time = f_get_sunday() + 8 * 24 * 3600 + 10 * 3600
		end

		db:insert("pet_fight_winner",Json.Encode(ret))
	end
end

--开启阵法
function Pet_vs_mgr:open_strategy(index,char_id)
	local container = g_pet_vs_mgr:get_container(char_id)
	if not container then return end

	local strategy_con = container:get_strategy_con()
	if not strategy_con then return end

	if strategy_con:get_strategy(index) ~= -1 then
		if g_player_mgr:is_online_char(char_id) then
			local line = g_player_mgr:get_char_line(char_id)
			g_server_mgr:send_to_server(line, char_id, CMD_P2M_PET_FIGHT_OPEN_MATRIX_S, {["result"] = 20919})
		end

		return
	end

	if strategy_con:is_slot_full() then
		if g_player_mgr:is_online_char(char_id) then
			local line = g_player_mgr:get_char_line(char_id)
			g_server_mgr:send_to_server(line, char_id, CMD_P2M_PET_FIGHT_OPEN_MATRIX_S, {["result"] = 20920})
		end
	else
		if g_player_mgr:is_online_char(char_id) and container.open_flag == nil then
			local slot_count = strategy_con:get_slot_count()
			local line = g_player_mgr:get_char_line(char_id)
			local node = {}
			node.index_count = slot_count + 1
			node.result = 0
			node.index = index
			node.char_id = char_id
			container.open_flag = 1
			--print("34343434343434",j_e(node))
			g_sock_event_mgr:add_event_count(char_id, CMD_M2P_PET_FIGHT_MATRIX_CHECK_S, self, self.call_back_open, self.failed_open, node, 3, node)
			g_server_mgr:send_to_server(line, char_id, CMD_P2M_PET_FIGHT_MATRIX_CHECK_C, node)
		end
	end
end

function Pet_vs_mgr:call_back_open(node, pkt)
	local container = g_pet_vs_mgr:get_container(node.char_id)
	if not container then return end
	container.open_flag = nil

	if pkt.result == 0 then
		local strategy_con = container:get_strategy_con()
		if not strategy_con then return end

		strategy_con:open_strategy(node.index)
		if g_player_mgr:is_online_char(node.char_id) then
			local line = g_player_mgr:get_char_line(node.char_id)
			local ret = {}
			ret.strategy = strategy_con:get_net_info()
			ret.result = 0
			g_server_mgr:send_to_server(line, node.char_id, CMD_P2M_PET_FIGHT_OPEN_MATRIX_S, ret)
		end
	end
end

function Pet_vs_mgr:failed_open(node, pkt)
	local container = g_pet_vs_mgr:get_container(node.char_id)
	if not container then return end
	container.open_flag = nil
end





