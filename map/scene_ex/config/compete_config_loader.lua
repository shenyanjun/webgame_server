local lom = require("lom")

module("scene_ex.config.compete_config_loader", package.seeall)

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
		if "Compete" == node.tag then
			local id = tonumber(node.attr["id"])
			local map_config = {}
			for _, child in pairs(node) do
				if "Init" == child.tag then
					map_config.init = parse_init(child)
				elseif "Reward" == child.tag then
					map_config.reward = parse_reward(child)
				elseif "CD" == child.tag then
					map_config.cd = {}
					map_config.cd.time = tonumber(child.attr["time"])
					map_config.cd.cost = tonumber(child.attr["cost"])
				end
			end
			config[id] = map_config
		end
	end

	return config
end

function parse_limit(node)
	local data = {}
	for _, child in pairs(node) do
		if "Level" == child.tag then
			data.level = {tonumber(child.attr["min"]), tonumber(child.attr["max"])}
		elseif "Human" == child.tag then
			data.human = {tonumber(child.attr["min"]), tonumber(child.attr["max"])}
		elseif "Cycle" == child.tag then
			data.cycle = tonumber(child.attr["number"])
		elseif "Time" == child.tag then
			data.time = (tonumber(child.attr["hour"]) or 0) * 3600
				+ (tonumber(child.attr["min"]) or 0) * 60 + (tonumber(child.attr["sec"]) or 0) 
		end
	end
	
	return data
end

function parse_init(node)
	local data = {}
	for _, child in pairs(node) do
		if "Entry" == child.tag then
			data.entry = {tonumber(child.attr["x"]), tonumber(child.attr["y"])}
		elseif "Pos" == child.tag then
			data.pos = {tonumber(child.attr["x"]), tonumber(child.attr["y"])}
		elseif "Limit" == child.tag then
			data.limit = parse_limit(child)
		elseif "Home" == child.tag then
			data.home = {
				["id"] = tonumber(child.attr["id"])
				, ["pos"] = {tonumber(child.attr["x"]), tonumber(child.attr["y"])}
			}
		end
	end
	
	return data
end


function parse_reward(node)
	local result = {}
	result.r_time = tonumber(node.attr["hour"]) * 3600 + tonumber(node.attr["minute"]) * 60
	for _, child in pairs(node) do
		if "WIN" == child.tag then
			result.win = {}
			result.win.title = child.attr["title"]
			result.win.content = child.attr["content"]
			result.win.item_list = {}
			for _, entry in pairs(child) do
				if "Item" == entry.tag then
					table.insert(result.win.item_list, {tonumber(entry.attr["id"]), tonumber(entry.attr["count"]), entry.attr["name"]})
				end
			end
		elseif "LOSE" == child.tag then
			result.lose = {}
			result.lose.title = child.attr["title"]
			result.lose.content = child.attr["content"]
			result.lose.item_list = {}
			for _, entry in pairs(child) do
				if "Item" == entry.tag then
					table.insert(result.lose.item_list, {tonumber(entry.attr["id"]), tonumber(entry.attr["count"]), entry.attr["name"]})
				end
			end
		elseif "RANK" == child.tag then
			if result.rank == nil then
				result.rank = {}
			end
			local item = {}
			item.min = tonumber(child.attr["min"])
			item.max = tonumber(child.attr["max"])
			item.item_list = {}
			for _, entry in pairs(child) do
				if "Item" == entry.tag then
					table.insert(item.item_list, {tonumber(entry.attr["id"]), tonumber(entry.attr["count"]), entry.attr["name"]})
				elseif "Sp" == entry.tag then
					item.sp = tonumber(entry.attr["number"])
				end
			end
			table.insert(result.rank, item)
		end
	end
	
	return result
end

config = parse_config(Server_path .. "common/config/xml/compete/compete.xml")
--print("compete.xml ==>", j_e(config[4901000]))