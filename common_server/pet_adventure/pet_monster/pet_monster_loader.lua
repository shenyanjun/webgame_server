local debug_print = function() end
local lom = require("lom")

module("pet_adventure.pet_monster.pet_monster_loader", package.seeall)

_pet_info = {}				--基本信息
_pet_base = {}				--基本系数
_pet_base_skill = {}			--先天技能
_pet_acquired_skill = {}		--后天技能
_pet_foundation = {}			--四大基础属性
--_pet_skill_number = {}		--后天随机技能数量
--_pet_grouth = {}				--成长率的权值
--_pet_default_value = {}		--默认得不到技能的权值
--_monster_to_occ = {}			--怪物职业对应宠物职业

function init()
	HandleXmlFile(CONFIG_DIR .. "xml/pet/pet_adventure/pet_monster.xml")
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
		if xml_tree.tag == "Pet" then
			local item_str = "Pet "
			local t_node = {}
			for attr_name, attr_value in pairs(xml_tree.attr) do
				if type(attr_name) == "string" and attr_name == "monster_id" then
					t_node[attr_name] = tonumber(attr_value)
				elseif type(attr_name) == "string" and attr_name == "occ" then
					t_node[attr_name] = tonumber(attr_value)
				elseif type(attr_name) == "string" then
					t_node[attr_name] = attr_value
				end
			end
			for i, xml_node in pairs(xml_tree) do
				if type(xml_node.tag) == "string" and xml_node.tag == "Basic_attribute_list" then
					t_node[xml_node.tag] = {}
					for k,v in pairs(xml_node) do
						if v.tag then
							t_node[xml_node.tag][v.tag] = tonumber(v[1])
						end
					end
				elseif type(xml_node.tag) == "string" and xml_node.tag == "Basic_coefficient_list" then
					t_node[xml_node.tag] = {}
					for k,v in pairs(xml_node) do
						if v.tag then
							t_node[xml_node.tag][v.tag] = tonumber(v[1])
						end
					end
				elseif type(xml_node.tag) == "string" and xml_node.tag == "Base_skill_list" then
					t_node[xml_node.tag] = {}
					local item_count = 1
					for k,v in pairs(xml_node) do
						if v.tag then
							t_node[xml_node.tag][item_count] = tonumber(v[1])
							item_count = item_count + 1
						end
					end
				elseif type(xml_node.tag) == "string" and xml_node.tag == "other_skill_list" then
					t_node[xml_node.tag] = {}
					local count = 1
					for node_attr,node_attr_value in pairs(xml_node) do
						if node_attr_value.value then
							t_node.default_value = tonumber(node_attr_value.value)
						elseif node_attr_value.attr then
							t_node[xml_node.tag][count] = {}
							for k,v in pairs(node_attr_value.attr) do
								t_node[xml_node.tag][count][k] = tonumber(v)
							end
							count = count + 1
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

function HandleEmbed(t_node)
	--print(j_e(t_node))
	--基本信息
	_pet_info[t_node.occ] = {}
	_pet_info[t_node.occ][1] = t_node.level or 0
	_pet_info[t_node.occ][2] = t_node.name or 0
	_pet_info[t_node.occ][3] = t_node.occ or 0
	_pet_info[t_node.occ][4] = t_node.pullulate or 0
	_pet_info[t_node.occ][5] = t_node.monster_id or 0

	--print("xml _pet_info:", _pet_info[t_node.id][1], _pet_info[t_node.id][2], _pet_info[t_node.id][3], type(_pet_info[t_node.id][2]))
	--基本系数
	_pet_base[t_node.occ] = {}
	--_pet_base[t_node.id] = t_node.Basic_coefficient_list
	--1hp生命 2mp法力 3s_attack物理攻击 4m_attack法术攻击 5s_defense物理防御 6m_defense法术防御 7critical暴击率 8dodge闪避率
	--9point命中率 10critical_ef暴击效果 11ice_attack冰攻 12fire_attack雷攻 13poison_attack毒攻 14ice_defense冰抗
	--15poison_defence毒抗 16fire_defense雷抗
	_pet_base[t_node.occ][1] = t_node.Basic_coefficient_list.hp or 0
	_pet_base[t_node.occ][2] = t_node.Basic_coefficient_list.mp or 0
	_pet_base[t_node.occ][3] = t_node.Basic_coefficient_list.s_attack or 0
	_pet_base[t_node.occ][4] = t_node.Basic_coefficient_list.m_attack or 0
	_pet_base[t_node.occ][5] = t_node.Basic_coefficient_list.s_defense or 0
	_pet_base[t_node.occ][6] = t_node.Basic_coefficient_list.m_defense or 0
	_pet_base[t_node.occ][7] = t_node.Basic_coefficient_list.critical or 0
	_pet_base[t_node.occ][8] = t_node.Basic_coefficient_list.dodge or 0
	_pet_base[t_node.occ][9] = t_node.Basic_coefficient_list.point or 0
	_pet_base[t_node.occ][10] = t_node.Basic_coefficient_list.critical_ef or 0
	_pet_base[t_node.occ][11] = t_node.Basic_coefficient_list.ice_attack or 0
	_pet_base[t_node.occ][12] = t_node.Basic_coefficient_list.fire_attack or 0
	_pet_base[t_node.occ][13] = t_node.Basic_coefficient_list.poison_attack or 0
	_pet_base[t_node.occ][14] = t_node.Basic_coefficient_list.ice_defense or 0
	_pet_base[t_node.occ][15] = t_node.Basic_coefficient_list.poison_defence or 0
	_pet_base[t_node.occ][16] = t_node.Basic_coefficient_list.fire_defense or 0
--	print("_pet_base:", j_e(_pet_base[t_node.occ]))

	--天生技能
	_pet_base_skill[t_node.occ] = {}
	--_pet_base_skill[t_node.occ] = t_node.Base_skill_list
	for k,v in pairs(t_node.Base_skill_list) do
		_pet_base_skill[t_node.occ][k] = t_node.Base_skill_list[k]
	end
	--print("_pet_base_skill:", j_e(_pet_base_skill[t_node.occ]))


	--四大基础属性
	_pet_foundation[t_node.occ] = {}
	--_pet_foundation[t_node.id] = t_node.Basic_attribute_list
	--根骨最小值strengh intelligence悟性最小值 stemina体魄最小值 dexterity身法最小值
	_pet_foundation[t_node.occ][1] = t_node.Basic_attribute_list.strengh or 0
	_pet_foundation[t_node.occ][2] = t_node.Basic_attribute_list.intelligence or 0
	_pet_foundation[t_node.occ][3] = t_node.Basic_attribute_list.stemina or 0
	_pet_foundation[t_node.occ][4] = t_node.Basic_attribute_list.dexterity or 0

	--后天技能
	--_pet_acquired_skill[t_node.id] = {}
	--_pet_acquired_skill[t_node.occ] = t_node.other_skill_list
	local count = 0
	_pet_acquired_skill[t_node.occ] = {}
	for k,v in pairs(t_node.other_skill_list or {}) do
		count = count + 1
		_pet_acquired_skill[t_node.occ][count] = v
	end

end

--启动物品加载
init()

