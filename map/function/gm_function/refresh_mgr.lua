
local _config = require("function.gm_function.refresh_loader")
local _random = crypto.random
local space = 60*60

local special_monster_id = 5334 --鹊桥活动 搞了个刷怪特效，做了点特殊处理

Refresh_mgr = oo.class(nil,"Refresh_mgr")

function Refresh_mgr:__init()
	self.function_list = {}
end

function Refresh_mgr:get_click_param()
	return self,self.on_timer,30,nil
end

function Refresh_mgr:on_timer(tm)
	self:on_refresh_timer(tm)
end

function Refresh_mgr:on_refresh_timer(tm)
	if f_is_pvp() or f_is_line_faction() then return end		--非正常线
	local now = ev.time
	local today = f_get_today()
	for k,_ in pairs(self.function_list or {}) do
		self:clean(k)
	end
	for id,list in pairs(_config.GmRefreshTable or {}) do
		if now >= list.start_time and now < list.end_time then
			for i,v in pairs(list.time_list or {}) do
				if now >= tonumber(today+v[1]) and now <= tonumber(today+v[2]) then
					if not v[3] then
						v[3] = now+list.space_time
						self:do_fresh(id,list)
					elseif v[3] and now >= v[3] then
						v[3] = now+list.space_time
						self:do_fresh(id,list)
					end
					break	--每次只刷新一个
				end
			end
		end 
	end
end

function Refresh_mgr:clean(id)
	if not self.function_list[id] then return end
	local list = nil
	local now = ev.time
	--怪物
	list = self.function_list[id].monster_list
	if list then
		for occ,v in pairs(list or {}) do
			for index,index_l in pairs(v or {}) do
				local b = true
				if now >= index_l.time then
					for k,_ in pairs(index_l.list or {}) do
						local obj = g_obj_mgr:get_obj(k)
						if obj and not obj:is_combat() then
							local _ = obj:leave()
						else
							b = false
						end
					end
					if b then
						v[index] = nil
					end
				end	
			end		
			if table.maxn(list[occ]) == 0 then
				list[occ] = nil
			end
		end
		if table.maxn(list) == 0 then
			self.function_list[id].monster_list = nil
		end
	end 
	--采集
	list = self.function_list[id].npc_list
	if list then
		for occ,v in pairs(list or {}) do
			for index,index_l in pairs(v or {}) do
				if now >= index_l.time then
					for k,_ in pairs(index_l.list or {}) do
						f_npc_leave(k)	
					end
					v[index] = nil
				end
			end
			if table.maxn(list[occ]) == 0 then
				list[occ] = nil
			end
		end
		if table.maxn(list) == 0 then 
			self.function_list[id].npc_list = nil
		end
	end 
	--掉落包
	list = self.function_list[id].box_list
	if list then
		for occ,v in pairs(list or {}) do
			for index,index_l in pairs(v or {}) do
				if now >= index_l.time then
					for k,_ in pairs(index_l.list or {}) do
						local obj = g_obj_mgr:get_obj(k)
						local _ = obj and obj:leave()
					end
					v[index] = nil
				end						
			end	
			if table.maxn(list[occ]) == 0 then
				list[occ] = nil
			end		
		end
		if table.maxn(list) == 0 then
			self.function_list[id].box_list = nil
		end
	end 

	if not self.function_list[id].monster_list and not self.function_list[id].npc_list and not self.function_list[id].box_list then
		self.function_list[id] = nil
	end 
end

