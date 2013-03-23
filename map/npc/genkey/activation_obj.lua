

--local debug_print = print
local debug_print = function() end
--local activation_loader = require("config.activation_config")
local activation_loader = require("config.loader.activation_config_loader")

Activation_obj = oo.class(nil, "Activation_obj")

function Activation_obj:init()
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
			local dbh = f_get_db()
			local query = string.format("{key_id:'%s'}",key)
			local row, e_code = dbh:select_one("active_key", nil, query,"{key_id:1}")
			if 0 == e_code and row then
				if row.flag == 1 then
					self.reward_list[key].flag = 1
					self.type_list[row.type][row.char_id]=1
					return 20702,nil
				end
			end
			local query = string.format("{char_id:%d,type:%d}",char_id,type)
			local row, e_code = dbh:select_one("active_key", nil, query,"{char_id:1,type:1}")
			if 0 == e_code and row then
				return 20700, nil
			end
			return 0,type
		end
	else
		--local dbh = f_get_db()
		--local query = string.format("{char_id:%d,type:%d}", char_id,type)
		--local row, e_code = dbh:select_one("active_key", nil, query,"{char_id:1,type:1}")
		--if 0 == e_code and row then
			--return 20700
		--end

		local type
		local dbh = f_get_db()
		local query = string.format("{key_id:'%s'}", key)
		local fields = "{char_id:1,type:1,flag:1}"
		local row, e_code = dbh:select_one("active_key", fields, query,"{key_id:1}")
		if 0 == e_code and row then
			if row.flag == 1 then
				return 20702,nil
			end
			if row.type ~= nil or row.type ~= "" then
				if self.type_list[row.type] == nil then
					return 0, row.type
				end
				if row.char_id ~= nil and row.char_id ~= "" then
					return 20700, nil
				else
					if self.type_list[row.type][char_id] == 1 then
						return 20700, nil
					else
						type = row.type
					end
				end
			else
				return 20702,nil
			end
		end
		if type ~= nil then
			local query = string.format("{char_id:%d,type:%d}",char_id,type)
			local row, e_code = dbh:select_one("active_key", nil, query,"{char_id:1,type:1}")
			if 0 == e_code and row then
				return 20700, nil
			else
				return 0, type
			end
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

	local player = g_obj_mgr:get_obj(char_id)
	local pack_con = player:get_pack_con()
	
	local item_id_list = {}
	for k,v in pairs(item or {})do
		item_id_list[k] = {}
		item_id_list[k].type = 1
		item_id_list[k].item_id = tonumber(v[1])
		item_id_list[k].number = v[2]
	end

	local free_slot = pack_con:get_bag_free_slot_cnt()
	if free_slot <=0  then
		return 43004
	end

	if pack_con:add_item_l(item_id_list, {['type']=ITEM_SOURCE.NOVICE}) ~= 0 then
		return 27003
	end
	local name = player:get_name()
	self:update_flag(key,name,char_id,type)
	return 0
end

function Activation_obj:update_flag(key,name,char_id,type)
	--local str = string.format("update gift_newer set flag =1,char_name = '%s',char_id = %d,time = %d where key_id = '%s'",name,char_id,ev.time,key)
	--local dbh = get_dbh_web()
	--dbh:execute(str)

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

Activation_obj:init()