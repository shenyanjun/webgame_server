
local debug_print = function() end
local lom = require("lom")
local _scene = require("config.scene_config")

module("scene.monster_layout_loader", package.seeall)


layout_l = create_local("monster_layout_loader.layout_l", {})
occ_level_l = create_local("monster_layout_loader.occ_level_l", {})
update_l = create_local("monster_layout_loader.update_l", {})

function get_layout_config(scene_id)
	--[[if layout_l.value[scene_id] == nil then
		parse_xml(scene_id)
	end]]

	return layout_l.value[scene_id] or {},occ_level_l.value[scene_id] or {},update_l.value[scene_id] or 20
end

function parse_xml(scene_id)
	local path = CONFIG_DIR .. "xml/monster_layout/scene_" .. scene_id .. ".xml"
	local file_handle = io.open(path)
	if not file_handle then
		debug_print("Can't open the xml file, file name:", path)
		return 
	end

	local file_data = file_handle:read("*a")
	file_handle:close()

	if is_change_config_md5(path, file_data) then
		local xml_tree,err = lom.parse(file_data)
		if err then
			debug_print(path .. " error:",err)
			return 
		end
		handle_xml(xml_tree, scene_id)
	end
end

function handle_xml(xml_tree, scene_id)
	if xml_tree == nil then return end

	if xml_tree.tag then
		if xml_tree.tag == "Item" then
			layout_l.value[scene_id] = {}
			occ_level_l.value[scene_id] = {}
			update_l.value[scene_id] = 20

			local obj_l = layout_l.value[scene_id]
			local occ_level_l = occ_level_l.value[scene_id]
			update_l.value[scene_id] = tonumber(xml_tree.attr.update_time) or 20

			for k,node in pairs(xml_tree) do
				if node.tag == "area" then
					local t_node = {}
					for i, xml_node in pairs(node) do
						if type(xml_node.tag) == "string" then
							local node_value = xml_node[1]
							t_node[xml_node.tag] = tonumber(node_value)
							for node_attr, node_attr_value in pairs(xml_node.attr) do
								if node_attr == "type" and node_attr_value == "string" then
									t_node[xml_node.tag] = xml_node[1]
								end
							end
						end
					end

					local area = tonumber(node.attr.id)
					local occ = tonumber(t_node.mon_type)
					if obj_l[area] == nil then
						obj_l[area] = {}
					end
					obj_l[area][occ] = {}
					obj_l[area][occ]["total"] = tonumber(t_node.total)
					obj_l[area][occ]["number"] = tonumber(t_node.number)
					obj_l[area][occ]["number_per"] = tonumber(t_node.number_per)
					obj_l[area][occ]["bt_total"] = t_node.bt_total and tonumber(t_node.bt_total)
					obj_l[area][occ]["bt_mon_type"] = t_node.bt_mon_type and tonumber(t_node.bt_mon_type)
					obj_l[area][occ]["bt_per"] = t_node.bt_per and tonumber(t_node.bt_per)
					obj_l[area][occ]["pet_total"] = t_node.pet_total and tonumber(t_node.pet_total)
					obj_l[area][occ]["pet_mon_type"] = t_node.pet_mon_type and tonumber(t_node.pet_mon_type)
					obj_l[area][occ]["pet_per"] = t_node.pet_per and tonumber(t_node.pet_per)
					obj_l[area][occ]["random_pos"] = t_node.random_pos and tonumber(t_node.random_pos)

				--副本要求
				elseif node.tag == "level_list" then
					local occ = tonumber(node.attr.occ)
					if occ_level_l[occ] == nil then
						occ_level_l[occ] = {}
					end
					for i,xml_node in pairs(node) do
						if xml_node.tag == "level" then
							local lv_num = tonumber(xml_node.attr.number)
							local lv_occ = tonumber(xml_node.attr.occ)
							occ_level_l[occ][lv_num] = lv_occ
						end
					end
				end
			end
		else
			for k,nd in pairs(xml_tree) do
				handle_xml(nd, scene_id)
			end
		end
	end
end


for s_id,_ in pairs(_scene._config) do
	parse_xml(s_id)
end