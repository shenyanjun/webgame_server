--local debug_print = print
local debug_print = function() end
local _sk_config = require("config.skill_config")
local _sk_passive_config = require("config.skill_passive_config")
local _sk_combat_config = require("config.skill_combat_config")


--获取可学技能id
--1玩家id 技能命令id
function f_skill_get_study(obj_id, skill_cmd)
	local obj = g_obj_mgr:get_obj(obj_id)
	if obj ~= nil and obj:get_type() == OBJ_TYPE_HUMAN then
		local skill_con = obj:get_skill_con()
		local sk_id = skill_con:find_study_skill(skill_cmd)
		local sk_o = g_skill_mgr:get_skill(sk_id)
		local sk_config = _sk_config._skill[sk_id]

		if sk_id ~= nil and sk_o ~= nil and sk_config ~= nil then
			local t = {}
			t.skill_id = sk_id
			t.level = sk_o:get_level()
			t.xp = sk_config[2]
			t.gold = sk_config[3]
			t.is_study = false
			if obj:get_level() >= sk_config[1] 
				and (sk_config[4] == nil or skill_con:get_skill(sk_config[4]) ~= nil) then
				t.is_study = true
			end
			return t
		end
	end
end

--学习技能
function f_skill_study_skill(obj_id, skill_cmd, money_per)

	if f_is_passive_skill(skill_cmd) then
		return f_skill_study_passive_skill(obj_id, skill_cmd)
	--elseif f_is_common_combat_skill(skill_cmd) then
		--return f_skill_study_common_combat_skill(obj_id, skill_cmd, money_per or 0)
	else
		return f_skill_study_combat_skill(obj_id, skill_cmd, money_per or 0)
	end

end

--学习战斗技能
function f_skill_study_combat_skill(obj_id, skill_cmd, money_per)
	--print("MMMMMMMMMMMMMMMMMMMMM", skill_cmd)
	local obj = g_obj_mgr:get_obj(obj_id)
	if obj ~= nil and obj:get_type() == OBJ_TYPE_HUMAN then
		local skill_con = obj:get_skill_con()
		local sk_id,cmd_id = skill_con:find_study_skill(skill_cmd)
		local sk_o = g_skill_mgr:get_skill(sk_id)
		local sk_config = _sk_config._skill[sk_id]

		if sk_id ~= nil and sk_o ~= nil and sk_config ~= nil then
			if sk_id > cmd_id + SKILL_HUMAN_COMBAT_MAX_STUDY then
				return 21126
			end

			if obj:get_level() < sk_config[1] then
				return 21121
			end
			if sk_config[4] ~= nil and skill_con:get_skill(sk_config[4]) == nil then
				return 21122
			end

			--扣钱和经验
			--if obj:get_exp() < sk_config[2] then
				--return 21123
			--end
			if obj:get_sp() < sk_config[2] then
				return 21136
			end

			local pack_con = obj:get_pack_con()
			local money = pack_con:get_money()
			local need_money = sk_config[3] + math.floor(sk_config[3] * money_per)
			if money.gift_gold + money.gold < need_money then
				return 21128
			end
			if money.gift_gold > 0 and pack_con:check_money_lock(MoneyType.GIFT_GOLD) then				return -1			end
			if need_money <= money.gift_gold then
				pack_con:dec_money(MoneyType.GIFT_GOLD, need_money, {['type']=MONEY_SOURCE.STUDY_SKILL})
			else
				local left_money = need_money - money.gift_gold
				if left_money > 0 and pack_con:check_money_lock(MoneyType.GOLD) then					return -1				end
				pack_con:dec_money(MoneyType.GIFT_GOLD, money.gift_gold, {['type']=MONEY_SOURCE.STUDY_SKILL})
				pack_con:dec_money(MoneyType.GOLD, left_money, {['type']=MONEY_SOURCE.STUDY_SKILL})
			end

			--obj:del_exp(sk_config[2])
			obj:add_sp(-sk_config[2])

			local cd = g_skill_mgr:create_cd(sk_id, obj_id)
			skill_con:add_skill(sk_id, sk_o, cd)
			skill_con:serialize()

			return 0
		else
			print("Error f_skill_study_skill", obj_id, obj, obj and obj:get_type() or nil, skill_cmd)
			g_warning_log:write("Error f_skill_study_skill:" .. skill_cmd)
			return 21124
		end
	end
end

