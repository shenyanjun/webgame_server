
--读降妖配置

local lom = require("lom")
module("bags.monster_gift_loader", package.seeall)

--降妖随机物品表
monster_gift_item = {}
monster_gift_item.total = {}
monster_gift_item.spec	= {}
monster_need_item = {}

local GiftRandomLoader = {}
function GiftRandomLoader:init()
	--加载随机物品
	self:HandleXmlFile(CONFIG_DIR .. "xml/bag/monster_bag_gift.xml")
end

function GiftRandomLoader:HandleXmlFile(str_file)
	local file_handle = io.open(str_file)
	if not file_handle then
		print("HandleXmlFile can't open the xml file, file name=", str_file)
		return 
	end
	local file_data = file_handle:read("*a")
	file_handle:close()
	
	local xml_tree,err = lom.parse(file_data)
	if err then
		print("HandleXmlFile error:",err)
		return 
	end

	self:HandleItemXmlTree(xml_tree)

end

--XML数据结构分析
function GiftRandomLoader:HandleItemXmlTree(xml_tree, flags)
	if not xml_tree then
		print("HandleXmlTree tree is nil return")
		return XML_ERROR_TREE_NIL
	end
	if xml_tree.tag then
		if xml_tree.tag == "RandomItem" then
			local item_str = "RandomItem"
			local t_node = {}
			local t_id = 0
			for attr_name, attr_value in pairs(xml_tree.attr) do
				if type(attr_name) == "string" then
					t_node[attr_name] = attr_value
				end
				if attr_name == "id" then
					t_id = tonumber(attr_value)
				end
			end

			t_node['item_list'] = {}
			monster_need_item[t_id] = {} 

			for i, xml_node in pairs(xml_tree) do
				if type(xml_node.tag) == "string" and xml_node.tag == "need_item" then
					for c,d in pairs(xml_node) do
						if d.tag then
							local itemid , count
							for attr_name, attr_value in pairs(d.attr) do
								if attr_name == "id" then
									itemid = attr_value
								elseif attr_name == "count" then
									count = attr_value
								end
							end
							if itemid and count then
								monster_need_item[t_id][itemid] = count
							end
						end
					end
				end
				
				if type(xml_node.tag) == "string" and xml_node.tag == "item_list" then
					--for attr_name, attr_value in pairs(xml_node.attr) do
						--if type(attr_name) == "string" then
							--t_node['count'][cnt] = tonumber(attr_value)
						--end
					--end
					--
					local item_count = 1
					for k,v in pairs(xml_node) do
						if v.tag then
							t_node['item_list'][item_count] = {}
							for attr_name, attr_value in pairs(v.attr) do
								if type(attr_name) == "string" then
									if attr_name == 'value' or attr_name == 'id' or attr_name == 'count' or attr_name == 'record' then
										t_node['item_list'][item_count][attr_name] = tonumber(attr_value)
									else
										t_node['item_list'][item_count][attr_name] = attr_value
									end
								end
							end
							item_count = item_count + 1
						end
					end
				end
			end
			--print("\nt_node =",j_e(t_node))
			self:HandleItem(t_node)
		else
			for k,xml_node in pairs(xml_tree) do
				self:HandleItemXmlTree(xml_node, flags)
			end
		end
	end
end


--创建每一类地图的参数列表
function GiftRandomLoader:HandleItem(t_nodes)
	--if not flags then
		--Gift_Random_Item[tonumber(t_node.id)] = t_node
	--elseif flags == 1 then
		--security_box_item[tonumber(t_node.id)] = t_node
	--end
	local id = tonumber(t_nodes.id)
	monster_gift_item.total[id] = {}
	monster_gift_item.total[id].list = {}
	monster_gift_item.total[id].pro	 = 0

	monster_gift_item.spec[id] = {}
	monster_gift_item.spec[id].list = {}
	monster_gift_item.spec[id].pro	= 0

	local j = 1
	local total_lvl = 0
	local spec_lvl = 0
	for i = 1, table.getn(t_nodes.item_list) do
		--排好总表
		monster_gift_item.total[id].list[i] = {}
		for k, v in pairs(t_nodes.item_list[i]) do
			monster_gift_item.total[id].list[i][k] = v  
			if k == 'value' then
				total_lvl = total_lvl + v
				monster_gift_item.total[id].list[i].lvl = total_lvl
			end
		end
		monster_gift_item.total[id].pro = monster_gift_item.total[id].pro + tonumber(t_nodes.item_list[i]['value'])

		--排好特殊物品表
		if t_nodes.item_list[i].broadcast and t_nodes.item_list[i].broadcast == '1' then
			monster_gift_item.spec[id].list[j] = {}
			for k, v in pairs(t_nodes.item_list[i]) do
				monster_gift_item.spec[id].list[j][k] = v
				if k == 'value' then
					spec_lvl = spec_lvl + v
					monster_gift_item.spec[id].list[j].lvl = spec_lvl
				end
			end
			monster_gift_item.spec[id].pro = monster_gift_item.spec[id].pro + tonumber(t_nodes.item_list[i]['value'])
			j = j + 1
		end
	end
end

--启动物品加载
GiftRandomLoader:init()

function GetMonsterNeedItem(id)
	if id then
		return monster_need_item[id]
	end
	return monster_need_item
end




