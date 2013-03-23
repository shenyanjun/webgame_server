local pet_monster_loader = require("pet_adventure.pet_monster.pet_monster_loader")

Pet_monster_mgr = oo.class(nil,"Pet_monster_mgr")

function Pet_monster_mgr:__init()
	self.pet_monster_list = {}

	self:build_pet_monster()
end

function Pet_monster_mgr:add_monster(pet_monster)
	if pet_monster == nil then return end
	local occ = pet_monster:get_occ()
	self.pet_monster_list[occ] = pet_monster
end

function Pet_monster_mgr:del_monster(occ)
	if occ == nil then return end
	self.pet_monster_list[occ] = nil
end

function Pet_monster_mgr:get_pet_monster(occ)
	return self.pet_monster_list[occ]
end


function Pet_monster_mgr:build_pet_monster()
	local pet_info = pet_monster_loader._pet_info
	local pet_base = pet_monster_loader._pet_base
	local pet_base_skill = pet_monster_loader._pet_base_skill
	local pet_foundation = pet_monster_loader._pet_foundation
	local pet_acquired_skill = pet_monster_loader._pet_acquired_skill

	for k,v in pairs(pet_info) do
		local pet_monster = Pet_monster(k)
		pet_monster:set_name(v[2])
		--pet_monster:set_level(v[1])
		--pet_monster:set_pullulate(v[4])
		pet_monster:set_occ(v[3])
		pet_monster:set_monster_id(v[5])

		--pet_monster:load_base_attr(pet_foundation[k][1],pet_foundation[k][2],pet_foundation[k][3],pet_foundation[k][4])
		--pet_monster:load_skill_con()

		self:add_monster(pet_monster)

	end
end

