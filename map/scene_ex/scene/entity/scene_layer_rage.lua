
require("scene_ex.scene.entity.scene_layer")
local tower_rage_config = require("scene_ex.config.tower_rage_loader")
local _random = crypto.random


-- 怒气副本 基类层
Scene_layer_rage = oo.class(Scene_layer, "Scene_layer_rage")

function Scene_layer_rage:carry_scene(obj, pos)
	local obj_id = obj:get_id()
	if self.char_id ~= nil and self.char_id ~= obj_id then
		return SCENE_ERROR.E_EXISTS_COPY
	end
	local config = tower_rage_config.config[self.tower_id].layer_config[self.id]
	return self:push_scene(obj, config.entry)
end

function Scene_layer_rage:instance()
	local config = tower_rage_config.config[self.tower_id].layer_config[self.id]
	self.open_time = ev.time
	self.end_time = ev.time + config.timeout
	self.record_id = config.record_id
	self.except = config.except
	self.obj_mgr:instance(self.map_obj:get_w(), self.map_obj:get_h())
end

function Scene_layer_rage:get_home_carry(obj)
	local config = tower_rage_config.config[self.tower_id]
	local home_carry = config.home
	if not home_carry or not home_carry.id 
		or not home_carry.pos or not home_carry.pos[1] or not home_carry.pos[2] then
		return nil, nil
	end
	return home_carry.id, home_carry.pos
end

function Scene_layer_rage:next_sequence()

end

function Scene_layer_rage:on_timer(tm)
	if self.end_time and self.end_time <= ev.time then
		self:close()
	else
		self.obj_mgr:on_timer(tm)
	end
end

function Scene_layer_rage:on_obj_enter(obj)
	Scene_layer.on_obj_enter(self, obj)

	if obj:get_type() == OBJ_TYPE_HUMAN then
		self.char_id = obj:get_id()
		local config = tower_rage_config.config[self.tower_id].layer_config[self.id]		
		local str = config.layer_comment
		if str ~= nil then
			local pkt = {}
			pkt.type = 1
			pkt.text = str
			self:send_human(self.char_id, CMD_MAP_SCENE_TOWER_EX_COMMENT_S, pkt)
		end
	end
end

function Scene_layer_rage:end_update()
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
function Scene_layer_rage:finish()
	--print("Scene_layer_rage:finish()", is_refresh)
	
	self.show_next_layer_time = ev.time
	self.end_time = self.end_time + 30

	--通知完成
	self:end_update()
end

--显示进入口
function Scene_layer_rage:show_next_layer()
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

function Scene_layer_rage:next_sequence_1()
	if self.is_over or self.instance_id == nil then
		return
	end
	
	if self.sequence == 1 then
		self:build_monster()
	end
	
	if self.boss_id == nil then
		self.is_over = true
		self:finish()
		return
	end

	self.sequence = self.sequence + 1 
end

function Scene_layer_rage:build_monster()
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
	for k, v in ipairs(self.monster_ex.monster.list or {}) do
		local pos = map_obj:find_space(self.monster_ex.monster.area, 20)
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

function Scene_layer_rage:send_comment(i, j)
	if self:find_obj(self.char_id) then
		local config = tower_rage_config.config[self.tower_id].layer_config[self.id]
		local str = config.comments[i][j]
		local pkt = {}
		pkt.type = 2
		pkt.text = str
		self:send_human(self.char_id, CMD_MAP_SCENE_TOWER_EX_COMMENT_S, pkt)
	end
end


function Scene_layer_rage:create_summon_1()
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




---------------------------------------------------------------
-- 第一层
Scene_layer_rage1 = oo.class(Scene_layer_rage, "Scene_layer_rage1")

function Scene_layer_rage1:__init(group, tower_id, map_id, instance_id, map_obj, is_first)
	Scene_layer_rage.__init(self, group, tower_id, map_id, instance_id, map_obj, is_first)

	local config = tower_rage_config.config[self.tower_id].layer_config[self.id]
	self.monster_ex = config.monster_ex1
