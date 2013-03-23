
local _sector = f_scene_sector()
local _random = crypto.random

local _zone_w = 30
local _zone_h = 30
local _s_zone_w = 10
local _s_zone_h = 10
local _clog = 1     --障碍
local _stall = 51
local _mon_area = {10, 100} --怪物和采集物品区域范围
local _level = 20   --主动扫描级别差

Scene_map = oo.class(nil, "Scene_map")

function Scene_map:__init(id)
	self.id = id
	self.map_l = {}     --地图数组从0开始
	self.map_l_ex = {}  --记录地图坐标包含哪些obj
	self.id_to_pos = {}

	self.map_w = 0
	self.map_h = 0

	--刷怪区域
	self.mon_map_l = {}

	--zone
	self.zone_w = 0
	self.zone_h = 0
	self.zone_l = {}

	--small_zone
	self.s_zone_w = 0
	self.s_zone_h = 0
	self.s_zone_l = {}
end

function Scene_map:clone(id)
	local map_o = Scene_map(id)
	--map_o.map_l = table.duplicate(self.map_l)
	map_o.map_l = self.map_l
	map_o.map_w = self.map_w
	map_o.map_h = self.map_h
	--map_o.mon_map_l = table.duplicate(self.mon_map_l)
	map_o.mon_map_l = self.mon_map_l
	map_o:zone_map()
	map_o:s_zone_map()
	return map_o
end

function Scene_map:load(file_nm)
	local ret = g_i_scene:load(self.id, file_nm)
	self.map_l,self.map_w, self.map_h = g_i_scene:get_map(self.id)
	if not ret or self.map_l == nil then
		return false
	end
	
	--刷怪区域
	for k,v in pairs(self.map_l) do
		if v >= _mon_area[1] and v <= _mon_area[2] then
			if self.mon_map_l[v] == nil then
				self.mon_map_l[v] = {}
				self.mon_map_l[v]["list"] = {}
				self.mon_map_l[v]["count"] = 0
			end

			self.mon_map_l[v]["count"] = self.mon_map_l[v]["count"] + 1
			local n = self.mon_map_l[v]["count"]
			self.mon_map_l[v]["list"][n] = k
		end
	end

	--切割地图
	self:zone_map()
	self:s_zone_map()

	return true
end

function Scene_map:zone_map()
	self.zone_w = math.floor((self.map_w-1)/_zone_w) + 1
	self.zone_h = math.floor((self.map_h-1)/_zone_h) + 1
	local sz = self.zone_w * self.zone_h
	for i=0,sz-1 do
		self.zone_l[i] = Scene_zone(i)
	end
end
function Scene_map:s_zone_map()
	self.s_zone_w = math.floor((self.map_w-1)/_s_zone_w) + 1
	self.s_zone_h = math.floor((self.map_h-1)/_s_zone_h) + 1
	local sz = self.s_zone_w * self.s_zone_h
	for i=0,sz-1 do
		self.s_zone_l[i] = Small_zone(i)
	end
end


function Scene_map:get_w()
	return self.map_w
end
function Scene_map:get_h()
	return self.map_h
end

--obj
function Scene_map:add_obj(obj_id, pos)
	local off = pos[1] + pos[2]*self.map_w
	local ty = Obj_mgr.obj_type(obj_id)
	if self.map_l_ex[off] == nil then
		self.map_l_ex[off] = {}
	end
	self.map_l_ex[off][obj_id] = ty
	self.id_to_pos[obj_id] = off
	--print("--", off, obj_id, ty)
end
function Scene_map:del_obj(obj_id, pos)
--[[
	local off = pos[1] + pos[2]*self.map_w
	print("--", off, obj_id, self.map_l_ex[off], self.map_l_ex[off] and self.map_l_ex[off][obj_id])
	if self.map_l_ex[off] ~= nil then
		self.map_l_ex[off][obj_id] = nil
		if table.size(self.map_l_ex[off]) == 0 then
			self.map_l_ex[off] = nil
		end
	end
]]
	local off = self.id_to_pos[obj_id]
	if off and self.map_l_ex[off] ~= nil then
		self.map_l_ex[off][obj_id] = nil
--[[
		if table.size(self.map_l_ex[off]) == 0 then
			self.map_l_ex[off] = nil
		end]]
	end
end
function Scene_map:clean_obj(obj_id, pos)
	local off = self.id_to_pos[obj_id]
	self.id_to_pos[obj_id] = nil
	if off and self.map_l_ex[off] ~= nil then
		self.map_l_ex[off][obj_id] = nil
	end
end
function Scene_map:pos_zone(pos)
	local cx = math.floor(pos[1]/_zone_w)
	local cy = math.floor(pos[2]/_zone_h)
	return cy*self.zone_w + cx
end
function Scene_map:pos_s_zone(pos)
	local cx = math.floor(pos[1]/_s_zone_w)
	local cy = math.floor(pos[2]/_s_zone_h)
	return cy*self.s_zone_w + cx
end


------------扫描函数--------------
function Scene_map:print_pos(pos)
	local off = pos[2]*self.map_w + pos[1]
