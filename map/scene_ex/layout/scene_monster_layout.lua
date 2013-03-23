
local debug_print = print

local _random = crypto.random
local _max_mon_area = 30    --怪区最大值
local layout_config = require("scene.monster_layout_loader")


--场景怪物,采集物品布局
Scene_monster_layout = oo.class(nil, "Scene_monster_layout")

--[[
function Scene_monster_layout:__init(sid, b_update)
	--self.cur_obj_l = {}
	self.scene_d = table.copy(sid)

	self.update_count = ev.time
	self.b_update = b_update

	--按怪物职业保存出生坐标
	self.occ_pos_l = {}
	
	self.area_obj_count = {}
	self.obj_list = {}
end

function Scene_monster_layout:load(level)
	local layout_l, occ_level_l, update_time = layout_config.get_layout_config(self.scene_d[1])

	local scene_o = g_scene_mgr_ex:get_scene(self.scene_d)
	for area,list in pairs(layout_l) do
		--self.cur_obj_l[area] = {}
		self.area_obj_count[area] = {}
		for occ,v in pairs(list) do
			for i=1,v.total do
				local pos = scene_o:get_map_obj():find_space(area, 20)
				if pos ~= nil then
					if level ~= nil and occ_level_l[occ] ~= nil then
						occ = occ_level_l[occ][level] or occ
					end

					local obj
					if area <= _max_mon_area then
						obj = g_obj_mgr:create_monster(occ, pos, self.scene_d)
					else
						obj = g_obj_mgr:create_npc(occ, "", pos, self.scene_d)
					end
					self:add_obj(obj:get_id(), occ, area)
					g_scene_mgr_ex:enter_scene(obj)
				end
			end
		end
	end
		
	return true
end

--坐标队列
function Scene_monster_layout:add_pos(occ, area, pos)
	if self.occ_pos_l[occ] == nil then
		self.occ_pos_l[occ] = {}
		self.occ_pos_l[occ]["list"] = {}
		self.occ_pos_l[occ]["count"] = 0
		self.occ_pos_l[occ]["head"] = 1
		self.occ_pos_l[occ]["tail"] = 0
	end 
	if self.occ_pos_l[occ]["count"] > 200 then
		return 
	end

	self.occ_pos_l[occ]["count"] = self.occ_pos_l[occ]["count"] + 1
	self.occ_pos_l[occ]["tail"] = self.occ_pos_l[occ]["tail"] + 1
	local n = self.occ_pos_l[occ]["tail"]
	self.occ_pos_l[occ]["list"][n] = table.copy(pos)
end
function Scene_monster_layout:random_pos(occ, area)
	local scene_o = g_scene_mgr_ex:get_scene(self.scene_d)
	local map_o = scene_o:get_map_obj()
	if self.occ_pos_l[occ] == nil or self.occ_pos_l[occ]["count"] < 1 then
		return map_o:find_space(area, 20)
	else
		local n = self.occ_pos_l[occ]["head"]
		local pos = self.occ_pos_l[occ]["list"][n]
		self.occ_pos_l[occ]["list"][n] = nil
		self.occ_pos_l[occ]["head"] = self.occ_pos_l[occ]["head"] + 1
		self.occ_pos_l[occ]["count"] = self.occ_pos_l[occ]["count"] - 1

		for i=1,3 do
			local x = math.max(1, _random(pos[1], pos[1] + 10) - 5)
			local y = math.max(1, _random(pos[2], pos[2] + 10) - 5)
			if map_o:is_mon_area(area, {x,y}) then
				--print("Scene_monster_layout:get_pos1", x, y)
				return {x,y}
			end
		end

		--print("Scene_monster_layout:get_pos2")
		return map_o:find_space(area, 20)
	end
end

function Scene_monster_layout:update()
	if not self.b_update then
		return 
	end
	local now = ev.time
	local layout_l, occ_level_l, update_time = layout_config.get_layout_config(self.scene_d[1])
	--self.update_count = self.update_count + 1
	if self.update_count <= now then
		self.update_count = now + update_time

		local scene_o = g_scene_mgr_ex:get_scene(self.scene_d)
		for area,list in pairs(layout_l) do
			for occ,v in pairs(list) do
				local cur_count = self:get_count(occ, area)
				if cur_count <= v.total - v.number then
					local n = math.floor((v.total-cur_count)*v.number_per)
					local num = math.min(math.max(n,v.number), v.total-cur_count)
					for i=1,num do
						local pos = self:random_pos(occ, area)
						if pos ~= nil then
							local obj
							if area <= _max_mon_area then
								obj = g_obj_mgr:create_monster(occ, pos, self.scene_d)
							else
								obj = g_obj_mgr:create_npc(occ, "", pos, self.scene_d)
							end
							self:add_obj(obj:get_id(), occ, area)
							g_scene_mgr_ex:enter_scene(obj)
						end

						--创建精英怪
						if v.bt_mon_type ~= nil 
							and self:get_count(v.bt_mon_type, area) < v.bt_total 
							and _random(0, 10000) < v.bt_per*10000 then

							local pos = self:random_pos(v.bt_mon_type, area)
							if pos ~= nil then
								local obj = g_obj_mgr:create_monster(v.bt_mon_type, pos, self.scene_d)
								self:add_obj(obj:get_id(), v.bt_mon_type, area)
								g_scene_mgr_ex:enter_scene(obj)
							end
						end

						--创建宠物召唤怪
						if v.pet_mon_type ~= nil 
							and self:get_count(v.pet_mon_type, area) < v.pet_total 
							and _random(0, 10000) < v.pet_per*10000 then

							local pos = self:random_pos(v.pet_mon_type, area)
							if pos ~= nil then
								local obj = g_obj_mgr:create_monster(v.pet_mon_type, pos, self.scene_d)
								self:add_obj(obj:get_id(), v.pet_mon_type, area)
								g_scene_mgr_ex:enter_scene(obj)
							end
						end
					end
				end
			end
		end
	end
end

function Scene_monster_layout:add_obj(obj_id, occ, area)
	if not self.obj_list[obj_id] then
		self.area_obj_count[area][occ] = (self.area_obj_count[area][occ] or 0) + 1
		self.obj_list[obj_id] = {area, occ}
	end
end

function Scene_monster_layout:del_obj(obj_id, occ, home_pos)
	local obj_info = self.obj_list[obj_id]
	if obj_info then
		local area = obj_info[1]
		local occ = obj_info[2]
		self.obj_list[obj_id] = nil
		self.area_obj_count[area][occ] = self.area_obj_count[area][occ] - 1
		self:add_pos(occ, area, home_pos)
	end
end

function Scene_monster_layout:get_count(occ, area)
	return self.area_obj_count[area][occ] or 0
end
]]

