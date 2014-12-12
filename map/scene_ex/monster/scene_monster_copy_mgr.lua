
local _ai_tm = 30

Scene_monster_copy_mgr = oo.class(Scene_monster_mgr, "Scene_monster_copy_mgr")

function Scene_monster_copy_mgr:__init()
	self.obj_count = 0
	self.obj_l = {}      --怪物对象列表

	self.human_l = {}      --玩家对象列表
	self.human_count = 0

	--ai方面
	self.ai_status = false        --当前状态
	self.ai_close_status = true   --关闭状态
	self.ai_time = ev.time
end


--event
function Scene_monster_copy_mgr:on_obj_enter(obj_id, obj)
	local ty = obj:get_type()
	if ty == OBJ_TYPE_MONSTER then
		self:add_obj(obj_id, obj, obj:get_pos())
	elseif ty == OBJ_TYPE_HUMAN then
		if self.human_l[obj_id] == nil then
			self.human_l[obj_id] = 1
			self.human_count = self.human_count + 1
		end

		self:start_ai()  
	end
end
function Scene_monster_copy_mgr:on_obj_leave(obj_id, obj)
	local ty = obj:get_type()
	if ty == OBJ_TYPE_MONSTER then
		self:del_obj(obj_id, obj:get_pos())
	elseif ty == OBJ_TYPE_HUMAN then
		if self.human_l[obj_id] ~= nil then
			self.human_l[obj_id] = nil
			self.human_count = self.human_count - 1
			if self.human_count <= 0 then
				self:close_ai()  
			end
		end
	end
end

function Scene_monster_copy_mgr:on_timer(tm)
	local obj_mgr = g_obj_mgr
	if self:is_ai_running() then
		for k,_ in pairs(self.obj_l) do
			local obj = obj_mgr:get_obj(k)
			if obj ~= nil then
				obj:on_timer(tm)
			end
		end
	end
end

--private 函数
function Scene_monster_copy_mgr:start_ai()
	self.ai_close_status = false
	if not self.ai_status then
		self.ai_status = true
		local obj_mgr = g_obj_mgr
		for k,_ in pairs(self.obj_l) do
			local obj = obj_mgr:get_obj(k)
			if obj ~= nil then
				obj:get_ai_obj():initialize()
			end
		end
	end
end

function Scene_monster_copy_mgr:close_ai()
	self.ai_time = ev.time
	self.ai_close_status = true
end

function Scene_monster_copy_mgr:is_ai_running()
	if self.ai_close_status and ev.time > self.ai_time + _ai_tm then
		self.ai_status = false
		return false
	end
	return true
end