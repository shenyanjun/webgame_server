
local debug_print = function() end
local _expr = require("config.expr")
local _sk_config = require("config.skill_combat_config")
local _attr = require("config.attr_config")

--变羊
Skill_1003200 = oo.class(Skill_combat, "Skill_1003200") 

function Skill_1003200:__init(cmd_id, lv)
	Skill_combat.__init(self, cmd_id, SKILL_BAD, SKILL_OBJ_1003200, lv)
	-- 时间
	self.sec = _sk_config._skill_p[SKILL_OBJ_1003200][lv][2]
	self.range = _sk_config._skill_p[SKILL_OBJ_1003200][lv][3]
	--print("======>enter Skill_1003200")
end

--param.des_id
function Skill_1003200:effect(sour_id, param)
	--print("======>enter Skill_1003200:effect")
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
	local map_obj = scene_o:get_map_obj()
	local obj_list = map_obj:monster_scan_obj_rect(obj_d:get_pos(), self.range, 6)
	obj_list[sour_id] = nil

	obj_s:on_useskill(self.id, nil, 0)
	self:send_syn(obj_s, obj_s:get_id(), nil, 2)  --技能同步

	for k,v in pairs(obj_list) do
		local obj_o = g_obj_mgr:get_obj(k)
		if obj_o ~= nil and scene_o:is_attack(sour_id, k) == 0 then
			local ret = obj_o:on_beskill(self.id, obj_s)
			if ret == 2 then
				--变形效果
				local impact_o = Impact_1501(k)
				if obj_d:on_beimpact(impact_o:get_cmd_id(), obj_s) == 1 then
					param.metamorphosis = _attr.metamorphosis[3]
					impact_o:set_count(self.sec)   
					impact_o:effect(param)
				else
					impact_o:immune()
				end

				self:send_syn(obj_s, param.des_id, nil, ret)

			elseif ret == 1 then
			end
		end
	end
	return 0

end


f_create_monster_skill_class("SKILL_OBJ_10032%02d", "Skill_10032%02d")


