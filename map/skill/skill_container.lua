
local debug_print = function () end;
local _skill = require("config.skill_combat_config")
local _skill_config = require("config.skill_config")
local _skill_process = require("skill.skill_process")

local _fun_passive = 
	function (skill_cmd, skill_obj)
		if f_is_passive_skill(skill_cmd) then
			return true
		end
		if not skill_obj then
			return false
		end
		return skill_obj:get_type() == SKILL_PASSIVE
	end

local _cn_tm = 2

--角色技能实现类
Skill_container = oo.class(nil, "Skill_container")

function Skill_container:__init(obj_id)
	self.obj_id = obj_id  
	self.skill_obj_l = {}
	self.passive_obj_l = {}        --被动技能列表
end

function Skill_container:add_skill(skill_id, skill_obj, cd)
	local skill_cmd = skill_obj:get_cmd_id()      --human非战斗技能用skill_id表示
	--先清之前的被动技能
	if self.skill_obj_l[skill_cmd] and _fun_passive(self.skill_obj_l[skill_cmd]["skill_id"], nil) then
		local skill_o = g_skill_mgr:get_skill(self.skill_obj_l[skill_cmd]["skill_id"])
		skill_o:ineffectiveness(self.obj_id, {})
	end
	self.skill_obj_l[skill_cmd] = {}
	self.skill_obj_l[skill_cmd]["cd"] = cd
	self.skill_obj_l[skill_cmd]["skill_id"] = skill_id

	self:init_other(skill_cmd, skill_id)
	
	return 0
end

function Skill_container:del_skill(skill_cmd)
	if self.skill_obj_l[skill_cmd] == nil then
		return 0
	end

	if _fun_passive(self.skill_obj_l[skill_cmd]["skill_id"], nil) then
		local skill_o = g_skill_mgr:get_skill(self.skill_obj_l[skill_cmd]["skill_id"])
		skill_o:ineffectiveness(self.obj_id, {})
	end
	
	self.skill_obj_l[skill_cmd]["cd"] = nil
	self.skill_obj_l[skill_cmd] = nil

	return 0
end

function Skill_container:init_other(skill_cmd, skill_id)
	--是否被动技能
	if _fun_passive(skill_cmd, nil) then
		self.passive_obj_l[skill_cmd] = skill_id
		--被动技能初始化的时候即生效
		local skill_o = g_skill_mgr:get_skill(skill_id)
		skill_o:effect(self.obj_id, {})
	end
end

function Skill_container:get_skill_l()
	return self.skill_obj_l
end
function Skill_container:get_skill(skill_cmd)
	--local skill_o = g_skill_mgr:get_skill(skill_id)
	return self.skill_obj_l[skill_cmd]
end

--skill_cmd:技能类id
function Skill_container:get_skill_id(skill_cmd)
	return self.skill_obj_l[skill_cmd]["skill_id"]
end
function Skill_container:get_skill_cd(skill_cmd)
	--if self.skill_obj_l[skill_id] ~= nil then
		return self.skill_obj_l[skill_cmd]["cd"]
	--end
end

-- 返回技能对象
function Skill_container:get_skill_obj(skill_cmd)
	local hm_o = g_obj_mgr:get_obj(self.obj_id)
	local skill_id = self:get_skill_id(skill_cmd)

	local ap_lv = 0 
	if f_is_append_level(skill_cmd) then
		ap_lv = hm_o:get_equip_skill_level(skill_cmd)  --技能附加等级
	end
	local skill_o = g_skill_mgr:get_skill(skill_id + ap_lv)
end

--是否学习了该技能等级(用于自身技能判断)
function Skill_container:is_study_skill(skill_id)
	local skill_o = g_skill_mgr:get_skill(skill_id)
	return self.skill_obj_l[skill_o:get_cmd_id()] and true or false
end

