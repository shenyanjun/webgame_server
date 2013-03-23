local namespace = require("scene_ex.scene_mode.mode_base")

local Mode_party = oo.class(namespace.Mode_base, "scene_ex.scene_mode.Mode_party")

function Mode_party:do_can_attack(attacker, defender)
	local faction_id = attacker:get_faction_id()
	if faction_id and faction_id == defender:get_faction_id() then
		return SCENE_ERROR.E_ATTACK_PARTY						--帮成员之间不允许pk
	end
	
	return SCENE_ERROR.E_SUCCESS
end

Scene_config_mgr.register_mode_class(SCENE_MODE.PARTY, Mode_party)