end


function Scene_layer_rage1:on_timer(tm)
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

function Scene_layer_rage1:on_obj_leave(obj)
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
		self.monster_id_l[obj_id] = nil
	end
end


---------------------------------------------------------------
-- 第二层
Scene_layer_rage2 = oo.class(Scene_layer_rage1, "Scene_layer_rage2")

function Scene_layer_rage2:__init(group, tower_id, map_id, instance_id, map_obj, is_first)
	Scene_layer_rage.__init(self, group, tower_id, map_id, instance_id, map_obj, is_first)

	local config = tower_rage_config.config[self.tower_id].layer_config[self.id]
	self.monster_ex = config.monster_ex2
end

function Scene_layer_rage2:on_timer(tm)
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

---------------------------------------------------------------
-- 第三层
Scene_layer_rage3 = oo.class(Scene_layer_rage, "Scene_layer_rage3")

function Scene_layer_rage3:__init(group, tower_id, map_id, instance_id, map_obj, is_first)
	Scene_layer_rage.__init(self, group, tower_id, map_id, instance_id, map_obj, is_first)

	local config = tower_rage_config.config[self.tower_id].layer_config[self.id]
	self.monster_ex = config.monster_ex3
	self.can_summon = false
	self.boss_list = {}
	self.boss_id = 5694
	self.summon_boss = nil
end

function Scene_layer_rage3:create_summon_3()
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
						local obj_id = obj:get_id()
						self.boss_id = obj_id
					end
				end
			end
		end
	end
end

function Scene_layer_rage3:create_summon_boss()
	local boss = self.summon_boss
	local param = {}
	param.des_id = boss.partner_id
	local partner = g_obj_mgr:get_obj(boss.partner_id)
	if not partner then
		return
	end
	local cur_pos = partner and partner:get_pos()
	local pos_m = {cur_pos[1]-5,cur_pos[1]+5,cur_pos[2]-5,cur_pos[2]+5}
	local map_o = partner:get_scene_obj():get_map_obj()
	local pos = map_o:find_pos(pos_m)
	local obj = g_obj_mgr:create_monster(boss.occ, pos, boss.scene_d, param)
	self:enter_scene(obj)
	local obj_id = obj:get_id()
	self.boss_list[obj_id] = obj
end

function Scene_layer_rage3:on_timer(tm)
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
		self:create_summon_3()
		self.can_summon = false
	end

	local boss = self.summon_boss
	if boss and self.boss_list[boss.partner_id] ~= nil and boss.time < ev.time then
		self:create_summon_boss()
		self.summon_boss = nil
	end

	if self.show_next_layer_time ~= nil and self.show_next_layer_time <= ev.time then
		self:show_next_layer()
		self.show_next_layer_time = nil
	end
end


function Scene_layer_rage3:build_monster()
	local map_obj = self:get_map_obj()
	local obj_mgr = g_obj_mgr
	-- boss
	local pos = self.monster_ex.boss and map_obj:find_space(self.monster_ex.boss.area, 20)
	if pos then
		for k, v in pairs(self.monster_ex.boss.list) do
			local obj = obj_mgr:create_monster(self.monster_ex.boss.list[k][1], pos, self.key)
			if obj and SCENE_ERROR.E_SUCCESS == self:enter_scene(obj) then
				local obj_id = obj:get_id()
				self.boss_list[obj_id] = obj
			end
		end
	end
	-- monster
	for k, v in ipairs(self.monster_ex.monster.list or {}) do
		local pos = map_obj:find_space(self.monster_ex.monster.area, 20)
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


function Scene_layer_rage3:on_obj_leave(obj)
	Scene_layer.on_obj_leave(self, obj)

	if self.instance_id == nil then
		return
	end
	local obj_id = obj:get_id()
	if self.boss_list[obj_id] ~= nil  then
		self.boss_list[obj_id] = nil
		self:boss_die_handle(obj)
	elseif self.monster_id_l[obj_id] ~= nil then	
		self.monster_id_l[obj_id] = nil
	elseif self.boss_id == obj_id then
		self.boss_id = nil
	end

