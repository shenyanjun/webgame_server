
local debug_print = function() end
local _expr = require("config.expr")
local _sk_config = require("config.skill_combat_config")


--法力燃烧(AOE扣法)
Skill_1003100 = oo.class(Skill_combat, "Skill_1003100") 

function Skill_1003100:__init(cmd_id, lv)
	Skill_combat.__init(self, cmd_id, SKILL_BAD, SKILL_OBJ_1003100, lv)
	-- 燃烧范围
	self.area = _sk_config._skill_p[SKILL_OBJ_1003100][lv][2]
	-- 燃烧百分比
	self.per = _sk_config._skill_p[SKILL_OBJ_1003100][lv][3]
	-- 扣法力
	self.addition = _sk_config._skill_p[SKILL_OBJ_1003100][lv][4]
end

--param.des_id
function Skill_1003100:effect(sour_id, param)
	--print("======>enter Skill_1003100:effect")
	local obj_s = g_obj_mgr:get_obj(sour_id)
	if obj_s == nil then 
		return 21101 
	end

	local scene_o = obj_s:get_scene_obj()
	local map_obj = scene_o:get_map_obj()
	local obj_list = map_obj:monster_scan_obj_rect(obj_s:get_pos(), self.area, 6)
	obj_list[sour_id] = nil

	obj_s:on_useskill(self.id, nil, 0)
	self:send_syn(obj_s, obj_s:get_id(), nil, 2)  --技能同步

	for k,v in pairs(obj_list) do
		local obj_o = g_obj_mgr:get_obj(k)
		if obj_o ~= nil and scene_o:is_attack(sour_id, k) == 0 then
			local ret = obj_o:on_beskill(self.id, obj_s)
			if ret == 2 then
				local new_pkt = self:make_mp_pkt(obj_s, obj_o, self.per, self.addition)
				if obj_o:on_damage_mp(new_pkt.mp, obj_s, self.id) then
					self:send_syn(obj_s, k, new_pkt, ret)
				end
			elseif ret == 1 then
			end
		end
	end
	return 0
end

function Skill_1003100:make_mp_pkt(obj_s, obj_d, per, addition)
	local new_pkt = {}

	new_pkt[1] = 0
	new_pkt[2]= obj_d:get_id()
	new_pkt[3] = 0
	new_pkt[4] = 0

	new_pkt[3] = -obj_d:get_mp() * per - addition

	new_pkt.mp = new_pkt[3]  
	return new_pkt,new_pkt[3]
end

f_create_monster_skill_class("SKILL_OBJ_10031%02d", "Skill_10031%02d")


