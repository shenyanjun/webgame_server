
local lom = require("lom")

module("scene_ex.config.td_config_loader", package.seeall)

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
		if "TD" == node.tag then
			local id = tonumber(node.attr["id"])
			local map_config = {}
			for _, child in pairs(node) do
				if "Entry" == child.tag then
					map_config.entry = {tonumber(child.attr["x"]), tonumber(child.attr["y"])}
				elseif "Home" == child.tag then
					map_config.home = {
						["id"] = tonumber(child.attr["id"])
						, ["pos"] = {tonumber(child.attr["x"]), tonumber(child.attr["y"])}
					}
				elseif "Heart" == child.tag then
					map_config.heart = {
						["id"] = tonumber(child.attr["id"])
						, ["pos"] = {tonumber(child.attr["x"]), tonumber(child.attr["y"])}
					}
				elseif "Helper" == child.tag then
					map_config.helper = parse_helper(child)
				elseif "Mana" == child.tag then
					map_config.mana_list = parse_mana(child)
				elseif "Wild" == child.tag then
					map_config.wild = parse_wild(child)
				elseif "Born" == child.tag then
					map_config.born = parse_born(child)
				elseif "Declare" == child.tag then
					map_config.declare = parse_declare(child)
				elseif "Monster" == child.tag then
					map_config.monster = parse_monster(child)
				elseif "Test" == child.tag then
					map_config.test = parse_test(child)
				elseif "WDay" == child.tag then
					local w_id = tonumber(child.attr["id"])
					if not map_config.day_list then
						map_config.day_list = {}
					end
					map_config.day_list[w_id] = parse_day_list(child)
				end
			end
			
			for _, path in pairs(map_config.born) do
				table.insert(path.path, map_config.heart.pos)
			end
			
			for k, v in pairs(map_config.declare) do
				local sequence = map_config.monster[k]
				v.sequence = sequence
			end
			
			config[id] = map_config
		end
	end
	
	return config
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

function parse_test(node)
	return {['mana'] = tonumber(node.attr["mana"])}
end

function parse_guard_level(node)
	local list = {}
	for _, child in pairs(node) do
		if "Item" == child.tag then
			local info = {}
			info.desc_id = tonumber(child.attr["desc_id"])
			info.mana = tonumber(child.attr["mana"])
			info.item_id = tonumber(child.attr["item"])
			table.insert(list, info)
		end
	end
	return list
end

function parse_guard(node)
	local guard = {}
	for _, child in pairs(node) do
		if "Npc" == child.tag then
			local id = tonumber(child.attr["id"])
			local npc = {}
			npc.id = id
			npc.name = child.attr["name"]
			npc.pos = {tonumber(child.attr["x"]), tonumber(child.attr["y"])}
			npc.level_list = parse_guard_level(child)
			guard[id] = npc
		end
	end
	return guard
end

function parse_buff(node)
	local buff = {}
	for _, child in pairs(node) do
		if "Impact" == child.tag then
			local id = tonumber(child.attr["id"])
			local impact = {}
			impact.id = id
			impact.name = child.attr["name"]
			impact.desc_id = tonumber(child.attr["desc_id"])
			impact.mana = tonumber(child.attr["mana"])
			buff[id] = impact
		end
	end
	return buff
end

function parse_helper(node)
	local helper = {}
	for _, child in pairs(node) do
		if "Guard" == child.tag then
			helper.guard = parse_guard(child)
		elseif "Buff" == child.tag then
			helper.buff = parse_buff(child)
		end
	end
	return helper
end

function parse_mana(node)
	local mana_list = {}
	for _, child in pairs(node) do
		if "Item" == child.tag then
			mana_list[tonumber(child.attr["id"])] = tonumber(child.attr["mana"] or 0)
		end
	end
	return mana_list
end

function parse_area(node)
	local area = {}
	for _, child in pairs(node) do
		if "Item" == child.tag then
			local item = {}
			item.id = tonumber(child.attr["id"])
			item.number = tonumber(child.attr["number"])
			item.interval = tonumber(child.attr["interval"] or 0)
			table.insert(area, item)
		end
	end
	return area
end

function parse_wild(node)
	local wild = {}
	for _, child in pairs(node) do
		if "Area" == child.tag then
			local id = tonumber(child.attr["id"])
			wild[id] = parse_area(child)
		end
	end
	return wild
end

function parse_path(node)
	local path = {}
	for _, child in pairs(node) do
		if "Pos" == child.tag then
			table.insert(
				path
				, {tonumber(child.attr["x"]), tonumber(child.attr["y"])})
		end
	end
	return path
end

function parse_born(node)
	local born = {}
	for _, child in pairs(node) do
		if "Path" == child.tag then
			local id = tonumber(child.attr["id"])
			born[id] = {
				["pos"] = {tonumber(child.attr["x"]), tonumber(child.attr["y"])}
				, ["path"] = parse_path(child)
			}
		end
	end
	return born
end

function parse_descripe(node)
	for _, child in pairs(node) do
		if "Descripe" == child.tag then
			return child.attr["text"]
		end
	end
end

function parse_declare(node)
	local declare = {}
	for _, child in pairs(node) do
		if "Freq" == child.tag then
			local id = tonumber(child.attr["id"])
			local freq = {}
			freq.id = id
			freq.interval = tonumber(child.attr["interval"])
			freq.name = child.attr["name"]
			freq.text = parse_descripe(child)
			declare[id] = freq
		end
	end
	return declare
end

function parse_item(node, path, list)
	for _, child in pairs(node) do
		if "Item" == child.tag then
			local item = {}
			item.id = tonumber(child.attr["id"])
			item.span = tonumber(child.attr["span"])
			item.number = tonumber(child.attr["number"])
			item.count = tonumber(child.attr["count"])
			item.path = path
			table.insert(list, item)
		end
	end
end

function parse_freq(node, path, sequence)
	for _, child in pairs(node) do
		if "Freq" == child.tag then
			local id = tonumber(child.attr["id"])
			local list = sequence[id]
			if not list then
				list = {}
				sequence[id] = list
			end
			parse_item(child, path, list)
		end
	end
end

function parse_monster(node)
	local sequence = {}
	for _, child in pairs(node) do
		if "Sequence" == child.tag then
			local path = tonumber(child.attr["path"])
			parse_freq(child, path, sequence)
		end
	end
	return sequence
end

config = parse_config(CONFIG_DIR .. "xml/td/td.xml")