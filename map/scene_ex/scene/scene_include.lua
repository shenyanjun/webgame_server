require("scene_ex.scene.scene_entry")

require("scene_ex.scene.entity.scene_entity")
require("scene_ex.scene.entity.scene")
require("scene_ex.scene.entity.scene_instance")
require("scene_ex.scene.entity.scene_td")
require("scene_ex.scene.entity.scene_spa")
require("scene_ex.scene.entity.scene_war")
require("scene_ex.scene.entity.scene_layer")
require("scene_ex.scene.entity.scene_layer_ex")
require("scene_ex.scene.entity.scene_layer_rage")
require("scene_ex.scene.entity.scene_invasion")
require("scene_ex.scene.entity.scene_frenzy")
require("scene_ex.scene.entity.scene_territory")
require("scene_ex.scene.entity.scene_desert")
require("scene_ex.scene.entity.scene_level")
require("scene_ex.scene.entity.scene_faction_battle")
require("scene_ex.scene.entity.scene_faction_manor")
require("scene_ex.scene.entity.scene_manor_rob")
require("scene_ex.scene.entity.scene_personal")
require("scene_ex.scene.entity.scene_chess")
require("scene_ex.scene.entity.scene_match")
require("scene_ex.scene.entity.scene_qualify")
require("scene_ex.scene.entity.scene_knockout")
require("scene_ex.scene.entity.scene_vip")
require("scene_ex.scene.entity.scene_marry")
require("scene_ex.scene.entity.scene_marry_monster")
require("scene_ex.scene.entity.scene_more_kill")
require("scene_ex.scene.entity.scene_story")
require("scene_ex.scene.entity.scene_battlefield")
require("scene_ex.scene.entity.scene_faction")
require("scene_ex.scene.entity.scene_td_ex")
require("scene_ex.scene.entity.scene_pvp_battle")
require("scene_ex.scene.entity.scene_gobang")
require("scene_ex.scene.entity.scene_wild_boss")
require("scene_ex.scene.entity.scene_sheep")
require("scene_ex.scene.entity.scene_fish")
require("scene_ex.scene.entity.scene_compete")


require("scene_ex.scene.entry.scene_copy")
require("scene_ex.scene.entry.scene_team_copy")
require("scene_ex.scene.entry.scene_group")
require("scene_ex.scene.entry.scene_group_ex")
require("scene_ex.scene.entry.scene_tower")
require("scene_ex.scene.entry.scene_tower_ex")
require("scene_ex.scene.entry.scene_faction_copy")
require("scene_ex.scene.entry.scene_frenzy_entry")
require("scene_ex.scene.entry.scene_territory_snatch")
require("scene_ex.scene.entry.scene_territory_battle")
require("scene_ex.scene.entry.scene_territory_copy")
require("scene_ex.scene.entry.scene_territory_battle_copy")
require("scene_ex.scene.entry.scene_team_entry")
require("scene_ex.scene.entry.scene_faction_battle_copy")
require("scene_ex.scene.entry.scene_faction_manor_copy")
require("scene_ex.scene.entry.scene_personal_copy")
require("scene_ex.scene.entry.scene_world_war_entry")
require("scene_ex.scene.entry.scene_vip_entry")
require("scene_ex.scene.entry.scene_marry_entry")
require("scene_ex.scene.entry.scene_marry_monster_entry")
require("scene_ex.scene.entry.scene_single_entry")
require("scene_ex.scene.entry.scene_battlefield_entry")
require("scene_ex.scene.entry.scene_faction_copy_ex")
require("scene_ex.scene.entry.scene_pvp_battle_entry")
require("scene_ex.scene.entry.scene_sheep_entry")
require("scene_ex.scene.entry.scene_fish_entry")
require("scene_ex.scene.entry.scene_compete_copy")


