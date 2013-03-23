
local lom = require("lom")
local _random = math.random
module("scene_ex.config.sheep_config_loader", package.seeall)


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
	local myconfig = {}
	for _, node in pairs(xml_tree) do
		if "Sheep" == node.tag then
			local id = tonumber(node.attr["id"])
			local map_config = {}
			for _, child in pairs(node) do
				if "Entry" == child.tag then
					map_config.entry = {tonumber(child.attr["x"]), tonumber(child.attr["y"])}
				elseif "Home" == child.tag then
					map_config.home = {
						["id"] = tonumber(child.attr["id"])
						, ["pos"] = {tonumber(child.attr["x"]), tonumber(child.attr["y"])}
					}
				
				elseif "Item" == child.tag then
					map_config.treasure = parse_treasure(child)
				elseif "Limit" == child.tag then
					map_config.limit = tonumber(child.attr["level"])
					map_config.max_sheep = tonumber(child.attr["max_sheep"])
				elseif "Relive" == child.tag then
					map_config.relive = {
								["time"] = tonumber(child.attr["time"])
							, 	["pos"] = {tonumber(child.attr["x"]), tonumber(child.attr["y"])}
							}
				elseif "Leave" == child.tag then
					map_config.leave = {
								["dis"] = tonumber(child.attr["dis"])
							, 	["pos"] = {tonumber(child.attr["x"]), tonumber(child.attr["y"])}
							}
				elseif "Pasture" == child.tag then
					map_config.pasture = parse_pasture(child)
				elseif "Wolf" == child.tag then
					map_config.wolf = parse_wolf(child)
				elseif "Sheep" == child.tag then
					map_config.sheep = parse_sheep(child)
				elseif "Count" == child.tag then
					map_config.count = parse_count(child)
				elseif "WDay" == child.tag then
					local w_id = tonumber(child.attr["id"])
					if not map_config.day_list then
						map_config.day_list = {}
					end
					map_config.day_list[w_id] = parse_day_list(child)
				end
			end
			
			config[id] = map_config
			myconfig = map_config
		end
	end
	
	return config, myconfig
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


function parse_treasure(node)
	local treasure = {}
	for _, child in pairs(node) do
		if "Treasure" == child.tag then
			local id = tonumber(child.attr["id"])
			local item_l = parse_item(child)
			treasure[id] = {}
			treasure[id].item_l = item_l
			treasure[id].exp = tonumber(child.attr["exp"])
		end
	end
	return treasure
end

function parse_item(node)
	local item_l = {}
	for _, child in pairs(node) do
		if "item_list" == child.tag then
			local list = {}
			list.count = tonumber(child.attr["count"])
			list.item_l = parse_item_l(child)
			table.insert(item_l, list)
		end
	end
	return item_l
end

function parse_item_l(node)
	local item_l = {}
	for _, child in pairs(node) do
		if "item" == child.tag then
			local item = {}
			item.item_id = tonumber(child.attr["id"])
			item.value = tonumber(child.attr["value"])
			item.number = tonumber(child.attr["count"])
			item.type = 1
			item.broadcast = tonumber(child.attr["broadcast"])
			table.insert(item_l, item)
		end
	end
	return item_l
end

function parse_pasture(node)
	local area = {}
	local info = {}
	for _, child in pairs(node) do
		if "Item" == child.tag then
			local w = {}
			w.id = tonumber(child.attr["id"])
			w.span = tonumber(child.attr["span"])
			w.number = tonumber(child.attr["number"])
			w.count = tonumber(child.attr["count"])
			local ar = tonumber(child.attr["area"])
			area[ar] = w 
			info[w.id] = w
		end
	end
	return {["area"] = area, ["info"] = info}
end

function parse_wolf(node)
	local wolf = {}
	for _, child in pairs(node) do
		if "Item" == child.tag then
			local w = {}
			w.id = tonumber(child.attr["id"])
			w.att = tonumber(child.attr["att"])
			w.area  = tonumber(child.attr["area"])
			wolf = w 
		end
	end
	return wolf
end

function parse_sheep(node)
	local sheep = {}
	for _, child in pairs(node) do
		if "Level" == child.tag then
			local sh = {}
			sh.level = tonumber(child.attr["id"])
			sh.pasture = tonumber(child.attr["pasture"])
			sh.hp = tonumber(child.attr["hp"])
			sh.def = tonumber(child.attr["def"])
			sheep[sh.level] = sh
		end
	end
	return sheep
end

function parse_count(node)
	local count = {}
	for _, child in pairs(node) do
		if "Item" == child.tag then
			local sh = tonumber(child.attr["sheep"])
			local wf = tonumber(child.attr["wolf"])
			count[sh] = wf
		end
	end
	return count
end

config, myconfig = parse_config(CONFIG_DIR .. "xml/activity/sheep.xml")
for k, v in pairs(myconfig) do
	--print("0000000000000", k)
	if k ~= "treasure" then
		--print(j_e(v))
	end
end
--//***************************new algorithm form table*************************//
--list传入的table， number需要从list随机取出number个对象， fun(o) 返回list[i]中权值的位置 如（list[i][j] or list[i].weight 若无则默认为1）
function random_algorithm(list, u, fun)
	local location = {}
	local a = {}
	local total = 0
	local rate = {}
	local n = table.getn(list)
	--print("table.getn", n, u)
	for i, v in ipairs(list) do
		a[i] = (fun and fun(v) or 1)
		location[i] = i
		total = total + a[i]
		rate[i] = total
	end
	local reduce
	local result = {}
	for i = 1, u do
		local bingo = _random(1, total)
		--print(bingo)
		for j = 1, n do
			if rate[j] >= bingo then
				result[i] = location[j]
				if i == number then
					break
				end
				--调整
				total = total - a[j]
				reduce = a[n] - a[j]
				a[j] = a[n]
				rate[j] = a[j] + (rate[j-1] or 0)
				location[j] = n
				for k =  j+ 1, n do
					rate[k] = rate[k] + reduce;
				end
				
				break
			end
		end
		n = n - 1
	end

	return result
end


local l = {}
l[1] = 10
l[2] = 2
l[3] = 5

local f = function(e) return e end

function test()
	local r = {}
	for i = 1, 10000 do
		local t = random_algorithm(l, 2, f)
		for _, v in pairs(t) do
			r[v] = (r[v] or 0) + 1
		end
	end
	print(j_e(r))
end
--test()