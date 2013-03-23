local lom = require("lom")

module("scene_ex.config.more_kill_loader", package.seeall)


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
		if "MoreKill" == node.tag then
			local id = tonumber(node.attr["id"])
			local map_config = {}
			for _, child in pairs(node) do
				if "Init" == child.tag then
					map_config.init = parse_init(child)
				elseif "Wild" == child.tag then
					map_config.wild_monster_time = tonumber(child.attr["monster_time"]) or 10
					map_config.wild = parse_wild(child)
				elseif "Reward" == child.tag then
					map_config.reward = parse_reward(child)
				elseif "KillCount" == child.tag then
					map_config.kill_count = parse_kill_count(child)
				elseif "Buff" == child.tag then
					map_config.buff = parse_buff(child)
				elseif "TransportPos" == child.tag then
					map_config.transport_pos = parse_transport_pos(child)
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
		elseif "Vip" == child.tag then
			data.vip = {}
			data.vip[3] = tonumber(child.attr["level_3"])
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
	local wild = {}
	for _, child in pairs(node) do
		if "Level" == child.tag then
			table.insert(wild, {tonumber(child.attr["limit"]), parse_level(child)})
		end
	end
	
	return wild
end

function parse_level(node)
	local template = {
		["Item"] = {nil, {"id", "number"}}
	}
	
	local level = {}
	for _, child in pairs(node) do
		if "Create" == child.tag then
			local obj = {}
			obj.area = tonumber(child.attr["area"])
			obj.live_size = tonumber(child.attr["live_size"])
			obj.item = parse_from_template(child, template)
			table.insert(level, obj)
		end
	end
	
	return level
end

function parse_reward(node)
	local reward = {}
	for _, child in pairs(node) do
		if "Monster" == child.tag then
			if reward.monster == nil then
				reward.monster = {}
			end
			table.insert(reward.monster, parse_reward_entry(child))
		elseif "Boss" == child.tag then
			if reward.boss == nil then
				reward.boss = {}
			end
			table.insert(reward.boss, parse_reward_entry(child))
		elseif "MoreKill" == child.tag then
			if reward.more_kill == nil then
				reward.more_kill = {}
			end
			table.insert(reward.more_kill, parse_reward_entry(child))
		end
	end
	
	return reward
end

function parse_reward_entry(node)
	local template = {
		["Item"] = {nil, {"kill", "number"}}
	}
	
	local reward = {}
	for _, child in pairs(node) do
		if "Prop" == child.tag then
			reward.prop = parse_prop(child)
		elseif "Point" == child.tag then
			reward.point = parse_from_template(child, template)
		end
	end
	
	return reward
end

function parse_prop(node)
	local prop = {}
	for _, child in pairs(node) do
		if "Item" == child.tag then
			table.insert(prop, {id = tonumber(child.attr["id"]), name = child.attr["name"]})
		end
	end
	return prop
end

function parse_kill_count(node)

	local kill_count = {}
	for _, child in pairs(node) do
		if "Item" == child.tag then
			table.insert(kill_count, {tonumber(child.attr["count"]), tonumber(child.attr["time"])})
		end
	end
	return kill_count
end

function parse_buff(node)

	local buff = {}
	for _, child in pairs(node) do
		if "Transport" == child.tag then
			buff.transport = {}
			for _, item in pairs(child) do
				if "Item" == item.tag then
					buff.transport[tonumber(item.attr["count"])] = tonumber(item.attr["size"])
				end
			end
		elseif "Refresh" == child.tag then
			buff.refresh = {}
			for _, item in pairs(child) do
				if "Item" == item.tag then
					buff.refresh[tonumber(item.attr["count"])] = tonumber(item.attr["size"])
				end
			end
		elseif "MoreKill" == child.tag then
			buff.more_kill = {}
			for _, item in pairs(child) do
				if "Item" == item.tag then
					buff.more_kill[tonumber(item.attr["count"])] = {tonumber(item.attr["factor"])}
				end
			end
		elseif "Magic" == child.tag then
			buff.magic = {}
			buff.magic.factor = tonumber(child.attr["factor"])
		end
	end
	return buff
end

function parse_transport_pos(node)
	local transport_pos = {}
	for _, child in pairs(node) do
		if "Pos" == child.tag then
			table.insert(transport_pos, {tonumber(child.attr["x"]), tonumber(child.attr["y"])})
		end
	end
	return transport_pos
end

config = parse_config(Server_path .. "common/config/xml/more_kill/more_kill.xml")
--print("more_kill.xml ==>", j_e(config[3501000]))