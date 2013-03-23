local lom = require("lom")

module("scene_ex.config.territory_config_loader", package.seeall)

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
		if "Copy" == node.tag then
			local id = tonumber(node.attr["id"])
			local map_config = {}
			for _, child in pairs(node) do
				if "Entry" == child.tag then
					map_config.entry = parse_entry(child)
				elseif "Home" == child.tag then
					map_config.home = {
						["id"] = tonumber(child.attr["id"])
						, ["pos"] = {tonumber(child.attr["x"]), tonumber(child.attr["y"])}
					}
				elseif "Relive" == child.tag then
					map_config.relive = parse_relive(child)
					map_config.relive.time = tonumber(child.attr["time"])
				elseif "Limit" == child.tag then
					map_config.limit = parse_limit(child)
				elseif "Broadcast" == child.tag then
					map_config.broadcast = parse_broadcast(child)
				elseif "Score" == child.tag then
					map_config.score = parse_score(child)
				elseif "SceneLayer" == child.tag then
					if map_config.scene_layer == nil then
						map_config.scene_layer = {}
					end
					table.insert(map_config.scene_layer, parse_scene_layer(child))
				elseif "WDay" == child.tag then
					local w_id = tonumber(child.attr["id"])
					if not map_config.day_list then
						map_config.day_list = {}
					end
					map_config.day_list[w_id] = parse_day_list(child)
				elseif "Reward" == child.tag then
					map_config.reward = parse_reward(child)
				elseif "BuffMonster" == child.tag then
					map_config.buff_monster = parse_buff_monster(child)
				elseif "Experience" == child.tag then
					map_config.exp = {}
					map_config.exp.base = tonumber(child.attr["base"])
					map_config.exp.time = tonumber(child.attr["time"])
					map_config.exp.factor = tonumber(child.attr["factor"])
				end
			end
			config[id] = map_config
		end
	end

	return config
end

function parse_score(node)
	local score = {}
	for _, child in pairs(node) do
		if "Occ" == child.tag then
			score.occ = {}
			for _, entry in pairs(child) do
				if entry.tag == "Item" then
					score.occ[tonumber(entry.attr["id"])] = tonumber(entry.attr["point"])
				end
			end
		elseif "Power" == child.tag then
			score.power = {}
			for _, entry in pairs(child) do
				if entry.tag == "Item" then
					table.insert(score.power, {tonumber(entry.attr["power"]), tonumber(entry.attr["point"])})
				end
			end
		end
	end
	return score
end

function parse_buff_monster(node)
	local buff_monster = {}
	for _, child in pairs(node) do
		if "Item" == child.tag then
			buff_monster[tonumber(child.attr["monster_id"])] = {tonumber(child.attr["buff_id"]), tonumber(child.attr["per"]), tonumber(child.attr["val"]), tonumber(child.attr["time"])} 
		end
	end
	return buff_monster
end


function parse_belong(node)
	local belong = {}
	belong.begin = {}
	belong.m_list = {}
	for _, child in pairs(node) do
		if "Item" == child.tag then
			local item = {tonumber(child.attr["id"]), tonumber(child.attr["x"]), tonumber(child.attr["y"]), tonumber(child.attr["side"]) } 
			table.insert(belong.begin, item)
			belong.m_list[tonumber(child.attr["id"])] = {tonumber(child.attr["pair_id"]), {tonumber(child.attr["x"]), tonumber(child.attr["y"])} }
			belong.m_list[tonumber(child.attr["pair_id"])] = {tonumber(child.attr["id"]), {tonumber(child.attr["x"]), tonumber(child.attr["y"])} }
		end
	end
	return belong
end

function parse_entry(node)
	local entry = {}
	entry[1] = {}
	entry[2] = {}
	for _, child in pairs(node) do
		if "Side_1" == child.tag then
			local pos = {tonumber(child.attr["id"]), {tonumber(child.attr["x"]), tonumber(child.attr["y"])}}
			entry[1][tonumber(child.attr["id"])] = pos
			--table.insert(entry[1], pos)
		elseif "Side_2" == child.tag then
			local pos = {tonumber(child.attr["id"]), {tonumber(child.attr["x"]), tonumber(child.attr["y"])}}
			entry[2][tonumber(child.attr["id"])] = pos
			--table.insert(entry[2], pos)
		end
	end
	return entry
end

function parse_relive(node)
	local relive = {}
	relive[1] = {}
	relive[2] = {}
	relive[3] = {}
	relive[4] = {}
	for _, child in pairs(node) do
		if "Side_1" == child.tag then
			local pos = {tonumber(child.attr["id"]), {tonumber(child.attr["x"]), tonumber(child.attr["y"])}}
			relive[1][tonumber(child.attr["id"])] = pos
			--table.insert(relive[1], pos)
		elseif "Side_2" == child.tag then
			local pos = {tonumber(child.attr["id"]), {tonumber(child.attr["x"]), tonumber(child.attr["y"])}}
			relive[2][tonumber(child.attr["id"])] = pos
			--table.insert(relive[2], pos)
		elseif "Side_1_c" == child.tag then
			local pos = {tonumber(child.attr["id"]), {tonumber(child.attr["x"]), tonumber(child.attr["y"])}}
			relive[3][tonumber(child.attr["id"])] = pos
			--table.insert(relive[1], pos)
		elseif "Side_2_c" == child.tag then
			local pos = {tonumber(child.attr["id"]), {tonumber(child.attr["x"]), tonumber(child.attr["y"])}}
			relive[4][tonumber(child.attr["id"])] = pos
			--table.insert(relive[2], pos)
		end
	end
	return relive
