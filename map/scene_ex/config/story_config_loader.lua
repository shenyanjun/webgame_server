
local lom = require("lom")

module("scene_ex.config.story_config_loader", package.seeall)

config = g_all_scene_config
chapter = {}

function parse_limit(node)
	local data = {}
	for _, child in pairs(node) do
		if "Level" == child.tag then
			data.level = {tonumber(child.attr["min"]), tonumber(child.attr["max"])}
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
	for _, child in pairs(node) do
		if "Item" == child.tag then
			local item = {
				["id"] = tonumber(child.attr["id"])
				, ["type"] = tonumber(child.attr["type"])
				, ["area"] = tonumber(child.attr["area"])
				, ["number"] = tonumber(child.attr["number"]) or 1
				, ["span"] = tonumber(child.attr["span"]) or 0
				, ["count"] = tonumber(child.attr["count"]) or 1
			}
			table.insert(data, item)
		end
	end
	
	return data	
end

function parse_type1(node)
	local data = {type = 1, sequence = {}}
	
	for _, child in pairs(node) do
		if "Sequence" == child.tag then
			local sequence = parse_sequence(child)
			table.insert(data.sequence, sequence)
		end
	end
	
	return data
end

function parse_trigger(node)
	local event = {}
	
	for _, child in pairs(node) do
		if "Entry" == child.tag then
			event.entry = {chapter = child.attr["chapter"]}
		elseif "Dead" == child.tag then
			local list = {}
			for _, item in pairs(child) do
				if "Item" == item.tag then
					local id = tonumber(item.attr["id"])
					list[id] = {
						occ = id
						, chapter = item.attr["chapter"]
						, type = tonumber(item.attr["type"]) or 0}
				end
			end
			event.dead = list
		end
	end
	
	return event
end

function parse_action(node)
	local data = {}
	for _, child in pairs(node) do
		if "Update" == child.tag then
			local type = tonumber(child.attr["type"])
			if 1 == type then
				data.update = parse_type1(child)
			end
		elseif "Trigger" == child.tag then
			data.trigger = parse_trigger(child)
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

parse_config(CONFIG_DIR .. "xml/story/story.xml")