end
--搜寻空地（pos指坐标范围）
function Scene_map:find_pos(pos)
	local count = 0
	while(true) do
		count = count + 1
		if count > 100 then
			--print("Error:Scene_map:find_pos")
			local debug = Debug(g_debug_log)
			debug:trace("Error:Scene_map:find_pos")
			return
		end
		if pos == nil then
			local off = _random(0, (self.map_w-1)*(self.map_h-1))
			if self.map_l[off] ~= _clog then
				local des_pos = {}
				des_pos[1] = off%self.map_w
				des_pos[2] = math.floor(off/self.map_w)
				return des_pos
			end
		else
			local x = _random(pos[1], pos[2])
			local y = _random(pos[3], pos[4])
			local off = y*self.map_w+x
			if self.map_l[off] ~= _clog then
				return {x,y}
			end
		end
	end
end

--搜寻刷怪空地
function Scene_map:get_mon_area_l(area)
	return self.mon_map_l[area]["list"]
end
function Scene_map:is_mon_area(area, pos)
	local off = pos[1] + pos[2]*self.map_w
	if self.map_l[off] == area and (self.map_l_ex[off] == nil or table.size(self.map_l_ex[off]) <= 0) then
		return true
	end
	return false
end
--是否非障碍
function Scene_map:is_clog_pos(pos)
	local off = pos[1] + pos[2]*self.map_w
	return self.map_l[off] ~= _clog
end

function Scene_map:find_space(area, cn)
	if self.mon_map_l[area] ~= nil then
		local n = self.mon_map_l[area]["count"]
		cn = cn or 50
		local r = _random(1, n+1)
		local off 
		for i=1,cn do
			off = self.mon_map_l[area]["list"][r]
			if self.map_l_ex[off] ~= nil and table.size(self.map_l_ex[off]) > 0 then
				r = (r + 1)>n and 1 or r+1
			else
				break
			end
		end
		if off ~= nil then
			local pos = {}
			pos[1] = off%self.map_w
			pos[2] = math.floor(off/self.map_w)
			return pos
		end
	end
end

--是否可以摊位
function Scene_map:is_space_stall(pos, area)
	local w_s = pos[1] - area
	local h_s = pos[2] - area
	w_s = w_s>=0 and w_s or 0
	h_s = h_s>=0 and h_s or 0

	local w_e = pos[1] + area
	local h_e = pos[2] + area
	w_e = w_e<self.map_w and w_e or self.map_w-1
	h_e = h_e<self.map_h and h_e or self.map_h-1

	for i=w_s,w_e do
		for j=h_s,h_e do
			if self.map_l[j*self.map_w+i] == _stall then
				local list = self.map_l_ex[j*self.map_w+i] or {}
				for k,v in pairs(list) do	
					if v == OBJ_TYPE_NPC then
						return false
					end
				end
			else 
				return false
			end
		end
	end
	return true
end

function Scene_map:scan_obj_l(zone_id)
	if self.zone_l[zone_id] ~= nil then
		return self.zone_l[zone_id]:get_obj_l()
	end
end
function Scene_map:scan_human_l(zone_id)
	if self.zone_l[zone_id] ~= nil then
		return self.zone_l[zone_id]:get_human_l()
	end
end
function Scene_map:scan_monster_l(zone_id)
	if self.zone_l[zone_id] ~= nil then
		return self.zone_l[zone_id]:get_monster_l()
	end
end
function Scene_map:scan_box_l(zone_id)
	if self.zone_l[zone_id] ~= nil then
		return self.zone_l[zone_id]:get_box_l()
	end
end
function Scene_map:scan_npc_l(zone_id)
	if self.zone_l[zone_id] ~= nil then
		return self.zone_l[zone_id]:get_npc_l()
	end
end
function Scene_map:scan_pet_l(zone_id)
	if self.zone_l[zone_id] ~= nil then
		return self.zone_l[zone_id]:get_pet_l()
	end
end

--扫描函数
function Scene_map:scan_obj(pos, area, func)
	local w_s = pos[1] - area
	local h_s = pos[2] - area
	w_s = w_s>=0 and w_s or 0
	h_s = h_s>=0 and h_s or 0

	local w_e = pos[1] + area
	local h_e = pos[2] + area
	w_e = w_e<self.map_w and w_e or self.map_w-1
	h_e = h_e<self.map_h and h_e or self.map_h-1

	for i=w_s,w_e do
		for j=h_s,h_e do
			if self.map_l[j*self.map_w+i] ~= _clog then
				local list = self.map_l_ex[j*self.map_w+i] or {}
				for k,v in pairs(list) do	
					if not func(k, v) then
						return
					end
				end
			end
		end
	end
end

--扫描指定区域人物和守卫类型的对象, area表示区域大小,count表示扫描个数,
function Scene_map:scan_human_and_guard_rect(pos, area, count)
	local c = 0
	local obj_l = {}
	local f = function(obj_id, ty)
		local obj = g_obj_mgr:get_obj(obj_id)
		if ty == OBJ_TYPE_HUMAN or ty == OBJ_TYPE_PET or (ty == OBJ_TYPE_MONSTER and obj and obj:get_occ() > MONSTER_GUARD) then
			obj_l[obj_id] = 1
			c = c + 1

			if count ~= nil and c >= count then
				return false
			end
		end
		return true
	end

	self:scan_obj(pos, area, f)
	return obj_l
end

