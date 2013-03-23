

--≈‰≈ºπÿœµ
Pet_breed_syn_mgr = oo.class(nil, "Pet_breed_syn_mgr")

function Pet_breed_syn_mgr:__init()
	self.breed_list = {}
end

function Pet_breed_syn_mgr:get_spouse_id(s_id)
	for k, v in pairs(self.breed_list or {}) do
		if v[1] == s_id then
			return v[2]
		elseif v[2] == s_id then
			return v[1]
		end
	end
end

function Pet_breed_syn_mgr:add_spouse_id(s_id_1, s_id_2)
	for k, v in pairs(self.breed_list or {}) do
		if v[1] == s_id_1 or v[1] == s_id_2 or v[2] == s_id_1 or v[2] == s_id_2 then
			return
		end
	end
	table.insert(self.breed_list,{s_id_1, s_id_2})
end

function Pet_breed_syn_mgr:del_spouse_id(s_id)
	for k, v in pairs(self.breed_list or {}) do
		if v[1] == s_id or v[2] == s_id then
			table.remove(self.breed_list,k)
		end
	end
end


function Pet_breed_syn_mgr:get_breed_info()
	return self.breed_list
end

function Pet_breed_syn_mgr:serialize_to_db()
	local ret = {}
	ret.data = self.breed_list
	return ret
end

function Pet_breed_syn_mgr:update_spouse()
	local db = f_get_db()
	local ret = self:serialize_to_db()
	local condition = string.format("{id:%d}",1)
	db:update("pet_breed_spouse",condition,Json.Encode(ret),true)
end

function Pet_breed_syn_mgr:load()
	local db = f_get_db()
	local data = "{data:1}"
	local condition = string.format("{id:%d}",1)
	local row, e_code = db:select_one("pet_breed_spouse",data, condition)
	if 0 == e_code and row then
		self.breed_list = row.data
	end
end





