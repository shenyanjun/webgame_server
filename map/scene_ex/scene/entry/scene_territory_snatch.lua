--local debug_print = print
local debug_print = function() end
local territory_config = require("scene_ex.config.territory_config_loader")


-- 帮派领地争夺战
Scene_territory_snatch = oo.class(Scene_copy, "Scene_territory_snatch")

function Scene_territory_snatch:__init(map_id, instance_id)
	Scene_copy.__init(self, map_id)
	self.instance_id = instance_id
	self.attack_layer = 0	-- 进攻方所在的层
	self.defense_layer = 2	-- 防御方所在的层
	self.map_list = {}
	self.is_initial = false
	self.is_end	= nil		-- 是否已经结束战斗
	self.winner_side = 2	-- 胜利方，默认为防守方
	self.owner_list = {}	-- 进入人员列表
	self.enter_l = {}		-- 已进入的列表
	--防止已帮派副本ID相同，而加入的附加字符
	self.i_id = instance_id

	self.side_channal = {
		g_chat_channal_mgr:new_channal()
		, g_chat_channal_mgr:new_channal()
	}
end

function Scene_territory_snatch:get_score(obj)
	return 0
end

function Scene_territory_snatch:clone(instance_id)
	debug_print("Scene_territory_snatch:clone()", instance_id)
	local obj = Scene_territory_snatch(self.id, instance_id)
	obj.map_list = self.map_list
	return obj
end

function Scene_territory_snatch:reset_end_time(time)
	for k, instance in pairs(self.instance_list) do
		instance:reset_end_time(time)
	end
end

function Scene_territory_snatch:set_winner(side)
	self.winner_side = side
	for k, instance in pairs(self.instance_list) do
		instance:set_winner(side)
	end
end

function Scene_territory_snatch:instance()
	debug_print("Scene_territory_snatch:instance()", self.id)
	if self.is_initial then
		return
	end
	
	self.scene_layer_l = {}
	--self.map_list = {}
	self.instance_list = {}

	local config = territory_config.config[self.id]
	if not config or not config.scene_layer then
		debug_print("Scene_territory_snatch:not config or not config.scene_layer")
		return
	end

	for _, layer in pairs(config.scene_layer) do
		local map_id = layer.map
		table.insert(self.scene_layer_l, map_id)
		self.map_list[map_id] = self.map_list[map_id] or g_scene_config_mgr:load_map(map_id, layer.path)
		local map_obj = self.map_list[map_id]
		if not map_obj then
			debug_print("Scene_territory_snatch:SCENE_ERROR.E_NOT_ON_SCENE", map_id, layer.path)
			return SCENE_ERROR.E_NOT_ON_SCENE, nil
		end
		local instance = Scene_territory(self, self.id, map_id, self.instance_id, map_obj:clone(map_id))
		self.instance_list[map_id] = instance
		instance:instance()
	end
	
	self:attack_layer_increase()
	--self.attack_layer = 1
	debug_print("Scene_territory_snatch:instance()", self.id, self.attack_layer)
	self.is_initial = true
end

function Scene_territory_snatch:get_instance(scene_id)
	local instance_id = scene_id and scene_id[3]
	return instance_id and self.instance_list[instance_id]
end


function Scene_territory_snatch:push_current(obj)
	if not obj then
		return SCENE_ERROR.E_SCENE_CHANGE
	end
	local side = obj:get_side()
	local cur_layer = self.attack_layer
	if side == 2 then
		cur_layer = self.defense_layer
	end
	local map_id = self.scene_layer_l[cur_layer]
	if not map_id then
		return SCENE_ERROR.E_SCENE_CHANGE
	end
		
	local instance = self.instance_list[map_id]
	local obj_id = obj:get_id()
	if not instance or instance:get_obj(obj_id) or instance:is_door(obj_id) then
		return SCENE_ERROR.E_SCENE_CHANGE
	end
	
	return instance:carry_scene(obj, nil)
end

