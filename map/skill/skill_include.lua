

--**********接口函数*************
require("config.skill_cmd")
local _sk_class = require("skill.skill_class")
local _sk_config = require("config.skill_combat_config")
local _sk_config_passive = require("config.skill_passive_config")
local _sk_config_self = require("config.skill_self_config")
local _sk_magic_config = require("config.skill_magic_config")

--自身技能列表
local _self_skill_l = create_local("skill_include._self_skill_l", {})
_self_skill_l.value[OBJ_TYPE_HUMAN] = create_local("skill_include._self_skill_l.OBJ_TYPE_HUMAN", {})
_self_skill_l.value[OBJ_TYPE_PET] = create_local("skill_include._self_skill_l.OBJ_TYPE_PET", {})

--基本技能
local base_skill_l = {
	[SKILL_OBJ_90000] = true,
	[SKILL_OBJ_90001] = true,       --基本攻击
	[SKILL_OBJ_90100] = true,			
	[SKILL_OBJ_90101] = true,
	[SKILL_OBJ_90200] = true,			
	[SKILL_OBJ_90201] = true,
	[SKILL_OBJ_90300] = true,			
	[SKILL_OBJ_90301] = true,
	[SKILL_OBJ_90400] = true,			
	[SKILL_OBJ_90401] = true,     
	[SKILL_OBJ_91000] = true,			--回城技能
	[SKILL_OBJ_91001] = true,
}
--基本技能对应职业
local _base_occ_skill = {           --不同职业对应不同基本攻击
[OCC_WUZHE]	={[SKILL_OBJ_90000] = 1, [SKILL_OBJ_90001] = 1, [SKILL_OBJ_91000] = 1, [SKILL_OBJ_91001] = 1},
[OCC_MOXIU]	={[SKILL_OBJ_90100] = 1, [SKILL_OBJ_90101] = 1, [SKILL_OBJ_91000] = 1, [SKILL_OBJ_91001] = 1},
[OCC_JIANXIU]={[SKILL_OBJ_90200]= 1, [SKILL_OBJ_90201] = 1, [SKILL_OBJ_91000] = 1, [SKILL_OBJ_91001] = 1},
[OCC_SHUSHI]={[SKILL_OBJ_90300] = 1, [SKILL_OBJ_90301] = 1, [SKILL_OBJ_91000] = 1, [SKILL_OBJ_91001] = 1},
[OCC_JISI]  ={[SKILL_OBJ_90400] = 1, [SKILL_OBJ_90401] = 1, [SKILL_OBJ_91000] = 1, [SKILL_OBJ_91001] = 1},
}

--是否自身技能
function f_is_self_skill(skill_id)
	return _self_skill_l.value[OBJ_TYPE_HUMAN].value[skill_id] or _self_skill_l.value[OBJ_TYPE_PET].value[skill_id]
end

--是否吸血影响的单体伤害技能
function f_is_leech_skill(skill_id)
	return _sk_class._single_dg[skill_id] ~= nil
end
--是否隐身技能
function f_is_latent_skill(skill_id)
	return _sk_class._latent[skill_id] ~= nil
end
--是否被动技能
function f_is_passive_skill(skill_cmd)
	return _sk_class._passive[skill_cmd] ~= nil
end

--是否通用战斗技能
function f_is_common_combat_skill(skill_cmd)
	return _sk_class._common_combat[skill_cmd] ~= nil
end

--是否法宝技能
function f_is_magic_skill(skill_cmd)
	return _sk_class._magic[skill_cmd] ~= nil
end

--是否宠物附体技能
function f_is_appendage_skill(skill_cmd)
	return _sk_class._appendage[skill_cmd] ~= nil
end

--是否进阶后的技能
function f_is_advanced_skill(skill_cmd)
	return _sk_class._advanced[skill_cmd] ~= nil
end

--是否可以附加技能等级
function f_is_append_level(skill_cmd)
	if f_is_self_skill(skill_cmd) then return false end
	if f_is_passive_skill(skill_cmd) then return false end
	return not _sk_class._not_append_level[skill_cmd]
