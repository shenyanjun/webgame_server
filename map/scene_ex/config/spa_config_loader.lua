local lom = require("lom")

module("scene_ex.config.spa_config_loader", package.seeall)

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
			map_config.limit = tonumber(node.attr["limit"]) or 50 
			for _, child in pairs(node) do
				if "Entry" == child.tag then
					map_config.entry = parse_entry(child)
				elseif "Notify" == child.tag then
					map_config.notify = parse_notify(child)
				elseif "WDay" == child.tag then
					local w_id = tonumber(child.attr["id"])
					local day = map_config.day_list
					if not day then
						day = {}
						map_config.day_list = day
					end
					day[w_id] = parse_day_list(child)
				end
			end
			config[id] = map_config
		end
	end
	
	return true
end

function parse_entry(node)
	local entry = {tonumber(node.attr["x"]), tonumber(node.attr["y"])}
	return entry
end

function parse_notify(node)
	local notify = {}
	for _, child in pairs(node) do
		if "Descripe" == child.tag then
			local desc = {}
			desc.text = tostring(child.attr["text"])
			desc.offset = tonumber(child.attr["offset"])
			desc.type = tonumber(node.attr["type"] or 0)
			table.insert(notify, desc)
		end
	end
	return notify
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
	local day = {}
	for _, child in pairs(node) do
		if "OpenTime" == child.tag then
			day.open_time = parse_open_time(child)
		elseif "Exp" == child.tag then
			day.exp = {}
			day.exp.base = tonumber(child.attr["base"])
			day.exp.limit = tonumber(child.attr["limit"])
			day.exp.interval = tonumber(child.attr["interval"])
		end
	end
	return day
end

parse_config(CONFIG_DIR .. "xml/spa/spa.xml")