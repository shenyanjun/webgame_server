local debug_print = function() end
local lom = require("lom")

module("pet_adventure.pet_barrier.pet_barrier_loader", package.seeall)

barrier_list = {}

function init()
	HandleXmlFile(CONFIG_DIR .. "xml/pet/pet_adventure/pet_adventure.xml")
	--HandleXmlFile(XML_ITEMS_FILE_PATH .. 'pet_info.xml')
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
		if xml_tree.tag == "barrier" then
			local item_str = "barrier "
			local t_node = {}
			for attr_name, attr_value in pairs(xml_tree.attr) do
				if type(attr_name) == "string" and attr_name == "id" then
					t_node[attr_name] = tonumber(attr_value)
				elseif type(attr_name) == "string" and attr_name == "barrier_name" then
					t_node[attr_name] = attr_value
				elseif type(attr_name) == "string" and attr_name == "battle_type" then
					t_node[attr_name] = tonumber(attr_value)
				end
			end
			local t_node_1 = {}
			t_node_1.reward = {}
			t_node_1.monster = {}
			t_node_1.condition = {}
			local count = 0
			for i, xml_node in pairs(xml_tree) do
				if type(xml_node.tag) == "string" and xml_node.tag == "barrier_lvl" then
					count = count + 1
					t_node_1.reward[count] = {}
					for m, n in pairs(xml_node.attr) do
						if type(m) == "string" and m == "level" then
							t_node_1.reward[count][1] = tonumber(n)
						elseif type(m) == "string" and m == "player_exp" then
							t_node_1.reward[count][2] = tonumber(n)
						elseif type(m) == "string" and m == "money" then
							t_node_1.reward[count][3] = tonumber(n)
						elseif type(m) == "string" and m == "pet_exp" then
							t_node_1.reward[count][4] = tonumber(n)
						elseif type(m) == "string" and m == "reward_id" then
							t_node_1.reward[count][5] = tonumber(n)
						elseif type(m) == "string" and m == "pet_bless" then
							t_node_1.reward[count][6] = tonumber(n)
						end
					end

					t_node_1.monster[count] = {}
					for k,v in pairs(xml_node) do
						if type(v.tag) == "string" and v.tag == "monster" then
						local table_monster = {}
							for m,n in pairs(v.attr) do
								if type(m) == "string" and m == "occ" then
									table_monster[1] = tonumber(n) 
								elseif type(m) == "string" and m == "monster_level" then
									table_monster[2] = tonumber(n) 
								elseif type(m) == "string" and m == "monster_pullulate" then
									table_monster[3] = tonumber(n) 
								elseif type(m) == "string" and m == "monster_name" then
									table_monster[4] = n
								end
							end
							table.insert(t_node_1.monster[count],table_monster)
						end
					end
				elseif type(xml_node.tag) == "string" and xml_node.tag == "barrier_condition" then
					for k,v in pairs(xml_node) do
						if type(v.tag) == "string" and v.tag == "condition" then
							for m,n in pairs(v.attr) do
								if type(m) == "string" and m == "id" then
									table.insert(t_node_1.condition, tonumber(n))
								end
							end
						end
					end
				end
			end
			HandleEmbed(t_node,t_node_1)
		else
			for k,xml_node in pairs(xml_tree) do
				HandleXmlTree(xml_node)
			end
		end
	end
end

function HandleEmbed(t_node, t_node_1)
	local barrier_id = t_node.id
	local battle_type = t_node.battle_type
	local barrier_name = t_node.barrier_name
	local barrier_condition = t_node_1.condition or {}

	barrier_list[barrier_id] = {}
	barrier_list[barrier_id].battle_type = battle_type
	barrier_list[barrier_id].barrier_name = barrier_name 
	barrier_list[barrier_id].condition = barrier_condition

	barrier_list[barrier_id].level_list = {}
	for k,v in pairs(t_node_1.reward) do
		local level = v[1]
		barrier_list[barrier_id].level_list[level] = {}
		barrier_list[barrier_id].level_list[level].reward = v
		barrier_list[barrier_id].level_list[level].monster = t_node_1.monster[k]
	end

end

--启动物品加载
init()

