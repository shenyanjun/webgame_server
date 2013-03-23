
local lom = require("lom")

module("scene_ex.config.frenzy_config_loader", package.seeall)

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
			local exp = {}
			for _, child in pairs(node) do
				if "Entry" == child.tag then
					map_config.entry = parse_entry(child)
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
				elseif "Home" == child.tag then
					map_config.home = {
						["id"] = tonumber(child.attr["id"])
						, ["pos"] = {tonumber(child.attr["x"]), tonumber(child.attr["y"])}
					}
				elseif "Honor" == child.tag then
					map_config.honor = parse_honor_list(child)
				elseif "Terminator" == child.tag then
					map_config.terminator = parse_honor_list(child)
				elseif "Cheats" == child.tag then
					map_config.cheats = parse_cheats_list(child)
				elseif "Side" == child.tag then
					map_config.side = parse_side_list(child)
				elseif "Limit" == child.tag then
					map_config.limit = parse_limit(child)
					map_config.limit.count = tonumber(node.attr["limit"]) or 50 
				end
			end
			config[id] = map_config
		end
	end

	return config
end

function parse_limit(node)
	local limit = {}
	for _, child in pairs(node) do
		if "Copy" == child.tag then
			limit.copy = tonumber(child.attr["value"]) or 1
		elseif "Time" == child.tag then
			limit.cd = tonumber(child.attr["cd"]) or 0
			limit.freeze = tonumber(child.attr["freeze"]) or 0
			limit.wait = tonumber(child.attr["wait"]) or 0
		elseif "Reward" == child.tag then
			limit.reward = {
				["min"] = tonumber(child.attr["min"]) or 0
				, ["max"] = tonumber(child.attr["max"]) or 0
				, ["heart"] = tonumber(child.attr["heart"]) or 0
			}
		elseif "Human" == child.tag then
			limit.human = tonumber(child.attr["max"]) or 50
		elseif "Score" == child.tag then
			limit.score = {
				["win"] = tonumber(child.attr["win"]) or 1
				, ["honor"] = tonumber(child.attr["honor"]) or 1
			}
		elseif "Enemy" == child.tag then
			limit.enemy = {
				["kill"] = tonumber(child.attr["kill"]) or 60
				, ["win"] = tonumber(child.attr["win"]) or 1
				, ["honor"] = tonumber(child.attr["honor"]) or 60
			}
		end
	end
	return limit	
end

function parse_guard_list(node)
	local guard = {}
	for _, child in pairs(node) do
		if "Pos" == child.tag then
			table.insert(
				guard
				, {
					tonumber(child.attr["occ"])
					, {tonumber(child.attr["x"]), tonumber(child.attr["y"])}
				})
		end
	end
	return guard
end

function parse_side_info(node)
	local info = {}
	for _, child in pairs(node) do
		if "Heart" == child.tag then
			info.heart = {tonumber(child.attr["occ"]), {tonumber(child.attr["x"]), tonumber(child.attr["y"])}}
		elseif "Guard" == child.tag then
			info.guard = parse_guard_list(child)
		end
	end
	return info
end

function parse_side_list(node)
	local side = {}
	for _, child in pairs(node) do
		if "Blue" == child.tag then
			side[1] = parse_side_info(child)
		elseif "Red" == child.tag then
			side[2] = parse_side_info(child)
		end
	end
	return side
end

function parse_buff(node)
	local buff = {}
	buff.level = tonumber(node.attr["level"])
	buff.diff = tonumber(node.attr["diff"])
	return buff
end

function parse_cheats_list(node)
	local buff_list = {}
	for _, child in pairs(node) do
		if "Buff" == child.tag then
			local buff = parse_buff(child)
			table.insert(buff_list, buff)
		end
	end
	
	table.sort(
		buff_list
		, function (left, right)
			return left.diff < right.diff
		end)
	
	local i = 1
	while true do
		local cur = buff_list[i]
		if not cur then
			break
		end
		i = i + 1
		local next = buff_list[i]
		cur.next = next and next.diff
	end

	return {['buff'] = buff_list}
end

function parse_pos(node)
	local list = {}
	for _, child in pairs(node) do
		if "Pos" == child.tag then
			local pos = {tonumber(child.attr["x"]), tonumber(child.attr["y"])}
			table.insert(list, pos)
		end
	end
	return list
end

function parse_entry(node)
	local entry = {}
	for _, child in pairs(node) do
		if "Blue" == child.tag then
			entry[1] = parse_pos(child)
		elseif "Red" == child.tag then
			entry[2] = parse_pos(child)
		end
	end
	return entry
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

function parse_update(node)
	local freq_list = {}
	for _, child in pairs(node) do
		if "Freq" == child.tag then
			local freq = {}
			freq.offset = tonumber(child.attr["offset"])
			freq.interval = tonumber(child.attr["interval"])
			freq.count = tonumber(child.attr["count"])
			freq.per = tonumber(child.attr["per"])
			table.insert(freq_list, freq)
		end
	end
	return freq_list
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
	item.area = tonumber(node.attr["area"])
	for _, child in pairs(node) do
		if "Update" == child.tag then
			item.update = parse_update(child)
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

config = parse_config(CONFIG_DIR .. "xml/frenzy/frenzy.xml")