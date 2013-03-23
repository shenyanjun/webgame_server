local debug_print = print
--local debug_print = function() end
local manor_config = require("scene_ex.config.faction_manor_loader")
local _manor_config = require("config.faction_manor_config")

Scene_faction_manor_copy = oo.class(Scene_copy, "Scene_faction_manor_copy")

function Scene_faction_manor_copy:get_self_config()
	return manor_config.config[self.id]
end

--副本出口
function Scene_faction_manor_copy:get_home_carry(obj)
	local config = self:get_self_config()
	local home_carry = config and config.home
	if not home_carry or not home_carry.id or not home_carry.pos or not home_carry.pos[1] or not home_carry.pos[2] then
		return nil, nil
	end
	return home_carry.id, home_carry.pos
end

--获取副本实例ID
function Scene_faction_manor_copy:get_instance_id(obj)
	local obj_id = obj:get_id()
	local faction = g_faction_mgr:get_faction_by_cid(obj_id)	
	local instance_id = faction and faction:get_faction_id()
	if instance_id == nil then 
		return nil, SCENE_ERROR.E_INVALID_FACTION
	end
	instance_id = "manor_" .. instance_id
	return instance_id, SCENE_ERROR.E_SUCCESS
end


--副本创建权限检查
function Scene_faction_manor_copy:check_create_access(obj)
	--print("Scene_faction_manor_copy:check_create_access()", obj:get_id())
	
	local obj_id = obj:get_id()
	local faction = g_faction_mgr:get_faction_by_cid(obj_id)
	local faction_id = faction and faction:get_faction_id()
	
	if not faction_id or not g_faction_manor_mgr:had_manor(faction_id) then
		return SCENE_ERROR.E_INVALID_FACTION, nil 
	end

--[[	
	if 0 ~= faction:get_dissolve_flag() then
		return SCENE_ERROR.E_FACTION_DISSOLVE, nil
	end
]]
	local instance_id = self:get_instance_id(obj)
	if g_scene_mgr_ex:exists_instance(instance_id) then
		return SCENE_ERROR.E_EXISTS_COPY, nil
	end

	local config = self:get_self_config()
	if not config then
		return SCENE_ERROR.E_INVALID_CONFIG, nil
	end

	local limit = config.limit
	if not limit then
		return SCENE_ERROR.E_INVALID_CONFIG, nil
	end


	
	return SCENE_ERROR.E_SUCCESS, nil
end

--副本进入权限检查
function Scene_faction_manor_copy:check_entry_access(obj)
	--debug_print("Scene_faction_manor_copy:check_entry_access()", obj:get_id())
	
	local config = self:get_self_config()
	if not config then
		return SCENE_ERROR.E_SCENE_CLOSE, nil
	end

	local level_limit = config.limit and config.limit.level
	if level_limit then
		local level = obj:get_level()
		if (level_limit.min and level < level_limit.min) or (level_limit.max and level_limit.max < level) then
			return SCENE_ERROR.E_LEVEL_LIMIT, nil
		end
	end	

	return SCENE_ERROR.E_SUCCESS, nil
end

--创建副本实例
function Scene_faction_manor_copy:create_instance(instance_id, obj)
	--debug_print("Scene_faction_manor_copy:create_instance()", instance_id)

--[[
	g_faction_mgr:set_fb(obj:get_id(), self.id)
	local pkt = {}
	pkt.faction_id = instance_id
	pkt.switch_flag = 1
	pkt.scene_id = self.id
	g_faction_mgr:switch_fb(pkt)
	]]
	return Scene_faction_manor(self.id, instance_id, self.map_obj:clone(self.id))
end

function Scene_faction_manor_copy:instance()
	self.map_obj = g_scene_config_mgr:load_map(self.id)
	self.status = SCENE_STATUS.IDLE
end

