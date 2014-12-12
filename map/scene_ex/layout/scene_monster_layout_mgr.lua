
local debug_print = print
local lom = require("lom")


--场景怪物,采集物品布局管理类
Scene_monster_layout_mgr = oo.class(nil, "Scene_monster_layout_mgr")

function Scene_monster_layout_mgr:__init()
	self.layout_l = {}       --怪物分布配置
	self.occ_level_l = {}    --副本职业，等级要求
	self.update_l = {}
end

--返回 分布配置，副本职业等级要求，更新时间
function Scene_monster_layout_mgr:load(scene_id)
	if self.layout_l[scene_id] == nil then
		self.layout_l[scene_id] = {}
		self.occ_level_l[scene_id] = {}
		self.update_l = {}
		local path = CONFIG_DIR .. "monster_layout/scene_" .. scene_id .. ".xml"
		self:parse_xml(path, scene_id)
	end

	return self.layout_l[scene_id], self.occ_level_l[scene_id], self.update_l[scene_id] or 20
end


--解析xml
function Scene_monster_layout_mgr:parse_xml(path, scene_id)
	local file_handle = io.open(path)
	if not file_handle then
		debug_print("Can't open the xml file, file name:", path)
		return 
	end

	local file_data = file_handle:read("*a")
	file_handle:close()

	local xml_tree,err = lom.parse(file_data)
	if err then
		debug_print(self.xml_name .. " error:",err)
		return 
	end
	local ret = self:handle_xml(xml_tree, scene_id)
end

function Scene_monster_layout_mgr:handle_xml(xml_tree, scene_id)
	if xml_tree == nil then return end

	local obj_l = self.layout_l[scene_id]
	local occ_level_l = self.occ_level_l[scene_id]
	if xml_tree.tag then
		if xml_tree.tag == "Item" and tonumber(xml_tree.attr.scene_id) == scene_id
			and xml_tree.attr.update_time ~= nil then

			--self.update_time = tonumber(xml_tree.attr.update_time)
			self.update_l[scene_id] = tonumber(xml_tree.attr.update_time)
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

					--[[if self.cur_obj_l[area] == nil then
						self.cur_obj_l[area] = {}
						self.cur_obj_l[area][occ] = {}
						self.cur_obj_l[area][occ]["count"] = 0
						self.cur_obj_l[area][occ]["list"] = {}
					end]]

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
				self:handle_xml(nd, scene_id)
			end
		end
	end
end

g_scene_monster_layout_mgr = Scene_monster_layout_mgr()