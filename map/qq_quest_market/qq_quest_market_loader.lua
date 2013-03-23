
--QQ任务集市
local lom = require("lom")
module("qq_quest_market.qq_quest_market_loader", package.seeall)

local basic = {
	["id"] = true;
	["level"] = true;
	["type"]  = true;
}
local complex = {
	["kill_monster"] = true;
	["ent_scene"] = true;
}

local qq_quest_market_list ={}

function init()
	HandleXmlFile(CONFIG_DIR .. "xml/npc_function/qq_quest_market.xml")
end

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
		print("HandleXmlFile error:",err)
		return 
	end
	local ret = HandleXmlTree(xml_tree)
end

function HandleXmlTree(xml_tree)
	if not xml_tree then
		print("qq quest market HandleXmlTree tree is nil return")
		return
	end

	if xml_tree.tag and xml_tree.tag == "qq_quest_market" then
		for _,attr_tree in pairs(xml_tree) do
			if attr_tree.tag == "Quest" then
				qq_quest_market_list[attr_tree.attr.id] = {}
				for i,v in pairs(attr_tree) do
					if basic[v.tag] then
						qq_quest_market_list[attr_tree.attr.id][v.tag] = tonumber(v[1])
					elseif complex[v.tag] then
						qq_quest_market_list[attr_tree.attr.id][v.tag] = {}
						build_postcondition(v, qq_quest_market_list[attr_tree.attr.id][v.tag])
					end
				end
			end			
		end
	end
end

function build_postcondition(data, info)
	for i,v in pairs(data) do
		if v.tag == "item" then
			info[tonumber(v.attr.id)] = tonumber(v[1])
		elseif v.tag == "scene" then
			info[tonumber(v.attr.id)] = tonumber(v[1])
		end
	end
end

function get_quest(quest_id)
	return qq_quest_market_list[quest_id] 
end

function get_type_quest(quest_id)
	return qq_quest_market_list[quest_id].type or 0
end

function get_level_quest(quest_id)
	return qq_quest_market_list[quest_id].level or 1
end

init()