end

function parse_limit(node)
	local template = {
		["Level"] = {"level", {"min", "max"}}
		, ["Human"] = {"human", {"min", "max"}}
		, ["Cycle"] = {"cycle", {"number"}}
		, ["Timeout"] = {"timeout", {"number"}}
		, ["FactionLevel"] = {"faction_level", {"min", "max"}}
		, ["CostFactionGold"] = {"cost_faction_gold", {"gold"}}
		, ["SuccessLayer"] = {"success_layer", {"number"}}
	}
	return parse_from_template(node, template)
end

function parse_broadcast(node)
	local broadcast = {}
	broadcast.occ = {}
	for _, child in pairs(node) do
		if child.tag == "occ" then
			local id = tonumber(child.attr["id"])
			broadcast.occ[id] = {}
			broadcast.occ[id].enter = child.attr["enter"]
			broadcast.occ[id].leave = child.attr["leave"]	
		elseif child.tag then
			broadcast[child.tag] = child.attr["text"]
		end
	end
	return broadcast
end

function parse_scene_layer(node)
	local scene_layer = {}
	for _, child in pairs(node) do
		if "Map" == child.tag then
			scene_layer.map = tonumber(child.attr["id"])
			scene_layer.path = CONFIG_DIR .. child.attr["path"]
		elseif "Timeout" == child.tag then
			scene_layer.timeout = tonumber(child.attr["value"])
		elseif "Entry" == child.tag then
			scene_layer.entry = {tonumber(child.attr["x"]), tonumber(child.attr["y"])}
		elseif "Boss" == child.tag then
			if scene_layer.boss == nil then scene_layer.boss = {} end
			scene_layer.boss[tonumber(child.attr["side"])] = {tonumber(child.attr["occ"]), {tonumber(child.attr["x"]), tonumber(child.attr["y"])}, tonumber(child.attr["time"]), child.attr["notify"] and tonumber(child.attr["notify"])}
		elseif "Wild" == child.tag then
			scene_layer.wild = parse_wild(child)
		elseif "Born" == child.tag then
			scene_layer.born = parse_born(child)
		elseif "Belong" == child.tag then
			scene_layer.belong = parse_belong(child)
		end
	end
	return scene_layer
end

function parse_wild(node)
	local wild = {}
	wild[1] = false
	wild[2] = false
	for _, child in pairs(node) do
		if "Side_1" == child.tag then
			wild[1] = parse_wild_side(child)
		elseif "Side_2" == child.tag then
			wild[2] = parse_wild_side(child)
		end
	end
	return wild
end

function parse_wild_side(node)
	local template = {
		["Item"] = {nil, {"id", "number", "interval", "area", "path", "target", "total", "notify", "area_t"}}
	}
	
	local result = {}
	for _, child in pairs(node) do
		if "Sequence" == child.tag then
			local obj = {}
			obj.interval = tonumber(child.attr["interval"])
			obj.sequence = parse_from_template(child, template)
			table.insert(result, obj)
		elseif "Repeat" == child.tag then
			result.repeat_create = parse_from_template(child, template)
		end
	end
	return result
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

function parse_reward_node(node)
	local give_box_l = {}
	for _, child in pairs(node) do
		if "GiveBox" == child.tag then
			local give_box = {}
			give_box.box_title = child.attr["box_title"]
			for _, entry in pairs(child) do
				if entry.tag == "Item" then
					if give_box.item_list == nil then give_box.item_list = {} end
					table.insert(give_box.item_list, {count=tonumber(entry.attr["count"]), id=tonumber(entry.attr["id"]), name=entry.attr["name"]})
				end
				if entry.tag == "Money" then
					if give_box.money_list == nil then give_box.money_list = {} end
					table.insert(give_box.money_list, {tonumber(entry.attr["type"]), tonumber(entry.attr["ratio"])})
				end
			end
			table.insert(give_box_l, give_box)
		end
	end
	return give_box_l
end

function parse_reward(node)
	local reward = {}
	reward.title = node.attr["title"]
	reward.content = node.attr["content"]
	for _, child in pairs(node) do
		if "Winner" == child.tag then
			reward.winner = parse_reward_node(child)
		elseif "Loser" == child.tag then
			reward.loser = parse_reward_node(child)
		end
	end
	--print("--->reward:", j_e(reward))
	return reward
end

config = parse_config(Server_path .. "common/config/xml/territory/territory.xml")
--print("--->config:", j_e(config[2501000]))