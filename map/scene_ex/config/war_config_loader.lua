
local lom = require("lom")

module("scene_ex.config.war_config_loader", package.seeall)

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
			local exp = {}
			map_config.limit = tonumber(node.attr["limit"]) or 50 
			for _, child in pairs(node) do
				if "Entry" == child.tag then
					map_config.entry = parse_entry(child)
				elseif "Relive" == child.tag then
					map_config.relive = parse_relive(child)
				elseif "Notify" == child.tag then
					map_config.notify = parse_notify(child)
				elseif "WDay" == child.tag then
					local w_id = tonumber(child.attr["id"])
					if not map_config.day_list then
						map_config.day_list = {}
					end
					map_config.day_list[w_id] = parse_day_list(child)
					map_config.day_list[w_id].exp = exp
				elseif "Exp" == child.tag then
					exp.base = tonumber(child.attr["base"])
					exp.limit = tonumber(child.attr["limit"])
					exp.interval = tonumber(child.attr["interval"])
				elseif "Honor" == child.tag then
					map_config.honor = parse_honor_list(child)
				end
			end
			config[id] = map_config
		end
	end
	
	return true
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

function parse_honor_list(node)
	local honor = {}
	for _, child in pairs(node) do
		if "Descripe" == child.tag then
			local desc = {}
			desc.text = tostring(child.attr["text"])
			desc.number = tonumber(child.attr["number"])
			desc.type = tonumber(node.attr["type"] or 0)
			honor[desc.number] = desc
		end
	end
	return honor
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

function parse_update(node)
	local freq_list = {}
	for _, child in pairs(node) do
		if "Freq" == child.tag then
			local freq = {}
--			freq.hour = tonumber(child.attr["hour"])
--			freq.minu = tonumber(child.attr["minu"])
			freq.offset = tonumber(child.attr["offset"])
			freq.interval = tonumber(child.attr["interval"])
			freq.count = tonumber(child.attr["count"])
			freq.per = tonumber(child.attr["per"])
			table.insert(freq_list, freq)
		end
	end
	return freq_list
end

function parse_area(node)
	local area = {}
	for _, child in pairs(node) do
		if "Range" == child.tag then
			local renge = {}
			renge[1] = tonumber(child.attr["min_x"])
			renge[2] = tonumber(child.attr["max_x"])
			renge[3] = tonumber(child.attr["min_y"])
			renge[4] = tonumber(child.attr["max_y"])
			table.insert(area, renge)
		end
	end
	return area
end

function parse_item_list(node)
	local item_list = {}
	for _, child in pairs(node) do
		if "Object" == child.tag then
			local item = {}
			item.id = tonumber(child.attr["id"])
			item.count = tonumber(child.attr["count"])
			table.insert(item_list, item)
		end
	end
	return item_list
end

function parse_item(node)
	local item = {}
	item.occ = tonumber(node.attr["occ"])
	item.type = tonumber(node.attr["type"])
	for _, child in pairs(node) do
		if "Update" == child.tag then
			item.update = parse_update(child)
		elseif "Area" == child.tag then
			item.area = parse_area(child)
		elseif "Descripe" == child.tag then
			item.desc = tostring(child.attr["text"])
		elseif "ItemList" == child.tag then
			item.item_list = parse_item_list(child)
		end
	end
	return item
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
		if "Item" == child.tag then
			local item = parse_item(child)
			table.insert(item_list.update_list, item)
		elseif "OpenTime" == child.tag then
			item_list.open_time = parse_open_time(child)
		end
	end
	return item_list
end

parse_config(CONFIG_DIR .. "xml/war/war.xml")