


--local debug_print = print
local debug_print = function() end
local lom = require("lom")
module("pet_adventure.pet_adventure_reward_loader", package.seeall)

item_list = {}

function init()
	HandleXmlFile(CONFIG_DIR .. "xml/pet/pet_adventure/pet_adventure_reward.xml")
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
		if xml_tree.tag == "reward_item" then
			t_node = {}
			for attr_name, attr_value in pairs(xml_tree.attr) do
				if type(attr_name) == "string" and attr_name == "id" then
					t_node[attr_name] = tonumber(attr_value)
				end
			end

			for i, xml_node in pairs(xml_tree) do
				if xml_node.tag == "item_list" then
					t_node_1 = {}
					t_node_1.item_list = {}
					t_node_1.item = {}
					for attr_name, attr_value in pairs(xml_node.attr) do
						if type(attr_name) == "string" and attr_name == "count" then
							t_node_1.item_list[1] = tonumber(attr_value)
						end
					end
					
					local count_2 = 0
					for k, v in pairs(xml_node) do
						if v.tag == "item" then
							count_2 = count_2 + 1
							t_node_1.item[count_2] = {}
							for attr_name, attr_value in pairs(v.attr) do
								if type(attr_name) == "string" and attr_name == "item_id" then
									t_node_1.item[count_2][1] = tonumber(attr_value) or 0
								elseif type(attr_name) == "string" and attr_name == "count"then
									t_node_1.item[count_2][2] = tonumber(attr_value) or 0
								elseif type(attr_name) == "string" and attr_name == "wave" then				
									t_node_1.item[count_2][3] = tonumber(attr_value)			
								end
							end
						
						end
					end
					HandleEmbed_item(t_node, t_node_1)
				end
			end

		else
			for k,xml_node in pairs(xml_tree) do
				HandleXmlTree(xml_node)
			end
		end
	end
end

function HandleEmbed_item(t_node,t_node_1)
	local id = t_node.id
	if item_list[id] == nil then
		item_list[id] = {}
	end
	table.insert(item_list[id], t_node_1)
end

--启动物品加载
init()