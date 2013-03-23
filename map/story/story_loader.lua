local lom = require("lom")

module("story.story_loader", package.seeall)

config = {}

function parse_chapter(node)
	local chapter = {
		id = node.attr["id"]
		, name = node.attr["name"]
		, precondition = {}
		, postcondition = {}
		, reward = {}}
	for _, child in pairs(node) do
		if "Precondition" == child.tag then
			chapter.precondition.level = tonumber(child.attr["level"])
		elseif "Postcondition" == child.tag then
			chapter.postcondition.map_id = tonumber(child.attr["map_id"])
		elseif "Reward" == child.tag then
			for _, item in pairs(child) do
				if "Item" == item.tag then
					table.insert(chapter.reward, {id = tonumber(item.attr["id"]), number = tonumber(item.attr["number"])})
				end
			end
		end
	end

	return chapter
end

function parse_config(str_file)
	local file_handle = io.open(str_file)
	if not file_handle then
		debug_print("str_file can't open the xml file, file name=", str_file)
		return false
	end
	
	local file_data = file_handle:read("*a")
	file_handle:close()
	
	local xml_tree, err = lom.parse(file_data)
	if err then
		debug_print("str_file error:",err)
		return false
	end
	
	for _, node in pairs(xml_tree) do
		if "Chapter" == node.tag then
			--local id = node.attr["id"] 
			--config[id] = parse_chapter(node)
			table.insert(config, parse_chapter(node))
		end
	end
	
	return true
end

parse_config(CONFIG_DIR .. "xml/story/chapter.xml")