
local lom = require("lom")

module("scene_ex.config.tower_config_loader", package.seeall)

config = g_all_scene_config

local function parse_limit(node)
	local limit = {}
	for _, child in pairs(node) do
		if "Human" == child.tag then
			limit.human = {tonumber(child.attr["min"]), tonumber(child.attr["max"])}
		elseif "Level" == child.tag then
			limit.level = {tonumber(child.attr["min"]), tonumber(child.attr["max"])}
		elseif "Cycle" == child.tag then
			limit.cycle = tonumber(child.attr["number"])
		end
	end
	
	return limit
end

local function parse_home(node)
	return {["id"] = tonumber(node.attr["id"]), ["pos"] = {tonumber(node.attr["x"]), tonumber(node.attr["y"])}}
end

local function parse_sequence(node)
	local sequence = {}
	for _, child in pairs(node) do
		if "Item" == child.tag then
			local item = {}
			item.id = tonumber(child.attr["id"])
			item.type = tonumber(child.attr["type"])
			item.number = tonumber(child.attr["number"])
			item.area = tonumber(child.attr["area"])
			item.carry_id = tonumber(child.attr["carry_id"])
			table.insert(sequence, item)
		end
	end
	
	return sequence
end

local function parse_monster(node)
	local monster_list = {}
	for _, child in pairs(node) do
		if "Sequence" == child.tag then
			table.insert(monster_list, parse_sequence(child))
		end
	end
	
	return monster_list
end

local function parse_layer(node)
	local layer = {}
	for _, child in pairs(node) do
		if "Map" == child.tag then
			layer.id = tonumber(child.attr["id"])
			layer.path = CONFIG_DIR .. child.attr["path"]
		elseif "Timeout" == child.tag then
			layer.timeout = tonumber(child.attr["value"])
		elseif "Entry" == child.tag then
			layer.entry = {tonumber(child.attr["x"]), tonumber(child.attr["y"])}
		elseif "Monster" == child.tag then
			layer.monster_list = parse_monster(child)
		elseif "Record" == child.tag then
			layer.record_id = tonumber(child.attr["id"])
		elseif "Except" == child.tag then
			layer.except = {}
			for _, entry in pairs(child) do
				if "Item" == entry.tag then
					layer.except[tonumber(entry.attr["id"])] = 1
				end
			end
		end
	end
	
	return layer
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
		if "Tower" == node.tag then
			local tower_config = {}
			tower_config.layer_list = {}
			tower_config.layer_config = {}
			local id = tonumber(node.attr["id"])
			for _, child in pairs(node) do
				if "Limit" == child.tag then
					tower_config.limit = parse_limit(child)
				elseif "Home" == child.tag then
					tower_config.home = parse_home(child)
				elseif "Layer" == child.tag then
					local layer = parse_layer(child)
					tower_config.layer_config[layer.id] = layer
					table.insert(tower_config.layer_list, layer)
				elseif "WDay" == child.tag then
					local w_id = tonumber(child.attr["id"])
					if not tower_config.day_list then
						tower_config.day_list = {}
					end
					tower_config.day_list[w_id] = parse_day_list(child)
				end
			end
			config[id] = tower_config
		end
	end
	
	return true
end

parse_config(CONFIG_DIR .. "xml/tower/tower.xml")