local copy_config = require("scene_ex.config.compete_config_loader")

local contraband_list = {
	[101030000021] = true
	, [101030000020] = true
	
	, [101030000121] = true
	, [101030000120] = true
	
	, [101030000221] = true
	, [101030000220] = true
	
	, [101030000321] = true
	, [101030000320] = true
	
	, [101030000421] = true
	, [101030000420] = true
	
	, [101030000521] = true
	, [101030000520] = true
	
	, [101030000621] = true
	, [101030000620] = true
	
	, [101030000721] = true
	, [101030000720] = true
	
	, [101030000821] = true
	, [101030000820] = true
	
	, [101030000921] = true
	, [101030000920] = true
	
	, [101030001021] = true
	, [101030001020] = true
}

-- 离线竞技副本 
Scene_compete = oo.class(Scene_instance, "Scene_compete")


function Scene_compete:__init(map_id, instance_id, map_obj)
	Scene_instance.__init(self, map_id, instance_id, map_obj)

	self.ghost_id = nil
	self.be_challenge_id = nil
	self.is_end = nil
end


function Scene_compete:get_self_config()
	return copy_config.config[self.id]
end

function Scene_compete:get_self_limit_config()
	return copy_config.config[self.id].init.limit
end

--副本出口
function Scene_compete:get_home_carry(obj)
	local config = self:get_self_config()
	local home_carry = config.init.home
	if not home_carry or not home_carry.id
		or not home_carry.pos or not home_carry.pos[1] or not home_carry.pos[2] then
		return nil, nil
	end
	return home_carry.id, home_carry.pos
end

function Scene_compete:instance(args)
	--print("Scene_compete:instance(args)", j_e(args))
	self.be_challenge_id = args.be_challenge_id
	local config = self:get_self_limit_config()
	self.end_time = ev.time + config.time

	self.obj_mgr = Scene_obj_mgr_ex(Scene_monster_layout(self.key, false), Scene_monster_copy_mgr())
	self.obj_mgr:instance(self.map_obj:get_w(), self.map_obj:get_h())

	--
	local config = self:get_self_config()
	local ghost = g_obj_mgr:create_ghost(self.be_challenge_id, config.init.pos)
	self.ghost_id = ghost:get_id()
	ghost:load()
	ghost:set_pos(config.init.pos)
	--
	ghost:set_scene(self.key)
	--print("key", j_e(self.key))
	--self:enter_scene(self.ghost)
end

function Scene_compete:on_obj_enter(obj)
	local obj_id = obj:get_id()
	if obj:get_type() == OBJ_TYPE_HUMAN then
		if self.not_human then
			self.not_human = false
		end 
		--
		g_scene_mgr_ex:register_event(EVENT_SET.EVENT_KILL_GHOST, obj_id, self, self.kill_ghost_event)
		local ghost = g_obj_mgr:get_obj(self.ghost_id)
		local pkt = ghost:get_ghost_info()
		g_cltsock_mgr:send_client(obj_id, CMD_MAP_OFFLINE_COMPETE_GHOST_INFO_S, pkt)
		--print("CMD_MAP_OFFLINE_COMPETE_GHOST_INFO_S", j_e(pkt))
	end
end

function Scene_compete:on_obj_leave(obj)
	local obj_id = obj:get_id()
	if obj:get_type() == OBJ_TYPE_HUMAN then
		g_scene_mgr_ex:unregister_event(EVENT_SET.EVENT_KILL_GHOST, obj_id)
		--退出场景就当输
		if not self.is_end then
			g_svsock_mgr:send_server_ex(COMMON_ID, obj_id, CMD_M2C_OFFLINE_COMPETE_FINISH_C, {winner_id = self.be_challenge_id, loser_id = obj_id})
			self.is_end = true
		end
		self:clean_ghost()
		self.end_time = ev.time
	--elseif obj:get_type() == OBJ_TYPE_MONSTER then
		
	end
end

function Scene_compete:on_timer(tm)
	
	if self.end_time and self.end_time <= ev.time then
		self:close()
	end

	--self.obj_mgr:on_timer(tm)
end

function Scene_compete:get_obj(id)
	if id == self.ghost_id then
		local obj = g_obj_mgr:get_obj(id)
		return obj
	end
	return Scene_instance.get_obj(self, id)
end

function Scene_compete:die_event(args)
	--print("Scene_compete:die_event", j_e(args))
	self.is_end = true
	local killer_id = args.killer_id
	local obj_id = args.char_id
	local obj = self:get_obj(obj_id)
	if obj then
		g_cltsock_mgr:send_client(obj_id, CMD_MAP_OFFLINE_COMPETE_GHOST_LEAVE_S, {id = killer_id})
		g_svsock_mgr:send_server_ex(COMMON_ID, obj_id, CMD_M2C_OFFLINE_COMPETE_FINISH_C, {winner_id = self.be_challenge_id, loser_id = obj_id})
	end
end

function Scene_compete:kill_ghost_event(ghost_id, killer_id, id)
	--print("Scene_compete:", ghost_id, killer_id, id)
	self.is_end = true
	g_cltsock_mgr:send_client(killer_id, CMD_MAP_OFFLINE_COMPETE_GHOST_LEAVE_S, {id = id})
	g_svsock_mgr:send_server_ex(COMMON_ID, killer_id, CMD_M2C_OFFLINE_COMPETE_FINISH_C, {winner_id = killer_id, loser_id = ghost_id})
end


function Scene_compete:clean_ghost()
	g_obj_mgr:del_obj(self.ghost_id)
	self.ghost_id = nil

end

function Scene_compete:carry_scene(obj, pos)
	local config = self:get_self_config()
	return Scene_instance.carry_scene(self, obj, config.init.entry)
end

function Scene_compete:can_use(item_id)
	if contraband_list[item_id] then
		return false
	end
	return true
end