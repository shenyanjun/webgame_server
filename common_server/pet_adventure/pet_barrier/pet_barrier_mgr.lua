
local pet_barrier_loader = require("pet_adventure.pet_barrier.pet_barrier_loader")

Pet_barrier_mgr = oo.class(nil,"Pet_barrier_mgr")

function Pet_barrier_mgr:__init()
	self.barrier_obj_list = {}

	self:build_pet_barrier_list()
end


function Pet_barrier_mgr:add_pet_barrier(pet_barrier)
	local barrier_id = pet_barrier:get_barrier_id()
	self.barrier_obj_list[barrier_id] = pet_barrier
end

function Pet_barrier_mgr:del_pet_barrier(barrier_id)
	if barrier_id == nil then return end
	self.barrier_obj_list[barrier_id] = nil
end

function Pet_barrier_mgr:get_pet_barrier(barrier_id)
	return self.barrier_obj_list[barrier_id]
end

function Pet_barrier_mgr:get_list()
	return self.barrier_obj_list
end

function Pet_barrier_mgr:build_pet_barrier_list()
	for k,v in pairs(pet_barrier_loader.barrier_list) do
		local pet_barrier = Pet_barrier(k)
		self:add_pet_barrier(pet_barrier)
	end
end