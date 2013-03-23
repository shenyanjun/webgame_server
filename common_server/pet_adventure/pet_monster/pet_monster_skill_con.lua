
local pet_expr = require("pet_adventure.pet_monster.pet_monster_expr")
local pet_passive_skill = require("config.loader.pet_fight_passive_skill_loader")

Pet_monster_skill_con = oo.class(nil, "Pet_monster_skill_con")

function Pet_monster_skill_con:__init(occ)
	self.occ = occ

	self.effective_skill = {}
	self.base_skill_obj = nil

	--被动技能属性列表
	self.passive_attr ={}

	--冷却顺序
	self.skill_sort = {}
end

function Pet_monster_skill_con:get_effective_list()
	return self.effective_skill
end

function Pet_monster_skill_con:init_base_skill()

	local base_skill_id = pet_expr.get_base_skill(self.occ)

	if not base_skill_id then 
		print("Error:init_base_skill failed!".. occ)
		return 
	end

	self.base_skill_obj = g_d_skill_mgr:get_skill(base_skill_id)
end

--获取被动技能的所有属性
function Pet_monster_skill_con:set_passive_attr()
	for k,v in pairs(self.effective_skill or {}) do
		local cmd_id = v:get_cmd_id()
		local level = v:get_skill_id() - cmd_id
		if v:get_type() == SKILL_PASSIVE then
			local extra = pet_passive_skill.skill_passive_param[cmd_id][level]
			for m, n in pairs(extra) do
				if self.passive_attr[m] == nil then
					self.passive_attr[m] = {}
					self.passive_attr[m][1] = 0     --值
					self.passive_attr[m][2] = 0     --比率
				end
				self.passive_attr[m][1] = self.passive_attr[m][1] + n[1]
				self.passive_attr[m][2] = self.passive_attr[m][2] + n[2]
			end
		end	
	end
end

function Pet_monster_skill_con:get_passive_attr()
	return self.passive_attr
end

function Pet_monster_skill_con:init_effective_skill(skill_list)
	for k, v in pairs(skill_list) do
		local skill_obj = g_d_skill_mgr:get_skill(v.skill)
		if skill_obj then
			table.insert(self.effective_skill, skill_obj)
		end
	end
end


function Pet_monster_skill_con:use(pet_s,pet_d)
	local skill_id = self:get_effective_skill_id()
	local hp = 0
	local addition_hp = 0
	if skill_id ~= nil then
		local skill_o = g_d_skill_mgr:get_skill(skill_id)
		hp,addition_hp = skill_o:effect(pet_s,pet_d)
	else
		print("Error: this skill_id is not useabale")
	end
	self:sub_cd()
	local skill_con = pet_d:get_skill_con()
	skill_con:sub_cd()
	return skill_id,hp,addition_hp
end

--统一减少cd时间
function Pet_monster_skill_con:sub_cd()
	--for k, v in pairs(self.effective_skill or{}) do
		--local cd = v:get_cd()
		--if cd ~= 0 then
			--v:set_cd(cd-1)
		--end
	--end
	--local cd = self.base_skill_obj:get_cd()
	--if cd ~= 0 then
		--self.base_skill_obj:set_cd(cd-1)
	--end
	for k, v in pairs(self.skill_sort) do
		if v[2] > 0 then
			v[2] = v[2] -1
		end
	end
end

---阵法闯关
function Pet_monster_skill_con:use_ex(pet_s,strategy_con_s, strategy_con_d, index)
	local skill_id = self:get_effective_skill_id()
	local info = nil
	local dead_info = nil
	local addition_hp = 0
	if skill_id ~= nil then
		local skill_o = g_d_skill_mgr:get_skill(skill_id)
		info, dead_info, addition_hp = skill_o:effect_ex(pet_s,strategy_con_s, strategy_con_d, index)
	else
		print("Error: this skill_id is not useabale")
	end

	return skill_id, info, dead_info, addition_hp
end

--统一减少cd时间
function Pet_monster_skill_con:sub_cd_ex()
	--for k, v in pairs(self.effective_skill or{}) do
		--local cd = v:get_cd()
		--if cd ~= 0 then
			--v:set_cd(cd-1)
		--end
	--end
	--local cd = self.base_skill_obj:get_cd()
	--if cd ~= 0 then
		--self.base_skill_obj:set_cd(cd-1)
	--end
	for k, v in pairs(self.skill_sort) do
		if v[2] > 0 then
			v[2] = v[2] -2
			if v[2] < 0 then
				v[2] = 0
			end
		end
	end
end

--初始化技能cd时间
function Pet_monster_skill_con:sub_all_cd()
	--for k, v in pairs(self.effective_skill or{}) do
		--local cd = v:get_cd()
		--if cd ~= 0 then
			--v:set_cd(0)
		--end
	--end
	--local cd = self.base_skill_obj:get_cd()
	--if cd ~= 0 then
		--self.base_skill_obj:set_cd(0)
	--end

	self.skill_sort = {}
	for k, v in pairs(self.effective_skill or{}) do
		if v:get_type() == SKILL_BAD then
			local skill_id = v:get_skill_id()
			local ret = {}
			ret[1] = skill_id
			ret[2] = 0
			table.insert(self.skill_sort, ret)
		end
	end
	local skill_id = self.base_skill_obj:get_skill_id()
	local ret = {}
	ret[1] = skill_id
	ret[2] = 0
	table.insert(self.skill_sort, ret)
end

function Pet_monster_skill_con:get_effective_skill_id()
	--for k,v in pairs(self.effective_skill) do
		--local cmd_id = v:get_cmd_id()
		--local flag = 0
		--for m, n in ipairs(self.skill_sort) do
			--if n:get_cmd_id() == cmd_id then
				--flag = 1
				--self.skill_sort[m] = v
				--break
			--end
		--end
		--if flag == 0 then
			--table.insert(self.skill_sort, v)
		--end
	--end
--
	--for k,v in ipairs(self.skill_sort) do
		--if v:get_type() == SKILL_BAD then
			--if v:get_status() == 0 then
				--table.remove(self.skill_sort,k)
				--table.insert(self.skill_sort,v)
				--return v:get_skill_id()
			--end
		--end
	--end
--
	--return self.base_skill_obj:get_skill_id()

	for k,v in pairs(self.skill_sort) do
		if v[2] == 0 then
			if v[1] == self.base_skill_obj:get_skill_id() then
				v[2] = self.base_skill_obj:get_cd()
				table.remove(self.skill_sort, k)
				local ret = {}
				ret[1] = v[1]
				ret[2] = v[2]
				table.insert(self.skill_sort, ret)
				return self.base_skill_obj:get_skill_id()
			else
				for m, n in pairs(self.effective_skill) do
					local skill_id = n:get_skill_id()
					if skill_id == v[1] then
						v[2] = n:get_cd()
						table.remove(self.skill_sort, k)
						local ret = {}
						ret[1] = v[1]
						ret[2] = v[2]
						table.insert(self.skill_sort, ret)

						return skill_id
					end
				end
			end
		end
	end
	return self.base_skill_obj:get_skill_id()
end


