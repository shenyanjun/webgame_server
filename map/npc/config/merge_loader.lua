local debug_print = function() end

local lom = require("lom")
module("npc.config.merge_loader", package.seeall)


--local MergeLoader = {}
MergeTable = {}


function HandleXmlFile(str_file)
	debug_print("HandleXmlFile str_file=", str_file)
	local file_handle = io.open(str_file)
	if not file_handle then
		debug_print("HandleXmlFile can't open the xml file, file name=", str_file)
		return 
	end
	local file_data = file_handle:read("*a")
	file_handle:close()
	
	local xml_tree,err = lom.parse(file_data)
	if err then
		debug_print("HandleXmlFile error:",err)
		return 
	end
	local ret = HandleXmlTree(xml_tree)
end

--XML数据结构分析
function HandleXmlTree(xml_tree)
	if not xml_tree then
		debug_print("HandleXmlTree tree is nil return")
		return 1
	end
	if xml_tree.tag then
		if xml_tree.tag == "Merge" then
			local item_str = "Merge"
			local t_node = {}
			for attr_name, attr_value in pairs(xml_tree.attr) do
				if type(attr_name) == "string" then
					t_node[attr_name] = tonumber(attr_value)
				end
			end

			for i, xml_node in pairs(xml_tree) do
				if type(xml_node.tag) == "string" and xml_node.tag == "lvl_list" then
					t_node[xml_node.tag] = {}
					local item_count = 1
					for k,v in pairs(xml_node) do
						if v.tag then
							--local t_attr = {}
							t_node[xml_node.tag][item_count] = {}
							for attr_name, attr_value in pairs(v.attr) do
								if type(attr_name) == "string" then
									t_node[xml_node.tag][item_count][attr_name] = tonumber(attr_value)
									--t_attr[attr_name] = attr_value
								end
							end
							--t_node[xml_node.tag][item_count].count = tonumber(v[1])
							item_count = item_count + 1
						end
					end
				elseif type(xml_node.tag) == "string" and xml_node.tag == "protect_list" then
					t_node[xml_node.tag] = {}
					local item_count = 1
					for k,v in pairs(xml_node) do
						if v.tag then
							local t_attr = {}
							t_node[xml_node.tag][item_count] = {}
							for attr_name, attr_value in pairs(v.attr) do
								if type(attr_name) == "string" then
									t_node[xml_node.tag][item_count] = tonumber(attr_value) --[attr_name] 
								end
							end
							item_count = item_count + 1
						end
					end
				elseif type(xml_node.tag) == "string" then
					local node_value = xml_node[1]
					t_node[xml_node.tag] = tonumber(node_value)
					for node_attr, node_attr_value in pairs(xml_node.attr) do
						if type(node_attr) == "string" then
							if node_attr == "type" and node_attr_value == "string" then
								t_node[xml_node.tag] = xml_node[1]
							end
						end
					end
				end
			end
			HandleMerge(t_node)
		else
			for k,xml_node in pairs(xml_tree) do
				HandleXmlTree(xml_node)
			end
		end
	end
end

--处理强化配置表
function HandleMerge(t_node)
	local num = t_node.id
	MergeTable[num] = {}
	MergeTable[num].protect_list = t_node.protect_list or {}
	if t_node.lvl_list then
		MergeTable[num].lvl_list = {}
		--DrillTable[drill_num].lvl_list = t_node.lvl_list
		for k,v in pairs(t_node.lvl_list) do
			--DrillTable[drill_num].lvl_list[v.lvl] = {}
			MergeTable[num].lvl_list[k] = v
		end
	end
end


--启动加载
HandleXmlFile(CONFIG_DIR .. "xml/casting/gem_merge.xml")