function Scene_territory_snatch:close()
	if self.instance_id then
		local instance_id = self.instance_id
		self.instance_id = nil
		
		for _, instance in pairs(self.instance_list) do
			instance:close()
		end
		
		g_scene_mgr_ex:unregister_instance(instance_id)
	end

	for _, id in ipairs(self.side_channal) do
		g_chat_channal_mgr:remove_channal(id)
	end
	self.side_channal = {}
end

function Scene_territory_snatch:carry_scene(obj, pos)
	debug_print("==>Scene_territory_snatch:carry_scene:")
	--local debug = Debug(g_debug_log)
	--debug:trace("Scene_territory_snatch:carry_scene")
	if not obj then
		return SCENE_ERROR.E_NOT_ON_SCENE, nil
	end
	
	local config = territory_config.config[self.id]
	if not config or self.is_end then
		return SCENE_ERROR.E_CYCLE_LIMIT, nil
	end

	local map_id = pos[1]
	local pos_new = pos[2]
	if config.scene_layer[self.attack_layer+1] and map_id == config.scene_layer[self.attack_layer+1].map then
		return SCENE_ERROR.E_NOT_KILL_BOSS, nil
	end

	local instance = self.instance_list[map_id]
	if not instance then
		local map_obj = self.map_list[map_id]
		if not map_obj then
			return SCENE_ERROR.E_NOT_ON_SCENE, nil
		end
		instance = Scene_territory(self, self.id, map_id, self.instance_id, map_obj:clone(map_id))
		self.instance_list[map_id] = instance
		instance:instance()
	end
	
	return self:push_scene(obj, pos)
end

function Scene_territory_snatch:push_scene(obj, pos)
	local map_id = pos[1]
	local pos_new = pos[2]
	local instance = self.instance_list[map_id]
	if not instance then
		return SCENE_ERROR.E_NOT_ON_SCENE, nil
	end

	local obj_id = obj:get_id()
	if not self.owner_list[obj_id] then
		local config = territory_config.config[self.id]
		local cycle_limit = config.limit and config.limit.cycle.number
		local con = obj:get_copy_con()
		if cycle_limit and con:get_count_copy(self.id) >= cycle_limit then
			return SCENE_ERROR.E_CYCLE_LIMIT, nil
		end
		con:add_count_copy(self.id)
		self.owner_list[obj_id] = true
		--
		f_multi_web_sql(string.format("insert into copy_into set copy_id=%d, char_id=%d, time=%d, char_name='%s'"
					, self.id
					, obj_id
					, ev.time
					, obj:get_name()))
	end
	
	self.enter_l[obj_id] = (self.enter_l[obj_id] or 0) + 1
	local e_code, error_describe = instance:carry_scene(obj, pos_new)
	if SCENE_ERROR.E_SUCCESS == e_code then
		local channal_id = self.side_channal[1]
		g_chat_channal_mgr:add_member(obj_id, channal_id)
	else
		self.enter_l[obj_id] = (self.enter_l[obj_id] or 0) - 1
	end
	return e_code, error_describe
end

-- 进攻层加1
function Scene_territory_snatch:attack_layer_increase()
	self.attack_layer = self.attack_layer + 1
	local config = territory_config.config[self.id]
	if self.attack_layer == 2 and config.broadcast then
		if config.broadcast.attack1 then
			g_chat_channal_mgr:message(self.side_channal[1], config.broadcast.attack1)
		end
		if config.broadcast.defense1 then
			g_chat_channal_mgr:message(self.side_channal[2], config.broadcast.defense1)
		end
	end
	if self.attack_layer > config.limit.success_layer.number then
		if self.attack_layer == 3 and config.broadcast then
			if config.broadcast.attack2 then
				g_chat_channal_mgr:message(self.side_channal[1], config.broadcast.attack2)
			end
			if config.broadcast.defense2 then
				g_chat_channal_mgr:message(self.side_channal[2], config.broadcast.defense2)
			end
		end
		self:attacker_win()
	else
		if config.scene_layer[self.attack_layer] then
			self:reset_end_time(config.scene_layer[self.attack_layer].timeout or 60)
			local instance = self.instance_list[config.scene_layer[self.attack_layer].map]
			local _ = instance and instance:set_update_wild(true)
		end
	end

	if config.scene_layer[self.attack_layer-1] then
		local instance = self.instance_list[config.scene_layer[self.attack_layer-1].map]
		local _ = instance and instance:set_update_wild(false)
	end
