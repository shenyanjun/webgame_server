
Key_mgr = oo.class(nil, "Key_mgr")

function Key_mgr:__init()
	self.key_l = {}
end

function Key_mgr:add_key(char_id, key, acc_id)
	local id,sign = self:parse_id(key)
	if id ~= nil and id == char_id then
		self.key_l[char_id] = {}
		self.key_l[char_id]["key"] = key
		self.key_l[char_id]["acc_id"] = acc_id
		self.key_l[char_id]["sign"] = sign
	end
end

function Key_mgr:del_key(char_id)
	if char_id ~= nil then
		self.key_l[char_id] = nil
	end
end

function Key_mgr:parse_id(key)
	local n = string.find(key, "##")
	if n > 1 then
		local id = string.sub(key, 1, n-1)
		local sign = string.sub(key, n+2,n+2)
		return tonumber(id), tonumber(sign)
	end
end

function Key_mgr:parse_key(key)
	local id,sign = self:parse_id(key)
	--print("--------Key_mgr:parse_key1:", key, id, sign)
	if id ~= nil and self.key_l[id] ~= nil and self.key_l[id]["key"] == key then
		return id,self.key_l[id]["acc_id"],sign
	end
end

--g_key_mgr = Key_mgr()