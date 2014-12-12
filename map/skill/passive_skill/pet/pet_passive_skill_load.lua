
local debug_print = function() end
local lom = require("lom")

module("skill.passive_skill.pet.pet_passive_skill_load", package.seeall)

--被动技能
skill_passive_param = {}
skill_passive_name = {}
--转移技能
skill_transfer_param = {}
skill_transfer_param_ratio = {}
skill_transfer_name = {}

function init()
	HandleXmlFile(CONFIG_DIR .. "xml/pet/pet_passive_skill.xml")
	--HandleXmlFile(XML_ITEMS_FILE_PATH .. 'pet_passive_skill.xml')
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
		if xml_tree.tag == "Pet_passive_skill" then							--被动技能
			
			local t_node = {}
			for attr_name, attr_value in pairs(xml_tree.attr) do
				if type(attr_name) == "string" and attr_name == "skill_tags" then
					t_node[attr_name] = tonumber(attr_value)
				end
			end

			t_node.skill_list = {}
			for i, xml_node in pairs(xml_tree) do
				if type(xml_node.tag) == "string" and xml_node.tag == "skill_info" then
					local node_value = xml_node[1]
					local id = tonumber(xml_node.attr.id)
					t_node.skill_list[id] = {}
					for node_attr, node_attr_value in pairs(xml_node.attr) do
						if type(node_attr) == "string" and node_attr == "name" then
							t_node.skill_list[id][node_attr] = node_attr_value
						elseif type(node_attr) == "string" then
							t_node.skill_list[id][node_attr] = tonumber(node_attr_value)
						end
					end
				end

			end

			HandleEmbed(t_node,1)

		elseif xml_tree.tag == "Pet_transfer_skill" then
			local t_node = {}
			for attr_name, attr_value in pairs(xml_tree.attr) do
				if type(attr_name) == "string" and attr_name == "skill_tags" then
					t_node[attr_name] = tonumber(attr_value)
				end
			end

			t_node.skill_list = {}
			for i, xml_node in pairs(xml_tree) do
				if type(xml_node.tag) == "string" and xml_node.tag == "skill_info" then
					local id = tonumber(xml_node.attr.id)
					t_node.skill_list[id] = {}
					local node_value = xml_node[1]
					for node_attr, node_attr_value in pairs(xml_node.attr) do
						if type(node_attr) == "string" and node_attr == "name" then
							t_node.skill_list[id][node_attr] = node_attr_value
						elseif type(node_attr) == "string" then
							t_node.skill_list[id][node_attr] = tonumber(node_attr_value)
						end
					end
				end
			end
			HandleEmbed(t_node,2)
		else
			for k,xml_node in pairs(xml_tree) do
				HandleXmlTree(xml_node)
			end
		end

	end
end

function HandleEmbed(t_node, type)

	if 1 == type then								--被动技能
		local cmd_id = t_node.skill_tags
		skill_passive_param[cmd_id] = {}
		for k, v in pairs(t_node.skill_list) do
			local id = k%100
			skill_passive_name[k] = v.name
			skill_passive_param[cmd_id][id] = {}
			--1根骨 2悟性 3体魄 4身法 5闪避率 6暴击率 7暴击效果 8命中率 9冰攻 10雷攻 11毒攻 12冰抗 13雷抗 14毒抗 15物理减伤 16魔法减伤 17加血 18冰伤强化 19毒伤强化 20雷伤强化 21复仇
			skill_passive_param[cmd_id][id][1] = v.strengh or 0
			skill_passive_param[cmd_id][id][2] = v.intelligence or 0
			skill_passive_param[cmd_id][id][3] = v.stemina or 0
			skill_passive_param[cmd_id][id][4] = v.dexterity or 0
			skill_passive_param[cmd_id][id][5] = v.dodge or 0
			skill_passive_param[cmd_id][id][6] = v.critical or 0
			skill_passive_param[cmd_id][id][7] = v.critical_ef or 0
			skill_passive_param[cmd_id][id][8] = v.point or 0
			skill_passive_param[cmd_id][id][9] = v.ice_attack or 0
			skill_passive_param[cmd_id][id][10] = v.fire_attack or 0
			skill_passive_param[cmd_id][id][11] = v.poison_attack or 0
			skill_passive_param[cmd_id][id][12] = v.ice_defense or 0
			skill_passive_param[cmd_id][id][13] = v.fire_defense or 0
			skill_passive_param[cmd_id][id][14] = v.poison_defense or 0
			skill_passive_param[cmd_id][id][15] = v.physical_rd or 0
			skill_passive_param[cmd_id][id][16] = v.magic_rd or 0
			skill_passive_param[cmd_id][id][17] = v.hp or 0
			skill_passive_param[cmd_id][id][18] = v.ice_addition or 0
			skill_passive_param[cmd_id][id][19] = v.poison_addition or 0
			skill_passive_param[cmd_id][id][20] = v.fire_addition or 0
			skill_passive_param[cmd_id][id][21] = v.sub_hp or 0
			skill_passive_param[cmd_id][id][22] = v.s_defense or 0
			skill_passive_param[cmd_id][id][23] = v.m_defense or 0
		end
	elseif 2 == type then							--转移技能
		
		local cmd_id = t_node.skill_tags

		skill_transfer_param[cmd_id] = {}
		skill_transfer_param_ratio[cmd_id] = {}
		for k, v in pairs(t_node.skill_list) do
			local id = k
			skill_transfer_name[k] = v.name
			--1,物最小攻击，2物最大攻击，3物防，4魔最小攻击，5魔最大攻击，6魔防，
			--7冰攻，8冰防，9火攻，10，火防，11毒攻，12毒防，
			--13暴击，14暴击效率，15命中，16闪避
			--17根骨，18悟性，19体魄，20身法 21生命 22法力 23速度,
			--24暴击率,25命中率,26闪避率,27生命上限率,28法力上限率
			skill_transfer_param[cmd_id][id] = {}
			skill_transfer_param[cmd_id][id] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
			skill_transfer_param[cmd_id][id][17] =v.strengh or 0
			skill_transfer_param[cmd_id][id][18] =v.intelligence or 0
			skill_transfer_param[cmd_id][id][19] =v.stemina or 0
			skill_transfer_param[cmd_id][id][20] =v.dexterity or 0

			skill_transfer_param_ratio[cmd_id][id] = {}
			skill_transfer_param_ratio[cmd_id][id] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
			skill_transfer_param_ratio[cmd_id][id][17] =v.strengh_ratio or 0
			skill_transfer_param_ratio[cmd_id][id][18] =v.intelligence_ratio or 0
			skill_transfer_param_ratio[cmd_id][id][19] =v.stemina_ratio or 0
			skill_transfer_param_ratio[cmd_id][id][20] =v.dexterity_ratio or 0
		end

	elseif 3 == type then							--增加人物宠物技能
	end

end

--启动物品加载
init()

