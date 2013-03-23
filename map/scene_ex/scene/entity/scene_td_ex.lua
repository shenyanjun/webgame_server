local debug_print = print
local debug_print = function () end

local td_ex_config = require("scene_ex.config.td_ex_config_loader")

local close_timeout = 5
--local _max_mon_area = 30    --怪区最大值
local _monster_id = {}
_monster_id[202] = 9217
_monster_id[203] = 9218

local _skill = {}
_skill[101] = 1004209
_skill[102] = 1004210
_skill[201] = 990201

local max_skill_time = 48

Scene_td_ex = oo.class(Scene_instance, "Scene_td_ex")

function Scene_td_ex:__init(map_id, instance_id, map_obj)
	Scene_instance.__init(self, map_id, instance_id, map_obj)
	
	self.heart_id = nil
	self.sequence = 0
	self.counter = {}
	self.next_time = ev.time
	
	self.is_success = false
	self.is_faild = false
	self.end_time = nil
	
	self.skill_cnt = {}
	self.max_monster_cnt = {}
	self.monster_cnt = {}
	self.monster_get_skill = {}
	self.item_get_skill = {}
	self.skill_l = {}
	self.skill_index = {}
	self.skill_len = 0
	self.in_copy = false
	self.enter_flag = false
	self.skill_time = {}

	self.guard_list = {}
	self.guard_hp = {}
	self.occ = 0

	self.name = ""
	self.heart_hp = 0

	self.update_over = false
	self.obj_con = Scene_obj_container()
	self:init_skill_cnt()
end

function Scene_td_ex:init_skill_cnt()
	local helper = td_ex_config.config[self.id].helper
	local buff_list = helper and helper.buff
	for k, v in pairs(buff_list or {}) do
		self.skill_cnt[k] = 0
		self.item_get_skill[v.desc_id]  = k
	end
end

function Scene_td_ex:instance(args)
	local teamer = args.obj
	self.char_id = teamer:get_id()
	self.occ = teamer:get_occ()
	local config = td_ex_config.config[self.id]
	
	self.obj_mgr:instance(self.map_obj:get_w(), self.map_obj:get_h())
	
	local heart = config.heart
	local obj = g_obj_mgr:create_monster(heart.id, heart.pos, self.key)
	self.heart_id = obj:get_id()
	self:enter_scene(obj)

	local helper = config.helper
	local guard_list = helper and helper.guard
	local guard = guard_list and guard_list[heart.id]
	self.guard_list[heart.id] = {
		["id"] = self.heart_id
		, ["name"] = guard and guard.name
		, ["index"] = 0
	}
	for k, v in pairs(guard_list or {}) do
		local obj = g_obj_mgr:create_monster(k, v.pos, self.key, {self.instance_id})
		self.guard_list[k] = {
			["id"] = obj:get_id()
			, ["name"] = v.name
			, ["index"] = v.index
			}
		self.guard_hp[v.index] = 0
		self:enter_scene(obj)
	end
	if args and args.target then
		self.sequence = math.max(args.target - 1, 0)
		for obj_id, obj in pairs(args.members or {}) do
			local con = obj:get_copy_con()
			con:add_count_copy(self.id)
			self.owner_list[obj_id] = true
			
			f_multi_web_sql(string.format("insert into copy_into set copy_id=%d, char_id=%d, time=%d, char_name='%s'"
						, self.id
						, obj_id
						, ev.time
						, obj:get_name()))
		end
		--self.not_human = false
	end
end

function Scene_td_ex:get_last_time(obj)
	return nil
end

function Scene_td_ex:get_owner()
	return self.char_id
end

function Scene_td_ex:on_obj_enter(obj)
	if obj:get_type() == OBJ_TYPE_HUMAN then
		debug_print("======human enter")
		local obj_id = obj:get_id()	
		self.char_id = obj_id
		self.in_copy = true
		self.enter_flag = true
		g_scene_mgr_ex:register_event(EVENT_SET.EVENT_DEL_TEAM, obj_id, self, self.del_team_event)
		local args = obj:get_scene_args()
		local id = tostring(self.id)
		local max_layer = args[id] or 0
		if max_layer < self.sequence then
			args[id] = self.sequence
		end
		local pkt = {}
		local json = Json.Encode(pkt)
		self:send_human(self.char_id, CMD_MAP_TD_EX_ENTER_S, json, true)
		--[[--
		--test
		for k = 101, 111 do 
			for i = 1, 10 do
				self:add_skill(k)
			end
			--self:use_skill(self.char_id, k)
		end
		for k = 202, 203 do 
			for i = 1, 10 do
				self:add_skill(k)
			end
			--self:use_skill(self.char_id, k)
		end
		--]]--
	end
