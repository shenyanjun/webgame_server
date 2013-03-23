
local debug_print = function() end
local lom = require("lom")
module("npc.config.unlock_loader",package.seeall)

UnlockTable = {}
SpecUnlock = {}

function init()
	local filename = CONFIG_DIR .. "xml/casting/equip_unlock.xml"
	local filename1 = CONFIG_DIR .. "xml/casting/special_unlock.xml"
	HandleXmlFile(filename, 1)
	HandleXmlFile(filename1, 2)
end

--从XML文件中读取数据
function HandleXmlFile(str_file, type)
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
	if type == 1 then
		local ret = HandleXmlTree(xml_tree)
	elseif type == 2 then
		local ret = HandleXmlTreeTwo(xml_tree)
	end
end


function HandleXmlTree(xml_tree)
	if not xml_tree then
		debug_print("HandleXmlTree tree is nil return")
		return 1
	end

	for k,xml_node in pairs(xml_tree) do
		if xml_node.tag == "equip" then
			UnlockTable[tonumber(xml_node.attr.id)] = {}
			UnlockTable[tonumber(xml_node.attr.id)].des_id = tonumber(xml_node.attr.des_id)
			UnlockTable[tonumber(xml_node.attr.id)].money = tonumber(xml_node.attr.money)
			UnlockTable[tonumber(xml_node.attr.id)].item_list = {}
			local count = 1
			for k,v in pairs(xml_node) do
				if v.tag then
					for attr_name,attr_value in pairs(v.attr or {}) do
						if type(attr_name) == "string" then
							UnlockTable[tonumber(xml_node.attr.id)].item_list[count] = {}
							UnlockTable[tonumber(xml_node.attr.id)].item_list[count][attr_name] = tonumber(attr_value)
						end
					end
					count = count+1
				end 
			end
		end
	end
end


function HandleXmlTreeTwo(xml_tree)
	if not xml_tree then
		debug_print("HandleXmlTreeTwo tree is nil return")
		return 1
	end

	for k,xml_node in pairs(xml_tree) do
		if xml_node.tag == "equip" then
			local tmp_node = {}
			tmp_node.id 		= tonumber(xml_node.attr.id)
			tmp_node.des_id 	= tonumber(xml_node.attr.des_id)
			tmp_node.money 		= tonumber(xml_node.attr.money)
			tmp_node.item_list 	= {}

			for k,v in pairs(xml_node) do
				if v.tag then
					for attr_name,attr_value in pairs(v.attr or {}) do
						if type(attr_name) == "string" and attr_name == "material_id" then
							local id = tonumber(attr_value)
							if not SpecUnlock[id] then
								SpecUnlock[id] = {}
							end
							SpecUnlock[id][tmp_node.id] = {}
							SpecUnlock[id][tmp_node.id].des_id = tmp_node.des_id
							SpecUnlock[id][tmp_node.id].money  = tmp_node.money
						end
					end
				end 
			end

		end
	end
end

init()
--for k, v in pairs(SpecUnlock) do
	--print("\n105 =", k)
	--for kk, vv in pairs(v) do
		--print("107 =", kk, j_e(vv))
	--end
--end