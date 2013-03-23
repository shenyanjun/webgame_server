local debug_print = function() end
local lom = require("lom")
module("npc.config.advanced_loader", package.seeall)

AdvancedTable = {}

function init()
	HandleXmlFile(CONFIG_DIR .. "xml/casting/advanced.xml")
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
		if xml_tree.tag == "Series" then
			for i, xml_node in pairs(xml_tree) do
				if xml_node.tag == "Equip" then
					local t_node = {}

					for attr_name, attr_value in pairs(xml_node.attr) do
						if type(attr_name) == "string" then
							t_node[attr_name] = tonumber(attr_value)
						end
					end

					for k,v in pairs(xml_node) do
						local tmp_node = {}
						if v.tag == "material_list" then
							local item_count = 1
							for kk, vv in pairs(v) do
								if vv.tag == "material" then
									tmp_node[item_count] = {}
									for attr_name, attr_value in pairs(vv.attr) do
										if attr_name == "id" then
											tmp_node[item_count]["id"] = tonumber(attr_value)
										elseif attr_name == "req_num" then
											tmp_node[item_count]["req_num"] = tonumber(attr_value)
										end
									end

									item_count = item_count + 1
								end
							end

							t_node.material_l = {}
							for k, v in pairs(tmp_node) do
								t_node.material_l[v.id] = v.req_num
							end
						end
					end

					HandleAdvanced(t_node)
				end
			end
			
		else
			for k,xml_node in pairs(xml_tree) do
				HandleXmlTree(xml_node)
			end
		end
	end
end

--处理打孔配置表
function HandleAdvanced(t_node)
	local id = t_node.id
	AdvancedTable[id] = t_node
end

--启动物品加载
init()


--***************接口
function get_advanced_info(equip_id)
	if equip_id % 2 == 0 then
		equip_id = equip_id + 1
	end
	return AdvancedTable[equip_id]
end

--for kkk, vvv in pairs(AdvancedTable) do
	--for k, v in pairs(vvv) do
		--
		--if k == "material_l" then
			--for kk, vv in pairs(v) do
				--print("100, ", kk, vv)
			--end
		--else
			--print("97=", k, v)
		--end
	--end
--end
