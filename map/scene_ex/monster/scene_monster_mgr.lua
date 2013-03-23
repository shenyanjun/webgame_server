
local _ai_tm = 30      --ai关闭缓冲时间

Monster_zone = oo.class(nil, "Monster_zone")

function Monster_zone:__init(id)
	self.id = id
	self.obj_l = {}     --怪物对象列表
	self.obj_count = 0 

	self.human_l = {}   --玩家对象列表
	self.human_count = 0
	   
	self.guard_l = {}
	self.guard_count = 0 --守卫

	--ai方面
	self.ai_status = false        --当前状态
	self.ai_close_status = true   --关闭状态
	self.ai_time = ev.time

	--时间计数
	--self.time_count = 0
end

function Monster_zone:get_obj_l()
	return self.obj_l
end
function Monster_zone:get_count()
	return self.obj_count
end

------------AI方面-----------
function Monster_zone:start_ai()
	--print("scene ai starting.......", self.id, self.ai_status)
	self.ai_close_status = false
	if not self.ai_status then
		self.ai_status = true
		local obj_mgr = g_obj_mgr
		for k,v in pairs(self.obj_l) do
			--v:get_ai_obj():initialize()
			local obj = obj_mgr:get_obj(k)
			if obj ~= nil then
				obj:get_ai_obj():initialize()
			end
		end
	end
end
function Monster_zone:close_ai()
	--print("scene ai closing.......", self.id)
	self.ai_time = ev.time
	self.ai_close_status = true
end
function Monster_zone:is_ai_running()
	if self.ai_close_status and ev.time > self.ai_time + _ai_tm then
		self.ai_status = false
		return false
	end
	return true
end
function Monster_zone:is_ai_status()
	return self.ai_status and not self.ai_close_status
end


--event
function Monster_zone:on_obj_enter(obj_id, obj, ty)
	--local ty = obj:get_type()
	if ty == OBJ_TYPE_HUMAN then
		if self.human_l[obj_id] == nil then
			self.human_l[obj_id] = 1
			self.human_count = self.human_count + 1
		end

		if self.human_count == 1 then  
			self:start_ai()   --开始ai
		end
	elseif ty == OBJ_TYPE_MONSTER then
		if self.obj_l[obj_id] == nil then
			--self.obj_l[obj_id] = obj
			self.obj_l[obj_id] = 1
			self.obj_count = self.obj_count + 1

			if obj:get_occ() > MONSTER_GUARD then
				self.guard_l[obj_id] = 1
				self.guard_count = self.guard_count + 1
				self:start_ai()   --开始ai
			end
		end
	end
end
function Monster_zone:on_obj_leave(obj_id, obj, ty)
	--local ty = obj:get_type()
	if ty == OBJ_TYPE_HUMAN then
		if self.human_l[obj_id] ~= nil then
			self.human_l[obj_id] = nil
			self.human_count = self.human_count - 1
		end
	elseif ty == OBJ_TYPE_MONSTER then
		if self.obj_l[obj_id] ~= nil then
			self.obj_l[obj_id] = nil
			self.obj_count = self.obj_count - 1

			if self.guard_l[obj_id] ~= nil then
				self.guard_l[obj_id] = nil
				self.guard_count = self.guard_count - 1

				if self.human_count <= 0 and self.guard_count <= 0 then
					self:close_ai()              --关闭ai
				end	
			end
		end
	end
end




----------------------------------------

Scene_monster_mgr = oo.class(nil, "Scene_monster_mgr")

function Scene_monster_mgr:__init()
	self.obj_count = 0
	self.obj_l = {}      --怪物对象列表

	self.human_l = {}      --玩家对象列表
	self.human_count = 0

	--ai
	self.close_ai_tm = 0
end

function Scene_monster_mgr:load(w, h)
end

function Scene_monster_mgr:add_obj(obj_id, obj, pos)
	if self.obj_l[obj_id] == nil then
		--self.obj_l[obj_id] = obj
		self.obj_l[obj_id] = 1
		self.obj_count = self.obj_count + 1
	end
end

function Scene_monster_mgr:del_obj(obj_id, pos)
	if self.obj_l[obj_id] ~= nil then
		self.obj_l[obj_id] = nil
		self.obj_count = self.obj_count - 1
	end
end

function Scene_monster_mgr:clean()
	self.obj_l = {}
	self.obj_count = 0
end

--[[function Scene_monster_mgr:get_obj(obj_id)
	return self.obj_l[obj_id]
end]]
function Scene_monster_mgr:get_obj_l()
	return self.obj_l
end
function Scene_monster_mgr:get_count()
	return self.obj_count
end

--event
function Scene_monster_mgr:on_obj_enter(obj_id, obj)
end
function Scene_monster_mgr:on_obj_leave(obj_id, obj)
end
function Scene_monster_mgr:on_obj_move(obj_id, obj, old_pos, new_pos)
end

function Scene_monster_mgr:on_timer(tm)
end

--秒时间函数
function Scene_monster_mgr:on_slow_timer(tm)
end