--人物扫描指定区域的对象,obj_type指定扫描的对象类型,nil代表所有对象,count表示扫描个数
function Scene_map:scan_obj_rect(pos, area, obj_type, count)
	local c = 0
	local obj_l = {}
	local f = function(obj_id, ty)
		if ty == obj_type or (obj_type == nil and ty ~= OBJ_TYPE_BOX and ty ~= OBJ_TYPE_NPC) then
			obj_l[obj_id] = 1
			c = c + 1

			if count ~= nil and c >= count then
				return false
			end
		end
		return true
	end

	self:scan_obj(pos, area, f)
	return obj_l
end

--怪物技能扫描指定区域
function Scene_map:monster_scan_obj_rect(pos, area, count)
	local c = 0
	local obj_l = {}
	local f = function(obj_id, ty)
		if ty == OBJ_TYPE_HUMAN or ty == OBJ_TYPE_PET then
			obj_l[obj_id] = 1
			c = c + 1

			if count ~= nil and c >= count then
				return false
			end
		end
		return true
	end

	self:scan_obj(pos, area, f)
	return obj_l
end

--搜索指定列表中的怪物
function Scene_map:scan_one_monster_in_list(pos, area, list)
	local monster_id = nil
	local obj_mgr = g_obj_mgr
	local f = function(obj_id, ty)
		if ty == OBJ_TYPE_MONSTER and list[obj_mgr:get_obj(obj_id):get_occ()] ~= nil then
			monster_id = obj_id
			return false
		end
		return true
	end

	self:scan_obj(pos, area, f)
	return monster_id
end

--怪物技能扫描对立阵营
function Scene_map:monster_scan_obj_side(pos, area, count, side)
	local c = 0
	local obj_l = {}
	local obj_mgr = g_obj_mgr
	local f = function(obj_id, ty)
		if ty == OBJ_TYPE_HUMAN or ty == OBJ_TYPE_PET or ty == OBJ_TYPE_MONSTER then
			local obj = g_obj_mgr:get_obj(obj_id)
			if obj ~= nil and obj:get_side() ~= side then
				obj_l[obj_id] = 1
				c = c + 1

				if count ~= nil and c >= count then
					return false
				end
			end
		end
		return true
	end

	self:scan_obj(pos, area, f)
	return obj_l
end

--搜索指定pos area范围中的怪物
function Scene_map:scan_one_monster_in_pos_area(pos, area, count)
	local c = 0
	local obj_l = {}
	local f = function(obj_id, ty)
		if ty == OBJ_TYPE_MONSTER then
			obj_l[obj_id] = 1
			c = c + 1

			if count ~= nil and c >= count then
				return false
			end
		end
		return true
	end

	self:scan_obj(pos, area, f)
	return obj_l
end

--扫描指定区域的对象,obj_type指定扫描的对象类型,nil代表所有对象,count表示扫描个数
--[[function Scene_map:scan_obj_rect(pos, area, obj_type, count)
	local w_s = pos[1] - area
	local h_s = pos[2] - area
	w_s = w_s>=0 and w_s or 0
	h_s = h_s>=0 and h_s or 0

	local w_e = pos[1] + area
	local h_e = pos[2] + area
	w_e = w_e<self.map_w and w_e or self.map_w-1
	h_e = h_e<self.map_h and h_e or self.map_h-1

	local obj_l = {}
	local c = 0
	for i=w_s,w_e do
		for j=h_s,h_e do
			if self.map_l[j*self.map_w+i] ~= _clog then
				local list = self.map_l_ex[j*self.map_w+i] or {}
				for k,v in pairs(list) do	
					if (obj_type == nil and v ~= OBJ_TYPE_BOX and v ~= OBJ_TYPE_NPC) or v == obj_type then
						obj_l[k] = 1
						c = c + 1
					end
				end
			end
		end
		if count ~= nil and c >= count then
			break
		end
	end
	return obj_l
end]]

--怪物技能扫描指定区域
--[[function Scene_map:monster_scan_obj_rect(pos, area, count)
	local w_s = pos[1] - area
	local h_s = pos[2] - area
	w_s = w_s>=0 and w_s or 0
	h_s = h_s>=0 and h_s or 0

	local w_e = pos[1] + area
	local h_e = pos[2] + area
	w_e = w_e<self.map_w and w_e or self.map_w-1
	h_e = h_e<self.map_h and h_e or self.map_h-1

	local obj_l = {}
	local c = 0
	for i=w_s,w_e do
		for j=h_s,h_e do
			if self.map_l[j*self.map_w+i] ~= _clog then
				local list = self.map_l_ex[j*self.map_w+i] or {}
				for k,v in pairs(list) do	
					if  v == OBJ_TYPE_HUMAN or v == OBJ_TYPE_PET then
						obj_l[k] = 1
						c = c + 1
					end
				end
			end
		end
		if count ~= nil and c >= count then
			break
		end
	end
	--print(";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;", c)
	return obj_l
end]]

--怪物技能扫描对立阵营
--[[function Scene_map:monster_scan_obj_side(pos, area, count, side)
	local w_s = pos[1] - area
	local h_s = pos[2] - area
	w_s = w_s>=0 and w_s or 0
	h_s = h_s>=0 and h_s or 0

	local w_e = pos[1] + area
	local h_e = pos[2] + area
	w_e = w_e<self.map_w and w_e or self.map_w-1
	h_e = h_e<self.map_h and h_e or self.map_h-1

	local obj_l = {}
	local c = 0
	local obj_mgr = g_obj_mgr
	for i=w_s,w_e do
		for j=h_s,h_e do
			if self.map_l[j*self.map_w+i] ~= _clog then
				local list = self.map_l_ex[j*self.map_w+i] or {}
				for k,v in pairs(list) do	
					if v == OBJ_TYPE_HUMAN or v == OBJ_TYPE_PET or v == OBJ_TYPE_MONSTER then
						local obj = g_obj_mgr:get_obj(k)
						if obj ~= nil and obj:get_side() ~= side then
							obj_l[k] = 1
							c = c + 1
						end
					end
				end
			end
		end
		if count ~= nil and c >= count then
			break
		end
	end

	return obj_l
end]]


