local more_kill_config = require("scene_ex.config.more_kill_loader")
local _random = crypto.random

Scene_more_kill = oo.class(Scene_instance, "Scene_more_kill")
function Scene_more_kill:__init(map_id, instance_id, map_obj)
	Scene_instance.__init(self, map_id, instance_id, map_obj)
	

	self.char_id = nil
	self.is_success = false
	self.close_time = nil
	self.start_time = ev.time
	self.check_time = ev.time
	self.check_boss_time = ev.time + 10
	
	self.wild = nil				-- 刷怪配置
	self.monster_to_area = {}
	self.monster_occ_in = {}	-- 用于过滤副本外队员杀怪
	self.kill_boss_cnt = 0
	self.kill_monster_cnt = 0
	self.kill_count	= 0			--连斩计数
	self.kill_count_max	= 0		--连斩最大记录计数
	self.kill_time = ev.time	--连斩计时
	self.kill_in = 0			--在多少秒杀死怪算连斩
	--buff
	self.transport_count = 0
	self.transport_use_cnt = 0	--使用次数
	self.refresh_count = 0
	self.refresh_use_cnt = 0	--刷新使用次数
	self.magic_buff = _random(0, 5)
	self.magic_buff_time = ev.time + 60
end


function Scene_more_kill:get_self_config()
	return more_kill_config.config[self.id]
end

function Scene_more_kill:get_self_limit_config()
	return self:get_self_config().init.limit
end

--副本出口
function Scene_more_kill:get_home_carry(obj)
	local config = self:get_self_config()
	local home_carry = config and config.init.home
	if not home_carry or not home_carry.id
		or not home_carry.pos or not home_carry.pos[1] or not home_carry.pos[2] then
		return nil, nil
	end
	return home_carry.id, home_carry.pos
end

function Scene_more_kill:on_timer(tm)
	local now = ev.time
	if (self.end_time and self.end_time <= now) then

		self:close()
		return
	end

	if ev.time >= self.check_time then
		--[[
		con = self.obj_mgr:get_obj_con(OBJ_TYPE_MONSTER)
		if con == nil or table.is_empty(con:get_obj_list()) then
			
		end
		]]
		self:create_wild()
		local config = self:get_self_config()
		self.check_time = ev.time + config.wild_monster_time
	end
	if ev.time >= self.check_boss_time then
		self:create_wild(16)
		self.check_boss_time = ev.time + 10
	end
	if ev.time >= self.magic_buff_time and self.char_id ~= nil then
		local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
		local enter_list = con and con:get_obj_list()
		if enter_list[self.char_id] ~= nil then
			local obj = g_obj_mgr:get_obj(self.char_id)
			local impact_con = obj:get_impact_con()
			impact_con:del_impact(IMPACT_OBJ_3501 + self.magic_buff)
			local buff_id = nil
			for i=1, 20 do
				buff_id = _random(0, 5)
				if buff_id ~= self.magic_buff then
					self.magic_buff = buff_id
					break
				end
			end
		
			local str_impact = string.format("Impact_350%d", self.magic_buff + 1)
			local impact_o = _G[str_impact](self.char_id)
			local config = self:get_self_config()
			impact_o:set_count(59)  
			local param = {}
			param.per = 0
			param.val = config.buff.magic.factor
			param.type = IMPACT_TYPE.JIN + self.magic_buff
			impact_o:effect(param)
		
			self.magic_buff_time = ev.time + 60
			self:update_client()
		end
	end

	self.obj_mgr:on_timer(tm)
end

function Scene_more_kill:create_wild(area)
	
	for k, v in ipairs(self.wild) do
		if area == nil or area == v.create.area then
			local entry = v.create.item[v.step]
			while entry ~= nil and v.live < v.create.live_size do
				local size = math.min(v.create.live_size - v.live, v.remain)
				self:create_monster(v.create.area, entry.id, size, k)
				v.live = v.live + size
				v.remain = v.remain - size
				if v.remain <=0 then
					v.step = v.step + 1
					entry = v.create.item[v.step]
					v.remain = entry and entry.number or 0
				end
			end
		end
	end

end

