local namespace = require("scene_ex.scene_mode.mode_base")

local Mode_peace = oo.class(namespace.Mode_base, "scene_ex.scene_mode.Mode_peace")

function Mode_peace:do_can_attack(attacker, defender)
	local is_compete = attacker:get_compete()
	if is_compete and is_compete == defender:get_compete() then
		return SCENE_ERROR.E_SUCCESS	--只有在切磋,才能攻击
	end
	return SCENE_ERROR.E_ATTACK_BAN
end

Scene_config_mgr.register_mode_class(SCENE_MODE.PEACE, Mode_peace)