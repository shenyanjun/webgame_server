Account_cache = oo.class(nil, "Account_cache")

function Account_cache:__init()
	self.account_cache = {}
	self.obj_cache = {}
	self.has_server_id = false
	self.server_list = {}
end

function Account_cache:get_server_list()
	return self.server_list
end

function Account_cache:load(low, high)
	local db = f_get_db()
	local rows, e_code = db:select("server_list", "{_id:0, server_id:1}", nil, nil, 0, 0, "{server_id:1}")
	if 0 == e_code and rows then
		for _, row in ipairs(rows) do
			self.has_server_id = true
			table.insert(self.server_list, row.server_id)
		end
	end

	if not self.has_server_id then
		table.insert(self.server_list, SERVER_ID)
	end

	local query = Json.Encode({["level"] = {["$gte"] = low, ["$lte"] = high}})
	local fields = "{_id:0, account_name:1, server_id:1, id:1}"
	rows, e_code = db:select("characters", fields, query, nil, 0, 0, "{level:1}")
	if 0 == e_code and rows then
		for _, row in ipairs(rows) do
			if not row.server_id then
				row.server_id = SERVER_ID
			end
			self.obj_cache[row.id] = {row.account_name, row.server_id, row.id}
			local cache_list = self.account_cache[row.server_id]
			if not cache_list then
				cache_list = {}
				self.account_cache[row.server_id] = cache_list
			end
			cache_list[row.account_name] = {row.account_name, row.server_id, row.id}
		end
	end
end

function Account_cache:find(obj_id)
	local cache = self.obj_cache[obj_id]	
	if obj_id and not cache then
		local query = string.format("{id:%d}", obj_id)
		local fields = "{_id:0, account_name:1, server_id:1, id:1}"
		local row, e_code = f_get_db():select_one("characters", fields, query, nil, "{id:1}")
		if 0 == e_code and row then
			if not row.server_id then
				row.server_id = SERVER_ID
			end
			cache = {row.account_name, row.server_id, row.id}
			self.obj_cache[row.id] = cache
		end
	end
	return cache
end

function Account_cache:find_of_account(server_id, account_name)
	local cache = self.account_cache[server_id] and self.account_cache[server_id][account_name]
	if server_id and account_name and not cache then
		local query = Json.Encode({["account_name"] = account_name})
		local fields = "{_id:0, account_name:1, server_id:1, id:1}"
		local rows, e_code = f_get_db():select("characters", fields, query, nil, 0, 0, "{account_name:1}")
		if 0 == e_code and rows then
			for _, row in ipairs(rows) do
				if not row.server_id then
					row.server_id = SERVER_ID
				end
				
				local info = {row.account_name, row.server_id, row.id}
				if server_id == row.server_id then
					cache = info
				end
				
				local cache_list = self.account_cache[row.server_id]
				if not cache_list then
					cache_list = {}
					self.account_cache[row.server_id] = cache_list
				end
				
				cache_list[row.account_name] = info
			end
		end		
	end
	
	return cache and cache[3]
end