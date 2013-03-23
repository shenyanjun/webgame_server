local namespace = require("scene_ex.scene_mode.mode_base")

local Mode_kill = oo.class(namespace.Mode_base, "scene_ex.scene_mode.Mode_kill")

function Mode_kill:do_can_attack(attacker, defender)
	return SCENE_ERROR.E_SUCCESS
end

Scene_config_mgr.register_mode_class(SCENE_MODE.KILL, Mode_kill)