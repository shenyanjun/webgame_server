local debug_print = function() end

local lom = require("lom")
module("npc.config.action_loader", package.seeall)

ActionTable = {}

--[[local ActionFactory = oo.class(nil, "ActionFactory")
function ActionFactory:__init()
end]]


--XML数据结构分析
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

function HandleXmlTree(xml_tree)
	if not xml_tree then
		debug_print("HandleXmlTree tree is nil return")
		return 1
	end
	if xml_tree.tag then
		if xml_tree.tag == "Action" then
			local item_str = "Action "
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
					if type(xml_node.tag) == "string" and xml_node.tag == "item_list" then
						t_node[xml_node.tag] = {}
						local count = 1
						for k,v in pairs(xml_node) do
							if v.tag then
								--local t_attr = {}
								t_node[xml_node.tag][count] = {}
								for attr_name, attr_value in pairs(v.attr) do
									if type(attr_name) == "string" then
										t_node[xml_node.tag][count][attr_name] = tonumber(attr_value)
										--t_attr[attr_name] = attr_value
									end
								end
								t_node[xml_node.tag][count].price = tonumber(v[1])
								count = count + 1
							end
						end

					elseif type(xml_node.tag) == "string" and xml_node.tag == "skill_list" then
						t_node[xml_node.tag] = {}
						local count = 1
						for k,v in pairs(xml_node) do
							if v.tag then
								--local t_attr = {}
								t_node[xml_node.tag][count] = {}
								for attr_name, attr_value in pairs(v.attr) do
									if type(attr_name) == "string" then
										t_node[xml_node.tag][count][attr_name] = tonumber(attr_value)
										--t_attr[attr_name] = attr_value
									end
								end
								t_node[xml_node.tag][count].max_level = tonumber(v[1])
								count = count + 1
							end
						end
					elseif type(xml_node.tag) == "string" and xml_node.tag == "transfer_list" then
						t_node[xml_node.tag] = {}
						local count = 1
						for k,v in pairs(xml_node) do
							if v.tag then
								--local t_attr = {}
								t_node[xml_node.tag][count] = {}
								for attr_name, attr_value in pairs(v.attr) do
									if type(attr_name) == "string" and attr_name == "name" then
										t_node[xml_node.tag][count][attr_name] = (attr_value)
										--t_attr[attr_name] = attr_value
									elseif type(attr_name) == "string" then
										t_node[xml_node.tag][count][attr_name] = tonumber(attr_value)
									end
								end
								t_node[xml_node.tag][count].taxi = tonumber(v[1])
								count = count + 1
							end
						end
					elseif type(xml_node.tag) == "string" and xml_node.tag == "exchange_list" then
						t_node[xml_node.tag] = {}
						local count = 1
						for k,v in pairs(xml_node) do
							if v.tag then
								t_node[xml_node.tag][count] = {}
								local ncount = 1
								for m,n in pairs(v) do
									if type(n.tag) == "string" and n.tag == "exc" then
										t_node[xml_node.tag][count][ncount] = n[1]
										ncount = ncount + 1
									end
								end

								for attr_name, attr_value in pairs(v.attr) do
									if type(attr_name) == "string" then
										t_node[xml_node.tag][count][attr_name] = tostring(attr_value)
									end
								end
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
			HandleCreateAction(t_node)
		else
			for k,xml_node in pairs(xml_tree) do
				HandleXmlTree(xml_node)
			end
		end
	end
end


--***************创建action对象**************
function HandleCreateAction(t_node)
	--[[local action_id = t_node.id
	local ActionTemplate = oo.class(ActionFactory, "ActionFactory_" .. tostring(action_id))
	function ActionTemplate:__init()
		ActionFactory.__init(self)
		self.id = t_node.id
		self.type = t_node.type
		self.repair = t_node.repair
		self.sell = t_node.sell
		self.random_count = t_node.random_count
		self.item_list = table.duplicate(t_node.item_list)
		self.skill_list = table.duplicate(t_node.skill_list)
		if t_node.transfer_list then
			self.transfer_list = {}
			for k,v in pairs(t_node.transfer_list) do
				self.transfer_list[v.id] = {}
				self.transfer_list[v.id] = v
			end
		end
		self.exchange_list = table.duplicate(t_node.exchange_list) or {}
		self.name = t_node.name
	end

	ActionTable[action_id] = ActionTemplate]]

	local action_id = t_node.id

	local action_l = {}
	action_l.id = t_node.id
	action_l.type = t_node.type
	action_l.repair = t_node.repair
	action_l.sell = t_node.sell
	action_l.random_count = t_node.random_count
	action_l.item_list = table.duplicate(t_node.item_list)
	action_l.skill_list = table.duplicate(t_node.skill_list)

	if t_node.transfer_list then
		action_l.transfer_list = {}
		for k,v in pairs(t_node.transfer_list) do
			action_l.transfer_list[v.id] = {}
			action_l.transfer_list[v.id] = v
		end
	end
	action_l.exchange_list = table.duplicate(t_node.exchange_list) or {}
	action_l.name = t_node.name

	ActionTable[action_id] = action_l
end


--启动NPC功能加载
--HandleXmlFile(XML_NPC_FILE_PATH .."action.xml")
HandleXmlFile(CONFIG_DIR .. "xml/npc_function/" .."action.xml")