--扇形扫描,返回对象列表和方向,obj_type指定扫描的对象类型,nil代表所有对象
function Scene_map:scan_sector_rect(pos, des_pos, area, obj_type)
	local direct = _sector.get_direct(pos, des_pos)

	--扫描
	local w_s = pos[1] - area
	local h_s = pos[2] - area
	w_s = w_s>=0 and w_s or 0
	h_s = h_s>=0 and h_s or 0

	local w_e = pos[1] + area
	local h_e = pos[2] + area
	w_e = w_e<self.map_w and w_e or self.map_w-1
	h_e = h_e<self.map_h and h_e or self.map_h-1

	local obj_l = {}
	for i=w_s,w_e do
		for j=h_s,h_e do
			if self.map_l[j*self.map_w+i] ~= _clog and _sector.is_area(pos, {i,j}, direct) then
				local list = self.map_l_ex[j*self.map_w+i] or {}
				for k,v in pairs(list) do	
					if (obj_type == nil and v ~= OBJ_TYPE_BOX and v ~= OBJ_TYPE_NPC) or v == obj_type then
						obj_l[k] = 1
					end
				end
			end
		end
	end

	return obj_l, direct
end


--新：怪物扫描指定区域内最近一个对象,obj_id为不扫描对象,ty为nil 9格扫描 1 1格扫描
function Scene_map:new_scan_obj_rect_one(pos, area, obj_id, ty)
	local obj = g_obj_mgr:get_obj(obj_id)
	local level = obj:get_level()

	local func = function(k)
		local obj_d = g_obj_mgr:get_obj(k)
		if obj_d == nil then return end
		local obj_ty = obj_d:get_type()
		if obj_id ~= k and obj_d:is_alive() and obj_d:is_view() and obj_d:get_level() < level+_level then   --级别差
			return k
		end
	end

	return self:scan_s_zone(pos, area, func, OBJ_TYPE_HUMAN, ty)
end
--新：守卫扫描红名,obj_id为不扫描对象,ty为nil 9格扫描 1 1格扫描
function Scene_map:new_scan_obj_rect_one_evil(pos, area, obj_id, ty)
	local func = function(k)
		local obj_d = g_obj_mgr:get_obj(k)
		if obj_d == nil then return end
		local obj_ty = obj_d:get_type()
		if obj_id ~= k and (obj_ty == OBJ_TYPE_HUMAN or obj_ty == OBJ_TYPE_MONSTER)
			and obj_d:is_alive() then
			if --[[(obj_ty == OBJ_TYPE_MONSTER and obj_d:get_occ() < MONSTER_GUARD) or]]
				(obj_ty == OBJ_TYPE_HUMAN and obj_d:get_evil() < 0) then
				return k
			end
		end
	end

	return self:scan_s_zone(pos, area, func, OBJ_TYPE_HUMAN, ty)
end

--守塔守卫：扫描怪物 obj_id为不扫描对象,ty为nil 9格扫描 1 1格扫描
function Scene_map:new_scan_obj_rect_one_monster(pos, area, obj_id, ty)
	local func = function(k)
		local obj_d = g_obj_mgr:get_obj(k)
		if obj_d == nil then return end

		local obj_ty = obj_d:get_type()
		if obj_id ~= k and obj_d:get_occ() < MONSTER_GUARD and obj_d:is_alive() then
			return k
		end
	end

	return self:scan_s_zone(pos, area, func, OBJ_TYPE_MONSTER, ty)
end

--战场塔防扫描对立阵营人物：obj_id为塔防id,ty为nil 9格扫描 1 1格扫描
function Scene_map:new_scan_obj_side_one(pos, area, obj_id, ty)
	local obj = g_obj_mgr:get_obj(obj_id)

	local func = function(k)
		local obj_d = g_obj_mgr:get_obj(k)
		if obj_d == nil then return end

		local obj_ty = obj_d:get_type()
		if obj_d:get_side() ~= obj:get_side() and obj_d:is_alive() and obj_d:is_view() then
			return k
		end
	end

	local obj_id = self:scan_s_zone(pos, area, func, OBJ_TYPE_HUMAN, ty)
	return obj_id or self:scan_s_zone(pos, area, func, OBJ_TYPE_MONSTER, ty)
end

