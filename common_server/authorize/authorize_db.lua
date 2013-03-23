
--2011-05-27
--cqs
--任务委托数据库操作

local database = "authorize"

Authorize_db = oo.class(nil, "Authorize_db")

--初始化  load所有
function Authorize_db:Load()
	local db = f_get_db()

	local rows, e_code = db:select(database)
	if 0 == e_code then
		return rows
	else
		print("Loadauthorize Error: ", e_code)
	end
	return nil
end

function Authorize_db:update_authorize(data)
	local db = f_get_db()
	local authorize_list = {}
	for k, v in pairs(data.list) do
		authorize_list[k] = v
	end
	local values = {}
	values.day_begin = data.day_begin
	values.list = authorize_list
	local query =  "{day_begin: {'$gt': 0}}"
	local e_code = db:update(database, query, Json.Encode(values), true, false)
	if 0 == e_code then
		return rows
	else
		print("Updateauthorize Error: ", e_code)
	end
	return nil
end