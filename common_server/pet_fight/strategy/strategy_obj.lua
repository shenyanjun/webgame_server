


Strategy_obj = oo.class(nil, "Strategy_obj")

function Strategy_obj:__init()
	self.matrix = 0
	self.pet_list = {}
	self.pet_list[1] = 0
	self.pet_list[2] = 0
	self.pet_list[3] = 0
	self.pet_list[4] = 0

	self.attr = {}

	self.matrix_ex = 0
	self.pet_list_ex ={}
	self.pet_list_ex[1] = 0
	self.pet_list_ex[2] = 0
	self.pet_list_ex[3] = 0
	self.pet_list_ex[4] = 0
end

function Strategy_obj:init_pet_list_ex(pet_con)
	for i = 1,4 do
		self.pet_list_ex[i] = self.pet_list[i]
	end
	--self.pet_list_ex = self.pet_list
	for i = 1, 4 do
		if self.pet_list_ex[i] == 0 or self.pet_list_ex[i]== nil then
			for k, v in pairs(pet_con.pet_list or {}) do
				if self:can_be_insert_pet(v) then
					self.pet_list_ex[i] = v
				end
			end
		end
	end
end

function Strategy_obj:set_matrix(matrx_obj)
	self.matrix = matrx_obj
	self.matrix_ex = matrix_obj
end

function Strategy_obj:get_matrix()
	return self.matrix
end

function Strategy_obj:can_be_insert_pet(pet_obj)
	local pet_id = pet_obj:get_pet_id()
	for k, v in pairs (self.pet_list_ex or {}) do
		if v ~=0 and v~= nil then
			if v:get_pet_id() == pet_id then
				return false
			end
		end
	end
	return true
end

function Strategy_obj:can_be_set_pet_obj(pet_obj)
	if pet_obj == nil then return true end
	local pet_id = pet_obj:get_pet_id()
	for k, v in pairs (self.pet_list or {}) do
		if v ~=0 and v~= nil then
			if v:get_pet_id() == pet_id then
				return false
			end
		end
	end
	return true
end

function Strategy_obj:set_pet_obj(index,pet_obj)
	self.pet_list[index] = pet_obj
	if pet_obj == nil then 
		self.pet_list[index] = 0
	end
	--self.pet_list_ex[index] = pet_obj
end

function Strategy_obj:get_pet_obj(index)
	return self.pet_list[index]
end

function Strategy_obj:get_pet_obj_ex(index)
	if self.pet_list_ex[index] == nil then
		self.pet_list_ex[index] = 0
	end
	return self.pet_list_ex[index]
end

function Strategy_obj:init_set()
	for k, v in pairs (self.pet_list_ex or {}) do
		if v ~= nil and v~= 0 then
			v:set_strategy_obj(self)
		end
	end
end

function Strategy_obj:set_attr(index)
	local matrix_obj = self:get_matrix()
	if not matrix_obj then return end

	self.attr[index] = matrix_obj:get_all_attr(index)
end

function Strategy_obj:get_attr(index)
	return self.attr[index] or {}
end

function Strategy_obj:get_index(pet_id)
	for k, v in pairs(self.pet_list_ex or {}) do
		if v~= nil and v~= 0 and pet_id == v:get_pet_id() then
			return k
		end
	end
end


function Strategy_obj:get_net_info()
	local ret = {}

	for i = 1,4 do
		if self.pet_list[i]~= 0 and self.pet_list[i]~= nil then
			local pet_id = self.pet_list[i]:get_pet_id()
			table.insert(ret, pet_id)
		else
			self.pet_list[i] = 0
			table.insert(ret, 0)
		end
	end

	local matrix_id = 0
	if self.matrix ~= nil and self.matrix ~= 0 then
		matrix_id = self.matrix:get_matrx_id()
	end
	table.insert(ret, matrix_id)

	return ret
end













