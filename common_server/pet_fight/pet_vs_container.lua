

Pet_vs_container = oo.class(nil,"Pet_vs_container")

function Pet_vs_container:__init(obj_id, team_name)
	self.obj_id = obj_id

	--积分
	self.point = 0

	--胜负
	self.vs_list = {}
	self.vs_list[1] = 0   --胜
	self.vs_list[2] = 0   --负

	--队名
	self.team_name = team_name

	--挑战时间
	self.time_span = 0

	--
	self.challenge_time = 0

	--崇拜时间
	self.worship_time = 0

	--每天参战次数
	self.count = 0

	--报名时间
	self.app_time = 0

	--宠物对象容器
	self.pet_con = nil

	--策略容器
	self.strategy_con = nil

	--阵法容器
	self.matrix_con = nil

	--视频
	self.vedio_con = nil

	--用来定期分散插入数据库
	self.db_time = 0

	--
	self.flag = 0

	--判断时间以防连续刷
	self.time_d = 0

end

function Pet_vs_container:is_time_ok()
	local t_time = crypto.random(30,240) * 4
	if self.db_time + t_time <= ev.time then
		return true
	end
	return false
end

function Pet_vs_container:get_db_time()
	return self.db_time
end

function Pet_vs_container:set_db_time(time)
	self.db_time = time
end

function Pet_vs_container:get_vedio_con()
	return self.vedio_con
end

function Pet_vs_container:set_vedio_con(vedio_con)
	self.vedio_con = vedio_con
end

function Pet_vs_container:get_count()
	return self.count
end

function Pet_vs_container:set_count(count)
	self.count = count
end


function Pet_vs_container:get_char_id()
	return self.obj_id
end

function Pet_vs_container:get_vs_list()
	return self.vs_list
end

function Pet_vs_container:set_vs_list(vs_list)
	self.vs_list = vs_list
end

--设置胜负盘数 flag:1 为胜 2为负
function Pet_vs_container:set_winning(flag)
	self.vs_list[flag] = self.vs_list[flag] + 1
end

function Pet_vs_container:get_team_name()
	return self.team_name
end

function Pet_vs_container:set_team_name(name)
	self.team_name = name
end

function Pet_vs_container:get_time_span()
	return self.time_span
end

function Pet_vs_container:set_time_span(time_span)
	local count = self:get_count()
	if count%5 == 0 and count ~= 0 then
		self.time_span = time_span
	else
		self.time_span = 0
	end
end

function Pet_vs_container:set_pet_con(pet_con)
	self.pet_con = pet_con
end

function Pet_vs_container:get_pet_con()
	return self.pet_con
end

function Pet_vs_container:set_matrix_con(matrix_con)
	self.matrix_con = matrix_con
end

function Pet_vs_container:get_matrix_con()
	return self.matrix_con
end

function Pet_vs_container:set_strategy_con(strategy_con)
	self.strategy_con = strategy_con
end

function Pet_vs_container:get_strategy_con()
	return self.strategy_con
end

function Pet_vs_container:set_point(point)
	self.point = self.point + point
end

function Pet_vs_container:get_point()
	return self.point
end

function Pet_vs_container:get_flag()
	return self.flag
end

function Pet_vs_container:set_flag(flag)
	self.flag = flag
end

function Pet_vs_container:can_challenge()
	
	if self.count >= 20 then
		return 20916
	elseif self:get_left_time() ~= 0 then
		return 20912
	end

	if math.abs(ev.time - self.time_d) < 1 then
		return 
	else
		self.time_d = ev.time
	end

	return 0
end

function Pet_vs_container:is_count_full()
	if self.count >= 20 then
		return true
	end
	return false
end

--胜率
function Pet_vs_container:get_sum()
	local win = self.vs_list[1]
	local defeat = self.vs_list[2]
	local sum = win + defeat
	if sum == 0 then
		return 0
	end
	return math.floor((win/sum) *100)
end

