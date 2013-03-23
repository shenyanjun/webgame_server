local debug_print = function() end
local lom = require("lom")

module("mall.limit_loader", package.seeall)

MallLimitTable = {}

function init()
	local filename = CONFIG_DIR .. "xml/mall/mall_limited.xml"
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
			for i,xml_node in pairs(xml_tree) do
				if type(xml_node.tag) == "string" and xml_node.tag == "item_list" then
					t_node[xml_node.tag] = {}
					local count = 1
					for attr_key,attr_value in pairs(xml_node) do
						if type(attr_value.tag) == "string" and attr_value.tag == "item" then
							t_node[xml_node.tag][count] = {}
							for k,v in pairs(attr_value.attr) do
						    	if type(k) == "string" and k == "name" then
									t_node[xml_node.tag][count][k] = v
								else
									t_node[xml_node.tag][count][k] = tonumber(v)
								end
							end
							count = count+1	
						end	
					end
				elseif type(xml_node.tag) == "string" and xml_node.tag == "backup_list" then
					t_node[xml_node.tag] = {}
					local count = 1
					for attr_key,attr_value in pairs(xml_node) do
						if type(attr_value.tag) == "string" and attr_value.tag == "item" then
							t_node[xml_node.tag][count] = {}
							for k,v in pairs(attr_value.attr) do
						    	if type(k) == "string" and k == "name" then
									t_node[xml_node.tag][count][k] = v
								else
									t_node[xml_node.tag][count][k] = tonumber(v)
								end
							end
							count = count+1	
						end	
					end
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
	local number = t_node.id
	MallLimitTable[number] = {}
	MallLimitTable[number].min = t_node.startTime
	MallLimitTable[number].max = t_node.endTime
	if t_node.item_list then
		MallLimitTable[number].item_list = {}
		MallLimitTable[number].item_list.min = t_node.startTime
		MallLimitTable[number].item_list.max = t_node.endTime
		local weights = 0
		for k, v in pairs(t_node.item_list) do
			MallLimitTable[number].item_list[k] = {}
			MallLimitTable[number].item_list[k].id = v.id
			MallLimitTable[number].item_list[k].name = v.name
			MallLimitTable[number].item_list[k].weights = v.weights
			MallLimitTable[number].item_list[k].currency = v.currency
			MallLimitTable[number].item_list[k].original_price = v.original_price
			MallLimitTable[number].item_list[k].new_price = v.new_price
			MallLimitTable[number].item_list[k].total_count = v.total_count
			MallLimitTable[number].item_list[k].limited_time = v.limited_time
			MallLimitTable[number].item_list[k].limited_count = v.limited_count
			weights = weights+v.weights
		end
		MallLimitTable[number].item_list.weights = weights 
	end

	if t_node.backup_list then
		MallLimitTable[number].backup_list = {}
		local weights = 0
		for k, v in pairs(t_node.backup_list) do
			MallLimitTable[number].backup_list[k] = {}
			MallLimitTable[number].backup_list[k].id = v.id
			MallLimitTable[number].backup_list[k].name = v.name
			MallLimitTable[number].backup_list[k].weights = v.weights
			MallLimitTable[number].backup_list[k].currency = v.currency
			MallLimitTable[number].backup_list[k].original_price = v.original_price
			MallLimitTable[number].backup_list[k].new_price = v.new_price
			MallLimitTable[number].backup_list[k].total_count = v.total_count
			MallLimitTable[number].backup_list[k].limited_time = v.limited_time
			MallLimitTable[number].backup_list[k].limited_count = v.limited_count
			weights = weights+v.weights
		end
		MallLimitTable[number].backup_list.weights = weights 
	end
end


--启动物品加载
init()

