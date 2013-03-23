


local debug_print = function() end
local lom = require("lom")

module("vip.vip_info_load", package.seeall)

VipTable = {}

function init()
	local filename = CONFIG_DIR .. "xml/vip/vip.xml"
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
		if xml_tree.tag == "card" then
			local t_node = {}
			for attr_name,attr_value in pairs(xml_tree.attr) do
				if type(attr_name) == "string" and attr_name == "item_name" then
					t_node[attr_name] = attr_value
				else
					t_node[attr_name] = tonumber(attr_value)
				end
			end
			for i,xml_node in pairs(xml_tree) do
				if type(xml_node.tag) == "string" and xml_node.tag == "vip_bonus" then
					t_node["vip_bonus"] = {}
					for k,node in pairs(xml_node) do
						if type(node.tag) == "string" and node.tag == "item_list" then
							t_node["vip_bonus"]["item_list"] = {}
							local item_count = 1
							for key,value in pairs(node)do
								if type(value.tag) == "string" then
									t_node["vip_bonus"]["item_list"][item_count] = {}
									for attr_k,attr_v in pairs(value.attr) do
										t_node["vip_bonus"]["item_list"][item_count][attr_k] = tonumber(attr_v)
									end
									item_count = item_count+1	
								end
							end
						elseif type(node.tag) == "string" and node.tag == "vip_exp" then
							t_node["vip_bonus"]["vip_exp"] = {}
							for key,value in pairs(node.attr) do
								t_node["vip_bonus"]["vip_exp"][key] = tonumber(value)
							end
						end
					end
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
	local number = t_node.type_id
	VipTable[number] = {}
	for key,value in pairs(t_node) do
		if type(value) ~= "table" then
			VipTable[number][key] = value
		elseif type(value ) == "table" then
			VipTable[number][key] = {}
			for k,v in pairs(value) do
				if k == "item_list" then
					VipTable[number][key][k] = {}
					for i,node_v in pairs(v) do
						VipTable[number][key][k][i] = node_v  
					end
				elseif k == "vip_exp" then
					VipTable[number][key][k] = v
				end
			end
			
		end
	end 
end 


--启动物品加载
init()