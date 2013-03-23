local _expr = require("config.expr")
local _sk_config = require("config.skill_combat_config")



Skill_1004600 = oo.class(Skill_combat, "Skill_1004600")

function Skill_1004600:__init(cmd_id, lv)
	Skill_combat.__init(self, cmd_id, SKILL_GOOD, SKILL_OBJ_1004600, lv)
	self.scope 		= _sk_config._skill_p[SKILL_OBJ_1004600][lv][2]
	self.per 		= _sk_config._skill_p[SKILL_OBJ_1004600][lv][3]
	self.hp 		= _sk_config._skill_p[SKILL_OBJ_1004600][lv][4]
end

--param.des_id
function Skill_1004600:effect(sour_id, param)
	--print("Skill_1004600:effect(sour_id, param)", sour_id, j_e(param))
	local obj_s = g_obj_mgr:get_obj(sour_id)
	if obj_s == nil then 
		return 21101 
	end

	local scene_o = obj_s:get_scene_obj()
	local map_obj = scene_o:get_map_obj()
	local scene_mode = scene_o:get_mode()
	local obj_list = {}
	obj_list = map_obj:scan_human_and_guard_rect(obj_s:get_pos(), self.scope, 12)
	obj_list[sour_id] = nil

	obj_s:on_useskill(self.id, nil, 0)
	self:send_syn(obj_s, obj_s:get_id(), nil, 2)  --技能同步
	for k,v in pairs(obj_list or {}) do
		local obj_d = g_obj_mgr:get_obj(k)
		if obj_d ~= nil then
			local ret = obj_d:on_beskill(self.id, obj_s)
			if ret == 2 then
				local hp = self.hp

				local new_pkt = {}
				new_pkt.obj_id = k
				new_pkt.type = 0
				new_pkt.hp = hp
				new_pkt.mp = 0
				new_pkt.hp = new_pkt.hp + math.floor(self.per * obj_d:get_max_hp())
				--print("==>new_pkt.hp:",new_pkt.hp,"self.per",self.per,"obj_d:get_hp()",obj_d:get_hp())
				obj_d:add_hp(new_pkt.hp)
				--obj_d:on_useskill(self.id, obj_s, hp)
				self:send_syn(obj_s, k, new_pkt, ret)

			elseif ret == 1 then
				self:send_syn(obj_s, obj_s:get_id(), nil, ret)
			end
		end
	end

	return 0
end

f_create_monster_skill_class("SKILL_OBJ_10046%02d", "Skill_10046%02d")
