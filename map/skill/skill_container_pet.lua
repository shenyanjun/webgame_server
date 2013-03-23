local pet_skill_table = "pet_skill"
local combination = require("config.pet_skill_combination")
local pet_special_skill_loader = require("config.loader.pet_special_skill_loader")
local fresh_all_count = {10,50,150,640,1600,3200,6400,12800,23040,36864}

Skill_container_pet = oo.class(nil, "Skill_container_pet")

function Skill_container_pet:__init(pet_id, owner_id)
	self.owner_id = owner_id
	self.pet_id = pet_id

	--基础技能
	self.base_skill_id = 0
	--原来技能
	self.skill_list = {}   --{{0,0,0}}
	--副技能
	self.addition_skill_list = {} -- {{0,0,0}}

	--原来技能有效技能
	self.base_effective_skill = {0,0,0,0,0}
	self.base_effective_type = {}   --skill_type, index
	self.skill_flag = {} --存在的技能 skill_id 1(不包括天赋技能和融合技能)

	--融合技能有效技能
	self.addition_effective_skill = {0,0,0,0,0}
	self.addition_effective_type = {} -- skill_type, index

	--总技能
	self.effective_skill = {}

	self.passive_obj_l = {}         --被动技能列表
	self.transfer_obj_l = {}	    --转移技能列表

	--技能对象 （全部技能）
	self.skill_obj_l = {}

	--天赋技能
	self.special_skill = {0,0}
	self.special_effective_skill = {0,0}

	--刷新天赋技能
	self.fresh_count_list = {0,0}
	self.fresh_skill_list = {{},{}}

	--技能格个数
	self.skill_number = 3  --初始值为3，后面可以是4,5

	self:initialize()
end

-------------------------------------更新变化-------------------------------------------------
function Skill_container_pet:initialize()
	for i = 1, 5 do
		self.skill_list[i] = {0,0,0}
		self.addition_skill_list[i] = {0,0,0}
	end
end

--保存被动转移技能
function Skill_container_pet:init_other(skill_id)
	local skill_obj = g_skill_mgr:get_skill(skill_id)
	if skill_obj then
		local ret = skill_obj:get_type()
		if SKILL_PASSIVE == ret then 
			self.passive_obj_l[skill_id] = {}
			self.passive_obj_l[skill_id]["obj"] = skill_obj
		elseif SKILL_TRANSFER_ATTR == ret then
			self.transfer_obj_l[skill_id] = {}
			self.transfer_obj_l[skill_id]["obj"] = skill_obj
		end
	end
end

function Skill_container_pet:get_newest_effective_skill()
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

	local special_skill = {}
	for k, v in ipairs(self.special_effective_skill) do
		special_skill[k] = v

		if k == 2 then
			local s_lvl = v % 100
			local s_type = v - s_lvl 

			local d_lvl = special_skill[1] % 100
			local d_type = special_skill[1] - d_lvl 
			if s_type == d_type then
				if s_lvl >= d_lvl then
					special_skill[1] = 0
				else
					special_skill[2] = 0
				end
			end
		end
	end

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
	return effective_skill
end

--创建cd对象
function Skill_container_pet:create_sk_cd(skill_id)
	local sk_o = g_skill_mgr:get_skill(skill_id)
	if sk_o then
		local cd_o = g_skill_mgr:create_cd(skill_id, self.pet_id)
		if cd_o then
			return 0,sk_o,cd_o
		end
	end
end

function Skill_container_pet:update_base_effective_skill()
	self.base_effective_skill = {0,0,0,0,0}
	self.base_effective_type = {}
	self.skill_flag = {}
	for k,v in pairs(self.skill_list) do
		local effective_skill_id,ret = combination.get_pet_skill_combination(v)
		if ret == 0 then
			local effective_skill_id_ex = self:get_last_effective_skill_id(effective_skill_id)
			self.base_effective_skill[k] = effective_skill_id_ex
			local level = effective_skill_id_ex % 100
			local skill_type = effective_skill_id_ex - level
			self.base_effective_type[skill_type] = k
		end

		for m, n in ipairs(v) do
			if n ~= 0 then
				self.skill_flag[n] = 1
			end
		end
	end
end

