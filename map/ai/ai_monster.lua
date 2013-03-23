
local debug_print = function() end --print
--local debug_print = print
local _ai_param = require("config.ai_config")
local _random = crypto.random
local _dis = 0  --技能距离偏差


Ai_monster = oo.class(Ai_character, "Ai_monster")

function Ai_monster:__init(obj, lv)
	Ai_character.__init(self, obj, lv)

	--time
	self.time_move = Ai_time(_random(_ai_param._level[self.ai_level][13][1],_ai_param._level[self.ai_level][13][2]))	
	self.time_scan = Ai_time(_ai_param._level[self.ai_level][11])            --扫描时间

	--当前攻击对象
	self.att_obj_id = nil
	--攻击距离
	self.att_dis = 1
	--逃跑次数
	self.flee_count = 0
	self.flee_pos = {0,0}
	--战斗标记
	self.combat_flag = false
	self.cmobat_time = ev.time
end

function Ai_monster:initialize()
	self.time_move:set_time(_random(_ai_param._level[self.ai_level][13][1],_ai_param._level[self.ai_level][13][2]))
end
function Ai_monster:clear_up()
	self.att_obj_id = nil 
	self.obj.ai_enemy:clear()
	self.obj:clear()
	
	local move_obj = self.obj:get_move_obj()
	move_obj:clear()

	self.flee_count = 0
	self.combat_flag = false
	self.cmobat_time = ev.time

	if self:is_go_home() then
		self.obj:set_god(false)
		self.obj:set_speed_mode(1)
		self.obj:add_hp(self.obj:get_max_hp())

		--impact
		local impact_con = self.obj:get_impact_con()
		local _ = impact_con and impact_con:clear()
	end
end

function Ai_monster:get_combat_time()
	if self.combat_flag then
		return ev.time - self.cmobat_time
	end
	return 0
end

------------ai逻辑函数---------
function Ai_monster:on_logic_idle(utime)
	debug_print("Ai_monster:on_logic_idle")
	if _ai_param._level[self.ai_level][1] and self.time_scan:is_time() then
		local obj_id = self:scan_one_obj()
		if obj_id ~= nil then
			--self.att_obj_id = obj_id
			--self.obj.ai_enemy:add_obj(obj_id, nil, 0)
			self:to_attack()
		end
	end
	if _ai_param._level[self.ai_level][12] and self.time_move:is_time() then
		self.obj:rand_move()
		self.time_move:set_time(_random(_ai_param._level[self.ai_level][13][1],_ai_param._level[self.ai_level][13][2]))
	end
end
--[[function Ai_monster:on_logic_dead(utime)
	debug_print("Ai_monster:on_logic_dead")	
end]]
function Ai_monster:on_logic_combat(utime)
	--print("Ai_monster:on_logic_combat 1", self.obj:get_id(), self.att_obj_id)
	local att_obj = self:validate_obj(self.att_obj_id)
	if att_obj ~= nil then
		local skill_o,param = self.obj:get_ai_skill(att_obj)
		if skill_o ~= nil then
			--距离太远
			self.att_dis = skill_o:get_dis()
			if skill_o:get_type() == SKILL_BAD and self:distance(att_obj, self.obj) > self.att_dis + self.obj:get_cubage() then
				self:to_approach()
				return
			end

			local skill_con = self.obj:get_skill_con()
			skill_con:use(skill_o:get_id(), param)
		end
	else
		local att_obj = self:on_find_enemy()
		if att_obj == nil then
			self:to_gohome()
			return
		end
		--self.att_obj_id = att_obj:get_id()
	end
end
function Ai_monster:on_logic_flee(utime)
	debug_print("Ai_monster:on_logic_flee", self.obj:get_home_pos()[1], self.obj:get_home_pos()[2])
	local att_obj = self:validate_obj(self.att_obj_id)
	if att_obj ~= nil then
		if not self.obj:is_moving() and self:comp_pos(self.obj:get_pos(), self.flee_pos, 2) then
			--设置逃跑点为出生点
			self.obj:set_home_pos(self.flee_pos)
			self.obj:set_speed_mode(1)
			self:to_approach()
		else
			
		end
	end
