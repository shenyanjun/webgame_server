
local sh_config = require("scene_ex.config.sheep_config_loader")
local proto_mgr = require("item.proto_mgr")
local sheep_config = sh_config.myconfig

local cd = {}
cd[990301] = 9
cd[990401] = 9

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


Scene_sheep = oo.class(Scene_instance, "Scene_sheep")

function Scene_sheep:__init(map_id, instance_id, map_obj, end_time)
	Scene_instance.__init(self, map_id, instance_id, map_obj)
	
	self.sheep_list = {}		--当前等级
	self.char_list = {}
	self.sheep_count = 0
	self.wolf_list = {}
	self.wolf_count = 0
	self.pasture_list = {}		--{牧草，下一等级所需牧草}

	self.area_pasture = {}
	self.area_count = {}
	self.pasture_info = {}
	self.skill_cd = {}

	self.wait_relive = {}

	self.end_time = end_time

	self.check_time = ev.time

end


function Scene_sheep:instance()
	local config = sheep_config
	
	self.obj_mgr:instance(self.map_obj:get_w(), self.map_obj:get_h())
	
	local pasture_config = config.pasture.area
	for area, info in pairs(pasture_config) do
		local pt = {}
		pt.id = info.id
		pt.span = info.span
		pt.number = info.number
		pt.cnt = info.count
		pt.count = 0
		pt.timeout = 0
		self.area_pasture[area] = pt
	end
end

--副本出口
function Scene_sheep:get_home_carry(obj)
	local home_carry = sheep_config.home
	if not home_carry or not home_carry.id or not home_carry.pos 
			or not home_carry.pos[1] or not home_carry.pos[2] then
		return nil, nil
	end
	return home_carry.id, home_carry.pos
end

function Scene_sheep:get_self_config()
	return sheep_config
end


function Scene_sheep:carry_scene(obj, pos)
	
	if not pos then
		pos = sheep_config.entry
	end

	local obj_id = obj:get_id()
	if not self.owner_list[obj_id] then
		f_multi_web_sql(string.format("insert into copy_into set copy_id=%d, char_id=%d, time=%d, char_name='%s'"
					, self.id
					, obj_id
					, ev.time
					, obj:get_name()))
	end
	return self:push_scene(obj, pos)
end

function Scene_sheep:check_in()
	if self.sheep_count >= sheep_config.max_sheep then
		return false
	end
	return true
end

--羊升级

function Scene_sheep:up_sheep(obj_id, level, flag)
	local sheep_att = sheep_config.sheep[level]
	--print("Scene_sheep:up_sheep(obj_id, level, flag)", level, j_e(sheep_att))
	if not sheep_att then return end
	local sheep = {}
	sheep.level = sheep_att.level
	sheep.max_pasture = sheep_att.pasture
	sheep.hp = sheep_att.hp
	sheep.max_hp = sheep_att.hp
	sheep.def = sheep_att.def
	sheep.pasture = 0
	self.sheep_list[obj_id] = sheep

	self:send_sheep_info(obj_id)
	if flag then
		self:send_human(obj_id, CMD_MAP_WOLF_CHAR_INFO_S, {["result"] = 20039})
	end
end

--狼数量±
function Scene_sheep:create_wolf()
	local config_count = sheep_config.count[self.sheep_count]
	if not config_count then
		print("config_count is nil", config_count, self.sheep_count)
		return 
	end
	local count = math.max((config_count - (self.wolf_count or 0)), 0)
	local wolf = sheep_config.wolf
	if not wolf then
		print("no wolf config")
		return
	end
	for i = 1, count do
		local pos = self.map_obj:find_space(wolf.area, 20)
		--pos = {133, 147}
		local obj = g_obj_mgr:create_monster(wolf.id, pos, self.key)
		if obj and SCENE_ERROR.E_SUCCESS == self:enter_scene(obj) then
			local id = obj:get_id()
			self.wolf_list[id] = true
			self.wolf_count = self.wolf_count + 1
		else
			print("Error:not obj or enter scene error")
			break
		end
	end
