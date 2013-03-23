local lom = require("lom")

module("scene_ex.config.desert_config_loader", package.seeall)

config = g_all_scene_config

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
	
	for _, node in pairs(xml_tree) do
		if "Map" == node.tag then
			local id = tonumber(node.attr["id"])
			local map_config = {}
			for _, child in pairs(node) do
				if "Entry" == child.tag then
					map_config.entry = parse_entry(child)
				elseif "Relive" == child.tag then
					map_config.relive = parse_relive(child)
				elseif "WDay" == child.tag then
					local w_id = tonumber(child.attr["id"])
					if not map_config.day_list then
						map_config.day_list = {}
					end
					map_config.day_list[w_id] = parse_day_list(child)
				end
			end
			config[id] = map_config
		end
	end
	
	return true
end

function parse_world_level(node)
	local list = {}
	for _, child in pairs(node) do
		if "WorldLevel" == child.tag then
			table.insert(list, {tonumber(child.attr["level"]), parse_object(child)})
		end
	end
	return list
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

function parse_relive(node)
	local relive = {}
	for _, child in pairs(node) do
		if "Pos" == child.tag then
			local pos = {tonumber(child.attr["x"]), tonumber(child.attr["y"])}
			table.insert(relive, pos)
		end
	end
	return relive
end

function parse_object(node)
	local object_list = {}
	for _, child in pairs(node) do
		if "Object" == child.tag then
			local object = {}
			object.occ = tonumber(child.attr["occ"])
			object.area = tonumber(child.attr["area"])
			object.per = tonumber(child.attr["per"])
			object.live = tonumber(child.attr["live"])
			table.insert(object_list, object)
		end
	end
	return object_list
end

function parse_day_list(node)
	local update_list = {}
	for _, child in pairs(node) do
		if "Timespan" == child.tag then
			local info = {}
			info.hour = tonumber(child.attr["hour"])
			info.minu = tonumber(child.attr["minu"])
			info.interval = tonumber(child.attr["interval"])
			info.count = tonumber(child.attr["count"])
			--info.object_list = parse_object(child)
			info.world_level = parse_world_level(child)
			table.insert(update_list, info)
		end
	end
	return update_list
end

parse_config(CONFIG_DIR .. "xml/desert/desert.xml")
