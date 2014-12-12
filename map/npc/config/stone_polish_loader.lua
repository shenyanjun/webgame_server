--宝石打磨配置加载
local debug_print = function() end

local lom = require("lom")

module("npc.config.stone_polish_loader", package.seeall)

item_reward = {}

function init()
	HandleXmlFile(CONFIG_DIR .. "xml/casting/stone_polish.xml")
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
XML_ERROR_TREE_NIL = 1
function HandleXmlTree(xml_tree)
	if not xml_tree then
		debug_print("HandleXmlTree tree is nil return")
		return XML_ERROR_TREE_NIL
	end
	if xml_tree.tag then
		if xml_tree.tag == "reward" then
			local item_str = "reward "
			local t_node = {}
			local t_reward = {}
			for attr_name, attr_value in pairs(xml_tree.attr) do
				if type(attr_name) == "string" and attr_name == "gift_percent" then
					t_node[attr_name] = tonumber(attr_value)
				elseif type(attr_name) == "string" and attr_name == "money" then
					t_node[attr_name] = tonumber(attr_value)
				elseif type(attr_name) == "string" and attr_name == "item_id" then
					t_node[attr_name] = attr_value
				elseif type(attr_name) == "string" then
					t_node[attr_name] = attr_value
				end
			end
			local count = 1 
			for i, xml_node in pairs(xml_tree) do
				if type(xml_node.tag) == "string" and xml_node.tag == "item" then
					t_reward[count] = {}
					for attr_name,attr_value in pairs(xml_node.attr) do
						if type(attr_name) == "string" and attr_name == "item_id" then
							t_reward[count][1] = tonumber(attr_value)
						elseif type(attr_name) == "string" and attr_name == "count" then
							t_reward[count][2] = tonumber(attr_value)
						elseif type(attr_name) == "string" and attr_name == "wave" then
							t_reward[count][3] = tonumber(attr_value)
						end
					end
					count = count + 1
				end
			end
			HandleEmbed(t_node,t_reward)
		else
			for k,xml_node in pairs(xml_tree) do
				HandleXmlTree(xml_node)
			end
		end
	end
end

function HandleEmbed(t_node,t_reward)
     local item_id = t_node.item_id
	 item_reward[item_id] = {}
	 item_reward[item_id].gift_percent = t_node.gift_percent
	 item_reward[item_id].money = t_node.money
	 item_reward[item_id].reward_list = t_reward
end 


function f_get_item_reward()
	return item_reward
end
init()

--------------------------------------------------------------------------------------------------