end


function Scene_td_ex:on_failed()
	self.end_time = ev.time + close_timeout
	local pkt = string.format('{"time":%d}', close_timeout)
	self:send_human(self.char_id, CMD_MAP_WAIT_TIMEOUT_NOTIFY, pkt, true)
	
	local sql = "insert into copy_failed set char_id=%d, "..
			string.format(
				"copy_id=%d, run_num=%d, time=%d"
				, self.id
				, self.sequence
				, ev.time)
	
	local member_list = {}

	f_multi_web_sql(string.format(sql, self.char_id))
	table.insert(member_list, self.char_id)
		
	local obj = g_obj_mgr:get_obj(self.heart_id)
	if obj then
		f_scene_info_log("Scene_td_ex:on_failed(%d, %d, %d, %s, %s)", obj:get_hp(), obj:get_max_hp(), obj:get_occ(), tostring(obj:is_alive()), table.concat(member_list, ","))
	else
		f_scene_info_log("Scene_td_ex:on_failed(not obj, %s)", table.concat(member_list, ","))
	end
end

function Scene_td_ex:clear_skill_time()
	self.skill_time = {}
end

function Scene_td_ex:on_obj_leave(obj)
	local obj_id = obj:get_id()
	if obj:get_type() == OBJ_TYPE_HUMAN then
		g_scene_mgr_ex:unregister_event(EVENT_SET.EVENT_DEL_TEAM, obj_id)
		self.in_copy = false
		self:clear_skill_time()
	elseif self.heart_id == obj_id and self.instance_id then
		self:on_failed()
	else		
		local occ = obj:get_occ()
		if self.monster_cnt[occ] then
			self.monster_cnt[occ] = self.monster_cnt[occ] + 1
			if self.monster_cnt[occ] >= self.max_monster_cnt[occ] then
				self.monster_cnt[occ] = 0
				local skill_id = self.monster_get_skill[occ]
				self:add_skill(skill_id)
			end
		end

		if self.guard_list[occ] then
			self.guard_list[occ] = nil
		end

		self.obj_con:pop_obj(obj_id)
	end
end

function Scene_td_ex:carry_scene(obj, pos)
	
	local obj_id = obj:get_id()
	if obj_id ~= self.char_id then return 
		SCENE_ERROR.E_HUMAN_LIMIT
	end
	if self.end_time then
		return SCENE_ERROR.E_SCENE_CLOSE
	end
	if not pos then
		pos = td_ex_config.config[self.id].entry
	end
	return Scene_instance.carry_scene(self, obj, pos)
end

function Scene_td_ex:close()
	if self.instance_id then
		
		local data = {}
		local obj_mgr = g_obj_mgr
		local obj = obj_mgr:get_obj(self.char_id)
		if obj then
			table.insert(data, {["id"] = self.char_id, ["name"] = obj:get_name()})
		end
		
		g_public_sort_mgr:update_record(
			PUBLIC_SORT_TYPE.SCENE
			, self.sequence
			, {["scene_id"] = self.id, ["id"] = 0, ["data"] = data}
			, PUBLIC_SORT_ORDER.DESC)
		
		Scene_instance.close(self)
	end
end

function Scene_td_ex:send_success()
	local pkt = {}
	pkt.result = 0
	local json = Json.Encode(pkt)
	self:send_human(self.char_id, CMD_MAP_TD_EX_SUCCESS_S, json, true)
end

