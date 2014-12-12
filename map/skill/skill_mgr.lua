
local debug_print = function () end
local _sk_config = require("config.skill_combat_config")
local pet_sk_config = require("config.loader.pet_combat_skill_load")
local pet_sk_passive = require("skill.passive_skill.pet.pet_passive_skill_load")
local pet_sk_trigger = require("skill.passive_skill.pet.pet_trigger_skill_loader")

local g_skill_pool = {}
--技能类型ID, 技能名称的格式, 技能的初始级别, 技能的最终级别, 技能的类
function f_create_BadSkill(skill_type, skill_name_format, start_lv, limit_lv, skill_class)
	if not skill_type then
		debug_print("skill_type is nil")
		return;
	end
	skill_class = skill_class or BadSkill
	start_lv = start or 1
	limit_lv = limit_lv or 10
	local skill_param = _sk_config._skill_p

	for level = start_lv, limit_lv do
		if not skill_param[skill_type] or not skill_param[skill_type][level] then
			debug_print(string.format("skill_param[%d] is nil", skill_type, level))
			return;
		end
		local skill_name = string.format(skill_name_format, level)
		_G[skill_name] = skill_class(skill_type, level)
		g_skill_pool[skill_type + level] = _G[skill_name]
		debug_print(skill_name, " = ", _G[skill_name])
	end
end
--[[
f_create_BadSkill(SKILL_OBJ_90000, "Skill_900%02d", 1, 1);				--人物物理近战技能
f_create_BadSkill(SKILL_OBJ_90200, "Skill_902%02d", 1, 1);				--人物物理远程技能
]]

local skill_pet_class = {BadSkill, RangeBadSkill, SectorBadSkill, Exploded_around, Skill_add_blood_magic, Skill_pet_buff, Skill_vampire, Skill_indifferent, Skill_qishang}

local function get_skill_class(skill_config)
	local skill_class = skill_pet_class[1]			
	local config_range = skill_config[5]
	skill_class = skill_pet_class[config_range]
	if skill_class == nil then
		print("Error invaild get skill_class!")
	end 
	return skill_class
end

local pet_combat_skill_builder = function ()							--生成所有配置好的宠物战斗技能
	local skill_name_format = "Skill_%d"
	local skill_param = pet_sk_config.skill_param
	local skill_config = pet_sk_config.skill_config

	for skill_type, skill_params in pairs(skill_param) do
		local config_range = skill_config[skill_type]
		if not config_range then
			print("Error invaild pet skill:", skill_type)
		else
			local skill_class = get_skill_class(skill_config[skill_type])
			for level, params in pairs(skill_params) do
				local skill_name = string.format(skill_name_format, skill_type + level)
				_G[skill_name] = skill_class(skill_type, level)
			end
		end
	end
end

pet_combat_skill_builder()

--f_create_BadSkill(SKILL_OBJ_2000000, "Skill_20000%02d", 1, 1);			--宠物物理近战技能
--f_create_BadSkill(SKILL_OBJ_2000100, "Skill_20001%02d", 1, 1);			--宠物物理远程技能
--f_create_BadSkill(SKILL_OBJ_2000200, "Skill_20002%02d", 1, 1);			--宠物魔法近战技能
--f_create_BadSkill(SKILL_OBJ_2000300, "Skill_20003%02d", 1, 1);			--宠物魔法远程技能

--f_create_RangeBadSkill(SKILL_OBJ_2000000, "Skill_20000%02d", 1, 1);		--宠物物理近战技能
--f_create_SectorBadSkill(SKILL_OBJ_2000100, "Skill_20001%02d", 1, 1);			--宠物物理远程技能
--自身技能列表
--local _self_skill_l = f_skill_get_self_skill_l()

Skill_mgr = oo.class(nil, "Skill_mgr")

function Skill_mgr:__init()
	self.skill_pool = g_skill_pool       		 --技能池
	self:initialize()
end

