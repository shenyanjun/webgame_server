
Statue_obj = oo.class(nil, "Statue_obj")

function Statue_obj:__init(id, data)
	self.id = id
	self.char_id = data.char_id
	self.worship_list = {}     --膜拜标记
	self.worship_count = 0
	self.noworship_count = 0
	self.attr = g_player_mgr:get_player_attr(self.char_id)  --人物属性
	self.base = self:db_get_base_info(self.char_id)
	self.autograph = nil             --签名
end

function Statue_obj:set_autograph(aug)
	self.autograph = aug
end
function Statue_obj:get_autograph()
	return self.autograph
end

function Statue_obj:add_worship(char_id, flag)
	if self.worship_list[char_id] == nil then
		self.worship_list[char_id] = flag
		if flag == 0 then
			self.worship_count = self.worship_count + 1
			
			--广播
			if self.worship_count%50 == 0 then
				local new_pkt = {}
				new_pkt[1] = string.format(f_get_string(2051), self.worship_count)
				new_pkt[2] = self.id
				new_pkt[3] = self.base[2] or "human"
				new_pkt[4] = self.char_id
				
				new_pkt = Json.Encode(new_pkt)
				local online_l = g_player_mgr:get_online_player()
				for k,v in pairs(online_l or {}) do
					g_svsock_mgr:send_server_ex(WORLD_ID, k, CMD_C2B_STATUE_BROADCAST_S, new_pkt, true)
				end
			end
		else
			self.noworship_count = self.noworship_count + 1
		end
		
		return 0
	end
	return 20871
end

function Statue_obj:clear_worship()
	self.worship_list = {}
	self.worship_count = 0
	self.noworship_count = 0
end

function Statue_obj:get_worship_count()
	return self.worship_count
end
function Statue_obj:get_noworship_count()
	return self.noworship_count
end

--网络
function Statue_obj:net_get_info()
	if self.base ~= nil then
		local tb = {}
		tb[1] = self.char_id
		tb[2] = self.attr
		tb[3] = self:net_get_worship()
		tb[4] = self.base
		tb[5] = self.autograph
		return tb 
	end
end

function Statue_obj:net_get_worship()
	return {self.worship_count, self.noworship_count}
end

--数据库
function Statue_obj:db_get_base_info(char_id)
	local db = f_get_db()	local namespace = "sort_info"	local fields = "{_id:0, char_id:1, name:1, class:1, gender:1, faction_id:1, faction_nm:1}"	local query = string.format("{char_id:%d}", char_id)	local row, e_code = db:select_one(namespace, fields, query)
	if row ~= nil then
		local tb = {}
		tb[1] = row.char_id
		tb[2] = row.name
		tb[3] = row.class
		tb[4] = row.gender
		tb[5] = {row.faction_id, row.faction_nm}
		return tb
	else
		local namespace_c = "characters"		local fields_c = "{_id:0, id:1, name:1, class:1, gender:1}"		local query_c = string.format("{id:%d}", char_id)

		local row_c, e_code = db:select_one(namespace_c, fields_c, query_c)		
		if row_c ~= nil then
			local tb = {}
			tb[1] = row_c.id
			tb[2] = row_c.name
			tb[3] = row_c.class
			tb[4] = row_c.gender

			local namespace_f = "faction"			local fields_f = "{_id:0, factioner_id:1, faction_name:1}"			local query_f  = string.format("{factioner_id:%d}", char_id)

			local row_f, e_code = db:select_one(namespace_f, fields_f, query_f)	
			if row_f~= nil then
				tb[5] = {row_f.factioner_id, row_f.faction_name}
				return tb
			end
		end
	end
end