end

--是否基本技能
function f_is_base_skill(skill_id)
	return base_skill_l[skill_id]
end

--是否该职业才应该有的技能
function f_is_the_occ_skill(occ, skill_id)
	if f_is_passive_skill(skill_id) then
		return true
	elseif skill_id < SKILL_HUMAN_COMBAT_BEGIN or skill_id > SKILL_HUMAN_COMBAT_END then
		return true
	elseif f_is_base_skill(skill_id) then
		if _base_occ_skill[occ] and _base_occ_skill[occ][skill_id] then
			return true
		else
			return false
		end
	else
		local skill_occ = math.floor(skill_id / 10000)
		if skill_occ == occ then
			return true
		end
	end
	return false
end

--是否该职业才应该有的战斗技能
function f_is_the_occ_combat_skill(occ, skill_id)
	if skill_id < SKILL_HUMAN_COMBAT_BEGIN or skill_id > SKILL_HUMAN_COMBAT_END then
		return false
	elseif f_is_base_skill(skill_id) then
		return false
	else
		local skill_occ = math.floor(skill_id / 10000)
		if skill_occ == occ then
			return true
		end
	end
	return false
end

--获取公共cd的id
function f_skill_common_cd(skill_id)
	return _sk_class._cd[skill_id]
end

--创建战斗技能类
function f_create_skill_class(cmd_r, cls_r)
	local _sk_param = _sk_config._skill_p
	local ty = _G[string.format(cmd_r, 0)]
	local cls = _G[string.format(cls_r, 0)]
	for i=1,50 do
		local cmd = _G[string.format(cmd_r, i)]
		if _sk_param[ty][i] == nil or cmd == nil then break end
		local str = string.format(cls_r, i)

		_G[str] = oo.class(cls, str)
		_G[str].__init = function (self)
			cls.__init(self, cmd, i)
		end
	end
end

--创建被动技能类
function f_create_passive_skill_class(cmd_r, cls_r, base_cls)
	local _sk_param = _sk_config_passive._skill_p
	local ty = _G[string.format(cmd_r, 0)]
	if ty == nil then return end

	for i=1,20 do
		local cmd = _G[string.format(cmd_r, i)]
		if _sk_param[ty][i] == nil or cmd == nil then break end

		local str = string.format(cls_r, i)
		_G[str] = oo.class(base_cls, str)
		_G[str].__init = function (self)
			base_cls.__init(self, cmd, ty, i)
		end
	end
end


--创建自身技能类
function f_create_self_skill_class(cmd_r, cls_r, obj_type)
	local _sk_param = _sk_config_self._skill
	for i=1,99 do
		local cmd = _G[string.format(cmd_r, i)]
		local str = string.format(cls_r, i)
		if _sk_param[cmd] ~= nil then
			_self_skill_l.value[obj_type].value[cmd] = 1
			_G[str] = oo.class(Skill_self, str)
			_G[str].__init = function (self)
				Skill_self.__init(self, cmd)
			end
		end
	end
end

--创建生活技能类
--生活技能通用参数配置放在skill_self_config.lua里
function f_create_life_skill_class(cmd_r, cls_r)
	local _sk_param = _sk_config_self._skill
	local ty = _G[string.format(cmd_r, 0)]
	local cls = _G[string.format(cls_r, 0)]
	for i=1,50 do
		local skill_id = _G[string.format(cmd_r, i)]
		if _sk_param[skill_id] == nil or skill_id == nil then break end
		local str = string.format(cls_r, i)

		_G[str] = oo.class(cls, str)
		_G[str].__init = function (self)
			cls.__init(self, skill_id, i)
		end
	end
end

