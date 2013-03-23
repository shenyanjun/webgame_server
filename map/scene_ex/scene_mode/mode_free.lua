local namespace = require("scene_ex.scene_mode.mode_base")

local Mode_free = oo.class(namespace.Mode_base, "scene_ex.scene_mode.Mode_free")

function Mode_free:do_can_attack(attacker, defender)
	local is_compete = attacker:get_compete()	--切磋
	if is_compete and is_compete == defender:get_compete() then
		return SCENE_ERROR.E_SUCCESS
	end
	
	if attacker:get_pk_mode():get_mode() == PK_MODE_PEACE 
		or defender:get_pk_mode():get_mode() == PK_MODE_PEACE then	--和平模式
		return SCENE_ERROR.E_PK_MODE							 	--在自由地图，双方都打开杀戮模式才能攻击
	end
	
	return SCENE_ERROR.E_SUCCESS
end

Scene_config_mgr.register_mode_class(SCENE_MODE.FREE, Mode_free)