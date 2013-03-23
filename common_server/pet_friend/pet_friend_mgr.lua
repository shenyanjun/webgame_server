local data_base = "pet_friend"

Pet_friend_mgr = oo.class(nil, "Pet_friend_mgr")

function Pet_friend_mgr:__init()
	self.container_list = {}
end

function Pet_friend_mgr:get_container(char_id)
	if self.container_list[char_id] == nil then
		self.container_list[char_id] = Pet_friend_container(char_id)
	end
	return self.container_list[char_id]
end

function Pet_friend_mgr:get_container_ex(char_id)
	return self.container_list[char_id]
end

function Pet_friend_mgr:del_container(char_id)
	self.container_list[char_id] = nil
end

function Pet_friend_mgr:get_net_info()
	local ret = {}
	for k,v in pairs(self.container_list) do
		local info = v:get_net_info()
		for m,n in pairs(info) do
			table.insert(ret,n)
		end
	end

	return ret
end

function Pet_friend_mgr:serialize_to_db_ex()
	local ret = {}
	for k,v in pairs(self.container_list) do
		local info = v:serialize_to_db()
		for m,n in pairs(info) do
			table.insert(ret,n)
		end
	end

	return ret
end

function Pet_friend_mgr:serialize_to_db()
	local ret = {}
	ret.id = 1
	ret.data = self:serialize_to_db_ex()

	local db = f_get_db()
	local condition = string.format("{id:%d}",1)
	db:update(data_base,condition,Json.Encode(ret),true)
end

function Pet_friend_mgr:load()
	local dbh = f_get_db()
	local data = "{data:1}"
	local query =string.format("{id:%d}",1)
	local row, e_code = dbh:select_one(data_base, data, query)
	if row ~= nil then
		for k, v in pairs(row.data or {}) do
			local char_id = v[1]
			local container = self:get_container(char_id)
			container:add_pet_ex(v)
		end
	end
end

