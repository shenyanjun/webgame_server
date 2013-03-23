
local debug_print = function() end --print
--local debug_print = print
local _ai_param = require("config.ai_config")
local _random = crypto.random

------守卫ai---------
Ai_monster_guard = oo.class(Ai_monster, "Ai_monster_guard")

function Ai_monster_guard:__init(obj, lv)
	Ai_monster.__init(self, obj, lv)
end

--查找可攻击的玩家(子类重载)
function Ai_monster_guard:on_find_enemy()
	local eny_l = self.obj.ai_enemy:get_list()
	local scene_o = self.obj:get_scene_obj()

	local b = false
	local obj
	for k,v in pairs(eny_l) do
		obj = self:validate_obj(v.obj_id) 
		if obj ~= nil then
			self.att_obj_id = obj:get_id()
			b = true
			break	
		end
	end

	if b then     --仇恨列表搜索到敌人
		return obj
	else          --重新扫描
		local obj_id = self:scan_one_obj()
		return self:validate_obj(obj_id) 
	end
end

--[[function Ai_monster_guard:is_go_home()
	return false
end]]

--------------event--------------
function Ai_monster_guard:on_beskill(skill_id, killer)
	local skill_ty = skill_id and g_skill_mgr:get_skill_type(skill_id)
	if skill_ty == SKILL_MONSTER or skill_ty == SKILL_BAD then
		local o_id = killer and killer:get_id()
		if o_id == nil or killer:get_type() ~= OBJ_TYPE_MONSTER then return 2 end
		
		self.obj.ai_enemy:add_obj(o_id, skill_id, 0)
		if self.att_obj_id == nil then
			self:on_find_enemy()
		elseif self.att_obj_id ~= o_id then
			local o_ey = self.obj.ai_enemy:get_enemy(o_id)
			local att_ey = self.obj.ai_enemy:get_enemy(self.att_obj_id)
			if o_ey > att_ey then    --仇恨值
				local ave_ey = self.obj.ai_enemy:get_ave_enemy()
				local r = _ai_param._enemy[(math.floor((o_ey - att_ey)/ave_ey))] or 1
				if self:random_change() < r*100 or o_ey > 2*att_ey then
					self.att_obj_id = o_id
				end
			end
		end

		if self.status ~= AI_STATUS_COMBAT and self.status ~= AI_STATUS_APPROACH then
			self:to_attack()
		end
	end
	return 2
end
function Ai_monster_guard:on_damage(dg, killer, skill_id)
	local o_id = killer and killer:get_id()
	if o_id ~= nil and killer:get_type() == OBJ_TYPE_MONSTER then
		self.obj.ai_enemy:add_obj(o_id, skill_id, -dg)
	end
end