--守塔怪物搜索，func为判断函数, prior_l为优先列表, occ_l为对象类型列表, ty为nil 9格扫描 1 1格扫描
function Scene_map:new_scan_obj_rect_td(pos, ty)
	local zone_id = self:pos_s_zone(pos)

	--扫描当前zone
	local t_obj_l = {}
	local c = 0
	c = c + 1
	t_obj_l[c] = self.s_zone_l[zone_id]:get_obj_l()

	if ty == nil then
		--扫描周边的zone
		local z_l = self:scan_screen_s_zone(pos)
		z_l[zone_id] = nil
		for z_id,_ in pairs(z_l) do
			c = c + 1
			t_obj_l[c] = self.s_zone_l[z_id]:get_obj_l()
		end
	end

	local obj_mgr = g_obj_mgr
	local obj_id
	for _,lt in pairs(t_obj_l) do
		for o_id,_ in pairs(lt) do
			local obj = obj_mgr:get_obj(o_id)
			if obj ~= nil then
				if MONSTER_TD_SHIELD[obj:get_occ()] then
					return o_id
				elseif obj:get_type() == OBJ_TYPE_HUMAN then
					obj_id = o_id
				end
			end
		end
	end

	return obj_id
end

-- 搜索不同于自己阵营,有优先搜索类型
--s_zone 搜索，prior_l优先队列, ty为nil 9格扫描 1 1格扫描
function Scene_map:scan_side_one_prior(pos, my_side, prior_l, obj_type, ty)
	local zone_id = self:pos_s_zone(pos)

	--扫描当前zone
	local obj_l,obj_count
	if obj_type == OBJ_TYPE_HUMAN then
		obj_l = self.s_zone_l[zone_id]:get_human_l()
		obj_count = self.s_zone_l[zone_id]:get_human_count()
	elseif obj_type == OBJ_TYPE_MONSTER then
		obj_l = self.s_zone_l[zone_id]:get_monster_l()
		obj_count = self.s_zone_l[zone_id]:get_monster_count()
	end

	local scan_obj_id = nil
	if obj_count > 0 then
		for k,v in pairs(obj_l) do
			local obj_d = g_obj_mgr:get_obj(k)
			if obj_d ~= nil then
				local obj_ty = obj_d:get_type()
				if obj_d:get_side() ~= my_side and obj_d:is_alive() and obj_d:is_view() then
					scan_obj_id = scan_obj_id or k
					if prior_l and prior_l[obj_d:get_occ()] then
						return k
					end
				end
			end
		end
	end

	if ty == nil then
		--扫描周边的zone
		local z_l = self:scan_screen_s_zone(pos)
		z_l[zone_id] = nil
		for z_id,_ in pairs(z_l) do
			local obj_l,obj_count
			if obj_type == OBJ_TYPE_HUMAN then
				obj_l = self.s_zone_l[z_id]:get_human_l()
				obj_count = self.s_zone_l[z_id]:get_human_count()
			elseif obj_type == OBJ_TYPE_MONSTER then
				obj_l = self.s_zone_l[z_id]:get_monster_l()
				obj_count = self.s_zone_l[z_id]:get_monster_count()
			end

			if obj_count > 0 then
				for k,v in pairs(obj_l) do
					local obj_d = g_obj_mgr:get_obj(k)
					if obj_d ~= nil then
						local obj_ty = obj_d:get_type()
						if obj_d:get_side() ~= my_side and obj_d:is_alive() and obj_d:is_view() then
							scan_obj_id = scan_obj_id or k
							if prior_l and prior_l[obj_d:get_occ()] then
								return k
							end
						end
					end
				end
			end
		end
	end

	return scan_obj_id
end


--寻找直线上指定距离的远离pos的坐标点
function Scene_map:find_far_pos(pos, des_pos, area)
	local dis = math.pow((des_pos[2]-pos[2]),2) + math.pow((des_pos[1]-pos[1]),2)
	dis = math.floor(math.sqrt(dis)+0.5)

	if dis == 0 then 
		while area > 0 do
			local t_pos = {}
			t_pos[1] = (pos[1] + area) <= (self.map_w-1) and (pos[1] + area) or (self.map_w-1)
			t_pos[2] = pos[2]
			if self.map_l[t_pos[2]*self.map_w+t_pos[1]] ~= _clog then
				return t_pos
			end
			area = area - 1
		end
	else
		while area > 0 do
			local x = math.max(0, math.floor(area/dis*(des_pos[1]-pos[1])+des_pos[1]))
			local y = math.max(0, math.floor(area/dis*(des_pos[2]-pos[2])+des_pos[2]))
			x = x <= self.map_w-1 and x or self.map_w-1
			y = y <= self.map_h-1 and y or self.map_h-1
			if self.map_l[y*self.map_w+x] ~= _clog then
				return {x,y}
			end
			area = area - 1
		end
	end
end

--搜索附近空地坐标
function Scene_map:scan_space_rect_one(pos, area)
	if self.map_l_ex[pos[2]*self.map_w+pos[1]] == nil then
		return pos
	end

	local func = function(off)
		if self.map_l_ex[off] == nil then
			local des_pos = {}
			des_pos[1] = off%self.map_w
			des_pos[2] = math.floor(off/self.map_w)
			return des_pos
		end
	end
	return self:scan_ring(pos, area, func)
end

