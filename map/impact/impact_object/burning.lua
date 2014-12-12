
Impact_burning = oo.class(Impact_s, "Impact_burning")

--燃烧类效果
function Impact_burning:__init(obj_id, cmd_id)
	Impact_s.__init(self, obj_id)
	self.type = IMPACT_BURNING
	self.cmd_id = cmd_id
	self.sec_count = 5    --5秒轮询一次
	self.count = 12
	self.flag = 0
	self.class_nm = "Impact_burning"
end

--param:{param.total_val, param.val, cur_val}
function Impact_burning:on_effect(param)
	self.param = param
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj ~= nil then
		self:syn(param)

		local impact_con = obj:get_impact_con()
		impact_con:add_impact(self) 
	end
end

function Impact_burning:is_clear()
	return true
end

--效果叠加
function Impact_burning:on_splice(item)
	if item.level < self.level then                       			
		return self
	else                                   --级别不同，直接替换
		return item
	end
end

function Impact_burning:get_param()
	return {math.abs(self.param.per or 0)*100, math.abs(self.param.val or 0)}
end

function Impact_burning:get_event_time()
	return self.sec_count + ev.time
end


---------------------------------------------------------------
--燃烧(未使用)
Impact_1511 = oo.class(Impact_s, "Impact_1511")

function Impact_1511:__init(obj_id)
	Impact_s.__init(self, obj_id)
	self.type = IMPACT_BURNING
	self.cmd_id = IMPACT_OBJ_1511
	self.sec_count = 5    --5秒轮询一次
	self.count = 3
	self.flag = 0  
	self.class_nm = "Impact_1511"
end
function Impact_1511:get_effect()
	return self.param.dg_per
end

--param.dg_per
function Impact_1511:on_effect(param)
	self.param = param
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj ~= nil then
		self:syn(param)
		local impact_con = obj:get_impact_con()
		impact_con:add_impact(self) 

		local _ = obj.on_update_attribute and obj:on_update_attribute(1)
	end
end


----------------------------------------------------------
--持续伤害
Impact_1512 = oo.class(Impact_burning, "Impact_1512")

function Impact_1512:__init(obj_id)
	Impact_burning.__init(self, obj_id, IMPACT_OBJ_1512)
	self.sec_count = 3    --3秒轮询一次
	self.class_nm = "Impact_1512"
end

function Impact_1512:on_process()
	--print("Impact_1512:on_process()")
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj ~= nil and obj:is_alive() then
		obj:on_damage(-self.param.val, nil, nil)
		
		if ev.time >= self.tm_start + self.count*self.sec_count or not obj:is_alive() then
			return -1
		end
	end
end

----------------------------------------------------------
--持续加怒气
Impact_1513 = oo.class(Impact_burning, "Impact_1513")

function Impact_1513:__init(obj_id)
	Impact_burning.__init(self, obj_id, IMPACT_OBJ_1513)
	self.sec_count = 3    --3秒轮询一次
	self.class_nm = "Impact_1513"
	self.type = IMPACT_BURNING
	self.cmd_id = IMPACT_OBJ_1513
	self.count = 3
end

function Impact_1513:on_process()
	--print("Impact_1513:on_process()")
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj ~= nil and obj:is_alive() then
		obj:add_rage(self.param.val)
		
		if ev.time >= self.tm_start + self.count*self.sec_count or not obj:is_alive() then
			return -1
		end
	end
end