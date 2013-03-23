
Activation_obj = oo.class(nil, "Activation_obj")

function Activation_obj:__init()
	self.reward = {}
	self.reward_list = {}
	self.type_list = {}

	local dbh = f_get_db()

	local rows, e_code = dbh:select("active_key")
	if rows ~= nil and e_code == 0 then
		for k,v in pairs(rows) do
			local key_id = v.key_id
			local type = v.type
			if key_id ~= nil and key_id ~= "" then
				if self.reward_list[key_id] == nil then
					self.reward_list[key_id] = {}
				end
				self.reward_list[key_id].flag = v.flag
				self.reward_list[key_id].type = v.type
			end
			if type ~= nil and type ~= "" then
				if self.type_list[type] == nil then
					self.type_list[type] = {}
				end
				if v.char_id ~= nil and v.char_id ~= "" then
					self.type_list[type][v.char_id] = 1
				end
			end
		end
	end

	self:load_reward()
end

function Activation_obj:load_key()
	self.reward_list = {}
	self.type_list = {}

	local dbh = f_get_db()

	local rows, e_code = dbh:select("active_key")
	if rows ~= nil and e_code == 0 then
		for k,v in pairs(rows) do
			local key_id = v.key_id
			local type = v.type
			if key_id ~= nil and key_id ~= "" then
				if self.reward_list[key_id] == nil then
					self.reward_list[key_id] = {}
				end
				self.reward_list[key_id].flag = v.flag
				self.reward_list[key_id].type = v.type
			end
			if type ~= nil and type ~= "" then
				if self.type_list[type] == nil then
					self.type_list[type] = {}
				end
				if v.char_id ~= nil and v.char_id ~= "" then
					self.type_list[type][v.char_id] = 1
				end
			end
		end
	end
end

function Activation_obj:load_reward()
	self.reward = {}
	local dbh = f_get_db()
	local t_rows,e_code = dbh:select("active_reward")
	if t_rows ~= nil and e_code == 0 then
		for k,v in pairs(t_rows) do
			local type = tonumber(v.type)
			if self.reward[type] == nil then
				self.reward[type] = {}
			end
			local ret = {}
			ret[1] = tonumber(v.item_id)
			ret[2] = tonumber(v.count)

			table.insert(self.reward[type], ret)
		end
	end
end

--玩家利用激活码领取礼包的各种情况
function Activation_obj:can_be_fetch(char_id,key)
	if self.reward_list[key] ~= nil  then
		if self.reward_list[key].flag == 1 then
			return 20702,nil
		end
		local type = self.reward_list[key].type
		if self.type_list[type][char_id] == 1 then 
			return 20700,nil         --已领取
		else
			return 0,type
		end	
	end

	return 20701,nil								
end

function Activation_obj:get_activation_reward(type)
	return self.reward[type]
end

function Activation_obj:fetch_item(char_id,key,type)
	local item = self:get_activation_reward(type)
	if item == nil then return end 
	
	local item_id_list = {}
	for k,v in pairs(item or {})do
		item_id_list[k] = {}
		item_id_list[k].type = 1
		item_id_list[k].item_id = tonumber(v[1])
		item_id_list[k].number = v[2]
	end

	local name = g_player_mgr.all_player_l[char_id].char_nm
	self:update_flag(key,name,char_id,type)
	return 0, item_id_list
end

function Activation_obj:update_flag(key,name,char_id,type)
	local dbh = f_get_db()
	local data = {}
	data.flag = 1
	data.char_name = name
	data.char_id = char_id
	data.time = ev.time
	local query = string.format("{key_id:'%s'}",key)
	local err_code = dbh:update("active_key",query,Json.Encode(data))
	if err_code == 0 then
		if self.reward_list[key] == nil then
			self.reward_list[key] = {}
		end
		self.reward_list[key].flag = 1
		self.reward_list[key].type = type
		if self.type_list[type] == nil then
			self.type_list[type] = {}
		end
		self.type_list[type][char_id] = 1
	end
end

Activation_obj:__init()


