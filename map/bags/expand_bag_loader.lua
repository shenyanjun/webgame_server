
local debug_print = function() end
local lom = require("lom")

module("bags.expand_bag_loader", package.seeall)

Expand_bag_price_tbl = {}


function HandleXmlFile(str_file)
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
	for _,xml_node in pairs(xml_tree) do
		if xml_node.tag == 'bag' then
			local bag_id = tonumber(xml_node.attr['bag_id'])
			Expand_bag_price_tbl[bag_id] = {}
			for _, value in pairs(xml_node) do
				if value.tag == 'expand' then
					local cur_size = tonumber(value.attr.cur_size)
					Expand_bag_price_tbl[bag_id][cur_size] = {}
					Expand_bag_price_tbl[bag_id][cur_size].money_type = tonumber(value.attr.money_type)
					Expand_bag_price_tbl[bag_id][cur_size].add_size = tonumber(value.attr.add_size)
					Expand_bag_price_tbl[bag_id][cur_size].amount = tonumber(value.attr.amount)
				end
			end
		end
	end
end


--启动加载
HandleXmlFile(CONFIG_DIR .. "xml/bag/expand_bag.xml")