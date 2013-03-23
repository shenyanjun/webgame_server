
local lom = require("lom")

module("scene_ex.config.td_ex_config_loader", package.seeall)

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
				elseif "Born" == child.tag then
					map_config.born = parse_born(child)
				elseif "Declare" == child.tag then
					map_config.declare = parse_declare(child)
				elseif "Monster" == child.tag then
					map_config.monster = parse_monster(child)
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

function parse_guard(node)
	local guard = {}
	local index = 1
	for _, child in pairs(node) do
		if "Npc" == child.tag then
			local id = tonumber(child.attr["id"])
			local npc = {}
			npc.id = id
			npc.index = index
			index = index + 1
			npc.name = child.attr["name"]
			npc.pos = {tonumber(child.attr["x"]), tonumber(child.attr["y"])}
			guard[id] = npc
		end
	end
	return guard
end

function parse_buff(node)
	local buff = {}
	for _, child in pairs(node) do
		if "Impact" == child.tag then
			local skill = {}
			skill.id = tonumber(child.attr["id"])
			skill.name = child.attr["name"]
			skill.desc_id = child.attr["desc_id"]
			skill.time = tonumber(child.attr["time"])
			skill.interval = tonumber(child.attr["interval"])
			buff[skill.id] = skill
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

function parse_need_monster(node)
	local monster = {}
	local type
	for _, child in pairs(node) do
		if "Monster" == child.tag then
			local occ = tonumber(child.attr["occ"])
			local number = tonumber(child.attr["number"])
			type = tonumber(child.attr["Type"])
			monster[occ] = number
		end
	end
	return monster, type
end

function parse_skill(node)
	local skill = {}
	for _, child in pairs(node) do
		if "Skill" == child.tag then
			local id = tonumber(child.attr["id"])
			local monster, occ = parse_need_monster(child)
			table.insert(skill, {["id"] = id, ["monster"] = monster, ["occ"] = occ})
		end
	end
	return skill
end

function parse_descripe(node)
	local des = nil
	local skill = {}
	for _, child in pairs(node) do
		if "Descripe" == child.tag then
			des = child.attr["text"]
		elseif "Buff" == child.tag then
			skill = parse_skill(child)
		end
	end
	return des, skill
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
			freq.text, freq.skill = parse_descripe(child)
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

config = parse_config(CONFIG_DIR .. "xml/td/td_ex.xml")
