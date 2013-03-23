local _pet_off = 1000000000

Pet_sort_mgr = oo.class(nil, "Pet_sort_mgr")

function Pet_sort_mgr:__init()
	self.pet_sort = {}
end

function Pet_sort_mgr:db_load(pet_id)
	if self.pet_sort[pet_id] == nil then
		local m_db = f_get_db()
		local data = "{data:1}"
		local query = string.format("{id:%d}", pet_id)
		local row, e_code = m_db:select_one("pet_sort_info", data, query, nil, "{id:1}")
		if row == nil then return end
		
		self.pet_sort[pet_id] = row.data
	end
end

function Pet_sort_mgr:clear(pet_id)
	self.pet_sort[pet_id] = nil
end

function Pet_sort_mgr:get_pet_info(pet_id)
	return self.pet_sort[pet_id]
end

function Pet_sort_mgr:syn_info(pet_id, pet_info)
	self.pet_sort[pet_id] = pet_info
end


function Pet_sort_mgr:syn(char_id,pet_id, char_id_s, line_s)
	local node = {}
	node.char_id_s = char_id_s
	node.pet_id = pet_id
	node.line = line_s
	node.char_id = char_id

	local line = g_player_mgr:get_char_line(char_id)
	g_sock_event_mgr:add_event_count(char_id, CMD_M2P_PET_SORT_SYN_S, self, self.call_back_syn, nil, node, 3, node)
	g_server_mgr:send_to_server(line, char_id, CMD_P2M_PET_SORT_SYN_C, node)
end

function Pet_sort_mgr:call_back_syn(node,pkt)
	local char_id = node.char_id_s
	local line = node.line
	local pet_id = node.pet_id
	self.pet_sort[pet_id] = pkt
	g_server_mgr:send_to_server(line, char_id, CMD_P2M_PET_SORT_INFO_S, pkt)
end




