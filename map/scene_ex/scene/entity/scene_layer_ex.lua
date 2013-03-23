
require("scene_ex.scene.entity.scene_layer")
local tower_ex_config = require("scene_ex.config.tower_ex_loader")
local _random = crypto.random

-- 相克关系
local magic_ke = {4, 1, 5, 3, 2}
-- 相生关系
local magic_sheng = {5, 3, 1, 2, 4}
-- 重转花费
local replay_cost = 10

-- 70级单人爬塔副本 基类层
Scene_layer_ex = oo.class(Scene_layer, "Scene_layer_ex")

function Scene_layer_ex:carry_scene(obj, pos)
	local obj_id = obj:get_id()
	if self.char_id ~= nil and self.char_id ~= obj_id then
		return SCENE_ERROR.E_EXISTS_COPY
	end
	local config = tower_ex_config.config[self.tower_id].layer_config[self.id]
	return self:push_scene(obj, config.entry)
end

function Scene_layer_ex:instance()
	local config = tower_ex_config.config[self.tower_id].layer_config[self.id]
	self.open_time = ev.time
	self.end_time = ev.time + config.timeout
	self.record_id = config.record_id
	self.except = config.except
	self.obj_mgr:instance(self.map_obj:get_w(), self.map_obj:get_h())
end

function Scene_layer_ex:get_home_carry(obj)
	local config = tower_ex_config.config[self.tower_id]
	local home_carry = config.home
	if not home_carry or not home_carry.id 
		or not home_carry.pos or not home_carry.pos[1] or not home_carry.pos[2] then
		return nil, nil
	end
	return home_carry.id, home_carry.pos
end

function Scene_layer_ex:next_sequence()

end

function Scene_layer_ex:on_timer(tm)
	if self.end_time and self.end_time <= ev.time then
		self:close()
	else
		self.obj_mgr:on_timer(tm)
	end
end

function Scene_layer_ex:on_obj_enter(obj)
	Scene_layer.on_obj_enter(self, obj)

	if obj:get_type() == OBJ_TYPE_HUMAN then
		self.char_id = obj:get_id()
		local config = tower_ex_config.config[self.tower_id].layer_config[self.id]		
		local str = config.layer_comment
		if str ~= nil then
			local pkt = {}
			pkt.type = 1
			pkt.text = str
			self:send_human(self.char_id, CMD_MAP_SCENE_TOWER_EX_COMMENT_S, pkt)
		end
	end
end

function Scene_layer_ex:end_update()
	if self.record_id then
		if self.char_id then
			local data = {}
			local obj = g_obj_mgr:get_obj(self.char_id)
			if obj then
				table.insert(data, {['id'] = self.char_id, ['name'] = obj:get_name()})
			end

			g_public_sort_mgr:update_record(
				PUBLIC_SORT_TYPE.SCENE
				, ev.time - self.open_time
				, {["scene_id"] = self.tower_id, ["id"] = self.record_id, ["data"] = data}
				, PUBLIC_SORT_ORDER.ASC)
		end
	end
	self.group:open_next()
end

