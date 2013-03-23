
STATUS_ZERO = 0
STATUS_ONE = 1
STATUS_TWO = 2
local MAX_COUNT = 10


Pet_adventure_container = oo.class(nil, "Pet_adventure_container")

function Pet_adventure_container:__init(char_id)
	self.player_info = {}
	self.count = 0
	self.char_id = char_id
	self.pet_list = {0,0,0,0,0,0}

	self.pet_con = nil

	self.challenge_time = 0

	self.max_count = MAX_COUNT

	--用来定期分散插入数据库
	self.db_time = 0

	--限制时间操作
	self.time_l = 0

	--阵法策略
	self.p_strategy_con = nil

	--阵法闯关数据
	self.matrix_data = {}

	--阵法闯关次数
	self.matrix_count = 0

	--阵法闯关总次数
	self.matrix_max_count = MAX_COUNT

	--阵法闯关一天增加的次数
	self.add_count = 0
end

function Pet_adventure_container:get_strategy_con()
	return self.p_strategy_con
end

function Pet_adventure_container:load_strategy_con(pack)
	if self.p_strategy_con == nil then
		self.p_strategy_con = Pet_strategy_container(self.char_id)
		self.p_strategy_con:unserialize_to_db(pack)
	end
end

function Pet_adventure_container:is_time_ok()
	local t_time = crypto.random(32,210) * 3
	if self.db_time + t_time <= ev.time then
		return true
	end
	return false
end

function Pet_adventure_container:get_db_time()
	return self.db_time
end

function Pet_adventure_container:set_db_time(time)
	self.db_time = time
end

function Pet_adventure_container:get_max_count()
	return self.max_count
end

function Pet_adventure_container:set_max_count(addition)
	self.max_count = MAX_COUNT + addition
end

function Pet_adventure_container:get_challenge_time()
	return self.challenge_time
end

function Pet_adventure_container:set_challenge_time(time)
	self.challenge_time = time
end

function Pet_adventure_container:challenge(barrier_id,level, flag)
	local count = self:get_count()
	if flag == 1 then
		if self.player_info[barrier_id] ~= nil then
			if self.player_info[barrier_id][2] < level then
				self.player_info[barrier_id][2] = level
			end

			self.player_info[barrier_id][3] = STATUS_ONE

			self:set_count(count + 1)
		end
	end

	self:set_challenge_time(ev.time)

	local log_str = string.format(" pet_adventure: barrier_id=%d level=%d old_count=%d, new_count=%d, challenge_time=%d ",barrier_id,level, count,self:get_count(),ev.time)
	g_pet_adventure_log:write(log_str)
end

function Pet_adventure_container:get_challenge_level(barrier_id)
	return self.player_info[barrier_id][2]
end

function Pet_adventure_container:get_challenge_level2(barrier_id)
	return self.matrix_data[barrier_id][1]
end

function Pet_adventure_container:get_day_time()
	local l_time = self.challenge_time
	local time_today ={}
	time_today.year = os.date("%Y",l_time)
	time_today.month = os.date("%m",l_time)
	time_today.day = os.date("%d",l_time)
	time_today.hour = 0
	time_today.minute = 0
	time_today.second = 0
	local t_time = os.time(time_today)
	return t_time
end

function Pet_adventure_container:is_other_day(num)     --上线时判断
	if num == nil then num = 1 end
	if ev.time >= self:get_day_time() + num * 86400 then
		self.count = 0
		self.challenge_time = ev.time
		self.matrix_count = 0
		self.add_count = 0
		return true
	end
	return false
end

--注意 可能引起错误
function Pet_adventure_container:get_real_fight_pet_list()
	local real_pet_list = {}
	for i = 1, 6 do
		if self.pet_list[i] ~= nil and self.pet_list[i] ~= 0 then
			local pet_id = self.pet_list[i]
			if self.pet_con.pet_list[pet_id] ~= nil then
				table.insert(real_pet_list,self.pet_list[i])
			end
		else
			table.insert(real_pet_list, 0 )
		end
	end

	for i =1, 6 do
		if real_pet_list[i] == 0 or real_pet_list[i] == nil then
			for k,v in pairs(self.pet_con.pet_list) do
				local flag = 0
				for m,n in pairs(real_pet_list) do
					if n == k then
						flag = 1
						break
					end
				end
				if flag == 0 then
					real_pet_list[i] = k
				end
			end
		end
	end
	return real_pet_list
end

