
local consum_ret_table = "consum_ret"

Consum_ret_db = oo.class(nil, "Consum_ret_db")

function Consum_ret_db:__init()
end

function Consum_ret_db:load_all()
	local dbh = f_get_db()
	local rows, e_code = dbh:select(consum_ret_table)
	return e_code, rows
end

function Consum_ret_db:update(char_id)
	local db = f_get_db()
	local data = {}
	data.info = g_consum_ret_mgr:serialize_char_to_db(char_id)
	local query = string.format("{char_id:%d}",char_id)
	local e_code = db:update(consum_ret_table, query, Json.Encode(data), true)
	return e_code
end
