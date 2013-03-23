local debug_print = function() end
local lom = require("lom")
--local npc_loader = require("npc.config.npc_loader")

module("npc.config.scene_loader", package.seeall)

SceneTable = {}

--XML数据结构分析
function HandleXmlFile(str_file)
	debug_print("HandleXmlFile str_file=", str_file)
	local file_handle = io.open(str_file)
	if not file_handle then
		print("HandleXmlFile can't open the xml file, file name=", str_file)
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

function HandleXmlTree(xml_tree)
	if not xml_tree then
		print("ScenceLoader HandleXmlTree tree is nil return")
		return 1
	end
	if xml_tree.tag then
		if xml_tree.tag == "Scene" then
			local item_str = "Scene "
			local t_node = {}
			for attr_name, attr_value in pairs(xml_tree.attr) do
				if attr_name == "id" then
					t_node[attr_name] = tonumber(attr_value)
				else
					t_node[attr_name] = attr_value
				end
			end
			t_node.npc_list = {}
			--local npc_count = 1
			for i, xml_node in pairs(xml_tree) do
				if type(xml_node.tag) == "string" and xml_node.tag == "npc" then
					local id = tonumber(xml_node.attr.id)
					t_node.npc_list[id] = {}
					for node_attr, node_attr_value in pairs(xml_node.attr) do
						t_node.npc_list[id][node_attr] = tonumber(node_attr_value)
					end
				--	npc_count = npc_count + 1
				end
			end
			HandleCreateScene(t_node)
		else
			for k,xml_node in pairs(xml_tree) do
				HandleXmlTree(xml_node)
			end
		end
	end
end



--************创建静态场景***********

function HandleCreateScene(t_node)
	SceneTable[t_node.id] = t_node

	--[[for k,v in pairs(t_node.npc_list) do
		if not v.id or not npc_loader.NpcTable[v.id] then
			local err_msg = string.format(
				"Error: Scene %s Npc %s Not Exists!"
				, tostring(t_node.id or "nil")
				, tostring(v.id or "nil"))

			g_mission_log:write(err_msg)
			print(err_msg)
		end

		local t_InitScene = npc_loader.NpcTable[v.id].InitScene
		npc_loader.NpcTable[v.id].InitScene = function(self)
			debug_print("NpcTable[v.id].InitScene", v.id)
			if t_InitScene then
				t_InitScene(self)
			end
			self.scene[t_node.id] = {}
			self.scene[t_node.id].pos_list = {}
			self.scene[t_node.id].pos_list[1] = {}
			self.scene[t_node.id].pos_list[1].pos_x = v.pos_x
			self.scene[t_node.id].pos_list[1].pos_y = v.pos_y
			self.scene[t_node.id].pos_list[1].color = v.color
		end
	end]]
end

function get_scene_info(npc_id)
	for s_id,list in pairs(SceneTable) do
		if list.npc_list[npc_id] ~= nil then
			local scene_l = {}
			scene_l.pos_list = {}
			scene_l.pos_list[1] = {}
			scene_l.pos_list[1].pos_x = list.npc_list[npc_id].pos_x
			scene_l.pos_list[1].pos_y = list.npc_list[npc_id].pos_y
			scene_l.pos_list[1].color = list.npc_list[npc_id].color

			return s_id, scene_l
		end
	end
end

function get_npc_info(scene_id, npc_id)
	return SceneTable[scene_id] and SceneTable[scene_id][npc_id]
end



HandleXmlFile(CONFIG_DIR .. "xml/npc_function/" .. "scene.xml")