end

function Scene_sheep:remove_wolf()
	
	local config_count = sheep_config.count[self.sheep_count]
	if not config_count then
		print("config_count is nil", config_count, self.sheep_count)
		return 
	end
	local count = math.max((self.wolf_count - config_count), 0)
	--print("remove_wolf()", self.sheep_count, self.wolf_count, config_count, count)
	local k = 0
	for m, _ in pairs(self.wolf_list) do
		if k >= count then
			return 
		end
		local obj = g_obj_mgr:get_obj(m)
		if obj then
			obj:leave()
			k = k + 1
			self.wolf_list[m] = nil
			self.wolf_count = self.wolf_count - 1
			--print("rm wolf")
		end
	end
end

function Scene_sheep:on_obj_enter(obj)
	local obj_id = obj:get_id()
	local type = obj:get_type()
	local occ = obj:get_occ()
	if OBJ_TYPE_HUMAN == type then
		if not self.sheep_list[obj_id] then
			self:up_sheep(obj_id, 1)
			self.pasture_list[obj_id] = 0
		end
		self:send_sheep_info(obj_id)
		self.skill_cd[obj_id] = {}
		self.sheep_count = self.sheep_count + 1
		self.char_list[obj_id] = obj_id

		if self.check_obj_team == nil then
			self.check_obj_team = {}
			self.check_obj_team_time = ev.time + 1
		end
		self.check_obj_team[obj_id] = 1

	end

end

function Scene_sheep:on_obj_leave(obj)
	local obj_id = obj:get_id()
	local type = obj:get_type()
	local occ = obj:get_occ()
	if OBJ_TYPE_HUMAN == type then
		local pkt = {}
		pkt.type = 1
		local json = Json.Encode(pkt)
		self:send_human(obj_id, CMD_MAP_WOLF_END_S, json, true)
		self.char_list[obj_id] = nil
		if not obj:is_alive() then
			self.wait_relive[obj_id] = nil
			obj:do_relive(1, true)
		end
		self.sheep_count = math.max(self.sheep_count - 1, 0)
		self:remove_wolf()
	elseif OBJ_TYPE_NPC == type then
		local area = self.area_count[obj_id]
		if area then
			local pasture = self.area_pasture[area]
			if pasture then
				pasture.count = math.max(pasture.count - 1, 0)
			end
		end
	end

end

function Scene_sheep:update_pasture()
	--print("Scene_sheep:update_pasture()")
	local obj_mgr = g_obj_mgr
	local now = ev.time
	for area, pasture in pairs(self.area_pasture or {}) do
		
		if pasture.timeout <= now then
			while pasture.count < pasture.number do
				pasture.timeout = now + pasture.span
				local pos = self.map_obj:find_space(area, 20)
				if pos then
					--print("pppppp", pos[1], pos[2])
					local obj = obj_mgr:create_npc(pasture.id, "", pos, self.key)
					if obj and SCENE_ERROR.E_SUCCESS == self:enter_scene(obj) then
						local id = obj:get_id()
						pasture.count = pasture.count + 1
						self.area_count[id] = area
						self.pasture_info[pasture.id] = pasture
					else
						print("Error:not obj or enter scene error")
						break
					end
				end
			end
		end
	
	end
end

function Scene_sheep:search_monster()
	local obj_mgr = g_obj_mgr
	local leave = sheep_config.leave
	if not leave then return end
	local monster_list = self.map_obj:scan_one_monster_in_pos_area(leave.pos, leave.dis, 2)
	local flag = false
	for k, v in pairs(monster_list or {}) do
		local obj = obj_mgr:get_obj(k)
		if obj then
			local occ = obj:get_occ()
			obj:leave()
			self.wolf_count = self.wolf_count - 1
			flag = true
		end
	end
