local namespace = require("scene_ex.scene_mode.mode_base")

local Mode_none = oo.class(namespace.Mode_base, "scene_ex.scene_mode.Mode_none")

function Mode_none:can_attack(attacker, defender)
	return SCENE_ERROR.E_ATTACK_BAN
end

function Mode_none:do_can_attack(attacker, defender)
	return SCENE_ERROR.E_ATTACK_BAN
end

Scene_config_mgr.register_mode_class(SCENE_MODE.NONE, Mode_none)