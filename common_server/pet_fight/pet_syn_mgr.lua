

Pet_syn_mgr = oo.class(nil, "Pet_syn_mgr")

function Pet_syn_mgr:__init()
	self.list = {}
end

function Pet_syn_mgr:create_id()
	local id = crypto.uuid()
	self.list[id] = {}
	return id
end

-- flag 1为挑战者 2 为被挑战者
function Pet_syn_mgr:insert_char(id,char_id,flag)
	self.list[id][flag] = char_id
end

function Pet_syn_mgr:get_size(id)
	return table.size(self.list[id])
end

function Pet_syn_mgr:clear(id)
	self.list[id] = nil
end

function Pet_syn_mgr:get_char(id, flag)
	return self.list[id][flag]
end

Pet_syn_mgr:__init()