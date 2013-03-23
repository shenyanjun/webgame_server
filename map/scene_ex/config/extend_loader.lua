local lom = require("lom")

module("scene_ex.config.extend_loader", package.seeall)

config = {}
schedule = {}
transport = {}

function parse_time(node)
	local freq_list = nil
	for _, child in pairs(node) do
		if "TimeSpan" == child.tag then
			if not freq_list then
				freq_list = {}
			end
			local freq = {}
			freq.hour = tonumber(child.attr["hour"])
			freq.minu = tonumber(child.attr["minu"])
			freq.interval = tonumber(child.attr["interval"])
			freq.rate = tonumber(child.attr["rate"])
			table.insert(freq_list, freq)
		end
	end
	return freq_list
end

function parse_node(node)
	local info = {}
	for _, child in pairs(node) do
		if "Count" == child.tag then
			info.count = {}
			info.count.number = tonumber(child.attr["number"])
			info.count.rate = tonumber(child.attr["rate"])
		elseif "Time" == child.tag then
			info.time = parse_time(child)
		end
	end
	return info
end

function parse_notify(node)
	local notify = {}
	for _, child in pairs(node) do
		if "Descripe" == child.tag then
			local desc = {}
			desc.text = tostring(child.attr["text"])
			desc.offset = tonumber(child.attr["offset"])
			desc.type = tonumber(node.attr["type"] or 1)
			table.insert(notify, desc)
		end
	end
	return notify
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

function parse_collect_item(node)
	local collect = {}
	for _, child in pairs(node) do
		if "Collect" == child.tag then
			table.insert(collect, {tonumber(child.attr["id"]), tonumber(child.attr["number"]), 
				tonumber(child.attr["interval"]), tonumber(child.attr["area"])})
		end
	end
	return collect
end

function parse_collect_open_time(node)
	local open_time = {}
	for _, child in pairs(node) do
		if "TimeSpan" == child.tag then
			local time_span = {}
			time_span.hour = tonumber(child.attr["hour"])
			time_span.minu = tonumber(child.attr["minu"])
			time_span.interval = tonumber(child.attr["interval"])
			time_span.collect = parse_collect_item(child)
			table.insert(open_time, time_span)
		end
	end
	return open_time
end


function parse_day_list(node)
	local day = {}
	for _, child in pairs(node) do
		if "OpenTime" == child.tag then
			day.open_time = parse_open_time(child)
		elseif "Exp" == child.tag then
			day.exp = {}
			day.exp.base = tonumber(child.attr["base"])
			day.exp.limit = tonumber(child.attr["limit"])
			day.exp.interval = tonumber(child.attr["interval"])
		end
	end
	return day
end

function parse_exp_reward(node)
	local reward = {}
	for _, child in pairs(node) do
		if "Notify" == child.tag then
			reward.notify = parse_notify(child)
		elseif "WDay" == child.tag then
			local w_id = tonumber(child.attr["id"])
			local day = reward.day_list
			if not day then
				day = {}
				reward.day_list = day
			end
			day[w_id] = parse_day_list(child)
		end
	end
	return reward
end

function parse_collect_list(node)
	local day = {}
	for _, child in pairs(node) do
		if "OpenTime" == child.tag then
			day.open_time = parse_collect_open_time(child)
		end
	end
	return day
end

function parse_summon(node)
	local summon = {}
	for _, child in pairs(node) do
		if "Notify" == child.tag then
			summon.notify = parse_notify(child)
		elseif "WDay" == child.tag then
			local w_id = tonumber(child.attr["id"])
			local day = summon.day_list
			if not day then
				day = {}
				summon.day_list = day
			end
			day[w_id] = parse_collect_list(child)
		end
	end
	return summon
end

