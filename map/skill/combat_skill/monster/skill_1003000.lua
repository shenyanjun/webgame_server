
local debug_print = function() end
local _expr = require("config.expr")
local _sk_config = require("config.skill_combat_config")
local _random = crypto.random

--召唤炸弹怪 扔向固定N个位置
Skill_1003000 = oo.class(Skill_combat, "Skill_1003000")

function Skill_1003000:__init(cmd_id, lv)
	Skill_combat.__init(self, cmd_id, SKILL_GOOD, SKILL_OBJ_1003000, lv)

	self.monster_id = _sk_config._skill_p[SKILL_OBJ_1003000][lv][2]
	self.monster_count = _sk_config._skill_p[SKILL_OBJ_1003000][lv][3]
	self.monster_time = _sk_config._skill_p[SKILL_OBJ_1003000][lv][4]
	self.monster_skill = _sk_config._skill_p[SKILL_OBJ_1003000][lv][5]
	self.monster_pos_list = table.copy(_sk_config._skill_p[SKILL_OBJ_1003000][lv][6])

	--self.monster_count = math.min(self.monster_count, #self.monster_pos_list)
end
--param.des_id
function Skill_1003000:effect(sour_id, param)
	local obj_s = g_obj_mgr:get_obj(sour_id)
	if obj_s == nil then 
		return 21101 
	end
	
	local ret = obj_s:on_beskill(self.id, obj_s)
	if ret == 2 then
		--召唤 从self.monster_pos_list中随机选self.monster_count个位置
		local m_param = {self.monster_time, sour_id, self.monster_skill}
		local attack_id = obj_s:get_attack_id()
		local scene_d = obj_s:get_scene()
		local pos_count = 0		-- 已选中的元素个数
		local pos_list_size = #self.monster_pos_list
		local pos_pre = math.floor(self.monster_count / pos_list_size * 100)	-- 每个元素被选中的概率
		for i=1, pos_list_size do
			--debug_print("====>pos_count", pos_count, "i:", i)
			if pos_count < self.monster_count 
			and (_random(0, 100) < pos_pre or (pos_list_size - i < self.monster_count - pos_count)) then
				local pos = {}
				pos[1] = self.monster_pos_list[i][1]
				pos[2] = self.monster_pos_list[i][2]
				local map_o = obj_s:get_scene_obj():get_map_obj()
				if map_o:is_clog_pos(pos) then
					local obj = g_obj_mgr:create_monster(self.monster_id, pos, scene_d, m_param)
					g_scene_mgr_ex:enter_scene(obj)
					pos_count = pos_count + 1
					if attack_id ~= nil then
						obj:add_enemy_obj(attack_id, nil)
					end
				end
			end
		end

		obj_s:on_useskill(self.id, obj_s, hp)
		self:send_syn(obj_s, obj_s:get_id(), nil, ret)
		return 0
	elseif ret == 1 then
		self:send_syn(obj_s, obj_s:get_id(), nil, ret)
		return 0
	end
	return 21102
end

f_create_monster_skill_class("SKILL_OBJ_10030%02d", "Skill_10030%02d")