Scene_mgr.register_scene_class(SCENE_TYPE.DESERT, Scene_desert)
Scene_mgr.register_scene_class(SCENE_TYPE.FRENZY, Scene_frenzy_entry)
Scene_mgr.register_scene_class(SCENE_TYPE.SPA, Scene_spa)
Scene_mgr.register_scene_class(SCENE_TYPE.PUBLIC, Scene_entity)
Scene_mgr.register_scene_class(SCENE_TYPE.INVASION, Scene_faction_copy)
Scene_mgr.register_scene_class(SCENE_TYPE.TERRITORY, Scene_territory_copy)
Scene_mgr.register_scene_class(SCENE_TYPE.TERRITORY_BATTLE, Scene_territory_battle_copy)
Scene_mgr.register_scene_class(SCENE_TYPE.COMMON, Scene)
Scene_mgr.register_scene_class(SCENE_TYPE.TOWER, Scene_tower)
Scene_mgr.register_scene_class(SCENE_TYPE.FACTION_BATTLE, Scene_faction_battle_copy)
Scene_mgr.register_scene_class(SCENE_TYPE.FACTION_MANOR, Scene_faction_manor_copy)
Scene_mgr.register_scene_class(SCENE_TYPE.VIP, Scene_vip_entry)
Scene_mgr.register_scene_class(SCENE_TYPE.MARRY, Scene_marry_entry)
Scene_mgr.register_scene_class(SCENE_TYPE.MARRY_MONSTER, Scene_marry_monster_entry)
Scene_mgr.register_scene_class(
	SCENE_TYPE.COPY
	, function (map_id)
		return Scene_team_copy(map_id, Scene_instance)
	end)
Scene_mgr.register_scene_class(
	SCENE_TYPE.TD
	, function (map_id)
		return Scene_team_copy(map_id, Scene_td, SCENE_STATUS.CLOSE)
	end)
Scene_mgr.register_scene_class(
	SCENE_TYPE.TD_EX
	, function (map_id)
		return Scene_team_copy(map_id, Scene_td_ex, SCENE_STATUS.CLOSE)
	end)

Scene_mgr.register_scene_class(
	SCENE_TYPE.LEVEL
	, function (map_id)
		return Scene_team_entry(map_id, Scene_level)
	end)
Scene_mgr.register_scene_class(
	SCENE_TYPE.MANOR_ROB
	, function (map_id)
		return Scene_team_entry(map_id, Scene_manor_rob)
	end)
Scene_mgr.register_scene_class(
	SCENE_TYPE.PERSONAL
	, function (map_id)
		return Scene_personal_copy(map_id, Scene_personal)
	end)
Scene_mgr.register_scene_class(
	SCENE_TYPE.CHESS
	, function (map_id)
		return Scene_team_entry(map_id, Scene_chess)
	end)
Scene_mgr.register_scene_class(
	SCENE_TYPE.MORE_KILL
	, function (map_id)
		return Scene_team_entry(map_id, Scene_more_kill)
	end)
Scene_mgr.register_scene_class(SCENE_TYPE.WORLD_WAR, Scene_world_war_entry)
Scene_mgr.register_scene_class(
	SCENE_TYPE.STORY
	, function (map_id)
		return Scene_single_entry(map_id, Scene_story)
	end)
Scene_mgr.register_scene_class(
	SCENE_TYPE.TOWER_EX
	, function (map_id)
		return Scene_tower_ex(map_id, "Scene_layer_ex")
	end)
Scene_mgr.register_scene_class(
	SCENE_TYPE.TOWER_RAGE
	, function (map_id)
		return Scene_tower_ex(map_id, "Scene_layer_rage")
	end)
Scene_mgr.register_scene_class(SCENE_TYPE.BATTLEFIELD, Scene_battlefield_entry)
Scene_mgr.register_scene_class(SCENE_TYPE.FACTION, Scene_faction_copy_ex)
Scene_mgr.register_scene_class(SCENE_TYPE.PVP_BATTLE, Scene_pvp_battle_entry)
Scene_mgr.register_scene_class(
	SCENE_TYPE.GOBANG
	, function (map_id)
		return Scene_team_entry(map_id, Scene_gobang)
	end)
Scene_mgr.register_scene_class(SCENE_TYPE.WILD_BOSS, Scene_wild_boss)
Scene_mgr.register_scene_class(SCENE_TYPE.SHEEP, Scene_sheep_entry)
Scene_mgr.register_scene_class(SCENE_TYPE.FISH, Scene_fish_entry)
Scene_mgr.register_scene_class(SCENE_TYPE.COMPETE, Scene_compete_copy)
