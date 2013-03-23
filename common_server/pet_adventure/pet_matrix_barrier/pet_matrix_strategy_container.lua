local pet_matrix_barrier_loader = require("pet_adventure.pet_matrix_barrier.pet_matrix_barrier_loader")

Pet_matrix_strategy_container = oo.class(nil,"Pet_matrix_strategy_container")

function Pet_matrix_strategy_container:__init()
	self.monster_list = {0,0,0,0,0,0,0,0,0}
end

function Pet_matrix_strategy_container:create_monster_list(barrier_id, level)
	self.monster_list = {0,0,0,0,0,0,0,0,0}
	local monster = pet_matrix_barrier_loader.barrier_list[barrier_id].level_list[level].monster
	local monster_mgr = g_pet_monster_mgr
	for k, v in pairs(monster) do
		local occ = v[1]
		local monster_obj = monster_mgr:get_pet_monster(occ)
		if monster_obj then
			local attr = {v[6],v[7],v[8],v[9]}
			monster_obj:init_matrix_attr(v[4],v[2],v[3],attr)
			self.monster_list[v[5]] = monster_obj
		end
	end
end

function Pet_matrix_strategy_container:get_monster_list()
	return self.monster_list
end

function Pet_matrix_strategy_container:get_pet(index)
	if self.monster_list[index] == 0 then
		return nil
	end

	return self.monster_list[index]
end

function Pet_matrix_strategy_container:get_pet_attr()
	local attr = {}
	local attr2 = {}
	for k, v in pairs(self.monster_list) do
		if v ~= 0 and v:get_hp() > 0 then
			table.insert(attr, {v:get_monster_id(), v:get_hp(), k, v:get_name(), v:get_level(), v:get_pullulate()})
			table.insert(attr2, {v:get_hp(), k})
		end
	end

	return attr, attr2
end

function Pet_matrix_strategy_container:get_monster(index)
	return self.monster_list[index]
end

function Pet_matrix_strategy_container:sud_all_cd()
	for k, v in pairs(self.monster_list) do
		if v ~= 0 and v:get_hp() > 0 then
			local skill_con = v:get_skill_con()
			skill_con:sub_cd_ex()
		end
	end
end
