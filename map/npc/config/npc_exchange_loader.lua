local debug_print = function() end

local lom = require("lom")
module("npc.config.npc_exchange_loader", package.seeall)

NpcExchage = {}


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
		if xml_tree.tag == "Exchange" then
			local item_str = "Exchange"
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

					if type(xml_node.tag) == "string" and xml_node.tag == "coll_item_list" then
						t_node[xml_node.tag] = {}
						local count = 1
						for k,v in pairs(xml_node) do
							if v.tag == "item" then
								t_node[xml_node.tag][count] = {}
								for m,n in pairs(v.attr) do
									if type(m) == "string" and m == "id" then
										t_node[xml_node.tag][count] = t_node[xml_node.tag][count] or {}
										t_node[xml_node.tag][count].item_id = tonumber(n)
										t_node[xml_node.tag][count].count = tonumber(v[1])
									elseif type(m) == "string" and m == "name" then
										t_node[xml_node.tag][count] = t_node[xml_node.tag][count] or {}
										t_node[xml_node.tag][count].name = tostring(n)
									end
								end
								count = count + 1
							end
						end
					elseif type(xml_node.tag) == "string" and xml_node.tag == "coll_money_list" then
						t_node[xml_node.tag] = {}
						for k,v in pairs(xml_node) do
							if v.tag then
								t_node[xml_node.tag][v.tag] = tonumber(v[1])
							end
						end
					elseif type(xml_node.tag) == "string" and xml_node.tag == "exc_item_list" then
						t_node[xml_node.tag] = {}
						local count = 1
						for k,v in pairs(xml_node) do
							if v.tag == "item" then
								t_node[xml_node.tag][count] = {}
								for m,n in pairs(v.attr) do
									if type(m) == "string" and m == "id" then
										t_node[xml_node.tag][count] = t_node[xml_node.tag][count] or {}
										t_node[xml_node.tag][count].item_id = tonumber(n)
										t_node[xml_node.tag][count].count = tonumber(v[1])
									elseif type(m) == "string" and m == "expire_time" then
										t_node[xml_node.tag][count] = t_node[xml_node.tag][count] or {}
										t_node[xml_node.tag][count].expire_time = tonumber(n)
									elseif type(m) == "string" and m == "name" then
										t_node[xml_node.tag][count] = t_node[xml_node.tag][count] or {}
										t_node[xml_node.tag][count].name = tostring(n)
									end
								end
								count = count + 1
							end
						end
					elseif type(xml_node.tag) == "string" and xml_node.tag == "exc_money_list" then
						t_node[xml_node.tag] = {}
						for k,v in pairs(xml_node) do
							if v.tag then
								t_node[xml_node.tag][v.tag] = tonumber(v[1])
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
			HandleNpcExchange(t_node)
		else
			for k,xml_node in pairs(xml_tree) do
				HandleXmlTree(xml_node)
			end
		end
	end
end


--******************创建兑换npc***************

function HandleNpcExchange(t_node)
	local exc_id = t_node.id

	local NpcExchageTemplate = oo.class(nil, "NpcExchageTemplate_" .. tostring(exc_id))
	function NpcExchageTemplate:__init()
		self.id = t_node.id
		self.flag = t_node.flag
		self.name = t_node.name
		self.broadcast = t_node.broadcast
		self.one_rank = tonumber(t_node.one_rank)
		self.three_rank = tonumber(t_node.three_rank)

		self.coll_item_list = t_node.coll_item_list or {}
		self.coll_money_list = t_node.coll_money_list or {}
		self.exc_item_list = t_node.exc_item_list or {}
		self.exc_money_list = t_node.exc_money_list or {}
	end

	NpcExchage[exc_id] = NpcExchageTemplate()
end


HandleXmlFile(CONFIG_DIR .. "xml/npc_function/" .. "npc_exchange.xml")