--刷新
function Refresh_mgr:do_fresh(id,list)
	if not self.function_list[id] then
		self.function_list[id] = {}
		self.function_list[id].monster_list = {}
		self.function_list[id].npc_list = {}
		self.function_list[id].box_list = {}
	end
	local num_pos = #list.position_list
	local max_num = math.max(#list.monster_list,#list.npc_list,#list.box_list)
	local s_id = list.map_id
	local now = ev.time
	local str_name = ""
	local index = tonumber(os.date("%H%M%S",ev.time))
	local broadcast = false
	local effect_id = nil --全服播放特效,提醒玩家
	local special_effect_id = nil
		
	for i=1,max_num do
		local create_number = math.max(list.monster_list[i] and list.monster_list[i].number or 0,
										list.npc_list[i] and list.npc_list[i].number or 0,
										list.box_list[i] and list.box_list[i].number or 0) 

		if list.monster_list[i] then
			if not self.function_list[id].monster_list[i] then
				self.function_list[id].monster_list[i] = {}
			end
			str_name = list.monster_list[i].name..","..str_name
			self.function_list[id].monster_list[i][index] = {}
			self.function_list[id].monster_list[i][index].time = now+space
			self.function_list[id].monster_list[i][index].list = {}
		end

		if list.npc_list[i] then
			if not self.function_list[id].npc_list[i] then
				self.function_list[id].npc_list[i] = {}
			end
			str_name = list.npc_list[i].name..","..str_name
			self.function_list[id].npc_list[i][index] = {}
			self.function_list[id].npc_list[i][index].time = now+space
			self.function_list[id].npc_list[i][index].list = {}
		end
		if list.box_list[i] then
			if not self.function_list[id].box_list[i] then
				self.function_list[id].box_list[i] = {}
			end
			str_name = list.box_list[i].name..","..str_name
			self.function_list[id].box_list[i][index] = {}
			self.function_list[id].box_list[i][index].time = now+space
			self.function_list[id].box_list[i][index].list = {}
		end
		
		for n=1,create_number do
			local pos_l = nil
			if num_pos > 0 then
				local index_pos = _random(1, num_pos+1)
				pos_l = {}
				pos_l[1] = list.position_list[index_pos].min_pos.x
				pos_l[2] = list.position_list[index_pos].max_pos.x
				pos_l[3] = list.position_list[index_pos].min_pos.y
				pos_l[4] = list.position_list[index_pos].max_pos.y	
				local map_obj = g_scene_mgr_ex:get_scene({s_id,nil}):get_map_obj()
				if pos_l[1] <= 0 or  pos_l[3] <= 0 or pos_l[2] >= map_obj:get_w() or pos_l[4] >= map_obj:get_h() then
					pos_l = nil
				end
			end
			
			--怪物
			if list.monster_list[i] and n <= list.monster_list[i].number then
				local map_obj = g_scene_mgr_ex:get_scene({s_id,nil}):get_map_obj() 
				local pos = map_obj:find_pos(pos_l)
				if pos then
					local obj = g_obj_mgr:create_monster(list.monster_list[i].occ, pos, {s_id,nil})
					g_scene_mgr_ex:enter_scene(obj)
					self.function_list[id].monster_list[i][index].list[obj:get_id()] = 1
					broadcast = true
					if list.monster_list[i].occ == special_monster_id then special_effect_id = "effect_1" end
					--if effect_id == nil then effect_id = list.monster_list[i].effect_id end
				end
			end
			--采集
			if list.npc_list[i] and n <= list.npc_list[i].number then
				local map_obj = g_scene_mgr_ex:get_scene({s_id, nil}):get_map_obj()
				local pos = map_obj:find_pos(pos_l)
				if pos then
					local obj = f_npc_create_enter(list.npc_list[i].occ, nil, pos, {s_id,nil})
					self.function_list[id].npc_list[i][index].list[obj:get_id()] = 1
					broadcast = true
					--if effect_id == nil then effect_id = list.npc_list[i].effect_id end
				end
			end
			--掉落
			if list.box_list[i] and n <= list.box_list[i].number then
				local map_obj = g_scene_mgr_ex:get_scene({s_id,nil}):get_map_obj() 
				local pos = map_obj:find_pos(pos_l)
				if pos then
					local obj = g_obj_mgr:create_monster(list.box_list[i].occ, pos, {s_id,nil})
					g_scene_mgr_ex:enter_scene(obj)
					self.function_list[id].box_list[i][index].list[obj:get_id()] = 1
					broadcast = true
				end
			end

		end
	end

	if str_name ~= "" and broadcast then
		--广播
		local str_db = string.format("%s%s%s%s，%s",string.sub(str_name,1,string.len(str_name)-1),f_get_string(2601),list.map_name,f_get_string(2602),f_get_string(2603))
		f_cmd_linebd(f_create_sysbd_format(str_db,16))
		--播放特效
		--print('________________________special_effect_id',special_effect_id)
		if special_effect_id then
			local online_players = g_obj_mgr:get_list(OBJ_TYPE_HUMAN)
			for k, v in pairs(online_players or {}) do
				g_cltsock_mgr:send_client(v:get_id(), CMD_PLAY_EFFECT_S, {["effect_id"] = special_effect_id})
			end
		end
	end 
end