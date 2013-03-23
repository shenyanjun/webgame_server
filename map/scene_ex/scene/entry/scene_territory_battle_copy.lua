--local debug_print = print
local debug_print = function() end
local territory_config = require("scene_ex.config.territory_config_loader")

--帮派领地攻防战副本管理
Scene_territory_battle_copy = oo.class(Scene_copy, "Scene_territory_battle_copy")

	
function Scene_territory_battle_copy:get_self_config()
	return territory_config.config[self.id]
end

--副本出口
function Scene_territory_battle_copy:get_home_carry(obj)
	local config = self:get_self_config()
	local home_carry = config and config.home
	if not home_carry or not home_carry.id or not home_carry.pos or not home_carry.pos[1] or not home_carry.pos[2] then
		return nil, nil
	end
	return home_carry.id, home_carry.pos
end

--获取副本实例ID
function Scene_territory_battle_copy:get_instance_id(obj)
	local instance_id = g_faction_territory:get_owner_id()
	if instance_id == "" then
		instance_id = nil
	else
		instance_id = "territory_" .. instance_id
	end
	return instance_id, instance_id and SCENE_ERROR.E_SUCCESS or SCENE_ERROR.E_INVALID_FACTION
end


--副本创建权限检查
function Scene_territory_battle_copy:check_create_access(obj)
	debug_print("Scene_territory_battle_copy:check_create_access()", SCENE_ERROR.E_NOT_OPNE)
	local e_code = SCENE_ERROR.E_NOT_OPNE
	return e_code, {}
end

--副本进入权限检查
function Scene_territory_battle_copy:check_entry_access(obj)
	debug_print("Scene_territory_battle_copy:check_entry_access()")
	if self.status ~= SCENE_STATUS.OPEN then
		return SCENE_ERROR.E_SCENE_CLOSE, nil
	end

	local owner = g_faction_territory:get_owner_id()
	if owner == "" then
		return SCENE_ERROR.E_SCENE_CLOSE, nil
	end

	local team_id = obj:get_team()
	local team_obj = team_id and g_team_mgr:get_team_obj(team_id)
	if team_obj then
		return SCENE_ERROR.E_HAS_TEAM
	end

	local faction = g_faction_mgr:get_faction_by_cid(obj:get_id())
	local faction_id = faction and faction:get_faction_id()
	if faction_id == owner then
		return SCENE_ERROR.E_SUCCESS, nil
	end

	local is_attacker = self:is_attacker(obj)
	-- 测试用
	if ev.time < self.time_after_60s and (is_attacker and not App_filter:is_on_application(obj:get_id())) then
		return SCENE_ERROR.E_NOT_TERRITOR_APPLY, nil
	end

	local config = self:get_self_config()
	if not config then
		return SCENE_ERROR.E_SCENE_CLOSE, nil
	end

	local level_limit = config.limit and config.limit.level
	if level_limit then
		local level = obj:get_level()
		if (level_limit.min and level < level_limit.min) or (level_limit.max and level_limit.max < level) then
			return SCENE_ERROR.E_LEVEL_LIMIT, nil
		end
	end	

	return SCENE_ERROR.E_SUCCESS, nil
end

--创建副本实例
function Scene_territory_battle_copy:create_instance(instance_id, obj)
	debug_print("====> territory_each_copy:clone", self.id, instance_id)
	local config = self:get_self_config()
	--local str = g_faction_mgr:get_faction_by_fid(instance_id):get_faction_name()
	local msg = {}
	local bd_str = config.broadcast and config.broadcast.open
	f_construct_content(msg, bd_str, 13)
	f_cmd_sysbd(msg)

	return self.territory_each_copy:clone(instance_id)
end


function Scene_territory_battle_copy:instance()
	debug_print("====> Scene_territory_battle_copy:instance()", self.id)
	self.territory_each_copy = Scene_territory_battle(self.id)
	self.territory_each_copy:instance()
end

function Scene_territory_battle_copy:change_pos(obj, pos)
	local instance_id = self:get_instance_id(obj)
	local instance = self.instance_list[instance_id]
	return instance and instance:change_pos(obj, pos)
end
--[[
--攻方进入点位置
function Scene_territory_battle_copy:get_attack_layer_pos(obj)
	local config = self:get_self_config()
	return config.entry[1][1][1], config.entry[1][1][2]
end

--防方进入点位置
function Scene_territory_battle_copy:get_defense_layer_pos(obj)
	local config = self:get_self_config()
	return config.entry[2][1][1], config.entry[2][1][2]
end
]]

function Scene_territory_battle_copy:get_attack_layer_pos(obj)
	local instance_id = self:get_instance_id(obj)
	local instance = self.instance_list[instance_id]
	return instance and instance:get_attack_layer_id(), instance and instance:get_attack_layer_entry()
end

function Scene_territory_battle_copy:get_defense_layer_pos(obj)
	local instance_id = self:get_instance_id(obj)
	local instance = self.instance_list[instance_id]
	return instance and instance:get_defense_layer_id(), instance and instance:get_defense_layer_entry()
end

function Scene_territory_battle_copy:get_instance(scene_id)
	local instance_id = scene_id and scene_id[2]
	local instance = instance_id and self.instance_list[instance_id]
	return instance and instance:get_instance(scene_id)
end

function Scene_territory_battle_copy:is_attacker(obj)
	local instance_id = self:get_instance_id(obj)
	local instance = self.instance_list[instance_id]
	return instance and instance:is_attacker(obj)
end

function Scene_territory_battle_copy:open_event(args)
	debug_print("Scene_territory_battle_copy:open_event")
	local owner_id = g_faction_territory:get_owner_id()
	if owner_id == "" then	-- 未被占领不用开启
		return 
	end

	self.status = SCENE_STATUS.OPEN
	self.time_after_60s = ev.time + 60
	local instance_id = self:get_instance_id(nil)
	local instance = self:create_instance(instance_id, nil)
	self.instance_list[instance_id] = instance
	g_scene_mgr_ex:register_instance(instance_id, self)
	instance:instance()
	f_scene_info_log("open_faction_battle_copy instance_id:%s", instance_id)
	local ret = {}
	ret.type = 1
	g_svsock_mgr:send_server_ex(COMMON_ID, 0, CMD_M2P_APPLICATION_WAR_C, ret)
end

function Scene_territory_battle_copy:close_event(args)
	debug_print("Scene_territory_battle_copy:close_event")
	self.status = SCENE_STATUS.CLOSE
end

--攻防战最后结果，取结果记录，side:1为攻方，2为防方，page:第几页
function Scene_territory_battle_copy:get_battle_score(side, page)
	local instance_id = self:get_instance_id(nil)
	return self.instance_list[instance_id] and self.instance_list[instance_id]:get_cache(side, page)
end

--攻防战过程中取战况
function Scene_territory_battle_copy:get_battle_info(char_id)
	local instance_id = self:get_instance_id(nil)
	return self.instance_list[instance_id] and self.instance_list[instance_id]:get_battle_info(char_id)
end

--攻防战过程中取战况
function Scene_territory_battle_copy:get_battle_info_page(side, page)
	local instance_id = self:get_instance_id(nil)
	return self.instance_list[instance_id] and self.instance_list[instance_id]:get_battle_cache(side, page)
end