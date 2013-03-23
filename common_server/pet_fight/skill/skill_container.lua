local pet_skill_table = "pet_skill"
local combination = require("config.pet_skill_combination")
local pet_passive_skill = require("config.loader.pet_fight_passive_skill_loader")
local pet_expr = require("config.pet_fight_expr")

Skill_container = oo.class(nil, "Skill_container")

function Skill_container:__init(obj_id, owner_id)
	self.obj_id = obj_id
	self.owner_id = owner_id

	--技能列表
	self.skill_list = {}

	--有效技能列表
	self.effective_skill = {}

	--被动技能属性列表
	self.passive_attr ={}

	--自身技能
	self.base_skill_obj = {}

	--冷却顺序
	self.skill_sort = {}

	--
	self.base_effective_skill = {0,0,0,0,0}
	self.addition_effective_skill = {0,0,0,0,0}
	self.addition_skill_list = {{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0}}
	self.special_effective_skill = {0,0}
	self.special_skill = {0,0}
end

function Skill_container:get_last_special_skill()
	--local skill_o_5 = self.effective_skill[6]
	--local skill_o_6 = self.effective_skill[7]
	--local skill_id_5 = 0
	--local skill_id_6 = 0
	--if skill_o_5 then
		--skill_id_5 = skill_o_5:get_skill_id()
	--end
--
	--if skill_o_6 then
		--skill_id_6 = skill_o_6:get_skill_id()
	--end
	return self.special_effective_skill
end

function Skill_container:get_effective_list()
	return self.base_effective_skill
end

function Skill_container:get_skill_list()
	return self.skill_list
end

function Skill_container:init_base_skill(occ)

	local base_skill_id = pet_expr.get_base_skill(occ)

	if not base_skill_id then 
		print("Error:init_base_skill failed!".. occ)
		return 
	end

	self.base_skill_obj = g_skill_mgr:get_skill(base_skill_id)
end

--获取最后的有效技能（包括魂玉里面吸取魂魄之后的技能加成）
function Skill_container:get_last_effective_skill_id(skill_id)
	if skill_id == nil then return end

	local container = g_pet_vs_mgr:get_container(self.owner_id)
	if not container then return end

	local pet_con =container:get_pet_con()
	if not pet_con then return end

	local pet_obj = pet_con:get_pet_obj(self.obj_id)
	if not pet_obj then return end

	local pet_pack = pet_obj:get_equip_con()
	if not pet_pack then return end

	local ret = pet_pack:get_skill_list()

	local mod_skill = skill_id % 100
	local skill_id_ex = skill_id - mod_skill
	
	local t_skill = 0
	if ret[skill_id_ex] ~= nil then
		t_skill = ret[skill_id_ex] + mod_skill
	end

	if t_skill == 0 then
		return skill_id, skill_id_ex, ret[skill_id_ex]	
	elseif t_skill > 12 then
		return skill_id_ex + 12, skill_id_ex, ret[skill_id_ex]
	else 
		return skill_id + ret[skill_id_ex], skill_id_ex, ret[skill_id_ex]
	end

end


--获取被动技能的所有属性
function Skill_container:set_passive_attr()
	self.passive_attr = {}
	for k,v in pairs(self.effective_skill or {}) do
		local level = v % 100
		local cmd_id = v - level
		local skill_obj = g_skill_mgr:get_skill(v)
		if skill_obj:get_type() == SKILL_PASSIVE then
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

function Skill_container:get_passive_attr()
	return self.passive_attr
end


function Skill_container:use(pet_s,strategy_con_s, strategy_con_d)
	local skill_id = self:get_effective_skill_id()
	local info = nil
	local dead_info = nil
	local addition_hp = 0
	if skill_id ~= nil then
		local skill_o = g_skill_mgr:get_skill(skill_id)
		info, dead_info, addition_hp = skill_o:effect(pet_s,strategy_con_s, strategy_con_d)
	else
		print("Error: this skill_id is not useabale")
	end

	return skill_id, info, dead_info, addition_hp
end

--统一减少cd时间
function Skill_container:sub_cd()
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
function Skill_container:sub_all_cd()
	self.skill_sort = {}
	for k, v in pairs(self.effective_skill or{}) do
		local skill_obj = g_skill_mgr:get_skill(v)
		if skill_obj and skill_obj:get_type() == SKILL_BAD then
			local ret = {}
			ret[1] = v
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

