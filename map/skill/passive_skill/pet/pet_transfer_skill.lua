

--宠物属性转移人物属性技能
Pet_transfer_skill = oo.class(Skill_passive,"Pet_transfer_skill")

local pet_transfer_skill = require("skill.passive_skill.pet.pet_passive_skill_load")

function Pet_transfer_skill:__init(skill_type, level)
	Skill_passive.__init(self, skill_type + level, SKILL_TRANSFER_ATTR, skill_type, level)
	self.equip_l = pet_transfer_skill.skill_transfer_param[skill_type][skill_type+level]				--宠物转移属性点数
	self.equip_l_ratio = pet_transfer_skill.skill_transfer_param_ratio[skill_type][skill_type+level]	--宠物转移属性比率
end

function Pet_transfer_skill:get_effect(param)
	return nil
end

--使用宠物属性转移到人物身上的情况:
--1宠物出战 2玩家登陆,宠物处于出战状态 3添加技能
function Pet_transfer_skill:effect(sour_id, param)
	local equip_l = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}

	local player = g_obj_mgr:get_obj(param.owner_id)
	local pet_con = player:get_pet_con()
	local pet_obj = pet_con:get_pet_obj(sour_id)

	if pet_obj == nil then
		print("Error: the pet is missing!",param.owner_id)
		return equip_l
	end

	--根骨、悟性、体魄、身法
	local strengh = pet_obj:get_strengh_t()
	local intelligence = pet_obj:get_intelligence_t()
	local stemina = pet_obj:get_stemina_t()
	local dexterity = pet_obj:get_dexterity_t()

	--根骨、悟性、体魄、身法
	--计算方式:属性点数+属性*属性比率
	equip_l[17] = self.equip_l[17] + strengh * self.equip_l_ratio[17]
	equip_l[18] = self.equip_l[18] + intelligence * self.equip_l_ratio[18]
	equip_l[19] = self.equip_l[19] + stemina * self.equip_l_ratio[19]
	equip_l[20] = self.equip_l[20] + dexterity * self.equip_l_ratio[20]

	return equip_l
end

local skill_transfer_builder = function()
	local skill_name_format = "Skill_%d"
	local _skill_param = pet_transfer_skill.skill_transfer_param
	for skill_type, skill_params in pairs(_skill_param) do
		for level, params in pairs(skill_params) do
			local skill_name = string.format(skill_name_format, level)
			_G[skill_name] = Pet_transfer_skill(skill_type, level%100)
		end
	end
end


skill_transfer_builder()
