

module("skill.skill_class", package.seeall)

--************技能归类**********



--吸血影响的单体伤害技能
local _single_l = {"SKILL_OBJ_900%02d", "SKILL_OBJ_2101%02d"}

_single_dg = {}
for _,v in pairs(_single_l) do
	local i = 1
	while true do
		local str = string.format(v, i)
		i = i + 1
		if _G[str] == nil then break end
		_single_dg[_G[str]] = 1
	end
end

--隐身技能
local latent_l = {"SKILL_OBJ_2118%02d"}

_latent = {}
for _,v in pairs(latent_l) do
	local i = 1
	while true do
		local str = string.format(v, i)
		i = i + 1
		if _G[str] == nil then break end
		_latent[_G[str]] = 1
	end
end


--被动技能
local sk_l = {"SKILL_OBJ_1180%02d","SKILL_OBJ_1181%02d","SKILL_OBJ_1182%02d","SKILL_OBJ_1183%02d","SKILL_OBJ_1184%02d",
"SKILL_OBJ_2180%02d","SKILL_OBJ_2181%02d","SKILL_OBJ_2182%02d","SKILL_OBJ_2183%02d","SKILL_OBJ_2184%02d",
"SKILL_OBJ_3180%02d","SKILL_OBJ_3181%02d","SKILL_OBJ_3182%02d","SKILL_OBJ_3183%02d","SKILL_OBJ_3184%02d",
"SKILL_OBJ_4180%02d","SKILL_OBJ_4181%02d","SKILL_OBJ_4182%02d","SKILL_OBJ_4183%02d","SKILL_OBJ_4184%02d",
"SKILL_OBJ_5182%02d","SKILL_OBJ_5183%02d","SKILL_OBJ_5185%02d",}

_passive = {}
for _,sk in pairs(sk_l) do
	local str = string.format(sk, 0)
	if _G[str] ~= nil then
		_passive[_G[str]] = 1
	end
end

--通用被动技能
for i = 1, 30 do
	for j = 0, SKILL_PASSIVE_COMMON_MAX do
		local str = string.format("SKILL_OBJ_10%02d%02d", i, j)
		if _G[str] ~= nil then
			_passive[_G[str]] = 1
			--print("_passive_skill:str", str, "id", _G[str])
		end
	end
end

_common_combat = {}
--通用战斗技能
for i = 1, 20 do
	for j = 0, SKILL_COMBAT_COMMON_MAX do
		local str = string.format("SKILL_OBJ_99%02d%02d", i, j)
		if _G[str] ~= nil then
			_common_combat[_G[str]] = 1
			--print("_common_combat_skill:str", str, "id", _G[str])
		end
	end
end

_magic = {}
--法宝技能
for i = 1, 99 do
	for j = 0, SKILL_MAGIC_MAX do
		local str = string.format("SKILL_OBJ_87%02d%02d", i, j)
		local str2 = string.format("SKILL_OBJ_88%02d%02d", i, j)
		if _G[str] ~= nil then
			_magic[_G[str]] = 1
			--print("_magic_skill:str", str, "id", _G[str])
		end
		if _G[str2] ~= nil then
			_magic[_G[str2]] = 1
			--print("_magic_skill:str", str, "id", _G[str])
		end
	end
end

_appendage = {}
--宠物附体技能
for i = 1, 99 do
	for j = 0, SKILL_APPENDAGE_MAX do
		local str = string.format("SKILL_OBJ_77%02d%02d", i, j)
		if _G[str] ~= nil then
			_appendage[_G[str]] = 1
			--print("_magic_skill:str", str, "id", _G[str])
		end
	end
end

_advanced = {}
--进阶技能
local advanced_list = {115100, 115200, 115300, 115400,
						415100, 415200, 415300, 415400,
						515100, 515200, 515300, 515400}
for _, i in pairs(advanced_list) do
	for j = 0, SKILL_COMBAT_COMMON_MAX - 20 do
		local str = string.format("SKILL_OBJ_%06d", i+j)
		if _G[str] ~= nil then
			_advanced[_G[str]] = 1
			--print("_magic_skill:str", str, "id", _G[str])
		end
	end
end

--不能附加技能等级的战斗技能
_not_append_level = {}
_not_append_level[SKILL_OBJ_90000] = 1
_not_append_level[SKILL_OBJ_90100] = 1
_not_append_level[SKILL_OBJ_90200] = 1
_not_append_level[SKILL_OBJ_90300] = 1
_not_append_level[SKILL_OBJ_90400] = 1
_not_append_level[SKILL_OBJ_91000] = 1


--**********公共cd技能*************
local sk_l = {}
sk_l[1] = {}
sk_l[2] = {}

_cd = {}
for k,list in pairs(sk_l) do
	for _,sk in pairs(list) do
		local i = 1
		while true do
			local str = string.format(sk, i)
			i = i + 1
			if _G[str] == nil then break end
			_cd[_G[str]] = k
		end
	end
end




