local pet_skill_config = require("config.loader.pet_fight_combat_skill_load")
local _pet_expr = require("config.pet_fight_expr")
local _expr = require("config.expr")
local _pet_exp = require("config.pet_config")
local pet_fight_config = require("config.xml.pet.pet_fight.pet_fight_config")

D_skill_base = oo.class(nil,"D_skill_base")

function D_skill_base:__init(skill_id, type)
	self.skill_id = skill_id
	self.type = type
	self.cmd_id = skill_id - skill_id % 100
	self.cd = 0
end

function D_skill_base:get_skill_id()
	return self.skill_id
end

function D_skill_base:get_type()
	return self.type
end

function D_skill_base:get_cd()
	return self.cd
end

function D_skill_base:set_cd(cd)
	if cd < 0 then
		cd = 0
	end
	self.cd = cd
end

function D_skill_base:get_cmd_id()
	return self.cmd_id
end

function D_skill_base:get_status()
	if self.cd <= 0 then
		return 0
	end
	return self.cd
end

function D_skill_base:get_level()
	return self.skill_id % 100
end

function D_skill_base:effect(obj_s, obj_d)
	return 0
end

function D_skill_base:effect(obj_s,strategy_con_s, strategy_con_d, index)
	return 0
end


-----战斗技能--------------------------

D_skill_combat = oo.class(D_skill_base,"D_skill_combat")

function D_skill_combat:__init(skill_id, type)
	D_skill_base.__init(self, skill_id, type)

	self.ak = pet_skill_config.skill_param[self.cmd_id][skill_id-self.cmd_id][2]			--攻击力
	self.ak_class = pet_skill_config.skill_config[self.cmd_id][4]			--技能伤害类型
	self.cd = pet_skill_config.skill_config[self.cmd_id][2]
end


function D_skill_combat:get_rank(obj_s, strategy_con_s, strategy_con_d, index)
	if index == nil then return end
	local index_list = pet_fight_config.pet_addr[index]

	local attack_index = 0
	local pet = {}
	for k, v in pairs(index_list) do
		local pet_obj = strategy_con_d:get_pet(v)		
		if pet_obj and pet_obj:get_hp() > 0 then
			attack_index = v
			pet = {pet_obj, v}
			break
		end
	end

	if attack_index == 0 then
		for i = 1, 9 do
			local pet_obj = strategy_con_d:get_pet(i)			
			if pet_obj and pet_obj:get_hp() > 0 then
				attack_index = i
				pet = {pet_obj, i}
				break
			end
		end
	end

	if attack_index == 0 then return end

	local skill_position = pet_fight_config.skill_position[self.cmd_id]
	if skill_position == nil then
		return {pet}
	else
		local index_list = pet_fight_config.pet_position[attack_index][skill_position]
		return self:strategy_pet(index_list, strategy_con_d)
	end
end

function D_skill_combat:strategy_pet(index_list,strategy_con_d)
	local pet_list = {}

	for k, v in pairs(index_list) do
		local pet_obj = strategy_con_d:get_pet(v)
		if pet_obj and pet_obj:get_hp() > 0 then
			table.insert(pet_list, {pet_obj, v})
		end
	end

	return pet_list
end

function D_skill_combat:effect_ex(obj_s,strategy_con_s, strategy_con_d, index)
	local pet_list = self:get_rank(obj_s,strategy_con_s, strategy_con_d, index)
	local info = {}
	local dead_info = {}
	local addition_hp_list = 0
	for k, v in pairs(pet_list) do
		local new_pkt,p_nil,addition_hp = self:make_hp_pkt(obj_s, v[1], self.ak, self.ak_class)  --计算伤害
		local hp = math.floor(-new_pkt.hp)
		v[1]:del_hp(hp)
		table.insert(info, {v[2],hp})
		if v[1]:get_hp() <= 0 then
			table.insert(dead_info,v[2])
		end

		addition_hp_list = addition_hp_list + addition_hp
		--print("32323",addition_hp_list)
	end

	return info, dead_info, addition_hp_list
end

function D_skill_combat:effect(obj_s,obj_d)
	local new_pkt,p_nil,addition_hp = self:make_hp_pkt(obj_s, obj_d, self.ak, self.ak_class)  --计算伤害
	local hp = math.floor(-new_pkt.hp)
	obj_d:del_hp(hp)
	return hp,addition_hp
end

