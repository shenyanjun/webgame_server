

local lom = require("lom")
module("npc.config.reset_loader", package.seeall)

RandomTable = {}

function init()
	local filename = CONFIG_DIR .. "xml/casting/equip_reset.xml"
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
		if xml_tree.tag == "Random" then
			local t_node = {}
			for attr_name, attr_value in pairs(xml_tree.attr) do
				if type(attr_name) == "string" then
					t_node[attr_name] = tonumber(attr_value)
				end
			end
			for i, xml_node in pairs(xml_tree) do
				if type(xml_node.tag) == "string" and xml_node.tag == "material_list" then
					t_node[xml_node.tag] = {}
					local color_count = 1
					for k,equip_list in pairs(xml_node) do
						if type(equip_list.tag) == "string" and equip_list.tag == "equip_list" then
							t_node[xml_node.tag][color_count] = {}
							for attr_name, attr_value in pairs(equip_list.attr) do
							    if type(attr_name) == "string" then
									t_node[xml_node.tag][color_count][attr_name] = tonumber(attr_value)
								end 
							end
							local item_count = 1
							for key,v in pairs(equip_list) do
								if v.tag then
									t_node[xml_node.tag][color_count][item_count] = {}
									for attr_name,attr_value in pairs(v.attr) do
										if type(attr_name) == "string" then
											t_node[xml_node.tag][color_count][item_count][attr_name] = tonumber(attr_value)											
										end
									end
									item_count = item_count + 1
								end
							end
							color_count = color_count + 1
						end
					end
				elseif type(xml_node.tag) == "string" and xml_node.tag == "money_list" then
					t_node[xml_node.tag] = {}
					local level_count = 1
					for key,equip_level in pairs(xml_node) do
						if type(equip_level.tag) == "string" and equip_level.tag == "equip_level" then
							t_node[xml_node.tag][level_count] = {}
							for attr_name,attr_value in pairs(equip_level.attr) do
								if type(attr_name) == "string" then
									t_node[xml_node.tag][level_count][attr_name] = tonumber(attr_value)
								end
							end
							local color_count = 1
							for k,v in pairs(equip_level) do
								if v.tag then
									t_node[xml_node.tag][level_count][color_count] = {}
									for attr_name,attr_value in pairs(v.attr) do
										if type(attr_name) == "string" then
											t_node[xml_node.tag][level_count][color_count][attr_name] = tonumber(attr_value)
										end
									end
									color_count = color_count + 1
								end
							end
							level_count = level_count + 1
						 end
					  end
				elseif type(xml_node.tag) == "string" then
					local node_value = xml_node[1]
					t_node[xml_node.tag] = tonumber(node_value)
					for node_attr, node_attr_value in pairs(xml_node.attr) do
						if type(node_attr) == "string" then
							if node_attr == "type" and node_attr_value == "string" then
								t_node[xml_node.tag] = xml_node[1]
							end
						end
					end
				end
			end
			HandleRandom(t_node)
		else
			for k,xml_node in pairs(xml_tree) do
				HandleXmlTree(xml_node)
			end
		end
	end
end

--处理洗练配置表
function HandleRandom(t_node)
	local random_num = t_node.id
	RandomTable[random_num] = {}
	if t_node.money_list then
	    RandomTable[random_num].money_list = {}
		for k,v in pairs(t_node.money_list) do
			local level = v.id
			RandomTable[random_num].money_list[level] = {}
			RandomTable[random_num].money_list[level].max = v.max
			RandomTable[random_num].money_list[level].min = v.min
			for key,value in pairs(v) do
				if type(value) == "table" then
					RandomTable[random_num].money_list[level][key] = {}
					RandomTable[random_num].money_list[level][key].color = value.color
					RandomTable[random_num].money_list[level][key].money_type = value.money_type
					RandomTable[random_num].money_list[level][key].req_money = value.req_money
				end
			end 
		end
	end

	if t_node.material_list then
		RandomTable[random_num].material_list = {}
		for k,v in pairs(t_node.material_list) do
			local color = v.color
			RandomTable[random_num].material_list[color] = {}
			for key,value in pairs(v) do
				if type(value) == "table" then
					RandomTable[random_num].material_list[color][key] = {}
					RandomTable[random_num].material_list[color][key].id = value.id
					RandomTable[random_num].material_list[color][key].req_count = value.req_count
				end
			end
		end
	end
end


init()
--for k, v in pairs(RandomTable) do
	--print("162 =", k, j_e(v))
--end