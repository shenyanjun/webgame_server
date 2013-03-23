local debug_print = function() end

--require("global")
local lom = require("lom")
local action_loader = require("npc.config.action_loader")
local misson_loader = require("mission_ex.mission_loader")
local scene_loader = require("npc.config.scene_loader")

module("npc.config.npc_loader", package.seeall)

NpcTable = {}

--[[local NpcFactory = oo.class(nil, "NpcFactory")

function NpcFactory:__init()
	self.scene = {}
	self.action_list = {}
	self.start_quest_list = {}
	self.end_quest_list = {}
end]]


function HandleXmlFile(str_file)
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
		print("NpcLoader HandleXmlTree tree is nil return")
		return 1
	end
	if xml_tree.tag then
		if xml_tree.tag == "Npc" then
			local item_str = "Npc "
			local t_node = {}
			for attr_name, attr_value in pairs(xml_tree.attr) do
				t_node[attr_name] = attr_value
				if type(attr_name) == "string" then
					item_str = item_str..attr_name.." = "..attr_value.." "
				end
			end
			for i, xml_node in pairs(xml_tree) do
				if type(xml_node.tag) == "string" then
					local node_value = xml_node[1]
					if type(xml_node.tag) == "string" and xml_node.tag == "action_list" then
						t_node[xml_node.tag] = {}
						local count = 1
						for k,v in pairs(xml_node) do
							if v.tag then
								t_node[xml_node.tag][count] = v[1]
								count = count + 1
							end
						end
					elseif type(xml_node.tag) == "string" and xml_node.tag == "start_quest_list" then
						t_node[xml_node.tag] = {}
						local count = 1
						for k,v in pairs(xml_node) do
							if v.tag then
								t_node[xml_node.tag][count] = v[1]
								count = count + 1
							end
						end
					elseif type(xml_node.tag) == "string" and xml_node.tag == "end_quest_list" then
						t_node[xml_node.tag] = {}
						local count = 1
						for k,v in pairs(xml_node) do
							if v.tag then
								t_node[xml_node.tag][count] = v[1]
								count = count + 1
							end
						end
					else
						t_node[xml_node.tag] = tonumber(node_value)
					end

					for node_attr, node_attr_value in pairs(xml_node.attr) do
						if type(node_attr) == "string" then
							if node_attr == "type" and node_attr_value == "string" then
								t_node[xml_node.tag] = xml_node[1]
							end
						end
					end
				end
			end
			HandleCreateNpc(t_node)
		else
			for k,xml_node in pairs(xml_tree) do
				HandleXmlTree(xml_node)
			end
		end
	end
end



--*************创建npc****************
function HandleCreateNpc(t_node)
	local npc_id = tonumber(t_node.id)

	local NpcTemplate = oo.class(nil, "NpcFactory_" .. tostring(npc_id))
	function NpcTemplate:__init()
		self.scene = {}
		--self.action_list = {}
		self.start_quest_list = {}
		self.end_quest_list = {}
		self.npc_action_list = {}

		self:InitScene()
		self.named = t_node.name

		--功能列表
		if t_node.action_list then
			for k,v in pairs(t_node.action_list) do
				self.npc_action_list[k] = v
			end
		end

		--开始任务列表
		if t_node.start_quest_list then
			for _,v in pairs(t_node.start_quest_list) do
				local meta = misson_loader.get_meta(v)
				if not meta then
					local err_msg = string.format(
						"Error: Npc %s start_quest_list quest id %s Not Exists!"
						, tostring(t_node.id or "nil")
						, tostring(v or "nil"))
		    		g_mission_log:write(err_msg)
		    		print(err_msg)
				end
				self.start_quest_list[v] = {}
				self.start_quest_list[v]["id"] = meta.id
				self.start_quest_list[v]["name"] = meta.name
			end
		end

		--结束任务列表
		if t_node.end_quest_list then
			for _, v in pairs(t_node.end_quest_list) do
				local meta = misson_loader.get_meta(v)
				if not meta then
					local err_msg = string.format(
						"Error: Npc %s end_quest_list quest id %s Not Exists!"
						, tostring(t_node.id or "nil")
						, tostring(v or "nil"))
		    		g_mission_log:write(err_msg)
		    		print(err_msg)
				end
				self.end_quest_list[v] = {}
				self.end_quest_list[v]["id"] = meta.id
				self.end_quest_list[v]["name"] = meta.name
			end
		end
	end

	function NpcTemplate:GetActionById(action_id)
		--return self.action_list[action_id]
		return action_loader.ActionTable[action_id]
	end

	function NpcTemplate:get_action_list()
		return self.npc_action_list
	end

	function NpcTemplate:GetStartQuestById(quest_id)
		return self.start_quest_list[quest_id]
	end

	function NpcTemplate:GetEndQuestById(quest_id)
		return self.end_quest_list[quest_id]
	end

	--此为NPC加载器的虚函数，在场景加载器里会对此函数进行重载
	function NpcTemplate:InitScene()
		local s_id, scene_l = scene_loader.get_scene_info(npc_id)
		if s_id ~= nil then
			self.scene[s_id] = scene_l
		end
	end

	--判断NPC与玩家的位置
	function NpcTemplate:CanContactWithPlayer(player)
		local map_id = player:get_map_id()
		local pos = player:get_pos()

		return true--map_id == next(self.scene)
	end

	NpcTable[npc_id] = NpcTemplate()
end


HandleXmlFile(CONFIG_DIR .. "xml/npc_function/" .. "npc.xml")