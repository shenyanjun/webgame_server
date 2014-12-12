local debug_print = function() end
local lom = require("lom")
module("npc.config.embed_loader", package.seeall)

EmbedTable = {}
RageEmbed = {}

function init()
	HandleXmlFile(CONFIG_DIR .. "xml/casting/embed.xml")
	HandleRageXmlFile(CONFIG_DIR .. "xml/casting/rage_embed.xml")
end

--从XML文件中读取数据
function HandleRageXmlFile(str_file)
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
	local ret = HandleRageXmlTree(xml_tree)
end

--XML数据结构分析
function HandleRageXmlTree(xml_tree)
	if not xml_tree then
		debug_print("HandleXmlTree tree is nil return")
		return 1
	end
	if xml_tree.tag then
		if xml_tree.tag == "Embed" then
			local item_str = "Embed"
			local t_node = {}
			for attr_name, attr_value in pairs(xml_tree.attr) do
				if type(attr_name) == "string" then
					t_node[attr_name] = tonumber(attr_value)
				end
			end
			for i, xml_node in pairs(xml_tree) do
				if type(xml_node.tag) == "string" and xml_node.tag == "item_list" then
					t_node[xml_node.tag] = {}
					local item_count = 1
					for k,v in pairs(xml_node) do
						if type(v.tag) == "string" then
							t_node[xml_node.tag][item_count] = tonumber(v[1])
							item_count = item_count + 1
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
			HandleRageEmbed(t_node)
		else
			for k,xml_node in pairs(xml_tree) do
				HandleRageXmlTree(xml_node)
			end
		end
	end
end

--处理打孔配置表
function HandleRageEmbed(t_node)
	local slot = t_node.id
	RageEmbed[slot] = {}
	if t_node.item_list then
		RageEmbed[slot].item_list = {}
		for k,v in pairs(t_node.item_list) do
			RageEmbed[slot].item_list[v] = 1
		end
	end

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
		if xml_tree.tag == "Embed" then
			local item_str = "Embed"
			local t_node = {}
			for attr_name, attr_value in pairs(xml_tree.attr) do
				if type(attr_name) == "string" then
					t_node[attr_name] = tonumber(attr_value)
				end
			end
			for i, xml_node in pairs(xml_tree) do
				if type(xml_node.tag) == "string" and xml_node.tag == "lvl_list" then
					t_node[xml_node.tag] = {}
					local item_count = 1
					for k,v in pairs(xml_node) do
						if v.tag then
							t_node[xml_node.tag][item_count] = {}
							for attr_name, attr_value in pairs(v.attr) do
								if type(attr_name) == "string" then
									t_node[xml_node.tag][item_count][attr_name] = tonumber(attr_value)
								end
							end
							item_count = item_count + 1
						end
					end
				elseif type(xml_node.tag) == "string" and xml_node.tag == "item_list" then
					t_node[xml_node.tag] = {}
					local item_count = 1
					for k,v in pairs(xml_node) do
						if v.tag then
							t_node[xml_node.tag][item_count] = tonumber(v[1])
							item_count = item_count + 1
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
			HandleEmbed(t_node)
		else
			for k,xml_node in pairs(xml_tree) do
				HandleXmlTree(xml_node)
			end
		end
	end
end

--处理打孔配置表
function HandleEmbed(t_node)
	local slot = t_node.id
	EmbedTable[slot] = {}
	if t_node.item_list then
		EmbedTable[slot].item_list = {}
		for k,v in pairs(t_node.item_list) do
			EmbedTable[slot].item_list[k] = v
		end
	end

	if t_node.lvl_list then
		EmbedTable[slot].lvl_list = {}
		for k,v in pairs(t_node.lvl_list) do
			EmbedTable[slot].lvl_list[k] = v
		end
	end

end

--启动物品加载
init()
--print("193 =", j_e(RageEmbed))
