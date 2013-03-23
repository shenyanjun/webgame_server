-- 帮派庭院

local faction_courtyard_table = "faction_courtyard"

Faction_courtyard_db = oo.class(nil, "Faction_courtyard_db")

function Faction_courtyard_db:__init()
end

function Faction_courtyard_db:load_all()
	local dbh = f_get_db()
	local rows, e_code = dbh:select(faction_courtyard_table)
	return e_code, rows
end

function Faction_courtyard_db:update_one(faction_id)
	local db = f_get_db()
	local data = {}

	local faction_courtyard = g_faction_courtyard_mgr:get_faction_courtyard(faction_id)
	if faction_courtyard then
		data = faction_courtyard:serialize_to_db() or {}
	end

	local query = string.format("{faction_id:'%s'}", faction_id)
	local e_code = db:update(faction_courtyard_table, query, Json.Encode(data), true)
	return e_code
end

function Faction_courtyard_db:del_one(faction_id)
	local db = f_get_db()
	local data = {}
	data.money_tree_obj = {}
	data.censer_obj = {}
	local query = string.format("{faction_id:'%s'}", faction_id)
	local e_code = db:update(faction_courtyard_table, query, Json.Encode(data), true)
	return e_code
end