function parse_func(node)
	local type_args = {
		[0] = {"id", "min_x", "min_y", "max_x", "max_y", "level"}
		, [1] = {"level"}
		, [2] = {"level"}
		, [3] = {"level"}
		, [4] = {"level"}
		, [5] = {"level"}
	}

	local func_list = {}
	for _, child in pairs(node) do
		if "Func" == child.tag then
			local func = {}
			func.type = tonumber(child.attr["type"])
			for _, n in pairs(child) do
				if "Args" == n.tag then
					local args = {}
					for _, v in pairs(type_args[func.type]) do
						args[v] = tonumber(n.attr[v])
					end
					func.args = args
					break
				end
			end
			table.insert(func_list, func)
		end
	end
	return func_list
end

function parse_time_event(node)
	local day = {}
	for _, child in pairs(node) do
		if "TimeSpan" == child.tag then
			local timespan = {}
			timespan.time = tonumber(child.attr["hour"]) * 3600 + tonumber(child.attr["minu"]) * 60
			timespan.func = parse_func(child)
			table.insert(day, timespan)
		end
	end
	return day
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

function parse_reward(node)
	local reward = {}
	reward.quest_list = {}
	reward.fun_list = {}
	for _, child in pairs(node) do
		if "Reward" == child.tag then
			reward.exp = tonumber(child.attr["exp"])
			reward.gold = tonumber(child.attr["gold"])
			reward.gift_gold = tonumber(child.attr["gift_gold"])
			reward.gift_jade = tonumber(child.attr["gift_jade"])
			reward.jade = tonumber(child.attr["jade"])
			reward.item_list = parse_item_list(child)
		elseif "Quest" == child.tag then
			local quest_id = child.attr["id"]
			if quest_id then
				table.insert(reward.quest_list, quest_id)
			end
		elseif "Fun" == child.tag then
			local fun_id = child.attr["id"]
			if fun_id then
				table.insert(reward.fun_list, fun_id)
			end
		end
	end
	return reward
end

function parse_cheats(node)
	local cheats = {}
	cheats.options = {}
	for _, child in pairs(node) do
		if "Option" == child.tag then
			local item = {}
			item.target = tonumber(child.attr["target"])
			item.limit = tonumber(child.attr["limit"])
			item.t_id = tonumber(child.attr["t_id"])
			item.l_id = tonumber(child.attr["l_id"])
			item.reward = parse_reward(child)
			item.money = tonumber(child.attr["money"])
			item.mana = tonumber(child.attr["mana"]) or 0
			item.money_type = tonumber(child.attr["money_type"])
			table.insert(cheats.options, item)
		end
	end
	
	table.sort(
		cheats.options
		, function (l, r)
			if l.target == r.target then
				return l.limit < r.limit
			end
			return l.target < r.target
		end)
	
	cheats.list = {}
	for k, v in ipairs(cheats.options) do
		table.insert(cheats.list, {v.target, v.limit, v.money, v.money_type})
	end

	return cheats
end

function load_extend_config()
	local path = CONFIG_DIR .. "xml/extend/scene_extend.xml"
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
		if "Scene" == node.tag then
			local id = tonumber(node.attr["id"])
			local info = {}
			for _, child in pairs(node) do
				if "Exp" == child.tag then
					info.exp = parse_node(child)
				elseif "Lost" == child.tag then
					info.lost = parse_node(child)
				elseif "ExpReward" == child.tag then
					info.exp_reward = parse_exp_reward(child)
				elseif "Summon" == child.tag then
					info.summon = parse_summon(child)
				elseif "Cheats" == child.tag then
					info.cheats = parse_cheats(child)
				end
			end
			config[id] = info
		elseif "Schedule" == node.tag then
			for _, child in pairs(node) do
				if "WDay" == child.tag then
					local w_id = tonumber(child.attr["id"])
					schedule[w_id] = parse_time_event(child)
				end
			end
		elseif "Transport" == node.tag then
			for _, child in pairs(node) do
				if "Carry" == child.tag then
					local id = tonumber(child.attr["id"])
					transport[id] = {tonumber(child.attr["x"]), tonumber(child.attr["y"])}
				end
			end
		end
	end
	return true
end

load_extend_config()