-- 完成当前层的任务
function Scene_layer_ex:finish(is_refresh)
	--print("Scene_layer_ex:finish()", is_refresh)
	--发奖励
	if not is_refresh or self.rewards == nil then
		local config = tower_ex_config.config[self.tower_id].layer_config[self.id]
		self.rewards = config.rewards and config.rewards[_random(1, #config.rewards + 1)]
		--print("=> self.rewards", j_e(self.rewards))
	end
	
	if self.rewards ~= nil and self.rewards.weight_t > 0 then
		local r = _random(1,  self.rewards.weight_t + 1)
		for k, v in ipairs(self.rewards.weight) do
			if r <= v then
				self.reward = self.rewards.list[k]
				break
			end
		end
		--
		if self.reward ~= nil and self.char_id ~= nil then
			local pkt = {}
			pkt.reward = self.reward
			pkt.jade = replay_cost
			pkt.finish_time = self.finish_time - self.open_time
			if not is_refresh then
				pkt.list = self.rewards.list
				pkt.layer = self.record_id
			end
			--print("reward:", j_e(pkt))
			self:send_human(self.char_id, CMD_MAP_SCENE_TOWER_EX_REWARD_S, pkt)
			f_scene_info_log("tower_ex:self_id:%d, char_id:%d, reward_id:%d, is_refresh:%d", self.id, self.char_id, self.reward, is_refresh and 1 or 0)
		end
	end

	if is_refresh == true then
		return
	end

	self.show_next_layer_time = ev.time + 7
	self.end_time = self.end_time + 30

	--通知完成
	self:end_update()
end

--显示进入口
function Scene_layer_ex:show_next_layer()
	local next_layer = self.monster_ex.next_layer
	if next_layer ~= nil then
		local map_obj = self:get_map_obj()
		local obj_mgr = g_obj_mgr
		local pos = map_obj:find_space(next_layer[2], 20)
		if pos then
			local args = {}
			args.time = self.end_time
			args.perpetual = true
			args.carry_id = next_layer[3]
			local obj = obj_mgr:create_npc(next_layer[1], "", pos, self.key, args)
			self:enter_scene(obj)
		end
		self:notify_next_layer()
	end
end

function Scene_layer_ex:get_reward(is_replay)
	--print("Scene_layer_ex:get_reward", is_replay)
	if self.reward ~= nil and self.char_id ~= nil then
		if is_replay == true then	--重新转盘
			local player = g_obj_mgr:get_obj(self.char_id)
			if player ~= nil then
				if self.first_play ~= nil then
					return
				end
				local pack_con = player:get_pack_con()
				local money = pack_con:get_money()
				if money.gift_jade < replay_cost then 
					return 22264 
				end
				if money.gift_jade >= replay_cost then
					--扣礼券
					pack_con:dec_money(MoneyType.GIFT_JADE, replay_cost, {['type']=MONEY_SOURCE.TOWER_EX})
				end
				self:finish(true)
				self.first_play = true
			end
		else
			local player = g_obj_mgr:get_obj(self.char_id)
			if player ~= nil then
				local pack_con = player:get_pack_con()
				local item_list = {}
				item_list[1] = {}
				item_list[1].type = 1
				item_list[1].item_id = self.reward
				item_list[1].number  = 1
			
				local error = pack_con:check_add_item_l_inter_face(item_list)
				if error == 0 then 
					pack_con:add_item_l(item_list, {['type']=ITEM_SOURCE.TOWER_EX})
					f_scene_info_log("tower_ex get_reward:self_id:%d, char_id:%d, reward_id:%d", self.id, self.char_id, self.reward)
					self.reward = nil
				else
					--背包满

				end
			end
		end
	end
	return 0
end

function Scene_layer_ex:next_sequence_1()
	if self.is_over or self.instance_id == nil then
		return
	end
	
	if self.sequence == 1 then
		self:build_monster()
	end
	if self.boss_id == nil then
		self.is_over = true
		self.finish_time = ev.time
		self:finish()
		return
	end
--[[
	local member_str = ""
	if self.record_id then
		local team_obj = g_team_mgr:get_team_obj(self.instance_id)
		if team_obj then
			local list = team_obj:get_team_l()
			
			local t = {}
			for obj_id, _ in pairs(list) do
				table.insert(t, obj_id)
			end
			member_str = table.concat(t, " ")
		end
	end
]]
	self.sequence = self.sequence + 1 
end

function Scene_layer_ex:build_monster()
	self.boss_type = _random(1, 6)

	local map_obj = self:get_map_obj()
	local obj_mgr = g_obj_mgr
	-- boss
	local pos = self.monster_ex.boss and map_obj:find_space(self.monster_ex.boss.area, 20)
	if pos then
		local obj = obj_mgr:create_monster(self.monster_ex.boss.list[self.boss_type][1], pos, self.key)
		if obj and SCENE_ERROR.E_SUCCESS == self:enter_scene(obj) then
			self.boss_id = obj:get_id()
		end
	end
	-- monster
	local m_pos = table.copy(self.monster_ex.monster_pos)
	for k, v in ipairs(self.monster_ex.monster.list or {}) do
		local pos_i = _random(1, #m_pos)
		local pos = m_pos[pos_i]
		if pos then
			local obj = obj_mgr:create_monster(v[1], pos, self.key)
			if obj then
				if self.monster_id_l == nil then
					self.monster_id_l = {}
				end
				self:enter_scene(obj)
				table.remove(m_pos, pos_i)
				self.monster_id_l[obj:get_id()] = 1
			end
		end
	end

end

function Scene_layer_ex:create_summon_1()
	-- 
	local area = self.monster_ex.summon and self.monster_ex.summon.area
	local m_param = {self.end_time - ev.time, self.boss_id}
	if area ~= nil then
		local map_obj = self:get_map_obj()
		for k, v in ipairs(self.monster_ex.summon.list) do
			local id = v[1]
			local size = v[2]
			--print("id, szie", id, size)
			for i = 1, size do
				local pos = map_obj:find_space(area, 20)
				if pos then
					local obj = g_obj_mgr:create_monster(id, pos, self.key, m_param)
					if obj and SCENE_ERROR.E_SUCCESS == self:enter_scene(obj) then
					
					end
				end
			end
		end
	end
end

function Scene_layer_ex:send_comment(i, j)
	if self:find_obj(self.char_id) then
		local config = tower_ex_config.config[self.tower_id].layer_config[self.id]
		local str = config.comments[i][j]
		local pkt = {}
		pkt.type = 2
		pkt.text = str
		self:send_human(self.char_id, CMD_MAP_SCENE_TOWER_EX_COMMENT_S, pkt)
	end
end

---------------------------------------------------------------
-- 第一层
Scene_layer_ex1 = oo.class(Scene_layer_ex, "Scene_layer_ex1")

function Scene_layer_ex1:__init(group, tower_id, map_id, instance_id, map_obj, is_first)
	Scene_layer_ex.__init(self, group, tower_id, map_id, instance_id, map_obj, is_first)

	local config = tower_ex_config.config[self.tower_id].layer_config[self.id]
	self.monster_ex = config.monster_ex1
end


function Scene_layer_ex1:on_timer(tm)
	if self.end_time and self.end_time <= ev.time then
		self:close()
	else
		local con = self.obj_mgr:get_obj_con(OBJ_TYPE_MONSTER)
		if 0 == con:get_obj_count() and 0 == self.resources:get_obj_count() then
			self:next_sequence_1()
		end
		
		self.obj_mgr:on_timer(tm)
	end

	if self.can_summon == true then
		self:create_summon_1()
		self.can_summon = nil
	end

	if self.show_next_layer_time ~= nil and self.show_next_layer_time <= ev.time then
		self:show_next_layer()
		self.show_next_layer_time = nil
	end
end

function Scene_layer_ex1:on_obj_leave(obj)
	Scene_layer.on_obj_leave(self, obj)

	if obj:get_type() == OBJ_TYPE_HUMAN then
		local impact_con = obj:get_impact_con()
		impact_con:del_impact(IMPACT_OBJ_2008)
		return
	end

	if self.instance_id == nil then
		return
	end

	local obj_id = obj:get_id()
	if obj_id == self.boss_id then
		self.boss_id = nil
		--
		for k, v in pairs(self.monster_id_l) do
			local obj_monster = g_obj_mgr:get_obj(k)
			self.monster_id_l[k] = nil
			local _ = obj_monster and obj_monster:leave()
		end
		self.monster_id_l = {}
	elseif self.monster_id_l[obj_id] ~= nil then
		local config = tower_ex_config.config[self.tower_id].layer_config[self.id]		
		self.monster_id_l[obj_id] = nil
		local magic_type = nil
		local obj_occ = obj:get_occ()
		for k, v in ipairs(self.monster_ex.monster.list) do 
			if obj_occ == v[1] then
				magic_type = k
				break
			end
		end
		if magic_ke[self.boss_type] == magic_type then
			--print("kill right",self.boss_type, magic_type)
			local str = config.comments[self.boss_type][1]
			if self.char_id ~= nil then
				local pkt = {}
				pkt.type = 2
				pkt.text = str
				self:send_human(self.char_id, CMD_MAP_SCENE_TOWER_EX_COMMENT_S, pkt)
				local impact_o = Impact_2008(self.char_id)
				local p2 = {}
				p2.per = 0.5
				p2.val = 0
				impact_o:set_count(math.ceil((self.end_time - ev.time) / impact_o.sec_count))
				impact_o:effect(p2)
			end
		else
			--print("kill fault",self.boss_type, magic_type)
			local str = config.comments[self.boss_type][2]
			if self.char_id ~= nil then
				local pkt = {}
				pkt.type = 2
				pkt.text = str
				self:send_human(self.char_id, CMD_MAP_SCENE_TOWER_EX_COMMENT_S, pkt)
			end
			self.can_summon = true
		end
		
		for k, v in pairs(self.monster_id_l) do
			local obj_monster = g_obj_mgr:get_obj(k)
			self.monster_id_l[k] = nil
			local _ = obj_monster and obj_monster:leave()
		end
	end
	
end

---------------------------------------------------------------
-- 第二层
Scene_layer_ex2 = oo.class(Scene_layer_ex, "Scene_layer_ex2")

function Scene_layer_ex2:__init(group, tower_id, map_id, instance_id, map_obj, is_first)
	Scene_layer_ex.__init(self, group, tower_id, map_id, instance_id, map_obj, is_first)

	local config = tower_ex_config.config[self.tower_id].layer_config[self.id]
	self.monster_ex = config.monster_ex2
end


function Scene_layer_ex2:on_timer(tm)
	if self.end_time and self.end_time <= ev.time then
		self:close()
	else
		local con = self.obj_mgr:get_obj_con(OBJ_TYPE_MONSTER)
		if 0 == con:get_obj_count() and 0 == self.resources:get_obj_count() then
			self:next_sequence_1()
		end
	
		self.obj_mgr:on_timer(tm)
	end

	if self.can_summon == true then
		self:create_summon_1()
		self.can_summon = nil
	end

	if self.show_next_layer_time ~= nil and self.show_next_layer_time <= ev.time then
		self:show_next_layer()
		self.show_next_layer_time = nil
	end
end

function Scene_layer_ex2:on_obj_leave(obj)
	Scene_layer.on_obj_leave(self, obj)

	if self.instance_id == nil then
		return
	end

	local obj_id = obj:get_id()
	if obj_id == self.boss_id then
		self.boss_id = nil
		--
		for k, v in pairs(self.monster_id_l) do
			local obj_monster = g_obj_mgr:get_obj(k)
			self.monster_id_l[k] = nil
			local _ = obj_monster and obj_monster:leave()
		end
		self.monster_id_l = {}
	elseif self.monster_id_l[obj_id] ~= nil then
		local config = tower_ex_config.config[self.tower_id].layer_config[self.id]		
		self.monster_id_l[obj_id] = nil
		local magic_type = nil
		local obj_occ = obj:get_occ()
		for k, v in ipairs(self.monster_ex.monster.list) do 
			if obj_occ == v[1] then
				magic_type = k
				break
			end
		end
		local boss_o = g_obj_mgr:get_obj(self.boss_id)
		if magic_type ~= nil and magic_ke[self.boss_type] == magic_type then
			--print("kill right:add ",self.boss_type, magic_type)
			local str = config.comments[self.boss_type][1]
			if self.char_id ~= nil then
				local pkt = {}
				pkt.type = 2
				pkt.text = str
				self:send_human(self.char_id, CMD_MAP_SCENE_TOWER_EX_COMMENT_S, pkt)
			end
			if boss_o ~= nil then
				boss_o:add_power_per(0.8)
			end
		elseif magic_type ~= nil and magic_type == self.boss_type then
			--print("kill fault:sub ",self.boss_type, magic_type)
			local str = config.comments[self.boss_type][2]
			if self.char_id ~= nil then
				local pkt = {}
				pkt.type = 2
				pkt.text = str
				self:send_human(self.char_id, CMD_MAP_SCENE_TOWER_EX_COMMENT_S, pkt)
			end
			if boss_o ~= nil then
				boss_o:add_power_per(-0.2)
			end
		elseif magic_type ~= nil and magic_sheng[self.boss_type] == magic_type then
			--print("kill fault:more",self.boss_type, magic_type)
			local str = config.comments[self.boss_type][3]
			if self.char_id ~= nil then
				local pkt = {}
				pkt.type = 2
				pkt.text = str
				self:send_human(self.char_id, CMD_MAP_SCENE_TOWER_EX_COMMENT_S, pkt)
			end
			if boss_o ~= nil then
				boss_o:add_power_per(-0.5)
			end
		else
			--print("kill other",self.boss_type, magic_type)	
			local str = config.comments[self.boss_type][4]
			if self.char_id ~= nil then
				local pkt = {}
				pkt.type = 2
				pkt.text = str
				self:send_human(self.char_id, CMD_MAP_SCENE_TOWER_EX_COMMENT_S, pkt)
			end
			self.can_summon = true
		end
	end
end


---------------------------------------------------------------
-- 第三层
Scene_layer_ex3 = oo.class(Scene_layer_ex, "Scene_layer_ex3")

function Scene_layer_ex3:__init(group, tower_id, map_id, instance_id, map_obj, is_first)
	Scene_layer_ex.__init(self, group, tower_id, map_id, instance_id, map_obj, is_first)

	local config = tower_ex_config.config[self.tower_id].layer_config[self.id]
	self.monster_ex = config.monster_ex3
end

function Scene_layer_ex3:build_monster()

	local map_obj = self:get_map_obj()
	local obj_mgr = g_obj_mgr
	-- boss
	local pos = self.monster_ex.boss and map_obj:find_space(self.monster_ex.boss.area, 20)
	if pos then
		local obj = obj_mgr:create_monster(self.monster_ex.boss.list[1][1], pos, self.key)
		if obj and SCENE_ERROR.E_SUCCESS == self:enter_scene(obj) then
			self.boss_id = obj:get_id()
		end
	end
	-- monster
	local summon_id = self.monster_ex.summon.list[1][1]
	local m_pos = table.copy(self.monster_ex.monster_pos)
	for k, v in ipairs(self.monster_ex.monster.list or {}) do
		local pos_i = _random(1, #m_pos)
		local pos = m_pos[pos_i][1]
		if pos then
			local obj = obj_mgr:create_monster(v[1], pos, self.key)
			if obj and summon_id then
				if self.monster_id_l == nil then
					self.monster_id_l = {}
				end
				obj:set_god(true)
				obj:set_stop_ai(true)
				self:enter_scene(obj)
				local obj_id = obj:get_id()
				self.monster_id_l[obj_id] = {2, k}
				if self.summon_id_l == nil then
					self.summon_id_l = {}
				end

				local s_pos1 = m_pos[pos_i][2]
				local summon_obj = obj_mgr:create_monster(summon_id, s_pos1, self.key)
				self:enter_scene(summon_obj)
				self.summon_id_l[summon_obj:get_id()] = obj_id
				--
				local s_pos2 = m_pos[pos_i][3]
				local summon_obj2 = obj_mgr:create_monster(summon_id, s_pos2, self.key)
				self:enter_scene(summon_obj2)
				self.summon_id_l[summon_obj2:get_id()] = obj_id
				table.remove(m_pos, pos_i)
			end
		end
	end

end

function Scene_layer_ex3:on_timer(tm)
	if self.end_time and self.end_time <= ev.time then
		self:close()
	else
		local con = self.obj_mgr:get_obj_con(OBJ_TYPE_MONSTER)
		if 0 == con:get_obj_count() and 0 == self.resources:get_obj_count() then
			self:next_sequence_1()
		end
	
		self.obj_mgr:on_timer(tm)
	end

	if self.show_next_layer_time ~= nil and self.show_next_layer_time <= ev.time then
		self:show_next_layer()
		self.show_next_layer_time = nil
	end
end

function Scene_layer_ex3:on_obj_leave(obj)
	Scene_layer.on_obj_leave(self, obj)

	if obj:get_type() == OBJ_TYPE_HUMAN then
		local impact_con = obj:get_impact_con()
		impact_con:del_impact(IMPACT_OBJ_2008)
		return
	end

	if self.instance_id == nil then
		return
	end

	local obj_id = obj:get_id()
	if obj_id == self.boss_id then
		self.boss_id = nil
		--
		for k, v in pairs(self.monster_id_l) do
			local obj_monster = g_obj_mgr:get_obj(k)
			self.monster_id_l[k] = nil
			local _ = obj_monster and obj_monster:leave()
		end
		self.monster_id_l = {}
		--
		for k, v in pairs(self.summon_id_l) do
			local obj_monster = g_obj_mgr:get_obj(k)
			self.summon_id_l[k] = nil
			local _ = obj_monster and obj_monster:leave()
		end
		self.summon_id_l = {}
	elseif self.monster_id_l[obj_id] ~= nil then
		--print("kill monster", obj_id)
		self.monster_id_l[obj_id] = nil	
	elseif self.summon_id_l[obj_id] ~= nil then
		--print("kill summon", self.summon_id_l[obj_id])
		local config = tower_ex_config.config[self.tower_id].layer_config[self.id]
		local owner_id = self.summon_id_l[obj_id]
		if self.monster_id_l[owner_id] ~= nil then
			self.monster_id_l[owner_id][1] = self.monster_id_l[owner_id][1] - 1
			if self.monster_id_l[owner_id][1] == 0 then
				local monster_type = self.monster_id_l[owner_id][2]
				local str = config.comments[1][monster_type]
				if self.char_id ~= nil then
					local pkt = {}
					pkt.type = 2
					pkt.text = str
					self:send_human(self.char_id, CMD_MAP_SCENE_TOWER_EX_COMMENT_S, pkt)
				end
				self:wake_up_owner(owner_id, monster_type)
			end
		end
		self.summon_id_l[obj_id] = nil
	end
end

function Scene_layer_ex3:wake_up_owner(owner_id, monster_type)
	--print("wake_up_owner", owner_id)
	local owner_o =  g_obj_mgr:get_obj(owner_id)
	if owner_o then
		owner_o:set_god(false)
		owner_o:set_stop_ai(false)
	end
	if monster_type == 1 then
		local impact_o = Impact_2008(self.char_id)
		local p2 = {}
		p2.per = 0.5
		p2.val = 0
		impact_o:set_count(math.ceil((self.end_time - ev.time) / impact_o.sec_count))
		impact_o:effect(p2)
	elseif monster_type == 2 then
		local boss_o = g_obj_mgr:get_obj(self.boss_id)
		if boss_o ~= nil then
			boss_o:add_power_per(-0.3)
		end
		owner_o:add_enemy_obj(self.boss_id, nil)
	elseif monster_type == 3 then
		owner_o.owner_id = self.boss_id
	elseif monster_type == 4 then

	end
end

---------------------------------------------------------------
-- 第四层
Scene_layer_ex4 = oo.class(Scene_layer_ex, "Scene_layer_ex4")

function Scene_layer_ex4:__init(group, tower_id, map_id, instance_id, map_obj, is_first)
	Scene_layer_ex.__init(self, group, tower_id, map_id, instance_id, map_obj, is_first)

	local config = tower_ex_config.config[self.tower_id].layer_config[self.id]
	self.monster_ex = config.monster_ex4
end

function Scene_layer_ex4:build_monster()
	Scene_layer_ex3.build_monster(self)
end

function Scene_layer_ex4:on_timer(tm)
	if self.end_time and self.end_time <= ev.time then
		self:close()
	else
		local con = self.obj_mgr:get_obj_con(OBJ_TYPE_MONSTER)
		if 0 == con:get_obj_count() and 0 == self.resources:get_obj_count() then
			self:next_sequence_1()
		end
	
		self.obj_mgr:on_timer(tm)
	end

	if self.show_next_layer_time ~= nil and self.show_next_layer_time <= ev.time then
		self:show_next_layer()
		self.show_next_layer_time = nil
	end
end

function Scene_layer_ex4:on_obj_leave(obj)
	Scene_layer_ex3.on_obj_leave(self, obj)
end

function Scene_layer_ex4:wake_up_owner(owner_id, monster_type)
	--print("wake_up_owner", owner_id)
	local owner_o =  g_obj_mgr:get_obj(owner_id)
	if owner_o then
		owner_o:set_god(false)
		owner_o:set_stop_ai(false)
	end
	if monster_type == 1 then
		owner_o.owner_id = self.boss_id
	elseif monster_type == 2 then
		
	elseif monster_type == 3 then
		owner_o.owner_id = self.char_id
		--owner_o:set_god(true)
	elseif monster_type == 4 then
		local impact_o = Impact_2008(self.char_id)
		local p2 = {}
		p2.per = 0.5
		p2.val = 0
		impact_o:set_count(math.ceil((self.end_time - ev.time) / impact_o.sec_count))
		impact_o:effect(p2)
	end
end

---------------------------------------------------------------
-- 第五层
Scene_layer_ex5 = oo.class(Scene_layer_ex, "Scene_layer_ex5")

function Scene_layer_ex5:__init(group, tower_id, map_id, instance_id, map_obj, is_first)
	Scene_layer_ex.__init(self, group, tower_id, map_id, instance_id, map_obj, is_first)

	local config = tower_ex_config.config[self.tower_id].layer_config[self.id]
	self.monster_ex = config.monster_ex5
	--
	self.summon_next_time = ev.time + 5
	self.monster_next_time = ev.time + math.floor(config.timeout / 2)
	self.monster_times = 3
end

function Scene_layer_ex5:build_monster()

	local map_obj = self:get_map_obj()
	local obj_mgr = g_obj_mgr
	-- boss
	local pos = self.monster_ex.boss and map_obj:find_space(self.monster_ex.boss.area, 20)
	if pos then
		local obj = obj_mgr:create_monster(self.monster_ex.boss.list[1][1], pos, self.key)
		if obj and SCENE_ERROR.E_SUCCESS == self:enter_scene(obj) then
			self.boss_id = obj:get_id()
		end
	end
	self.monster_id_l = {}
	self.summon_id_l = {}
end

function Scene_layer_ex5:summon_bomb()
	local summon_id = self.monster_ex.summon.list[1][1]
	local summon_times = self.monster_ex.summon.list[1][2]
	local area = self.monster_ex.summon.area
	self.summon_next_time = self.monster_ex.summon.next_time + ev.time
	local map_obj = self:get_map_obj()
	local param = {5, self.boss_id, SKILL_OBJ_1002914}
	for i = 1, summon_times do
		local pos = map_obj:find_space(area, 20)
		if pos then
			local obj = g_obj_mgr:create_monster(summon_id, pos, self.key, param)
			if obj ~= nil then
				if self.summon_id_l == nil then
					self.summon_id_l = {}
				end
				self:enter_scene(obj)
				self.summon_id_l[obj:get_id()] = 1
			end
		end
	end
end

function Scene_layer_ex5:build_crystal()
	local monster_id = self.monster_ex.monster.list[1][1]
	local monster_times = self.monster_ex.monster.list[1][2]
	local area = self.monster_ex.monster.area
	self.monster_next_time = self.monster_ex.monster.next_time + ev.time
	local map_obj = self:get_map_obj()
	for i = 1, monster_times do
		local pos = map_obj:find_space(area, 20)
		if pos then
			local obj = g_obj_mgr:create_monster(monster_id, pos, self.key)
			if obj ~= nil then
				if self.monster_id_l == nil then
					self.monster_id_l = {}
				end
				self:enter_scene(obj)
				self.monster_id_l[obj:get_id()] = ev.time
			end
		end
	end
	--
	if self:find_obj(self.char_id) then
		local config = tower_ex_config.config[self.tower_id].layer_config[self.id]
		local str = config.comments[1][1]
		local pkt = {}
		pkt.type = 2
		pkt.text = str
		self:send_human(self.char_id, CMD_MAP_SCENE_TOWER_EX_COMMENT_S, pkt)
	end
end



function Scene_layer_ex5:on_timer(tm)
	if self.end_time and self.end_time <= ev.time then
		self:close()
	else
		local con = self.obj_mgr:get_obj_con(OBJ_TYPE_MONSTER)
		if 0 == con:get_obj_count() and 0 == self.resources:get_obj_count() then
			self:next_sequence_1()
		end
	
		self.obj_mgr:on_timer(tm)
	end

	if self.show_next_layer_time ~= nil and self.show_next_layer_time <= ev.time then
		self:show_next_layer()
		self.show_next_layer_time = nil
	end

	if not self.is_over and ev.time >= self.summon_next_time then
		self:summon_bomb()
	end

	if not self.is_over and self.monster_times > 0 and ev.time >= self.monster_next_time then
		self:build_crystal()
		self.monster_times = self.monster_times - 1
	end

	for k, v in pairs(self.monster_id_l or {}) do
		if ev.time > v + 20 then
			local obj = g_obj_mgr:get_obj(k)
			self.monster_id_l[k] = nil
			local _ = obj and obj:leave()
		end
	end
end

function Scene_layer_ex5:on_obj_leave(obj)
	Scene_layer.on_obj_leave(self, obj)

	if self.instance_id == nil then
		return
	end

	local obj_id = obj:get_id()
	if obj_id == self.boss_id then
		self.boss_id = nil
		--
		for k, v in pairs(self.monster_id_l) do
			local obj_monster = g_obj_mgr:get_obj(k)
			self.monster_id_l[k] = nil
			local _ = obj_monster and obj_monster:leave()
		end
		self.monster_id_l = {}
		--
		for k, v in pairs(self.summon_id_l) do
			local obj_monster = g_obj_mgr:get_obj(k)
			self.summon_id_l[k] = nil
			local _ = obj_monster and obj_monster:leave()
		end
		self.summon_id_l = {}
	elseif self.monster_id_l[obj_id] ~= nil then
		--print("kill monster", obj_id)
		self:reset_end_time(self.end_time + 15)
		self.monster_id_l[obj_id] = nil
	elseif self.summon_id_l[obj_id] ~= nil then
		--print("kill summon", self.summon_id_l[obj_id])
		self.summon_id_l[obj_id] = nil
	end
end

---------------------------------------------------------------
-- 第六层
Scene_layer_ex6 = oo.class(Scene_layer_ex, "Scene_layer_ex6")

function Scene_layer_ex6:__init(group, tower_id, map_id, instance_id, map_obj, is_first)
	Scene_layer_ex.__init(self, group, tower_id, map_id, instance_id, map_obj, is_first)

	local config = tower_ex_config.config[self.tower_id].layer_config[self.id]
	self.monster_ex = config.monster_ex6
	self.summon_id_l = {}
end

function Scene_layer_ex6:next_sequence_6()
	if self.is_over or self.instance_id == nil then
		return
	end
	
	self:build_monster()
	
	if self.sequence >= 4 and self.boss_id == nil then
		self.is_over = true
		self.finish_time = ev.time
		self:finish()
		return
	end

	self.sequence = self.sequence + 1 
end

function Scene_layer_ex6:build_monster()
	
	if self.sequence == 1 then
		self:build_stage_monster(1)
	elseif self.sequence == 2 then
		self:build_stage_monster(2)
	elseif self.sequence == 3 then
		local map_obj = self:get_map_obj()
		-- boss
		local pos = self.monster_ex.boss and map_obj:find_space(self.monster_ex.boss.area, 20)
		if pos then
			local obj = g_obj_mgr:create_monster(self.monster_ex.boss.list[1][1], pos, self.key)
			if obj and SCENE_ERROR.E_SUCCESS == self:enter_scene(obj) then
				self.boss_id = obj:get_id()
				self.resources:push_obj(self.boss_id)
			end
		end
		self.monster_id_l = {}
	end
end

--生成图腾
function Scene_layer_ex6:build_crystal(it)
	local summon_id = self.monster_ex.summon.list[it][1]
	local map_obj = self:get_map_obj()
	local pos = self.monster_ex.summon_pos[it]
	if pos then
		local obj = g_obj_mgr:create_monster(summon_id, pos, self.key)
		if obj ~= nil then
			self:enter_scene(obj)
			if self.summon_id_l == nil then
				self.summon_id_l = {}
			end
			self.summon_id_l[obj:get_id()] = 1
		end
	end
end

--生成小怪
function Scene_layer_ex6:build_stage_monster(it)
	local monster_id = self.monster_ex.monster.list[it][1]
	local monster_times = self.monster_ex.monster.list[it][2]
	local area = self.monster_ex.monster.area
	local map_obj = self:get_map_obj()
	self.monster_id_l = {}
	self.monster_sequence = 1
	for i = 1, monster_times do
		local pos = map_obj:find_space(area, 20)
		if pos then
			local obj = g_obj_mgr:create_monster(monster_id + i - 1, pos, self.key)
			if obj ~= nil then
				self.monster_id_l[i] = obj:get_id()
				self:enter_scene(obj)
				self.resources:push_obj(obj:get_id())
			end
		end
	end
	--
	self.is_killing = true
end

function Scene_layer_ex6:on_timer(tm)
	if self.end_time and self.end_time <= ev.time then
		self:close()
	else
		if 0 == self.resources:get_obj_count() then
			self:next_sequence_6()
		end
		
		self.obj_mgr:on_timer(tm)
	end

	if self.summon_crystal ~= nil then
		self:build_crystal(self.summon_crystal)
		self.summon_crystal = nil
	end

	if self.show_next_layer_time ~= nil and self.show_next_layer_time <= ev.time then
		self:show_next_layer()
		self.show_next_layer_time = nil
	end
end

function Scene_layer_ex6:on_obj_leave(obj)
	Scene_layer.on_obj_leave(self, obj)

	if self.instance_id == nil then
		return
	end

	local obj_id = obj:get_id()
	self.resources:pop_obj(obj_id)

	if obj_id == self.boss_id then
		self.boss_id = nil
		--
		for k, v in pairs(self.summon_id_l) do
			local obj_monster = g_obj_mgr:get_obj(k)
			self.summon_id_l[k] = nil
			local _ = obj_monster and obj_monster:leave()
		end
		self.summon_id_l = {}
	elseif self.summon_id_l[obj_id] ~= nil then
		--print("kill summon", self.summon_id_l[obj_id])
		self.summon_id_l[obj_id] = nil
	elseif self.is_killing then
		--print("kill monster", obj_id)
		local kill_error = false
		for k, v in ipairs(self.monster_id_l or {}) do
			if v == obj_id then
				if self.monster_sequence == k then
					self.monster_sequence = self.monster_sequence + 1
					if self.monster_sequence >= 6 then
						self.is_killing = false
						self.monster_id_l = {}
						if self.sequence == 2 then
							self.summon_crystal = 1
							self:send_comment(1, 1)
						elseif self.sequence == 3 then
							self.summon_crystal = 2
							self:send_comment(1, 3)
						end
					end
				else
					kill_error = true
					self.is_killing = false
					if self.sequence == 2 then
						self:send_comment(1, 2)
					elseif self.sequence == 3 then
						self:send_comment(1, 4)
					end
					break
				end
			end
		end
		
		if kill_error then
			for i, monster_id in pairs(self.monster_id_l) do
				if monster_id ~= obj_id then
					local obj_monster = g_obj_mgr:get_obj(monster_id)
					local _ = obj_monster and obj_monster:leave()
				end
			end
			self.monster_id_l = {}
			self:reset_end_time(math.max(ev.time + 3, self.end_time - 60))
		end
	end
end


---------------------------------------------------------------
-- 第七层
Scene_layer_ex7 = oo.class(Scene_layer_ex, "Scene_layer_ex7")

function Scene_layer_ex7:__init(group, tower_id, map_id, instance_id, map_obj, is_first)
	Scene_layer_ex.__init(self, group, tower_id, map_id, instance_id, map_obj, is_first)

	local config = tower_ex_config.config[self.tower_id].layer_config[self.id]
	self.monster_ex = config.monster_ex7
end

function Scene_layer_ex7:build_monster()
	local map_obj = self:get_map_obj()
	-- boss
	local pos = self.monster_ex.boss and map_obj:find_space(self.monster_ex.boss.area, 20)
	if pos then
		local obj = g_obj_mgr:create_monster(self.monster_ex.boss.list[1][1], pos, self.key)
		if obj and SCENE_ERROR.E_SUCCESS == self:enter_scene(obj) then
			self.boss_id = obj:get_id()
			obj:set_boss_attr(self.monster_ex.boss_attr)
		end
	end
	self:build_crystal()
end

--生成图腾
function Scene_layer_ex7:build_crystal()
	local crystal = self.monster_ex.summon.list
	local pos_list = self.monster_ex.summon_pos
	local obj_mgr = g_obj_mgr
	for k, v in ipairs(crystal or {}) do
		local pos = pos_list[k]
		if pos then
			local obj = obj_mgr:create_monster(v[1], pos, self.key)
			if obj then
				if self.monster_id_l == nil then
					self.monster_id_l = {}
				end
				self:enter_scene(obj)
				self.monster_id_l[obj:get_id()] = 1
			end
		end
	end
end

function Scene_layer_ex7:on_timer(tm)
	if self.end_time and self.end_time <= ev.time then
		self:close()
	else
		local con = self.obj_mgr:get_obj_con(OBJ_TYPE_MONSTER)
		if 0 == con:get_obj_count()  then
			self:next_sequence_1()
		end
		
		
		self.obj_mgr:on_timer(tm)
	end

	if self.show_next_layer_time ~= nil and self.show_next_layer_time <= ev.time then
		self:show_next_layer()
		self.show_next_layer_time = nil
	end
end

function Scene_layer_ex7:on_obj_leave(obj)
	Scene_layer.on_obj_leave(self, obj)

	if self.instance_id == nil then
		return
	end

	local obj_id = obj:get_id()
	if obj_id == self.boss_id then
		self.boss_id = nil
		for k, v in pairs(self.monster_id_l or {}) do
			local obj_monster = g_obj_mgr:get_obj(k)
			self.monster_id_l[k] = nil
			local _ = obj_monster and obj_monster:leave()
		end
		self.monster_id_l = {}
	end
end

---------------------------------------------------------------
-- 第八层
Scene_layer_ex8 = oo.class(Scene_layer_ex, "Scene_layer_ex8")

function Scene_layer_ex8:__init(group, tower_id, map_id, instance_id, map_obj, is_first)
	Scene_layer_ex.__init(self, group, tower_id, map_id, instance_id, map_obj, is_first)

	local config = tower_ex_config.config[self.tower_id].layer_config[self.id]
	self.monster_ex = config.monster_ex8
	self.crystal_id = nil
	self.is_skill = nil
	self.skill_type = 1   --nil无1反弹 2无敌
	self.skill_time = ev.time + 300
	self.combat_tm_flag = nil
end

function Scene_layer_ex8:build_monster()
	local map_obj = self:get_map_obj()
	-- boss
	local pos = self.monster_ex.boss and map_obj:find_space(self.monster_ex.boss.area, 20)
	if pos then
		local obj = g_obj_mgr:create_monster(self.monster_ex.boss.list[1][1], pos, self.key)
		if obj and SCENE_ERROR.E_SUCCESS == self:enter_scene(obj) then
			self.boss_id = obj:get_id()
			obj:set_summon_pos(self.monster_ex.summon.list[1][1], self.monster_ex.summon_pos[1])
			self.resources:push_obj(self.boss_id)
		end
	end
end

function Scene_layer_ex8:on_timer(tm)
	if self.end_time and self.end_time <= ev.time then
		self:close()
	else
		if 0 == self.resources:get_obj_count() then
			self:next_sequence_1()
		end
		
		self.obj_mgr:on_timer(tm)
	end

	if self.show_next_layer_time ~= nil and self.show_next_layer_time <= ev.time then
		self:show_next_layer()
		self.show_next_layer_time = nil
	end
end

function Scene_layer_ex8:on_obj_leave(obj)
	Scene_layer.on_obj_leave(self, obj)

	if self.instance_id == nil then
		return
	end

	local obj_id = obj:get_id()
	self.resources:pop_obj(obj_id)
	if obj_id == self.boss_id then
		local boss = g_obj_mgr:get_obj(self.boss_id)
		local _ = boss and boss:clean_obj()
		self.boss_id = nil
	elseif obj:get_occ() == 4639 then
		local boss = g_obj_mgr:get_obj(self.boss_id)
		local _ = boss and boss:reset_skill()
	end
end

