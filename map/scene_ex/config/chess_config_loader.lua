local lom = require("lom")

module("scene_ex.config.chess_config_loader", package.seeall)

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
		if "Chess" == node.tag then
			local id = tonumber(node.attr["id"])
			local map_config = {}
			for _, child in pairs(node) do
				if "Init" == child.tag then
					map_config.init = parse_init(child)
				elseif "Wild" == child.tag then
					map_config.wild = parse_wild(child)

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


function parse_wild(node)
	local template = {
		["Item"] = {nil, {"id", "number", "area", "type"}}
	}
	
	local result = {}
	for _, child in pairs(node) do
		if "Sequence" == child.tag then
			local obj = {}
			obj.interval = tonumber(child.attr["interval"])
			obj.time = tonumber(child.attr["time"] or "0")
			obj.sequence = parse_from_template(child, template)
			table.insert(result, obj)
		end
	end
	
	return result
end

config = parse_config(Server_path .. "common/config/xml/chess/chess.xml")
--print("chess.xml ==>", j_e(config[3101000]))