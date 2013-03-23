

Pet_breed_mgr = oo.class(nil, "Pet_breed_mgr")

function Pet_breed_mgr:__init()
	self.breed_container = {}
end

function Pet_breed_mgr:add_container(container)
	local char_id = container:get_char_id()
	if char_id then
		self.breed_container[char_id] = container
	end
end

function Pet_breed_mgr:del_container(char_id)
	self.breed_container[char_id] = nil
end

function Pet_breed_mgr:create_container(char_id)
	local container = Pet_breed_container(char_id)
	self:add_container(container)
	container:update_container()
	return container
end

function Pet_breed_mgr:get_container(char_id)
	return self.breed_container[char_id]
end

function Pet_breed_mgr:syn_all_breed(server_id)
	local ret = {}
	for k, v in pairs(self.breed_container or {}) do
		table.insert(ret, v:get_breed_list())
	end
	g_server_mgr:send_to_server(server_id,0,CMD_P2M_PET_BREED_ALL_SYN_S,ret)
end

function Pet_breed_mgr:load()
	local db = f_get_db()
	local rows, e_code = db:select("pet_breed_egg")
	if 0 == e_code and rows then
		for k,v in pairs(rows or {}) do
			local char_id = v.char_id
			local con = self:create_container(char_id)
			con:set_breed_list(v.breed_list)
		end
	end
end

function Pet_breed_mgr:serialize_to_db()
	for k,v in pairs(self.breed_container) do
		if v:is_time_ok() then
			v:update_container()
			v:set_db_time(ev.time)
		end
	end
end

function Pet_breed_mgr:serialize_to_db_ex()
	for k, v in pairs(self.breed_container or {}) do
		v:update_container()
	end
end

function Pet_breed_mgr:get_click_serialize_param()
	return self,self.serialize_to_db,45,nil
end

function Pet_breed_mgr:out_line(char_id)
	if self.breed_container[char_id] ~= nil then
		self.breed_container[char_id]:update_container()
		self.breed_container[char_id] = nil
	end
end

function Pet_breed_mgr:on_line(char_id)
	if self.breed_container[char_id] == nil then
		local container = Pet_breed_container(char_id)
		container:load_container()
		self:add_container(container)

		local syn_info = container:get_breed_list()
		local ret = {}
		table.insert(ret, syn_info)
		g_server_mgr:send_to_all_map(0,CMD_P2M_PET_BREED_SINGLE_SYN_S,Json.Encode(ret),true)
	end
end


function Pet_breed_mgr:get_click_serialize_param_email()
	return self,self.insert_email,120,nil
end

function Pet_breed_mgr:insert_email()
	for k, v in pairs(self.breed_container or {}) do
		local char_id = v:get_char_id()
		if g_player_mgr:is_online_char(char_id) ~= nil then
			if v:get_flag() == 0 then
				if v:can_insert_email() then
					--宠物到时间提示
					local title = f_get_string(2315)
					local content = f_get_string(2316)
					g_email_mgr:create_email(-1,char_id,title,content,0,Email_type.type_common,Email_sys_type.type_normal,nil)
				end
			end
		end
	end
end




