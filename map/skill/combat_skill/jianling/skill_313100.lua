
--local debug_print = print
local debug_print = function() end
local _expr = require("config.expr")
local _sk_config = require("config.skill_combat_config")

--霜天雪舞 
Skill_313100 = oo.class(Skill_combat, "Skill_313100")

function Skill_313100:__init(cmd_id, lv)
	Skill_combat.__init(self, cmd_id, SKILL_BAD, SKILL_OBJ_313100, lv)
	self.ak = _sk_config._skill_p[SKILL_OBJ_313100][lv][2]
	self.dis = _sk_config._skill_p[SKILL_OBJ_313100][lv][3]       --击退距离
end
--param.des_id
function Skill_313100:effect(sour_id, param)
	if param.des_id == nil or sour_id == param.des_id then return 21101 end
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
		--击退
		local map_obj = scene_o:get_map_obj()
		local pos = obj_s:get_pos()
		local des_pos = obj_d:get_pos()
		local new_pos = map_obj:find_far_pos(pos, des_pos, self.dis)
		if new_pos ~= nil then
			obj_d:modify_pos(new_pos)
			scene_o:send_move_soon_syn(param.des_id, obj_d, des_pos, new_pos, 2)
		end

		--伤害
		local ak = obj_s:get_s_attack() + self.ak
		local new_pkt = self:make_hp_pkt(obj_s, obj_d, ak)
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


f_create_skill_class("SKILL_OBJ_3131%02d", "Skill_3131%02d")