--波浪型从内至外搜索最近一个坐标点,不搜索pos点, func为判断函数
function Scene_map:scan_ring(pos, area, func)
	--从内至外搜索
	for i=1,area do
		--上下搜索
		local w_list = {}
		local w_s = pos[1]-i
		if w_s >= 0 then w_list[w_s] = 1 end
		w_s = pos[1]+i
		if w_s < self.map_w - 1 then w_list[w_s] = 1 end

		local min_h = pos[2]-area>=0 and pos[2]-area or 0
		local max_h = pos[2]+area<=self.map_h-1 and pos[2]+area or self.map_h-1
		for ws,_ in pairs(w_list) do
			for j=min_h,max_h do
				if self.map_l[j*self.map_w+ws] ~= _clog then
					local ret = func(j*self.map_w+ws)
					if ret ~= nil then return ret end
				end
			end
		end
		--左右搜索
		local h_list = {}
		local h_s = pos[2]-i
		if h_s >= 0 then h_list[h_s] = 1 end
		h_s = pos[2]+i
		if h_s < self.map_h - 1 then h_list[h_s] = 1 end

		local min_w = pos[1]-area>=0 and pos[1]-area or 0
		local max_w = pos[1]+area<=self.map_w-1 and pos[1]+area or self.map_w-1
		for hs,_ in pairs(h_list) do
			for j=min_w,max_w do
				if self.map_l[j*self.map_w+hs] ~= _clog then
					local ret = func(j*self.map_w+hs)
					if ret ~= nil then return ret end
				end
			end
		end
	end
end

--s_zone 搜索，func为判断函数, ty为nil 9格扫描 1 1格扫描
function Scene_map:scan_s_zone(pos, area, func, obj_type, ty)
	local zone_id = self:pos_s_zone(pos)

	--扫描当前zone
	local obj_l,obj_count
	if obj_type == OBJ_TYPE_HUMAN then
		obj_l = self.s_zone_l[zone_id]:get_human_l()
		obj_count = self.s_zone_l[zone_id]:get_human_count()
	elseif obj_type == OBJ_TYPE_MONSTER then
		obj_l = self.s_zone_l[zone_id]:get_monster_l()
		obj_count = self.s_zone_l[zone_id]:get_monster_count()
	end

	if obj_count > 0 then
		for k,v in pairs(obj_l) do
			local ret = func(k)
			if ret ~= nil then return ret end
		end
	end

	if ty == nil then
		--扫描周边的zone
		local z_l = self:scan_screen_s_zone(pos)
		z_l[zone_id] = nil
		for z_id,_ in pairs(z_l) do
			local obj_l,obj_count
			if obj_type == OBJ_TYPE_HUMAN then
				obj_l = self.s_zone_l[z_id]:get_human_l()
				obj_count = self.s_zone_l[z_id]:get_human_count()
			elseif obj_type == OBJ_TYPE_MONSTER then
				obj_l = self.s_zone_l[z_id]:get_monster_l()
				obj_count = self.s_zone_l[z_id]:get_monster_count()
			end

			if obj_count > 0 then
				for k,v in pairs(obj_l) do
					local ret = func(k)
					if ret ~= nil then return ret end
				end
			end
		end
	end
end

--扫描屏内对象
function Scene_map:scan_screen_obj(pos, ty)
	local obj_l = {}
	local z_l = self:scan_screen_zone(pos)
	local list = {}
	for k,v in pairs(z_l) do
		if ty == nil then
			list = self.zone_l[k]:get_obj_l()
		elseif ty == OBJ_TYPE_HUMAN then
			list = self.zone_l[k]:get_human_l()
		elseif ty == OBJ_TYPE_MONSTER then
			list = self.zone_l[k]:get_monster_l()
		elseif ty == OBJ_TYPE_BOX then
			list = self.zone_l[k]:get_box_l()
		elseif ty == OBJ_TYPE_NPC then
			list = self.zone_l[k]:get_npc_l()
		elseif ty == OBJ_TYPE_PET then
			list = self.zone_l[k]:get_pet_l()
		end
		for o_id,v in pairs(list) do
			obj_l[o_id] = 1
		end
	end
	return obj_l
end
--扫描屏范围内玩家对象
function Scene_map:scan_screen_human(pos)
	return self:scan_screen_obj(pos, OBJ_TYPE_HUMAN)
end
--扫描屏范围内怪物对象
function Scene_map:scan_screen_monster(pos)
	return self:scan_screen_obj(pos, OBJ_TYPE_MONSTER)
end
--扫描屏内掉落包对象
function Scene_map:scan_screen_box(pos)
	return self:scan_screen_obj(pos, OBJ_TYPE_BOX)
end
--扫描npc对象
function Scene_map:scan_screen_npc(pos)
	return self:scan_screen_obj(pos, OBJ_TYPE_NPC)
end
--扫描pet对象
function Scene_map:scan_screen_pet(pos)
	return self:scan_screen_obj(pos, OBJ_TYPE_PET)
end

--扫描pos周边的9个zone
function Scene_map:scan_screen_zone(pos)
	local z_id = self:pos_zone(pos)
	local w = z_id % self.zone_w
	local h = math.floor(z_id / self.zone_w)

	local z_l = {}
	local tmp_w = w 
	local tmp_h = h
	z_l[z_id] = 1
	
	tmp_w = w-1>=0 and w-1 or w
	tmp_h = h
	z_l[tmp_w + tmp_h*self.zone_w] = 1

	tmp_w = w
	tmp_h = h-1>=0 and h-1 or h
	z_l[tmp_w + tmp_h*self.zone_w] = 1

	tmp_w = w-1>=0 and w-1 or w
	tmp_h = h-1>=0 and h-1 or h
	z_l[tmp_w + tmp_h*self.zone_w] = 1

	tmp_w = w+1<self.zone_w and w+1 or w
	tmp_h = h
	z_l[tmp_w + tmp_h*self.zone_w] = 1

	tmp_w = w
	tmp_h = h+1<self.zone_h and h+1 or h
	z_l[tmp_w + tmp_h*self.zone_w] = 1

	tmp_w = w+1<self.zone_w and w+1 or w
	tmp_h = h+1<self.zone_h and h+1 or h
	z_l[tmp_w + tmp_h*self.zone_w] = 1

	tmp_w = w+1<self.zone_w and w+1 or w
	tmp_h = h-1>=0 and h-1 or h
	z_l[tmp_w + tmp_h*self.zone_w] = 1

	tmp_w = w-1>=0 and w-1 or w
	tmp_h = h+1<self.zone_h and h+1 or h
	z_l[tmp_w + tmp_h*self.zone_w] = 1
	return z_l
