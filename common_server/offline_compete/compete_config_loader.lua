local lom = require("lom")

module("offline_compete.compete_config_loader", package.seeall)

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
		if "Compete" == node.tag then
			for _, child in pairs(node) do
				if "Reward" == child.tag then
					config.reward = parse_reward(child)
				elseif "Broadcast" == child.tag then
					config.broadcast = {}
					config.broadcast.content = child.attr["content"]
				elseif "CD" == child.tag then
					config.cd = {}
					config.cd.time = tonumber(child.attr["time"])
					config.cd.cost = tonumber(child.attr["cost"])
				end
			end
		end
	end

	return config
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
		elseif "NOTICE" == child.tag then
			result.notice = {}
			result.notice.title = child.attr["title"]
			result.notice.content = child.attr["content"]
			result.notice.item_list = {}
			for _, entry in pairs(child) do
				if "Item" == entry.tag then
					table.insert(result.notice.item_list, {tonumber(entry.attr["id"]), tonumber(entry.attr["count"]), entry.attr["name"]})
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
--print("compete.xml ==>", j_e(config))