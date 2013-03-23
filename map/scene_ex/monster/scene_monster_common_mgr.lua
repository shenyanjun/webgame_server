
local _ai_cls_tm = 30  --关闭ai轮询时间
local _zone_w = 80
local _zone_h = 80

Scene_monster_common_mgr = oo.class(Scene_monster_mgr, "Scene_monster_common_mgr")

function Scene_monster_common_mgr:__init()
	self.obj_count = 0
	self.obj_l = {}      --怪物对象列表

	self.zone_w = 0
	self.zone_h = 0
	self.zone_l = {}

	self.human_l = {}      --玩家对象列表
	self.human_count = 0

	--ai
	self.close_ai_tm = 0
end

function Scene_monster_common_mgr:load(w, h)
	if not w or not h then return end

	--切割地图
	self.zone_w = math.floor((w-1)/_zone_w) + 1
	self.zone_h = math.floor((h-1)/_zone_h) + 1
	local sz = self.zone_w * self.zone_h
	for i=0,sz-1 do
		self.zone_l[i] = Monster_zone(i)
	end
	--print("-----------------------monster zone number:", sz)
end

--event
function Scene_monster_common_mgr:on_obj_enter(obj_id, obj)
	--print("-----Scene_monster_common_mgr:on_obj_enter", self.human_count)
	--zone
	local ty = obj:get_type()
	local zone_id = self:pos_zone(obj:get_pos())
	obj:set_ai_zone(zone_id)
	self.zone_l[zone_id]:on_obj_enter(obj_id, obj, ty)

	if ty == OBJ_TYPE_MONSTER then
		self:add_obj(obj_id, obj, obj:get_pos())
	elseif ty == OBJ_TYPE_HUMAN then
		if self.human_l[obj_id] == nil then
			self.human_l[obj_id] = 1
			self.human_count = self.human_count + 1
		end

		self:start_zone_ai(zone_id)  --开始ai
	end
end
function Scene_monster_common_mgr:on_obj_leave(obj_id, obj)
	--print("-----Scene_monster_common_mgr:on_obj_leave", self.human_count)
	--zone
	local ty = obj:get_type()
	--local zone_id = self:pos_zone(obj:get_pos())
	local zone_id = obj:get_ai_zone()
	self.zone_l[zone_id]:on_obj_leave(obj_id, obj, ty)

	if ty == OBJ_TYPE_MONSTER then
		self:del_obj(obj_id, obj:get_pos())
	elseif ty == OBJ_TYPE_HUMAN then
		if self.human_l[obj_id] ~= nil then
			self.human_l[obj_id] = nil
			self.human_count = self.human_count - 1
			if self.human_count <= 0 then
				self:close_all_ai()
			end
		end
	end
end
function Scene_monster_common_mgr:on_obj_move(obj_id, obj, old_pos, new_pos)
	--local z_id_s = self:pos_zone(old_pos)
	local z_id_s = obj:get_ai_zone()
	local z_id_d = self:pos_zone(new_pos)
	if z_id_s ~= z_id_d then
		local ty = obj:get_type()
		obj:set_ai_zone(z_id_d)
		local _ = self.zone_l[z_id_s] and self.zone_l[z_id_s]:on_obj_leave(obj_id, obj, ty)
		local _ = self.zone_l[z_id_d] and self.zone_l[z_id_d]:on_obj_enter(obj_id, obj, ty)

		if ty == OBJ_TYPE_HUMAN then
			self:start_zone_ai(z_id_d)      --开始ai
		end
	end
end

function Scene_monster_common_mgr:on_timer(tm)
	local obj_mgr = g_obj_mgr
	for k,v in pairs(self.zone_l) do
		if v:is_ai_running() then
			for o_id,_ in pairs(v.obj_l) do
				--obj:on_timer(tm)
				local obj = obj_mgr:get_obj(o_id)
				if obj ~= nil then
					obj:on_timer(tm)
				end
			end
		end
	end
end

--秒时间函数
function Scene_monster_common_mgr:on_slow_timer(tm)
	--[[for k,v in pairs(self.zone_l) do
		if v:is_ai_running() then
			for _,obj in pairs(v.obj_l) do
				obj:on_slow_timer(tm)
			end
		end
	end]]

	self.close_ai_tm = self.close_ai_tm + tm           --math.floor(1/tm)
	if self.close_ai_tm >= _ai_cls_tm then
		self.close_ai_tm = 0
		self:time_close_ai()
	end
end

--private 函数
function Scene_monster_common_mgr:pos_zone(pos)
	local cx = math.floor(pos[1]/_zone_w)
	local cy = math.floor(pos[2]/_zone_h)
	return cy*self.zone_w + cx
end

--扫描z_id周边的9个zone
function Scene_monster_common_mgr:scan_around_zone(z_id)
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

function Scene_monster_common_mgr:time_close_ai()
	for z_id,z_o in pairs(self.zone_l) do
		if not z_o.ai_close_status and z_o.human_count <= 0 and z_o.guard_count <= 0 then
			local z_l = self:scan_around_zone(z_id)
			z_l[z_id] = nil
			local b = true
			for k,_ in pairs(z_l) do
				if self.zone_l[k].human_count > 0 or 
					self.zone_l[k].guard_count > 0 then
					b = false
					break
				end	
			end
			if b then
				z_o:close_ai()              --关闭ai
			end
		end	
	end
end

function Scene_monster_common_mgr:start_zone_ai(zone_id)
	if not self.zone_l[zone_id] then
		local debug = Debug(g_debug_log)
		local msg = string.format("Scene_monster_common_mgr:start_zone_ai(%s)", tostring(zone_id))
		debug:trace(msg)
	end

	if not self.zone_l[zone_id]:is_ai_status() then
		local z_l = self:scan_around_zone(zone_id)
		for k,_ in pairs(z_l) do
			self.zone_l[k]:start_ai()  --开始ai
		end
	end
end

function Scene_monster_common_mgr:close_all_ai()
	--print("scene all ai closing.......")
	for _,v in pairs(self.zone_l) do
		if v.guard_count <= 0 then
			v:close_ai()
		end
	end
end