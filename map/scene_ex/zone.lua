
Scene_zone = oo.class(nil, "Scene_zone")

function Scene_zone:__init(id)
	self.id = id
	self.obj_l = {}      --不包含掉落包对象
	self.human_l = {}
	self.monster_l = {}
	self.box_l = {}
	self.npc_l = {}
	self.pet_l = {}
end

function Scene_zone:get_obj_l()
	return self.obj_l
end
function Scene_zone:get_human_l()
	return self.human_l
end
function Scene_zone:get_monster_l()
	return self.monster_l
end
function Scene_zone:get_box_l()
	return self.box_l
end
function Scene_zone:get_npc_l()
	return self.npc_l
end
function Scene_zone:get_pet_l()
	return self.pet_l
end

--event
function Scene_zone:on_obj_enter(obj_id)
	local ty = Obj_mgr.obj_type(obj_id)
	if ty == OBJ_TYPE_HUMAN then
		self.human_l[obj_id] = ty
		self.obj_l[obj_id] = ty
	elseif ty == OBJ_TYPE_MONSTER then
		self.monster_l[obj_id] = ty
		self.obj_l[obj_id] = ty
	elseif ty == OBJ_TYPE_BOX then
		self.box_l[obj_id] = ty
	elseif ty == OBJ_TYPE_NPC then
		self.npc_l[obj_id] = ty
	elseif ty == OBJ_TYPE_PET then
		self.pet_l[obj_id] = ty
		self.obj_l[obj_id] = ty
	end
end
function Scene_zone:on_obj_leave(obj_id)
	local ty = Obj_mgr.obj_type(obj_id)
	if ty == OBJ_TYPE_HUMAN then
		self.human_l[obj_id] = nil
		self.obj_l[obj_id] = nil
	elseif ty == OBJ_TYPE_MONSTER then
		self.monster_l[obj_id] = nil
		self.obj_l[obj_id] = nil
	elseif ty == OBJ_TYPE_BOX then
		self.box_l[obj_id] = nil
	elseif ty == OBJ_TYPE_NPC then
		self.npc_l[obj_id] = nil
	elseif ty == OBJ_TYPE_PET then
		self.pet_l[obj_id] = nil
		self.obj_l[obj_id] = nil
	end
end