function Pet_adventure_container:can_challenge_barrier(barrier_id,level)
	if self.time_l > ev.time then
		return 
	else
		self.time_l = ev.time + 1
	end

	if level > 5 then 
		--print("Error: the barrier level is not valid, level " .. level)
		return 22101 
	end

	local pet_barrier = g_pet_barrier_mgr:get_pet_barrier(barrier_id)
	if not pet_barrier then 
		--print("Error: there is no barrier to challenge, id" .. barrier_id)
		return 22102 
	end

	local condition = pet_barrier:get_barrier_condition()
	if table.size(condition) ~= 0 then 
		for k,v in pairs(condition) do
			if self.player_info[v][2] < 1 then
				--print("Error: the period barrier is not open, barrier_id " .. v)
				return 22103
			end
		end
	end

	if self.count >= self:get_max_count() then 
		--print("Error: the count is much more large than the max, count " .. self.count)
		return 22104 
	end

	if self.player_info[barrier_id] ~= nil then
		if self.player_info[barrier_id][3] ~= STATUS_TWO and self.player_info[barrier_id][2] <= 5 and self.player_info[barrier_id][2] + 1 >= level then
			return 0
		end
	end

	return 22101
end

function Pet_adventure_container:set_status(barrier_id)
	local ret = {}
	for k,v in pairs(self.player_info) do
		if v[3] == STATUS_TWO then
			local flag = 0
			local pet_barrier = g_pet_barrier_mgr:get_pet_barrier(k)
			local condition = pet_barrier:get_barrier_condition()
			for m, n in pairs(condition) do
				if self.player_info[n][2] < 1 then
					flag = 1
					break
				end
			end
			if flag == 0 then
				self.player_info[k][3] = STATUS_ZERO
				table.insert(ret, k)
			end
		end
	end
	table.insert(ret,barrier_id)

	return ret
end

function Pet_adventure_container:get_change_info(list)
	local ret = {}
	for k,v in pairs(list) do
		if self.player_info[v] then
			table.insert(ret,self.player_info[v])
		end
	end

	return ret
end


function Pet_adventure_container:get_pet_con()
	return self.pet_con
end

function Pet_adventure_container:load_pet_con()
	if self.pet_con == nil then
		self.pet_con = D_pet_container(self.char_id)
		self.pet_con:load()
	end
end

function Pet_adventure_container:get_pet_list()
	return self.pet_list
end

function Pet_adventure_container:set_pet_list(pet_list)
	if pet_list == nil then
		self.pet_list = {0,0,0,0,0,0}
	else
		for k = 1, 6 do
			if pet_list[k] == nil then
				self.pet_list[k] = 0
			else
				self.pet_list[k] = pet_list[k]
			end
		end
	end
	
end

function Pet_adventure_container:get_char_id()
	return self.char_id
end

function Pet_adventure_container:get_count()
	return self.count
end

function Pet_adventure_container:set_count(count)
	self.count = count
	if self.count > self:get_max_count() then
		self.count = self:get_max_count()
	end
end

function Pet_adventure_container:get_player_info(barrier_id)
	return self.player_info[barrier_id][2]
end