function Skill_container:get_effective_skill_id()
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
					if n == v[1] then
						local skill_obj = g_skill_mgr:get_skill(n)
						v[2] = skill_obj:get_cd()
						table.remove(self.skill_sort, k)
						local ret = {}
						ret[1] = v[1]
						ret[2] = v[2]
						table.insert(self.skill_sort, ret)

						return n
					end
				end
			end
		end
	end
	return self.base_skill_obj:get_skill_id()
end

function Skill_container:clear()
	--技能列表
	self.skill_list = {}

	--有效技能列表
	self.effective_skill = {}

	--被动技能列表
	self.passive_attr ={}

	self.special_effective_skill = {0,0}
	self.special_skill = {0,0}

	self.base_effective_skill = {0,0,0,0,0}
	self.addition_effective_skill = {0,0,0,0,0}
	self.addition_skill_list = {{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0}}
end

--玩家更新数据
function Skill_container:update_skill(item_l)
	self:clear()
	self.skill_list = item_l[1] or {{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0}}
	self.special_skill = item_l[2] or {0,0}
	self.addition_skill_list = item_l[3] or {{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0}}

	self:get_newest_effective_skill()
	self:set_passive_attr()
end


function Skill_container:load()
	local dbh = f_get_db()
	local data = "{skill_list:1,special_skill:1,addition_skill_list:1}"
	local query =string.format("{pet_id:%d}",self.obj_id)
	local row, e_code = dbh:select_one(pet_skill_table, data, query)

	if row ~= nil then
		--基础技能
		self.skill_list = row.skill_list or {{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0}}
		--融合技能
		self.addition_skill_list = row.addition_skill_list or {{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0}}
		--天赋技能
		self.special_skill = row.special_skill or {0,0}
		self:get_newest_effective_skill()
		self:set_passive_attr()
	end
end

function Skill_container:get_newest_effective_skill()
	self:update_base_effective_skill()
	self:update_addition_effective_skill()
	self:update_special_effective_skill()

	local effective_skill = {}
	for k, v in ipairs(self.base_effective_skill) do
		if v ~= 0 then
			table.insert(effective_skill, v)
		end
	end
	for k, v in ipairs(self.addition_effective_skill) do
		if v ~= 0 then
			table.insert(effective_skill, v)
		end
	end

	local special_skill = self.special_effective_skill
	for m, n in ipairs(self.special_effective_skill) do
		if n ~= 0 then
			local s_lvl = n % 100
			local s_type = n - s_lvl
			for k, v in ipairs(effective_skill) do
				local e_lvl = v % 100
				local e_type = v - e_lvl
				if e_type == s_type then
					if s_lvl > e_lvl then
						effective_skill[k] = n
						special_skill[m] = 0
					else
						special_skill[m] = 0
					end
					break
				end
			end
		end
	end

	for k, v in ipairs(special_skill) do
		if v ~= 0 then
			table.insert(effective_skill, v)
		end
	end
	
	self.effective_skill = effective_skill
end

function Skill_container:update_base_effective_skill()
	self.base_effective_skill = {0,0,0,0,0}
	for k,v in pairs(self.skill_list) do
		local effective_skill_id,ret = combination.get_pet_skill_combination(v)
		if ret == 0 then
			local effective_skill_id_ex = self:get_last_effective_skill_id(effective_skill_id)
			self.base_effective_skill[k] = effective_skill_id_ex
		end
	end
end

function Skill_container:update_addition_effective_skill()
	self.addition_effective_skill = {0,0,0,0,0}
	for k,v in pairs(self.addition_skill_list) do
		local effective_skill_id,ret = combination.get_pet_skill_combination(v)
		if ret == 0 then
			local effective_skill_id_ex = self:get_last_effective_skill_id(effective_skill_id)
			self.addition_effective_skill[k] = effective_skill_id_ex
		end
	end
end

function Skill_container:update_special_effective_skill()
	self.special_effective_skill = {0,0}
	for k,v in pairs(self.special_skill) do
		if v ~= 0 then
			local effective_skill_id_ex = self:get_last_effective_skill_id(v)
			self.special_effective_skill[k] = effective_skill_id_ex
		end
	end
end