--怪物创建技能类
function f_create_monster_skill_class(cmd_r, cls_r)
	local _sk_param = _sk_config._skill_p
	local cls = _G[string.format(cls_r, 0)]
	local ty = _G[string.format(cmd_r, 0)]
	for i=1,60 do
		local str = string.format(cls_r, i)
		local str_cmd = string.format(cmd_r, i)
		local cmd = _G[str_cmd]
		--print("%%%%%%%%Skill_1002100", str, str_cmd, cmd, ty)
		if _sk_param[ty][i] == nil or cmd == nil then 
			--print("=>ty:", ty, "i:", i, "str_cmd:", str_cmd)
			break 
		end

		_G[str] = oo.class(cls, str)
		_G[str].__init = function (self)
			cls.__init(self, cmd, i)
		end
	end
end

function f_skill_get_self_skill_l(obj_type)
	return _self_skill_l.value[obj_type].value
end


require("config.skill_config")
require("skill.skill")
require("skill.cd_time")
--require("skill/skill_object")

--self skill
require("skill.self_skill.stuff_skill")

--human skill
require("skill.combat_skill.base_skill")
require("skill.passive_skill.passive_base_skill")

require("skill.combat_skill.pojun.skill_110000")
require("skill.combat_skill.pojun.skill_110100")
require("skill.combat_skill.pojun.skill_110200")
require("skill.combat_skill.pojun.skill_110300")
--require("skill/combat_skill/pojun/skill_110400")
--require("skill/combat_skill/pojun/skill_110500")
require("skill.combat_skill.pojun.skill_110600")
require("skill.combat_skill.pojun.skill_110700")
require("skill.combat_skill.pojun.skill_110800")
require("skill.combat_skill.pojun.skill_115100")
require("skill.combat_skill.pojun.skill_115200")
require("skill.combat_skill.pojun.skill_115300")
require("skill.combat_skill.pojun.skill_115400")

require("skill.combat_skill.qisha.skill_210100")
require("skill.combat_skill.qisha.skill_210200")
require("skill.combat_skill.qisha.skill_211000")
require("skill.combat_skill.qisha.skill_211300")
require("skill.combat_skill.qisha.skill_211400")
require("skill.combat_skill.qisha.skill_211600")
require("skill.combat_skill.qisha.skill_211700")
require("skill.combat_skill.qisha.skill_211800")
require("skill.combat_skill.qisha.skill_211900")


require("skill.combat_skill.jianling.skill_310000")
require("skill.combat_skill.jianling.skill_310100")
require("skill.combat_skill.jianling.skill_310200")
require("skill.combat_skill.jianling.skill_311100")
require("skill.combat_skill.jianling.skill_311200")
require("skill.combat_skill.jianling.skill_311300")
require("skill.combat_skill.jianling.skill_312100")
require("skill.combat_skill.jianling.skill_313100")


require("skill.combat_skill.tianshang.skill_410000")
require("skill.combat_skill.tianshang.skill_410100")
--require("skill/combat_skill/tianshang/skill_410200")
--require("skill/combat_skill/tianshang/skill_410300")
require("skill.combat_skill.tianshang.skill_411100")
require("skill.combat_skill.tianshang.skill_411200")
require("skill.combat_skill.tianshang.skill_412100")
require("skill.combat_skill.tianshang.skill_412200")
require("skill.combat_skill.tianshang.skill_412300")
require("skill.combat_skill.tianshang.skill_415100")
require("skill.combat_skill.tianshang.skill_415200")
require("skill.combat_skill.tianshang.skill_415300")
require("skill.combat_skill.tianshang.skill_415400")

