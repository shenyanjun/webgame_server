--2010-11-17
--laojc
--db
local database = "buffer"

module("reward.buffer_reward.buffer_reward_db", package.seeall)


function select_all_reward()
	local dbh = f_get_db()

	local rows, e_code = dbh:select(database)
	if 0 == e_code then
		return rows
	end
	return nil


	--local dbh = get_dbh()
	--if dbh == nil then return end
	--if dbh.errcode ~= 0 then
		--print("DB_ERROR, dbh.error = ", dbh.errcode, dbh.errmsg)
	--end
	--
	--local rs = dbh:selectall_ex("select type,start_date,end_date,start_time,end_time,time from buffer_reward")
	--if dbh.errcode ~= 0 then
		--print("DB_ERROR", dbh.errmsg)
	--end
	--return rs
end