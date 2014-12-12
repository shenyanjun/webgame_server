--活动配置加载文件


--local debug_print = print
local debug_print = function() end
local lom = require("lom")
module("npc.config.honor_loader", package.seeall)

honor_list = {}
glory_list = {}

function init()
	HandleXmlFile(CONFIG_DIR .. "xml/honor/honor_npc.xml")
	HandleXmlFile(CONFIG_DIR .. "xml/honor/glory_npc.xml")
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
		if xml_tree.tag == "honor_npc" then
		
			for i, xml_node in pairs(xml_tree) do
				if xml_node.tag == "item" then
					local item_str = "item"
					local t_node = {}
					for attr_name, attr_value in pairs(xml_node.attr) do
						if type(attr_name) == "string" and attr_name == "item_id" then
							t_node[attr_name] = attr_value
						elseif type(attr_name) == "string" and attr_name == "value" then			
							t_node[attr_name] = tonumber(attr_value)
						end
					end
					HandleEmbed_honor(t_node)
				end
			end
		elseif xml_tree.tag == "glory_npc" then
		
			for i, xml_node in pairs(xml_tree) do
				if xml_node.tag == "item" then
					local item_str = "item"
					local t_node = {}
					for attr_name, attr_value in pairs(xml_node.attr) do
						if type(attr_name) == "string" and attr_name == "item_id" then
							t_node[attr_name] = attr_value
						elseif type(attr_name) == "string" and attr_name == "value" then			
							t_node[attr_name] = tonumber(attr_value)
						end
					end
					HandleEmbed_glory(t_node)
				end
			end
		else
			for k,xml_node in pairs(xml_tree) do
				HandleXmlTree(xml_node)
			end
		end
	end
end

function HandleEmbed_honor(t_node)
	honor_list[t_node.item_id] = t_node.value
end

function HandleEmbed_glory(t_node)
	glory_list[t_node.item_id] = t_node.value
end

--启动物品加载
init()
