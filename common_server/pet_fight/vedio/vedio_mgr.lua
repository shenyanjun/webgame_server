

Vedio_mgr = oo.class(nil, "Vedio_mgr")

function Vedio_mgr:__init()
	self.container_list = {}

	self.vedio_list = {}
end

function Vedio_mgr:get_container(char_id)
	return self.container_list[char_id]
end

function Vedio_mgr:add_container(container)
	local char_id = container:get_char_id()
	self.container_list[char_id] = container
end

function Vedio_mgr:del_container(char_id)
	self.container_list[char_id] = nil
end

function Vedio_mgr:add_vedio(vedio)
	local id = vedio:get_id()
	self.vedio_list[id] = vedio
end

function Vedio_mgr:del_vedio(id)
	self.vedio_list[id] = nil
end

function Vedio_mgr:create_vedio(type)
	local vedio =Vedio(type)
	return vedio
end

function Vedio_mgr:load()
	
end

