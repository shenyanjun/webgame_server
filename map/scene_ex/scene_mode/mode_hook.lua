local namespace = require("scene_ex.scene_mode.mode_base")

local Mode_hook = oo.class(namespace.Mode_base, "scene_ex.scene_mode.Mode_hook")

function Mode_hook:do_can_attack(attacker, defender)	
	if PK_MODE_PEACE == attacker:get_pk_mode():get_mode() then
		return SCENE_ERROR.E_ATTACK_HOOK
	end
	
	return SCENE_ERROR.E_SUCCESS
end

Scene_config_mgr.register_mode_class(SCENE_MODE.HOOK, Mode_hook)