--查找当前可学的技能id(skill_cmd为技能id)
function Skill_container:find_study_skill(skill_cmd)
	skill_cmd = string.format("SKILL_OBJ_%d", skill_cmd)
	local str = string.sub(skill_cmd, 1,string.len(skill_cmd)-2) .. "%02d"
	local cmd_id = _G[string.format(str, 0)]
	
	if self.skill_obj_l[cmd_id] ~= nil then
		return self:get_skill_id(cmd_id)+1,cmd_id   --返回下一级技能id
	else
		local sk_id = string.format(str, 1)
		return _G[sk_id],cmd_id
	end
end

--检测cd
function Skill_container:check_use(skill_cmd, param)
	local hm_o = g_obj_mgr:get_obj(self.obj_id)
	if skill_cmd == nil or self.skill_obj_l[skill_cmd] == nil or not f_is_the_occ_skill(hm_o:get_occ(), skill_cmd) then 
		print("error use skill =====>>", skill_cmd, hm_o:get_id())
		return 21111 
	end

	local skill_id = self:get_skill_id(skill_cmd)
	local cd = self:get_skill_cd(skill_cmd)
	local ap_lv = 0 
	if f_is_append_level(skill_cmd) then
		ap_lv = hm_o:get_equip_skill_level(skill_cmd)  --技能附加等级
	end
	local skill_o = g_skill_mgr:get_skill(skill_id + ap_lv)
	if cd and skill_o and cd:get_status() and hm_o ~= nil then
		if not hm_o:is_use_skill(skill_cmd) then
			return 21114
		end

		return 0
	end
	return 21116
end

--成功返回0，错误返回错误码
function Skill_container:use(skill_cmd, param)
	--print("Skill_container:use", skill_cmd, j_e(param))
	local hm_o = g_obj_mgr:get_obj(self.obj_id)
	if skill_cmd == nil or self.skill_obj_l[skill_cmd] == nil or not f_is_the_occ_skill(hm_o:get_occ(), skill_cmd) then 
		print("error use skill =====>>", skill_cmd, hm_o:get_id())
		return 21111 
	end

	if self.passive_obj_l[skill_cmd] then
		return 21112
	end

	-- 使用进阶技能
	if f_is_advanced_skill(skill_cmd) then
		return self:use_advanced(skill_cmd, param)
	end

	local skill_id = self:get_skill_id(skill_cmd)
	local cd = self:get_skill_cd(skill_cmd)
	local ap_lv = 0 
	if f_is_append_level(skill_cmd) then
		ap_lv = hm_o:get_equip_skill_level(skill_cmd)  --技能附加等级
	end
	local skill_o = g_skill_mgr:get_skill(skill_id + ap_lv)
	if cd and skill_o and cd:get_status() and hm_o ~= nil then
		if not hm_o:is_use_skill(skill_cmd) then
			return 21114
		end

		local sub_mp_per, sub_mp_val = hm_o:get_passive_effect(EXTRA_SUB_MP, nil)
		local mp = math.max(skill_o:get_expend_mp() - skill_o:get_expend_mp() * sub_mp_per - sub_mp_val, 0)
		if mp > hm_o:get_mp() then 
			return 21115
		end

		local ret = skill_o:effect(self.obj_id, param)
		if ret == 0 then
			cd:use()
			local _ = mp > 0 and hm_o:add_mp(-mp)

			if skill_o:get_type() == SKILL_BAD and Obj_mgr.obj_type(self.obj_id) == OBJ_TYPE_HUMAN then
				hm_o:set_combat(true)
			end
		end
		return ret
	end
	return 21116
end

