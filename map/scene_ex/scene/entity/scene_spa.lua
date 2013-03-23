Scene_spa = oo.class(Scene, "Scene_spa")

local _f_s_c = require("scene_ex.config.faction_spa_loader")
local spa_config = require("scene_ex.config.spa_config_loader")

function Scene_spa:__init(map_id)
	Scene.__init(self, map_id)
	
	self.buff_type = 3
	self.vip_type = HUMAN_ADDITION.sprint_exp
	self.exp_factor = 20
	self.reward_level_limit = 30
	self.end_time = 0
	self.status = SCENE_STATUS.CLOSE
	self.spa_monster = {}	--∞Ô≈…¡Óπ÷
	self.spa_entry = {}		-- π”√µ⁄º∏∏ˆ∞Ô≈…¡Ó
end

function Scene_spa:instance()
	self.broadcast_timer = Broadcast_timer()
	self.exp_reward = Exp_reward()
	self.timer_queue = Timer_queue()
	self.obj_mgr:instance(self.map_obj:get_w(), self.map_obj:get_h())
	self:on_new_day()
end

function Scene_spa:notify_open(info, args)
	Scene.notify_open(self, info, args)
	self.end_time = info.end_time
	self.status = SCENE_STATUS.OPEN
	self.exp_reward:celan_faction_append()
	for k, v in pairs(self.spa_monster) do 
		v:leave()
	end
	self.spa_monster = {}
	self.spa_entry = {}
end

function Scene_spa:notify_close()
	Scene.notify_close(self, info, args)
	self.status = SCENE_STATUS.CLOSE
	self.exp_reward:celan_faction_append()
	for k, v in pairs(self.spa_monster) do 
		v:leave()
	end
	self.spa_monster = {}
	self.spa_entry = {}
end

function Scene_spa:can_carry(obj)
	return SCENE_ERROR.E_CARRY
end

function Scene_spa:add_addition(obj_id, char_id)
	local obj_addition = self.exp_reward:get_addition(obj_id)
	local char_addition = self.exp_reward:get_addition(char_id)
	local addition_limit = self.exp_reward:get_addition_limit()

	if obj_addition >= addition_limit then
		return 21009
	end

	if char_addition >= addition_limit then
		return 21008
	end

	self.exp_reward:add_addition(obj_id, 1)
	self.exp_reward:add_addition(char_id, 1)
	
	local pkt = {}
	pkt.type = 1
	pkt.param_l = {['obj_id'] = obj_id, ['des_id'] = char_id}
	self:send_screen(obj_id, CMD_MAP_PLAYER_OPERATE_SYN, pkt, true)
	--
	local args = {}
	args.type = 2
	g_event_mgr:notify_event(EVENT_SET.EVENT_WASH_COUNT, obj_id, args)
	args.type = 1
	g_event_mgr:notify_event(EVENT_SET.EVENT_WASH_COUNT, char_id, args)
	--
	local new_pkt = {}
	local faction = g_faction_mgr:get_faction_by_cid(obj_id)
	local faction_id = faction and faction:get_faction_id()
	new_pkt.id = faction_id and self.spa_entry[faction_id] or 0
	new_pkt.addition = self.exp_reward:get_soap_and_faction_addition(obj_id)
	new_pkt.remain = self.exp_reward:get_addition_limit_remain(obj_id)
	g_cltsock_mgr:send_client(obj_id, CMD_TERRITORY_SPA_HAD_USED_S, new_pkt)

	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	local faction_id = faction and faction:get_faction_id()
	new_pkt.id = faction_id and self.spa_entry[faction_id] or 0
	new_pkt.addition = self.exp_reward:get_soap_and_faction_addition(char_id)
	new_pkt.remain = self.exp_reward:get_addition_limit_remain(char_id)
	g_cltsock_mgr:send_client(char_id, CMD_TERRITORY_SPA_HAD_USED_S, new_pkt)

	return SCENE_ERROR.E_SUCCESS
end

function Scene_spa:login_scene(obj, pos)
	return self:push_scene(obj, spa_config.config[self.id].entry)
end

function Scene_spa:get_last_time(obj)
	return math.max(self.end_time - ev.time, 0)
end

function Scene_spa:get_limit()
	return spa_config.config[self.id].limit
end

function Scene_spa:exp_reward_config(today)
	local config = spa_config.config[self.id]
	return config and config.day_list and config.day_list[today.wday]
end

function Scene_spa:notify_config(today)
	local config = spa_config.config[self.id]
	return config and config.notify
end

function Scene_spa:on_timer(tm)
	local now_time = ev.time
	
	self.obj_mgr:on_timer(tm)
	
	if self.tomorrow <= now_time then
		self:on_new_day()
	end
	
	self.timer_queue:exec(now_time)
	
	self.broadcast_timer:on_timer()
	self.exp_reward:try_reward(now_time, self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN):get_obj_list())
end

--»°Œ¬»™∞Ô≈…¡Ó–≈œ¢
function Scene_spa:get_faction_append_info()
	return _f_s_c._faction_spa_append
