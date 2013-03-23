
local lom = require("lom")
local _random = math.random
module("scene_ex.config.fish_config_loader", package.seeall)


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
		if "Fishing" == node.tag then
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
				
				elseif "Limit" == child.tag then
					map_config.limit = tonumber(child.attr["level"])
					map_config.max_fish = tonumber(child.attr["max_char"])
					map_config.max_count = tonumber(child.attr["max_count"])
				elseif "Fish" == child.tag then
					map_config.fish = parse_fish(child)
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

function parse_fish(node)
	local info = {}
	for _, child in pairs(node) do
		if "Hook" == child.tag then
			local hook_id = tonumber(child.attr["id"])
			local fish_list = parse_fish_list(child)
                        info[hook_id] = fish_list
		end
	end
	return info
end

function parse_fish_list(node)
	local info = {}
        local index = 1
	for _, child in pairs(node) do
              if "Item" == child.tag then
                    local w = {}
                    w.kind = tonumber(child.attr["kind"])
                    w.item_id = tonumber(child.attr["id"])
                    w.hits = tonumber(child.attr["hits"])
                    w.number = tonumber(child.attr["count"])
                    w.rate = tonumber(child.attr["rate"])
                    w.type = 1
                    info[index] = w
                    index = index + 1
              end
        end
        return info
end

config, myconfig = parse_config(CONFIG_DIR .. "xml/activity/fish.xml")
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
