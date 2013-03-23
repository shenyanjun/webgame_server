
local debug_print = function() end
local lom = require("lom")

module("npc.config.random_script_loader", package.seeall)

Random_config = {}


--从XML文件中读取数据
function HandleXmlFile(str_file)
	debug_print("HandleXmlFile str_file=", str_file)
	local file_handle = io.open(str_file)
	if not file_handle then
		debug_print("HandleXmlFile can't open the xml file, file name=", str_file)
		return E_FAIL_TO_OPEN_FILE
	end
	local file_data = file_handle:read("*a")
	file_handle:close()
	local xml_tree,err = lom.parse(file_data)
	if err then
		debug_print("HandleXmlFile error:",err)
		return E_FAIL_TO_PARSE_XML
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
		if xml_tree.tag == "Action" then
			local t_node = {}
			for attr_name, attr_value in pairs(xml_tree.attr) do
				if type(attr_name) == "string" and attr_name == "id" then
					t_node[attr_name] = attr_value
				elseif type(attr_name) == "string" and attr_name == "money" then
					t_node[attr_name] = tonumber(attr_value) or 0
				elseif type(attr_name) == "string" and attr_name == "money_type" then
					t_node[attr_name] = tonumber(attr_value) or 0
				end
			end
			for xml_node_index, xml_node in pairs(xml_tree) do
				if type(xml_node.tag) == "string" and xml_node.tag == "random_item_list" then
					t_node[xml_node.tag] = {}
					local item_list = {}

					for node_attr,node_attr_value in pairs(xml_node) do
						if node_attr_value.attr then
							local item_id = tonumber(node_attr_value.attr.id) or 0
							item_list[item_id] = {}

							item_list[item_id].name = node_attr_value.attr.name
							item_list[item_id].type = tonumber(node_attr_value.attr.type) or 0
							item_list[item_id].value = tonumber(node_attr_value.attr.value) or 0
							item_list[item_id].price = tonumber(node_attr_value.attr.money) or 0
							item_list[item_id].number = tonumber(node_attr_value.attr.number) or 0					
						end
						if type(node_attr) == "string" and node_attr == "attr" then
							t_node[xml_node.tag].limit = tonumber(node_attr_value.limit)
						end 
					end

					t_node[xml_node.tag].item_list = item_list
				end

				if type(xml_node.tag) == "string" and xml_node.tag == "certain_item_list" then
					t_node[xml_node.tag] = {}
					local item_list = {}

					for node_attr,node_attr_value in pairs(xml_node) do
						if node_attr_value.attr then
							local item_id = tonumber(node_attr_value.attr.id) or 0
							item_list[item_id] = {}

							item_list[item_id].name = node_attr_value.attr.name
							item_list[item_id].item_id = tonumber(node_attr_value.attr.id) or 0
							item_list[item_id].number = tonumber(node_attr_value.attr.number) or 0
							item_list[item_id].type = tonumber(node_attr_value.attr.type) or 0
							item_list[item_id].price = tonumber(node_attr_value.attr.money) or 0					
						end
					end

					t_node[xml_node.tag].item_list = item_list
				end
			end
			HandleEmbed(t_node,1)
		else
			for k,xml_node in pairs(xml_tree) do
				HandleXmlTree(xml_node)
			end
		end
	end
end

function HandleEmbed(t_node)
	local action_id = t_node.id

	local action_l = {}
	action_l.money = t_node.money
	action_l.money_type = t_node.money_type 
	action_l.random_item_list = t_node.random_item_list or {}
	action_l.certain_item_list = t_node.certain_item_list or {}

	--计算权值
	if action_l.random_item_list.item_list ~= nil then
		local value_t = 0
		for item_id,o in pairs(action_l.random_item_list.item_list) do
			value_t = value_t + o.value
		end
		action_l.random_item_list.value_t = value_t
	end

	Random_config[action_id] = action_l
end



--启动物品加载
HandleXmlFile(CONFIG_DIR .. "xml/script/random_script.xml")

function Get_random_script_name(action_id,item_id)
	if Random_config[action_id].certain_item_list.item_list[item_id].name then
		return Random_config[action_id].certain_item_list.item_list[item_id].name
	end
	return Random_config[action_id].random_item_list.item_list[item_id].name
end

