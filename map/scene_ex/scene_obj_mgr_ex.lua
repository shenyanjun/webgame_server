local human_timeout = 3
local pet_timeout = 3
local npc_timeout = 5

Scene_obj_mgr_ex = oo.class(Scene_obj_mgr, "Scene_obj_mgr_ex")

function Scene_obj_mgr_ex:__init(monster_layout, monster_mgr)
	Scene_obj_mgr.__init(self)

	self.monster_mgr = monster_mgr
	self.monster_layout = monster_layout
end

function Scene_obj_mgr_ex:add_obj(obj)
	local obj_id = obj:get_id()
	local type = obj:get_type()
	
	if OBJ_TYPE_HUMAN == type then
		self.human_con:push_obj(obj_id)
		self.monster_mgr:on_obj_enter(obj_id, obj)
	elseif OBJ_TYPE_MONSTER == type then
		self.monster_con:push_obj(obj_id)
		self.monster_mgr:on_obj_enter(obj_id, obj)
	elseif OBJ_TYPE_BOX == type then
		self.box_con:push_obj(obj_id)
	elseif OBJ_TYPE_NPC == type then
		self.npc_con:push_obj(obj_id)
	elseif OBJ_TYPE_PET == type then
		self.pet_con:push_obj(obj_id)
	end
end

function Scene_obj_mgr_ex:del_obj(obj)
	local obj_id = obj:get_id()
	local type = obj:get_type()
	
	if OBJ_TYPE_HUMAN == type then
		self.human_con:pop_obj(obj_id)
		self.monster_mgr:on_obj_leave(obj_id, obj)
	elseif OBJ_TYPE_MONSTER == type then
		self.monster_con:pop_obj(obj_id)
		self.monster_mgr:on_obj_leave(obj_id, obj)
		self.monster_layout:del_obj(obj_id, obj:get_occ(), obj:get_home_pos())
	elseif OBJ_TYPE_BOX == type then
		self.box_con:pop_obj(obj_id)
	elseif OBJ_TYPE_NPC == type then
		self.npc_con:pop_obj(obj_id)
		self.monster_layout:del_obj(obj_id, obj:get_occ(), obj:get_pos())
	elseif OBJ_TYPE_PET == type then
		self.pet_con:pop_obj(obj_id)
	end
end

function Scene_obj_mgr_ex:on_obj_move(obj_id, obj, pos, des_pos)
	self.monster_mgr:on_obj_move(obj_id, obj, pos, des_pos)
end

function Scene_obj_mgr_ex:instance(w, h)
	self.monster_mgr:load(w, h)
	self.monster_layout:load()
end

function Scene_obj_mgr_ex:on_timer(tm)
--[[
	local now = ev.time
	self.monster_mgr:on_timer(tm)

	if self.timeout <= now then
		self.timeout = now + 1
		
		self.monster_mgr:on_slow_timer(1)
		
		self.human_con:on_timer(1)
		self.box_con:on_timer(1)
		self.npc_con:on_timer(1)
		self.pet_con:on_timer(1)
	end
]]	
	local now = ev.time

	self.monster_mgr:on_timer(tm)
	
	if self.human_timeout <= now then
		self.human_timeout = ev.time + human_timeout
		self.human_con:on_timer(human_timeout)
	end
	
	if self.pet_timeout <= now then
		self.pet_timeout = ev.time + pet_timeout
		
		self.pet_con:on_timer(pet_timeout)
		self.box_con:on_timer(pet_timeout)
	end
	
	if self.npc_timeout <= now then
		self.npc_timeout = ev.time + npc_timeout
		self.npc_con:on_timer(npc_timeout)
	end
end

function Scene_obj_mgr_ex:on_slow_timer(tm)
	self.monster_layout:update()
	self.monster_mgr:on_slow_timer(tm)
end