--使用进阶技能 成功返回0，错误返回错误码
function Skill_container:use_advanced(skill_cmd, param)
	--print("Skill_container:use_advanced()", skill_cmd, Json.Encode(param))
	local hm_o = g_obj_mgr:get_obj(self.obj_id)
	local image_skill = _skill._skill_advanced_occ[hm_o:get_occ()][skill_cmd]
	if image_skill == nil or hm_o:check_occ_levelup() == nil then
		return 21114
	end
	local skill_id = self:get_skill_id(skill_cmd)
	local cd = self:get_skill_cd(skill_cmd)
	local ap_lv = 0 
	if f_is_append_level(skill_cmd) then
		ap_lv = hm_o:get_equip_skill_level(skill_cmd)  --技能附加等级
	end
	local skill_o = g_skill_mgr:get_skill(skill_id + ap_lv)
	if cd and skill_o and cd:get_status() and hm_o ~= nil then
		local image_skill_id = nil
		if not hm_o:is_use_skill(skill_cmd) then
			return 21114
		end

		local rage = skill_o:get_expend_rage()
		if rage > hm_o:get_rage_value() then 
			return 21117
		end
		
		local ret = 21114
		if hm_o:check_rage_status() then
			image_skill_id = image_skill + ((skill_id + ap_lv) % 100)
			local image_skill_o = g_skill_mgr:get_skill(image_skill_id)
			if image_skill_o ~= nil then
				ret = image_skill_o:effect(self.obj_id, param)
			end
		else
			ret = skill_o:effect(self.obj_id, param)
		end
		if ret == 0 then
			cd:use()
			local _ = rage > 0 and hm_o:sub_rage(rage)

			if skill_o:get_type() == SKILL_BAD then
				hm_o:set_combat(true)
			end
		end
		
		return ret, image_skill_id
	end
	return 21116
end

------------网络通信--------
function Skill_container:net_get_info()
	local list = {}
	local count = 1
	local obj = g_obj_mgr:get_obj(self.obj_id)
	for k,v in pairs(self.skill_obj_l) do
		--if _self_ski_l[k] == nil then           --自身技能对客户端透明
		--if f_is_the_occ_skill(obj:get_occ(), v.skill_id) then
			local skill_o = g_skill_mgr:get_skill(v.skill_id)
			local equip_skill_level = 0
			if f_is_append_level(k) then
				equip_skill_level = obj:get_equip_skill_level(k)
			end
			list[count] = {v.skill_id, k, equip_skill_level, v.cd:get_cd_time(),skill_o:get_expend_mp()}
			count = count + 1
		--end
		--end
	end
	return list
end

function Skill_container:net_get_cd_info(skill_cmd)
	local list = {}
	local count = 1
	if skill_cmd == nil then
		local obj = g_obj_mgr:get_obj(self.obj_id)
		for k,v in pairs(self.skill_obj_l) do
			local skill_type = g_skill_mgr:get_skill_type(v.skill_id)
			if skill_type ~= SKILL_PASSIVE and skill_type ~= SKILL_TRANSFER_ATTR and f_is_the_occ_skill(obj:get_occ(), v.skill_id) then
				list[count] = {v.skill_id, k, v.cd:get_last_time()}
				--[[list[count]["skill_id"] = v.skill_id
				list[count]["skill_cmd"] = k
				list[count]["time"] = v.cd:get_last_time()]]
				count = count + 1
			end
		end
	else
		local skill_id = self:get_skill_id(skill_cmd)
		local skill_type = g_skill_mgr:get_skill_type(skill_id)
		if skill_type ~= SKILL_PASSIVE and skill_type ~= SKILL_TRANSFER_ATTR then
			local cd = self:get_skill_cd(skill_cmd)
			if cd ~= nil then
				list[count] = {v.skill_id, k, v.cd:get_last_time()}
				--[[list[count]["skill_id"] = skill_id
				list[count]["skill_cmd"] = k
				list[count]["time"] = cd:get_last_time()]]
			end
		end
	end
	return list
end



----------持久化函数----------

function Skill_container:extract_skill_list_info(has_cd)
	local info = {}
	info.owner_id = self.obj_id
	
	local skill_l = {}
	local c = 0
	for k,v in pairs(self.skill_obj_l) do
		local skill_id = v.skill_id
		local cd
		if has_cd and not self.passive_obj_l[k] and v.cd:is_save() then
			cd = v.cd
		end

		if not f_is_self_skill(k) or cd ~= nil then
			c = c + 1
			skill_l[c] = {skill_id, k, cd}
		end
	end
	info.skill_list = skill_l
	
	return info
end

function Skill_container:serialize()
	local m_db = f_get_db()
	local query = string.format("{owner_id:%d}", self.obj_id)
	local info = self:extract_skill_list_info(true)
	m_db:update("skill", query, Json.Encode(info), true)