function Scene_monster_layout:__init(sid, b_update)
	self.scene_d = table.copy(sid)

	self.b_update = b_update
	
	self.area_obj_count = {}
	self.obj_list = {}
	
	self.update_list = {}
	
	self.update_count = 0
end

function Scene_monster_layout:create_monster(occ, area, pos, args)
	local org_occ = occ
	
	if args.pet_mon_type
		and self:get_count(args.pet_mon_type, area) < args.pet_total 
		and _random(0, 10000) < args.pet_per * 10000 then
		occ = args.pet_mon_type
		--print("_________p")
	elseif args.bt_mon_type
		and self:get_count(args.bt_mon_type, area) < args.bt_total
		and _random(0, 10000) < args.bt_per*10000 then
		occ = args.bt_mon_type
		--print("----------b")
	end
	
	local obj
	if area <= _max_mon_area then
		obj = g_obj_mgr:create_monster(occ, pos, self.scene_d)
	else
		obj = g_obj_mgr:create_npc(occ, "", pos, self.scene_d)
	end
	
	self:add_obj(obj:get_id(), occ, area, org_occ)
	g_scene_mgr_ex:enter_scene(obj)
end

function Scene_monster_layout:load(level)
	local layout_l = layout_config.get_layout_config(self.scene_d[1])

	local scene_o = g_scene_mgr_ex:get_scene(self.scene_d)
	for area,list in pairs(layout_l) do
		self.area_obj_count[area] = {}
		for occ,v in pairs(list) do
			for i=1, v.total do
				local pos = scene_o:get_map_obj():find_space(area, 20)
				if pos ~= nil then
					if level ~= nil and occ_level_l[occ] ~= nil then
						occ = occ_level_l[occ][level] or occ
					end

					self:create_monster(occ, area, pos, v)
				end
			end
		end
	end
		
	return true
end

function Scene_monster_layout:update()
	if not self.b_update then
		return 
	end
	
	local layout_l, occ_level_l, update_time = layout_config.get_layout_config(self.scene_d[1])
	
	local now = ev.time
	if self.update_count <= now then
		self.update_count = now + update_time
	
		for area, list in pairs(self.update_list) do
			local mon_list = layout_l[area]
			if mon_list then
				for _, obj_info in ipairs(list) do
					local occ = obj_info[1]
					local args = mon_list[occ]
					self:create_monster(occ, area, obj_info[2], args)
				end
			end
			self.update_list[area] = {}
		end
	end
end

function Scene_monster_layout:add_obj(obj_id, occ, area, org_occ)
	if not self.obj_list[obj_id] then
		self.area_obj_count[area][occ] = (self.area_obj_count[area][occ] or 0) + 1
		self.obj_list[obj_id] = {area, org_occ, occ}
	end
end

function Scene_monster_layout:del_obj(obj_id, occ, home_pos)
	local obj_info = self.obj_list[obj_id]
	local layout_l = layout_config.get_layout_config(self.scene_d[1])
	if obj_info then
		local area = obj_info[1]
		local occ = obj_info[3]
		local pos = nil
		if layout_l[area] and layout_l[area][occ] and layout_l[area][occ].random_pos then
			local scene_o = g_scene_mgr_ex:get_scene(self.scene_d)
			pos = scene_o:get_map_obj():find_space(area, 20)
		else
			pos = home_pos
		end
		
		self.obj_list[obj_id] = nil
		self.area_obj_count[area][occ] = self.area_obj_count[area][occ] - 1
		
		local list = self.update_list[area]
		if not list then
			list = {}
			self.update_list[area] = list
		end
		
		table.insert(list, {obj_info[2], pos})
	end
end

function Scene_monster_layout:get_count(occ, area)
	return self.area_obj_count[area][occ] or 0
end