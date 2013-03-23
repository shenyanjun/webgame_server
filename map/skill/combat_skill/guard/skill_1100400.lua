

local _sk_config = require("config.skill_combat_config")

--TD守卫 佛光普照
Skill_1100400 = oo.class(Skill_combat, "Skill_1100400")

function Skill_1100400:__init(cmd_id, lv)
	Skill_combat.__init(self, cmd_id, SKILL_BAD, SKILL_OBJ_1100400, lv)
	
	self.per = _sk_config._skill_p[SKILL_OBJ_1100400][lv][2]
	self.val = _sk_config._skill_p[SKILL_OBJ_1100400][lv][3]
end
--param nil
function Skill_1100400:effect(sour_id, param)
	if param.des_id == nil then return 21101 end
	local obj_s = g_obj_mgr:get_obj(sour_id)
	local obj_d = g_obj_mgr:get_obj(param.des_id)
	if obj_s == nil or obj_d == nil then 
		return 21101 
	end

	local team_id = obj_d:get_team()
	local team_obj = g_team_mgr:get_team_obj(team_id)
	--if team_obj == nil then return 21134 end
	
	local scene_o = obj_s:get_scene_obj()
	local map_obj = scene_o:get_map_obj()

	local list
	if team_obj == nil then
		list = {}
		list[param.des_id] = 1
	else
		list = team_obj:get_team_l()
	end

	obj_s:on_useskill(self.id, nil, 0)
	for k,_ in pairs(list) do
		local obj_d = g_obj_mgr:get_obj(k)
		if obj_d ~= nil and map_obj:distance(obj_s:get_pos(), obj_d:get_pos()) < _sk_config._skill[self.id][1] + 3 then
			local ret = obj_d:on_beskill(self.id, obj_s)
			if ret == 2 then
				local hp = math.floor(obj_d:get_max_hp() * self.per + self.val)
				--human
				if obj_d:is_alive() then
					local new_pkt = {}
					new_pkt.obj_id = k
					new_pkt.type = 0
					new_pkt.mp = 0
					new_pkt.hp = hp
					obj_d:add_hp(hp)
					self:send_syn(obj_s, k, new_pkt, ret)
				end

				--pet
				local pet_con = obj_d:get_pet_con()
				local pet_obj = pet_con:get_combat_pet()
				if pet_obj ~= nil then
					local new_pkt = {}
					new_pkt.obj_id = pet_obj:get_id()
					new_pkt.type = 0
					new_pkt.hp = hp
					new_pkt.mp = 0
					pet_obj:add_hp(hp)
					self:send_syn(obj_s, pet_obj:get_id(), new_pkt, ret)
				end
			elseif ret == 1 then
				self:send_syn(obj_s, k, nil, ret)
			end
		end
	end

	return 0
end

f_create_monster_skill_class("SKILL_OBJ_11004%02d", "Skill_11004%02d")
