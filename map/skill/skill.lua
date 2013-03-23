
local _expr = require("config.expr")
local _sk_config = require("config.skill_combat_config")
local _sk_config_self = require("config.skill_self_config")
local _dis = 5  --偏差

--*********技能基类*************

Skill = oo.class(nil, "Skill")

function Skill:__init(id, ty)
	self.id = id
	self.cmd_id = nil
	self.distance = 1   --施放有效距离
	self.cd_time = 3    --cd时间
	self.type = ty      --技能类型
	self.level = 1

	self.expend_mp = 0   --耗魔
end
function Skill:get_id()
	return self.id
end
--非战斗技能cmd_id为skill_id
function Skill:get_cmd_id()
	return self.cmd_id or self.id
end
function Skill:get_cd()
	return self.cd_time
end
function Skill:get_type()
	return self.type
end
function Skill:get_dis()
	return self.distance
end
function Skill:get_level()
	return self.level
end
function Skill:get_expend_mp()
	return self.expend_mp
end
function Skill:get_expend_rage()
	return self.expend_mp
end

function Skill:is_validate_dis(obj_s, obj_d)
	--local map_obj = obj_s:get_scene_obj():get_map_obj()
	local cubage = obj_s:get_cubage() + obj_d:get_cubage()
	if self:skill_distance(obj_s:get_pos(), obj_d:get_pos()) <= self:get_dis() + cubage + _dis then
		return true
	end
	return false
end
function Skill:skill_distance(pos, des_pos)
	local x = des_pos[1] - pos[1]
	local y = des_pos[2] - pos[2]
	return math.floor(math.sqrt(0.8*math.pow(x-y, 2) + 0.2*math.pow(x+y, 2)))
end

