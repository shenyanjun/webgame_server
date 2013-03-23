
--local debug_print = print
local debug_print = function() end
local _expr = require("config.expr")


--怪物远程魔法攻击
Skill_1001100 = oo.class(Skill_combat, "Skill_1001100")

function Skill_1001100:__init(cmd_id, lv)
	Skill_combat.__init(self, cmd_id, SKILL_BAD, SKILL_OBJ_1001100, lv)
	--self.ak = 0
end
--param.des_id
function Skill_1001100:effect(sour_id, param)
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
		local new_pkt = self:make_hp_pkt(obj_s, obj_d, 0, 2)
		obj_s:on_useskill(self.id, obj_d, new_pkt.hp)
		if obj_d:on_damage(new_pkt.hp, obj_s, self.id) then
			self:send_syn(obj_s, param.des_id, new_pkt, ret)
		end
		
		debug_print("Skill_1001100:effect", sour_id, param.des_id, 0)
		return 0
	elseif ret == 1 then
		self:send_syn(obj_s, param.des_id, nil, ret)
		return 0
	end
	return 21102
end


f_create_monster_skill_class("SKILL_OBJ_10011%02d", "Skill_10011%02d")
