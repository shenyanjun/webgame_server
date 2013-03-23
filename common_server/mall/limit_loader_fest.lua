local debug_print = function() end
local lom = require("lom")

module("mall.limit_loader_fest", package.seeall)

MallLimitFestItemTable = {}

function init()
	local filename = CONFIG_DIR .. "xml/mall/mall_limited_fest.xml"
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
		if xml_tree.tag == "date" then
			local t_node = {}
			for attr_name, attr_value in pairs(xml_tree.attr) do
				t_node[attr_name] = tonumber(attr_value)
			end
			t_node.item_list = {}
			local count = 1
			for i,xml_node in pairs(xml_tree) do
				if type(xml_node.tag) == "string" and xml_node.tag == "item" then
					t_node.item_list[count] = {}
					for key,value in pairs(xml_node.attr) do
					    if type(key) == "string" and key == "name" then
							t_node.item_list[count][key] = value
						else
							t_node.item_list[count][key] = tonumber(value)
						end
					end
					count = count+1	
				end
			end
			handle_node(t_node)
		else
			for k,xml_node in pairs(xml_tree) do
				HandleXmlTree(xml_node)
			end
		end
	end
end


function handle_node(t_node)
	local id = t_node.id
	MallLimitFestItemTable[id] = {}
	for k,v in pairs(t_node.item_list) do
		MallLimitFestItemTable[id][k] = {}
		MallLimitFestItemTable[id][k].id = v.id
		MallLimitFestItemTable[id][k].name = v.name
		MallLimitFestItemTable[id][k].currency = v.currency
		MallLimitFestItemTable[id][k].original_price = v.original_price
		MallLimitFestItemTable[id][k].new_price = v.new_price
		MallLimitFestItemTable[id][k].total_count = v.total_count
		MallLimitFestItemTable[id][k].limited_count = v.limited_count
		MallLimitFestItemTable[id][k].limited_time = v.limited_time

	end
	
end


--启动物品加载
init()
