

local pet_friend_time = 72 * 60 *60
local hour =  60 * 60

Pet_friend_container = oo.class(nil,"Pet_friend_container")

function Pet_friend_container:__init(char_id)
	self.char_id = char_id
	self.pet_list = {}
end

function Pet_friend_container:get_char_id()
	return self.char_id
end

--pet_data: {char_id,char_name,pet_id,pet_name,pullulate,skill_count,time,content,occ}
function Pet_friend_container:add_pet(pet_data)
	local pet_id = pet_data[3]
	if self.pet_list[pet_id] == nil then
		self.pet_list[pet_id] = {}
	end

	local time = self.pet_list[pet_id][7]
	if time == nil or time == 0 or time < ev.time then
		pet_data[7] = ev.time + pet_data[7] * hour
	else
		pet_data[7] = time + pet_data[7] * hour
	end

	self.pet_list[pet_id] = pet_data
end

function Pet_friend_container:update_info(pet_id, skill_count, pullulate)
	if self.pet_list[pet_id] ~= nil then
		self.pet_list[pet_id][6] = skill_count
		self.pet_list[pet_id][5] = pullulate
	end
end

function Pet_friend_container:add_pet_ex(pet_data)
	local pet_id = pet_data[3]
	if self.pet_list[pet_id] == nil then
		self.pet_list[pet_id] = {}
	end

	local time = self.pet_list[pet_id][7]
	if time == nil or time == 0 or time < ev.time then
		self.pet_list[pet_id] = pet_data
	else
		pet_data[7] = time + pet_data[7]
		self.pet_list[pet_id] = pet_data
	end
end

function Pet_friend_container:del_pet(pet_id)
	self.pet_list[pet_id] = nil
end

function Pet_friend_container:get_pet(pet_id)
	return self.pet_list[pet_id]
end

function Pet_friend_container:is_friend_time_ok(pet_id,time)
	if self.pet_list[pet_id] == nil then
		return false
	end

	local n_time = self.pet_list[pet_id][7]
	if n_time == nil or n_time < ev.time or n_time == 0 then
		self.pet_list[pet_id][7] = ev.time
	end

	local time_l = self.pet_list[pet_id][7] + time * hour
	if time_l - ev.time > pet_friend_time then
		return false
	end 

	return true


end

function Pet_friend_container:set_pet_data(pet_id,time,content)
	self.pet_list[pet_id][7] = self.pet_list[pet_id][7] + time * hour
	self.pet_list[pet_id][8] = content
end

function Pet_friend_container:serialize_to_db()
	local ret = {}
	for k,v in pairs(self.pet_list) do
		table.insert(ret,v)
	end

	return ret
end

function Pet_friend_container:get_net_info()
	local ret = {}
	for k,v in pairs(self.pet_list) do
		if v[7] > ev.time then
			local t_ret = {}
			t_ret[1] = v[1]
			t_ret[2] = v[2]
			t_ret[3] = v[3]
			t_ret[4] = v[4]
			t_ret[5] = v[5]
			t_ret[6] = v[6]
			t_ret[7] = v[7] - ev.time
			t_ret[8] = v[8]
			t_ret[9] = v[9]
			table.insert(ret,t_ret)
		else
			self.pet_list[k] = nil
		end
	end

	return ret
end






