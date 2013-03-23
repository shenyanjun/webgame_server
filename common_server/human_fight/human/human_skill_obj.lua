local _expr = require("config.xml.human_fight.human_skill_expr")
local _sk_config = require("config.xml.human_fight.human_skill_config")
Human_skill_obj = oo.class(nil, "Human_skill_obj")

function Human_skill_obj:__init(skill_id,type)
	self.skill_id = skill_id
	self.level = skill_id % 100
	self.cmd_id = skill_id - self.level
	self.cd = 0
	self.type = type
end

function Human_skill_obj:get_skill_id()
	return self.skill_id
end

function Human_skill_obj:get_type()
	return self.type
end

function Human_skill_obj:get_cd()
	return self.cd
end

function Human_skill_obj:set_cd(cd)
	if cd < 0 then
		cd = 0
	end
	self.cd = cd
end

function Human_skill_obj:get_cmd_id()
	return self.cmd_id
end

function Human_skill_obj:get_status()
	if self.cd <= 0 then
		return 0
	end
	return self.cd
end

function Human_skill_obj:get_level()
	return self.skill_id % 100
end

function Human_skill_obj:effect(obj_s, obj_d)
	return 0
end


-----战斗技能--------------------------

Human_skill_combat = oo.class(Human_skill_obj,"Human_skill_combat")

function Human_skill_combat:__init(skill_id, type)
	Human_skill_obj.__init(self, skill_id, type)

	self.ak = _sk_config._skill_p[self.cmd_id][self.level][2]			--攻击力
	self.ak_class = _sk_config._skill[self.cmd_id][4] or 1			--技能伤害类型
	self.cd = _sk_config._skill[self.cmd_id][1]
	self.mp = _sk_config._skill_p[self.cmd_id][self.level][1] --耗魔
end

function Human_skill_combat:get_mp()
	return self.mp
end

function Human_skill_combat:effect(obj_s,obj_d)
	local new_pkt = self:make_hp_pkt(obj_s, obj_d, self.ak, self.ak_class)  --计算伤害
	local hp = math.floor(-new_pkt.hp)
	obj_d:del_hp(hp)
	obj_s:del_mp(self.mp)
	return hp, new_pkt[1]
end



--战斗血魔变化pkt, ak 技能攻击力 dg_type 伤害类型(nil or 1,物理攻击 2，魔法攻击 )
function Human_skill_combat:make_hp_pkt(obj_s, obj_d, ak, dg_type)
	--print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>", self.id, self.cmd_id, dg_type)
	local damage_expr
	if dg_type == nil or dg_type == 1 then
		damage_expr = _expr.human_s_damage
	elseif dg_type == 2 then
		damage_expr = _expr.human_m_damage
	end
			
	local new_pkt = {}
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

--被动技能
Human_skill_passive = oo.class(Human_skill_obj,"Human_skill_passive")

function Human_skill_passive:__init(skill_id, type)
	Human_skill_obj.__init(self, skill_id, type)
end



