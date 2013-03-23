local lom = require("lom")

module("scene_ex.config.copy_detail_loader", package.seeall)

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

copy = {}

function parse_config(path)
	local xml_tree = load_file(path)
	if not xml_tree then
		return {}
	end
	
	copy["copy_cate"] = {}
	copy["copy_pre_rank"] = {}
	copy["copy_list"] = {}
	local k = 1
	local n = 1
	for _, child in pairs(xml_tree) do
		if "Copy" == child.tag then
			for _, node in pairs(child) do
				if node.tag == "Scene" then
					
					local copy_info = {}
					copy_info["id"] = tonumber(node.attr["id"])
					copy_info["name"] = tostring(node.attr["Name"])
					copy_info["lv_down"] = tonumber(node.attr["MinLevel"])
					copy_info["lv_up"] = tonumber(node.attr["MaxLevel"])
					copy_info["cycle"] = tonumber(node.attr["Cycle"])
					copy_info["min_number"] = tonumber(node.attr["MinNumber"])
					copy_info["max_number"] = tonumber(node.attr["MaxNumber"])
					copy_info["cate"] = tonumber(node.attr["Cate"])
					copy_info["pre"] = tonumber(node.attr["Pre"])
					--print("&&&&&&", j_e(copy_info))
					if not copy.copy_cate[copy_info.cate] then
						copy.copy_cate[copy_info.cate] = {}
					end
					table.insert(copy.copy_cate[copy_info.cate], copy_info)
					table.insert(copy.copy_pre_rank, copy_info)
					copy.copy_list[copy_info.id] = copy_info
				end
			end
		end
	end

	return copy
end

copy = parse_config(CONFIG_DIR .. "/xml/detail_optimize/copy_detail.xml")

local sortFunc = function(a, b)
	return a.pre < b.pre
end
for k, v in pairs(copy.copy_cate) do
	table.sort(v, sortFunc)
end

table.sort(copy.copy_pre_rank, sortFunc)

--print(j_e(config.copy_cate))
