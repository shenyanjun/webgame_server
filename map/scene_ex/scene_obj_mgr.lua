
------------------------------------Scene_obj_container-----------------------------------------
Scene_obj_container = oo.class(nil, "Scene_obj_container")

function Scene_obj_container:__init()
	self.obj_list = {}
	self.obj_count = 0
end

function Scene_obj_container:push_obj(obj_id)
	if not self.obj_list[obj_id] then
		self.obj_list[obj_id] = true
		self.obj_count = self.obj_count + 1
	end
end

function Scene_obj_container:pop_obj(obj_id)
	if self.obj_list[obj_id] then
		self.obj_list[obj_id] = nil
		self.obj_count = self.obj_count - 1
	end
end

function Scene_obj_container:get_obj_list()
	return self.obj_list
end

function Scene_obj_container:get_obj_count()
	return self.obj_count
end

function Scene_obj_container:is_member(obj_id)
	return self.obj_list[obj_id]
end

function Scene_obj_container:on_timer(tm)
	local obj_mgr = g_obj_mgr
	for k, _ in pairs(self.obj_list) do
		local obj = obj_mgr:get_obj(k)
		if obj then
			obj:on_timer(tm)
		end
	end
end

------------------------------------Scene_obj_mgr-----------------------------------------
Scene_obj_mgr = oo.class(nil, "Scene_obj_mgr")

local human_timeout = 2
local pet_timeout = 3
local npc_timeout = 5

function Scene_obj_mgr:__init()
	self.human_con = Scene_obj_container()
	self.monster_con = Scene_obj_container()
	self.box_con = Scene_obj_container()
	self.npc_con = Scene_obj_container()
	self.pet_con = Scene_obj_container()
	
	self.human_timeout = ev.time + human_timeout
	self.pet_timeout = ev.time + pet_timeout
	self.npc_timeout = ev.time + npc_timeout
end

function Scene_obj_mgr:add_obj(obj)
	local obj_id = obj:get_id()
	local type = obj:get_type()
	
	if OBJ_TYPE_HUMAN == type then
		self.human_con:push_obj(obj_id)
	elseif OBJ_TYPE_MONSTER == type then
		self.monster_con:push_obj(obj_id)
	elseif OBJ_TYPE_BOX == type then
		self.box_con:push_obj(obj_id)
	elseif OBJ_TYPE_NPC == type then
		self.npc_con:push_obj(obj_id)
	elseif OBJ_TYPE_PET == type then
		self.pet_con:push_obj(obj_id)
	end
end

function Scene_obj_mgr:del_obj(obj)
	local obj_id = obj:get_id()
	local type = obj:get_type()
	
	if OBJ_TYPE_HUMAN == type then
		self.human_con:pop_obj(obj_id)
	elseif OBJ_TYPE_MONSTER == type then
		self.monster_con:pop_obj(obj_id)
	elseif OBJ_TYPE_BOX == type then
		self.box_con:pop_obj(obj_id)
	elseif OBJ_TYPE_NPC == type then
		self.npc_con:pop_obj(obj_id)
	elseif OBJ_TYPE_PET == type then
		self.pet_con:pop_obj(obj_id)
	end
end

function Scene_obj_mgr:get_obj_con(type)
	local obj_con = nil
	
	if OBJ_TYPE_HUMAN == type then
		obj_con = self.human_con
	elseif OBJ_TYPE_MONSTER == type then
		obj_con = self.monster_con
	elseif OBJ_TYPE_BOX == type then
		obj_con = self.box_con
	elseif OBJ_TYPE_NPC == type then
		obj_con = self.npc_con
	elseif OBJ_TYPE_PET == type then
		obj_con = self.pet_con
	end
	
	return obj_con
end

function Scene_obj_mgr:get_obj(obj_id)
	local obj = g_obj_mgr:get_obj(obj_id)
	
	if obj then
		local type = obj:get_type()
		local con = nil
		
		if OBJ_TYPE_HUMAN == type then
			con = self.human_con
		elseif OBJ_TYPE_MONSTER == type then
			con = self.monster_con
		elseif OBJ_TYPE_BOX == type then
			con = self.box_con
		elseif OBJ_TYPE_NPC == type then
			con = self.npc_con
		elseif OBJ_TYPE_PET == type then
			con = self.pet_con
		end
		
		if not con or not con:is_member(obj_id) then
			return nil
		end
	end
	
	return obj
end

function Scene_obj_mgr:on_obj_move(obj_id, obj, pos, des_pos)
end

function Scene_obj_mgr:instance(w, h)
end

function Scene_obj_mgr:on_timer(tm)
	local now = ev.time

	self.monster_con:on_timer(tm)
	
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

function Scene_obj_mgr:on_slow_timer(tm)
end

function Scene_obj_mgr:on_serialize_timer(tm)
	local obj_mgr = g_obj_mgr
	for obj_id, _ in pairs(self.human_con:get_obj_list()) do
		local obj = obj_mgr:get_obj(obj_id)
		if obj then
			local result, errmsg = pcall(Db_human.on_timer, obj:get_db(), tm)
			if not result then
				print("function Scene_obj_mgr:on_serialize_timer(tm) ", errmsg)
				local _ = g_debug_log and g_debug_log:write("Scene:on_serialize_timer Error:" .. errmsg)
			end
		end
	end
end
