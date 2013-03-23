
local lom = require("lom")

module("scene_ex.config.pvp_battle_loader", package.seeall)

local open_time_list = {}

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
	
	local config = {}
	for _, node in pairs(xml_tree) do
		if "Map" == node.tag then
			local id = tonumber(node.attr["id"])
			local limit = tonumber(node.attr["limit"])
			local map_config = {}
			local exp = {}
			for _, child in pairs(node) do
				if "Entry" == child.tag then
					map_config.entry = parse_pos(child)
				elseif "WDay" == child.tag then
					local w_id = tonumber(child.attr["id"])
					if not map_config.day_list then
						map_config.day_list = {}
					end
					map_config.day_list[w_id] = parse_day_list(child, w_id)
				elseif "Home" == child.tag then
					map_config.home = {
						["id"] = tonumber(child.attr["id"])
						, ["pos"] = {tonumber(child.attr["x"]), tonumber(child.attr["y"])}
					}
				elseif "Limit" == child.tag then
					map_config.limit = parse_limit(child)
					map_config.limit.count = tonumber(node.attr["limit"]) or 50 
				elseif "Wild" == child.tag then
					map_config.wild = parse_wild(child)
				end
			end
			config = map_config
		end
	end

	return config
end

function parse_limit(node)
	local limit = {}
	for _, child in pairs(node) do
		if "level" == child.tag then
			limit.level = {}
			limit.level.max = tonumber(child.attr["max"]) or 100
			limit.level.min = tonumber(child.attr["min"]) or 60
		elseif "Time" == child.tag then
			limit.god = tonumber(child.attr["god"]) or 10
			limit.clear = tonumber(child.attr["clear"]) or 120
		elseif "Relive" == child.tag then
			limit.rel_time = tonumber(child.attr["time"]) or 20
			limit.rel_pos = parse_pos(child)
			limit.rel_pos_count = #limit.rel_pos
		end
	end
	return limit	
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



function parse_open_time(node)
	local open_time = {}
	local time_info = {}
	for _, child in pairs(node) do
		if "TimeSpan" == child.tag then
			local time_span = {}
			time_span.hour = tonumber(child.attr["hour"])
			time_span.minu = tonumber(child.attr["minu"])
			time_span.interval = tonumber(child.attr["interval"])
			local info = {}
			info.open_time = time_span.hour * 3600 + time_span.minu * 60
			info.end_time = info.open_time + time_span.interval * 60
			table.insert(time_info, info)
			table.insert(open_time, time_span)
		end
	end
	return open_time, time_info
end

function parse_day_list(node, week)
	local item_list = {}
	open_time_list[week] = {}
	for _, child in pairs(node) do
		if "OpenTime" == child.tag then
			local open_info, time_info = parse_open_time(child)
			item_list.open_time = open_info
			open_time_list[week] = time_info
		end
	end
	return item_list
end

function parse_wild(node)
	local wild = {}
	for _, child in pairs(node) do
		if "World" == child.tag then
			local level = tonumber(child.attr["level"])
			wild[level] = parse_world(child)
		end
	end
	return wild
end

function parse_world(node)
	local world = {}
	for _, child in pairs(node) do
		if "Monster" == child.tag then
			world.monster = parse_monster(child)
			world.monster_interval = tonumber(child.attr["interval"])
		elseif "Collect" == child.tag then
			world.collect = parse_collect(child)
			world.collect_interval = tonumber(child.attr["interval"])
		elseif "Boss" == child.tag then
			world.boss = parse_boss(child)
			world.boss_count = #world.boss
		end
	end
	return world
end

function parse_monster(node)
	local monster_l = {}
	for _, child in pairs(node) do
		if "Monster" == child.tag then
			local monster = {}
			monster.id = tonumber(child.attr["id"])
			monster.number = tonumber(child.attr["number"])
			monster.area = tonumber(child.attr["area"])
			table.insert(monster_l, monster)
		end
	end
	return monster_l
end

function parse_collect(node)
	local collect_l = {}
	for _, child in pairs(node) do
		if "Item" == child.tag then
			local collect = {}
			collect.id = tonumber(child.attr["id"])
			collect.number = tonumber(child.attr["number"])
			collect.area = tonumber(child.attr["area"])
			table.insert(collect_l, collect)
		end
	end
	return collect_l
end

function parse_boss(node)
	local boss_l = {}
	for _, child in pairs(node) do
		if "Boss" == child.tag then
			local boss = {}
			boss.id = tonumber(child.attr["id"])
			boss.time = tonumber(child.attr["time"])
			boss.number = tonumber(child.attr["number"])
			boss.area = tonumber(child.attr["area"])
			table.insert(boss_l, boss)
		end
	end
	return boss_l
end

function check_open_time(week)
	local now = ev.time - f_get_today()
	local list = open_time_list[week]
	for _, info in pairs(list or {}) do
		if info.open_time <= now and now < info.end_time then
			return 0
		end
	end
	return SCENE_ERROR.E_NOT_OPNE
end

config = parse_config(CONFIG_DIR .. "xml/pvp/pvp_battle.xml")

--print("============>", j_e(config))