function Pet_vs_container:load_pet_con(item_l)
	if self.pet_con == nil then
		self.pet_con = Pet_container(self.obj_id)
		self.pet_con:load(item_l)
	end
end

function Pet_vs_container:load_strategy_con(pack)
	if self.strategy_con == nil then 
		self.strategy_con = Strategy_container(self.obj_id)
		self.strategy_con:unseralize_to_db(pack)
		--self.strategy_con:update_strategy_obj(self.pet_con)
	end
end

function Pet_vs_container:load_matrix_con(item_l)
	if self.matrix_con == nil then
		self.matrix_con = Matrix_container(self.obj_id)
		self.matrix_con:load(item_l)
	end
end

function Pet_vs_container:load_vedio_con()
	if self.vedio_con == nil then
		self.vedio_con = Vedio_container(self.obj_id)
		self.vedio_con:load()
	end
end

function Pet_vs_container:get_left_time()
	local left_time = self.time_span + 5*60 - ev.time
	if left_time < 0 then
		left_time = 0
	end
	return left_time
end

function Pet_vs_container:get_net_info()

	local ret = {}

	--基本信息
	ret.base_info = {}
	ret.base_info[1] = self.team_name
	ret.base_info[2] = self.point
	ret.base_info[3] = g_pet_vs_mgr:get_rank_by_id(self.obj_id)
	ret.base_info[4] = self:get_vs_list()
	ret.base_info[5] = self:get_left_time()
	ret.base_info[6] = 20 - self:get_count()

	--策略
	ret.strategy_info = self.strategy_con:get_net_info()

	--挑战列表
	ret.chellange_info = g_pet_vs_mgr:get_char_info(self.obj_id)

	--冠军
	ret.win_info = g_pet_vs_mgr:get_first_info()

	return ret
end


function Pet_vs_container:load(item_l)
	self:load_pet_con(item_l)
	self:load_vedio_con()
	if item_l == nil then
		self:load_strategy_con()
		--self:load_matrix_con()
	else
		if table.size(item_l.strategy) ~= 9 then
		 	self:load_strategy_con()
		else
			self:load_strategy_con(item_l.strategy)
		end
		--self:load_matrix_con(item_l.matrix or {})
	end
end

function Pet_vs_container:get_challenge_time()
	return self.challenge_time
end

function Pet_vs_container:set_challenge_time(time)
	self.challenge_time = time or 0
end

function Pet_vs_container:set_worship_time(time)
	self.worship_time = time or 0
end

function Pet_vs_container:get_worship_time()
	return self.worship_time
end

function Pet_vs_container:serialize_to_db()
	local ret = {}
	ret.char_id = self.obj_id
	ret.vs_list = self.vs_list
	ret.team_name = self.team_name
	ret.count = self.count 
	ret.strategy = self.strategy_con:seralize_to_db()
	--ret.matrix = self.matrix_con:seralize_to_db()
	ret.time_span = self.time_span
	ret.point = self.point
	ret.challenge_time = self.challenge_time
	ret.worship_time = self.worship_time

	return ret
end

function Pet_vs_container:get_day_time(time)
	local l_time = time or self.challenge_time
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

function Pet_vs_container:is_other_day(num)     --上线时判断
	if num == nil then num = 1 end
	if ev.time >= self:get_day_time(self.challenge_time) + num * 86400 then
		self.count = 0
		self.challenge_time = ev.time
		return true
	end
	return false
end

function Pet_vs_container:is_other_worship_time(num)
	if num == nil then num = 1 end
	if ev.time >= self:get_day_time(self.worship_time) + num * 86400 then
		self.worship_time = 0
		return true
	end
	return false
end

function Pet_vs_container:update_container()
	local db = f_get_db()
	local ret = self:serialize_to_db()
	local condition = string.format("{char_id:%d}",self.obj_id)
	db:update("pet_fight",condition,Json.Encode(ret),true)
end

function Pet_vs_container:insert_container()
	local db = f_get_db()
	local ret = self:serialize_to_db()
	db:insert("pet_fight",Json.Encode(ret))
end

