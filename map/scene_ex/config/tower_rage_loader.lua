
local lom = require("lom")
--怒气副本
module("scene_ex.config.tower_rage_loader", package.seeall)

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

local function parse_comment(node)
	local t = {}
	for _, child in pairs(node) do
		if "Item" == child.tag then
			table.insert(t, child.attr["text"])
		end
	end
	return t
end

local function parse_comments(node)
	local t = {}
	for _, child in pairs(node) do
		if "Comment" == child.tag then
			table.insert(t, parse_comment(child))
		end
	end
	return t
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

local function parse_reward(node)
	local t = {}
	local weight = 0
	t.list = {}
	t.weight = {}
	for _, child in pairs(node) do
		if "Item" == child.tag then
			weight = weight + tonumber(child.attr["weight"])
			table.insert(t.list, tonumber(child.attr["id"]))
			table.insert(t.weight, weight)
		end
	end
	t.weight_t = weight
	return t
end

local function parse_rewards(node)
	local t = {}
	for _, child in pairs(node) do
		if "Reward" == child.tag then
			table.insert(t, parse_reward(child))
		end
	end
	return t
end

local function parse_monster_ex1_item(node)
	local t = {}
	t.area = tonumber(node.attr["area"])
	t.next_time = tonumber(node.attr["next_time"])
	t.list = {}
	for _, child in pairs(node) do
		if "Item" == child.tag then
			table.insert(t.list, {tonumber(child.attr["id"]), tonumber(child.attr["number"]) or 1} )
		end
	end
	return t
end

local function parse_monster_pos(node)
	local t = {}
	for _, child in pairs(node) do
		if "Item" == child.tag then
			table.insert(t, {tonumber(child.attr["x"]), tonumber(child.attr["y"])} )
		end
	end
	return t
end

local function parse_monster_pos3(node)
	local t = {}
	for _, child in pairs(node) do
		if "Item" == child.tag then
			table.insert(t, {{tonumber(child.attr["x"]), tonumber(child.attr["y"])},{tonumber(child.attr["x1"]), tonumber(child.attr["y1"])}, {tonumber(child.attr["x2"]), tonumber(child.attr["y2"])} })
		end
	end
	return t
end

local function parse_monster_ex1(node)
	local monster_ex = {}
	for _, child in pairs(node) do
		if "NextLayer" == child.tag then
			monster_ex.next_layer = {tonumber(child.attr["id"]), tonumber(child.attr["area"]), tonumber(child.attr["carry_id"])}
		elseif "Boss" == child.tag then
			monster_ex.boss = parse_monster_ex1_item(child)
		elseif "Monster" == child.tag then
			monster_ex.monster = parse_monster_ex1_item(child)
		elseif "Summon" == child.tag then
			monster_ex.summon = parse_monster_ex1_item(child)
		elseif "MonsterPos" == child.tag then
			monster_ex.monster_pos = parse_monster_pos(child)
		end
	end
	return monster_ex
end

local function parse_monster_ex2(node)
	return parse_monster_ex1(node)
end

local function parse_monster_ex3(node)
	return parse_monster_ex1(node)
end

local function parse_monster_ex4(node)
	return parse_monster_ex1(node)
end

local function parse_monster_ex5(node)
	return parse_monster_ex1(node)
end

local function parse_monster_ex6(node)
	return parse_monster_ex1(node)
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
		elseif "Monster_ex1" == child.tag then
			layer.monster_ex1 = parse_monster_ex1(child)
		elseif "Monster_ex2" == child.tag then
			layer.monster_ex2 = parse_monster_ex2(child)
		elseif "Monster_ex3" == child.tag then
			layer.monster_ex3 = parse_monster_ex3(child)
		elseif "Monster_ex4" == child.tag then
			layer.monster_ex4 = parse_monster_ex4(child)
		elseif "Monster_ex5" == child.tag then
			layer.monster_ex5 = parse_monster_ex5(child)
		elseif "Monster_ex6" == child.tag then
			layer.monster_ex6 = parse_monster_ex6(child)
		elseif "Monster_ex7" == child.tag then
			layer.monster_ex7 = parse_monster_ex7(child)
		elseif "Monster_ex8" == child.tag then
			layer.monster_ex8 = parse_monster_ex8(child)
		elseif "Monster_ex9" == child.tag then
			layer.monster_ex9 = parse_monster_ex9(child)
		elseif "Record" == child.tag then
			layer.record_id = tonumber(child.attr["id"])
		elseif "Except" == child.tag then
			layer.except = {}
			for _, entry in pairs(child) do
				if "Item" == entry.tag then
					layer.except[tonumber(entry.attr["id"])] = 1
				end
			end
		elseif "Comments" == child.tag then
			layer.comments = parse_comments(child)
			layer.layer_comment = child.attr["text"]
		elseif "Rewards" == child.tag then
			layer.rewards = parse_rewards(child)
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
		debug_print("str_file error:", str_file, err)
		return false
	end
	
	for _, node in pairs(xml_tree) do
		if "Rage" == node.tag then
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

parse_config(CONFIG_DIR .. "xml/tower/tower_rage.xml")