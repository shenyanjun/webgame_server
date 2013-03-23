

Human_vedio_mgr = oo.class(nil, "Human_vedio_mgr")

function Human_vedio_mgr:__init()
	self.container_list = {}

	self.vedio_list = {}
end

function Human_vedio_mgr:get_container(char_id)
	return self.container_list[char_id]
end

function Human_vedio_mgr:add_container(container)
	local char_id = container:get_char_id()
	self.container_list[char_id] = container
end

function Human_vedio_mgr:del_container(char_id)
	self.container_list[char_id] = nil
end

function Human_vedio_mgr:add_vedio(vedio)
	local id = vedio:get_id()
	self.vedio_list[id] = vedio
end

function Human_vedio_mgr:del_vedio(id)
	self.vedio_list[id] = nil
end

function Human_vedio_mgr:create_vedio(type)
	local vedio =Human_vedio(type)
	return vedio
end

function Human_vedio_mgr:load()
	
end