--学习被动技能
function f_skill_study_passive_skill(obj_id, skill_cmd)
	--print("MMMMMMMMMMMMMMMMM obj_id:", obj_id, "skill_cmd", skill_cmd)
	local obj = g_obj_mgr:get_obj(obj_id)
	if obj ~= nil and obj:get_type() == OBJ_TYPE_HUMAN then
		local skill_con = obj:get_skill_con()
		local sk_id,cmd_id = skill_con:find_study_skill(skill_cmd)
		local sk_o = g_skill_mgr:get_skill(sk_id)
		local sk_study_req = _sk_passive_config._skill_study_req[sk_id]

		--print("MMMMMMMMMMMMMMMMMMMMM", skill_cmd, sk_id, sk_o, sk_config)
		if sk_id ~= nil and sk_o ~= nil and sk_study_req ~= nil then
			if sk_id > cmd_id + SKILL_PASSIVE_COMMON_MAX then
				return 21126
			end
			-- 1依赖玩家等级
			if obj:get_level() < sk_study_req[1] then
				return 21121
			end
			-- 2依赖帮派等级
			local faction = g_faction_mgr:get_faction_by_cid(obj_id)
			if faction == nil or faction:get_level() < sk_study_req[2] then
				return 21127
			end
			-- 帮派未研究该技能
			local passive_skill_l = faction:get_action_practice()
			if sk_id % 100 > passive_skill_l[f_passive_skill_to_faction(cmd_id)] then
				return 21130
			end

			--3消耗经验
			local pack_con = obj:get_pack_con()
			if obj:get_exp() < sk_study_req[3] then
				return 21123
			end
			--4消耗铜币
			local money = pack_con:get_money()
			if money.gift_gold + money.gold < sk_study_req[4] then
				return 21128
			end
			--5消耗帮贡
			local contribution = faction:get_contribution(obj_id)
			if contribution < sk_study_req[5] then
				return 21129
			end
			if pack_con:check_money_lock(9) then	--检查帮贡是否已锁
				return -1
			end
			local s_pkt = {}
			s_pkt.param	= -sk_study_req[5]
			s_pkt.flag	= 6 --FACTION.contribution
			s_pkt.type  = 7
			g_faction_mgr:update_faction_level(obj_id, s_pkt)
			
			if money.gift_gold > 0 and pack_con:check_money_lock(MoneyType.GIFT_GOLD) then				return -1			end
			if sk_study_req[4] < money.gift_gold then
				pack_con:dec_money(MoneyType.GIFT_GOLD, sk_study_req[4], {['type']=MONEY_SOURCE.STUDY_SKILL})
			else
				local left_money = sk_study_req[4] - money.gift_gold
				if left_money > 0 and pack_con:check_money_lock(MoneyType.GIFT_GOLD) then					return -1				end
				pack_con:dec_money(MoneyType.GIFT_GOLD, money.gift_gold, {['type']=MONEY_SOURCE.STUDY_SKILL})
				pack_con:dec_money(MoneyType.GOLD, left_money, {['type']=MONEY_SOURCE.STUDY_SKILL})
			end

			obj:del_exp(sk_study_req[3])

			local cd = g_skill_mgr:create_cd(sk_id, obj_id)
			skill_con:add_skill(sk_id, sk_o, cd)
			skill_con:serialize()

			local _ = obj.on_update_attribute and obj:on_update_attribute(1)
			return 0
		else
			print("Error f_skill_study_skill", obj_id, obj, obj and obj:get_type() or nil, skill_cmd)
			g_warning_log:write("Error f_skill_study_skill:" .. skill_cmd)
			return 21124
		end
	end
end

--是否已经学习了该技能
function f_skill_is_study_complete(obj, skill_id)
	if obj ~= nil and obj:get_type() == OBJ_TYPE_HUMAN then
		local skill_con = obj:get_skill_con()
		local sk_id = skill_con:find_study_skill(skill_id)
		if sk_id > skill_id then
			return true
		end
	end
	return false
end

--是否学习了攻击技能，任务调用
function f_skill_is_study_combat(obj)
	if obj ~= nil and obj:get_type() == OBJ_TYPE_HUMAN then
		local skill_con = obj:get_skill_con()
		return skill_con:get_skill_count(OBJ_TYPE_HUMAN) > 2
	end
	return false
end

------技能书学习技能-----
--是否可学
function f_skill_book_is_study(obj, skill_id)
	--local obj = g_obj_mgr:get_obj(obj_id)
	if obj ~= nil and obj:get_type() == OBJ_TYPE_HUMAN then
		local skill_con = obj:get_skill_con()
		local sk_id = skill_con:find_study_skill(skill_id)
		if sk_id == skill_id then
			return 0
		end
		return 21125
	end
	return 20034
end