function Scene_more_kill:create_monster(area, monster_id, size, k)
	for i = 1, size do
		local pos = self.map_obj:find_space(area, 20)
		if pos then
			local obj = g_obj_mgr:create_monster(monster_id, pos, self.key)
			if obj and SCENE_ERROR.E_SUCCESS == self:enter_scene(obj) then
				self.monster_to_area[obj:get_id()] = k
				self.monster_occ_in[monster_id] = 1
			end
		end
	end
end

function Scene_more_kill:instance(args)
	--print("Scene_more_kill:instance()")
	local config = self:get_self_config()
	self.end_time = ev.time + config.init.limit.time
	self.start_time = ev.time
	self.obj_mgr:instance(self.map_obj:get_w(), self.map_obj:get_h())
	--
	local level = args.obj:get_level()
	local wild = nil
	self.monster_level = #config.wild
	for _, v in ipairs(config.wild or {}) do
		if level >= v[1] then
			wild = v[2]
			break
		end
		self.monster_level = self.monster_level - 1
	end
	if wild == nil then
		wild = config.wild[#config.wild][2]
		self.monster_level = 1
	end
	self.wild = {}
	for k, v in ipairs(wild or {}) do
		self.wild[k] = {}
		self.wild[k].create = v
		self.wild[k].remain = v.item[1].number
		self.wild[k].step	= 1
		self.wild[k].live	= 0
	end
	self:create_wild()
end

function Scene_more_kill:on_obj_enter(obj)
	Scene_instance.on_obj_enter(self, obj)

	if obj:get_type() == OBJ_TYPE_HUMAN then
		self.char_id = obj:get_id()
		self.char_name = obj:get_name()
		g_scene_mgr_ex:register_event(EVENT_SET.EVENT_KILL_MONSTER, self.char_id, self, self.kill_monster_event)
		--
		local config = self:get_self_config()
		local str_impact = string.format("Impact_350%d", self.magic_buff + 1)
		local impact_o = _G[str_impact](self.char_id)
		impact_o:set_count(self.magic_buff_time - ev.time - 2)  
		local param = {}
		param.per = 0
		param.val = config.buff.magic.factor
		param.type = IMPACT_TYPE.JIN + self.magic_buff
		impact_o:effect(param)
		--
		self:update_client()
	end
end

function Scene_more_kill:on_obj_leave(obj)
	Scene_instance.on_obj_leave(self, obj)
	
	if obj:get_type() == OBJ_TYPE_MONSTER then
		local k = self.monster_to_area[obj:get_id()]
		if k ~= nil and self.wild[k] ~= nil then
			self.wild[k].live = self.wild[k].live - 1
		end
	elseif obj:get_type() == OBJ_TYPE_HUMAN then
		local impact_con = obj:get_impact_con()
		g_scene_mgr_ex:unregister_event(EVENT_SET.EVENT_KILL_MONSTER, obj:get_id())
		impact_con:del_impact(IMPACT_OBJ_3501)
		impact_con:del_impact(IMPACT_OBJ_3502)
		impact_con:del_impact(IMPACT_OBJ_3503)
		impact_con:del_impact(IMPACT_OBJ_3504)
		impact_con:del_impact(IMPACT_OBJ_3505)
	end
end

function Scene_more_kill:kill_monster_event(monster_occ, obj_id)
	if self.monster_occ_in[monster_occ] == nil then
		return
	end

	if monster_occ >= 5000 and monster_occ < 6000 then
		self.kill_boss_cnt = self.kill_boss_cnt + 1
	else
		self.kill_monster_cnt = self.kill_monster_cnt + 1
	end

	local config = self:get_self_config()
	local kill_count_config = config.kill_count
	if self.kill_time + self.kill_in >= ev.time then
		self.kill_count = self.kill_count + 1
		self.kill_time = ev.time
		for _, v in ipairs(kill_count_config) do
			if self.kill_count >= v[1] then
				self.kill_in = v[2]
				break
			end
		end
		if self.kill_count > self.kill_count_max then
			self.kill_count_max = self.kill_count
		end
	else
		self.kill_count = 1
		self.kill_time = ev.time
		self.kill_in = kill_count_config[#kill_count_config][2]
	end

	--buff
	local total_kill = self.kill_boss_cnt + self.kill_monster_cnt
	--print("more kill", self.kill_boss_cnt , self.kill_monster_cnt, self.kill_count)
	local buff = config.buff
	local more_kill_buff = buff.more_kill[self.kill_count]
	if more_kill_buff ~= nil and self.char_id ~= nil then
		--print("more_kill_buff", j_e(more_kill_buff))
		--连斩buff
		local impact_o = Impact_3506(self.char_id, self.kill_count)
		impact_o:set_count(1800)  
		local param = {}
		param.per = 0
		param.val = more_kill_buff[1]
		param.type = IMPACT_TYPE.LIGHT
		impact_o:effect(param)
	end
	local is_update_client = false
	local refresh_buff = buff.refresh[total_kill]
	if refresh_buff ~= nil then
		--print("refresh_buff", j_e(refresh_buff))
		self.refresh_count = self.refresh_count + refresh_buff
		is_update_client = true
	end
	local transport_buff = buff.transport[total_kill]
	if transport_buff ~= nil then
		--print("transport_buff", j_e(transport_buff))
		self.transport_count = self.transport_count + transport_buff
		is_update_client = true
	end
	--
	if is_update_client == true then
		self:update_client()
	end
	self:update_kill_count()
end

function Scene_more_kill:do_reward()
	--print("Scene_more_kill:do_reward()")
	if self.is_do_reward or self.char_id == nil then
		return
	end
	local reward_list = {}
	local reward_config = self:get_self_config().reward
	for _, v in ipairs(reward_config.monster or {}) do
		local reward_size = 0
		for k, item in ipairs(v.point) do
			if self.kill_monster_cnt >= item.kill then
				reward_size = item.number
				break
			end
		end
		if reward_size > 0 then
			local n = #v.prop
			for i = 1, reward_size do
				local item = v.prop[_random(1, n+1)]
				local item_id = item.id
				local item_name = item.name
				if reward_list[item_id] == nil then
					reward_list[item_id] = {}
					reward_list[item_id][1] = 1
					reward_list[item_id][2] = item_name
				else
					reward_list[item_id][1] = reward_list[item_id][1] + 1
				end
			end
		end
	end
	for _, v in ipairs(reward_config.boss or {}) do
		local reward_size = 0
		for k, item in ipairs(v.point) do
			if self.kill_boss_cnt >= item.kill then
				reward_size = item.number
				break
			end
		end
		if reward_size > 0 then
			local n = #v.prop
			for i = 1, reward_size do
				local item = v.prop[_random(1, n+1)]
				local item_id = item.id
				local item_name = item.name
				if reward_list[item_id] == nil then
					reward_list[item_id] = {}
					reward_list[item_id][1] = 1
					reward_list[item_id][2] = item_name
				else
					reward_list[item_id][1] = reward_list[item_id][1] + 1
				end
			end
		end
	end

	--连斩奖励 
	for _, v in ipairs(reward_config.more_kill or {}) do
		local reward_size = 0
		for k, item in ipairs(v.point) do
			if self.kill_count_max >= item.kill then
				reward_size = item.number
				break
			end
		end
		if reward_size > 0 and v.prop[reward_size] ~= nil then
			local item = v.prop[reward_size]
			local item_id = item.id
			local item_name = item.name
			if reward_list[item_id] == nil then
				reward_list[item_id] = {}
				reward_list[item_id][1] = 1
				reward_list[item_id][2] = item_name
			else
				reward_list[item_id][1] = reward_list[item_id][1] + 1
			end
		end
	end

	self.is_do_reward = true
	local item_email_list = {}
	for k, v in pairs(reward_list) do
		local item = {}
		item.name = v[2]
		item.id = k
		item.count  = v[1]
		table.insert(item_email_list, item)
	end
	local str_log = string.format("insert into log_chop set char_id=%d, char_name='%s', kill_small=%d, kill_boss=%d, transport=%d, refresh=%d, time=%d, reward='%s' ",
					self.char_id, self.char_name, self.kill_monster_cnt, self.kill_boss_cnt, self.transport_use_cnt, self.refresh_use_cnt, ev.time, Json.Encode(item_email_list))
	f_multi_web_sql(str_log)
	if table.is_empty(reward_list) then
		return
	end
	--[[
	local player = g_obj_mgr:get_obj(self.char_id)
	if player ~= nil then
		local pack_con = player:get_pack_con()
		local item_list = {}
		local i = 1
		local pkt_list = {}
		for k, v in pairs(reward_list) do
			--print("reward", k, v[1], v[2])
			item_list[i] = {}
			item_list[i].type = 1
			item_list[i].item_id = k
			item_list[i].number  = v[1]
			i = i + 1
			table.insert(pkt_list, {v[2], v[1]})
		end
	
		local error = pack_con:check_add_item_l_inter_face(item_list)
		if error == 0 then 
			pack_con:add_item_l(item_list, {['type']=ITEM_SOURCE.TOWER_EX})
			local pkt = {}
			pkt.type = 1
			pkt.list = pkt_list
			g_cltsock_mgr:send_client(self.char_id, CMD_MAP_SCENE_MORE_KILL_END_S, pkt)
			return
		else
			local pkt = {}
			pkt.type = 2
			g_cltsock_mgr:send_client(self.char_id, CMD_MAP_SCENE_MORE_KILL_END_S, pkt)
		end
	end
	]]
	--发邮件奖励包
	local pkt = {}
	pkt.sender = -1
	pkt.recevier = self.char_id
	pkt.title = f_get_string(2671)
	pkt.content = f_get_string(2672)
	pkt.box_title = f_get_string(2673) 
	pkt.item_list = item_email_list
	pkt.money_list = {}
	g_svsock_mgr:send_server_ex(COMMON_ID, 0, CMD_M2P_SEND_EMAIL_S, pkt)

end

function Scene_more_kill:close()
	self:do_reward()
	Scene_instance.close(self)
end

function Scene_more_kill:update_client()
	local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
	local enter_list = con and con:get_obj_list()
	if enter_list[self.char_id] ~= nil then
		local pkt = {}
		pkt.list = {self.transport_count, self.refresh_count, self.magic_buff + 1}
		g_cltsock_mgr:send_client(self.char_id, CMD_MAP_SCENE_MORE_KILL_UPDATE_S, pkt)
	end
end

function Scene_more_kill:update_kill_count()
	local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
	local enter_list = con and con:get_obj_list()
	if enter_list[self.char_id] ~= nil then
		local pkt = {}
		pkt.count = self.kill_count
		pkt.time = self.kill_in
		g_cltsock_mgr:send_client(self.char_id, CMD_MAP_SCENE_MORE_KILL_COUNT_S, pkt)
	end
end

function Scene_more_kill:transport_to(pos_i)
	if self.transport_count <= 0 then
		return 22632
	end
	local config = self:get_self_config()
	if config.transport_pos == nil or config.transport_pos[pos_i] == nil then
		return 22633
	end
	local obj = g_obj_mgr:get_obj(self.char_id)
	if obj == nil then
		return 22634
	end
	self.transport_count = self.transport_count - 1
	self.transport_use_cnt = self.transport_use_cnt + 1
	self:transport(obj, config.transport_pos[pos_i])
	self:update_client()
	return 0
end

function Scene_more_kill:refresh_buff()
	if self.refresh_count <= 0 then
		return 22631
	end
	self.refresh_count = self.refresh_count - 1
	self.refresh_use_cnt = self.refresh_use_cnt + 1
	self.magic_buff_time = ev.time
	return 0
end

function Scene_more_kill:carry_scene(obj, pos)
	if not obj then
		return SCENE_ERROR.E_NOT_ON_SCENE
	end
	
	local obj_id = obj:get_id()
	if self.char_id ~= nil and self.char_id ~= obj_id then
		return SCENE_ERROR.E_EXISTS_COPY
	end
	if not self.owner_list[obj_id] then
		local config = self:get_self_limit_config()
		--
		local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
		local enter_list_size = con and con:get_obj_count()
		if config.human[2] <= enter_list_size then
			return SCENE_ERROR.E_HUMAN_LIMIT
		end
		local cycle_limit = config.cycle
		local con = obj:get_copy_con()
		if cycle_limit and con:get_count_copy(self.id) >= cycle_limit then
			return SCENE_ERROR.E_CYCLE_LIMIT
		end
		con:add_count_copy(self.id)
		self.owner_list[obj_id] = true
		
		f_multi_web_sql(string.format("insert into copy_into set copy_id=%d, char_id=%d, time=%d, char_name='%s'"
					, self.id
					, obj_id
					, ev.time
					, obj:get_name()))
	end
	
	return self:push_scene(obj, pos)
end