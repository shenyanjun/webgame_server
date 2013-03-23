local territory_config = require("scene_ex.config.territory_config_loader")

--帮派领地争夺战副本管理
Scene_territory_copy = oo.class(Scene_faction_copy, "Scene_territory_copy")

--创建副本实例
function Scene_territory_copy:create_instance(instance_id, obj)
	g_faction_mgr:set_fb(obj:get_id(), self.id)
--[[	
	local pkt = {}
	pkt.faction_id = instance_id
	pkt.switch_flag = 1
	pkt.scene_id = self.id
	g_faction_mgr:switch_fb(pkt)
	]]
	local config = self:get_self_config()
	local str = g_faction_mgr:get_faction_by_fid(instance_id):get_faction_name()
	local msg = {}
	local bd_str = str .. (config.broadcast.open)
	f_construct_content(msg, bd_str, 13)
	f_cmd_sysbd(msg)

	-- 争夺战扣帮派资金
	local pkt = {}
	pkt.flag = 8
	pkt.param = -config.limit.cost_faction_gold.gold
	pkt.type = 8
	g_faction_mgr:update_faction_level(obj:get_id(), pkt)
	f_scene_info_log("create_instance snatch instance_id:%s", instance_id)
	return self.territory_each_copy:clone(instance_id)
end

function Scene_territory_copy:get_self_config()
	return territory_config.config[self.id]
end

function Scene_territory_copy:get_self_limit_config()
	local config = self:get_self_config()
	return config and config.limit
end


function Scene_territory_copy:get_instance(scene_id)
	local instance_id = scene_id and scene_id[2]
	local instance = instance_id and self.instance_list[instance_id]
	return instance and instance:get_instance(scene_id)
end

function Scene_territory_copy:instance()
	self.territory_each_copy = Scene_territory_snatch(self.id)
	self.territory_each_copy:instance()
end
--[[
function Scene_territory_copy:carry_scene(obj, pos)
	local instance_id = self:get_instance_id(obj)
	return self.i_l[instance_id]:carry_scene()
	return Scene_copy.carry_scene(self, obj, pos)
end
]]

function Scene_territory_copy:get_attack_layer_pos(obj)
	local instance_id = self:get_instance_id(obj)
	local instance = self.instance_list[instance_id]
	return instance and instance:get_attack_layer_id(), instance and instance:get_attack_layer_entry()
end

function Scene_territory_copy:get_defense_layer_pos(obj)
	local instance_id = self:get_instance_id(obj)
	local instance = self.instance_list[instance_id]
	return instance and instance:get_defense_layer_id(), instance and instance:get_defense_layer_entry()
end

function Scene_territory_copy:is_attacker(obj)
--[[
	local instance_id = self:get_instance_id(obj)
	local instance = self.instance_list[instance_id]
	return instance and instance:is_attacker(obj)
	]]
	return true
end


function Scene_territory_copy:check_create_access(obj)
	local obj_id = obj:get_id()
	local faction = g_faction_mgr:get_faction_by_cid(obj_id)
	local faction_id = faction and faction:get_faction_id()
	if not faction_id then
		return SCENE_ERROR.E_INVALID_FACTION, nil 
	end

	local owner_id = g_faction_territory:get_owner_id()
	if owner_id ~= "" then
		return SCENE_ERROR.E_HAD_BE_OCCUPY, nil
	end

	local money = faction:get_money()
	local config = self:get_self_config()
	
	if money < config.limit.cost_faction_gold.gold then
		return SCENE_ERROR.E_LACK_FACTION_MONEY, nil 
	end

	--
	if g_scene_mgr_ex:exists_instance(faction_id) then
		return SCENE_ERROR.E_EXISTS_COPY, nil
	end
	
	if 0 ~= faction:get_dissolve_flag() then
		return SCENE_ERROR.E_FACTION_DISSOLVE, nil
	end

	local config = self:get_self_config()
	if not config then
		return SCENE_ERROR.E_INVALID_CONFIG, nil
	end

	local limit = config.limit
	if not limit then
		return SCENE_ERROR.E_INVALID_CONFIG, nil
	end

	local faction_level_limit = limit.faction_level
	if faction_level_limit then
		local faction_level = faction:get_level()
		if (faction_level_limit.min and faction_level < faction_level_limit.min)
			or (faction_level_limit.max and faction_level_limit.max < faction_level) then
			return SCENE_ERROR.E_FACTION_LEVEL_LIMIT, nil
		end
	end

	if obj_id ~= faction:get_factioner_id() then
		return SCENE_ERROR.E_INVALID_FACTIONER, nil
	end

	local cycle_limit = limit.cycle and limit.cycle.number
	
	local con = obj:get_copy_con()
	if cycle_limit
		and (g_faction_mgr:get_fb(obj_id, self.id) >= cycle_limit 
				or (not con) or con:get_count_copy(self.id) >= cycle_limit) then
		return SCENE_ERROR.E_CYCLE_LIMIT, nil
	end

	local error_l = {}
	local e_code = SCENE_ERROR.E_SUCCESS

	local human = limit.human
	if human.min and faction:get_member_count() < human.min then
		e_code = SCENE_ERROR.E_SCENE_CHANGE
		table.insert(error_l, SCENE_ERROR.E_FACTION_HUMAN_MIN)
	end
	
	local level_limit = limit.level
	if level_limit then
		local level = obj:get_level()
		if (level_limit.min and level < level_limit.min) or (level_limit.max and level_limit.max < level) then
			e_code = SCENE_ERROR.E_SCENE_CHANGE
			table.insert(error_l, SCENE_ERROR.E_LEVEL_LIMIT)
		end
	end
	return e_code, error_l
end
