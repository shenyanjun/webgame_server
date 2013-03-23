--local _DEBUG_ = true;

local debug_print = function () end;
if _DEBUG_ then
	debug_print = print;
end

local pet_passive_skill = require("skill.passive_skill.pet.pet_passive_skill_load")

PetPassiveSkill = oo.class(Skill_passive,"PetPassiveSkill");


function PetPassiveSkill:__init(skill_type, level)
	Skill_passive.__init(self, skill_type + level, SKILL_PASSIVE, skill_type, level);
	self.extra = pet_passive_skill.skill_passive_param[skill_type][level];
	self.skill_type = skill_type
end

function PetPassiveSkill:get_effect(param)
	return nil;
end

function PetPassiveSkill:effect(sour_id, param)
	local player = g_obj_mgr:get_obj(param.owner_id)
	local pet_con = player:get_pet_con()
	local pet_obj = pet_con:get_pet_obj(sour_id)

	for k, v in pairs(self.extra) do
		pet_obj:add_passive_effect(k, nil, v)
	end
end

local skill_builder = function ()
	local skill_name_format = "Skill_%d"
	local skill_param = pet_passive_skill.skill_passive_param
	for skill_type, skill_params in pairs(skill_param) do
		for level, params in pairs(skill_params) do
			local skill_name = string.format(skill_name_format, skill_type + level)
			_G[skill_name] = PetPassiveSkill(skill_type, level)
			debug_print(string.format("Skill_%d", skill_type + level))
			--print("skill_type, leve:",skill_type, level)
		end
	end
end

skill_builder()
