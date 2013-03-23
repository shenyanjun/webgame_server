
local debug_print = function() end
local lom = require("lom")

module("skill.passive_skill.pet.pet_trigger_skill_loader", package.seeall)

--攻击触发技能
skill_trigger_config = {}


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
		return
	end

	for _, node in pairs(xml_tree) do
		if "Pet_trigger_skill" == node.tag then
			local skill_type = tonumber(node.attr["skill_tags"])
			local trigger_type = tonumber(node.attr["trigger_type"])
			--print("---->", skill_type, trigger_type)
			skill_trigger_config[skill_type] = parse_skill_info(node, trigger_type)
		end
	end

end

function parse_skill_info(node, trigger_type)
	local skill_info = {}
	for _, child in pairs(node) do
		if "skill_info" == child.tag then
			local skill_level = tonumber(child.attr["level"])
			skill_info[skill_level] = {["name"]=child.attr["name"], ["cd"]=tonumber(child.attr["cd"]), ["duration"]=tonumber(child.attr["duration"]), 
										["protect"]=tonumber(child.attr["protect"]), ["pro"]=tonumber(child.attr["pro"]), ["trigger_type"]=trigger_type}
			--print("=====", skill_level, j_e(skill_info[skill_level]))
		end
	end
	return skill_info
end


HandleXmlFile(CONFIG_DIR .. "xml/pet/pet_trigger_skill.xml")