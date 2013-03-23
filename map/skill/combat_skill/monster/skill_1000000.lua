
local debug_print = function() end
local _expr = require("config.expr")


--怪物物理攻击
Skill_1000000 = oo.class(Skill_combat, "Skill_1000000")

function Skill_1000000:__init(cmd_id, lv)
	Skill_combat.__init(self, cmd_id, SKILL_BAD, SKILL_OBJ_1000000, lv)
end
--param.des_id
function Skill_1000000:effect(sour_id, param)
	if param.des_id == nil or sour_id == param.des_id then return 21101 end
	local obj_s = g_obj_mgr:get_obj(sour_id)
	local obj_d = g_obj_mgr:get_obj(param.des_id)
	if obj_s == nil or obj_d == nil then 
		return 21101 
	end

	local scene_o = obj_s:get_scene_obj()
	local md_ret = scene_o:is_attack(sour_id, param.des_id)
	if md_ret ~= 0 then
		return md_ret
	end

	local ret = obj_d:on_beskill(self.id, obj_s)
	if ret == 2 then
		local new_pkt = self:make_hp_pkt(obj_s, obj_d, 0)
		obj_s:on_useskill(self.id, obj_d, new_pkt.hp)
		if obj_d:on_damage(new_pkt.hp, obj_s, self.id) then
			self:send_syn(obj_s, param.des_id, new_pkt, ret)
		end
		return 0
	elseif ret == 1 then
		self:send_syn(obj_s, param.des_id, nil, ret)
		return 0 
	end
	return 21102
end

f_create_monster_skill_class("SKILL_OBJ_10000%02d", "Skill_10000%02d")

--[[--1级
Skill_1000001 = oo.class(Skill_1000000, "Skill_1000001")

function Skill_1000001:__init()
	Skill_1000000.__init(self, SKILL_OBJ_1000001, 1)
end

--2级
Skill_1000002 = oo.class(Skill_1000000, "Skill_1000002")

function Skill_1000002:__init()
	Skill_1000000.__init(self, SKILL_OBJ_1000002, 2)
end

--3
Skill_1000003 = oo.class(Skill_1000000, "Skill_1000003")

function Skill_1000003:__init()
	Skill_1000000.__init(self, SKILL_OBJ_1000003, 3)
end

--4
Skill_1000004 = oo.class(Skill_1000000, "Skill_1000004")

function Skill_1000004:__init()
	Skill_1000000.__init(self, SKILL_OBJ_1000004, 4)
end

--5
Skill_1000005 = oo.class(Skill_1000000, "Skill_1000005")

function Skill_1000005:__init()
	Skill_1000000.__init(self, SKILL_OBJ_1000005, 5)
end]]


