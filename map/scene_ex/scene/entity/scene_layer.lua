local tower_config = require("scene_ex.config.tower_config_loader")
local _scene_config = require("config.scene_config")

local _max_mon_area = 30    --怪区最大值

Scene_layer = oo.class(Scene_instance, "Scene_layer")

function Scene_layer:__init(group, tower_id, map_id, instance_id, map_obj, is_first)
	Scene_instance.__init(self, map_id, instance_id, map_obj)
	self.group = group
	self.tower_id = tower_id
	self.key = {tower_id, instance_id, map_id}
	
	self.is_over = false
	self.sequence = 1
	self.not_human = is_first
	
	self.resources = Scene_obj_container()
end

function Scene_layer:get_name()
	local config = g_scene_config_mgr:get_config(self.tower_id)
	return config and config.name
end

function Scene_layer:get_mode()
	local config = g_scene_config_mgr:get_config(self.tower_id)
	return config and config.mode
end

function Scene_layer:get_type()
	local config = g_scene_config_mgr:get_config(self.tower_id)
	return config and config.type
end

function Scene_layer:carry_scene(obj, pos)
	local config = tower_config.config[self.tower_id].layer_config[self.id]
	local limit = tower_config.config[self.tower_id].limit
	if self:get_human_count() >= limit.human[2] then
		return SCENE_ERROR.E_HUMAN_LIMIT
	end
	return self:push_scene(obj, config.entry)
end

function Scene_layer:instance()
	local config = tower_config.config[self.tower_id].layer_config[self.id]
	self.open_time = ev.time
	self.end_time = ev.time + config.timeout
	self.record_id = config.record_id
	self.except = config.except
	self.obj_mgr:instance(self.map_obj:get_w(), self.map_obj:get_h())
end

function Scene_layer:get_last_time(obj)
	return math.max(self.end_time - ev.time, 0)
end

--通知开始下一层
function Scene_layer:notify_next_layer()
	local pkt = {}
	pkt.carry_id = _scene_config.get_tower_carry_id(self.id)
	if pkt.carry_id ~= nil then
		pkt = Json.Encode(pkt)
		local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
		local enter_list = con and con:get_obj_list()
		for k, _ in pairs(enter_list) do
			g_cltsock_mgr:send_client(k, CMD_MAP_TOWER_NEXT_LAYER_S, pkt, true)
		end
	end
end

function Scene_layer:end_update()
	if self.record_id then
		local team_obj = g_team_mgr:get_team_obj(self.instance_id)
		if team_obj then
			local team_l = team_obj:get_team_l()
			if team_l then
				local data = {}
				local obj_mgr = g_obj_mgr
				for k, _ in pairs(team_l) do
					local obj = obj_mgr:get_obj(k)
					if obj then
						table.insert(data, {['id'] = k, ['name'] = obj:get_name()})
					end
				end

				g_public_sort_mgr:update_record(
					PUBLIC_SORT_TYPE.SCENE
					, ev.time - self.open_time
					, {["scene_id"] = self.tower_id, ["id"] = self.record_id, ["data"] = data}
					, PUBLIC_SORT_ORDER.ASC)
			end
		end
	end
	self.group:open_next()
	self:notify_next_layer()
end

function Scene_layer:get_home_carry(obj)
	local config = tower_config.config[self.tower_id]
	local home_carry = config.home
	if not home_carry or not home_carry.id 
		or not home_carry.pos or not home_carry.pos[1] or not home_carry.pos[2] then
		return nil, nil
	end
	return home_carry.id, home_carry.pos
end

function Scene_layer:pop_player(obj_id)
	local obj = g_obj_mgr:get_obj(obj_id)
	if SCENE_ERROR.E_SUCCESS ~= self.group:push_current(obj) then
		self:kickout(obj_id)
	end
end

function Scene_layer:close()
	if self.instance_id then
	
		local instance_id = self.instance_id
		self.instance_id = nil	

		if self.obj_mgr then
			local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
			if con then
				for obj_id, _ in pairs(con:get_obj_list()) do
					self:pop_player(obj_id)
				end
			end
--[[			
			local con = self.obj_mgr:get_obj_con(OBJ_TYPE_MONSTER)
			if con then
				local obj_mgr = g_obj_mgr
				for obj_id, _ in pairs(con:get_obj_list()) do
					local obj = obj_mgr:get_obj(obj_id)
					if obj then
						obj:leave()
					end
				end
			end
]]
		end
		
		if self.door_obj_mgr then
			for obj_id, _ in pairs(self.door_obj_mgr:get_obj_list()) do
				self:pop_player(obj_id)
			end
		end

		self:clean_scene_obj()
		
		self.group:close_layer(self.id)
	end
end

function Scene_layer:next_sequence()
	if self.is_over then
		return
	end
	
	local config = tower_config.config[self.tower_id].layer_config[self.id]
	local sequence = config.monster_list and config.monster_list[self.sequence]
	
	if not sequence then
		self.is_over = true
		self:end_update()
		--通知完成
		return
	end

	local member_str = ""
	if self.record_id then
		local team_obj = g_team_mgr:get_team_obj(self.instance_id)
		if team_obj then
			local list = team_obj:get_team_l()
			
			local t = {}
			for obj_id, _ in pairs(list) do
				table.insert(t, obj_id)
			end
			member_str = table.concat(t, " ")
		end
	end
	
	local map_obj = self:get_map_obj()
	local obj_mgr = g_obj_mgr
	for _, info in pairs(sequence) do
		for i=1, info.number do
			local pos = map_obj:find_space(info.area, 20)
			if pos then
				local obj
				if info.type == 2 then
					obj = obj_mgr:create_npc(info.id, "", pos, self.key)
					self.resources:push_obj(obj:get_id())
				elseif info.type == 3 then
					local args = {}
					args.time = self.end_time
					args.perpetual = true
					args.carry_id = info.carry_id
					obj = obj_mgr:create_npc(info.id, "", pos, self.key, args)
				else
					obj = obj_mgr:create_monster(info.id, pos, self.key)
				end
				
				local ret_code = self:enter_scene(obj)

				if self.record_id then
					f_scene_info_log("Scene_layer:next_sequence(%d, %s, %s, %s, %s, %s, %s)"
						, self.id
						, tostring(info.id)
						, tostring(obj and obj:get_id())
						, tostring(pos[1])
						, tostring(pos[2])
						, tostring(ret_code)
						, member_str)
				end
			end
		end
	end
	
	self.sequence = self.sequence + 1
end

function Scene_layer:on_timer(tm)
	if self.end_time and self.end_time <= ev.time then
		self:close()
	else
		local con = self.obj_mgr:get_obj_con(OBJ_TYPE_MONSTER)
		if 0 == con:get_obj_count() and self.except == nil and 0 == self.resources:get_obj_count() then
			self:next_sequence()
		elseif self.except ~= nil and 0 == self.resources:get_obj_count() then
			-- 有过滤怪物列表的情况
			local next_s = true
			for obj_id, _ in pairs(con:get_obj_list()) do
				local obj = g_obj_mgr:get_obj(obj_id)
				if obj and self.except[obj:get_occ()] == nil then
					next_s = false
					break
				end
			end
			if next_s then
				self:next_sequence()
			end
		end
	
		self.obj_mgr:on_timer(tm)
	end
end

function Scene_layer:on_obj_leave(obj)
	Scene_instance.on_obj_leave(self, obj)
	if OBJ_TYPE_NPC == obj:get_type() then
		self.resources:pop_obj(obj:get_id())
	end
end