function Scene_td_ex:next_sequence()
	if self.is_success or self.is_faild then
		return
	end

	self.sequence = self.sequence + 1
	self.counter = {}
	self.update_over = false
	local declare = td_ex_config.config[self.id].declare
	
	local freq = declare[self.sequence]
	if not freq then
		if self.obj_con:get_obj_count() == 0 then
			self:send_success()
			self.is_success = true
		else
			self.is_faild = true
			self:on_failed()
		end
		--self:close()
		return
	end
	
	local skill_list = freq.skill
	for _, info in pairs(skill_list or {}) do
		--print("occ:", self.sequence, self.occ, info.occ, info.id)
		if  info.occ and self.occ == info.occ then
			for monster_id, number in pairs(info.monster or {}) do
				--print("monster:", monster_id, number)
				self.monster_cnt[monster_id] = 0
				self.max_monster_cnt[monster_id] = number
				self.monster_get_skill[monster_id] = info.id
			end
		end
	end

	local obj_mgr = g_obj_mgr
	local obj = obj_mgr:get_obj(self.char_id)
	if obj then
		local args = obj:get_scene_args()
		local id = tostring(self.id)
		local max_layer = args[id] or 0
		if max_layer < self.sequence then
			args[id] = self.sequence
		end
	end

	self.next_time = ev.time + freq.interval
	
	if freq.sequence then
		for _, item in pairs(freq.sequence) do
			local info = {}
			info.item = item
			info.count = 0
			info.timeout = ev.time
			table.insert(self.counter, info)
		end
	end
end

function Scene_td_ex:update()
	local has_update = false
	
	local born = td_ex_config.config[self.id].born
	local obj_mgr = g_obj_mgr
	local now = ev.time

	for k, info in pairs(self.counter) do
		if info.timeout <= now then
			local item = info.item
			if info.count < item.count then
				info.count = info.count + 1
				info.timeout = now + item.span
				
				local path = born[item.path]
				local args = {path.path, self.heart_id}
				for i = 1, item.number do
					local obj = obj_mgr:create_monster(item.id, path.pos, self.key, args)
					self:enter_scene(obj)
					self.obj_con:push_obj(obj:get_id())
				end
			else
				self.counter[k] = nil
			end
		end
		has_update = true
	end

	if not has_update then
		self.update_over = true
	end
end

function Scene_td_ex:on_slow_timer(tm)
	self.obj_mgr:on_slow_timer(tm)
end

function Scene_td_ex:update_skill(buff_id)
	local time = self.skill_time[buff_id]
	if time and time.now < ev.time then
		time.now = time.now + 5
		self:on_use_skill(self.char_id, buff_id)
		if time.now > time.st + max_skill_time then
			self.skill_time[buff_id] = nil 
		end
	end
end

function Scene_td_ex:on_timer(tm)
	local now = ev.time
	if self.end_time and self.end_time <= now then
		self:close()
		return
	end
	
	if self.next_time <= now then
		self:next_sequence()
	end
	
	self:update()
	self.obj_mgr:on_timer(tm)
	self:update_skill(101)
	self:update_skill(102)

	if not self.end_time then
		local freq = td_ex_config.config[self.id].declare[self.sequence]
		if freq then
			local obj_mgr = g_obj_mgr
			
			local heart = {0, 0}
			local obj = self.heart_id and obj_mgr:get_obj(self.heart_id)
			if obj then
				heart = {obj:is_alive() and obj:get_hp() or 0, obj:get_max_hp()}
			end
			
			
			local npc_list = {}
			---[[--
			local send_flag = false
			for occ, info in pairs(self.guard_list) do
				if self.heart_id ~= info.id then
					local npc = {info.index, 0, 0}
					local obj_npc = obj_mgr:get_obj(info.id)
					if obj_npc then
						local index = info.index
						local guard_hp = obj_npc:get_hp()
						if guard_hp ~= self.guard_hp[index] then
							send_flag = true
							self.guard_hp[index] = guard_hp
						end
						table.insert(npc_list, {index, guard_hp, obj_npc:get_max_hp()})
					else
						table.insert(npc_list, npc)
					end
				end
			end
			--]]--
			local heart_hp = obj and obj:get_hp() or 0
			local name = freq.name
			if self.in_copy == true and (self.enter_flag == true or self.name ~= name or self.heart_hp ~= heart_hp or send_flag == true) then
				self.enter_flag = false
				self.name = name
				self.heart_hp = heart_hp
				local pkt = {
					  ["blood"] = heart
					, ["time"] = math.max(self.next_time - now, 0)
					, ["desc"] = freq.text
					, ["name"] = freq.name
					, ["npc"]  = npc_list 	
				}
				
				local json = Json.Encode(pkt)
				--print("heart:", json)
				self:send_human(self.char_id, CMD_TD_EX_SEND_TIME_S, json, true)
			end
			
		end
	end
end