end
function Skill_container:unserialize()
	local m_db = f_get_db()
	local fields = Json.Encode({skill_list=1})
	local query = string.format("{owner_id:%d}", self.obj_id)
	local rows, e_code = m_db:select_one("skill", fields, query, nil, "{owner_id:1}")
	if rows ~= nil then
		for _,v in pairs(rows.skill_list or {}) do
			local skid = tonumber(v[1])
			local cmd_id = v[2]
			local item = v[3]
			
			local skill_o = g_skill_mgr:get_skill(skid)
			if skill_o ~= nil then
				self.skill_obj_l[cmd_id] = {}
				self.skill_obj_l[cmd_id]["skill_id"] = skid
				if item ~= nil then
					local cd_o = Cd_time(skid, self.obj_id, skill_o:get_cd())
					cd_o = cd_o:clone(item, skill_o:get_cd())
					self.skill_obj_l[cmd_id]["cd"] = cd_o
				else
					self.skill_obj_l[cmd_id]["cd"] = Cd_time(skid, self.obj_id, skill_o:get_cd())
				end
				self:init_other(cmd_id, skid)
			else
				print("warning:Skill_container:unserialize skill not exist:", skid)
			end
		end
	end
end

--被动技能初始化生成
function Skill_container:passive_init(char_id)
	for k,skid in pairs(self.passive_obj_l) do
		local skill_o = g_skill_mgr:get_skill(skid)
		skill_o:effect(char_id, {})
	end
end

--[[function Skill_container:get_passive_l()
	return self.passive_obj_l
end]]

function Skill_container:get_skill_count(type)				--获取技能数量，自身技能不算在内
	local self_skill_l = f_skill_get_self_skill_l(type)
	local skill_l =  self:get_skill_l()
	local count = 0
	for k, v in pairs(skill_l) do
		if not self_skill_l[k] then
			count = count + 1
		end
	end
	return count
end

function Skill_container:get_all_combat_skill() 
	local skill_l =  self:get_skill_l()
	local skill_l_r = {}
	local obj = g_obj_mgr:get_obj(self.obj_id)
	for k, v in pairs(skill_l) do
		if not f_is_passive_skill(k) and not f_is_self_skill(k) and not f_is_base_skill(k) and f_is_the_occ_skill(obj:get_occ(), v.skill_id) then
			skill_l_r[k] = v["skill_id"] % 100
		end
	end
	return skill_l_r
end

-- 返回当前职业，最高战斗技能id
function Skill_container:get_all_combat_skill_array() 
	local skill_l =  self:get_skill_l()
	local skill_l_r = {}
	local obj = g_obj_mgr:get_obj(self.obj_id)
	for k, v in pairs(skill_l) do
		if not f_is_passive_skill(k) and not f_is_self_skill(k) and not f_is_base_skill(k) and f_is_the_occ_skill(obj:get_occ(), v.skill_id) then
			local skill_id = v.skill_id
			local ap_lv = 0
			if f_is_append_level(k) then
				ap_lv = obj:get_equip_skill_level(k)  --技能附加等级
			end
			table.insert(skill_l_r, skill_id + ap_lv)
		end
	end
	return skill_l_r
end

-- 是否所选职业的技能是满学习状态
function Skill_container:is_full_combat_skill(occ) 
	--print("Skill_container:is_full_combat_skill()", occ)
	local skill_l =  self:get_skill_l()
	local skill_l_r = {}
	
	for k, v in pairs(skill_l) do
		if f_is_the_occ_combat_skill(occ, v.skill_id) then
			skill_l_r[k] = v.skill_id
		end
	end
	
	local obj = g_obj_mgr:get_obj(self.obj_id)
	local level = obj and obj:get_level()
	for s_cmd, v in pairs(_skill._skill_occ[occ]) do
		local had_skill_id = skill_l_r[s_cmd]
		if had_skill_id == nil then 
			return false 
		end
		if _skill_config._skill[had_skill_id] == nil or level == nil then
			print("error	is_full_combat_skill")
			return false
		end
		if _skill_config._skill[had_skill_id + 1][1] <= level then
			return false
		end
	end
	-- 进阶技能
	if obj:check_occ_levelup() ~= nil then
		for s_cmd, v in pairs(_skill._skill_advanced_occ[occ]) do
			local had_skill_id = skill_l_r[s_cmd]
			if had_skill_id == nil then 
				return false 
			end
			if _skill_config._skill[had_skill_id] == nil or level == nil then
				print("error	is_full_combat_skill")
				return false
			end
			if _skill_config._skill[had_skill_id + 1][1] <= level then
				return false
			end
		end
	end
	return true
