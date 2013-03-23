

--*********道具buff************

local _double = 0.1

--双倍经验
Impact_3001 = oo.class(Impact_s, "Impact_3001")

function Impact_3001:__init(obj_id, level)
	Impact_s.__init(self, obj_id)
	self.type = IMPACT_PROP_EXPERIENCE
	self.cmd_id = IMPACT_OBJ_3001
	self.sec_count = 60    --60秒轮询一次
	self.count = 10
	self.flag = 0  
	self.level = level or 1

	self.flag_splice = 1       --0 不叠加 1叠加
	self.class_nm = "Impact_3001"
end

function Impact_3001:on_effect(param)
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj ~= nil then
		self:syn(param)
		self.param = param
		local impact_con = obj:get_impact_con()
		local old_o = impact_con:find_impact(self.cmd_id)
		if not old_o then
			obj:add_double_exp(self.param.per or _double)
		else
			local o_per = old_o.param.per or _double
			local n_per = self.param.per or _double
			if (o_per < n_per) then
				obj:add_double_exp(n_per - o_per)
			elseif (o_per > n_per) then
				return 31351  --旧的对象百分比大于当前要的对象百分比
			end
		end
		impact_con:add_impact(self) 
		return 0
	end
end
function Impact_3001:on_stop()
	local obj = g_obj_mgr:get_obj(self.obj_id)
	obj:add_double_exp(-(self.param and self.param.per or _double))
end
function Impact_3001:on_resume()
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj ~= nil then
		obj:add_double_exp(self.param and self.param.per or _double)
	end
	self:syn(self.param)
end
function Impact_3001:get_param()
	if self.param == nil then
		self.param = {}
	end
	return {math.floor((self.param and self.param.per or _double) * 100)}
end
function Impact_3001:is_clear()
	return false
end
function Impact_3001:is_net_serialize()
	return false
end


--vip挂机场景经验buff
Impact_3002 = oo.class(Impact_s, "Impact_3002")

function Impact_3002:__init(obj_id)
	Impact_s.__init(self, obj_id)
	self.type = IMPACT_PROP_EXPERIENCE
	self.cmd_id = IMPACT_OBJ_3002
	self.sec_count = 1
	self.count = 10000000
	self.flag = 0  

	self.flag_splice = 0       --0 不叠加 1叠加
	self.class_nm = "Impact_3002"
end

function Impact_3002:on_effect(param)
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj ~= nil then
		self.param = param
		self:syn(param)

		local impact_con = obj:get_impact_con()
		obj:add_double_exp(self.param.per)
		impact_con:add_impact(self) 
	end
end
function Impact_3002:on_stop()
	local obj = g_obj_mgr:get_obj(self.obj_id)
	obj:add_double_exp(-self.param.per)
end

function Impact_3002:is_clear()
	return false
end
function Impact_3002:is_save()
	return false
end
function Impact_3002:get_param()
	return {math.floor(self.param.per * 100), math.floor(self.param.per * 100)}
end
--效果叠加回调
function Impact_3002:on_splice(item)
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if item.level >= self.level then        --高级别替换低级别
		obj:add_double_exp(-self.param.per)
		return item
	else
		obj:add_double_exp(-item.param.per)
		return self
	end
end

--神龙活动经验buff
Impact_3003 = oo.class(Impact_s, "Impact_3003")

function Impact_3003:__init(obj_id, level)
	Impact_s.__init(self, obj_id)
	self.type = IMPACT_PROP_EXPERIENCE
	self.cmd_id = IMPACT_OBJ_3003
	self.sec_count = 1
	self.count = 10
	self.flag = 0  
	self.level = level or 1
	self.flag_splice = 1       --0 不叠加 1叠加
	self.class_nm = "Impact_3003"
end

function Impact_3003:on_effect(param)
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj ~= nil then
		self.param = param
		self:syn(param)

		local impact_con = obj:get_impact_con()
		obj:add_double_exp(self.param.per)
		impact_con:add_impact(self) 
	end
end
function Impact_3003:on_stop()
	local obj = g_obj_mgr:get_obj(self.obj_id)
	obj:add_double_exp(-self.param.per)
end

function Impact_3003:is_clear()
	return false
end

function Impact_3003:get_param()
	return {math.floor(self.param.per * 100), self.level}
end

--效果叠加回调
function Impact_3003:on_splice(item)
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if item.level == self.level then                       			
		self.count = self.count + item.count
		obj:add_double_exp(-item.param.per)
		return self
	elseif item.level > self.level then        --高级别替换低级别
		obj:add_double_exp(-self.param.per)
		return item
	else
		obj:add_double_exp(-item.param.per)
		return self
	end
end

function Impact_3003:on_resume()
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj ~= nil then
		obj:add_double_exp(self.param.per)
		self:syn(self.param)
	end
end

--*************加mp，hp buff基类*************
Impact_resume = oo.class(Impact_s, "Impact_resume")

function Impact_resume:__init(obj_id, cmd_id)
	Impact_s.__init(self, obj_id)
	self.type = IMPACT_PROP_RESUME
	self.cmd_id = cmd_id
	self.sec_count = 10    --10秒轮询一次
	self.count = 10000000    --无限时间
	self.flag = 1  

	self.flag_splice = 1       --0 不叠加 1叠加
	self.flag_pause = 0        --1暂停 0运行
