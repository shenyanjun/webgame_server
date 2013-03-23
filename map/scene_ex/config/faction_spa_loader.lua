local lom = require("lom")

module("scene_ex.config.faction_spa_loader", package.seeall)

_faction_spa_append = {}

function parse_config(str_file)
	local file_handle = io.open(str_file)
	if not file_handle then
		debug_print("str_file can't open the xml file, file name=", str_file)
		return false
	end
	
	local file_data = file_handle:read("*a")
	file_handle:close()
	
	local xml_tree, err = lom.parse(file_data)
	if err then
		debug_print("str_file error:",err)
		return false
	end
	local id = 1
	for _, child in pairs(xml_tree) do
		if "Item" == child.tag then
			_faction_spa_append[id] = {tonumber(child.attr["per"]), tonumber(child.attr["req_value"]), tonumber(child.attr["faction_money"]), tonumber(child.attr["money"]), tonumber(child.attr["monster_occ"]), child.attr["name"]}
			id = id + 1
		end
	end
	
	return true
end

parse_config(CONFIG_DIR .. "xml/spa/faction_spa.xml")
--print("faction_spa:", j_e(_faction_spa_append))