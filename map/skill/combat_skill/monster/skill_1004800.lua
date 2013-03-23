--狼普通攻击
Skill_1004800 = oo.class(Skill_combat, "Skill_1004800")

function Skill_1004800:__init(cmd_id, lv)
	Skill_combat.__init(self, cmd_id, SKILL_BAD, SKILL_OBJ_1004800, lv)
end
--param.des_id
function Skill_1004800:effect(sour_id, param)
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
		if obj_d:get_type() == OBJ_TYPE_HUMAN then
			obj_s:on_useskill(self.id, obj_d, 0)
			local scene = obj_d:get_scene_obj()
			if scene and SCENE_TYPE.SHEEP == scene:get_type() then
				local _ = scene:be_attack(param.des_id, sour_id)
				self:send_syn(obj_s, param.des_id, new_pkt, 1)
			end
		end
		return 0
	elseif ret == 1 then
		self:send_syn(obj_s, param.des_id, nil, ret)
		return 0 
	end
	return 21102
end

f_create_monster_skill_class("SKILL_OBJ_10048%02d", "Skill_10048%02d")