function Skill_container_pet:update_addition_effective_skill()
	self.addition_effective_skill = {0,0,0,0,0}
	self.addition_effective_type = {}
	for k,v in pairs(self.addition_skill_list) do
		local effective_skill_id,ret = combination.get_pet_skill_combination(v)
		if ret == 0 then
			local effective_skill_id_ex = self:get_last_effective_skill_id(effective_skill_id)
			self.addition_effective_skill[k] = effective_skill_id_ex
			local level = effective_skill_id_ex % 100
			local skill_type = effective_skill_id_ex - level
			self.addition_effective_type[skill_type] = k
		end
	end
end

function Skill_container_pet:update_special_effective_skill()
	self.special_effective_skill = {0,0}
	for k,v in pairs(self.special_skill) do
		if v ~= 0 then
			local effective_skill_id_ex = self:get_last_effective_skill_id(v)
			self.special_effective_skill[k] = effective_skill_id_ex
		end
	end
end

function Skill_container_pet:get_pet_bag_skill()
	local player = g_obj_mgr:get_obj(self.owner_id)
	if not player then return end

	local pet_con = player:get_pet_con()
	if not pet_con then return end

	local pet_obj = pet_con:get_pet_obj(self.pet_id)
	local pet_pack = pet_obj:get_pack_con()
	local ret = pet_pack:get_skill_list()

	return ret --skill_type, level
end

--获取最后的有效技能（包括魂玉里面吸取魂魄之后的技能加成）
function Skill_container_pet:get_last_effective_skill_id(skill_id)
	if skill_id == nil then return end
	local ret = self:get_pet_bag_skill()

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

--
function Skill_container_pet:update_skill_obj()
	self.passive_obj_l = {}
	self.transfer_obj_l = {}
	local effective_skill = self:get_newest_effective_skill()

	local skill_obj_l = {}
	for k, v in ipairs(effective_skill) do
		--重新初始化被动和转移技能
		self:init_other(v)

		if self.skill_obj_l[v] == nil then
			local ret,sk_o,cd_o = self:create_sk_cd(v)
			if ret == 0 then
				local list = {}
				list["cd"] = cd_o
				list["obj"] = sk_o
				skill_obj_l[v] = list
			end
		else
			skill_obj_l[v] = self.skill_obj_l[v]
		end
	end

	self.skill_obj_l = skill_obj_l

	--先天技能
	if self.skill_obj_l[self.base_skill_id] == nil then
		self:init_base_skill(self.base_skill_id)
	end
end
------------------------------技能操作-----------------------------------------------
function Skill_container_pet:find_pet_skill_index()
	for i = 1, self.skill_number do
		local list = self.skill_list[i]
		if list[1] == 0 and list[2] == 0 and list[3] == 0 then	--此技能栏为空
			return i
		end
	end
end

--用来宠物融合预览
function Skill_container_pet:fusion_skill_list_show(skill_id, skill_list, t_skill_limit, main_skill_type)
	local skill_o = g_skill_mgr:get_skill(skill_id)
	if not skill_o then return end

	local sk_ty, sub = combination.get_pet_skill_type(skill_id)			--技能skill_id的类型与下标
	if sub <= 0 or sub > 3 then											--配置有错,不能入库
		print("Error: configuration is Wrong!",sub,skill_id)
		return 200012,nil
	end

	local index = main_skill_type[sk_ty]
	if index then
		if skill_list[index][sub] ~= 0 then
			return 21125,skill_id
		else
			skill_list[index][sub] = skill_id
		end
	else
		local index = nil
		for i = 1, t_skill_limit do
			local list = skill_list[i]
			if list[1] == 0 and list[2] == 0 and list[3] == 0 then	--此技能栏为空
				index = i
				break
			end
		end
		if index then
			skill_list[index][sub] = skill_id
			main_skill_type[sk_ty] = index
		else
			return 22022,nil
		end
	end
	
	--self:equip_change_skill()
	--更新列表

	return 0, skill_list
end

function Skill_container_pet:fushion_effective_skill_show(addition_skill_list)
	local addition_effective_skill = {0,0,0,0,0}
	for k,v in pairs(addition_skill_list) do
		local effective_skill_id,ret = combination.get_pet_skill_combination(v)
		if ret == 0 then
			local effective_skill_id_ex = self:get_last_effective_skill_id(effective_skill_id)
			addition_effective_skill[k] = effective_skill_id_ex
		end
	end

	return addition_effective_skill
