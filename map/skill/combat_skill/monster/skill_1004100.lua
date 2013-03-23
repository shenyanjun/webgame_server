
local _sk_config = require("config.skill_combat_config")
local _ip = require("impact.impact_process")


--怪物对人/怪加buff技能
Skill_1004100 = oo.class(Skill_combat, "Skill_1004100")

function Skill_1004100:__init(cmd_id, lv)
	Skill_combat.__init(self, cmd_id, SKILL_GOOD, SKILL_OBJ_1004100, lv)
	-- 范围
	self.buff_id = _sk_config._skill_p[SKILL_OBJ_1004100][lv][2]
	self.time 	= _sk_config._skill_p[SKILL_OBJ_1004100][lv][3]
	self.per 	= _sk_config._skill_p[SKILL_OBJ_1004100][lv][4]
	self.val 	= _sk_config._skill_p[SKILL_OBJ_1004100][lv][5]
	self.range  = _sk_config._skill_p[SKILL_OBJ_1004100][lv][6]
	self.target_type  = _sk_config._skill_p[SKILL_OBJ_1004100][lv][7]
end
--param.des_id
function Skill_1004100:effect(sour_id, param)
	--print("Skill_1004100:effect()", sour_id, j_e(param))
	if param.des_id == nil or sour_id == nil then return 21101 end
	local obj_s = g_obj_mgr:get_obj(sour_id)
	local obj_d = g_obj_mgr:get_obj(param.des_id)
	if obj_s == nil or obj_d == nil then 
		return 21101
	end
	if not self:is_validate_dis(obj_s, obj_d) then
		return 21131
	end
	
	local oth_side = obj_s:get_side() == 1 and 2 or 1
	local scene_o = obj_s:get_scene_obj()
	local map_obj = scene_o:get_map_obj()
	local obj_list = map_obj:monster_scan_obj_side(obj_s:get_pos(), self.range, 50, oth_side)
	obj_list[sour_id] = nil
	
	for k,v in pairs(obj_list) do
		local obj_o = g_obj_mgr:get_obj(k)
		if obj_o ~= nil and (self.target_type == nil or self.target_type == Obj_mgr.obj_type(k)
			or (Obj_mgr.obj_type(k) == OBJ_TYPE_PET and self.target_type == 1)) then
			local ret = obj_o:on_beskill(self.id, obj_s)
			if ret == 2 then	
				for i, buff_id in ipairs(self.buff_id) do
					local impact_o = _G[string.format("Impact_%d", buff_id)](k)
					if obj_o:on_beimpact(impact_o:get_cmd_id(), obj_s) == 1 then
						local p2 = {}
						p2.per = self.per[i]
						p2.val = self.val[i]
						impact_o:set_count(self.time / impact_o.sec_count)
						impact_o:effect(p2)
					end
				end
				self:send_syn(obj_s, k, nil, ret)
			end
		end
	end

	return 0
end


f_create_monster_skill_class("SKILL_OBJ_10041%02d", "Skill_10041%02d")


