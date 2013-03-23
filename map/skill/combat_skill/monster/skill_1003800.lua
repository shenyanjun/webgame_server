
local debug_print = function() end
local _sk_config = require("config.skill_combat_config")


--棋子爆炸(扇形AOE)
Skill_1003800 = oo.class(Skill_combat, "Skill_1003800")

function Skill_1003800:__init(cmd_id, lv)
	Skill_combat.__init(self, cmd_id, SKILL_BAD, SKILL_OBJ_1003800, lv)
	-- 范围
	self.scope 		= _sk_config._skill_p[SKILL_OBJ_1003800][lv][2]
	self.addition 	= _sk_config._skill_p[SKILL_OBJ_1003800][lv][3]
end

--param.des_id
function Skill_1003800:effect(sour_id, param)
	--print("Skill_1003800:effect")
	local obj_s = g_obj_mgr:get_obj(sour_id)
	if obj_s == nil or sour_id == param.des_id then 
		return 21101 
	end

	local scene_o = obj_s:get_scene_obj()
	local map_obj = scene_o:get_map_obj()
	local scene_mode = scene_o:get_mode()
	local obj_list = {}
	if scene_mode == SCENE_MODE.SIDE then
		return 21101
	else
		obj_list = map_obj:scan_obj_rect(obj_s:get_pos(), self.scope, OBJ_TYPE_MONSTER, 20)
	end
	obj_list[sour_id] = nil

	obj_s:on_useskill(self.id, nil, 0)
	self:send_syn(obj_s, obj_s:get_id(), nil, 2)  --技能同步

	for k,v in pairs(obj_list) do
		local obj_o = g_obj_mgr:get_obj(k)
		if obj_o ~= nil and scene_o:is_attack(sour_id, k) == 0 then
			local ret = obj_o:on_beskill(self.id, obj_s)
			if ret == 2 then
				local new_pkt = self:make_hp_pkt(obj_s, obj_o, self.ak or 0)
				local new_pkt = {}
				new_pkt[1] = 0
				new_pkt[2]= obj_o:get_id()
				new_pkt[3] = -self.addition
				new_pkt[4] = 0
				new_pkt.hp = new_pkt[3]
				if obj_o:on_damage(new_pkt.hp, obj_s, self.id) then
					self:send_syn(obj_s, k, new_pkt, ret)					
				end
			elseif ret == 1 then
			end
		end
	end
	return 0
end


f_create_monster_skill_class("SKILL_OBJ_10038%02d", "Skill_10038%02d")


