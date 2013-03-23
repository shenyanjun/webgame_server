local debug_print = function() end
local lom = require("lom")

module("answer_ex.answer_reward_loader", package.seeall)


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

question_reward = {}

function parse_config(path)
	local xml_tree = load_file(path)
	if not xml_tree then
		return {}
	end
	local reward = {}
	for _, child in pairs(xml_tree) do
		if "sort" == child.tag then
			local number = tonumber(child.attr["reward"])
			local broadcast = tonumber(child.attr["broadcast"])
			reward["number"] = number
			reward["broadcast"] = broadcast
			reward["rank"] = parse_rank(child)
		end
	end
	return reward
end


function parse_rank(node)
	local data = {}
	for _, child in pairs(node) do
		if "level" == child.tag then
			local id = tonumber(child.attr["id"])
			data[id] = parse_reward(child)		
		end
	end
	return data
end

function parse_reward(node)
	local data = {}
	for _, child in pairs(node) do
		if "reward" == child.tag then
			for _, v in pairs(child) do
				if "item_list" == v.tag then
					data["item"] = parse_item(v)
				elseif "money_list" == v.tag then
					data["money"] = parse_money(v)
				end
			end
		end
	end
	return data
end

function parse_item(node)
	local data = {}
	for _, child in pairs(node) do
		if "item" == child.tag then
			local info = {}
			info.id = tonumber(child.attr["id"])
			info.count = tonumber(child.attr["number"])
			info.name = tostring(child.attr["name"])
			table.insert(data, info)
		end
	end
	return data
end

function parse_money(node)
	local data = {}
	for _, child in pairs(node) do
		if "money" == child.tag then
			local money = {}
			money.type = tonumber(child.attr["currency"])
			money.number =	tonumber(child.attr["number"])
			data[money.type] = money.number
		end
	end
	return data
end


question_reward = parse_config(CONFIG_DIR .. "/xml/answer_ex/question_reward.xml")
--print("&&&&&&reward", j_e(question_reward))