--技能书学习技能
function f_skill_book_study(obj, skill_id)
	--local obj = g_obj_mgr:get_obj(obj_id)
	if obj ~= nil and obj:get_type() == OBJ_TYPE_HUMAN then
		local skill_con = obj:get_skill_con()
		if skill_con:get_skill(skill_id) == nil then
			local sk_o = g_skill_mgr:get_skill(skill_id)
			local cd_o = g_skill_mgr:create_cd(skill_id, obj:get_id())
			if sk_o ~= nil and cd_o ~= nil then
				skill_con:add_skill(skill_id, sk_o, cd_o)
				skill_con:serialize()

				skill.skill_process.get_list(obj:get_id(), obj:get_id())
				return 0
			end
		end
		return 21125
	end
	return 20034
end

--某项法宝技能生效
function f_magic_skill_effect(char_id, skill_id)
	local skill_o = g_skill_mgr:get_skill(skill_id)
	if skill_o:get_type() == SKILL_MAGIC_ATTRIBUTE then
		skill_o:effect(char_id)
		return true
	elseif skill_o:get_type() == SKILL_MAGIC_TEAM then
		local obj = g_obj_mgr:get_obj(char_id)
		local _ = obj and f_deal_player_skill_magic_team(obj)
	end
	return false
end

--取消某项法宝技能
function f_magic_skill_ineffectiveness(char_id, skill_id)
	local skill_o = g_skill_mgr:get_skill(skill_id)
	if skill_o:get_type() == SKILL_MAGIC_ATTRIBUTE then
		skill_o:ineffectiveness(char_id)
		return true
	elseif skill_o:get_type() == SKILL_MAGIC_TEAM then
		local obj = g_obj_mgr:get_obj(char_id)
		local _ = obj and f_deal_player_skill_magic_team(obj)
	end
	return false
end


module("skill.skill_process", package.seeall)

local use_pkt = {}

get_list = function(char_id, obj_id)
	local obj = g_obj_mgr:get_obj(char_id)
	if obj ~= nil then
		local ty = Obj_mgr.obj_type(obj_id)
		if ty == OBJ_TYPE_HUMAN and obj_id == char_id and obj:is_enter_scene() then
			local skill_con = obj:get_skill_con()
			local new_pkt = {}
			new_pkt.list = skill_con:net_get_info()
			new_pkt.obj_id = obj_id
			-- 加入法宝技能
			local mk_con = obj:get_magickey_con()
			local sk_t = mk_con:get_skill_l()
			for k, v in pairs(sk_t) do
				local skill_o = g_skill_mgr:get_skill(v.skill_id)
				if skill_o ~= nil then
					table.insert(new_pkt.list, {skill_o.id, skill_o.cmd_id, 0, v.cd:get_cd_time(), skill_o.expend_mp})					
				end
			end
			-- 加入宠物附体技能
			local sk_appendage = obj.appendage_skill_list
			for k, v in pairs(sk_appendage) do
				local skill_o = g_skill_mgr:get_skill(v.skill_id)
				if skill_o ~= nil then
					table.insert(new_pkt.list, {skill_o.id, skill_o.cmd_id, 0, v.cd:get_cd_time(), skill_o.expend_mp})					
				end
			end
			--进阶后可加怒气值
			if obj:check_occ_levelup() ~= nil then
				local image_skill = _sk_combat_config._skill_advanced_occ[obj:get_occ()]
				for k, v in pairs(image_skill) do
					local src_skill_o = skill_con:get_skill_obj(k)
					if src_skill_o ~= nil then
						table.insert(new_pkt.list, {v + (src_skill_o.id % 100), v, 0, v.cd:get_cd_time(), skill_o.expend_mp})					
					end
				end
			end
			g_cltsock_mgr:send_client(char_id, CMD_MAP_GET_SKILL_LIST_S, new_pkt)
			--print("new_pkt", CMD_MAP_GET_SKILL_LIST_S, j_e(new_pkt))
		end
	end
end

--更新玩家技能列表
update_list = function(obj_id)
	get_list(obj_id, obj_id)
end

get_pet_list = function(char_id, obj_id)
	local obj = g_obj_mgr:get_obj(char_id)
	if obj ~= nil then
		local ty = Obj_mgr.obj_type(obj_id)
		if ty == OBJ_TYPE_PET then
			local pet_con = obj:get_pet_con()
			local pet_obj = pet_con:get_pet_obj(obj_id)
			if pet_obj ~= nil then
				local skill_con = pet_obj:get_skill_con()
				local new_pkt = {}
				new_pkt = skill_con:net_get_info()
				g_cltsock_mgr:send_client(char_id, CMD_MAP_PET_SKILL_INFO_S, new_pkt)
			end
		end
	end
end