function Scene_td_ex:is_attack(attacker_id, defender_id)
	if self.end_time then
		return SCENE_ERROR.E_ATTACK_BAN
	end

	if self.heart_id == defender_id then
		local type = Obj_mgr.obj_type(attacker_id)
		if OBJ_TYPE_HUMAN == type or OBJ_TYPE_PET == type then
			return SCENE_ERROR.E_HEART
		end
	end
	
	local scene_mode = g_scene_config_mgr:get_mode(self:get_mode())
	if not scene_mode then
		return SCENE_ERROR.E_INVALID_ID
	end
	
	local attacker = self:get_obj(attacker_id)
	if not attacker then
		return SCENE_ERROR.E_NOT_ON_SCENE
	end
	
	local defender = self:get_obj(defender_id)
	if not defender then
		return SCENE_ERROR.E_NOT_ON_SCENE
	end
	
	if OBJ_TYPE_PET == attacker:get_type() then
		attacker = g_obj_mgr:get_obj(attacker:get_owner_id())
	end
	
	if OBJ_TYPE_HUMAN == attacker:get_type() and defender:get_occ() > MONSTER_GUARD then
		return SCENE_ERROR.E_HEART
	end
	
	if OBJ_TYPE_HUMAN == defender:get_type() and attacker:get_occ() > MONSTER_GUARD then
		return SCENE_ERROR.E_HEART
	end
		
	return scene_mode:can_attack(attacker, defender)
end

--[[--
function Scene_td_ex:summon_guard(obj_id, occ)
	if obj_id ~= self:get_owner() then
		return SCENE_ERROR.E_CAPTION_USE
	end
	
	local obj = self:get_obj(obj_id)
	if not obj then
		return SCENE_ERROR.E_NOT_ON_SCENE
	end
	
	local helper = td_ex_config.config[self.id].helper
	local guard_list = helper and helper.guard
	local guard = guard_list and guard_list[occ]
	if not guard then
		return SCENE_ERROR.E_NOT_CONFIG
	end
	
	local npc = self.guard_list[occ]
	if npc then
		return SCENE_ERROR.E_EXIST_NPC
		
	else
		local info = guard.level_list[1]
		if self.total_mana < info.mana then
			return SCENE_ERROR.E_NOT_MANA
		end
		
		local pack_con = obj:get_pack_con()
		if info.item_id then
			if pack_con:get_item_count(info.item_id) < 1 then
				return SCENE_ERROR.E_NOT_ITEM
			end
			
			if 0 ~= pack_con:del_item_by_item_id(info.item_id, 1, {['type'] = ITEM_SOURCE.USE_ITEM}) then
				return SCENE_ERROR.E_NOT_ITEM
			end
		end
		
		self.total_mana = self.total_mana - info.mana
		local monster = g_obj_mgr:create_monster(occ, guard.pos, self.key, {self.instance_id})
		if occ == 9204 and monster ~= nil then
			monster:set_heart_id(self.heart_id)
		end
		self:enter_scene(monster)
		self.guard_list[occ] = {
			["id"] = monster:get_id()
			, ["lv"] = 1
			, ["name"] = guard.name
		}
	end
	
	return SCENE_ERROR.E_SUCCESS
end
--]]--

function Scene_td_ex:add_skill(skill_id)
	debug_print("Scene_td_ex:add_skill(skill_id)", skill_id)
	self.skill_cnt[skill_id] = self.skill_cnt[skill_id] + 1
	local helper = td_ex_config.config[self.id].helper
	local buff_l = helper and helper.buff
	local buff = buff_l and buff_l[skill_id]
	if self.in_copy == true then
		local pkt = {}
		pkt.item_id = buff and buff.desc_id
		--pkt.id = skill_id
		local json = Json.Encode(pkt)
		debug_print("add_skill", json)
		self:send_human(self.char_id, CMD_MAP_TD_EX_ADD_SKILL_S, json, true)
	end
	local index = self.skill_index[skill_id]
	if index and self.skill_l[index] then
		self.skill_l[index].count = self.skill_cnt[skill_id]
		debug_print("find index", index, self.skill_l[index])
	else
		debug_print("no_index")
		self.skill_len = self.skill_len + 1
		self.skill_index[skill_id] = self.skill_len
		local skill = {}
		--skill.id = skill_id
		--skill.name = buff.name
		skill.count = self.skill_cnt[skill_id]
		skill.item_id = buff.desc_id
		self.skill_l[self.skill_len] = skill
	end
	self:send_skill_list()
