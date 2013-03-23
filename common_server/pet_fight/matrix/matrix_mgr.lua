
local matrix_config = require("config.matrix_config")


Matrix_mgr = oo.class(nil, "Matrix_mgr")

function Matrix_mgr:__init()
	self.matrix_list = {}

	self:build_matrix_list()
end

function Matrix_mgr:build_matrix_list()
	for k, v in pairs(matrix_config.matrix) do
		self.matrix_list[k] = Matrix_obj(k)
	end
end

function Matrix_mgr:get_matrix(matrix_id)
	return self.matrix_list[matrix_id]
end