end

-- π”√Œ¬»™∞Ô≈…¡Ó
function Scene_spa:use_faction_append(char_id, entry_id)
	--print("Scene_spa:use_faction_append()", char_id, entry_id)
	local obj = g_obj_mgr:get_obj(char_id)
	if obj == nil then
		return -1
	end
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	local faction_id = faction and faction:get_faction_id()
	if faction_id == nil then
		return 20683
	end

	if _f_s_c._faction_spa_append[entry_id][2] >= 90 then
		if App_filter:get_faction_id() ~= faction_id then
			return 20688
		end
	elseif faction:get_level() < _f_s_c._faction_spa_append[entry_id][2] then
		return 20684
	end

	if faction:get_money() < _f_s_c._faction_spa_append[entry_id][3] then
		return 20685
	end

	--
	if self.exp_reward:get_faction_append(faction_id) * 100 >= _f_s_c._faction_spa_append[entry_id][1] then
		return 20687
	end
	--ø€Õ≠±“
	local need_gold = _f_s_c._faction_spa_append[entry_id][4]
	if need_gold > 0 then
		local pack_con = obj:get_pack_con()
		local money_list = {}
		money_list[MoneyType.GIFT_GOLD] = need_gold
		local src_log = {["type"] = MONEY_SOURCE.USE_FACTION_SPA}
		local ret_code = pack_con:dec_money_l_inter_face(money_list, src_log, 1)
		if ret_code ~= 0 then
			ret_code = ret_code == 43067 and -1 or ret_code
			return ret_code
		end
	end

	-- ø€∞Ô≈…◊ Ω
	local pkt = {}
	pkt.flag = 8
	pkt.param = -_f_s_c._faction_spa_append[entry_id][3]
	pkt.type = 9
	g_faction_mgr:update_faction_level(char_id, pkt)

	--
	self.exp_reward:set_faction_append(faction_id, _f_s_c._faction_spa_append[entry_id][1] / 100)
	--
	local obj_monster = g_obj_mgr:create_monster(_f_s_c._faction_spa_append[entry_id][5], obj:get_pos(), self.key)
	obj_monster:set_owner_faction_name(faction:get_faction_name())
	if obj_monster and SCENE_ERROR.E_SUCCESS == self:enter_scene(obj_monster) then
		if self.spa_monster[faction_id] then 
			self.spa_monster[faction_id]:leave()
		end
		self.spa_monster[faction_id] = obj_monster
		self.spa_entry[faction_id] = entry_id
		self:broadcast(obj, entry_id)
	end

	return 0
end

--Õ®÷™∞Ô≈…≥…‘±“— π”√Œ¬»™∞Ô≈…¡Ó
function Scene_spa:notify_faction_append(faction_id, entry_id)
	local obj_list = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN):get_obj_list() or {}
	local new_pkt = {}
	new_pkt.id = entry_id
	for obj_id, _ in pairs(obj_list) do
		local faction = g_faction_mgr:get_faction_by_cid(obj_id)
		local my_faction_id = faction and faction:get_faction_id()
		if faction_id == my_faction_id then
			new_pkt.addition = self.exp_reward:get_soap_and_faction_addition(obj_id)
			new_pkt.remain = self.exp_reward:get_addition_limit_remain(obj_id)
			g_cltsock_mgr:send_client(obj_id, CMD_TERRITORY_SPA_HAD_USED_S, new_pkt)
		end
	end
end

function Scene_spa:on_obj_enter(obj)
	local obj_id = obj:get_id()
	local faction = g_faction_mgr:get_faction_by_cid(obj_id)
	local faction_id = faction and faction:get_faction_id()
	--if faction_id and self.spa_monster[faction_id] then 
		local new_pkt = {}
		new_pkt.id = faction_id and self.spa_entry[faction_id] or 0
		new_pkt.addition = self.exp_reward:get_soap_and_faction_addition(obj_id)
		new_pkt.remain = self.exp_reward:get_addition_limit_remain(obj_id)
		g_cltsock_mgr:send_client(obj:get_id(), CMD_TERRITORY_SPA_HAD_USED_S, new_pkt)
	--end
end

--’ŸªΩº™œÈŒÔπ„≤•
function Scene_spa:broadcast(obj, entry_id)
	if not obj then return end
	local msg = {}
	f_construct_content(msg, obj:get_name(), 53)
	f_construct_content(msg, f_get_string(1610), 12)
	f_construct_content(msg, self:get_name(), 25)
	f_construct_content(msg, f_get_string(1611), 12)
	f_construct_content(msg, _f_s_c._faction_spa_append[entry_id][6], 22)
	f_construct_content(msg, f_get_string(1612), 12)

	local pkt = {}
	pkt.msg = msg
	pkt.bdc_type = 4
	pkt.msg_type = 5
	g_svsock_mgr:send_server_ex(WORLD_ID, obj:get_id(), CMD_C2W_FACTION_BROADCAST_S, pkt)
end