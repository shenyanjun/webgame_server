local _sk_magic_config = require("config.skill_magic_config")
require("skill.magic_skill.magic_base_skill")
local _random = crypto.random


local function get_obj(char_id)
	return g_obj_mgr:get_obj(char_id)
end

--让队伍buff生效
f_deal_player_skill_magic_team = function (obj)
	--print("f_deal_player_skill_magic_team", obj:get_id())
	if obj == nil or 1 then
		return
	end
	local team_id = obj:get_team()
	local team_obj = g_team_mgr:get_team_obj(team_id)
	local member_l = {}
	if team_obj ~= nil then
		member_l = team_obj:get_team_l()
	else
		member_l[obj:get_id()] = 1
	end

	local skill_magic_team_o_l = {}

	for obj_id, _ in pairs(member_l) do
		local player = g_obj_mgr:get_obj(obj_id)
		if player ~= nil then
			local mk_con = player:get_magickey_con()
			local skill_t = mk_con:get_skill_l()
			for _, v in pairs(skill_t) do
				local skill_o = g_skill_mgr:get_skill(v.skill_id)
				if skill_o ~= nil and skill_o:get_type() == SKILL_MAGIC_TEAM then
					table.insert(skill_magic_team_o_l, skill_o)
				end
			end
		end
	end
	
	--test 
--[[
	local skill_table = {889101}
	for k, v in ipairs(skill_table) do
		local skill_o = g_skill_mgr:get_skill(v)
		table.insert(skill_magic_team_o_l, skill_o)
	end
]]
	for obj_id, _ in pairs(member_l) do
		local player = g_obj_mgr:get_obj(obj_id)
		if player ~= nil then
			local param = {}
			param.sour_id = obj_id
			param.obj_s = player
			local impact_con = player:get_impact_con()
			local _ = impact_con and impact_con:clear_team_buff()
			for _, skill_o in ipairs(skill_magic_team_o_l) do
				skill_o:on_effect(param)
			end
		end
	end
end

local function deal_player_add_team(obj, args, char_id)
	print("deal_player_add_team()", obj, j_e(args), char_id)
	f_deal_player_skill_magic_team(obj)
end

local function deal_player_del_team(obj, args, char_id)
	print("deal_player_del_team()", obj, j_e(args), char_id)
	local team_o = g_team_mgr:get_team_obj(args.team_id)
	if team_o ~= nil then
		local teamer_id = team_o:get_teamer_id()
		local teamer = g_obj_mgr:get_obj(teamer_id)
		if teamer ~= nil then
			f_deal_player_skill_magic_team(teamer)
		end
	end
	f_deal_player_skill_magic_team(obj)

end

--
--g_event_mgr:register_event(EVENT_SET.EVENT_ADD_TEAM, get_obj, deal_player_add_team)
--g_event_mgr:register_event(EVENT_SET.EVENT_DEL_TEAM, get_obj, deal_player_del_team)

--法宝七 2 小队防御光环150~1750(加物防，法防) {百分比，固定值}
Skill_889100 = oo.class(Skill_magic, "Skill_889100")

function Skill_889100:on_effect(param)
	--print("Skill_889100:on_effect()")
	--local obj_s = param.obj_s
	local entry = _sk_magic_config._skill_p[self.cmd_id][self.level]
	local sour_id =  param.sour_id
	local impact_o = Impact_4101(sour_id)
	impact_o:set_count(100000000)
	impact_o:effect({per = entry[1], val = entry[2]})
	
	return 0
end
f_skill_magic_team_builder(SKILL_OBJ_889100)

--法宝七 3 小队抗性光环200~2150(加冰，毒，雷抗) {百分比，固定值}
Skill_889200 = oo.class(Skill_magic, "Skill_889200")

function Skill_889200:on_effect(param)
	--print("Skill_889100:on_effect()")
	--local obj_s = param.obj_s
	local entry = _sk_magic_config._skill_p[self.cmd_id][self.level]
	local sour_id =  param.sour_id
	local impact_o = Impact_4103(sour_id)
	impact_o:set_count(100000000)
	impact_o:effect({per = entry[1], val = entry[2]})
	
	return 0
end
f_skill_magic_team_builder(SKILL_OBJ_889200)

--法宝七 4 小队伤害光环150~1750(加物攻，法攻) {百分比，固定值}
Skill_889300 = oo.class(Skill_magic, "Skill_889300")

function Skill_889300:on_effect(param)
	--print("Skill_889300:on_effect()")
	--local obj_s = param.obj_s
	local entry = _sk_magic_config._skill_p[self.cmd_id][self.level]
	local sour_id =  param.sour_id
	local impact_o = Impact_4102(sour_id)
	impact_o:set_count(100000000)
	impact_o:effect({per = entry[1], val = entry[2]})
	
	return 0
end
f_skill_magic_team_builder(SKILL_OBJ_889300)

--法宝七 5 小队光环提升1%~10%的根骨悟性体魄身法 {百分比，固定值}
Skill_889400 = oo.class(Skill_magic, "Skill_889400")

function Skill_889400:on_effect(param)
	--print("Skill_889400:on_effect()")
	--local obj_s = param.obj_s
	local entry = _sk_magic_config._skill_p[self.cmd_id][self.level]
	local sour_id =  param.sour_id
	local impact_o = Impact_4105(sour_id)
	impact_o:set_count(100000000)
	impact_o:effect({per = entry[1], val = entry[2]})
	
	return 0
end
f_skill_magic_team_builder(SKILL_OBJ_889400)

--法宝八 2 小队光环属性攻击增加150~750(加冰，毒，雷) {百分比，固定值}
Skill_889500 = oo.class(Skill_magic, "Skill_889500")

function Skill_889500:on_effect(param)
	--print("Skill_889500:on_effect()")
	--local obj_s = param.obj_s
	local entry = _sk_magic_config._skill_p[self.cmd_id][self.level]
	local sour_id =  param.sour_id
	local impact_o = Impact_4104(sour_id)
	impact_o:set_count(100000000)
	impact_o:effect({per = entry[1], val = entry[2]})
	
	return 0
end
f_skill_magic_team_builder(SKILL_OBJ_889500)