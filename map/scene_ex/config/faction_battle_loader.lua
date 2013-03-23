local lom = require("lom")

module("scene_ex.config.faction_battle_loader", package.seeall)

function parse_obj_attribute(node, template)
	local obj = {}
	for _, key in ipairs(template) do
		obj[key] = tonumber(node.attr[key])
	end
	return obj
end

function parse_from_template(node, template)
	local result = {}
	for _, child in pairs(node) do
		local info = template[child.tag]
		if info then
			local obj = {}
			for _, key in ipairs(info[2] or {}) do
				obj[key] = tonumber(child.attr[key])
			end
			local name = info[1]
			if name then
				result[name] = obj
			else
				table.insert(result, obj)
			end
		end
	end
	return result
end

function load_file(path)
	local file_handle = io.open(path)
	if not file_handle then
		debug_print("str_file can't open the xml file, file name=", path)
		return nil
	end
	
	local file_data = file_handle:read("*a")
	file_handle:close()
	
	local xml_tree, err = lom.parse(file_data)
	if err then
		debug_print("str_file error:",err)
		return nil
	end
	
	return xml_tree
end

function parse_config(path)
	local xml_tree = load_file(path)
	if not xml_tree then
		return {}
	end
	
	local config = g_all_scene_config
	for _, node in pairs(xml_tree) do
		if "Map" == node.tag then
			local id = tonumber(node.attr["id"])
			local map_config = {}
			for _, child in pairs(node) do
				if "Entry" == child.tag then
					map_config.entry = parse_entry(child)
				elseif "Home" == child.tag then
					map_config.home = {
						["id"] = tonumber(child.attr["id"])
						, ["pos"] = {tonumber(child.attr["x"]), tonumber(child.attr["y"])}
					}
				elseif "Relive" == child.tag then
					map_config.relive = parse_relive(child)
					map_config.relive.time = tonumber(child.attr["time"])
				elseif "Limit" == child.tag then
					map_config.limit = parse_limit(child)
				end
			end
			config[id] = map_config
		end
	end

	return config
end


function parse_entry(node)
	local entry = {}
	entry[1] = {}
	entry[2] = {}
	for _, child in pairs(node) do
		if "Side_1" == child.tag then
			local pos = {tonumber(child.attr["x"]), tonumber(child.attr["y"])}
			table.insert(entry[1], pos)
		elseif "Side_2" == child.tag then
			local pos = {tonumber(child.attr["x"]), tonumber(child.attr["y"])}
			table.insert(entry[2], pos)
		end
	end
	return entry
end

function parse_relive(node)
	local relive = {}
	relive[1] = {}
	relive[2] = {}
	for _, child in pairs(node) do
		if "Side_1" == child.tag then
			local pos = {tonumber(child.attr["x"]), tonumber(child.attr["y"])}
			table.insert(relive[1], pos)
		elseif "Side_2" == child.tag then
			local pos = {tonumber(child.attr["x"]), tonumber(child.attr["y"])}
			table.insert(relive[2], pos)
		end
	end
	return relive
end

function parse_limit(node)
	local template = {
		["Level"] = {"level", {"min", "max"}}
		, ["Human"] = {"human", {"min", "max"}}
		, ["Cycle"] = {"cycle", {"number"}}
		, ["Timeout"] = {"timeout", {"number"}}
		, ["FactionLevel"] = {"faction_level", {"min", "max"}}
	}
	return parse_from_template(node, template)
end





config = parse_config(Server_path .. "common/config/xml/faction_battle/faction_battle.xml")
--print("--->config:", j_e(config[2801000]))