end
--[[function Ai_monster:on_logic_patrol(utime)
end]]
function Ai_monster:on_logic_gohome(utime)
	debug_print("Ai_monster:on_logic_gohome")
	if not self.obj:is_moving() then
		self:to_idle()
	end
end
function Ai_monster:on_logic_approach(utime)
	debug_print("Ai_monster:on_logic_approach")
	local att_obj = self:validate_obj(self.att_obj_id)
	if att_obj ~= nil then
		--随机性
		if _random(0,100) < 85 then
			if self:distance(att_obj, self.obj) <= self.att_dis + self.obj:get_cubage() then
				self:attack_obj(att_obj)
				self:to_attack()
				return
			elseif self.obj:des_move(att_obj:get_pos(), self.att_dis) then
				return
			end
		else
			return
		end
	end

	att_obj = self:on_find_enemy()
	if att_obj == nil then
		self:to_gohome()
		return
	end
	--self.att_obj_id = att_obj:get_id()
end

------------执行函数--------------
function Ai_monster:to_idle()
	self:clear_up()
	self:set_status(AI_STATUS_IDLE)
end
function Ai_monster:to_gohome()
	if self:is_go_home() then
		self.obj:set_god(true)
		self.obj:set_speed_mode(2)
	end
	
	self.obj:des_move(self.obj:get_home_pos())
	self:set_status(AI_STATUS_GOHOME)
end
function Ai_monster:to_approach()
	self:set_status(AI_STATUS_APPROACH)
end
function Ai_monster:to_attack()
	self:set_status(AI_STATUS_COMBAT)

	if not self.combat_flag then
		self.combat_flag = true
		self.cmobat_time = ev.time
	end
end
function Ai_monster:attack_obj(att_obj)
	if self.ai_level > 9 then   --守卫和boss怪
		local skill_o,param = self.obj:get_ai_skill(att_obj)
		if skill_o ~= nil then
			local skill_con = self.obj:get_skill_con()
			skill_con:use(skill_o:get_id(), param)
		end
	end
end

function Ai_monster:to_flee()
	debug_print("Ai_monster:to_flee()", 1)
	local att_obj = self:validate_obj(self.att_obj_id)
	if self.flee_count == 0 and att_obj ~= nil then
		self.flee_count = self.flee_count + 1

		local scene_o = self.obj:get_scene_obj()
		local map_obj = scene_o:get_map_obj()
		local area = _ai_param._level[self.ai_level][5]
		self.flee_pos = map_obj:find_far_pos(att_obj:get_pos(), self.obj:get_pos(), area)
		if self.flee_pos ~= nil then
			self.obj:set_speed_mode(0)
			self.obj:des_move(self.flee_pos)
			self:set_status(AI_STATUS_FLEE)

			if _ai_param._level[self.ai_level][7] then
				--召唤同伴
				self.obj:say(1)

				--print("Ai_monster:to_flee()", 3, self.flee_pos[1], self.flee_pos[2])
				if self.flee_pos ~= nil then
					local area = _ai_param._level[self.ai_level][9]
					local obj_l = map_obj:scan_obj_rect(self.obj:get_pos(), area, OBJ_TYPE_MONSTER) or {}
					for k,_ in pairs(obj_l) do
						local obj = g_obj_mgr:get_obj(k)
						if obj ~= nil and obj:get_ai_obj():get_status() == AI_STATUS_IDLE then
							obj.ai_enemy:copy_enemy(self.obj.ai_enemy)
							obj:get_ai_obj():to_attack()
						end
					end
				end
			end
		end
	end
end


