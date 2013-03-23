local database = "activity_player_info"
local database_fun = "gm_activity"  --记录活动信息

Activity_reward_db = oo.class(nil, "Activity_reward_db")

local record_time = ev.time

--
function Activity_reward_db:select_activity_reward(char_id, id)
	if not char_id then
		return
	end

	local db = f_get_db()
	local query = string.format("{char_id:%d,id:%d}",char_id, id)

	local rows, e_code = db:select(database,nil,query)
	if 0 == e_code then
		return rows
	else
		print("Select_regression Error: ", e_code)
		return nil
	end
end

function Activity_reward_db:update(record)
	if not record then
		return
	end
	local db = f_get_db()
	local query = string.format("{char_id:%d,id:%d}",record.char_id, record.id)

	local e_code = db:update(database, query, Json.Encode(record), true, false,true)

	if 0 ~= e_code then
		print("Rctivity_reward_db:update Error: ", e_code)
	end
end