end


function Scene_sheep:end_copy()

	local pkt = {}
	pkt.type = 2
	local json = Json.Encode(pkt)
	for k, v in pairs(self.char_list) do
		self:send_human(k, CMD_MAP_WOLF_END_S, json, true)
	end
	for m, _ in pairs(self.wolf_list) do
		local obj = g_obj_mgr:get_obj(m)
		if obj then
			obj:leave()
		end
	end
	for p, _ in pairs(self.area_count) do
		local obj = g_obj_mgr:get_obj(p)
		if obj then
			obj:leave()
		end
	end
end

function Scene_sheep:on_timer(tm)
	
	local now = ev.time
	if not self.close_time and self.end_time <= now then
		self.close_time =  now + 30
		self:end_copy()
	end

	if self.close_time and self.close_time <= now then
		self:close()
	end

	if self.check_time < ev.time then
		self.check_time = ev.time + 2
		self:create_wolf()
	end

	self:search_monster()
	self:update_pasture()
	self:do_relive(now)
	self.obj_mgr:on_timer(tm)
	if self.check_obj_team ~= nil and ev.time >= self.check_obj_team_time then
		for k, v in pairs(self.check_obj_team) do
			local obj = g_obj_mgr:get_obj(k)
			local team_id = obj and obj:get_team()
			local team_o = team_id and g_team_mgr:get_team_obj(team_id)
			if team_o ~= nil then
				f_team_kickout(obj)
			end
		end
		self.check_obj_team = nil
	end
end

function Scene_sheep:can_use(item_id)
	if contraband_list[item_id] then
		return false
	end
	return true
end

function Scene_sheep:be_attack(obj_id, killer_id)
	local killer = g_obj_mgr:get_obj(killer_id)
	local obj = g_obj_mgr:get_obj(obj_id)
	local att = sheep_config.wolf.att
	local relive = sheep_config.relive
	if not self.char_list[obj_id] then
		print("char not in scene")
		return
	end
	if not obj or not att or not relive then return end
	local hp = math.floor(att/(self.sheep_list[obj_id].def))
	self.sheep_list[obj_id].hp = math.max((self.sheep_list[obj_id].hp - hp), 0)

	self:send_sheep_info(obj_id)
	if self.sheep_list[obj_id].hp <= 0 then
		obj:on_die(killer)
	end
end

function Scene_sheep:send_sheep_info(obj_id)
	local info = {}
	local sheep = self.sheep_list[obj_id]
	info[1] = sheep.hp
	info[2] = sheep.max_hp
	info[3] = sheep.level
	info[4] = sheep.pasture
	info[5] = sheep.max_pasture
	local pkt = {}
	pkt.info = info
	pkt.result = 0
	local json = Json.Encode(pkt)
	--print("sheep_info:", json)
	self:send_human(obj_id, CMD_MAP_WOLF_CHAR_INFO_S, json, true)
end

function Scene_sheep:die_event(args)
	local obj_id = args.char_id
	local obj = self:get_obj(obj_id)
	if obj then
		local relive = sheep_config.relive
		self.wait_relive[obj_id] = ev.time + relive.time			--加入等待复活列表
		obj:set_kill_status(0)
		args.mode = 1
		args.is_notify = false
		args.is_evil = false
		args.relive_time = relive.time or 20
	end
end

function Scene_sheep:do_relive(now_time)
	local obj_mgr = g_obj_mgr
	for char_id, time in pairs(self.wait_relive) do
		if time < now_time then
			self.wait_relive[char_id] = nil
			local obj = obj_mgr:get_obj(char_id)
			if obj then
				self:relive_sheep(obj)
			end
		end
	end
end

function Scene_sheep:relive_sheep(obj)
	if obj:is_alive() then
		return
	end
	local relive = sheep_config.relive
	local pos = relive.pos
	obj:do_relive(1, true)	--复活
	obj:send_relive(relive.time)
	local obj_id = obj:get_id()
	self:up_sheep(obj_id, 1)
	self:transport(obj, pos)