end

function Scene_layer_rage3:boss_die_handle(obj)
	local partner = nil
	for k, v in pairs(self.boss_list) do
		partner = v
	end
	if partner == nil then
		for k, v in pairs(self.monster_id_l or {}) do
			local obj_monster = g_obj_mgr:get_obj(k)
			self.monster_id_l[k] = nil
			local _ = obj_monster and obj_monster:leave()
		end
		self.can_summon = true
	else
		local partner_id = partner:get_id()
		local pkt = {}
		pkt.can_summon = true
		pkt.occ = obj:get_occ()
		pkt.scene_d = partner:get_scene()
		pkt.partner_id = partner_id
		pkt.time = ev.time + 20
		self.summon_boss = pkt
	end
end

---------------------------------------------------------------
-- 第四层
Scene_layer_rage4 = oo.class(Scene_layer_rage3, "Scene_layer_rage4")

function Scene_layer_rage4:__init(group, tower_id, map_id, instance_id, map_obj, is_first)
	Scene_layer_rage.__init(self, group, tower_id, map_id, instance_id, map_obj, is_first)

	local config = tower_rage_config.config[self.tower_id].layer_config[self.id]
	self.monster_ex = config.monster_ex4
	self.can_summon = false
	self.boss_list = {}
	self.boss_id = 5697
	self.summon_boss = nil

end

function Scene_layer_rage4:on_timer(tm)
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
		self:create_summon_3()
		self.can_summon = false
	end

	local boss = self.summon_boss
	if boss and self.boss_list[boss.partner_id] ~= nil and boss.time < ev.time then
		self:create_summon_boss()
		self.summon_boss = nil
	end

	if self.show_next_layer_time ~= nil and self.show_next_layer_time <= ev.time then
		self:show_next_layer()
		self.show_next_layer_time = nil
	end
end


---------------------------------------------------------------
-- 第五层
Scene_layer_rage5 = oo.class(Scene_layer_rage, "Scene_layer_rage5")

function Scene_layer_rage5:__init(group, tower_id, map_id, instance_id, map_obj, is_first)
	Scene_layer_rage.__init(self, group, tower_id, map_id, instance_id, map_obj, is_first)

	local config = tower_rage_config.config[self.tower_id].layer_config[self.id]
	self.monster_ex = config.monster_ex5
	self.can_summon = false
	self.monster_list = {}
	self.boss_id = 5698
	self.pos_list = self.monster_ex.monster_pos
	self.cur_pos = 1						--初始位置
	self.change_time = nil					--改变位置的时间
	self.change_monster = nil				--改变位置的怪物
end

function Scene_layer_rage5:create_summon_5()
	local map_obj = self:get_map_obj()
	local obj_mgr = g_obj_mgr
	-- boss
	local pos = self.monster_ex.boss and map_obj:find_space(self.monster_ex.boss.area, 20)
	if pos then
		local obj = obj_mgr:create_monster(self.monster_ex.boss.list[1][1], pos, self.key)
		if obj and SCENE_ERROR.E_SUCCESS == self:enter_scene(obj) then
			local obj_id = obj:get_id()
			self.boss_id = obj_id
		end
	end
	-- monster

	local m_pos = self.pos_list
	for k, v in ipairs(self.monster_ex.monster.list or {}) do
		local pos = m_pos[self.cur_pos]
		if pos then
			local obj = obj_mgr:create_monster(v[1], pos, self.key)
			if obj then
				if self.monster_id_l == nil then
					self.monster_id_l = {}
				end
				self:enter_scene(obj)
				self.change_monster = obj
				self.change_time = ev.time + 30
				self.monster_id_l[obj:get_id()] = 1
			end
		end
	end
end

function Scene_layer_rage5:change_pos()
	self.cur_pos = self.cur_pos + 1
	if self.cur_pos > 4 then
			self.cur_pos = 1
	end
	local pos = self.pos_list[self.cur_pos]
	self:transport(self.change_monster, pos)
