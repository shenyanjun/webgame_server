
local debug_print = function() end
--local debug_print = print
local _ai_param = require("config.ai_config")
local _random = crypto.random


--会追踪怪物的AI
Ai_monster_trace  = oo.class(Ai_monster, "Ai_monster_trace")

function Ai_monster_trace:__init(obj, lv)
	Ai_monster.__init(self, obj, lv)

	self.trace_id = nil  -- 追踪对象的ID
	debug_print("===> Ai_monster_trace:__init")
end

function Ai_monster_trace:set_des_obj_id(id)
	self.trace_id = id
end

function Ai_monster_trace:get_des_obj_id()
	return self.trace_id
end

function Ai_monster_trace:on_logic_idle(utime)
	--debug_print("Ai_monster_trace:on_logic_idle")
	local obj = self.trace_id and g_obj_mgr:get_obj(self.trace_id)
	if obj == nil then
		self.trace_id = nil
		Ai_monster.on_logic_idle(self, utime)
		return
	end

	self.att_obj_id = self.trace_id
	self.obj.ai_enemy:add_obj(self.trace_id, nil, 0)
	self:to_attack()
end

function Ai_monster_trace:on_logic_combat(utime)
	--debug_print("Ai_monster_trace:on_logic_combat")
	local att_obj = g_obj_mgr:get_obj(self.att_obj_id)
	if att_obj ~= nil then
		local skill_o,param = self.obj:get_ai_skill(att_obj)
		if skill_o ~= nil then
			--距离太远
			self.att_dis = skill_o:get_dis()
			if skill_o:get_type() == SKILL_BAD and self:distance(att_obj, self.obj) > self.att_dis then
				self:to_approach()
				return
			end

			local skill_con = self.obj:get_skill_con()
			skill_con:use(skill_o:get_id(), param)
		end
	else
		local att_obj = self:on_find_enemy()
		if att_obj == nil then
			--self:to_gohome()
			self:to_idle()
			return
		end
	end
end

function Ai_monster_trace:on_logic_approach(utime)
	debug_print("Ai_monster_trace:on_logic_approach")

	local obj = self.trace_id and g_obj_mgr:get_obj(self.trace_id)
	if obj == nil then
		self.trace_id = nil
		Ai_monster.on_logic_approach(self, utime)
		return
	end

	local scene_o = self.obj:get_scene_obj()
	local path_l = scene_o:get_map_obj():find_path(self.obj:get_pos(), obj:get_pos())
	self.obj.move_obj:move(path_l, math.max(0, #path_l - math.max(self.att_dis-2, 0) - self.obj:get_cubage()))
	self:set_status(AI_STATUS_MOVE)
end

function Ai_monster_trace:on_logic_move(utime)
	--debug_print("Ai_monster_trace:on_logic_move")
	if not self.obj:is_moving() then
		self:set_status(AI_STATUS_IDLE)
	end
end

function Ai_monster_trace:is_go_home()
	return false
end

function Ai_monster_trace:on_beskill(skill_id, killer)
	--print("Ai_monster_trace:on_beskill", 1)
	if self.status == AI_STATUS_GOHOME then
		return 1
	end

	--print("Ai_monster_trace:on_beskill", 2, skill_id, g_skill_mgr:get_skill_type(skill_id))
	local skill_ty = skill_id and g_skill_mgr:get_skill_type(skill_id)
	if self:get_status() ~= AI_STATUS_FLEE and 
		(skill_ty == SKILL_MONSTER or skill_ty == SKILL_BAD) then

		local o_id = killer and killer:get_id()
		if o_id == nil then return 2 end
		
		self.obj.ai_enemy:add_obj(o_id, skill_id, 0)
		local scene_o = self.obj:get_scene_obj()
		if killer:get_type() == OBJ_TYPE_HUMAN and killer:get_team() ~= nil then --把组添加到仇恨列表
			local team_obj = g_team_mgr:get_team_obj(killer:get_team())
			local team_l = team_obj and team_obj:get_team_l()
			for k,_ in pairs(team_l or {}) do
				local obj = g_obj_mgr:get_obj(k)
				if obj ~= nil and k ~= o_id then
					self.obj.ai_enemy:add_obj(k, nil, 0)
				end
			end
		elseif killer:get_type() == OBJ_TYPE_PET then   --把宠物的玩家和组添加到仇恨列表
			local owner_id = killer:get_owner_id()
			self.obj.ai_enemy:add_obj(owner_id, nil, 0)
		end

		if self.att_obj_id == nil then
			local att_obj = self:on_find_enemy()
			--[[if att_obj ~= nil then
				self.att_obj_id = att_obj:get_id()
			end]]
		elseif self.att_obj_id ~= o_id and self.trace_id == nil then
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

		local att_obj = g_obj_mgr:get_obj(self.att_obj_id)	
		if att_obj ~= nil and not self.obj:is_sneer() and self:random_change() < 3 and self.trace_id == nil then          --辅助者
			local aster = att_obj:get_assister()
			if aster ~= nil and self.obj.ai_enemy:get_enemy(aster) >= 0 then
				self.att_obj_id = aster

				local emy = self.obj.ai_enemy:get_max_enmity()
				local ave_ey = self.obj.ai_enemy:get_ave_enemy()
				self.obj.ai_enemy:set_obj(aster, nil, emy+ave_ey*3)
			end
		end

		if self.status ~= AI_STATUS_COMBAT and self.status ~= AI_STATUS_APPROACH then
			self:to_attack()
		end
	end
	return 2
end
