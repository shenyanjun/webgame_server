local debug_print = function() end
local lom = require("lom")

module("vip.vip_fairy_store_loader", package.seeall)

FairyTable = {}

function init()
	local filename = CONFIG_DIR .. "xml/vip/fairy_store.xml"
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
		if xml_tree.tag == "catalog" then
			local t_node = {}
			for attr_name,attr_value in pairs (xml_tree.attr) do
				t_node[attr_name] = tonumber(attr_value)
			end
			local item_count  = 1
			t_node.item_list = {}
			
			for i ,xml_node in pairs (xml_tree) do
				if type(xml_node.tag) == "string" and xml_node.tag == "item" then
					t_node.item_list[item_count] = {}
					for attr_name,attr_value in pairs (xml_node.attr) do
						if type(attr_name) == "string" and attr_name == "name" then
							t_node.item_list[item_count][attr_name] = attr_value
						elseif type(attr_name) == "string" and attr_name == "item_id" then
							t_node.item_list[item_count][attr_name] = attr_value 
						else
							t_node.item_list[item_count][attr_name] = tonumber(attr_value)	
						end
						
					end
					item_count = item_count+1
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
	local number = t_node.id
	FairyTable[number] = {}
	FairyTable[number].item_list ={}
	for key,value in pairs(t_node.item_list) do
		FairyTable[number].item_list[value.item_id] = {}
		FairyTable[number].item_list[value.item_id].id = tonumber(value.item_id)
		FairyTable[number].item_list[value.item_id].name = value.name
		FairyTable[number].item_list[value.item_id].price = value.price
		FairyTable[number].item_list[value.item_id].currency = value.currency
	end

end


--启动物品加载
init()
