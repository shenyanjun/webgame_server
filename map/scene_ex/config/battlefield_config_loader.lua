
local lom = require("lom")

module("scene_ex.config.battlefield_config_loader", package.seeall)

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
				elseif "Broadcast" == child.tag then
					map_config.broadcast = parse_honor_list(child)
				elseif "Cheats" == child.tag then
					map_config.cheats = parse_cheats_list(child)
				elseif "Side" == child.tag then
					map_config.side = parse_side_list(child)
				elseif "Limit" == child.tag then
					map_config.limit = parse_limit(child)
					map_config.limit.count = tonumber(node.attr["limit"]) or 40 
				elseif "Wild" == child.tag then
					map_config.wild = parse_wild(child)
				elseif "Reward" == child.tag then
					map_config.reward = {}
					map_config.reward.win = tonumber(child.attr["win"])
					map_config.reward.lose = tonumber(child.attr["lose"])
					map_config.reward.tie = tonumber(child.attr["tie"])
					map_config.reward.max = tonumber(child.attr["max"])
					map_config.reward.commander_add = tonumber(child.attr["commander_add"])
					map_config.reward.list = parse_reward(child)
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
			limit.min_size = tonumber(child.attr["min_size"]) or 10
		elseif "Time" == child.tag then
			limit.cd = tonumber(child.attr["cd"]) or 0
			limit.freeze = tonumber(child.attr["freeze"]) or 0
			limit.wait = tonumber(child.attr["wait"]) or 0 
			limit.hold = tonumber(child.attr["hold"]) or 0
			limit.prepare = tonumber(child.attr["prepare"]) or 0
		elseif "EndPoint" == child.tag then
			limit.end_point = tonumber(child.attr["max"]) or 10000
			limit.max_exploit = tonumber(child.attr["max_exploit"]) or 100000
			limit.reward_line = tonumber(child.attr["reward_line"]) or 100000
			limit.reward_exploit = tonumber(child.attr["reward_exploit"]) or 100
		elseif "Score" == child.tag then
			limit.score = {
				["kill"] = tonumber(child.attr["kill"]) or 1
				, ["kill_commander"] = tonumber(child.attr["kill_commander"]) or 1
				, ["assistant"] = tonumber(child.attr["assistant"]) or 1
			}
		elseif "Exploit" == child.tag then
			limit.exploit = {
				["kill"] = tonumber(child.attr["kill"]) or 1
				, ["kill_commander"] = tonumber(child.attr["kill_commander"]) or 1
				, ["assistant"] = tonumber(child.attr["assistant"]) or 1
			}
		elseif "Enemy" == child.tag then
			limit.enemy = {
				["kill"] = tonumber(child.attr["kill"]) or 60
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
		elseif "Npc" == child.tag then
			info.npc = {tonumber(child.attr["occ"]), {tonumber(child.attr["x"]), tonumber(child.attr["y"])}}
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
	local item_list = {}
	for _, child in pairs(node) do
		if "Item" == child.tag then
			local item = {}
			item.occ = tonumber(child.attr["occ"])
			item.area = tonumber(child.attr["area"])
			item.count = tonumber(child.attr["count"])
			item.total = tonumber(child.attr["total"])
			item.interval = tonumber(child.attr["interval"])
			table.insert(item_list, item)
		end
	end
	return item_list
end

function parse_crytal_item(node)
	return parse_item(node)
end

function parse_diamond_item(node)
	return parse_item(node)
end

function parse_stronghold_item(node)
	local item_list = {}
	for _, child in pairs(node) do
		if "Item" == child.tag then
			local item = {}
			item.id = tonumber(child.attr["id"])
			item.pos = {tonumber(child.attr["x"]), tonumber(child.attr["y"])}
			table.insert(item_list, item)
		end
	end
	return item_list
end

function parse_stronghold_point_item(node)
	local item_list = {}
	item_list.point = {}
	item_list.exploit_base = {}
	for _, child in pairs(node) do
		if "Item" == child.tag then
			table.insert(item_list.point, tonumber(child.attr["point"]))
			table.insert(item_list.exploit_base, tonumber(child.attr["exploit_base"]))
		end
	end
	return item_list
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
	for _, child in pairs(node) do
		if "OpenTime" == child.tag then
			item_list.open_time = parse_open_time(child)
		end
	end
	return item_list
end

function parse_wild(node)
	local wild = {}
	for _, child in pairs(node) do
		if "Crystal" == child.tag then
			wild.crystal = parse_crytal_item(child)
			wild.crystal.exploit = tonumber(child.attr["exploit"])
			wild.crystal.point = tonumber(child.attr["point"])
			wild.crystal.interval = tonumber(child.attr["interval"])
		elseif "Diamond" == child.tag then
			wild.diamond = parse_diamond_item(child)
			wild.diamond.exploit = tonumber(child.attr["exploit"])
			wild.diamond.point = tonumber(child.attr["point"])
			wild.diamond.interval = tonumber(child.attr["interval"])
		elseif "Stronghold" == child.tag then
			wild.stronghold = parse_stronghold_item(child)
			wild.stronghold.occ = tonumber(child.attr["occ"])
			wild.stronghold.occ_1 = tonumber(child.attr["occ_1"])
			wild.stronghold.occ_2 = tonumber(child.attr["occ_2"])
			wild.stronghold.exploit = tonumber(child.attr["exploit"])
			wild.stronghold.point = tonumber(child.attr["point"])
		elseif "StrongholdPoint" == child.tag then
			wild.stronghold_point = parse_stronghold_point_item(child)
			wild.stronghold_point.interval = tonumber(child.attr["interval"])
		elseif "ExploitFactor" == child.tag then
			wild.exploit_factor = parse_exploit_factor(child)
		end
	end
	return wild
end

function parse_reward(node)
	local reward = {}
	for _, child in pairs(node) do
		if "Item" == child.tag then
			table.insert(reward, {tonumber(child.attr["value"]), tonumber(child.attr["factor"])})
		end
	end
	return reward
end

function parse_exploit_factor(node)
	return parse_reward(node)
end

config = parse_config(CONFIG_DIR .. "xml/battlefield/battlefield.xml")
