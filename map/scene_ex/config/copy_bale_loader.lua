
local debug_print = function() end
local lom = require("lom")
local _scene = require("config.scene_config")
require("global")
require("global_function")

module("scene_ex.config.copy_bale_loader", package.seeall)

config_list = create_local("scene_ex.config.copy_bale_loader.config_list", {})

function parse_xml(id)
	local name = CONFIG_DIR .. "xml/scene_copy/scene_copy_" .. id .. ".xml"
	local file_handle = io.open(name)
	if not file_handle then
		debug_print("Can't open the xml file, file name:", name)
		return 
	end

	local file_data = file_handle:read("*a")
	file_handle:close()

	--判断文件是否修改
	if is_change_config_md5(name, file_data) then
		local xml_tree,err = lom.parse(file_data)
		if err then
			print(name .. " error:",err)
			return 
		end
		handle_xml(xml_tree, id)
	end
end

function handle_xml(xml_tree, id)
	if xml_tree == nil then return end

	if xml_tree.tag then
		if xml_tree.tag == "Item" and tonumber(xml_tree.attr.scene_id) == id then
			--local request_l = {}
			config_list.value[id] = {}
			local request_l = config_list.value[id]
			request_l.copy_l = {}

			for k,node in pairs(xml_tree) do
				if node.tag == "class" then
					request_l["class"] = tonumber(node.attr.type)
				elseif node.tag == "prop_need" then
					request_l["prop"] = {}
					local count = 1
					for i, xml_node in pairs(node) do
						if xml_node.tag == "prop" then
							local t = {}
							t.item_id = tonumber(xml_node.attr.id)
							t.number = tonumber(xml_node.attr.number)
							request_l["prop"][count] = t
							count = count + 1
						end
					end
				elseif node.tag == "level" then
					request_l["level"] = {}
					request_l["level"][1] = tonumber(node.attr.min)
					request_l["level"][2] = tonumber(node.attr.max)
				elseif node.tag == "human" then
					request_l["human"] = {}
					request_l["human"][1] = tonumber(node.attr.min)
					request_l["human"][2] = tonumber(node.attr.max)
				elseif node.tag == "cycle" then
					request_l["cycle"] = tonumber(node.attr.number)
				elseif node.tag == "collectivity" then
					request_l["collectivity"] = tonumber(node.attr.type)
				elseif node.tag == "time" then
					request_l["time"] = tonumber(node.attr.sec)
				elseif node.tag == "home_carry" then
					request_l["home_carry"] = {}
					request_l["home_carry"]["id"] = tonumber(node.attr.scene_id)
					--request_l["home_carry"]["scene_id"] = tonumber(node.attr.scene_id)
					request_l["home_carry"]["pos"] = {tonumber(node.attr.x), tonumber(node.attr.y)}
					--request_l["home_carry"]["x"] = tonumber(node.attr.x)
					--request_l["home_carry"]["y"] = tonumber(node.attr.y)
				elseif node.tag == "info" then
					for j,sub_node in pairs(node) do
						if sub_node.tag == "sub_item" then
							local scene_id = tonumber(sub_node.attr.scene_id)
							request_l.copy_l[scene_id] = {}

							for i, xml_node in pairs(sub_node) do
								if xml_node.tag == "prop_need" then
									request_l.copy_l[scene_id]["prop"] = {}
									local count = 1
									for i, x_node in pairs(xml_node) do
										if x_node.tag == "prop" then
											local t = {}
											t.item_id = tonumber(x_node.attr.id)
											t.number = tonumber(x_node.attr.number)
											request_l.copy_l[scene_id]["prop"][count] = t
											count = count + 1
										end
									end
								elseif xml_node.tag == "entry" then
									request_l["entry"] = {}
									request_l["entry"]["x"] = tonumber(xml_node.attr.x)
									request_l["entry"]["y"] = tonumber(xml_node.attr.y)
								end
							end
						end
					end
				end
			end
			return request_l
		else
			for k,nd in pairs(xml_tree) do
				handle_xml(nd, id)
			end
		end
	end
end


for s_id,_ in pairs(_scene._config_bale) do
	parse_xml(s_id)
end