end

--扫描pos周边的9个s_zone
function Scene_map:scan_screen_s_zone(pos)
	local z_id = self:pos_s_zone(pos)
	local w = z_id % self.s_zone_w
	local h = math.floor(z_id / self.s_zone_w)

	local z_l = {}
	local tmp_w = w 
	local tmp_h = h
	z_l[z_id] = 1
	
	tmp_w = w-1>=0 and w-1 or w
	tmp_h = h
	z_l[tmp_w + tmp_h*self.s_zone_w] = 1

	tmp_w = w
	tmp_h = h-1>=0 and h-1 or h
	z_l[tmp_w + tmp_h*self.s_zone_w] = 1

	tmp_w = w-1>=0 and w-1 or w
	tmp_h = h-1>=0 and h-1 or h
	z_l[tmp_w + tmp_h*self.s_zone_w] = 1

	tmp_w = w+1<self.s_zone_w and w+1 or w
	tmp_h = h
	z_l[tmp_w + tmp_h*self.s_zone_w] = 1

	tmp_w = w
	tmp_h = h+1<self.s_zone_h and h+1 or h
	z_l[tmp_w + tmp_h*self.s_zone_w] = 1

	tmp_w = w+1<self.s_zone_w and w+1 or w
	tmp_h = h+1<self.s_zone_h and h+1 or h
	z_l[tmp_w + tmp_h*self.s_zone_w] = 1

	tmp_w = w+1<self.s_zone_w and w+1 or w
	tmp_h = h-1>=0 and h-1 or h
	z_l[tmp_w + tmp_h*self.s_zone_w] = 1

	tmp_w = w-1>=0 and w-1 or w
	tmp_h = h+1<self.s_zone_h and h+1 or h
	z_l[tmp_w + tmp_h*self.s_zone_w] = 1
	return z_l
end

--扫描cur_pos 与 des_pos 对应的不同的zone
function Scene_map:scan_far_zone(cur_pos, des_pos)
	local z_l_s = self:scan_screen_zone(cur_pos)
	local z_l_d = self:scan_screen_zone(des_pos)
	
	local z_l = {}
	for k,v in pairs(z_l_s) do
		if z_l_d[k] == nil then
			z_l[k] = 1
		end
	end
	return z_l
end

--两坐标距离
function Scene_map:distance(cur_pos, des_pos)
	local d_x = math.pow(cur_pos[1] - des_pos[1], 2)
	local d_y = math.pow(cur_pos[2] - des_pos[2], 2)
	return math.floor(math.sqrt(d_x + d_y))
end

--两坐标中间点坐标
function Scene_map:middle_pos(cur_pos, des_pos)
	local x = math.floor((des_pos[1] - cur_pos[1])/2)
	local y = math.floor((des_pos[2] - cur_pos[2])/2)
	local pos = {}
	pos[1] = cur_pos[1] + x
	pos[2] = cur_pos[2] + y
	--print("------Scene_map:middle_pos", des_pos[1], des_pos[2], cur_pos[1], cur_pos[2], pos[1], pos[2])
	return pos
end

--------------寻路函数-----------
--寻路函数
function Scene_map:find_path(cur_pos, des_pos)
	return g_i_scene:find_path(self.id, cur_pos, des_pos)
end
--随机区域内一个坐标的路径
function Scene_map:rand_path(cur_pos, area)
	local count = 50
	while count > 0 do
		count = count - 1

		local pos = {cur_pos[1], cur_pos[2]}
		pos[1] = math.min(math.max(1, pos[1]+_random(1, area*2+1)-area), self.map_w-1)
		pos[2] = math.min(math.max(1, pos[2]+_random(1, area*2+1)-area), self.map_h-1)
		local off = pos[1] + pos[2]*self.map_w
		if self.map_l_ex[off] == nil and self.map_l[off] ~= _clog then
			return self:find_path(cur_pos, pos), pos
		end
	end
end

---------event------------
function Scene_map:on_obj_enter(obj_id, pos)
	local obj = g_obj_mgr:get_obj(obj_id)
	if obj ~= nil then
		self:add_obj(obj_id, pos)
		
		--zone
		local zone_id = self:pos_zone(pos)
		obj:set_zone(zone_id)
		if not self.zone_l[zone_id] then
			local debug = Debug(g_debug_log)
			local msg = string.format(
							"Scene_map:on_obj_enter(%s, %s, %s, %s)"
							, tostring(self.id)
							, tostring(obj_id)
							, pos and Json.Encode(pos) or "nil"
							, tostring(zone_id))
			debug:trace(msg)
		end
		self.zone_l[zone_id]:on_obj_enter(obj_id)

		--s_zone
		local s_zone_id = self:pos_s_zone(pos)
		obj:set_s_zone(s_zone_id)
		self.s_zone_l[s_zone_id]:on_obj_enter(obj_id)
	end
