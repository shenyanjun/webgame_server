
local lom = require("lom")

module("scene_ex.config.war_config_loader", package.seeall)

config = g_all_scene_config

function parse_limit(node)
	local data = {}
	for _, child in pairs(node) do
		if "Level" == child.tag then
			data.level = {tonumber(child.attr["min"]), tonumber(child.attr["max"])}
		elseif "Human" == child.tag then
			data.human = {tonumber(child.attr["min"]), tonumber(child.attr["max"])}
		elseif "Cycle" == child.tag then
			data.cycle = tonumber(child.attr["number"])
		elseif "Time" == child.tag then
			data.time = (tonumber(child.attr["hour"]) or 0) * 3600
				+ (tonumber(child.attr["min"]) or 0) * 60 + (tonumber(child.attr["sec"]) or 0) 
		end
	end
	
	return data
end

function parse_init(node)
	local data = {}
	for _, child in pairs(node) do
		if "Entry" == child.tag then
			data.entry = {tonumber(child.attr["x"]), tonumber(child.attr["y"])}
		elseif "Limit" == child.tag then
			data.limit = parse_limit(child)
		end
	end
	
	return data
end

function parse_sequence(node)
	local data = {}
	data.limit = tonumber(node.attr["limit"])
	for _, child in pairs(node) do
		if "Item" == child.tag then
			local item = {
				["occ"] = tonumber(child.attr["occ"])
				, ["type"] = tonumber(child.attr["type"])
				, ["area"] = tonumber(child.attr["area"])
				, ["number"] = tonumber(child.attr["number"])
			}
			if not data.item_list then
				data.item_list = {}
			end
			table.insert(data.item_list, item)
		end
	end
	
	return data	
end

function parse_update(node)
	local data = {}
	for _, child in pairs(node) do
		if "Sequence" == child.tag then
			local sequence = parse_sequence(child)
			if not data.sequence then
				data.sequence = {}
			end
			table.insert(data.sequence, sequence)
		end
	end
	
	if data.sequence then
		table.sort(
			data.sequence
			, function (r, l)
				return r.limit < l.limit
			end)
	end
	
	return data
end

function parse_action(node)
	local data = {}
	for _, child in pairs(node) do
		if "Update" == child.tag then
			data.update = parse_update(child)
		end
	end
	
	return data
end

function parse_close(node)
	local data = {}
	for _, child in pairs(node) do
		if "Home" == child.tag then
			data.home = {
				['id'] = tonumber(child.attr["id"])
				, ['pos'] = {tonumber(child.attr["x"]), tonumber(child.attr["y"])}
			}
		end
	end
	
	return data
end

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
				if "Init" == child.tag then
					map_config.init = parse_init(child)
				elseif "Action" == child.tag then
					map_config.action = parse_action(child)
				elseif "Close" == child.tag then
					map_config.close = parse_close(child)
				end
			end
			config[id] = map_config
		end
	end
	
	return true
end

parse_config(CONFIG_DIR .. "xml/level/level.xml")