--local test_count = nil
--local test_time = nil
use = function(char_id, skill_cmd, obj_id, param)
	local obj = g_obj_mgr:get_obj(obj_id)
	if obj ~= nil then
		--if test_time == nil then test_time = ev.now test_count = 0 end
		local ty = obj:get_type()
		if (ty == OBJ_TYPE_HUMAN or ty == OBJ_TYPE_GHOST ) and (obj_id == char_id or char_id == param.des_id ) and obj:is_enter_scene() and obj:is_alive() then
			local ret = 0
			local r_skill_cmd = nil
			if f_is_magic_skill(skill_cmd) then
				ret = use_magic_skill(char_id, skill_cmd, obj_id, param)
			else
				local skill_con = obj:get_skill_con()
				ret, r_skill_cmd = skill_con:use(skill_cmd, param)
			end
			--local new_pkt = {}
			use_pkt.skill_cmd = r_skill_cmd or skill_cmd
			use_pkt.result = ret
			use_pkt.obj_id = obj_id
			g_cltsock_mgr:send_client(char_id, CMD_MAP_USE_SKILL_S, use_pkt)
			
			--打坐外观更新
			g_meditation_mgr:del_container(char_id)
			
			--test_count = test_count + 1
			--if test_count%10 == 0 then
			---	local str = string.format("skill 总时间:%d, 次数:%d,平均:%d", ev.now-test_time, test_count, math.floor((ev.now-test_time)*1000000/test_count))
			--	print(str)
			--	test_count = nil
			--	test_time = nil
			--end	
		elseif ty == OBJ_TYPE_PET then 
			--local pet_con = obj:get_pet_con()
			--local pet_obj = pet_con:get_pet_obj(obj_id)
			--if pet_obj ~= nil the
				--local skill_con = pet_obj:get_skill_con()
				local skill_con = obj:get_skill_con()
				local ret = skill_con:use(skill_cmd, param)
				--local new_pkt = {}
				use_pkt.skill_cmd = skill_cmd
				use_pkt.result = ret
				use_pkt.obj_id = obj_id
				g_cltsock_mgr:send_client(char_id, CMD_MAP_USE_SKILL_S, use_pkt)
			--end
		end
	end
end

get_cd_time = function(char_id, obj_id, skill_id)
	local obj = g_obj_mgr:get_obj(char_id)
	if obj ~= nil then 
		local ty = Obj_mgr.obj_type(obj_id)
		if ty == OBJ_TYPE_HUMAN and obj_id == char_id and obj:is_enter_scene() and obj:is_alive() then
			local skill_con = obj:get_skill_con()
			local new_pkt = {}
			new_pkt.list = skill_con:net_get_cd_info()
			new_pkt.obj_id = obj_id
			g_cltsock_mgr:send_client(char_id, CMD_MAP_GET_CD_S, new_pkt)
		elseif ty == OBJ_TYPE_PET then
			local pet_con = obj:get_pet_con()
			local pet_obj = pet_con:get_pet_obj(obj_id)
			if pet_obj ~= nil then
				local skill_con = pet_obj:get_skill_con()

				local new_pkt = {}
				new_pkt.list = skill_con:net_get_cd_info()
				new_pkt.obj_id = obj_id
				g_cltsock_mgr:send_client(char_id, CMD_MAP_GET_CD_S, new_pkt)
			end
		end
	end
end

-- 使用法宝技能
use_magic_skill = function(char_id, skill_cmd, obj_id, param)
	local hm_o = g_obj_mgr:get_obj(char_id)
	local mk_con = hm_o and hm_o:get_magickey_con() 
	local skill_t = mk_con and mk_con:get_skill_l() or {}
	local skill_id = skill_t[skill_cmd] and skill_t[skill_cmd].skill_id
	local skill_o = g_skill_mgr:get_skill(skill_id)
	if skill_o == nil or skill_o:get_type() ~= SKILL_MAGIC_USE then
		return 21102
	end

	local cd = skill_t[skill_cmd].cd
	if cd and cd:get_status() then
		if not hm_o:is_use_skill(skill_cmd) then
			return 21114
		end

		local sub_mp_per, sub_mp_val = hm_o:get_passive_effect(EXTRA_SUB_MP, nil)
		local mp = math.max(skill_o:get_expend_mp() - skill_o:get_expend_mp() * sub_mp_per - sub_mp_val, 0)
		if mp > hm_o:get_mp() then 
			return 21115
		end

		param.obj_s = hm_o
		local ret = skill_o:effect(char_id, param)
		if ret == 0 then
			cd:use()
			--这里不需要减mp,会在skill_o:effect里扣除
			--local _ = mp > 0 and hm_o:add_mp(-mp)
		end
		return ret
	end
	return 21116
end

--接口函数
--[[function f_get_skill_func()
	return skill_func
end]]




