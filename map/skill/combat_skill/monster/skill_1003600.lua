
local debug_print = function() end
local _expr = require("config.expr")
local _sk_config = require("config.skill_combat_config")
local _ip = require("impact.impact_process")


--怪物对人加buff技能
Skill_1003600 = oo.class(Skill_combat, "Skill_1003600")

function Skill_1003600:__init(cmd_id, lv)
	Skill_combat.__init(self, cmd_id, SKILL_BAD, SKILL_OBJ_1003600, lv)
	-- 范围
	self.buff_id = _sk_config._skill_p[SKILL_OBJ_1003600][lv][2]
	self.time 	= _sk_config._skill_p[SKILL_OBJ_1003600][lv][3]
	self.per 	= _sk_config._skill_p[SKILL_OBJ_1003600][lv][4]
	self.val 	= _sk_config._skill_p[SKILL_OBJ_1003600][lv][5]
	self.range  = _sk_config._skill_p[SKILL_OBJ_1003600][lv][6]
end
--param.des_id
function Skill_1003600:effect(sour_id, param)
	--print("Skill_1003600:effect()", sour_id, j_e(param))
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
		if obj_o ~= nil and Obj_mgr.obj_type(k) == OBJ_TYPE_HUMAN then
			local ret = obj_o:on_beskill(self.id, obj_s)
			if ret == 2 then
				if self.buff_id == 1311 then
					local impact_o = Impact_1311(k)
					if obj_o:on_beimpact(impact_o:get_cmd_id(), obj_s) == 1 then
						local p2 = {}
						p2.sp_per = self.per
						impact_o:set_count(self.time)
						impact_o:effect(p2)
					end
				elseif self.buff_id == 5151 then
					if k ~= param.des_id then
						local impact_o = _G[string.format("Impact_%d", param.buff_id[param.ran+1])](k)
						if obj_o:on_beimpact(impact_o:get_cmd_id(), obj_s) == 1 then
							local p2 = {}
							p2.per = self.per
							p2.val = self.val[param.ran+1]
							impact_o:set_count(self.time / impact_o.sec_count)
							impact_o:effect(p2)
						end
						param.ran = (param.ran + 1) % 4
					end
				elseif _ip.impact_type(self.buff_id) == IMPACT_CHANGE then
					f_add_change_buff(param.buff_id or self.buff_id, obj_o, (param.val or self.val) + (param.val_plus or 0), param.time or self.time)
				elseif _ip.impact_type(self.buff_id) == IMPACT_BUFF then
					f_add_buff_impact(obj_o, param.buff_id or self.buff_id, param.per or self.per, param.val or self.val, param.time or self.time)
				else
					local impact_o = _G[string.format("Impact_%d", self.buff_id)](k)
					if obj_o:on_beimpact(impact_o:get_cmd_id(), obj_s) == 1 then
						local p2 = {}
						p2.per = self.per
						p2.val = self.val
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


f_create_monster_skill_class("SKILL_OBJ_10036%02d", "Skill_10036%02d")


