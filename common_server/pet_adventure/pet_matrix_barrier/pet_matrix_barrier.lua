

local pet_matrix_barrier_loader = require("pet_adventure.pet_matrix_barrier.pet_matrix_barrier_loader")

Pet_matrix_barrier = oo.class(nil,"Pet_matrix_barrier")

function Pet_matrix_barrier:__init(barrier_id)
	self.barrier_id = barrier_id
	self.pet_strategy = Pet_matrix_strategy_container()
end

function Pet_matrix_barrier:get_strategy(level)
	self.pet_strategy:create_monster_list(self.barrier_id, level)
	return self.pet_strategy
end

function Pet_matrix_barrier:get_barrier_id()
	return self.barrier_id
end

function Pet_matrix_barrier:get_barrier_name()
	return pet_matrix_barrier_loader.barrier_list[self.barrier_id].barrier_name
end

function Pet_matrix_barrier:get_battle_type()
	return pet_matrix_barrier_loader.barrier_list[self.barrier_id].battle_type
end

function Pet_matrix_barrier:get_barrier_by_level(level)
	return pet_matrix_barrier_loader.barrier_list[self.barrier_id].level_list[level]
end

function Pet_matrix_barrier:get_barrier_monster(level)
	local monster = pet_matrix_barrier_loader.barrier_list[self.barrier_id].level_list[level].monster
	return monster
end

function Pet_matrix_barrier:get_barrier_reward(level)
	local reward = pet_matrix_barrier_loader.barrier_list[self.barrier_id].level_list[level].reward
	return reward
end

function Pet_matrix_barrier:get_barrier_condition()
	return pet_matrix_barrier_loader.barrier_list[self.barrier_id].condition
end

function Pet_matrix_barrier:get_barrier_list()
	return pet_matrix_barrier_loader.barrier_list[self.barrier_id].level_list
end




