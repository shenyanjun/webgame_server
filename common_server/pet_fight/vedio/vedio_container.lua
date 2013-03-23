

Vedio_container = oo.class(nil, "Vedio_container")

function Vedio_container:__init(char_id)
	self.char_id = char_id

	self.vedio_list = {}
end

function Vedio_container:get_vedio(id)
	for k,v in pairs(self.vedio_list) do
		if v:get_id() == id then
			return v
		end
	end
end

function Vedio_container:set_vedio(vedio)
	--local id = vedio:get_id()
	--self.vedio_list[id] = vedio
	table.insert(self.vedio_list,vedio)
end

function Vedio_container:get_net_info()
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

function Vedio_container:clear()
	self.vedio_list = {}
end


function Vedio_container:load()

	--local db = f_get_db()
	--local rows, e_code = db:select("pet_fight_vedio", nil, string.format("{$or:[{winner:%d}, {loser:%d}]}", self.char_id,self.char_id))
--
	--if 0 == e_code and rows then
		--for k, v in pairs(rows) do
			--local winner = v.winner
			--local loser = v.loser
			--local id = v.vedio_id
			--local vedio = Vedio(v.type)
			--vedio:set_id(id)
			--vedio:set_start_time(v.start_time)
			--vedio:set_winner(v.winner)
			--vedio:set_loser(v.loser)
			--vedio:set_vedio_list_ex(v.vedio_list)
--
			--self:set_vedio(vedio)
		--end
	--end
end