end

-------------------------------------------------------------------------------
function Skill_container_pet:check_and_add_skill(skill_id)
	local skill_o = g_skill_mgr:get_skill(skill_id)
	if not skill_o then return end

	if self.skill_flag[skill_id] ~= nil then return 21125, skill_id end

	return self:add_skill(skill_id)
end

--基本技能操作(--------------------技能操作要跟接口update_skill_obj结合使用，不然数据会混乱-----下面的接口只是更新一部分数据，
--而update_skill_obj调用了才会全部数据争取
function Skill_container_pet:add_skill(skill_id)
	local sk_ty, sub = combination.get_pet_skill_type(skill_id)			--技能skill_id的类型与下标
	if sub <= 0 or sub > 3 then											--配置有错,不能入库
		print("Error: configuration is Wrong!",sub,skill_id)
		return 200012,nil
	end

	local addition_index = self.addition_effective_type[sk_ty]
	if addition_index ~= nil then
		if self.addition_skill_list[addition_index][sub] ~= 0 then
			return 21125,skill_id
		else
			self.addition_skill_list[addition_index][sub] = skill_id
		end
	else
		local index = self.base_effective_type[sk_ty]
		if index then
			if self.skill_list[index][sub] ~= 0 then
				return 21125,skill_id
			else
				self.skill_list[index][sub] = skill_id
			end
		else
			index = self:find_pet_skill_index()
			if index then
				self.skill_list[index][sub] = skill_id
			else
				return 22022,nil
			end
		end
	end
	
	--self:equip_change_skill()
	--更新列表

	return 0, skill_id
end

function Skill_container_pet:del_skill(skill_id)
	local sk_ty,sub = combination.get_pet_skill_type(skill_id)
	local index = self.base_effective_type[sk_ty]

	if index then
		if sub <= 0 or sub > 3 then							--配置有错,不能入库
			print("Error: configuration is Wrong!",sub,skill_id)
			return 200012,nil
		end

		self.skill_list[index][sub] = 0
		if self.skill_list[index][1] == 0 and self.skill_list[index][2] == 0 and self.skill_list[index][3] == 0 then
			local skill = self.addition_skill_list[index]
			self.skill_list[index] = skill
			self:del_addition_skill(index)
		end

		return 0,skill_id
	end

	return 10018, nil
end

--天赋技能操作
function Skill_container_pet:add_skill_ex(skill_id,slot)
	local skill_obj = g_skill_mgr:get_skill(skill_id)
	if not skill_obj then return end

	if slot == nil then
		if self.special_skill[1] == 0 then
			self.special_skill[1] = skill_id
		elseif self.special_skill[2] == 0 then
			self.special_skill[2] = skill_id
		else
			return 
		end
	else
		if slot >0 and slot < 3  then
			self.special_skill[slot] = skill_id
		else
			return
		end
	end

	--self:update_skill_obj()
	--更新列表
	return 0
end

function Skill_container_pet:del_special_skill(slot)
	if slot < 1 or slot > 2 then return end
	local special_skill = self.special_skill[slot]
	if special_skill ~= nil and special_skill ~= 0 then
		if slot == 1 then
			self.special_skill[slot] = 0
		elseif slot == 2 then
			self.special_skill[slot] = 0
		end
	end

	--self:update_skill_obj()
	--self:serialize()
	--更新列表
	return 0
end

--副技能操作
function Skill_container_pet:add_addition_skill(skill_list, slot)
	self.addition_skill_list[slot] = skill_list
	return 0
end

function Skill_container_pet:add_addition_skill_ex(index, skill_id, slot)
	self.addition_skill_list[index][slot] = skill_id
end

function Skill_container_pet:del_addition_skill(slot)
	self.addition_skill_list[slot] = {0,0,0}
	return 0
end

function Skill_container_pet:del_addition_skill_ex(skill_id)
	local index = self:get_addition_skill_by_skill_id(skill_id)

	if index ~= 0 then
		return self:del_addition_skill(index)
	end
end

function Skill_container_pet:get_addition_skill_by_skill_id(skill_id)
	local index = 0
	for k, v in ipairs(self.addition_effective_skill) do
		if v ~= 0 and v == skill_id then
			index = k
			break
		end
	end

	return index
end

--返回技能skill_id对象的cd
function Skill_container_pet:get_skill_cd(skill_id)
	return self.skill_obj_l[skill_id]["cd"]
end

--使用技能,成功返回0，错误返回错误码
function Skill_container_pet:use(skill_id, param)
	if skill_id == nil or self.skill_obj_l[skill_id] == nil then 
		--local debug = Debug(g_debug_log)
		--debug:trace("===================>>", skill_id)
		print("===================>>", skill_id, self.pet_id, self.owner_id)
		return 21111 
	end
	if self.passive_obj_l[skill_id] or self.transfer_obj_l[skill_id] then
		return 21112							--被动技能与转移技能不能使用
	end

	local cd = self:get_skill_cd(skill_id)
	local skill_o = g_skill_mgr:get_skill(skill_id)
	if cd and skill_o and cd:get_status() then
		local hm_o = g_obj_mgr:get_obj(self.pet_id)
		if hm_o ~= nil then
			if not hm_o:is_use_skill(skill_id) then
				return 21114					--现在不能使用该技能
			end
			local mp = math.max(skill_o:get_expend_mp()+hm_o:get_passive_effect(SKILL_SUB_MP, skill_id), 0)
			if mp > hm_o:get_mp() then
				return 21115					--魔法不够
			end
			--skill_o = g_skill_mgr:get_skill(2250701)
			local ret = skill_o:effect(self.pet_id, param, self.owner_id)		--某些技能需要人物的id
			if ret == 0 then
				cd:use()
				local _ = mp > 0 and hm_o:add_mp(-mp)
			end
			return ret
		end
	end
	return 21116								--冷却中...
end

----------------------------被动和转移技能生效------------------------------------------
--转移技能的生效
function Skill_container_pet:transfer_init()
	local _equip_l = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
	local param = {}
	for k,sk in pairs(self.transfer_obj_l) do
		param.owner_id = self.owner_id
		local effect_param = sk["obj"]:effect(self.pet_id,param)
		for k1,v in pairs(effect_param) do
			_equip_l[k1] = _equip_l[k1] + v
		end
	end
	return _equip_l
end

--被动技能的生效
function Skill_container_pet:passive_init(char_id, pet_owner_id)
	local param = {}
	for k,sk in pairs(self.passive_obj_l) do
		param.owner_id = pet_owner_id
		sk["obj"]:effect(char_id, param)
	end
end

----------------------------天赋技能 -----------------------------------------------
function Skill_container_pet:get_max_skill_level()
	local level = 0
	for k,v in pairs(self.base_effective_skill) do
		if v ~= 0 then
			local lvl = v%100
			if level < lvl then
				level = lvl
			end
		end
	end

	return level
end

function Skill_container_pet:get_last_special_skill()
	return self.special_effective_skill
end

function Skill_container_pet:get_special_skill_count()
	local count = 0
	for k, v in pairs(self.special_skill) do
		if v ~= 0 then
			count = count + 1
		end
	end

	return count
end

function Skill_container_pet:get_fresh_skill_list()
	return self.fresh_skill_list
end

function Skill_container_pet:get_fresh_skill_slot_list(slot)
	return self.fresh_skill_list[slot]
end

function Skill_container_pet:set_fresh_skill_list(skill_list)
	self.fresh_skill_list = skill_list
end

function Skill_container_pet:set_fresh_skill_slot_list(skill_id_list,slot)
	self.fresh_skill_list[slot] = skill_id_list
end

function Skill_container_pet:get_fresh_count_list()
	return self.fresh_count_list
end

function Skill_container_pet:get_fresh_count_slot_list(slot)
	return self.fresh_count_list[slot]
end

function Skill_container_pet:add_fresh_count_list(count,slot)
	self.fresh_count_list[slot] = self.fresh_count_list[slot] + count
end

function Skill_container_pet:set_fresh_count_list(count,slot)
	self.fresh_count_list[slot] = count
end

function Skill_container_pet:get_special_skill()
	return self.special_skill
end

function Skill_container_pet:create_special_skill()
	local pet_special_skill = pet_special_skill_loader.pet_special_skill
	local skill_id_list = pet_special_skill["0"]

	local skill_list = f_random_wave(skill_id_list,1)
	local skill_id = skill_list[1][1]
	
	return skill_id or 0
end

function Skill_container_pet:create_special_skill_list(slot,level)
	local pet_special_skill = pet_special_skill_loader.pet_special_skill
	local skill_id_list = {}
	local fresh_count_list = self:get_fresh_count_list()
	local fresh_count = fresh_count_list[slot]

	local index = 0
	local max_count = table.size(fresh_all_count)
	for k,v in pairs(fresh_all_count) do
		if k ~= max_count then
			if fresh_count < v then
				index = k -1
				break
			end
		else
			index = k
			break
		end
	end

	local special_skill_list = pet_special_skill[tostring(index)]
	if special_skill_list == nil then return end

	local skill_id_list_ex = {}
	local skill_list = f_random_wave(special_skill_list,10)
	for m, n in pairs(skill_list) do
		table.insert(skill_id_list_ex,n[1])
	end

	return skill_id_list_ex or {}
end

-----------------------------------数据------------------------------------------
function Skill_container_pet:unserialize()
	--查询数据库
	local db = f_get_db()
	local rows, e_code = db:select_one(pet_skill_table, nil, string.format("{pet_id:%d}", self.pet_id), nil,"{pet_id:1}")

	if 0 == e_code and rows then
		self.fresh_count_list = rows.fresh_count_list or {0,0}
		self.fresh_skill_list = rows.fresh_skill_list or {{},{}}

		for i = 1, 5 do
			if rows.skill_list[i] == nil then
				rows.skill_list[i] = {0,0,0}
			end
		end
		--基础技能
		self.skill_list = rows.skill_list or {{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0}}
		--融合技能
		self.addition_skill_list = rows.addition_skill_list or {{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0}}
		--天赋技能
		self.special_skill = rows.special_skill or {0,0}

		--初始化skill_obj_l
		local base_skill_cd = rows.skill_cd
		--local addition_skill_cd = rows.addition_skill_cd
		local special_skill_cd = rows.special_skill_cd
		self:init_skill_obj(base_skill_cd,special_skill_cd)
		--self:update_skill_obj()
	end
end

function Skill_container_pet:init_skill_obj(base_skill_cd, special_skill_cd)
	for k, v in ipairs(self.skill_list) do
		local effective_id = self.base_effective_skill[k]
		local skill_o = g_skill_mgr:get_skill(effective_id)
		if skill_o then
			local list = {}
			list["obj"] = skill_o
			--cd处理
			if base_skill_cd[k] ~= nil then
				list["cd"] = Cd_time(effective_id, self.pet_id, skill_o:get_cd())
				list["cd"] = list["cd"]:clone(base_skill_cd[k], skill_o:get_cd())
			else
				list["cd"] = Cd_time(effective_id, self.pet_id, skill_o:get_cd())
			end

			self.skill_obj_l[effective_id] = list
		end
	end

	--for k, v in ipairs(self.addition_skill_list) do
		--local effective_id = self.addition_effective_skill[k]
		--local skill_o = g_skill_mgr:get_skill(effective_id)
		--if skill_o then
			--local list = {}
			--list["obj"] = skill_o
			----cd处理
			--if addition_skill_cd[k] ~= nil then
				--list["cd"] = Cd_time(effective_id, self.pet_id, skill_o:get_cd())
				--list["cd"] = list["cd"]:clone(addition_skill_cd[k], skill_o:get_cd())
			--else
				--list["cd"] = Cd_time(effective_id, self.pet_id, skill_o:get_cd())
			--end
--
			--self.skill_obj_l[effective_id] = list
		--end
	--end
	
	for k, v in ipairs(self.special_skill) do
		local effective_id = self.special_skill[k]
		local skill_o = g_skill_mgr:get_skill(v)
		if skill_o then
			local list = {}
			list["obj"] = skill_o
			--cd处理
			if special_skill_cd ~= nil and special_skill_cd[k] ~= nil then
				list["cd"] = Cd_time(v, self.pet_id, skill_o:get_cd())
				list["cd"] = list["cd"]:clone(special_skill_cd[k], skill_o:get_cd())
			else
				list["cd"] = Cd_time(v, self.pet_id, skill_o:get_cd())
			end

			self.skill_obj_l[effective_id] = list
		end
	end
end

function Skill_container_pet:extract_skill_list_info(has_cd)
	local update = {}
	update.pet_id = self.pet_id
	update.skill_cd = {}
	update.skill_list = {}
	--update.addition_skill_cd = {}
	update.addition_skill_list = {}
	update.special_skill_cd = {}
	update.special_skill = {}
	
	for k=1,5 do
		--base skill
		local temp = self.base_effective_skill[k]
		if has_cd and 0 ~= temp then
			update.skill_cd[k] = self.skill_obj_l[temp] ~= nil and self.skill_obj_l[temp]["cd"] or nil
		end
		update.skill_list[k] = self.skill_list[k] or {0,0,0}

		--addition_skill
		--local temp1 = self.addition_effective_skill[k]
		--if has_cd and 0 ~= temp1 then
		--	update.addition_skill_cd[k] = self.skill_obj_l[temp1] ~= nil and self.skill_obj_l[temp1]["cd"] or nil
		--end
		
		update.addition_skill_list[k] = self.addition_skill_list[k]
	end

	for i = 1, 2 do
		update.special_skill[i] = self.special_skill[i]
		if has_cd and 0 ~= self.special_skill[i] then
			update.skill_cd[i] = self.skill_obj_l[self.special_skill[i]] ~= nil and self.skill_obj_l[self.special_skill[i]]["cd"]
		end
	end
	
	update.fresh_count_list = self.fresh_count_list
	update.fresh_skill_list = self.fresh_skill_list

	return update
end

function Skill_container_pet:serialize()
	local update = self:extract_skill_list_info(true)
	local db = f_get_db()
	local e_code = db:update(pet_skill_table, string.format("{pet_id:%d}", self.pet_id),Json.Encode(update), true)
end

function Skill_container_pet:net_get_cd_info()
	local list = {}
	for k,v in pairs(self.skill_obj_l) do
		local skill_type = g_skill_mgr:get_skill_type(v.skill_id)
		if skill_type ~= SKILL_PASSIVE and skill_type ~= SKILL_TRANSFER_ATTR then
			local temp = {}
			temp["skill_id"] = v.skill_id
			temp["skill_cmd"] = k
			temp["time"] = v.cd:get_last_time()
			table.insert(list,temp)
		end
	end
	return list
end

--宠物技能的更新包
function Skill_container_pet:net_get_info()
	local new_pkt = {}
	new_pkt.obj_id = self.pet_id
	new_pkt.list = {}
	new_pkt.effective_list = {}
	new_pkt.base_list = {}
	new_pkt.special_skill_list = {}
	new_pkt.addition_effective_list = {}
	--new_pkt.addition_list = {}

	for k,v in ipairs(self.skill_list) do
		local e_skill = self.base_effective_skill[k]
		new_pkt.list[k] = v
		local list = {}
		list[1] = e_skill
		list[2] = 0 
		if e_skill ~= 0 and self.skill_obj_l[ e_skill ] and self.skill_obj_l[ e_skill ]["cd"] then
			list[2] = self.skill_obj_l[ e_skill ]["cd"]:get_cd_time()
		end
		new_pkt.effective_list[k] = list
	end
		
	for i =1, 2  do
		local skill_id = self.special_effective_skill[i]
		local list = {}
		list[1] = skill_id
		list[2] = 0 
		if skill_id ~= 0 and self.skill_obj_l[ skill_id ] and self.skill_obj_l[ skill_id ]["cd"] then
			list[2] = self.skill_obj_l[ skill_id ]["cd"]:get_cd_time()
		end
		table.insert(new_pkt.special_skill_list, list)
	end

	--for k, v in ipairs(self.addition_skill_list) do
		--local e_skill = self.addition_effective_skill[k]
		--new_pkt.addition_list[k] = v
		--local list = {}
		--list[1] = e_skill
		--list[2] = e_skill ~= 0 and self.skill_obj_l[ e_skill ]["cd"]:get_cd_time() or 0
		--new_pkt.addition_effective_list[k] = e_skill
	--end

	new_pkt.addition_effective_list = self.addition_effective_skill
	new_pkt.addition_skill_list = self.addition_skill_list

	new_pkt.base_list[1] = self.base_skill_id
	new_pkt.base_list[2] = self.skill_obj_l[ self.base_skill_id ]["cd"]:get_cd_time()

	return new_pkt
end


--同步到公共服
function Skill_container_pet:get_common_syn_info()
	local ret = {}
	local skill_list = {{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0}}
	for m, n in ipairs(self.skill_list) do
		for km, vm in ipairs(n) do
			skill_list[m][km] = vm
		end
	end
	for k, v in ipairs(self.base_effective_skill) do
		if v ~= 0 then
			local skill_o = g_skill_mgr:get_skill(v)
			if skill_o and skill_o:get_type() == SKILL_PET_ATTACK_TRIGGER then 
				skill_list[k] = {0,0,0}
			end
		end
	end
	ret[1] = skill_list

	local special_skill = {0,0}
	for m, n in ipairs(self.special_skill) do
		special_skill[m] = n
		if n ~= 0 then
			local skill_o = g_skill_mgr:get_skill(n)
			if skill_o and skill_o:get_type() == SKILL_PET_ATTACK_TRIGGER then 
				special_skill[m] = 0
			end
		end
	end
	ret[2] = special_skill

	local addition_skill_list = {{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0}}
	for m, n in ipairs(self.addition_skill_list) do
		for km, vm in ipairs(n) do
			addition_skill_list[m][km] = vm
		end
	end
	for k, v in ipairs(self.addition_effective_skill) do
		if v ~= 0 then
			local skill_o = g_skill_mgr:get_skill(v)
			if skill_o and skill_o:get_type() == SKILL_PET_ATTACK_TRIGGER then 
				addition_skill_list[k] = {0,0,0}
			end
		end
	end
	ret[3] = addition_skill_list


	return ret
end

---对外接口
function Skill_container_pet:equip_change_skill(flag)
	self:update_skill_obj()

	if flag == nil then
		--更新数据库
		self:serialize()
	end
	local new_pkt = {}
	new_pkt = self:net_get_info()
	g_cltsock_mgr:send_client(self.owner_id, CMD_MAP_PET_SKILL_INFO_S, new_pkt)

	return 0
end

--添加先天技能
function Skill_container_pet:add_base_skill(skill_id)
	self.base_skill_id = skill_id
	self:init_base_skill(skill_id)
end

--初始先天技能
function Skill_container_pet:init_base_skill(skill_id)
	local ret,skill_obj,cd = self:create_sk_cd(skill_id)
	local list = self.skill_obj_l[skill_id]
	if list == nil then
		list = {}
		list["cd"] = cd
		list["obj"] = skill_obj
		self.skill_obj_l[skill_id] = list
		self:init_other(skill_id, skill_obj)
	end
end

--设定技能数量
function Skill_container_pet:set_skill_limit(skill_limit_number)
	self.skill_number = skill_limit_number
end

--获取先天技能
function Skill_container_pet:get_base_skill()
	return self.base_skill_id
end

--返回skill_id技能
function Skill_container_pet:get_skill(skill_id)
	return self.skill_obj_l[skill_id]
end

--返回技能skill_id的对象
function Skill_container_pet:get_skill_obj(skill_id)
	if self.skill_obj_l[skill_id] ~= nil then
		return self.skill_obj_l[skill_id]["obj"]
	end
end

--获取技能id列表 不包括生效技能
function Skill_container_pet:get_skill_list()
	return self.skill_list
end

--获取生效技能列表
function Skill_container_pet:get_effective_list()
	return self.base_effective_skill
end

function Skill_container_pet:get_effective_list_ex()
	return self.effective_skill
end

function Skill_container_pet:get_skill_count()
	local count = 0
	for k,v in pairs(self.skill_list) do
		for m, n in pairs(v) do
			if n ~= 0 and n ~= nil then
				count = count + 1
			end
		end
	end
	for c, d in pairs(self.special_skill) do
		if d ~=0 and d ~= nil then
			count = count + 1
		end
	end

	return count
end