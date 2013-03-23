local debug_print = print
--local debug_print = function() end
local battle_config = require("scene_ex.config.faction_battle_loader")
Scene_faction_battle_copy = oo.class(Scene_copy, "Scene_faction_battle_copy")

function Scene_faction_battle_copy:get_self_config()
	return battle_config.config[self.id]
end

--副本出口
function Scene_faction_battle_copy:get_home_carry(obj)
	local config = self:get_self_config()
	local home_carry = config and config.home
	if not home_carry or not home_carry.id or not home_carry.pos or not home_carry.pos[1] or not home_carry.pos[2] then
		return nil, nil
	end
	return home_carry.id, home_carry.pos
end

--获取副本实例ID
function Scene_faction_battle_copy:get_instance_id(obj)
	local instance_id = g_faction_battle_mgr:get_accept_lid_from_cid(obj:get_id())
	return instance_id, instance_id and SCENE_ERROR.E_SUCCESS or SCENE_ERROR.E_INVALID_FACTION
end


--副本创建权限检查
function Scene_faction_battle_copy:check_create_access(obj)
	--print("Scene_faction_battle_copy:check_create_access()", obj:get_id())
	
	local obj_id = obj:get_id()
	local faction = g_faction_mgr:get_faction_by_cid(obj_id)
	local faction_id = faction and faction:get_faction_id()
	local l_id = g_faction_battle_mgr:get_accept_lid_from_cid(obj_id)
	if not faction_id or l_id == nil then
		return SCENE_ERROR.E_INVALID_FACTION, nil 
	end
	if g_scene_mgr_ex:exists_instance(l_id) then
		return SCENE_ERROR.E_EXISTS_COPY, nil
	end
--[[	
	if 0 ~= faction:get_dissolve_flag() then
		return SCENE_ERROR.E_FACTION_DISSOLVE, nil
	end
]]
	local config = self:get_self_config()
	if not config then
		return SCENE_ERROR.E_INVALID_CONFIG, nil
	end

	local limit = config.limit
	if not limit then
		return SCENE_ERROR.E_INVALID_CONFIG, nil
	end

	local ret = g_faction_battle_mgr:check_letter(l_id)
	if ret ~= 0 then
		return ret, nil
	end

	if g_faction_battle_mgr:get_letter_remain_time(l_id) < 30 then
		return SCENE_ERROR.E_FACTION_BATTLE_OVER, nil
	end
	
	return SCENE_ERROR.E_SUCCESS, nil
end

--副本进入权限检查
function Scene_faction_battle_copy:check_entry_access(obj)
	--debug_print("Scene_faction_battle_copy:check_entry_access()", obj:get_id())
	
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
function Scene_faction_battle_copy:create_instance(instance_id, obj)
	--debug_print("Scene_faction_battle_copy:create_instance()", instance_id)

--[[
	g_faction_mgr:set_fb(obj:get_id(), self.id)
	local pkt = {}
	pkt.faction_id = instance_id
	pkt.switch_flag = 1
	pkt.scene_id = self.id
	g_faction_mgr:switch_fb(pkt)
	]]
	return Scene_faction_battle(self.id, instance_id, self.map_obj:clone(self.id))
end

function Scene_faction_battle_copy:instance()

	self.map_obj = g_scene_config_mgr:load_map(self.id)
end

function Scene_faction_battle_copy:get_enter_pos(side)
	local config = self:get_self_config()
	return config.entry[side][crypto.random(#config.entry[side], #config.entry[side] + 1)]
end


-----------------------------------------------场景入口----------------------------------------------

function Scene_faction_battle_copy:login_scene(obj, pos)
	--print("Scene_faction_battle_copy:login_scene()", obj)
	local side = g_faction_battle_mgr:get_battle_side(obj:get_id())
	if side then
		pos = self:get_enter_pos(side)
	else
		return Scene_copy.login_scene(self, obj, pos)		
	end
	local e_code, error_list = self:carry_scene(obj, pos)
	if SCENE_ERROR.E_SUCCESS ~= e_code then
		return Scene_copy.login_scene(self, obj, pos)
	end
	return e_code, error_list
end