function Pet_adventure_container:load_player()
	local db = f_get_db()
	local data = "{data:1,count:1,challenge_time:1,pet_list:1,strategy:1,matrix_data:1,matrix_count:1,add_count:1}"
	local condition = string.format("{char_id:%d}",self.char_id)
	local row, e_code = db:select_one("pet_adventure",data, condition)
	if 0 == e_code and row then
		local count = row.count
		self.count = count
		self.challenge_time = row.challenge_time or 0
		self.player_info = {{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{12,0},{13,0},{14,0},{15,0},{16,0},{17,0},{18,0},{19,0},{20,0},
		{21,0},{22,0},{23,0},{24,0},{25,0},{26,0},{27,0},{28,0},{29,0},{30,0},{31,0},{32,0},{33,0},{34,0},{35,0},{36,0}}
		self.pet_list = row.pet_list or {0,0,0,0,0,0}
		for k,v in pairs(row.data) do
			local pet_barrier = g_pet_barrier_mgr:get_pet_barrier(v[1])
			if pet_barrier then
				self.player_info[v[1]] ={} 
				self.player_info[v[1]][1]= v[1]
				self.player_info[v[1]][2]= v[2]
			end
		end

		for m,n in pairs(self.player_info) do
			local pet_barrier = g_pet_barrier_mgr:get_pet_barrier(m)
			if pet_barrier then
				local condition = pet_barrier:get_barrier_condition()
				local size = table.size(condition)
				local flag = 0
				for b, c in pairs(condition) do
					if self.player_info[c] ~= nil and self.player_info[c][2] == 0 then
						flag = 1
						break
					end
				end
				if flag == 0 then
					if n[2] > 0 then
						self.player_info[m][3] = STATUS_ONE
					else
						self.player_info[m][3] = STATUS_ZERO
					end
				else
					self.player_info[m][3] = STATUS_TWO
				end
			else
				self.player_info[m] = nil
			end
		end

		self:load_pet_con()
		self:load_strategy_con(row.strategy)
		self:load_matrix(row.matrix_data, row.matrix_count)
		self.add_count = row.add_count or 0
	else
		self.count = 0
		self.player_info = {}
		self.pet_list = {0,0,0,0,0,0}
		self.challenge_time = 0
		local list = g_pet_barrier_mgr:get_list()
		for k,v in pairs(list) do
			local barrier_id = v:get_barrier_id()
			if self.player_info[barrier_id] == nil then
				self.player_info[barrier_id] = {}
			end
			self.player_info[barrier_id][1] = barrier_id
			self.player_info[barrier_id][2] = 0  --已挑战难度
			local condition = v:get_barrier_condition()
			if table.size(condition) > 0 then
				self.player_info[barrier_id][3] = STATUS_TWO  --关卡挑战状态 0为可挑战 1为已挑战 2不能挑战
			else
				self.player_info[barrier_id][3] = STATUS_ZERO
			end
			--self.player_info[barrier_id][3] = math.random(0,2)
		end

		self:load_pet_con()
		self:load_strategy_con()
		self:load_matrix()
		self.add_count = 0
	end
end

----------------阵法闯关
function Pet_adventure_container:get_matrix_data()
	return self.matrix_data
end

function Pet_adventure_container:load_matrix(matrix_data, count)
	self.matrix_count = count or 0

	if matrix_data == nil then
		local list = g_pet_matrix_barrier_mgr:get_list()
		for k,v in ipairs(list) do
			self.matrix_data[k] = {}
			self.matrix_data[k][1] = 0  --已挑战难度
			if k == 1 then
				self.matrix_data[k][2] = STATUS_ZERO --关卡挑战状态 0为可挑战 1为已挑战 2不能挑战
			else
				self.matrix_data[k][2] = STATUS_TWO
			end
		end
	else
		self.matrix_data = matrix_data
		local list = g_pet_matrix_barrier_mgr:get_list()
		for k, v in ipairs(list) do
			if self.matrix_data[k] == nil then
				self.matrix_data[k] = 0
				if k == 1 then
					self.matrix_data[k][2] = STATUS_ZERO --关卡挑战状态 0为可挑战 1为已挑战 2不能挑战
				else
					self.matrix_data[k][2] = STATUS_TWO
				end
			end
		end
	end
end

function Pet_adventure_container:get_matrix_count()
	return self.matrix_count
end

function Pet_adventure_container:set_matrix_count(count)  --要改点东西，关于最大次数
	self.matrix_count = count
end

function Pet_adventure_container:get_matrix_max_count()
	return self.matrix_max_count
end

function Pet_adventure_container:set_matrix_max_count(addition)
	self.matrix_max_count = MAX_COUNT + addition + self.add_count
end

function Pet_adventure_container:can_matrix_challenge(barrier_id, level)
	if level > 5 then
		return
	end

	if self.p_strategy_con:get_pet_count() <= 0 then
		--self.p_strategy_con:add_pet(1,1000000710)
		return 22107
	end

	if self:get_left_matrix_count() <= 0 then
		return 22108
	end 

	if self.matrix_data[barrier_id] == nil then
		return 22109
	end

	if self.matrix_data[barrier_id][2] ~= STATUS_TWO and self.matrix_data[barrier_id][1] + 1 >= level then
		return 0
	end

	return 22101
end

--阵法闯关成功之后才执行
function Pet_adventure_container:matrix_change(barrier_id,level)
	local flag = 0
	if self.matrix_data[barrier_id] ~= nil then
		if self.matrix_data[barrier_id][1] < level then
			self.matrix_data[barrier_id][1] = level
		end

		self.matrix_data[barrier_id][2] = STATUS_ONE

		local count = self:get_matrix_count()
		self:set_matrix_count(count + 1)
		if self.matrix_data[barrier_id + 1] ~= nil then
			if self.matrix_data[barrier_id + 1][1] == 0 then
				self.matrix_data[barrier_id + 1][2] = STATUS_ZERO
				flag = barrier_id + 1
			end
		end
	end

	return flag
end

function Pet_adventure_container:get_left_matrix_count()
	return self.matrix_max_count - self.matrix_count
end

function Pet_adventure_container:get_add_count()
	return self.add_count
end

function Pet_adventure_container:set_add_count()
	self.add_count = self.add_count + 5  --每次增加5次
end

function Pet_adventure_container:update_player()
	local ret = {}
	ret.char_id = self.char_id
	ret.count = self.count
	ret.challenge_time = self.challenge_time
	ret.data = {}
	for k,v in pairs(self.player_info or {}) do
		local data = {}
		data[1] = v[1]
		data[2] = v[2]
		table.insert(ret.data,data)
	end
	ret.pet_list = self.pet_list
	ret.strategy = self.p_strategy_con:serialize_to_db()
	ret.matrix_count = self.matrix_count
	ret.matrix_data = self.matrix_data
	ret.add_count = self.add_count

	local db = f_get_db()
	local condition = string.format("{char_id:%d}", self.char_id)
	db:update("pet_adventure", condition, Json.Encode(ret), true)
end

function Pet_adventure_container:get_net_info()
	local ret = {}
	for k,v in pairs(self.player_info) do
		table.insert(ret,v)
	end
	return ret
end



