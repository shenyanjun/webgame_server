local _config = require("config.xml.human_fight.human_skill_config")

Human_skill_container = oo.class(nil,"Human_skill_container")

function Human_skill_container:__init(char_id)
	self.char_id = char_id

	--主动技能列表
	self.skill_list = {}

	--排序
	self.skill_sort = {}

	--转移技能 添加的一些属性 hp,mp,物攻，法功，物防，法防
	self.skill_attr = {0,0,0,0,0,0}

	--转移技能 减少对方一些属性，hp,mp,物攻，法功，物防，法防
	self.skill_sub = {0,0,0,0,0,0}

	--技能释放顺序
	self.skill_sort_t = {}
end

function Human_skill_container:get_skill_list()
	return self.skill_list
end

function Human_skill_container:set_skill_list(skill_list)
	self.skill_list = skill_list
end

function Human_skill_container:sub_cd()
	for k, v in pairs(self.skill_sort) do
		if v[2] > 0 then
			local time = v[2] - 0.3
			v[2] = time
			if time < 0 then
				v[2] = 0
			end
		end
	end
end

function Human_skill_container:sub_all_cd()
	self.skill_sort = {}
	for k, v in pairs(self.skill_list or{}) do
		if v:get_type() == SKILL_BAD then
			local skill_id = v:get_skill_id()
			local ret = {}
			ret[1] = skill_id
			ret[2] = 0
			table.insert(self.skill_sort, ret)
		end
	end

	local base = {}
	base[1] = self:get_base_skill_id()
	base[2] = 0
	table.insert(self.skill_sort, base)
end

function Human_skill_container:get_base_skill_id()
	local occ = g_player_mgr.all_player_l[self.char_id].occ
	if occ == 11 then   --破军
		return SKILL_OBJ_90000 + 1
	elseif occ == 41 then --天殇
		return SKILL_OBJ_90300 + 1
	elseif occ == 51 then --铃星
		return SKILL_OBJ_90400 + 1
	end
end

function Human_skill_container:use(obj_s, obj_d)
	local skill_id = self:get_effective_skill_id()
	local hp = 0
	local tp = 0
	if skill_id ~= nil then
		local skill_o = g_human_skill_mgr:get_skill(skill_id)
		if self:is_skill_hp(skill_id) then
			local cmd_id = skill_o:get_cmd_id()
			local level = skill_o:get_level()
			local mp = _config._skill_p[cmd_id][level][1]
			hp = _config._skill_p[cmd_id][level][2]
			obj_s:del_mp(mp)
			obj_s:add_hp(hp)
		else
			local skill_o = g_human_skill_mgr:get_skill(skill_id)
			hp, tp = skill_o:effect(obj_s,obj_d)
		end
	else
		print("Error: this skill_id is not useabale")
	end

	self:sub_cd()
	local skill_con = obj_d:get_skill_con()
	skill_con:sub_cd()

	return skill_id, hp, tp
end

function Human_skill_container:get_effective_skill_id()
	local skill_l = self:skill_sort_l()
	local hp_skill = {}
	local ret = {}
	local human_obj = g_human_vs_mgr:get_container(self.char_id):get_human_obj()
	local mp = human_obj:get_mp()
	for k,v in pairs(self.skill_sort) do
		if v[2] == 0 then
			local skill_obj = g_human_skill_mgr:get_skill(v[1])
			if skill_obj then
				if mp >= skill_obj:get_mp() then
					local table_t = {}
					table_t[1] = v[1]
					table_t[2] = v[2]
					table_t[3] = k
					table.insert(ret,table_t)			
				end
			end
		end
	end

	local max_hp = human_obj:get_max_hp()
	for c,d in pairs(skill_l) do
		for m,n in pairs(ret) do
			local skill_obj = g_human_skill_mgr:get_skill(n[1])
			if skill_obj then
				if skill_obj:get_cmd_id() == d then
					if self:is_skill_hp(n[1]) then
						local hp = human_obj:get_hp()
						if hp <= max_hp * 0.5 then
							local cd = skill_obj:get_cd()
							table.remove(self.skill_sort, n[3])
							local ret = {}
							ret[1] = n[1]
							ret[2] = cd
							table.insert(self.skill_sort, ret)
							return n[1]
						end
					else
						local cd = skill_obj:get_cd()
						table.remove(self.skill_sort, n[3])
						local ret = {}
						ret[1] = n[1]
						ret[2] = cd
						table.insert(self.skill_sort, ret)
						return n[1]
					end
				end
			end
		end
	end

	return self:get_base_skill_id()
end

function Human_skill_container:is_skill_hp(skill_id)
	local level = skill_id - skill_id % 100
	if level == SKILL_OBJ_510200 or level == SKILL_OBJ_510300 then
		return true
	end

	return false
end

function Human_skill_container:skill_sort_l()
	local ret = {}
	local occ = g_player_mgr.all_player_l[self.char_id].occ
	if occ == 11 then   --破军
		ret = {SKILL_OBJ_110100,SKILL_OBJ_110200,SKILL_OBJ_110000,SKILL_OBJ_110300}
	elseif occ == 41 then --天殇
		ret = {SKILL_OBJ_411100,SKILL_OBJ_412300,SKILL_OBJ_410100,SKILL_OBJ_411200,SKILL_OBJ_410000}
	elseif occ == 51 then --铃星
		ret = {SKILL_OBJ_510200,SKILL_OBJ_510300,SKILL_OBJ_513600,SKILL_OBJ_513500,SKILL_OBJ_510000}
	end
	return ret
end

function Human_skill_container:clear()
	self.skill_list = {}
	self.skill_attr = {0,0,0,0,0,0}
	self.skill_sort = {}
	self.skill_sub = {0,0,0,0,0,0}
end

function Human_skill_container:update_skill_list(skill_list)
	self:clear()

	for k,v in pairs(skill_list or {}) do
		local skill_obj = g_human_skill_mgr:get_skill(v)
		if skill_obj then
			self.skill_list[v] = skill_obj
		end
	end

	self:set_skill_attr()
	self:set_skill_sub()
end

function Human_skill_container:set_skill_attr()
	for k,v in pairs(self.skill_list) do
		if v:get_type() == SKILL_PASSIVE then
			local cmd_id = v:get_cmd_id()
			local level = v:get_level()
			if cmd_id == SKILL_OBJ_110600 then
				self.skill_attr[5] = self.skill_attr[5] + _config._skill_t[cmd_id][level] or 0
			elseif cmd_id == SKILL_OBJ_412200 then
				self.skill_attr[6] = self.skill_attr[6] + _config._skill_t[cmd_id][level] or 0
			elseif cmd_id == SKILL_OBJ_412100 or cmd_id == SKILL_OBJ_513200 then
				self.skill_attr[4] = self.skill_attr[4] + _config._skill_t[cmd_id][level] or 0
			end
		end
	end
end

function Human_skill_container:set_skill_sub()
	for k,v in pairs(self.skill_list) do
		if v:get_type() == SKILL_PASSIVE then
			local cmd_id = v:get_cmd_id()
			local level = v:get_level()
			if cmd_id == SKILL_OBJ_110600 then
				--self.skill_sub[6] = self.skill_sub[6] + _config._skill_t[cmd_id][level] or 0
			end
		end
	end
end

function Human_skill_container:get_skill_attr()
	return self.skill_attr
end

function Human_skill_container:get_skill_sub()
	return self.skill_sub
end

function Human_skill_container:load()
end







