local database = "magickey"

MagicKey_db = oo.class(nil, "MagicKey_db")


--搜索法宝
function MagicKey_db:Select_magickey(char_id)
	local db = f_get_db()

	local query = string.format("{char_id:%d}",char_id)

	local rows, e_code = db:select_one(database, nil, query)

	if 0 == e_code then
		return rows
	else
		print("Select_magickey Error: ", e_code)
	end
	return nil
end

--保存整个法宝信息
function MagicKey_db:update_all(record)
	local db = f_get_db()

	local data = {} 
	data.char_id = record.char_id
	data.base = record.base
	data.magic_key = record.magic_key

	local query = string.format("{char_id:%d}", record.char_id)

	db:update(database, query, Json.Encode(data), true, false, true)
end


--更新法宝基本元素属性
function MagicKey_db:update_base(char_id, info)
	local m_db = f_get_db()
	local query = string.format("{char_id:%d}", char_id)
	local base = {["base"] = info}
	base = Json.Encode(base)

	m_db:update(database, query, base)
end


--更新第point个法宝，要减1，数据库从0开始
function MagicKey_db:update_magickey(char_id, point, data)
	local m_db = f_get_db()
	local query = string.format("{char_id:%d}", char_id)

	data = Json.Encode(data)

	local info = string.format([[{"magick_key.%d":%s}]], point - 1, data)

	m_db:update(database, query, info)
end

--更新法宝
function MagicKey_db:update_magickey_item(char_id, data)
	local m_db = f_get_db()
	local query = string.format("{char_id:%d}", char_id)
	local info = {["magic_key"] = data}
	info = Json.Encode(info)

	m_db:update(database, query, info)
end
