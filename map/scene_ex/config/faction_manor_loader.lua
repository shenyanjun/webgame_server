local lom = require("lom")

module("scene_ex.config.faction_manor_loader", package.seeall)

function parse_obj_attribute(node, template)
	local obj = {}
	for _, key in ipairs(template) do
		obj[key] = tonumber(node.attr[key]) or node.attr[key]
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
		if "Manor" == node.tag then
			local id = tonumber(node.attr["id"])
			local map_config = {}
			for _, child in pairs(node) do
				if "Entry" == child.tag then
					map_config.entry = parse_entry(child)
				elseif "EntryOth" == child.tag then
					map_config.entry_oth = parse_entry(child)
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
				elseif "WDay" == child.tag then
					local w_id = tonumber(child.attr["id"])
					if not map_config.day_list then
						map_config.day_list = {}
					end
					map_config.day_list[w_id] = parse_day_list(child)
				elseif "Rob" == child.tag then
					map_config.rob = parse_rob(child)
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

function parse_rob(node)
	rob = {}
	for _, child in pairs(node) do
		if "Item" == child.tag then
			local template = {"id", "name", "area", "action_id", "type1", "type2", "type3"}
			local item = parse_obj_attribute(child, template)
			table.insert(rob, item)
		end
	end

	return rob
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
		["Item"] = {nil, {"id", "number", "interval", "area", "r_type"}}
	}
	
	local result = {}
	for _, child in pairs(node) do
		if "Sequence" == child.tag then
			local obj = {}
			obj.interval = tonumber(child.attr["interval"])
			obj.sequence = parse_from_template(child, template)
			table.insert(result, obj)
		elseif "Boss" == child.tag then
			result.boss = {["id"] = tonumber(child.attr["id"]), ["area"] = tonumber(child.attr["area"]),
			[1] = tonumber(child.attr["type_1"]), [2] = tonumber(child.attr["type_2"]), [3] = tonumber(child.attr["type_3"])}
		end
	end
	
	return result
end

function parse_open_time(node)
	local open_time = {}
	for _, child in pairs(node) do
		if "TimeSpan" == child.tag then
			local time_span = {}
			time_span.hour = tonumber(child.attr["hour"])
			time_span.minu = tonumber(child.attr["minu"])
			time_span.interval = tonumber(child.attr["interval"])
			table.insert(open_time, time_span)
		end
	end
	return open_time
end

function parse_day_list(node)
	local item_list = {}
	item_list.update_list = {}
	for _, child in pairs(node) do
		if "OpenTime" == child.tag then
			item_list.open_time = parse_open_time(child)
		end
	end
	return item_list
end

config = parse_config(Server_path .. "common/config/xml/faction_manor/faction_manor.xml")
--print("2901000:", j_e(config[2901000].entry))
