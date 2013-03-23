
local debug_print = function() end
local _expr = require("config.expr")
local _sk_config = require("config.skill_combat_config")
local _random = crypto.random

--回血
Skill_1002200 = oo.class(Skill_combat, "Skill_1002200")

function Skill_1002200:__init(cmd_id, lv)
	Skill_combat.__init(self, cmd_id, SKILL_GOOD, SKILL_OBJ_1002200, lv)
	self.per = _sk_config._skill_p[SKILL_OBJ_1002200][lv][2] or 0
	self.hp = _sk_config._skill_p[SKILL_OBJ_1002200][lv][3] or 0
end
--param.des_id
function Skill_1002200:effect(sour_id, param)
	local obj_s = g_obj_mgr:get_obj(sour_id)
	if obj_s == nil then 
		return 21101 
	end
	
	local ret = obj_s:on_beskill(self.id, obj_s)
	if ret == 2 then
		local hp = self.hp

		local new_pkt = {}
		new_pkt.obj_id = param.des_id
		new_pkt.type = 0
		new_pkt.hp = hp
		new_pkt.mp = 0

		local obj_d = g_obj_mgr:get_obj(param.des_id)
		if not obj_d then
			return 21101
		end
		new_pkt.hp = new_pkt.hp + math.floor(self.per * obj_d:get_max_hp())
		--print("==>new_pkt.hp:",new_pkt.hp,"self.per",self.per,"obj_d:get_max_hp()",obj_d:get_max_hp())
		obj_d:add_hp(new_pkt.hp)
		obj_d:on_useskill(self.id, obj_s, hp)
		self:send_syn(obj_s, param.des_id, new_pkt, ret)

		return 0
	elseif ret == 1 then
		self:send_syn(obj_s, obj_s:get_id(), nil, ret)
		return 0
	end
	return 21102
end

f_create_monster_skill_class("SKILL_OBJ_10022%02d", "Skill_10022%02d")