
local MAX_NUM = 5

Pet_strategy_container = oo.class(nil, "Pet_strategy_container")

function Pet_strategy_container:__init(obj_id)
	self.obj_id = obj_id
	self.strategy_list = {0,0,0,0,0,0,0,0,0}
	self.pet_obj_list = {}  --index pet_obj
	self.pet_list = {}  --pet_id index
	self.pet_num = 0  --已设置阵法个数
end

function Pet_strategy_container:get_pet_count()
	return self.pet_num
end

function Pet_strategy_container:get_pet_list()
	return self.pet_list
end

function Pet_strategy_container:get_pet(index)
	return self.pet_obj_list[index]
end

function Pet_strategy_container:get_all_pet()
	local pet_list = {}
	for k, v in pairs(self.strategy_list) do
		if v ~= 0 and v ~= -1 then
			local pet_obj = self:get_pet(k)
			table.insert(pet_list, pet_obj)
		end
	end

	return pet_list
end

function Pet_strategy_container:reset_pet(strategy)
	self:del_all_pet()
	self:add_all_pet(strategy)
end

function Pet_strategy_container:edit_pet_num(num)
	self.pet_num = self.pet_num + num
	if self.pet_num < 0 then
		self.pet_num = 0
	end
end

function Pet_strategy_container:add_pet(index, pet_id)
	if self.pet_num >= MAX_NUM then return end

	local container = g_pet_adventure_mgr:get_container(self.obj_id)
	if not container then return end

	local pet_con = container:get_pet_con()
	if not pet_con then return end

	local pet_obj = pet_con:get_pet_obj(pet_id)
	if not pet_obj then return end

	self.strategy_list[index] = pet_id
	self.pet_list[pet_id] = index
	self.pet_obj_list[index] = pet_obj
	self:edit_pet_num(1)
end

function Pet_strategy_container:del_pet_by_id(pet_id)
	local o_index = self.pet_list[pet_id]
	if o_index ~= nil then
		self.pet_list[pet_id] = nil
		self.strategy_list[o_index] = 0
		self.pet_obj_list[o_index] = nil
		self:edit_pet_num(-1)
	end
end

function Pet_strategy_container:del_pet_by_index(index)
	if index == nil then return end

	local pet_id = self.strategy_list[index]
	if pet_id ~= 0 then
		self:del_pet_by_id(pet_id)
	end
end

function Pet_strategy_container:del_all_pet()
	for k, v in pairs(self.strategy_list) do
		if v ~= 0 then
			self:del_pet_by_id(v)
		end
	end
end

function Pet_strategy_container:add_all_pet(strategy)
	for k, v in pairs(strategy) do
		if v ~= 0 then
			self:add_pet(k, v)
		end
	end
end

function Pet_strategy_container:update_strategy(pet_list)
	local pet = {}
	for k,v in pairs(self.pet_list) do
		local flag = 0
		for m, n in pairs(pet_list) do
			if m == k then
				flag = 1
				break
			end
		end

		if flag == 0 then
			table.insert(pet, v)
		end
	end

	for b, c in pairs(pet) do
		self:del_pet_by_index(c)
	end
end

function Pet_strategy_container:init_set()
	local container = g_pet_adventure_mgr:get_container(self.obj_id)
	if not container then return end

	local pet_con = container:get_pet_con()
	if not pet_con then return end

	for k, v in pairs(self.pet_list) do
		local pet_obj = pet_con:get_pet_obj(k)
		if pet_obj ~= nil then
			pet_obj:set_hp()
			self.pet_obj_list[v] = pet_obj
			local skill_con = self.pet_obj_list[v]:get_skill_con()
			skill_con:sub_all_cd()
		end
	end
end

function Pet_strategy_container:sud_all_cd()
	for k, v in pairs(self.pet_obj_list) do
		if v ~= nil and v:get_hp() > 0 then
			local skill_con = v:get_skill_con()
			skill_con:sub_cd_ex()
		end
	end
end

function Pet_strategy_container:get_pet_attr()
	local attr = {}
	local attr2 = {}
	for k, v in pairs(self.pet_obj_list) do
		if v ~= nil and v:get_hp() > 0 then
			table.insert(attr, {v:get_occ(), v:get_hp(), k, v:get_name(), v:get_level(), v:get_pullulate()})
			table.insert(attr2, {v:get_hp(), k})
		end
	end

	return attr, attr2
end

function Pet_strategy_container:get_strategy()
	return self.strategy_list
end

function Pet_strategy_container:serialize_to_db()
	return self.strategy_list
end

function Pet_strategy_container:unserialize_to_db(pack)
	if pack == nil then return end

	self.strategy_list = pack
	--self.slot_count = 0
	for k, v in ipairs(self.strategy_list) do
		if v ~= 0 then
			self.pet_list[v] = k
			self:edit_pet_num(1)
		end
	end
end



