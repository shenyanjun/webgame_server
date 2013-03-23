
--local debug_print = print
local debug_print = function() end
local _expr = require("config.expr")
local _sk_config = require("config.skill_combat_config")

--噬灵蛊
Skill_512100 = oo.class(Skill_combat, "Skill_512100")

function Skill_512100:__init(cmd_id, lv)
	Skill_combat.__init(self, cmd_id, SKILL_BAD, SKILL_OBJ_512100, lv)
	self.mp_per = _sk_config._skill_p[SKILL_OBJ_512100][lv][2]
end
--param.des_id
function Skill_512100:effect(sour_id, param)
	if param.des_id == nil then return 21101 end
	local obj_s = g_obj_mgr:get_obj(sour_id)
	local obj_d = g_obj_mgr:get_obj(param.des_id)
	if obj_s == nil or obj_d == nil then 
		return 21101 
	end
	if sour_id ~= param.des_id and not self:is_validate_dis(obj_s, obj_d) then
		return 21131
	end

	local scene_o = obj_s:get_scene_obj()
	local md_ret = scene_o:is_attack(sour_id, param.des_id)
	if md_ret ~= 0 then
		return md_ret
	end

	--对怪无效
	if obj_d:get_type() ~= OBJ_TYPE_HUMAN then 
		return 21133
	end
	
	local ret = obj_d:on_beskill(self.id, obj_s)
	if ret == 2 then
		local mp = (obj_d:get_max_mp()*self.mp_per)
		local new_pkt = {}
		new_pkt.obj_id = param.des_id
		new_pkt.type = 0
		new_pkt.hp = 0
		new_pkt.mp = mp <= obj_d:get_mp() and -mp or -obj_d:get_mp()

		obj_d:add_mp(new_pkt.mp)
		obj_s:on_useskill(self.id, obj_d, new_pkt.hp)
		self:send_syn(obj_s, param.des_id, new_pkt, ret)
		return 0
	elseif ret == 1 then
		self:send_syn(obj_s, param.des_id, nil, ret)
		return 0
	end
	return 21102
end

f_create_skill_class("SKILL_OBJ_5121%02d", "Skill_5121%02d")
