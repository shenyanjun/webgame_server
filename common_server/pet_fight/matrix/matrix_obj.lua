
local matrix_config = require("config.matrix_config")
local matrix_name_config = require("config.loader.matrix_name_loader")

Matrix_obj = oo.class(nil, "Matrix_obj")

function Matrix_obj:__init(matrix_id)
	self.matrix_id = matrix_id

	self.occ_list = matrix_config.matrix[matrix_id]
	self.name = matrix_name_config[matrix_id]

end

function Matrix_obj:get_matrix_id()
	return self.matrix_id
end

function Matrix_obj:get_matrix_name()
	return self.name
end

function Matrix_obj:get_attr_percent()
	return 
end

-- attr_index : 属性index 得到的结果例如{1,0.5}  1为值 0.5为比率
function Matrix_obj:get_attr(index, attr_index)
	local occ_attr = self.occ_list[index][attr_index]
	return occ_attr
end

function Matrix_obj:get_all_attr(index)
	local occ_attr = self.occ_list[index]

	return occ_attr
	--local value_attr = {}
	--local key_attr = {}
	--for k, v in pairs(occ_attr or {}) do
		--if k <= 16 then
			--table.insert(value_attr, v[1])
			--table.insert(key_attr, v[2])
		--end
	--end
	--return value_attr, key_attr
end







