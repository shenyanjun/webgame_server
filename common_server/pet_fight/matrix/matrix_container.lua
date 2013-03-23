

Matrix_container = oo.class(nil, "Matrix_container")

function Matrix_container:__init(obj_id)
	self.obj_id = obj_id

	self.matrix_list = {}
end

function Matrix_container:get_matrx_obj(matrix_id)
	return self.matrix_list[matrix_id]
end

function Matrix_container:add_matrix_obj(matrix_obj)
	local matrix_id = matrix_obj:get_matrix_id()
	self.matrix_list[matrix_id] = matrix_obj
end

function Matrix_container:is_in_matrix(matrix_id)
	if self.matrix_list[matrix_id] == nil then 
		return false
	end
	return true
end

function Matrix_container:get_net_info()
	local ret = {}
	for k, v in pairs(self.matrix_list or {}) do
		local t = {}
		t[1] = v:get_matrix_id()
		t[2] = v:get_matrix_name()
		table.insert(ret, t)
	end

	return ret
end

function Matrix_container:seralize_to_db()
	local ret = {}
	for k, v in pairs(self.matrix_list or {}) do
		local id = v:get_matrix_id()
		table.insert(ret, id)
	end

	return ret
end

function Matrix_container:load(item_l)
	for k, v in pairs(item_l or {}) do
		local matrix_obj = g_matrix_mgr:get_matrix(v)
		self:add_matrix_obj(matrix_obj)
	end
end


