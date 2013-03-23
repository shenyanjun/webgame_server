
local _expr = require("config.expr")
local _sk_config = require("config.skill_combat_config")

--群体AOE  附加值+人物等级*系数的雷攻伤害(只对怪有作用)
Skill_990100 = oo.class(Skill_combat, "Skill_990100")

function Skill_990100:__init(cmd_id, lv)
	Skill_combat.__init(self, cmd_id, SKILL_BAD, SKILL_OBJ_990100, lv)
	self.ak = _sk_config._skill_p[SKILL_OBJ_990100][lv][2]
	self.h_p1 = _sk_config._skill_p[SKILL_OBJ_990100][lv][3]
	self.h_p2 = _sk_config._skill_p[SKILL_OBJ_990100][lv][4]
	self.m_p = _sk_config._skill_p[SKILL_OBJ_990100][lv][5]
	self.reflex_per = _sk_config._skill_p[SKILL_OBJ_990100][lv][6]
end
--param.des_id
function Skill_990100:effect(sour_id, param)

	local obj_s = g_obj_mgr:get_obj(sour_id)
	local obj_d = g_obj_mgr:get_obj(param.des_id)
	if obj_s == nil or obj_d == nil then 
		return 21101 
	end
	if not self:is_validate_dis(obj_s, obj_d) then
		return 21131
	end
	
	local scene_o = obj_s:get_scene_obj()
	local md_ret = scene_o:is_attack(sour_id, param.des_id)
	if md_ret ~= 0 then
		return md_ret
	end
	local ret = obj_d:on_beskill(self.id, obj_s)
	if ret == 2 then
		local hp_per = obj_d:get_hp() / obj_d:get_max_hp()
		local new_pkt = nil
		if obj_d:get_type() ~= OBJ_TYPE_HUMAN then
			if hp_per <= self.m_p then
				new_pkt = self:make_hp_pkt_2(param.des_id, -obj_d:get_hp()-10)
			else
				--套装附加攻击
				local set_l = obj_s:get_set_effect(SKILL_ADD_ATTACK, SKILL_OBJ_990100)
				local ak = self.ak + set_l[1] + self.ak*set_l[2]
				new_pkt = self:make_hp_pkt(obj_s, obj_d, ak)
			end
		else
			--if hp_per <= self.h_p1 and hp_per >= self.h_p2 then
				--new_pkt = self:make_hp_pkt_3(obj_s, obj_d, -obj_d:get_hp()-10)
			--else
				--套装附加攻击
				local set_l = obj_s:get_set_effect(SKILL_ADD_ATTACK, SKILL_OBJ_990100)
				local ak = self.ak + set_l[1] + self.ak*set_l[2]
				new_pkt = self:make_hp_pkt(obj_s, obj_d, ak)
				--
				--local reflex_damage = math.floor(obj_d:get_hp() * self.reflex_per)
				--obj_s:on_damage(reflex_damage, obj_d, nil)
				--f_add_buff_impact(obj_s, 2026, -0.1, 0, 30)
			--end
		end
		obj_s:on_useskill(self.id, obj_d, new_pkt.hp)
		if obj_d:on_damage(new_pkt.hp, obj_s, self.id) then
			self:send_syn(obj_s, param.des_id, new_pkt, ret)
		end
		
		--print("Skill_110000:effect", sour_id, param.des_id, ak)
		return 0
	elseif ret == 1 then
		self:send_syn(obj_s, param.des_id, nil, ret)
		return 0
	end
	return 21002
end

f_create_skill_class("SKILL_OBJ_9901%02d", "Skill_9901%02d")