--------------event--------------
function Ai_monster:on_beskill(skill_id, killer)
	--print("Ai_monster:on_beskill", 1)
	if self.status == AI_STATUS_GOHOME then
		return 1
	end

	--print("Ai_monster:on_beskill", 2, skill_id, g_skill_mgr:get_skill_type(skill_id))
	local skill_ty = skill_id and g_skill_mgr:get_skill_type(skill_id)
	if self:get_status() ~= AI_STATUS_FLEE and 
		(skill_ty == SKILL_MONSTER or skill_ty == SKILL_BAD or skill_ty == SKILL_MAGIC_USE or skill_ty == SKILL_PET_ATTACK_TRIGGER) then

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

		local att_obj = g_obj_mgr:get_obj(self.att_obj_id)	
		if att_obj ~= nil and not self.obj:is_sneer() and self:random_change() < 3 then          --辅助者
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
function Ai_monster:on_damage(dg, killer, skill_id)
	--判断是否逃跑
	if _ai_param._level[self.ai_level][4] then
		local hp_per = _ai_param._level[self.ai_level][6]
		if self.obj:is_alive() and hp_per >= self.obj:get_hp()/self.obj:get_max_hp() and self:is_flee_odds() then
			self:to_flee()
		end
	end

	local o_id = killer and killer:get_id()
	if o_id ~= nil then
		self.obj.ai_enemy:add_obj(o_id, skill_id, -dg)
	end
end


--[[--重新定位攻击对象
function Ai_monster:find_att_obj()
	local att_obj = self:on_find_enemy()
end]]

------private-----------
--是否改变攻击对象
--[[function Ai_monster:random_change()
	return _random(0, 100)
end]]

function Ai_monster:is_flee_odds()
	return _random(0, 100) < 40
end
--比较两坐标,area指允许偏差
function Ai_monster:comp_pos(pos, des_pos, area)
	area = area or 0
	if pos[1] <= des_pos[1] + area and pos[1] >= des_pos[1] - area and
		pos[2] <= des_pos[2] + area and pos[2] >= des_pos[2] - area then
		return true
	end
	return false
end
--查找可攻击的玩家(子类重载)
function Ai_monster:on_find_enemy()
	local eny_l = self.obj.ai_enemy:get_list()
	local scene_o = self.obj:get_scene_obj()
	for k,v in pairs(eny_l) do
		v = self:validate_obj(v.obj_id) 
		if v ~= nil then
			self.att_obj_id = v:get_id()
			return v	
		end
	end
end
function Ai_monster:get_attack_id()
	return self.att_obj_id
end
--[[function Ai_monster:del_enemy(obj_id)
	self.obj.ai_enemy:del_obj(obj_id)
end]]
--[[--判定有效的玩家
function Ai_monster:validate_obj(obj_id)
	if obj_id == nil then return end

	local scene_o = self.obj:get_scene_obj()
	local obj = g_obj_mgr:get_obj(obj_id)
	if obj ~= nil and scene_o:find_obj(obj_id) then
		if obj:is_alive() and (obj:is_view() or self.ai_level >= 13) then    --boss怪免疫隐身特效
			local map_obj = scene_o:get_map_obj()
			local dis = _ai_param._level[self.ai_level][3]
			if map_obj:distance(obj:get_pos(), self.obj:get_home_pos()) < dis then
				return obj
			end
		end
	end
end]]

--[[--获取对象间距离
function Ai_monster:distance(obj_s, obj_d)
	local map_obj = obj_s:get_scene_obj():get_map_obj()
	local dis = map_obj:distance(obj_s:get_pos(), obj_d:get_pos())
	dis = dis-obj_s:get_cubage()-obj_d:get_cubage()
	dis = dis > 0 and dis or 0
	return dis
end]]

--扫描指定区域内随机一个对象
function Ai_monster:scan_one_obj()
	local area = _ai_param._level[self.ai_level][2]
	local ty = self.ai_level <= 6 and 1 or nil       --ai大于6，9格扫描
	local obj_id = self.obj:scan_obj(area, ty)

	if obj_id ~= nil then
		self.att_obj_id = obj_id
		self.obj.ai_enemy:add_obj(obj_id, nil, 0)
		return obj_id
	end
end

--是否要归位
function Ai_monster:is_go_home()
	return self.obj:is_go_home()
end