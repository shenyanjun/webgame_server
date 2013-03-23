local pet_sk_config = require("config.loader.pet_fight_combat_skill_load")
local pet_sk_passive = require("config.loader.pet_fight_passive_skill_loader")

D_skill_mgr = oo.class(nil, "D_skill_mgr")

function D_skill_mgr:__init()
	self.skill_pool = {}

	self:build_pet_combat_skill()
	self:build_pet_passive_skill()
end

function D_skill_mgr:build_pet_combat_skill()
	local skill_param = pet_sk_config.skill_param
	for skill_type, skill_params in pairs(skill_param) do
		for level, params in pairs(skill_params) do
			self.skill_pool[skill_type + level] = D_skill_combat(skill_type + level, SKILL_BAD)
		end
	end
end

function D_skill_mgr:build_pet_passive_skill()
	local skill_param = pet_sk_passive.skill_passive_param
	for skill_type, skill_params in pairs(skill_param) do
		for level, params in pairs(skill_params) do
			self.skill_pool[skill_type + level] = D_skill_passive(skill_type + level, SKILL_PASSIVE)
		end
	end
end

function D_skill_mgr:get_skill(skill_id)
	return self.skill_pool[skill_id]
end