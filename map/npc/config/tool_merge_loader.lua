local debug_print = function() end

local lom = require("lom")
module("npc.config.tool_merge_loader", package.seeall)

Merge_config_tbl = {}


function init()
	local filename = CONFIG_DIR .. "xml/casting/tool_merge.xml"
	HandleXmlFile(filename)
end

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
	for _,xml_node in pairs(xml_tree) do
		if xml_node.tag == 'merge' then
			Merge_config_tbl[tonumber(xml_node.attr.id)] = {}
			Merge_config_tbl[tonumber(xml_node.attr.id)].next_id = tonumber(xml_node.attr.next_id)
			Merge_config_tbl[tonumber(xml_node.attr.id)].next_name = xml_node.attr.next_name
		end
	end
end


--启动加载
init()