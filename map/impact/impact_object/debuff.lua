
require("impact.impact_object.buff")
local _expr = require("config.expr")

--中毒效果
Impact_1301 = oo.class(Impact_s, "Impact_1301")

function Impact_1301:__init(obj_id)
	Impact_s.__init(self, obj_id)
	self.type = IMPACT_DEBUFF
	self.cmd_id = IMPACT_OBJ_1301
	self.sec_count = 3    --3秒轮询一次
	self.count = 5
	self.flag = 1 
	self.class_nm = "Impact_1301"
end

--param.ak param.dg
function Impact_1301:on_effect(param)
	--print("Impact_1301:effect", self.obj_id)
	self.param = param
	local obj_d = g_obj_mgr:get_obj(self.obj_id)
	if obj_d ~= nil then
		self:syn(param)
		
		local impact_con = obj_d:get_impact_con()
		impact_con:add_impact(self) 
	end
end

function Impact_1301:get_event_time()
	return self.sec_count + ev.time
end

function Impact_1301:on_process()
	self.cur_count = self.cur_count + 1
	if self.count < self.cur_count then
		return -1
	end

	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj ~= nil then
		local scene_o = obj:get_scene_obj()
		local new_pkt = {}
		new_pkt[1] = 0
		new_pkt[2] = self.obj_id
		new_pkt[3] = _expr.human_a_damage(self.param.ak or 1, obj, self.param.dg or 1)
		new_pkt[4] = 0
		
		if obj:on_damage(new_pkt.hp, g_obj_mgr:get_obj(self.param.sour_id), self.param.skill_id) then
			scene_o:send_screen(self.obj_id, CMD_MAP_COMBAT_ALTER_HP_S, new_pkt, 1)
		end
	end
end


--减速
Impact_1311 = oo.class(Impact_s, "Impact_1311")

function Impact_1311:__init(obj_id)
	Impact_s.__init(self, obj_id)
	self.type = IMPACT_DEBUFF
	self.cmd_id = IMPACT_OBJ_1311
	self.sec_count = 1
	self.count = 10
	self.flag = 0
	self.class_nm = "Impact_1311"
end

--返回减速速度 
function Impact_1311:get_effect()
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj ~= nil and not obj:is_god() then
		local sp = obj:get_speed()
		return -math.max(1, math.floor(sp*self.param.sp_per))
	end
	return 0
end
--param.sp_per
function Impact_1311:on_effect(param)
	--print("Impact_1311:effect", self.obj_id)
	self.param = param
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj ~= nil then
		self:syn(param)
		
		local impact_con = obj:get_impact_con()
		impact_con:add_impact(self) 

		local _ = obj.on_update_instant and obj:on_update_instant(4,0)
	end
end
function Impact_1311:on_stop()
	--print("Impact_1311:on_stop()")
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj ~= nil then
		local _ = obj.on_update_instant and obj:on_update_instant(4,0)
	end
end
function Impact_1311:get_param()
	return {(self.param.sp_per or 0)*100}
end


--降魔防
Impact_1321 = oo.class(Impact_attr, "Impact_1321")

function Impact_1321:__init(obj_id)
	Impact_s.__init(self, obj_id)
	self.type = IMPACT_DEBUFF
	self.cmd_id = IMPACT_OBJ_1321
	self.sec_count = 10    --10秒轮询一次
	self.count = 1
	self.flag = 1 
	self.class_nm = "Impact_1321"
end

--返回几率
function Impact_1321:get_effect()
	return -(self.param.per or 0), -(self.param.val or 0)
end


function Impact_1321:get_param()
	return {(self.param.per or 0)*100, self.param.val or 0}
end

function Impact_1321:on_add_effect(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.MAGIC_DE, per, val)
end

function Impact_1321:on_ineffectiveness(impact_con)
	local per, val = self:get_effect()
	impact_con:add_impact_effect(IMPACT_TYPE.MAGIC_DE, -per, -val)
end
