local lom = require("lom")

module("scene_ex.config.wild_boss_config_loader", package.seeall)

config = g_all_scene_config

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

function parse_open_time(node)
	local open_time = {}
	for _, child in pairs(node) do
		if "TimeSpan" == child.tag then
			local time_span = {}
			time_span.hour = tonumber(child.attr["hour"])
			time_span.minu = tonumber(child.attr["minu"])
			time_span.interval = tonumber(child.attr["interval"])
			time_span.boss_index = tonumber(child.attr["boss_index"])
			table.insert(open_time, time_span)
		end
	end
	return open_time
end



function parse_summon(node)
	local summon = {}
	for _, child in pairs(node) do
		if "OpenTime" == child.tag then
			summon.open_time = parse_open_time(child)
		end
	end
	return summon
end

function parse_item_list(node)
	local item_list = {}
	for _, child in pairs(node) do
		if "Item" == child.tag then
			local item = {}
			item.id = tonumber(child.attr["id"])
			item.name = child.attr["name"]
			item.count = tonumber(child.attr["number"])
			table.insert(item_list, item)
		end
	end
	return item_list
end

function parse_entry(node)
	local entry = {tonumber(node.attr["x"]), tonumber(node.attr["y"])}
	return entry
end

function parse_boss(node)
	local boss = {}
	for _, child in pairs(node) do
		if "Item" == child.tag then
			local item = {}
			item.occ = tonumber(child.attr["occ"])
			item.pos = {tonumber(child.attr["x"]), tonumber(child.attr["y"])}
			item.reward_id = tonumber(child.attr["reward_id"])
			boss[tonumber(child.attr["index"])] = item
		end
	end
	return boss
end

function parse_extra(node)
	local extra = {}
	for _, child in pairs(node) do
		if "Item" == child.tag then
			table.insert(extra, {tonumber(child.attr["id"]), tonumber(child.attr["value"]), child.attr["name"]})
		end
	end
	return extra
end

function parse_reward(node)
	local reward = {}
	for _, child in pairs(node) do
		if "Top" == child.tag then
			reward.number = tonumber(child.attr["number"])
			reward.top = {}
			for _, cc in pairs(child) do
				if "Extra" == cc.tag then
					local id = tonumber(cc.attr["id"])
					reward.top[id] = parse_extra(cc)
				end
			end
		end
	end
	return reward
end

function parse_rewards(node)
	local rewards = {}
	for _, child in pairs(node) do
		if "Reward" == child.tag then
			rewards[tonumber(child.attr["id"])] = parse_reward(child)
		end
	end
	return rewards
end

function parse_comments(node)
	local comments = {}
	for _, child in pairs(node) do
		if "Item" == child.tag then
			table.insert(comments, child.attr["text"])
		end
	end
	return comments
end

function load_wild_boss_config(path)
	local file_handle = io.open(path)
	if not file_handle then
		debug_print("str_file can't open the xml file, file name=", path)
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

			local map_config = {}
			for _, child in pairs(node) do
				if "Entry" == child.tag then
					map_config.entry = parse_entry(child)
				elseif "Summon" == child.tag then
					map_config.summon = parse_summon(child)
				elseif "Boss" == child.tag then
					map_config.boss = parse_boss(child)
				elseif "Rewards" == child.tag then
					map_config.rewards = parse_rewards(child)
				elseif "Comments" == child.tag then
					map_config.comments = parse_comments(child)
				end
			end
			config[id] = map_config
		end
	end
	return true
end

load_wild_boss_config(CONFIG_DIR .. "xml/wild_boss/wild_boss.xml")
--print("config", j_e(config[38100]))