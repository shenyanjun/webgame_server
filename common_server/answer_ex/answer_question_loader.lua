local debug_print = function() end
local lom = require("lom")

module("answer_ex.answer_question_loader", package.seeall)

question_config = {}

function load_file(path)
	local file_handle = io.open(path)
	if not file_handle then
		debug_print("str_file can't open the xml file, file name=", path)
		return nil
	end
	
	local file_data = file_handle:read("*a")
	file_handle:close()
	
	local xml_tree, err = lom.parse(file_data)
	if err then
		debug_print("str_file error:",err)
		return nil
	end
	
	return xml_tree
end


function parse_config(path)
	local xml_tree = load_file(path)
	if not xml_tree then
		return {}
	end
	local question = {}
	for _, child in pairs(xml_tree) do
		if "type" == child.tag then
			local number = tonumber(child.attr["number"])
			local type = tonumber(child.attr["id"])
			question[type] = {["number"] = number, ["topic"] = nil, ["count"] = nil}
			question[type].topic, question[type].count = parse_question(child)
		end
	end

	return question
end


function parse_question(node)
	local data = {}
	local count = 0
	for _, child in pairs(node) do
		if "question" == child.tag then
			local question_id = tonumber(child.attr["id"])
			local answer_id = nil
			for _, v in pairs(child) do
				if "answer" == v.tag then
					answer_id = tonumber(v.attr["id"])
				end
			end
			count = count + 1
			table.insert(data, {["question"] = question_id, ["answer"] = answer_id})
		end
	end
	return data, count
end


question_config = parse_config(CONFIG_DIR .. "/xml/answer_ex/question.xml")

--print("%%%%%%%%%%%%%%question", j_e(question_config))
