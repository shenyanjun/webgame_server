local _marry_config = require("scene_ex.config.marry_config_loader")
local _marry_dialogue = require("config.loader.marry_dialogue_loader")
local integral_func = require("mall.integral_func")

-- 结婚进行到的阶段
local MARRY_STAGE = {
	FREE		=	0,	--刚进入场景的自由阶段
	PREPARE_1	=	1,	--男主人点了开始
	PREPARE_2	=	2,	--女主人点了开始
	START		=	3,	--两个人都点了开始
	BEGINING	=	4,	--正式开始，所有人都不能动
	END			=	5,	--结婚仪式完成
}

--local MAX_MARRYING_TIME = 600	--结婚仪式最大时间
local MARRY_SELECT_DIALOGUE_TIME = 12	--主人按确定时间
local MARRY_SHOW_DIALOGUE_TIME = 6		--查看对话时间

Scene_marry = oo.class(Scene_instance, "Scene_marry")

function Scene_marry:__init(map_id, instance_id, map_obj)
	Scene_instance.__init(self, map_id, instance_id, map_obj)
	
	--self.kickout_human_l = {}
	self.hero_id = nil
	self.heroine_id = nil
	self.marry_state = MARRY_STAGE.FREE
	self.area_list = {}
	self.char_id_to_area = {}
	-- 对话
	self.dialogue_stage = nil
	self.dialogue_time = ev.time
	self.prev_id = 1	-- 上一次选择的对话项
	self.cupid_id = nil

	self.state_time = 0
	self.note_notify = 0
end

function Scene_marry:get_self_config()
	return _marry_config.config[self.id]
end

function Scene_marry:carry_scene(obj, pos, args)

	if not obj then
		return SCENE_ERROR.E_NOT_ON_SCENE
	end

	local obj_id = obj:get_id()
	local config = self:get_self_config()
	if obj_id ~= self.hero_id and obj_id ~= self.heroine_id
		and config.human_max < self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN):get_obj_count() + 1 then
		return SCENE_ERROR.E_FACTION_HUMAN_MAX
	end

	--if self.kickout_human_l[obj_id] ~= nil then
	--	return 22591
	--end
	if not self.owner_list[obj_id] then
		--[[
		local config = self:get_self_limit_config()
		local cycle_limit = config.cycle
		local con = obj:get_copy_con()
		if cycle_limit and con:get_count_copy(self.id) >= cycle_limit then
			return SCENE_ERROR.E_CYCLE_LIMIT
		end
		con:add_count_copy(self.id)
		]]
		self.owner_list[obj_id] = true
		
		f_multi_web_sql(string.format("insert into copy_into set copy_id=%d, char_id=%d, time=%d, char_name='%s'"
					, self.id
					, obj_id
					, ev.time
					, obj:get_name()))
	end
	
	return self:push_scene(obj, pos)
end