end


function Scene_layer_rage5:on_timer(tm)
	if self.end_time and self.end_time <= ev.time then
		self:close()
	else
		local con = self.obj_mgr:get_obj_con(OBJ_TYPE_MONSTER)
		if 0 == con:get_obj_count() and 0 == self.resources:get_obj_count() then
			self:next_sequence_1()
		end
		
		self.obj_mgr:on_timer(tm)
	end

	if self.change_time and self.change_time < ev.time  then
		self.change_time = self.change_time + 30
		self:change_pos()
	end

	if self.can_summon == true then
		self:create_summon_5()
		self.can_summon = false
	end

	if self.show_next_layer_time ~= nil and self.show_next_layer_time <= ev.time then
		self:show_next_layer()
		self.show_next_layer_time = nil
	end
end


function Scene_layer_rage5:build_monster()
	
	local area = self.monster_ex.summon and self.monster_ex.summon.area
	if area ~= nil then
		local map_obj = self:get_map_obj()
		for k, v in ipairs(self.monster_ex.summon.list) do
			local id = v[1]
			local size = v[2]
			--print("id, szie", id, size)
			for i = 1, size do
				local pos = map_obj:find_space(area, 20)
				if pos then
					local obj = g_obj_mgr:create_monster(id, pos, self.key)
					if obj and SCENE_ERROR.E_SUCCESS == self:enter_scene(obj) then
						local obj_id = obj:get_id()
						self.monster_list[obj_id] = obj_id
					end
				end
			end
		end
	end	
end


function Scene_layer_rage5:on_obj_leave(obj)
	Scene_layer.on_obj_leave(self, obj)

	if self.instance_id == nil then
		return
	end
	local obj_id = obj:get_id()
	if self.monster_list[obj_id] ~= nil  then
		self.monster_list[obj_id] = nil
		if table.is_empty(self.monster_list) then
			self.can_summon = true
		end
	elseif self.boss_id == obj_id then
		self.boss_id = nil
		self.change_monster = nil
		self.change_time = nil
		for k, v in pairs(self.monster_id_l or {}) do
			local obj_monster = g_obj_mgr:get_obj(k)
			self.monster_id_l[k] = nil
			local _ = obj_monster and obj_monster:leave()
		end
	end

end


---------------------------------------------------------------
-- 第六层
Scene_layer_rage6 = oo.class(Scene_layer_rage5, "Scene_layer_rage6")

function Scene_layer_rage6:__init(group, tower_id, map_id, instance_id, map_obj, is_first)
	Scene_layer_rage.__init(self, group, tower_id, map_id, instance_id, map_obj, is_first)

	local config = tower_rage_config.config[self.tower_id].layer_config[self.id]
	self.monster_ex = config.monster_ex6
	self.can_summon = false
	self.monster_list = {}
	self.boss_id = 5699
	self.pos_list = self.monster_ex.monster_pos
	self.cur_pos = _random(1, 5)
	self.change_time = nil
	self.change_monster = nil
end


function Scene_layer_rage6:change_pos()
	local cur_pos = _random(1, 5)
	local pos = self.pos_list[cur_pos]
	self:transport(self.change_monster, pos)
end


function Scene_layer_rage6:on_timer(tm)
	if self.end_time and self.end_time <= ev.time then
		self:close()
	else
		local con = self.obj_mgr:get_obj_con(OBJ_TYPE_MONSTER)
		if 0 == con:get_obj_count() and 0 == self.resources:get_obj_count() then
			self:next_sequence_1()
		end
		
		self.obj_mgr:on_timer(tm)
	end

	if self.change_time and self.change_time < ev.time  then
		self.change_time = self.change_time + 30
		self:change_pos()
	end

	if self.can_summon == true then
		self:create_summon_5()
		self.can_summon = false
	end

	if self.show_next_layer_time ~= nil and self.show_next_layer_time <= ev.time then
		self:show_next_layer()
		self.show_next_layer_time = nil
	end
end