end


function Scene_sheep:can_be_collected()
	return 0
end

function Scene_sheep:use_skill(obj_id, skill_id)
	
	skill_id  = tonumber(skill_id)
	if self.skill_cd[obj_id][skill_id] and self.skill_cd[obj_id][skill_id] > ev.time then
		return 21113
	end
	local skill_o = g_skill_mgr:get_skill(skill_id)
	if not skill_o then 
		print("====scene_sheep:skill_o is nil") 
		return SCENE_ERROR.E_INVALID_CONFIG
	end

	local param = {}
	param.des_id = obj_id
	local ret = skill_o:effect(obj_id, param)
	if ret == 0 then
		self.skill_cd[obj_id][skill_id] = ev.time + cd[skill_id]
	end
	return ret, skill_id
end


function Scene_sheep:obj_be_collected(obj_id, obj_c)
	local obj = g_obj_mgr:get_obj(obj_id)
	if not obj then	return end
	local treasure_id = obj_c:get_occ()
	--print("treasure_id:", treasure_id)
	local list = sheep_config.treasure[treasure_id]
	print(sheep_config.treasure, list)
	for k, v in pairs(sheep_config.treasure) do
		--print("kv", k, j_e(v))
	end
	if not list then 
		return
	end
	--print("list = config.treasure[treasure_id]:", treasure_id)
	local reward_l = {}
	local broadcast = false
	--print(j_e(list))
	local exp = list.exp
	for _, info in pairs(list.item_l) do
		local count = info.count
		local item_l = info.item_l
		local random_item_l = sh_config.random_algorithm(item_l, count, (function(e) return e.value end))
		for _, v in pairs(random_item_l) do
			if item_l[v].item_id == 0 then
				--print("get_any_item")
			else
				if item_l[v].broadcast == 1 then
					broadcast = true
				end
				table.insert(reward_l, item_l[v])
			end
		end
	end
	local pack_con = obj:get_pack_con()
	local err = pack_con:check_add_item_l_inter_face(reward_l)
	local name_l = ""
	if err == 0 then
		obj:add_exp(exp)
		name_l = name_l .. obj:get_name()
		pack_con:add_item_l(reward_l, {['type']=ITEM_SOURCE.SHEEP})
	end
	if broadcast and err == 0 then
		local string = {}
		f_construct_content(string, f_get_string(3101), 15)
		f_construct_content(string, name_l, 53)
		f_construct_content(string, f_get_string(3102), 15)
		
		for _, v in pairs(reward_l) do
			local e_code, proto = proto_mgr.get_proto(v.item_id)
			if proto then 
				local num = ""
				if v.number >= 1 then
					num = f_get_string(3104) .. v.number
				end
				local item_name = proto.value.name .. num .. ","
				local item_color = proto.value.color
				f_construct_content(string, item_name, item_color)
			end
		end
		f_construct_content(string, f_get_string(3103), 15)
		f_cmd_sysbd(string, 2)
	end
	--print("=======>", j_e(self.pasture_info[treasure_id].cnt))
	self.pasture_list[obj_id] = self.pasture_list[obj_id] + self.pasture_info[treasure_id].cnt
	self.sheep_list[obj_id].pasture = self.sheep_list[obj_id].pasture + self.pasture_info[treasure_id].cnt
	
	local ret = {}
	ret.count = self.pasture_info[treasure_id].cnt
	ret.id = treasure_id
	g_event_mgr:notify_event(EVENT_SET.EVENT_SHEEP_RUN, obj_id, ret)

	self:send_sheep_info(obj_id)
	if self.sheep_list[obj_id].pasture >= self.sheep_list[obj_id].max_pasture then
		local level = self.sheep_list[obj_id].level
		self:up_sheep(obj_id, level + 1, true)
	end
end