--obj_s:技能使用者
--obj_d:技能的目标
--ak:技能使用者的攻击力
--dg_type:技能伤害类型
function D_skill_combat:make_hp_pkt(obj_s, obj_d, ak, dg_type)
	local damage_pet_expr
	if dg_type == nil or dg_type == 1 or dg_type == 0 then		--物理伤害
		damage_pet_expr = _pet_expr.pet_s_damage
	elseif dg_type == 2 then					--魔法伤害
		damage_pet_expr = _pet_expr.pet_m_damage
	elseif dg_type == 3 then 					--冰攻伤害
		damage_pet_expr = _pet_expr.pet_ice_damage
	elseif dg_type == 4 then					--雷攻伤害
		damage_pet_expr = _pet_expr.pet_fire_damage
	elseif dg_type == 5 then					--毒攻伤害
		damage_pet_expr = _pet_expr.pet_poison_damage
	end

	local new_pkt = {}
	--[[new_pkt.obj_id = obj_d:get_id()
	new_pkt.type = 0
	new_pkt.hp = 0
	new_pkt.mp = 0]]

	new_pkt[1] = 0
	new_pkt[2]= 0--obj_d:get_pet_id()
	new_pkt[3] = 0
	new_pkt[4] = 0

	--if _expr.human_miss(obj_s, obj_d) then
		--new_pkt[1] = 1
	--else
		ak = math.floor(ak)
		new_pkt[3],new_pkt[1] = damage_pet_expr(obj_s, obj_d, ak, self:get_level(), self:get_cmd_id())
	--end

	new_pkt.hp = new_pkt[3]  --兼容老代码
	--ak = math.floor(ak)
	--new_pkt[3],new_pkt[1] = damage_pet_expr(obj_s, obj_d, ak, self:get_level(), self:get_cmd_id())

	local addition_hp = 0
	--吸血被动技能
	local hp = obj_s:get_vampire_hp()
	if hp ~= 0 and hp ~= nil then
		addition_hp = hp *  (-new_pkt.hp)
	end

	--复仇被动技能
	local sub_hp = obj_d:get_sub_hp()
	if sub_hp ~=0 and sub_hp ~= nil then
		local hp = sub_hp * (-new_pkt.hp)
		local t = hp
		if hp > obj_d:get_hp() then
			hp = obj_d:get_hp()
		end
		addition_hp = addition_hp - hp
	end

	--吸血主动技能，给挑战宠物回复生命值
	local cmd_id = self:get_cmd_id()
	if cmd_id == 2250700 or cmd_id == 2250800 then
		local enrich_ratio = pet_skill_config.skill_param[self.cmd_id][self:get_level()][8] or 0
		addition_hp = addition_hp + (-new_pkt.hp) * enrich_ratio
	--elseif cmd_id == 2230700 then
		--local percent = math.floor((1.2 - obj_d:get_hp()/obj_d:get_max_hp()) * 0.5 * 100)
		--local ex_hp = 0
		--local num = math.random(1,100)
		--if percent <= num then
			--local damage_ex =  pet_skill_config.skill_param[self.cmd_id][self:get_level()][10]
			--local strengh_ex_ratio = pet_skill_config.skill_param[self.cmd_id][self:get_level()][11]
			--local intelligence_ex_ratio = pet_skill_config.skill_param[self.cmd_id][self:get_level()][12]
			--local stemina_ex_ratio = pet_skill_config.skill_param[self.cmd_id][self:get_level()][13]
			--local dexterity_ex_ratio = pet_skill_config.skill_param[self.cmd_id][self:get_level()][14]
--
			--local strengh_ex = obj_s:get_strengh_t() * strengh_ex_ratio
			--local intelligence_ex = obj_s:get_intelligence_t() * intelligence_ex_ratio
			--local stemina_ex = obj_s:get_stemina_t() * stemina_ex_ratio
			--local dexterity_ex = obj_s:get_dexterity_t() * dexterity_ex_ratio
--
			--if strengh_ex ~= 0 then
				--ex_hp = damage_ex + strengh_ex
			--end
--
			--if intelligence_ex ~= 0 then
				--ex_hp = damage_ex + intelligence_ex
			--end
--
			--if stemina_ex ~= 0 then
				--ex_hp = damage_ex + stemina_ex
			--end
--
			--if dexterity_ex ~= 0 then
				--ex_hp = damage_ex + dexterity_ex
			--end
--
			--
			--local pet_attack_param_l = _pet_exp.pet_attack_param[self:get_level()]
			--if dg_type == nil or dg_type == 1 then		--物理伤害
				--ex_hp = pet_attack_param_l * ex_hp / obj_d:get_s_defense_t()
			--elseif dg_type == 2 then					--魔法伤害
				--ex_hp = pet_attack_param_l * ex_hp / obj_d:get_m_defense_t()
			--elseif dg_type == 3 then 					--冰攻伤害
				--
			--elseif dg_type == 4 then					--雷攻伤害
				--
			--elseif dg_type == 5 then					--毒攻伤害
				--
			--end
		--end
--
		--new_pkt.hp = new_pkt.hp - ex_hp
	end

	local addit_hp = 0
	if addition_hp < 0 then
		obj_s:del_hp(math.floor(- addition_hp))
		addit_hp = - math.floor(- addition_hp)
	elseif addition_hp > 0 then
		obj_s:add_hp(math.floor(addition_hp))
		addit_hp = math.floor(addition_hp)
	end

	return new_pkt,new_pkt[3],addit_hp
end

function D_skill_combat:send_syn()
end



----------被动技能-------------------------------

D_skill_passive = oo.class(D_skill_base, "D_skill_passive")

function D_skill_passive:__init(skill_id, type)
	D_skill_base.__init(self, skill_id, type)



end