function Scene_faction_manor_copy:get_enter_pos()
	local config = self:get_self_config()
	return config.entry[crypto.random(#config.entry, #config.entry + 1)]
end

function Scene_faction_manor_copy:get_enter_oth_pos()
	local config = self:get_self_config()
	return config.entry_oth[crypto.random(#config.entry_oth, #config.entry_oth + 1)]
end

function Scene_faction_manor_copy:open_event(args)
	self.status = SCENE_STATUS.OPEN
	
	local manor_list = g_faction_manor_mgr:get_faction_manor_l()
	for f_id, manor in pairs(manor_list) do
		local instance_id = "manor_" .. f_id
		local refresh_type = g_faction_manor_mgr:can_rob(f_id)
		if refresh_type then
			if self.instance_list[instance_id] == nil then
				local instance = self:create_instance(instance_id, nil)
				self.instance_list[instance_id] = instance
				g_scene_mgr_ex:register_instance(instance_id, self)
				instance:instance(nil)
			end
			--
			local info = {}
			info.refresh_type = refresh_type
			self.instance_list[instance_id]:notify_status(self.status, info)
		else
			local _ = self.instance_list[instance_id] and self.instance_list[instance_id]:check_close()
		end
	end
	--self:notify_status(args)
end

function Scene_faction_manor_copy:close_event(args)
	self.status = SCENE_STATUS.IDLE
	self:notify_status(args)
end

function Scene_faction_manor_copy:notify_status(args)
	--print("Scene_faction_manor_copy:notify_status()", self.status)
	local info = {}
	info.refresh_type = 0
	for instance_id, instance in pairs(self.instance_list or {}) do
	--[[
		if self.status == SCENE_STATUS.OPEN then 
			local faction = g_faction_mgr:get_faction_by_fid(instance.f_id)
			local count = faction and faction:get_online_member_count() or 1
			info.refresh_type = count <= _manor_config._refresh_monster_online[2] and 1 or count <= _manor_config._refresh_monster_online[3] and 2 or 3
		end
	]]
		instance:notify_status(self.status, info)
	end
end

function Scene_faction_manor_copy:notify_rob_succeed(char_id)
	--print("Scene_faction_manor_copy:notify_rob_succeed()")
	local instance_id = self:get_instance_id(g_obj_mgr:get_obj(char_id))
	local instance = instance_id and self.instance_list[instance_id]
	local _ = instance and instance:notify_rob_succeed(char_id)
end

function Scene_faction_manor_copy:notify_rob_start(char_id)

	local instance_id = self:get_instance_id(g_obj_mgr:get_obj(char_id))
	local instance = instance_id and self.instance_list[instance_id]
	local _ = instance and instance:notify_rob_start(char_id)
end

-----------------------------------------------场景入口----------------------------------------------

function Scene_faction_manor_copy:login_scene(obj, pos)
	--print("Scene_faction_manor_copy:login_scene()", obj:get_id())
	local pos = self:get_enter_pos()
	local e_code, error_list = self:carry_scene(obj, pos)
	if SCENE_ERROR.E_SUCCESS ~= e_code then
		return Scene_copy.login_scene(self, obj, pos)
	end
	return e_code, error_list
end

function Scene_faction_manor_copy:carry_scene(obj, pos, args)
	if not obj then
		return SCENE_ERROR.E_NOT_ON_SCENE, nil
	end
	
	local instance_id, e_code = self:get_instance_id(obj)
	if SCENE_ERROR.E_SUCCESS ~= e_code then
		return e_code, nil
	end
	
	local instance = self.instance_list[instance_id]
	if not instance then
		local e_code, error_describe = self:check_create_access(obj)
		if SCENE_ERROR.E_SUCCESS ~= e_code then
			return e_code, error_describe
		end
		
		instance = self:create_instance(instance_id, obj)
		self.instance_list[instance_id] = instance
		g_scene_mgr_ex:register_instance(instance_id, self)
		instance:instance(args)
		
		local args = {}
		args.map_id = self.id
		args.type = self:get_type()
		g_event_mgr:notify_event(EVENT_SET.EVENT_CREATE_COPY_SCENE, obj:get_id(), args)
	else
		local e_code, error_describe = self:check_entry_access(obj)
		if SCENE_ERROR.E_SUCCESS ~= e_code then
			return e_code, error_describe
		end
	end

	local scene_o = obj:get_scene_obj()
	if scene_o == instance then 
		return 21310, nil
	end
	return instance:carry_scene(obj, pos)
end

function Scene_faction_manor_copy:goto_manor(obj, f_id, pos, args)
	if not obj then
		return SCENE_ERROR.E_NOT_ON_SCENE, nil
	end
	
	local instance_id = "manor_" .. f_id
	
	local instance = self.instance_list[instance_id]
	if not instance then
		
		instance = self:create_instance(instance_id, obj)
		self.instance_list[instance_id] = instance
		g_scene_mgr_ex:register_instance(instance_id, self)
		instance:instance(args)
		
	end
	return instance:carry_scene(obj, pos)
end

function Scene_faction_manor_copy:pre_summon_boss(obj, boss_id)
	local instance_id = self:get_instance_id(obj)
	local instance = self.instance_list[instance_id]
	if not instance then
		return 22259
	end

	return instance:pre_summon_boss(obj, boss_id)
end


function Scene_faction_manor_copy:summon_boss(obj, boss_id)
	local instance_id = self:get_instance_id(obj)
	local instance = self.instance_list[instance_id]
	if not instance then
		return 22259
	end

	return instance:summon_boss(obj, boss_id)
end

function Scene_faction_manor_copy:summon_dogz(obj, level, stage)
	local instance_id = self:get_instance_id(obj)
	local instance = self.instance_list[instance_id]
	if not instance then
		return 22259
	end

	return instance:summon_dogz(obj:get_id(), level, stage)
end