function Scene_marry:on_timer(tm)

	--测试代码
	--[[
	if self.temp1 == nil or ev.time > self.temp1 then
		--print("self.marry_state", self.marry_state)
		self.temp1 = ev.time + 5
	end]]

	--self.obj_mgr:on_timer(tm)
	--最后10分钟，5分钟通知
	if self.end_time - ev.time < 600 and self.note_notify == 0 then
		self.note_notify = 1
		local pkt = {}
		pkt.type = 3
		local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
		local enter_list = con and con:get_obj_list()
		if enter_list[self.hero_id] ~= nil then
			self:send_human(self.hero_id, CMD_MAP_SCENE_MARRY_NOTE_NOTIFY_S, pkt)
		end
		if enter_list[self.heroine_id] ~= nil then
			self:send_human(self.heroine_id, CMD_MAP_SCENE_MARRY_NOTE_NOTIFY_S, pkt)
		end
	elseif self.end_time - ev.time < 300 and self.note_notify == 1 then
		self.note_notify = 2
		local pkt = {}
		pkt.type = 4
		local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
		local enter_list = con and con:get_obj_list()
		if enter_list[self.hero_id] ~= nil then
			self:send_human(self.hero_id, CMD_MAP_SCENE_MARRY_NOTE_NOTIFY_S, pkt)
		end
		if enter_list[self.heroine_id] ~= nil then
			self:send_human(self.heroine_id, CMD_MAP_SCENE_MARRY_NOTE_NOTIFY_S, pkt)
		end
	end

	if ev.time >= self.end_time then
		self:close()
	end

	if self.marry_state == MARRY_STAGE.START then
		if ev.time >= self.state_time then
			local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
			local enter_list = con and con:get_obj_list()
			local obj_hero = g_obj_mgr:get_obj(self.hero_id)
			local obj_heroine = g_obj_mgr:get_obj(self.heroine_id)
			if obj_hero ~= nil and obj_heroine ~= nil and enter_list[self.hero_id] ~= nil and enter_list[self.heroine_id] ~= nil then
				self.marry_state = MARRY_STAGE.BEGINING
				self:set_correct_pos()
				self:state_notify_s(1)
				self.begining_time = ev.time
				--
				self:start_dialoge(obj_hero, obj_heroine)
			end
		end
	elseif self.marry_state == MARRY_STAGE.BEGINING then
		local b_end_dialogue = false
		if self.dialogue_stage ~= nil and ev.time >= self.dialogue_time then
			self.dialogue_stage = self.dialogue_stage + 1

			local entry = _marry_dialogue.config[self.dialogue_stage]
			if entry ~= nil then
				if entry.speaker == 0 and self.cupid_id ~= nil then	--月老
					local obj_hero = g_obj_mgr:get_obj(self.hero_id)
					local obj_heroine = g_obj_mgr:get_obj(self.heroine_id)
					self.prev_id = crypto.random(1, #entry.contents + 1)
					local pkt = {}
					pkt.obj_id = self.cupid_id --self.my_obj:get_id()
					pkt.msg = entry.contents[self.prev_id]
					pkt.msg = string.gsub(pkt.msg, "{1}", self.hero_name or "")
					pkt.msg = string.gsub(pkt.msg, "{2}", self.heroine_name or "")
					self:send_old_man_say(pkt)
				else
					local send_to = entry.speaker == 1 and self.hero_id or self.heroine_id
					local pkt = {}
					pkt.state = self.dialogue_stage
					if self.dialogue_stage >= 2 then
						--[[
						local prev_entry = _marry_dialogue.config[self.dialogue_stage - 1]
						local prev_spe = prev_entry.speaker == 1 and self.hero_id or self.heroine_id
						local prev_obj = g_obj_mgr:get_obj(prev_spe)
						pkt.occ = prev_obj and prev_obj:get_occ() or 11
						pkt.name = prev_obj and prev_obj:get_name() or ""
						pkt.gender = prev_obj and prev_obj:get_sex() or 0
						]]
						pkt.prev_id = self.prev_id
					end
					local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
					local enter_list = con and con:get_obj_list()
					if enter_list and enter_list[send_to] then
						--print("==", send_to, CMD_MAP_SCENE_MARRY_DIALOGUE_S, j_e(pkt))
						self:send_human(send_to, CMD_MAP_SCENE_MARRY_DIALOGUE_S, pkt)
					end
				end
				if entry.speaker == 0 then
					self.dialogue_time = ev.time + MARRY_SHOW_DIALOGUE_TIME
				else
					self.dialogue_time = ev.time + MARRY_SELECT_DIALOGUE_TIME
				end
			else	--已经完成仪式
				b_end_dialogue = true
			end
			self.prev_id = 1
		end

		if b_end_dialogue then
			 self.marry_state = MARRY_STAGE.END
			 self:state_notify_s(2)

			local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
			local enter_list = con and con:get_obj_list()
			for obj_id, v in pairs(enter_list or {}) do
				local obj = g_obj_mgr:get_obj(obj_id)
				local _ = obj and obj:set_active(true)
			end
			--世界广播
			local marry = g_marry_mgr:get_marry_info_ex(self.instance_id)
			local pkt_new = {}
			pkt_new.char_name = marry and marry.char_name or ""
			pkt_new.mate_name = marry and marry.mate_name or ""
			pkt_new.type = 4
			g_svsock_mgr:send_server_ex(COMMON_ID, 0, CMD_M2P_MARRY_BROADCAST, pkt_new)

			self:build_collect()
		end
	end
end

function Scene_marry:on_obj_enter(obj)
	if obj:get_type() == OBJ_TYPE_HUMAN then
		local obj_id = obj:get_id()
		if obj_id == self.hero_id or obj_id == self.heroine_id then
			local pkt = {}
			pkt.is_end = 0
			if self.marry_state == MARRY_STAGE.END then
				pkt.is_end = 1
			elseif self.marry_state == MARRY_STAGE.START then
				self.state_time = ev.time + 3
			end
			self:send_human(obj_id, CMD_MAP_SCENE_MASTER_ENTER_MARRY_S, pkt)
		end
		if self.marry_state == MARRY_STAGE.BEGINING then
			if obj_id == self.hero_id then
				local config = self:get_self_config()
				self:set_human_pos(obj_id, config.hero.pos)
			elseif obj_id == self.heroine_id then
				local config = self:get_self_config()
				self:set_human_pos(obj_id, config.heroine.pos)
			else
				self:set_guest_pos(obj_id)
			end
			local pkt = {}
			pkt.state = 1
			self:send_human(obj_id, CMD_MAP_SCENE_MARRY_STATE_NOTIFY_S, pkt)
		end
		if self.marry_state == MARRY_STAGE.END then
			--[[
			if obj_id == self.hero_id or obj_id == self.heroine_id then
				local pkt = {}
				pkt.state = 2
				self:send_human(obj_id, CMD_MAP_SCENE_MARRY_STATE_NOTIFY_S, pkt)
			end
			]]
		end
		--进入结婚场景通知主人ID
		local pkt = {}
		pkt.id = {self.hero_id, self.heroine_id}
		self:send_human(obj_id, CMD_MAP_SCENE_MARRY_MASTER_ID_S, pkt)
	end
end

function Scene_marry:on_obj_leave(obj)
	if obj:get_type() == OBJ_TYPE_HUMAN then
		obj:set_active(true)
		if self.marry_state == MARRY_STAGE.BEGINING then
			local area = self.char_id_to_area[obj:get_id()]
			if area then
				self.area_list[area][3] = self.area_list[area][3] - 1
				self.char_id_to_area[obj:get_id()] = nil
			end
		end
	end
end

function Scene_marry:instance(obj)
	--
	local marry = g_marry_mgr:get_marry_info_ex(self.instance_id)
	self.end_time = ev.time + (marry.m_n or 60)
	if obj:get_sex() == 0 and obj:get_id() == marry.char_id then
		self.hero_id = marry.char_id
		self.heroine_id = marry.mate_id
		self.hero_name = marry.char_name
		self.heroine_name = marry.mate_name
	else
		self.heroine_id = marry.char_id
		self.hero_id = marry.mate_id
		self.hero_name = marry.mate_name
		self.heroine_name = marry.char_name
	end
	local config = self:get_self_config()
	self.cupid_id = config.cupid and  config.cupid.id

	self.obj_mgr = Scene_obj_mgr_ex(Scene_monster_layout(self.key, true), Scene_monster_copy_mgr())
	self.obj_mgr:instance(self.map_obj:get_w(), self.map_obj:get_h())

	--世界广播
	local pkt_new = {}
	pkt_new.char_name = marry.char_name
	pkt_new.mate_name = marry.mate_name
	pkt_new.type = 3
	pkt_new.line = SELF_SV_ID
	--pkt_new.s_id = self.id
	g_svsock_mgr:send_server_ex(COMMON_ID, 0, CMD_M2P_MARRY_BROADCAST, pkt_new)

	self:build_collect()
end

function Scene_marry:close()
	g_marry_mgr:set_fb_close(self.instance_id)
	Scene_instance.close(self)
end

--主人开始婚礼
function Scene_marry:start_marry(char_id)
	local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
	local enter_list = con and con:get_obj_list()

	if self.hero_id == char_id then
		if self.marry_state == MARRY_STAGE.FREE then
			self.marry_state = MARRY_STAGE.PREPARE_1
			if enter_list[self.heroine_id] ~= nil then
				local pkt = {}
				pkt.type = 1
				self:send_human(self.heroine_id, CMD_MAP_SCENE_MARRY_NOTE_NOTIFY_S, pkt)
			else
				local pkt = {}
				pkt.type = 2
				self:send_human(self.hero_id, CMD_MAP_SCENE_MARRY_NOTE_NOTIFY_S, pkt)
			end
			return 22589
		elseif self.marry_state == MARRY_STAGE.PREPARE_2 then
			self.marry_state = MARRY_STAGE.START
			self.state_time = ev.time + 10
			self:state_notify_s(0)
			return 0
		elseif self.marry_state == MARRY_STAGE.PREPARE_1 then
			return 22589
		else
			return 22588
		end
	end

	if self.heroine_id == char_id then
		if self.marry_state == MARRY_STAGE.FREE then
			self.marry_state = MARRY_STAGE.PREPARE_2
			if enter_list[self.hero_id] ~= nil then
				local pkt = {}
				pkt.type = 1
				self:send_human(self.hero_id, CMD_MAP_SCENE_MARRY_NOTE_NOTIFY_S, pkt)
			else
				local pkt = {}
				pkt.type = 2
				self:send_human(self.heroine_id, CMD_MAP_SCENE_MARRY_NOTE_NOTIFY_S, pkt)
			end
			return 22590
		elseif self.marry_state == MARRY_STAGE.PREPARE_1 then
			self.marry_state = MARRY_STAGE.START
			self.state_time = ev.time + 10
			self:state_notify_s(0)
			return 0
		elseif self.marry_state == MARRY_STAGE.PREPARE_2 then
			return 22590
		else
			return 22588
		end
	end
	return 22587
end

--取结婚场景玩家列表
function Scene_marry:get_human_list()
	local list = {}
	local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
	local enter_list = con and con:get_obj_list()
	for obj_id, v in pairs(enter_list or {}) do
		local obj = g_obj_mgr:get_obj(obj_id)
		if obj ~= nil and obj_id ~= self.hero_id and obj_id ~= self.heroine_id then
			local faction = g_faction_mgr:get_faction_by_cid(obj_id)
			table.insert(list, {obj_id, obj:get_name(), faction and faction:get_faction_name() or ""})
		end
	end
	return list
end

--驱逐结婚场景玩家列表
function Scene_marry:kickout_human_list(char_id, list)
	local ret = self:auth(char_id)
	if ret ~= 0 then return ret end

	local obj = g_obj_mgr:get_obj(char_id)
	local pkt = {}
	pkt.name = obj and obj:get_name() or ""
	for _, obj_id in ipairs(list or {}) do
		if obj_id ~= self.hero_id and obj_id ~= self.heroine_id then
			self:kickout(obj_id)
			--self.kickout_human_l[obj_id] = 1
			self:send_human(obj_id, CMD_MAP_SCENE_MARRY_KICKOUT_HUMAN_LIST_S, pkt)
		end
	end
	g_marry_mgr:set_kill_id_list( self.instance_id, list )
	return 0
end

--移动玩家到指定位置并设置不能动
function Scene_marry:set_correct_pos()
	local config = self:get_self_config()
	self.area_list = {}
	self.char_id_to_area = {}
	for k, v in ipairs(config.guest.area or {}) do
		self.area_list[k] = {v[1], v[2], 0} 
	end

	self:set_human_pos(self.hero_id, config.hero.pos)
	self:set_human_pos(self.heroine_id, config.heroine.pos)

	local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
	local enter_list = con and con:get_obj_list()
	for obj_id, v in pairs(enter_list or {}) do
		if obj_id ~= self.hero_id and obj_id ~= self.heroine_id then
			self:set_guest_pos(obj_id)
		end
	end

end

--移动客人到指定位置并设置不能动
function Scene_marry:set_guest_pos(char_id)
	for k, v in ipairs(self.area_list) do
		if v[3] < v[2] then
			local pos = self.map_obj:find_space(v[1], 20)
			if pos then
				self:set_human_pos(char_id, pos)
			end
			v[3] = v[3] + 1
			self.char_id_to_area[char_id] = k
			break
		end
	end
end

--移动玩家到指定位置并设置不能动
function Scene_marry:set_human_pos(char_id, pos)
	local obj = g_obj_mgr:get_obj(char_id)
	if obj then
		if not obj:is_alive() then
			obj:do_relive(1, true)	--复活
			obj:send_relive(3)
		end
		obj:set_active(false)
		self:transport(obj, pos)
	end
end

--
function Scene_marry:auth(char_id)
	if char_id ~= self.hero_id and char_id ~= self.heroine_id then
		return 22587
	end
	return 0
end

--结婚场景加时
function Scene_marry:add_time(char_id, time)
	if time <= 0 then
		return 22593
	end
	local ret = self:auth(char_id)
	local obj = g_obj_mgr:get_obj(char_id)
	if ret ~= 0 or obj == nil then return ret end

	local config = self:get_self_config()
	local pack_con = obj:get_pack_con()
	if pack_con:check_money_lock(MoneyType.JADE) then return -1 end
	local money = pack_con:get_money()
	if money.jade < config.out_time[2] * time then 
		return 22592 
	end
	pack_con:dec_money(MoneyType.JADE, config.out_time[2] * time, {['type']=MONEY_SOURCE.MARRY_ADD_TIME})
	integral_func.add_bonus(char_id, config.out_time[2] * time, {['type']=MONEY_SOURCE.MARRY_ADD_TIME})
	self:reset_end_time(self.end_time + config.out_time[1] * time)
	g_marry_mgr:set_fb_addtime(self.instance_id, config.out_time[1] * time)

	return 0
end

--采集物
function Scene_marry:create_collect_obj(obj, collect_id, pos_size)
	local pos = nil
	if pos_size == nil or pos_size <= 0 then
		pos = obj:get_pos()
		local collect_obj = g_obj_mgr:create_npc(collect_id, "", pos, self.key)
		if collect_obj and SCENE_ERROR.E_SUCCESS == self:enter_scene(collect_obj) then
			return true
		end
	else 
		local count = 0
		local map_o = self:get_map_obj()
		local cur_pos = obj:get_pos()
		local pos_m = {cur_pos[1]-5,cur_pos[1]+5,cur_pos[2]-5,cur_pos[2]+5}
		for i = 0, 80 do
			pos = map_o:find_pos(pos_m) or cur_pos
			local collect_obj = g_obj_mgr:create_npc(collect_id, "", pos, self.key)
			if collect_obj and SCENE_ERROR.E_SUCCESS == self:enter_scene(collect_obj) then
				count = count + 1
			end
			if count >= pos_size then
				return true
			end
		end
		if count >= 1 then
			return true
		end
	end
	
	return false
end

--场景自动生成采集物
function Scene_marry:build_collect()
	local config = self:get_self_config()
	local collect_l = config.collect
	if collect_l ~= nil then
		for _, v in ipairs(collect_l) do
			local size = v[2]
			for i = 1, size do
				local pos = self.map_obj:find_space(v[3], 20)
				if pos ~= ni then
					local collect_obj = g_obj_mgr:create_npc(v[1], "", pos, self.key)
					if collect_obj and SCENE_ERROR.E_SUCCESS == self:enter_scene(collect_obj) then
					
					end
				else
					break
				end
			end
		end
	end

end

--摆放物
function Scene_marry:create_stone_obj(obj, stone_id)
	local map_o = self:get_map_obj()
	local pos = obj:get_pos()
	local stone_obj = g_obj_mgr:create_monster(stone_id, pos, self.key)
	if stone_obj and SCENE_ERROR.E_SUCCESS == self:enter_scene(collect_obj) then
		return true
	end
	return false
end

--结婚场景客户端状态改变通知
function Scene_marry:state_notify_c(char_id, stage)
end

--结婚场景通知客户端状态改变
function Scene_marry:state_notify_s(state)
	local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
	local enter_list = con and con:get_obj_list()
	local pkt = {}
	pkt.state = state
	for obj_id, v in pairs(enter_list or {}) do
		self:send_human(obj_id, CMD_MAP_SCENE_MARRY_STATE_NOTIFY_S, pkt)
	end
end

--离开结婚场景
function Scene_marry:leave(char_id)
	if self.marry_state == MARRY_STAGE.BEGINING and (char_id == self.hero_id or char_id == self.heroine_id) then
		return
	end
	
	self:kickout(char_id)
end

-- 开始对话仪式
function Scene_marry:start_dialoge(obj_hero, obj_heroine)
	local pkt = {}
	pkt.state = 0
	pkt.occ = obj_hero:get_occ()
	pkt.name = obj_hero:get_name()
	pkt.gender = obj_hero:get_sex()
	pkt.sp_id = 2
	self:send_human(obj_heroine:get_id(), CMD_MAP_SCENE_MARRY_DIALOGUE_S, pkt)

	pkt.occ = obj_heroine:get_occ()
	pkt.name = obj_heroine:get_name()
	pkt.gender = obj_heroine:get_sex()
	pkt.sp_id = 1
	self:send_human(obj_hero:get_id(), CMD_MAP_SCENE_MARRY_DIALOGUE_S, pkt)

	self.dialogue_stage = 0
	self.dialogue_time = ev.time + 7

	-- 动态NPC
	--self.my_obj = pos and g_dynamic_npc_mgr:create_dynamic_npc(31001, "", self.key, {56, 72}, 300, {['action_id'] = 0} )
end

--广播月老讲话
function Scene_marry:send_old_man_say(pkt)

	local pkt_t = Json.Encode(pkt or {})
	local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
	local enter_list = con and con:get_obj_list()
	for obj_id, v in pairs(enter_list or {}) do
		g_cltsock_mgr:send_client(obj_id, CMD_MAP_MONSTER_SAY_S, pkt_t, true)
	end
end

--用户选择对话
function Scene_marry:select_dialogue(char_id, id)
	--print("Scene_entity:select_dialogue()", char_id, id)
	local entry = _marry_dialogue.config[self.dialogue_stage]
	if entry.speaker == 1 and char_id ~= self.hero_id then
		return 
	end
	if entry.speaker == 2 and char_id ~= self.heroine_id then
		return 
	end

	self.prev_id = entry.contents[id] and id or 1
	self.dialogue_time = ev.time + MARRY_SHOW_DIALOGUE_TIME
end