function Skill_mgr:initialize()
	--human自身技能
	local t = {101,199}
	for i=t[1],t[2] do
		local id_str = string.format("SKILL_OBJ_%d", i)
		local cl_str = string.format("Skill_%d", i)
		if _G[id_str] ~= nil and _G[cl_str] ~= nil and i%100 ~= 0 then
			self.skill_pool[_G[id_str]] = _G[cl_str]()
		end
	end
	--pet自身技能
	local t = {201,220}
	for i=t[1],t[2] do
		local id_str = string.format("SKILL_OBJ_%d", i)
		local cl_str = string.format("Skill_%d", i)
		if _G[id_str] ~= nil and _G[cl_str] ~= nil and i%100 ~= 0 then
			self.skill_pool[_G[id_str]] = _G[cl_str]()
		end
	end

	--基本技能回城
	local t = {91001}
	for _,v in pairs(t) do
		local id_str = string.format("SKILL_OBJ_%d", v)
		local cl_str = string.format("Skill_%d", v)
		if _G[id_str] ~= nil and _G[cl_str] ~= nil then
			self.skill_pool[_G[id_str]] = _G[cl_str]()
		end
	end

	local t = {90001, 90101, 90201, 90301, 90401}
	for _,v in pairs(t) do
		local id_str = string.format("SKILL_OBJ_%d", v)
		local cl_str = string.format("Skill_%d", v)
		if _G[id_str] ~= nil and _G[cl_str] ~= nil then
			self.skill_pool[_G[id_str]] = _G[cl_str]()
		end
	end

	--人物技能
	local t = {
	{110000, 118500}, 
	{210100, 218500}, 
	{310000, 318500},
	{410000, 418500},
	{510000, 518600},
	{990100, 990500},	--通用战斗技能
	}
	for k,v in pairs(t) do
		for i=v[1],v[2] do
			local id_str = string.format("SKILL_OBJ_%d", i)
			local cl_str = string.format("Skill_%d", i)
			if _G[id_str] ~= nil and _G[cl_str] ~= nil and i%100 ~= 0 then
				self.skill_pool[_G[id_str]] = _G[cl_str]()
			end
		end
	end

	-- 生活技能
	local t = {
	{600000, 600020}, 
	}
	for k,v in pairs(t) do
		for i=v[1],v[2] do
			local id_str = string.format("SKILL_OBJ_%d", i)
			local cl_str = string.format("Skill_%d", i)
			if _G[id_str] ~= nil and _G[cl_str] ~= nil and i%100 ~= 0 then
				self.skill_pool[_G[id_str]] = _G[cl_str]()
			end
		end
	end

	--怪物技能
	local t = {{1000000, 1000020},
	{1000100, 1000120},
	{1001100, 1001120},
	{1002100, 1002140},
	{1002200, 1002220},
	{1002300, 1002360},
	{1002400, 1002420},
	{1002500, 1002520},
	{1002600, 1002620},
	{1002700, 1002720},
	{1002800, 1002820},
	{1002900, 1002920},
	{1003000, 1003020},
	{1003100, 1003120},
	{1003200, 1003220},	
	{1003300, 1003320},	
	{1003400, 1003420},
	{1003500, 1003520},
	{1003600, 1003620},
	{1003700, 1003720},
	{1003800, 1003820},
	{1003900, 1003920},
	{1004000, 1004020},
	{1004100, 1004120},
	{1004200, 1004220},
	{1004300, 1004320},
	{1004400, 1004420},
	{1004500, 1004520},
	{1004600, 1004620},
	{1004700, 1004720},
	{1004800, 1004820},
	{1100100, 1100110}, -- TD守卫近身群体攻击
	{1100200, 1100210}, -- TD守卫远程群体攻击
	{1100300, 1100310}, -- TD守卫嘲讽
	{1100400, 1100410}, -- TD守卫佛光普照
	}
	for k,v in pairs(t) do
		for i=v[1],v[2] do
			local id_str = string.format("SKILL_OBJ_%d", i)
			local cl_str = string.format("Skill_%d", i)
			if _G[id_str] ~= nil and _G[cl_str] ~= nil and i%100 ~= 0 then
				self.skill_pool[_G[id_str]] = _G[cl_str]()
			end	
		end
	end

	--宠物技能
	self:build_pet_combat_skill()
	self:build_pet_passive_skill()
	self:build_pet_transfer_skill()
	self:build_pet_trigger_skill()

	--人物通用被动技能
	self:build_passive_common_skill()
	--法宝技能
	self:build_magic_skill()
	--宠物附体技能
	self:build_appendage_skill()
end

function Skill_mgr:build_pet_combat_skill()
	local skill_name_format = "Skill_%d"
	local skill_param = pet_sk_config.skill_param
	for skill_type, skill_params in pairs(skill_param) do
		for level, params in pairs(skill_params) do
			local skill_name = string.format(skill_name_format, skill_type + level)
			self.skill_pool[skill_type + level] = _G[skill_name]
		end
	end
end

function Skill_mgr:build_pet_passive_skill()
	local skill_name_format = "Skill_%d"
	local skill_param = pet_sk_passive.skill_passive_param
	for skill_type, skill_params in pairs(skill_param) do
		for level, params in pairs(skill_params) do
			local skill_name = string.format(skill_name_format, skill_type + level)
			self.skill_pool[skill_type + level] = _G[skill_name]
		end
	end
end

function Skill_mgr:build_pet_transfer_skill()
	local skill_name_format = "Skill_%d"
	local _skill_param = pet_sk_passive.skill_transfer_param
	for skill_type, skill_params in pairs(_skill_param) do
		for level, params in pairs(skill_params) do
			local skill_name = string.format(skill_name_format, level)
			self.skill_pool[skill_type + level%100] = _G[skill_name]
		end
	end
end

function Skill_mgr:build_pet_trigger_skill()
	local skill_name_format = "Skill_%d"
	local _skill_param = pet_sk_trigger.skill_trigger_config
	for skill_type, skill_params in pairs(_skill_param) do
		for level, params in pairs(skill_params) do
			local skill_name = string.format(skill_name_format, skill_type + level)
			self.skill_pool[skill_type + level] = _G[skill_name]
		end
	end
