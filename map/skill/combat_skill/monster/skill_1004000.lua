
local _expr = require("config.expr")
local _sk_config = require("config.skill_combat_config")


--属性AOE攻击
Skill_1004000 = oo.class(Skill_combat, "Skill_1004000")

function Skill_1004000:__init(cmd_id, lv)
	Skill_combat.__init(self, cmd_id, SKILL_BAD, SKILL_OBJ_1004000, lv)
	-- 范围
	self.scope 		= _sk_config._skill_p[SKILL_OBJ_1004000][lv][2]
	self.aoe_type 	= _sk_config._skill_p[SKILL_OBJ_1004000][lv][3]
	self.val 		= _sk_config._skill_p[SKILL_OBJ_1004000][lv][4]
	self.attack_monster = _sk_config._skill_p[SKILL_OBJ_1004000][lv][5]
end
--param.des_id
function Skill_1004000:effect(sour_id, param)
	local obj_s = g_obj_mgr:get_obj(sour_id)
	if obj_s == nil then 
		return 21101 
	end

	local scene_o = obj_s:get_scene_obj()
	local map_obj = scene_o:get_map_obj()
	local scene_mode = scene_o:get_mode()
	local obj_list = {}
	if scene_mode == SCENE_MODE.SIDE or self.attack_monster then
		local myside = obj_s:get_side() == 0 and 1 or obj_s:get_side()
		obj_list = map_obj:monster_scan_obj_side(obj_s:get_pos(), self.scope, 6, myside)
	else
		obj_list = map_obj:monster_scan_obj_rect(obj_s:get_pos(), self.scope, 6)
	end
	obj_list[sour_id] = nil

	obj_s:on_useskill(self.id, nil, 0)
	self:send_syn(obj_s, obj_s:get_id(), nil, 2)  --技能同步

	for k,v in pairs(obj_list) do
		local obj_o = g_obj_mgr:get_obj(k)
		if obj_o ~= nil and scene_o:is_attack(sour_id, k) == 0 and k ~= param.except_id then
			local ret = obj_o:on_beskill(self.id, obj_s)
			if ret == 2 then
				local new_pkt = self:make_hp_pkt(obj_s, obj_o, self.val, self.aoe_type)
				if obj_o:on_damage(new_pkt.hp, obj_s, self.id) then
					self:send_syn(obj_s, k, new_pkt, ret)
				end
			elseif ret == 1 then
			end
		end
	end
	return 0
end

function Skill_1004000:make_hp_pkt(obj_s, obj_d, ak, dg_type)
	--print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>", self.id, self.cmd_id, dg_type)

	local new_pkt = {}
	new_pkt[1] = 0
	new_pkt[2] = obj_d:get_id()
	new_pkt[3] = 0
	new_pkt[4] = 0

	if _expr.human_miss(obj_s, obj_d) then
		--miss
		new_pkt[1] = 1    --miss
	else
		ak = math.floor(ak)
		new_pkt[3],new_pkt[1] = _expr.quality_damage(obj_s, obj_d, dg_type, ak)
	end

	new_pkt.hp = new_pkt[3]  --兼容老代码
	return new_pkt,new_pkt[3]
end

f_create_monster_skill_class("SKILL_OBJ_10040%02d", "Skill_10040%02d")


