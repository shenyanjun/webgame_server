
Small_zone = oo.class(nil, "Small_zone")

function Small_zone:__init(id)
	self.id = id
	self.obj_l = {}     
	self.human_l = {}
	self.human_count = 0
	self.monster_l = {}
	self.monster_count = 0
end

function Small_zone:get_obj_l()
	return self.obj_l
end
function Small_zone:get_obj_count()
	return self.human_count + self.monster_count
end

function Small_zone:get_human_l()
	return self.human_l
end
function Small_zone:get_human_count()
	return self.human_count
end
function Small_zone:get_monster_l()
	return self.monster_l
end
function Small_zone:get_monster_count()
	return self.monster_count
end

--event
function Small_zone:on_obj_enter(obj_id)
	local ty = Obj_mgr.obj_type(obj_id)
	if ty == OBJ_TYPE_HUMAN then
		if self.human_l[obj_id] == nil then
			self.human_count = self.human_count + 1
		end
		self.human_l[obj_id] = ty
		self.obj_l[obj_id] = ty
	elseif ty == OBJ_TYPE_MONSTER then
		if self.monster_l[obj_id] == nil then
			self.monster_count = self.monster_count + 1
		end
		self.monster_l[obj_id] = ty
		self.obj_l[obj_id] = ty
	end
end
function Small_zone:on_obj_leave(obj_id)
	local ty = Obj_mgr.obj_type(obj_id)
	if ty == OBJ_TYPE_HUMAN then
		if self.human_l[obj_id] ~= nil then
			self.human_count = self.human_count - 1
		end
		self.human_l[obj_id] = nil
		self.obj_l[obj_id] = nil
	elseif ty == OBJ_TYPE_MONSTER then
		if self.monster_l[obj_id] ~= nil then
			self.monster_count = self.monster_count - 1
		end
		self.monster_l[obj_id] = nil
		self.obj_l[obj_id] = nil
	end
end