end

function Scene_td_ex:send_skill_list(obj)
	if self.in_copy == true then
		local pkt = {}
		pkt.skill_l = self.skill_l
		local json = Json.Encode(pkt)
		debug_print("skill_list", json)
		self:send_human(self.char_id, CMD_TD_EX_GET_SKILL_S, json, true)
	end
end

function Scene_td_ex:del_skill(obj_id, skill_id)
	debug_print("Scene_td_ex:del_skill(skill_id)", skill_id)
	local index = self.skill_index[skill_id]
	if not index then return end
	self.skill_cnt[skill_id] = self.skill_cnt[skill_id] - 1
	self.skill_l[index].count = self.skill_cnt[skill_id]
	if self.skill_cnt[skill_id] <= 0 then
		for i = index, self.skill_len - 1 do
			self.skill_l[i] = self.skill_l[i + 1]
			local item_skill_id = self.item_get_skill[self.skill_l[i].item_id]
			self.skill_index[item_skill_id] = i
		end
		self.skill_l[self.skill_len] = nil
		self.skill_index[skill_id] = nil
		self.skill_len = self.skill_len - 1
	end
	self:send_skill_list(obj_id)
end

function Scene_td_ex:use_skill(obj_id, item_id)
	if obj_id ~= self.char_id then
		return SCENE_ERROR.E_CAPTION_USE
	end
	debug_print("Scene_td_ex:use_skill", obj_id, item_id)
	local skill_id = self.item_get_skill[item_id]
	self:on_use_buff(obj_id, skill_id)
	local helper = td_ex_config.config[self.id].helper
	local buff_list = helper and helper.buff
	local skill = buff_list and buff_list[skill_id]
	if not skill then
		return SCENE_ERROR.E_NOT_CONFIG
	end
	
	if self.skill_cnt[skill_id] <= 0 then
		return SCENE_ERROR.E_NO_SKILL
	end
	self:del_skill(obj_id, skill_id)
	if skill_id > 0 and skill_id < 200 then
		self:on_use_buff(obj_id, skill_id)
	elseif skill_id > 200 and skill_id < 300 then
		if skill_id == 201 then
			self:on_use_skill(obj_id, skill_id)
		else
			self:on_summon_monster(obj_id, skill_id)
		end
	end
	return SCENE_ERROR.E_SUCCESS
end


function Scene_td_ex:on_use_skill(obj_id, skill_id)
	debug_print("Scene_td_ex:on_use_skill", obj_id, skill_id)
	local sk_id = _skill[skill_id]
	local skill_o = g_skill_mgr:get_skill(sk_id)
	local param = {}
	param.des_id = self.char_id
	skill_o:effect(obj_id, param)
end

function Scene_td_ex:on_use_buff(obj_id, buff_id)
	debug_print("Scene_td_ex:on_use_buff", obj_id, buff_id)
	if buff_id == 101 or buff_id == 102 then --嗜血
		self:on_use_skill(obj_id, buff_id)
		local time = {}
		time.now = ev.time
		time.st = ev.time
		self.skill_time[buff_id] = time
	end
	f_td_ex_add_impact(obj_id, buff_id)
end

function Scene_td_ex:on_summon_monster(obj_id, skill_id)
	debug_print("Scene_td_ex:on_summon_monster", obj_id, skill_id)
	
	local obj_mgr = g_obj_mgr
	local obj = obj_mgr:get_obj(obj_id)
	local param = {}
	local cur_pos = obj and obj:get_pos()
	local pos_m = {cur_pos[1]-5,cur_pos[1]+5,cur_pos[2]-5,cur_pos[2]+5}
	local map_o = self:get_map_obj()
	local pos = map_o:find_pos(pos_m)
	local obj = obj_mgr:create_monster(_monster_id[skill_id], pos, self.key, {30, self.char_id})
	self:enter_scene(obj)
end


function Scene_td_ex:use_refresh(obj_id)
	if obj_id ~= self:get_owner() then
		return SCENE_ERROR.E_CAPTION_USE
	end

	debug_print(self.update_over, self.obj_con:get_obj_count())

	if not self.update_over or 0 ~= self.obj_con:get_obj_count() then
		return SCENE_ERROR.E_UPDATE_OVER
	end
	
	self:next_sequence()

	return SCENE_ERROR.E_SUCCESS
end