end

function Scene_territory_snatch:attacker_win()
	self:set_winner(1)
	self:to_end()
-- 测试用
	if g_faction_territory:get_owner_id() == "" then
		local config = territory_config.config[self.id]
		g_faction_territory:set_owner_id(self.i_id)
		local str = g_faction_territory:get_owner_name()
		local msg = {}
		local bd_str = str .. (config.broadcast.succeed)
		f_construct_content(msg, bd_str, 13)
		f_cmd_sysbd(msg)
		f_scene_info_log("snatch attacker_win, instance_id:%s", self.instance_id)
		local ret = {}
		ret.owner_id = self.i_id
		g_svsock_mgr:send_server_ex(COMMON_ID, 0, CMD_M2P_APPLICATION_WAR_OVER_C, ret)
	end
end
-- 
function Scene_territory_snatch:is_attacker(obj)
	return true
end

-- 得到进入点的位置
function Scene_territory_snatch:get_attack_layer_id()
	local config = territory_config.config[self.id]
	return config.scene_layer[self.attack_layer].map
end
--[[
function Scene_territory_snatch:get_attack_layer_entry()
	local config = territory_config.config[self.id]
	return config.scene_layer[self.attack_layer].entry
end
]]
function Scene_territory_snatch:get_attack_layer_entry()
	local config = territory_config.config[self.id]
	return config.entry[1][self:get_attack_layer_id()][2]
end

function Scene_territory_snatch:get_defense_layer_id()
	local config = territory_config.config[self.id]
	return config.scene_layer[self.attack_layer].map
end
--[[
function Scene_territory_snatch:get_defense_layer_entry()
	local config = territory_config.config[self.id]
	return config.scene_layer[self.defense_layer].entry
end
]]
function Scene_territory_snatch:get_defense_layer_entry()
	local config = territory_config.config[self.id]
	return config.entry[2][self:get_attack_layer_id()][2]
end

function Scene_territory_snatch:get_relive_pos(obj, type)
	local config = territory_config.config[self.id]
	if self:is_attacker(obj) then
		return config.relive[1 + (type or 0)]
	end

	return config.relive[2 + (type or 0)]
end

function Scene_territory_snatch:to_end()
	self.is_end = true
	for k, instance in pairs(self.instance_list) do
		instance:the_end(0)
	end
end

function Scene_territory_snatch:to_kick_out()
	for k, instance in pairs(self.instance_list) do
		instance:kick_out()
	end
end

function Scene_territory_snatch:to_close()
	for k, instance in pairs(self.instance_list) do
		instance:close()
	end
end

function Scene_territory_snatch:open_reward_scene(map_id)
	debug_print("Scene_territory_snatch:open_reward_scene()")
	local config = territory_config.config[self.id]
	local instance = self.instance_list[map_id]
	instance:reset_end_time(config.scene_layer[3].timeout)

	--self.instance_list[config.scene_layer[3].map].is_succeed = true
	if config.scene_layer[3].map == map_id then
		self.instance_list[config.scene_layer[3].map]:set_update_wild(true)
	end
end

function Scene_territory_snatch:obj_leave(obj_id)
	debug_print("Scene_territory_battle:obj_leave", obj_id)
	self.enter_l[obj_id] = self.enter_l[obj_id] - 1
	--if self.enter_l[obj_id] == 0 then
		--self.enter_l[obj_id] = nil
	--end
	if self.enter_l[obj_id] <= 0 then
		local side = self:is_attacker(g_obj_mgr:get_obj(obj_id)) and 1 or 2
		local channal_id = self.side_channal[side]
		g_chat_channal_mgr:del_member(obj_id, channal_id)
		--删除buff
		local obj = g_obj_mgr:get_obj(obj_id)
		f_del_impact(obj, 2003)
		f_del_impact(obj, 2004)
		f_del_impact(obj, 2005)
		f_del_impact(obj, 2006)
		f_del_impact(obj, 1506)
		f_del_impact(obj, 1507)
	end

end