local _config = require("config.xml.human_fight.human_skill_config")
local _magic_config = require("config.xml.human_fight.magic_skill_config")

Human_skill_mgr = oo.class(nil, "Human_skill_mgr")

function Human_skill_mgr:__init()
	self.skill_pool = {}

	self:build_human_combat_skill()

	self:build_human_passive_skill()

	self:build_human_magic_skill()
end

function Human_skill_mgr:build_human_combat_skill()
	local skill_param = _config._skill_p
	for skill_type, skill_params in pairs(skill_param) do
		for level, params in pairs(skill_params) do
			self.skill_pool[skill_type + level] = Human_skill_combat(skill_type + level, SKILL_BAD)
		end
	end
end

function Human_skill_mgr:build_human_passive_skill()
	local skill_param = _config._skill_t
	for skill_type, skill_params in pairs(skill_param) do
		for level, params in pairs(skill_params) do
			self.skill_pool[skill_type + level] = Human_skill_passive(skill_type + level, SKILL_PASSIVE)
		end
	end
end

function Human_skill_mgr:build_human_magic_skill()
	local skill_name_format = "Skill_%d"
	local skill_param = _magic_config._skill_p
	for skill_type, skill_params in pairs(skill_param) do
		for level, params in pairs(skill_params) do
			local skill_name = string.format(skill_name_format, skill_type + level)
			--print("3333333333333333333",_G[skill_name])
			self.skill_pool[skill_type + level] = _G[skill_name]
		end
	end
end

function Human_skill_mgr:get_skill(skill_id)
	return self.skill_pool[skill_id]
end