end
--function Skill_mgr:initialize_pet_skill()
	----宠物技能
	--local t = {2000001, 2000101, 2000201, 2000301}
	--for _,v in pairs(t) do
		--local id_str = string.format("SKILL_OBJ_%d", v)
		--local cl_str = string.format("Skill_%d", v)
		--if _G[id_str] ~= nil and _G[cl_str] ~= nil then
			--self.skill_pool[_G[id_str]] = _G[cl_str]
		--end
	--end
--

	----local t = {
		----{2100000, 2101100}
	----}
	----for k,v in pairs(t) do
		----for i=v[1],v[2] do
			----local id_str = string.format("SKILL_OBJ_%d", i)
			----local cl_str = string.format("Skill_%d", i)
			----if _G[id_str] ~= nil and _G[cl_str] ~= nil and i%100 ~= 0 then
				----self.skill_pool[_G[id_str]] = _G[cl_str]
			----end
		----end
	----end
--end

-- 通用被动技能
function Skill_mgr:build_passive_common_skill()
	local t = {{100100, 109900}}	-- 通用被动技能id范围

	for k,v in pairs(t) do
		for i=v[1],v[2] do
			local id_str = string.format("SKILL_OBJ_%d", i)
			local cl_str = string.format("Skill_%d", i)
			if _G[id_str] ~= nil and _G[cl_str] ~= nil and i%100 ~= 0 then
				self.skill_pool[_G[id_str]] = _G[cl_str]
			end
		end
	end
end

--法宝技能
function Skill_mgr:build_magic_skill()
	local t = {{SKILL_MAGIC_BEGIN, SKILL_MAGIC_END}	}	-- 法宝技能技能id范围

	for k,v in pairs(t) do
		for i=v[1],v[2] do
			local id_str = string.format("SKILL_OBJ_%d", i)
			local cl_str = string.format("Skill_%d", i)
			if _G[id_str] ~= nil and _G[cl_str] ~= nil and i%100 ~= 0 then
				self.skill_pool[_G[id_str]] = _G[cl_str]
			end
		end
	end
end

--宠物附体技能
function Skill_mgr:build_appendage_skill()
	local t = {{SKILL_APPENDAGE_BEGIN, SKILL_APPENDAGE_END}	}	-- 宠物附体技能技能id范围

	for k,v in pairs(t) do
		for i=v[1],v[2] do
			local id_str = string.format("SKILL_OBJ_%d", i)
			local cl_str = string.format("Skill_%d", i)
			if _G[id_str] ~= nil and _G[cl_str] ~= nil and i%100 ~= 0 then
				self.skill_pool[_G[id_str]] = _G[cl_str]
			end
		end
	end
end

function Skill_mgr:get_skill(skill_id)
	return self.skill_pool[skill_id]
end
function Skill_mgr:get_skill_type(skill_id)
	if skill_id and self.skill_pool[skill_id] then
		return self.skill_pool[skill_id]:get_type()
	end
end

--[[function Skill_mgr:create_skill(skill_id)
	return self.skill_pool[skill_id]
end]]
function Skill_mgr:create_cd(skill_id, obj_id)
	local ski_o = self.skill_pool[skill_id]
	--if ski_o == nil then print("ski_o is nil", skill_id) end
	local cd = Cd_time(skill_id, obj_id, ski_o:get_cd())
	return cd
end

local _occ_skill = {           --不同职业对应不同基本攻击
[OCC_WUZHE]=SKILL_OBJ_90001,
[OCC_MOXIU]=SKILL_OBJ_90101,
[OCC_JIANXIU]=SKILL_OBJ_90201,
[OCC_SHUSHI]=SKILL_OBJ_90301,
[OCC_JISI]=SKILL_OBJ_90401,
}

local _occ_list = {} 			--不同职业所有自身技能列表

function Skill_mgr:get_self_skill(occ)
	if _occ_list[occ] ~= nil then
		return _occ_list[occ]
	end

	local ski_l = {}
	if occ > OCC_JISI then
		local _self_skill_l = f_skill_get_self_skill_l(OBJ_TYPE_PET)
		table.copy(_self_skill_l, ski_l)
	else
		local _self_skill_l = f_skill_get_self_skill_l(OBJ_TYPE_HUMAN)
		table.copy(_self_skill_l, ski_l)
		ski_l[ _occ_skill[occ] ] = 1
		ski_l[SKILL_OBJ_91001] = 1
	end
	_occ_list[occ] = ski_l

	return ski_l
end


--获取前置技能id
function Skill_mgr:prefix_skill(skill_id)
	if skill_id >= SKILL_HUMAN_COMBAT_BEGIN and skill_id <= SKILL_HUMAN_COMBAT_END then   --战斗技能
		local d = tonumber(string.sub(skill_id, -2))
		if d > 1 then
			return skill_id - 1
		end
	end
end

--获取职业基本物理攻击
function Skill_mgr:get_base_attack_skill(occ)
	--return _occ_skill[occ]
	local skill_o = self:get_skill(_occ_skill[occ])
	return skill_o:get_cmd_id()
end
