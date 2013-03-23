local namespace = require("scene_ex.scene_mode.mode_base")

local Mode_side = oo.class(namespace.Mode_base, "scene_ex.scene_mode.Mode_side")

function Mode_side:can_attack(attacker, defender)
	if not attacker or not defender then
		return SCENE_ERROR.E_INVALID_ARGS									 
	end
	
	if OBJ_TYPE_PET == attacker:get_type() then
		attacker = g_obj_mgr:get_obj(attacker:get_owner_id())
	end
	
	if OBJ_TYPE_PET == defender:get_type() then
		defender = g_obj_mgr:get_obj(defender:get_owner_id())
	end
	
	if not attacker or not defender then
		return SCENE_ERROR.E_INVALID_ARGS									 
	end
	
	if attacker:get_id() == defender:get_id() then
		return SCENE_ERROR.E_ATTACK_SELF 
	end
	
	local side = attacker:get_side()
	if side and side == defender:get_side() then
		return SCENE_ERROR.E_ATTACK_SIDE
	end

--[[
	if OBJ_TYPE_HUMAN ~= attacker:get_type() or OBJ_TYPE_HUMAN ~= defender:get_type() then  --双方有一方不是玩家
		return SCENE_ERROR.E_SUCCESS
	end
]]	
	return self:do_can_attack(attacker, defender)
end

function Mode_side:do_can_attack(attacker, defender)
	return SCENE_ERROR.E_SUCCESS
end

Scene_config_mgr.register_mode_class(SCENE_MODE.SIDE, Mode_side)