end

--param:{param.total_val, param.val, cur_val}
function Impact_resume:on_effect(param)
	self.param = param
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj ~= nil then
		self:syn(param)

		local impact_con = obj:get_impact_con()
		impact_con:add_impact(self) 
	end
end

function Impact_resume:is_clear()
	return false
end

--[[function Impact_resume:on_stop()
	self:serialize()
end]]
function Impact_resume:is_clone()
	return self.param.cur_val > 0
end

--效果叠加
function Impact_resume:on_splice(item)
	if item.level == self.level then                       			
		self.param.total_val = self.param.total_val + item.param.total_val
		self.param.cur_val = self.param.cur_val + item.param.cur_val
		return self
	else                                   --级别不同，直接替换
		return item
	end
end

--暂停函数
function Impact_resume:is_pause()
	return true
end
function Impact_resume:pause(flag)
	self.flag_pause = flag
	return flag
end

function Impact_resume:get_param()
	return {self.param.total_val, self.param.val, self.param.cur_val, self.flag_pause}
end
function Impact_resume:is_net_serialize()
	return false
end
function Impact_resume:on_serialize_to_db(item_l)
	item_l.flag_pause = self.flag_pause
end

function Impact_resume:get_event_time()
	return self.sec_count + ev.time
end


--加红buff
Impact_3011 = oo.class(Impact_resume, "Impact_3011")

function Impact_3011:__init(obj_id)
	Impact_resume.__init(self, obj_id, IMPACT_OBJ_3011)
	self.class_nm = "Impact_3011"
end

function Impact_3011:on_process()
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj ~= nil and self.flag_pause == 0 and obj:is_alive() then
		local max_hp = obj:get_max_hp()
		local cur_hp = obj:get_hp()
		local hp = max_hp - cur_hp
		if hp > 0 then
			hp = math.min(self.param.cur_val, hp, self.param.val)
			obj:add_hp(hp)
			self.param.cur_val = math.floor(self.param.cur_val - hp)

			--self:syn_human()
			self:syn(self.param)
			if self.param.cur_val <= 0 then
				return -1
			end
		end

		--self:serialize()
	end
end

--pet加红buff
Impact_3015 = oo.class(Impact_resume, "Impact_3015")

function Impact_3015:__init(obj_id)
	Impact_resume.__init(self, obj_id, IMPACT_OBJ_3015)
	self.class_nm = "Impact_3015"
end

function Impact_3015:on_process()
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj ~= nil and self.flag_pause == 0 and obj:is_alive() then
		local pet_con = obj:get_pet_con()
		obj = pet_con and pet_con:get_combat_pet()
		if obj == nil then return end

		local max_hp = obj:get_max_hp()
		local cur_hp = obj:get_hp()
		local hp = max_hp - cur_hp
		if hp > 0 then
			hp = math.min(self.param.cur_val, hp, self.param.val)
			obj:add_hp(hp)
			self.param.cur_val = math.floor(self.param.cur_val - hp)

			--self:syn_human()
			self:syn(self.param)
			if self.param.cur_val <= 0 then
				return -1
			end
		end
		--self:serialize()
	end
end



--加蓝buff
Impact_3021 = oo.class(Impact_resume, "Impact_3021")

function Impact_3021:__init(obj_id)
	Impact_resume.__init(self, obj_id, IMPACT_OBJ_3021)
	self.class_nm = "Impact_3021"
end

function Impact_3021:on_process()
	--print("-------------Impact_3021:on_process", self.param.cur_val)
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj ~= nil and self.flag_pause == 0 and obj:is_alive() then
		local max_mp = obj:get_max_mp()
		local cur_mp = obj:get_mp()
		local mp = max_mp - cur_mp
		if mp > 0 then
			mp = math.min(self.param.cur_val, mp, self.param.val)
			obj:add_mp(mp)
			self.param.cur_val = math.floor(self.param.cur_val - mp)

			--self:syn_human()
			self:syn(self.param)
			if self.param.cur_val <= 0 then
				return -1
			end
		end
		--self:serialize()
	end
end

--pet加蓝buff
Impact_3025 = oo.class(Impact_resume, "Impact_3025")

function Impact_3025:__init(obj_id)
	Impact_resume.__init(self, obj_id, IMPACT_OBJ_3025)
	self.class_nm = "Impact_3025"
end

function Impact_3025:on_process()
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj ~= nil and self.flag_pause == 0 and obj:is_alive() then
		local pet_con = obj:get_pet_con()
		obj = pet_con and pet_con:get_combat_pet()
		if obj == nil then return end

		local max_mp = obj:get_max_mp()
		local cur_mp = obj:get_mp()
		local mp = max_mp - cur_mp
		if mp > 0 then
			mp = math.min(self.param.cur_val, mp, self.param.val)
			obj:add_mp(mp)
			self.param.cur_val = math.floor(self.param.cur_val - mp)

			--self:syn_human()
			self:syn(self.param)
			if self.param.cur_val <= 0 then
				return -1
			end
		end
		--self:serialize()
	end
end