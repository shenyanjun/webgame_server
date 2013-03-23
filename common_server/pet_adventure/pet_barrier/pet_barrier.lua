

local pet_barrier_loader = require("pet_adventure.pet_barrier.pet_barrier_loader")

Pet_barrier = oo.class(nil,"Pet_barrier")

function Pet_barrier:__init(barrier_id)
	self.barrier_id = barrier_id
	--self.battle_type = pet_barrier_loader.barrier_list[barrier_id].battle_type
	--self.barrier_name = pet_barrier_loader.barrier_list[barrier_id].barrier_name
	--self.barrier_list = pet_barrier_loader.barrier_list[barrier_id].level_list
	--self.condition = pet_barrier_loader.barrier_list[barrier_id].condition
end


function Pet_barrier:get_barrier_id()
	return self.barrier_id
end
function Pet_barrier:get_barrier_name()
	return pet_barrier_loader.barrier_list[self.barrier_id].barrier_name
end

function Pet_barrier:get_battle_type()
	return pet_barrier_loader.barrier_list[self.barrier_id].battle_type
end

function Pet_barrier:get_barrier_by_level(level)
	return pet_barrier_loader.barrier_list[self.barrier_id].level_list[level]
end

function Pet_barrier:get_barrier_monster(level)
	local monster = pet_barrier_loader.barrier_list[self.barrier_id].level_list[level].monster
	return monster
end

function Pet_barrier:get_barrier_reward(level)
	local reward = pet_barrier_loader.barrier_list[self.barrier_id].level_list[level].reward
	return reward
end

function Pet_barrier:get_barrier_condition()
	return pet_barrier_loader.barrier_list[self.barrier_id].condition
end

function Pet_barrier:get_barrier_list()
	return pet_barrier_loader.barrier_list[self.barrier_id].level_list
end