require("skill.combat_skill.lingxing.skill_510000")
require("skill.combat_skill.lingxing.skill_510200")
require("skill.combat_skill.lingxing.skill_510300")
--require("skill/combat_skill/lingxing/skill_510400")
require("skill.combat_skill.lingxing.skill_511100")
--require("skill/combat_skill/lingxing/skill_511200")
--require("skill/combat_skill/lingxing/skill_511300")
--require("skill/combat_skill/lingxing/skill_512100")
--require("skill/combat_skill/lingxing/skill_512200")
require("skill.combat_skill.lingxing.skill_513100")
require("skill.combat_skill.lingxing.skill_513200")
--require("skill/combat_skill/lingxing/skill_513300")
--require("skill/combat_skill/lingxing/skill_513400")
require("skill.combat_skill.lingxing.skill_513500")
require("skill.combat_skill.lingxing.skill_513600")
require("skill.combat_skill.lingxing.skill_513700")
require("skill.combat_skill.lingxing.skill_515100")
require("skill.combat_skill.lingxing.skill_515200")
require("skill.combat_skill.lingxing.skill_515300")
require("skill.combat_skill.lingxing.skill_515400")

--life skill
require("skill.life_skill.skill_600000")

-- 通常战斗技能
require("skill.combat_skill.common.skill_990100")
require("skill.combat_skill.common.skill_990200")
require("skill.combat_skill.common.skill_990300")
require("skill.combat_skill.common.skill_990400")

--法宝技能
require("skill.magic_skill.magic_base_skill")
require("skill.magic_skill.skill_magic_damage_add")
require("skill.magic_skill.skill_magic_damage_sub")
require("skill.magic_skill.skill_magic_attack")
require("skill.magic_skill.skill_magic_be_attack")
require("skill.magic_skill.skill_magic_use")
require("skill.magic_skill.skill_magic_team")

--宠物附体技能
require("skill.pet_appendage_skill.pet_appendage_skill")
require("skill.pet_appendage_skill.skill_appendage_attack")

--monster
require("skill.combat_skill.monster.skill_1000000")
require("skill.combat_skill.monster.skill_1000100")
require("skill.combat_skill.monster.skill_1001100")
require("skill.combat_skill.monster.skill_1002100")
require("skill.combat_skill.monster.skill_1002200")
require("skill.combat_skill.monster.skill_1002300")
require("skill.combat_skill.monster.skill_1002400")
require("skill.combat_skill.monster.skill_1002500")
require("skill.combat_skill.monster.skill_1002600")
require("skill.combat_skill.monster.skill_1002700")
require("skill.combat_skill.monster.skill_1002800")
require("skill.combat_skill.monster.skill_1002900")
require("skill.combat_skill.monster.skill_1003000")
require("skill.combat_skill.monster.skill_1003100")
require("skill.combat_skill.monster.skill_1003200")
require("skill.combat_skill.monster.skill_1003300")
require("skill.combat_skill.monster.skill_1003400")
require("skill.combat_skill.monster.skill_1003500")
require("skill.combat_skill.monster.skill_1003600")
require("skill.combat_skill.monster.skill_1003700")
require("skill.combat_skill.monster.skill_1003800")
require("skill.combat_skill.monster.skill_1003900")
require("skill.combat_skill.monster.skill_1004000")
require("skill.combat_skill.monster.skill_1004100")
require("skill.combat_skill.monster.skill_1004200")
require("skill.combat_skill.monster.skill_1004300")
require("skill.combat_skill.monster.skill_1004400")
require("skill.combat_skill.monster.skill_1004500")
require("skill.combat_skill.monster.skill_1004600")
require("skill.combat_skill.monster.skill_1004700")
require("skill.combat_skill.monster.skill_1004800")

--pet
--require("config/pet_skill_passive_config")
require("skill.passive_skill.pet.pet_passive_skill")
require("skill.passive_skill.pet.pet_transfer_skill")
require("skill.passive_skill.pet.pet_trigger_skill")
--require("skill/combat_skill/pet/skill_2000000")
require("skill.combat_skill.pet.pet_combat_skill")

require("skill.skill_container")
require("skill.skill_container_pet")
require("skill.skill_container_monster")
require("skill.skill_mgr")
require("skill.skill_process")

--TD守卫技能
require("skill.combat_skill.guard.skill_1100100")
require("skill.combat_skill.guard.skill_1100200")
require("skill.combat_skill.guard.skill_1100300")
require("skill.combat_skill.guard.skill_1100400")


