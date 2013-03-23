local debug_print = function() end
local lom = require("lom")

module("answer_ex.answer_time_loader", package.seeall)

time_config = {}

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
	local time = {}
	for _, child in pairs(xml_tree) do
		if "Ordinary" == child.tag then
			time["ord"] = parse_ord(child)
		elseif "Festival" == child.tag then
			time["fes"] = parse_fes(child)
		end
	end
	return time
end


function parse_ord(node)
	local data = {}
	for _, child in pairs(node) do
		if "Wday" == child.tag then
			local week = tonumber(child.attr["id"])
			data[week] = parse_week(child)		
		end
	end
	return data
end


function parse_week(node)
	local data = {}
	for _, child in pairs(node) do
		if "cycle" == child.tag then
			local cycle = tonumber(child.attr["id"])
			data[cycle] = {["hour"] = tonumber(child.attr["hour"]), ["min"] = tonumber(child.attr["min"]),
					["interval"] = tonumber(child.attr["interval"]), ["reward"] = tonumber(child.attr["reward"])}
		end
	end
	return data
end

function parse_fes(node)
	local data = {}
	for _, child in pairs(node) do
		if "Fes" == child.tag then
			local date = tonumber(child.attr["id"])
			data[date] = {["hour"] = tonumber(child.attr["hour"]), ["min"] = tonumber(child.attr["min"]),
					["interval"] = tonumber(child.attr["interval"]), ["reward"] = tonumber(child.attr["reward"])}
			--print("********fes", j_e(data[date]))	 		
		end
	end
	return data
end

time_config = parse_config(CONFIG_DIR .. "/xml/answer_ex/question_time.xml")
