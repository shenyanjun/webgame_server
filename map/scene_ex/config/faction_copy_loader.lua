local lom = require("lom")

module("scene_ex.config.faction_copy_loader", package.seeall)

function parse_obj_attribute(node, template)
	local obj = {}
	for _, key in ipairs(template) do
		obj[key] = tonumber(node.attr[key])
	end
	return obj
end

function parse_from_template(node, template)
	local result = {}
	for _, child in pairs(node) do
		local info = template[child.tag]
		if info then
			local obj = {}
			for _, key in ipairs(info[2] or {}) do
				obj[key] = tonumber(child.attr[key])
			end
			local name = info[1]
			if name then
				result[name] = obj
			else
				table.insert(result, obj)
			end
		end
	end
	return result
end

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
		if "FactionCopy" == node.tag then
			local id = tonumber(node.attr["id"])
			local map_config = {}
			map_config.layer = {}
			for _, child in pairs(node) do
				if "Home" == child.tag then
					map_config.home = {
						["id"] = tonumber(child.attr["id"])
						, ["pos"] = {tonumber(child.attr["x"]), tonumber(child.attr["y"])}
					}
				elseif "Limit" == child.tag then
					map_config.limit = parse_limit(child)
				elseif "Buff" == child.tag then
					map_config.buff = parse_buff(child)
				elseif "Comments" == child.tag then
					map_config.comments = parse_comments(child)
				elseif "Layer" == child.tag then
					map_config.layer[tonumber(child.attr["id"])] = parse_layer(child)
				end
			end
			config[id] = map_config
		end
	end

	return config
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

function parse_limit(node)
	local template = {
		["Level"] = {"level", {"min", "max"}}
		, ["Human"] = {"human", {"min", "max"}}
		, ["Cycle"] = {"cycle", {"number"}}
		, ["Timeout"] = {"timeout", {"number"}}
		, ["FactionLevel"] = {"faction_level", {"min", "max"}}
	}
	return parse_from_template(node, template)
end

function parse_buff(node)
	local buff = {}
	buff.list = {}
	for _, child in pairs(node) do
		if "Gold" == child.tag then
			buff.gold = {tonumber(child.attr["number"]), tonumber(child.attr["probability"])}
		elseif "Jade" == child.tag then
			buff.jade = {tonumber(child.attr["number"]), tonumber(child.attr["probability"])}
		elseif "Item" == child.tag then
			table.insert(buff.list, tonumber(child.attr["point"]))
		end
	end
	return buff
end

function parse_comments(node)
	local comments = {}
	for _, child in pairs(node) do
		if "Email" == child.tag then
			comments.email = parse_comments_item(child)
		elseif "Broadcast" == child.tag then
			comments.broadcast = parse_comments_item(child)
		end
	end
	return comments
end

function parse_comments_item(node)
	local comments = {}
	for _, child in pairs(node) do
		if "Item" == child.tag then
			table.insert(comments, child.attr["text"])
		end
	end
	return comments
end

function parse_boss(node)
	local template = {"occ", "level", "defense", "hp"}
	local boss = parse_obj_attribute(node, template)
	boss.name = node.attr["name"]
	return boss
end

function parse_reward_item(node)
	local items = {}
	for _, child in pairs(node) do
		if "Item" == child.tag then
			local type = tonumber(child.attr["type"])
			if type == 3 then
				if items[3] == nil then
					items[3] = {}
				end
				table.insert(items[3], {tonumber(child.attr["id"]), tonumber(child.attr["value"]), child.attr["name"]} )
			else
				items[type] = {tonumber(child.attr["value"]), tonumber(child.attr["factor"]) or 0, tonumber(child.attr["max"]) or 0}
			end
		end
	end
	return items
end

function parse_rewards(node)
	local rewards = {}
	for _, child in pairs(node) do
		if "Common" == child.tag then
			rewards.common = parse_reward_item(child)
		elseif "Killer" == child.tag then
			rewards.killer = parse_reward_item(child)
		elseif "Top" == child.tag then
			rewards.top = {}
			for _, child2 in pairs(child) do
				if "Extra" == child2.tag then
					table.insert(rewards.top, parse_reward_item(child2))
				end
			end
		end
	end
	return rewards
end

function parse_wild(node)
	local wild = {}
	wild.collect = {}
	for _, child in pairs(node) do
		if "Collect" == child.tag then
			table.insert(wild.collect, {tonumber(child.attr["hp_per"]), tonumber(child.attr["id"]),
				tonumber(child.attr["number"]), tonumber(child.attr["time"])})
		end
	end
	return wild
end

function parse_layer(node)
	local layer = {}
	for _, child in pairs(node) do
		if "Entry" == child.tag then
			layer.entry = parse_entry(child)
		elseif "Map" == child.tag then
			layer.map_id = tonumber(child.attr["map_id"])
			layer.path = CONFIG_DIR .. child.attr["path"]
		elseif "PassTime" == child.tag then
			layer.pass_time = tonumber(child.attr["value"])
		elseif "Rewards" == child.tag then
			layer.rewards = parse_rewards(child)
		elseif "Boss" == child.tag then
			layer.boss = parse_boss(child)
		elseif "Wild" == child.tag then
			layer.wild = parse_wild(child)
		end
	end
	return layer
end


config = parse_config(Server_path .. "common/config/xml/faction/faction_copy.xml")
--print("config:", j_e(config[2201000]))