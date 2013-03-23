--活动配置加载文件


--local debug_print = print
local debug_print = function() end
local lom = require("lom")
module("npc.config.faction_npc_loader", package.seeall)

faction_npc_list = {}
count = 1

function init()
	HandleXmlFile(CONFIG_DIR .. "xml/faction/faction_npc.xml")
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
		if xml_tree.tag == "faction_npc" then
		
			for i, xml_node in pairs(xml_tree) do
				if xml_node.tag == "item" then
					local item_str = "item"
					local t_node = {}
					for attr_name, attr_value in pairs(xml_node.attr) do
						if type(attr_name) == "string" and attr_name == "item_id" then
							t_node[attr_name] = attr_value
						elseif type(attr_name) == "string" and attr_name == "price" then			
							t_node[attr_name] = tonumber(attr_value)
						elseif type(attr_name) == "string" and attr_name == "gold_level" then
							t_node[attr_name] = tonumber(attr_value)
						end
					end
					HandleEmbed_faction_npc(t_node)
				end
			end
		else
			for k,xml_node in pairs(xml_tree) do
				HandleXmlTree(xml_node)
			end
		end
	end
end

function HandleEmbed_faction_npc(t_node)
	faction_npc_list[t_node.item_id] = {}
	faction_npc_list[t_node.item_id][1] = t_node.item_id
	faction_npc_list[t_node.item_id][2] = t_node.price
	faction_npc_list[t_node.item_id][3] = t_node.gold_level
end

--启动物品加载
init()