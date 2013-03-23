local lom = require("lom")

module("scene_ex.config.invasion_config_loader", package.seeall)

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
		if "Invasion" == node.tag then
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
				elseif "Limit" == child.tag then
					map_config.limit = parse_limit(child)
				elseif "Wild" == child.tag then
					map_config.wild = parse_wild(child)
				elseif "Score" == child.tag then
					map_config.score = parse_score(child)
				end
			end
			config[id] = map_config
		end
	end

	return config
end

function parse_score(node)
	local template = {"rate", "type1", "type2", "type3"}
	local score = parse_obj_attribute(node, template)
	score.type_map = {}
	for _, child in pairs(node) do
		if "Item" == child.tag then
			local template = {"id", "type"}
			local item = parse_obj_attribute(child, template)
			score.type_map[item.id] = item
		end
	end
	return score
end

function parse_entry(node)
	local entry = {}
	for _, child in pairs(node) do
		if "Pos" == child.tag then
			local pos = {tonumber(child.attr["x"]), tonumber(child.attr["y"])}
			table.insert(entry, pos)
		end
	end
	return entry
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

function parse_wild(node)
	local template = {
		["Item"] = {nil, {"id", "number", "interval", "area"}}
	}
	
	local result = {}
	for _, child in pairs(node) do
		if "Sequence" == child.tag then
			local obj = {}
			obj.interval = tonumber(child.attr["interval"])
			obj.sequence = parse_from_template(child, template)
			table.insert(result, obj)
		end
	end
	
	return result
end

config = parse_config(Server_path .. "common/config/xml/invasion/invasion.xml")