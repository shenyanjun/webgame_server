module("scene_ex.scene_mode.mode_base", package.seeall)

Mode_base = oo.class(nil, "scene_ex.scene_mode.Mode_base")

function Mode_base:__init(mode)
	self.mode = mode
end

function Mode_base:get_mode()
	return self.mode
end

function Mode_base:can_attack(attacker, defender)
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

	if OBJ_TYPE_HUMAN ~= attacker:get_type() or OBJ_TYPE_HUMAN ~= defender:get_type() then  --双方有一方不是玩家
		return SCENE_ERROR.E_SUCCESS
	end
	
	local team_id = attacker:get_team()
	if team_id and team_id == defender:get_team() then
		return SCENE_ERROR.E_ATTACK_TEAM
	end
	
	return self:do_can_attack(attacker, defender)
end

function Mode_base:do_can_attack(attacker, defender)
	return SCENE_ERROR.E_NO_IMPL
end