end

-- 是否有其中一个职业的技能是满学习状态
function Skill_container:is_had_full_combat_skill() 
	local occ_l = {11, 41, 51}
	for k, v in ipairs(occ_l) do
		if self:is_full_combat_skill(v) then
			return true
		end
	end
	return false
end

-- 把所选职业的已学技能升级到满状态
function Skill_container:full_combat_skill(occ) 
	local skill_l =  self:get_skill_l()
	local skill_l_r = {}
	
	for k, v in pairs(skill_l) do
		if f_is_the_occ_combat_skill(occ, v.skill_id) then
			skill_l_r[k] = v.skill_id
		end
	end
	
	local obj = g_obj_mgr:get_obj(self.obj_id)
	local level = obj and obj:get_level()
	local need_serialize = false
	for s_cmd, skill_id in pairs(skill_l_r) do
		for i = skill_id, s_cmd + SKILL_HUMAN_COMBAT_MAX_STUDY do
			if _skill_config._skill[i + 1][1] > level then
				local cd = g_skill_mgr:create_cd(i, self.obj_id)
				local sk_o = g_skill_mgr:get_skill(i)
				if cd == nil or sk_o == nil then
					print("error	full_combat_skill", cd, sk_o)
					return false
				end
				if i > skill_id then
					self:add_skill(i, sk_o, cd)
					need_serialize = true
				end
				break
			end
		end
	end
	
	if need_serialize then
		self:serialize()
		return true
	end
	return false
end

-- 把所选的其它职业的已学技能升级到满状态
function Skill_container:full_other_combat_skill(occ)
	local occ_l = {11, 41, 51}
	local ret = false
	for k, v in pairs(occ_l) do
		if v ~= occ then
			local r = self:full_combat_skill(v)
			ret = r or ret
		end
	end
	return ret
end

-- 是否达到80级前的技能都升级完
function Skill_container:is_full_80_level_combat_skill(occ) 
	--print("Skill_container:is_full_80_level_combat_skill()", occ)
	local skill_l =  self:get_skill_l()
	local skill_l_r = {}
	
	for k, v in pairs(skill_l) do
		if f_is_the_occ_combat_skill(occ, v.skill_id) then
			skill_l_r[k] = v.skill_id
		end
	end
	
	local level = 80
	for s_cmd, v in pairs(_skill._skill_occ[occ]) do
		local had_skill_id = skill_l_r[s_cmd]
		if had_skill_id == nil then 
			return false 
		end
		if _skill_config._skill[had_skill_id] == nil then
			print("error	is_full_combat_skill")
			return false
		end
		if _skill_config._skill[had_skill_id + 1][1] <= level then
			return false
		end
	end

	return true
end

-- 学习所有进阶技能
function Skill_container:study_advanced_skill(occ)
	local skill_l =  self:get_skill_l()
	local had_study = false
	for k, v in pairs(_skill._skill_advanced_occ[occ] or {}) do
		if skill_l[k] == nil then
			local skill_id = k + 1
			local sk_o = g_skill_mgr:get_skill(skill_id)
			local cd_o = g_skill_mgr:create_cd(skill_id, self.obj_id)
			if sk_o ~= nil and cd_o ~= nil then
				self:add_skill(skill_id, sk_o, cd_o)
				had_study = true
			end
		end
	end
	if had_study then
		self:serialize()

		_skill_process.get_list(self.obj_id, self.obj_id)
	end
end