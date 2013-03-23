module("npc.dynamic.dynamic_npc_loader", package.seeall)

local lom = require("lom")
schedule = {}

local parse_args = {}

parse_args[1] =
function (node)
	local args = {}
	args.occ = tonumber(node.attr["occ"])
	args.name = node.attr["name"]
	args.timeout = tonumber(node.attr["timeout"])
	args.action_id = node.attr["action_id"]
	args.area_list = {}
	for _, child in pairs(node) do
		if "Area" == child.tag then
			for _, n in pairs(child) do
				if "Scene" == n.tag then
					local area = {}
					area.id = tonumber(n.attr["id"])
					area.area = tonumber(n.attr["area"])
					area.number = tonumber(n.attr["number"])
					area.lv = tonumber(n.attr["lv"])
					table.insert(args.area_list, area)
				end
			end
		elseif "Factor" == child.tag then
			args.default = tonumber(child.attr["default"])
			args.factor = {tonumber(child.attr["a"]) or 0, tonumber(child.attr["b"]) or 0}
		end
	end
	
	table.sort(args.area_list, function (l, r) return l.lv < r.lv end)
	
	return args
end

function parse_func(node)
	local func_list = {}
	for _, child in pairs(node) do
		if "Func" == child.tag then
			local func = {}
			func.type = tonumber(child.attr["type"])
			for _, n in pairs(child) do
				if "Args" == n.tag then
					local fun = parse_args[func.type]
					if fun then
						func.args = fun(n)
					end
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
		return
	end
	
	local config = {}
	for _, node in pairs(xml_tree) do
		if "Schedule" == node.tag then
			for _, child in pairs(node) do
				if "WDay" == child.tag then
					local w_id = tonumber(child.attr["id"])
					config[w_id] = parse_time_event(child)
				end
			end
		end
	end
	
	for w_id, schedule_list in pairs(config) do
		for _, timespan in pairs(schedule_list) do
			for _, func in pairs(timespan.func) do
				local day_list = schedule[w_id]
				if not day_list then
					day_list = {}
					schedule[w_id] = day_list
				end
				
				local func_list = day_list[func.type]
				if not func_list then
					func_list = {}
					day_list[func.type] = func_list
				end
				
				table.insert(func_list, {["time"] = timespan.time, ["func"] = func})
			end
		end
	end
	
end

parse_config(CONFIG_DIR .. "xml/npc_function/dynamic_npc.xml")