--使用技能同步:effect_pkt伤害包 sk_type伤害类型(1免疫，nil or 2正常伤害）
function Skill:send_syn(obj_s, des_id, effect_pkt, sk_type)
	local scene_o = obj_s:get_scene_obj()
	local new_pkt = {}
	--[[new_pkt.obj_id = obj_s:get_id()
	new_pkt.des_id = des_id
	new_pkt.skill_id = self.id
	new_pkt.effect = effect_pkt]]
	new_pkt[1] = obj_s:get_id()
	new_pkt[2] = self.id
	new_pkt[3] = {["des_id"]=des_id}
	new_pkt[4] = effect_pkt

	if effect_pkt ~= nil then
		effect_pkt.hp = nil   --兼容老代码
	end
	if effect_pkt == nil and sk_type == 1 then
		new_pkt[4] = {}
		new_pkt[4][1] = 3    --免疫
	end

	scene_o:send_screen(obj_s:get_id(), CMD_MAP_USE_SKILL_SYN_S, new_pkt, 1)
end
--对坐标使用技能同步
function Skill:send_syn_by_pos(obj_s, pos)
	local scene_o = obj_s:get_scene_obj()
	local new_pkt = {}
	--[[new_pkt.obj_id = obj_s:get_id()
	new_pkt.x = pos[1]
	new_pkt.y = pos[2]
	new_pkt.skill_id = self.id]]

	new_pkt[1] = obj_s:get_id()
	new_pkt[2] = self.id
	new_pkt[3] = {["x"]=pos[1],["y"]=pos[2]}
	
	scene_o:send_screen(obj_s:get_id(), CMD_MAP_USE_SKILL_SYN_S, new_pkt, 1)
end

--同步血魔变化
function Skill:send_syn_to_hp(type, obj_s, hp, mp)
	local new_pkt = {}
	new_pkt[1] = type
	new_pkt[2] = obj_s:get_id()
	new_pkt[3] = hp
	new_pkt[4] = mp 

	local scene_o = obj_s:get_scene_obj()
	scene_o:send_screen(obj_s:get_id(), CMD_MAP_COMBAT_ALTER_HP_S, new_pkt, 1)
end

--战斗血魔变化pkt, ak 技能攻击力 dg_type 伤害类型(nil or 1,物理攻击 2，魔法攻击 )
function Skill:make_hp_pkt(obj_s, obj_d, ak, dg_type)
	--print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>", self.id, self.cmd_id, dg_type)
	local damage_expr
	if dg_type == nil or dg_type == 1 then
		damage_expr = _expr.human_s_damage
	elseif dg_type == 2 then
		damage_expr = _expr.human_m_damage
	end
			
	local new_pkt = {}
	--[[new_pkt.type = 0
	new_pkt.obj_id = obj_d:get_id()
	new_pkt.hp = 0
	new_pkt.mp = 0]]
	new_pkt[1] = 0
	new_pkt[2]= obj_d:get_id()
	new_pkt[3] = 0
	new_pkt[4] = 0

	if _expr.human_miss(obj_s, obj_d) then
		--miss
		new_pkt[1] = 1    --miss
	else
		ak = math.floor(ak)
		new_pkt[3],new_pkt[1] = damage_expr(obj_s, obj_d, ak, self.level, self.cmd_id)
	end

	new_pkt.hp = new_pkt[3]  --兼容老代码
	return new_pkt,new_pkt[3]
end

--返回错误码，0表示成功
function Skill:effect(sour_id, param)
	return 0
end

--生成伤害包，不用公式计算 dg为负数
function Skill:make_hp_pkt_2(des_id, dg)

	local new_pkt = {}
	new_pkt[1] = 0
	new_pkt[2] = des_id
	new_pkt[3] = dg
	new_pkt[4] = 0
	new_pkt.hp = new_pkt[3]  --兼容老代码
	return new_pkt,new_pkt[3]
end

--生成伤害包，不用公式计算但计算miss dg为负数
function Skill:make_hp_pkt_3(obj_s, obj_d, dg)

	local new_pkt = {}
	new_pkt[1] = _expr.human_miss(obj_s, obj_d)
	new_pkt[2] = obj_d:get_id()
	new_pkt[3] = new_pkt[1] == 1 and 0 or dg
	new_pkt[4] = 0
	new_pkt.hp = new_pkt[3]  --兼容老代码
	return new_pkt,new_pkt[3]
end

--**********自身技能，喝药，使用道具*************

Skill_self = oo.class(Skill, "Skill_self")

function Skill_self:__init(id)
	Skill.__init(self, id, SKILL_SELF)
	self.distance = _sk_config_self._skill[id][1]
	self.cd_time = _sk_config_self._skill[id][2]
	--self.distance = dis
	--self.cd_time = cd_t
end

--param.item,param.des_id
function Skill_self:effect(sour_id, param)
	if param.des_id == nil then return 21101 end
	local obj_s = g_obj_mgr:get_obj(sour_id)
	local obj_d = g_obj_mgr:get_obj(param.des_id)
	if obj_s == nil or obj_d == nil  then 
		return 21101 
	end

	return 0
end


--***********战斗型技能***************
Skill_combat = oo.class(Skill, "Skill_combat")

function Skill_combat:__init(id, ty, skill_ty, lv)
	Skill.__init(self, id, ty)
	self.cmd_id = skill_ty
	self.level = lv
	if skill_ty < SKILL_OBJ_1000000 or skill_ty >= SKILL_OBJ_2000000 then   --人物技能,宠物技能
		self.distance = _sk_config._skill[skill_ty][1]
		self.cd_time = _sk_config._skill[skill_ty][2]
		self.expend_mp = _sk_config._skill_p[skill_ty][lv][1]
	elseif skill_ty >= SKILL_OBJ_1000000 and skill_ty < SKILL_OBJ_2000000 then --怪物技能
		self.distance = _sk_config._skill[id][1]
		self.cd_time = _sk_config._skill[id][2]
		self.expend_mp = 0
	end
end


--*************被动技能**************
Skill_passive = oo.class(Skill, "Skill_passive")

function Skill_passive:__init(id, ty, skill_ty, lv)
	Skill.__init(self, id, ty)
	self.cmd_id = skill_ty
	self.level = lv
	self.cd_time = -1    --cd时间
end

function Skill_passive:get_effect(param)
	return nil
end


--*************生活技能*************
Skill_life = oo.class(Skill, "Skill_life")
-- 生活技能通用配置放在skill_self_config.lua里
function Skill_life:__init(skill_id, skill_ty, lv)
	Skill.__init(self, skill_id, SKILL_LIFE)
	self.level = lv
	self.cmd_id = skill_ty
	self.distance = _sk_config_self._skill[skill_id][1]
	self.cd_time = _sk_config_self._skill[skill_id][2]
end
