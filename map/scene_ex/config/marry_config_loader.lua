local lom = require("lom")

module("scene_ex.config.marry_config_loader", package.seeall)

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
		if "Map" == node.tag then
			local id = tonumber(node.attr["id"])
			local map_config = {}
			for _, child in pairs(node) do
				if "Entry" == child.tag then
					map_config.entry = parse_entry(child)
				elseif "Home" == child.tag then
					map_config.home_carry = {
						["id"] = tonumber(child.attr["id"])
						, ["pos"] = {tonumber(child.attr["x"]), tonumber(child.attr["y"])}
					}
				elseif "Human" == child.tag then
					map_config.human_max = tonumber(child.attr["max"])
				elseif "Timeout" == child.tag then
					map_config.timeout = tonumber(child.attr["number"])
				elseif "Hero" == child.tag then
					map_config.hero = parse_master(child)
				elseif "Heroine" == child.tag then
					map_config.heroine = parse_master(child)
				elseif "Guest" == child.tag then
					map_config.guest = parse_guest(child)
				elseif "OutTime" == child.tag then
					map_config.out_time = {tonumber(child.attr["second"]), tonumber(child.attr["price"])}
				elseif "Cupid" == child.tag then
					map_config.cupid = {}
					map_config.cupid.id = tonumber(child.attr["id"])
				elseif "Monster" == child.tag then
					map_config.monster = {}
					map_config.monster = parse_monster(child)
				elseif "Cycle" == child.tag then
					map_config.cycle = tonumber(child.attr["number"])
				elseif "Collect" == child.tag then
					map_config.collect = parse_collect(child)
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

function parse_master(node)
	local master = {}
	for _, child in pairs(node) do
		if "Pos" == child.tag then
			master.pos = {tonumber(child.attr["x"]), tonumber(child.attr["y"])}
		end
	end
	return master
end

function parse_guest(node)
	local guest = {}
	guest.area = {}
	for _, child in pairs(node) do
		if "Area" == child.tag then
			table.insert(guest.area, {tonumber(child.attr["area"]), tonumber(child.attr["size"])})
		end
	end
	return guest
end

function parse_monster(node)
	local monster = {}
	for _, child in pairs(node) do
		if "Sequence" == child.tag then
			local sequence = {}
			sequence.level = tonumber(child.attr["level"])
			sequence.intimacy = tonumber(child.attr["intimacy"])
			sequence.item = {}
			for _, child2 in pairs(child) do
				if "Item" == child2.tag then
					table.insert(sequence.item, {tonumber(child2.attr["id"]), tonumber(child2.attr["number"]), tonumber(child2.attr["area"])})
				end
			end
			table.insert(monster, sequence)
		end
	end
	return monster
end

function parse_collect(node)
	local collect = {}
	for _, child in pairs(node) do
		if "Item" == child.tag then
			table.insert(collect, {tonumber(child.attr["id"]), tonumber(child.attr["number"]), tonumber(child.attr["area"])})
		end
	end
	return collect
end

config = parse_config(Server_path .. "common/config/xml/marry/marry_scene.xml")
--print("--->config:", j_e(config[3401001]))