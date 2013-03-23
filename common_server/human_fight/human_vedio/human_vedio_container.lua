

Human_vedio_container = oo.class(nil, "Human_vedio_container")

function Human_vedio_container:__init(char_id)
	self.char_id = char_id

	self.vedio_list = {}
end

function Human_vedio_container:get_vedio(id)
	for k,v in pairs(self.vedio_list) do
		if v:get_id() == id then
			return v
		end
	end
end

function Human_vedio_container:set_vedio(vedio)
	--local id = vedio:get_id()
	--self.vedio_list[id] = vedio
	table.insert(self.vedio_list,vedio)
end

function Human_vedio_container:get_net_info()
	local ret = {}
	local count = table.size(self.vedio_list)
	if count <= 30 then
		for k,v in pairs(self.vedio_list) do
			local t = v:get_net_info()
			table.insert(ret,t)
		end
	else
		local index = 1
		local list = {}
		for k,v in pairs(self.vedio_list) do
			if index > count -30 then
				local t = v:get_net_info()
				table.insert(ret,t)
			else
				table.insert(list,k)
			end
			index = index + 1
		end

		for k,v in pairs(list) do
			table.remove(self.vedio_list,k)
		end
	end
	return ret
end

function Human_vedio_container:clear()
	self.vedio_list = {}
end


function Human_vedio_container:load()

end