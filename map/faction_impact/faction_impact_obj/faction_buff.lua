
require("faction_impact.faction_impact_base")
--*********帮派增加人物属性buff基类************

Impact_faction = oo.class(Faction_impact_base, "Impact_faction")

function Impact_faction:__init(faction_id, ty, impact_id)
	Impact_s.__init(self, faction_id)
	self.type = ty
	self.cmd_id = impact_id
	self.sec_count = 10000    --10000秒轮询一次(不需要轮询)
	self.count = 10000
	self.flag = 0  
end

--param.per
function Impact_faction:effect(param)
--[[
	self.param = param
	local obj = g_obj_mgr:get_obj(self.obj_id)
	if obj ~= nil then
		self:syn(param)
		local impact_con = obj:get_impact_con()
		impact_con:add_impact(self) 
		print("===>Impact_faction:effect,cmd_id:", self.cmd_id,"param.per",self.param.per, "obj_id",self.obj_id)
		local _ = obj.on_update_attribute and obj:on_update_attribute(1)
	end
]]
end


function Impact_faction:get_effect()
	return self.param.per or 0, self.param.val or 0
end

function Impact_faction:get_param()
	return {(self.param.per or 0)*100, self.param.val or 0}
end

--玩家死亡不清理帮派buff
function Impact_faction:is_clear()
	return false
end

--不保存帮派buff
function Impact_faction:is_save()
	return false
end

--不需要网络序列化同步给其他人
function Impact_faction:is_net_serialize()
	return false
end


-------------   齐心协力(增加物理与魔法攻击)   -------------
Impact_5001 = oo.class(Impact_faction, "Impact_5001")
function Impact_5001:__init(obj_id, lv, per, val)
	Impact_faction.__init(self, obj_id, IMPACT_FACTION_BUFF, IMPACT_OBJ_5001)
	self.class_nm = "Impact_5001"
	self.param = {}
	self.param.per = per
	self.param.val = val
	--buff级别
	self.level = lv or 1
end


-------------   共度难关(增加物理与魔法防御)   -------------
Impact_5002 = oo.class(Impact_faction, "Impact_5002")
function Impact_5002:__init(obj_id, lv, per, val)
	Impact_faction.__init(self, obj_id, IMPACT_FACTION_BUFF, IMPACT_OBJ_5002)
	self.class_nm = "Impact_5002"
	self.param = {}
	self.param.per = per
	self.param.val = val
	--buff级别
	self.level = lv or 1
end

-------------   集思广益(增加杀怪经验)   -------------
Impact_5003 = oo.class(Impact_faction, "Impact_5003")
function Impact_5003:__init(obj_id, lv, per, val)
	Impact_faction.__init(self, obj_id, IMPACT_FACTION_BUFF, IMPACT_OBJ_5003)
	self.class_nm = "Impact_5003"
	self.param = {}
	self.param.per = per
	self.param.val = val
	--buff级别
	self.level = lv or 1
end