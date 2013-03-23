
--2012-01-09
--cqs
--收集活动数据库操作

local database = "collection_activity"
local database_fun = "gm_activity"  --记录活动信息

Collection_activity_db = oo.class(nil, "collection_activity_db")

--
function Collection_activity_db:LoadAll(uuid)
	print("13 =", uuid)
	local db = f_get_db()

	local query = string.format("{uuid:'%s'}", uuid)

	local rows, e_code = db:select(database, nil, query)
	if 0 == e_code then
		return rows
	else
		print("LoadAll Error: ", e_code)
	end
	return nil
end

function Collection_activity_db:clear(uuid)
	print("27 =", uuid)
	local db = f_get_db()

	local query = string.format("{uuid:'%s'}", uuid)
	local e_code = db:delete(database, query)

	if 0 ~= e_code then
		print("update_all Error: ", e_code)
	end
end

function Collection_activity_db:update_collections(uuid, db_data)
	local db = f_get_db()
	local query = string.format("{uuid:'%s'}", uuid)

	local data = Json.Encode(db_data)

	local info = string.format([[{"collection":'%s'}]],  data)

	local e_code = db:update(database, query, info, true)

	if 0 ~= e_code then
		print("update_collections Error: ", e_code)
	end
end


function Collection_activity_db:update_record(uuid, db_data)
	local db = f_get_db()
	local query = string.format("{uuid:'%s'}", uuid)

	local data = Json.Encode(db_data)

	local info = string.format([[{"record":'%s'}]],  data)

	local e_code = db:update(database, query, info, true)

	if 0 ~= e_code then
		print("update_record Error: ", e_code)
	end
end


function Collection_activity_db:update_all(uuid, items, records)
	print("72 =", uuid)
	local db = f_get_db()
	local query = string.format("{uuid:'%s'}", uuid)

	local info = {}
	info.record = records
	info.collection = items

	local e_code = db:update(database, query, Json.Encode(info), true)

	if 0 ~= e_code then
		print("update_all Error: ", e_code)
	end
end


