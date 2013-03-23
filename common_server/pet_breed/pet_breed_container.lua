--每个人的宠物蛋
Pet_breed_container = oo.class(nil, "Pet_breed_container")

function Pet_breed_container:__init(char_id)
	self.char_id = char_id
	self.breed_list = {}

	--用来定期分散插入数据库
	self.db_time = 0

	--是否通知邮件
	self.flag = 0  -- 0 不通知 1为通知
end

function Pet_breed_container:is_time_ok()
	local t_time = crypto.random(32,212) *4
	if self.db_time + t_time <= ev.time then
		return true
	end
	return false
end

function Pet_breed_container:get_db_time()
	return self.db_time
end

function Pet_breed_container:set_db_time(time)
	self.db_time = time
end

function Pet_breed_container:get_flag()
	return self.flag
end

function Pet_breed_container:set_flag(flag)
	self.flag = flag
end

function Pet_breed_container:add_breed(occ,bind,breed_time,attr_sum,skill_percent,count) -- count 为特殊技能个数
	table.insert(self.breed_list, {occ,bind,breed_time,attr_sum,skill_percent,count})
end

function Pet_breed_container:del_breed()
	local ret = {}
	local k_table = {}
	for k,v in pairs(self.breed_list) do
		if v[3] <= ev.time then
			table.insert(ret, v)
			self.breed_list[k] = nil
		end
	end
	self:set_flag(0)

	return ret
end

function Pet_breed_container:get_breed_list()
	local ret = {}
	ret[1] = self.char_id
	ret[2] = self.breed_list
	return ret
end

function Pet_breed_container:set_breed_list(breed_list)
	self.breed_list = breed_list
end

function Pet_breed_container:get_char_id()
	return self.char_id
end

function Pet_breed_container:serialize_db()
	return self.breed_list
end

function Pet_breed_container:load_container()
	local db = f_get_db()
	local data = "{breed_list:1}"
	local condition = string.format("{char_id:%d}",self.char_id)
	local row, e_code = db:select_one("pet_breed_egg",data, condition)
	if 0 == e_code and row then
		self.breed_list = row.breed_list
	end
end

function Pet_breed_container:update_container()
	local db = f_get_db()
	local ret = {} 
	ret.breed_list = self:serialize_db()
	local condition = string.format("{char_id:%d}",self.char_id)
	db:update("pet_breed_egg",condition,Json.Encode(ret),true)
end


function Pet_breed_container:can_insert_email()
	for k,v in pairs(self.breed_list or {}) do
		if v[3] <= ev.time then
			self:set_flag(1)
			return true
		end
	end

	return false
end