end
function Scene_map:on_obj_leave(obj_id, pos)
	self:clean_obj(obj_id, pos)
	
	--zone 防止玩家和宠物清除不了
	--[[if Obj_mgr.obj_type(obj_id) == OBJ_TYPE_PET or Obj_mgr.obj_type(obj_id) == OBJ_TYPE_HUMAN then
		for _,v in pairs(self.zone_l) do
			v:on_obj_leave(obj_id)
		end
	else
		local zone_id = self:pos_zone(pos)
		self.zone_l[zone_id]:on_obj_leave(obj_id)
	end

	--s_zone
	local s_zone_id = self:pos_s_zone(pos)
	self.s_zone_l[s_zone_id]:on_obj_leave(obj_id)]]

	local obj = g_obj_mgr:get_obj(obj_id)
	if obj ~= nil then
		local zone_id = obj:get_zone()
		local s_zone_id = obj:get_s_zone()
		local _ = self.zone_l[zone_id] and self.zone_l[zone_id]:on_obj_leave(obj_id)
		local _ = self.s_zone_l[s_zone_id] and self.s_zone_l[s_zone_id]:on_obj_leave(obj_id)
	else
		for _,v in pairs(self.zone_l) do
			v:on_obj_leave(obj_id)
		end
		for _,v in pairs(self.s_zone_l) do
			v:on_obj_leave(obj_id)
		end
		print("Error:Scene_map:on_obj_leave", obj_id, pos[1], pos[2])
	end
end
function Scene_map:on_obj_move(obj_id, obj, old_pos, new_pos)
	--print("on_obj_move............", obj_id)
	self:del_obj(obj_id, old_pos)
	self:add_obj(obj_id, new_pos)

	--zone
	--local z_id_s = self:pos_zone(old_pos)
	local z_id_s = obj:get_zone()
	local z_id_d = self:pos_zone(new_pos)
	if z_id_s ~= z_id_d then
		if not self.zone_l[z_id_s] or not self.zone_l[z_id_d] then
			local debug = Debug(g_debug_log)
			local msg = string.format(
							"Scene_map:on_obj_move(%s, %s, %s, %s, %s, %s)"
							, tostring(self.id)
							, tostring(obj_id)
							, old_pos and Json.Encode(old_pos) or "nil"
							, new_pos and Json.Encode(new_pos) or "nil"
							, tostring(z_id_s)
							, tostring(z_id_d))
			debug:trace(msg)
		end

		obj:set_zone(z_id_d)
		self.zone_l[z_id_s]:on_obj_leave(obj_id)
		self.zone_l[z_id_d]:on_obj_enter(obj_id)
	end

	--s_zone
	--local z_id_s = self:pos_s_zone(old_pos)
	local z_id_s = obj:get_s_zone()
	local z_id_d = self:pos_s_zone(new_pos)
	if z_id_s ~= z_id_d then
		if not self.s_zone_l[z_id_s] or not self.s_zone_l[z_id_d] then
			local debug = Debug(g_debug_log)
			local msg = string.format(
							"Scene_map:on_obj_move(%s, %s, %s, %s, %s, %s)"
							, tostring(self.id)
							, tostring(obj_id)
							, old_pos and Json.Encode(old_pos) or "nil"
							, new_pos and Json.Encode(new_pos) or "nil"
							, tostring(z_id_s)
							, tostring(z_id_d))
			debug:trace(msg)
		end

		obj:set_s_zone(z_id_d)
		self.s_zone_l[z_id_s]:on_obj_leave(obj_id)
		self.s_zone_l[z_id_d]:on_obj_enter(obj_id)
	end
end


------------test
function Scene_map.test(id)
	--[[local path = self:find_path({157,131}, {165, 120}) or {}
	self:print_pos({165,120})
	for k,v in pairs(path) do
		print("<<<<<<<<<<<<<path:", k, v[1], v[2])
	end--]]

	--test (5,4)
	--self.map_l_ex[4*self.map_w+5] = {}
	--self.map_l_ex[4*self.map_w+5][100] = OBJ_TYPE_HUMAN

	--(3,3)
	--self.map_l_ex[3*self.map_w+3] = {}
	--self.map_l_ex[3*self.map_w+3][200] = OBJ_TYPE_HUMAN

	--local obj_id = self:scan_obj_rect_one({1,1}, 4, OBJ_TYPE_HUMAN, 800)
	--local pos = self:find_far_pos({3,3}, {201,200}, 4)
	--print("Scene_map:test",pos[1], pos[2])
	
		
	print("------Scene_map:test1:",os.clock(), collectgarbage("count"))
	collectgarbage("collect")
	for i=1,500000 do
		--[[local path_l = g_i_scene:find_path(id, {58,107}, {82,132})
		if path_l == nil then
			print(">>>>>>>>>>>>>>>>>>>>>")
		end]]
		--local path = {{1,2},{1,2},{1,2},{1,2},{1,2},{1,2},{1,2},{1,2},{1,2},{1,2},{1,2},{1,2},}
	end
	
	collectgarbage("collect")
	collectgarbage("collect")
	collectgarbage("collect")
	print("------Scene_map:test2:",os.clock(), collectgarbage("count"))
end
