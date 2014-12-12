

local lom = require("lom")
module("npc.config.reset_seal_loader", package.seeall)

local seal_loader = {}

function init()
	local filename = CONFIG_DIR .. "xml/casting/equip_seal_reset.xml"
	HandleXmlFile(filename)
end

--从XML文件中读取数据
function HandleXmlFile(str_file)

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
		if xml_tree.tag == "equip_list" then
			local color = tonumber(xml_tree.attr.color)
			seal_loader[color] = {}	
			for i, xml_node in pairs(xml_tree) do
				if xml_node.tag == "material" then
					seal_loader[color]["material"] = seal_loader[color]["material"] or {}
					seal_loader[color]["material"][tonumber(xml_node.attr.id)] = tonumber(xml_node.attr.req_count)
				elseif xml_node.tag == "money_list" then
					seal_loader[color]["money"] = seal_loader[color]["money"] or {}					
					seal_loader[color]["money"] = tonumber(xml_node.attr.money)
				end
			end
		else
			for k,xml_node in pairs(xml_tree) do
				HandleXmlTree(xml_node)
			end
		end
	end
end

function get_reset_material(color)
	return seal_loader[color].material
end

function get_reset_money(color)
	return seal_loader[color].money
end

init()



