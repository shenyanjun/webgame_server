
--local debug_print = print
local debug_print = function() end
local lom = require("lom")
module("npc.config.drill_loader", package.seeall)

DrillTable = {}

function init()
	--self:GetAllFile(XML_ITEMS_FILE_PATH, self.HandleXmlFile)
	local filename = CONFIG_DIR .. "xml/casting/drill.xml"
	HandleXmlFile(filename)
end

--从XML文件中读取数据
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
		if xml_tree.tag == "Drill" then
			local item_str = "Drill"
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
							t_node[xml_node.tag][item_count].count = tonumber(v[1])
							item_count = item_count + 1
						end
					end
				elseif type(xml_node.tag) == "string" and xml_node.tag == "material_list" then
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
							t_node[xml_node.tag][item_count].count = tonumber(v[1])
							item_count = item_count + 1
						end
					end
				elseif type(xml_node.tag) == "string" and xml_node.tag == "inc_material_list" then
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
							t_node[xml_node.tag][item_count].count = tonumber(v[1])
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
			HandleDrill(t_node)
		else
			for k,xml_node in pairs(xml_tree) do
				HandleXmlTree(xml_node)
			end
		end
	end
end

--处理打孔配置表
function HandleDrill(t_node)
	local drill_num = t_node.id
	DrillTable[drill_num] = {}
	if t_node.material_list then
		DrillTable[drill_num].material_list = {}
		for k,v in pairs(t_node.material_list) do
			DrillTable[drill_num].material_list[k] = v.id
		end
	end
	if t_node.inc_material_list then
		DrillTable[drill_num].inc_material_list = {}
		for k,v in pairs(t_node.inc_material_list) do
			DrillTable[drill_num].inc_material_list[k] = {}
			DrillTable[drill_num].inc_material_list[k].item_id = v.id
			DrillTable[drill_num].inc_material_list[k].percent = v.percent
		end
	end

	--DrillTable[drill_num].inc_material = t_node.inc_material or {}

	if t_node.lvl_list then
		DrillTable[drill_num].lvl_list = {}
		for k,v in pairs(t_node.lvl_list) do
			DrillTable[drill_num].lvl_list[k] = v
		end
	end

end


init()