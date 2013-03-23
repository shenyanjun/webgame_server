local debug_print = function() end
local lom = require("lom")

module("mall.mall_benefit_loader", package.seeall)

local Pre_page = 16

CatalogTable = {}  --type ->物品
CatalogTable_item = {}  --item_id ->物品

function init()
	local filename = CONFIG_DIR .. "xml/mall/mall_benefit.xml"
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
		if xml_tree.tag == "Catalog" then
			local item_str = "Catalog "
			local t_node = {}
			for attr_name, attr_value in pairs(xml_tree.attr) do
				if attr_name == "id" then
					t_node[attr_name] = attr_value
				elseif attr_name == "name" then
					t_node[attr_name] = attr_value
				else
					t_node[attr_name] = tonumber(attr_value)
				end
			end
			local item_count = 1
			t_node.item_list = {}
			for i, xml_node in pairs(xml_tree) do
				if type(xml_node.tag) == "string" and xml_node.tag == "item" then
					t_node.item_list[item_count] = {}
					local node_value = xml_node[1]
					for node_attr, node_attr_value in pairs(xml_node.attr) do
						if type(node_attr) == "string" then
							t_node.item_list[item_count][node_attr] = tonumber(node_attr_value)
						end
					end
					item_count = item_count + 1
				end
			end
			handle_page(t_node)
		else
			for k,xml_node in pairs(xml_tree) do
				HandleXmlTree(xml_node)
			end
		end
	end
end


function handle_page(t_node)
	for k,v in pairs(t_node.item_list) do
		local list = {}
		list.item_id = v.item_id
		local _,item = Item_factory.create(v.item_id)
		if item == nil then
			print("item is not exist!", v.item_id)
		end
		list.name = item:get_name()
		list.price = v.price
		CatalogTable_item[v.item_id] = list
	end
end


--启动物品加载
init()
