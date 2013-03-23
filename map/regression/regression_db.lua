local database = "regression"
local time_db = "regression_time"

Regression_db = oo.class(nil, "Regression_db")

local record_time = ev.time

--增加回归信息
function Regression_db:select_regression(char_id)
	if not char_id then
		return
	end

	local db = f_get_db()
	local query = string.format("{char_id:%d}",char_id)

	local rows, e_code = db:select(database,nil,query)
	if 0 == e_code then
		return rows
	else
		print("Select_regression Error: ", e_code)
		return nil
	end
end


function Regression_db:update_regression(record)
	if not record then
		return
	end
	local db = f_get_db()
	local query = string.format("{char_id:%d}",record.char_id)

	local e_code = db:update(database, query, Json.Encode(record), true, false)

	if 0 ~= e_code then
		print("Error: ", e_code)
	end
end

function Regression_db:get_record_time()
	return record_time
end

function f_check_regression_time()

	local db = f_get_db()

	local rows, e_code = db:select(time_db)

	if 0 ~= e_code then
		print("Error: ", e_code)
	else
		local flags = false
		if rows then
			for k, v in pairs(rows) do
				if v.time then
					record_time = v.time
					flags = true
				end
			end
		end
		if not flags then
			local t = {}
			t.time = ev.time
			record_time = ev.time
			local e_code = db:insert(time_db, Json.Encode(t))
		end
	end
end