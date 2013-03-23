-- 帮派神兽
-- CodeBy:cailizhong
-- 2012/8/10

--local debug_print = print
local debug_print = function() end

local faction_dogz_table = "faction_dogz"

Faction_dogz_db = oo.class(nil, "Faction_dogz_db")

function Faction_dogz_db:__init()
end

-- 从数据库加载所有帮派神兽信息
function Faction_dogz_db:load_all()
	local dbh = f_get_db()
	local rows, e_code = dbh:select(faction_dogz_table)
	return e_code, rows
end

-- 更新神兽容器信息
function Faction_dogz_db:update(faction_id)
	local db = f_get_db()
	local data = {}
	data.dogz_info = {}
	local dogz_con = g_faction_dogz_mgr:get_dogz_con(faction_id)
	if dogz_con then
		data = dogz_con:serialize_to_db()
	end
	debug_print("in update")
	debug_print(j_e(data))
	debug_print("faction_id", faction_id)
	local query = string.format("{faction_id:'%s'}",faction_id)
	local e_code = db:update(faction_dogz_table, query, Json.Encode(data), true)
	return e_code
end

function Faction_dogz_db:del(faction_id)
	local db = f_get_db()
	local data = {}
	data.dogz_info = {}
	local query = string.format("{faction_id:'%s'}",faction_id)
	local e_code = db:update(faction_dogz_table, query, Json.Encode(data), true)
	return e_code
end





