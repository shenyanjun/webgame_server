
local debug_print = function() end --print
--local debug_print = print
local _ai_param = require("config.ai_config")
local _random = crypto.random
local _dis = 0  --技能距离偏差


Ai_monster_td = oo.class(Ai_character, "Ai_monster_td")

function Ai_monster_td:__init(obj, lv, path_l, des_obj_id)
	Ai_character.__init(self, obj, lv)

	self.status = AI_STATUS_MOVE
	--time
	self.time_scan = Ai_time(_ai_param._level_td[self.ai_level][4])            --扫描时间

	--当前攻击对象
	self.att_obj_id = nil

	--攻击距离
	self.att_dis = 1

	--移动路线
	self.path_l = path_l
	self.cur_path_index = 1

	self.obj:set_home_pos(self.path_l[1])

	--最终攻击对象
	self.des_obj_id = des_obj_id

	self.combat_flag = false
	self.cmobat_time = ev.time
end

function Ai_monster_td:set_des_obj_id(id)
	self.des_obj_id = id
end
function Ai_monster_td:get_des_obj_id(id)
	return self.des_obj_id
end

function Ai_monster_td:initialize()
end

function Ai_monster_td:clear_up()
	--[[self.att_obj_id = nil 
	self.obj.ai_enemy:clear()
	self.obj:clear()

	local move_obj = self.obj:get_move_obj()
	move_obj:clear()]]
	self.combat_flag = false
	self.cmobat_time = ev.time
end

function Ai_monster_td:on_logic_combat(utime)
	debug_print("Ai_monster_td:on_logic_combat 1", self.obj:get_id(), self.att_obj_id)
	local att_obj = self:validate_obj(self.att_obj_id)
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
			self:to_move()
			return
		end
		--self.att_obj_id = att_obj:get_id()
	end
end
function Ai_monster_td:on_logic_approach(utime)
	debug_print("Ai_monster_td:on_logic_approach")
	local att_obj = self:validate_obj(self.att_obj_id)
	if att_obj ~= nil then
		--随机性
		if _random(0,100) < 85 then
			if self:distance(att_obj, self.obj) <= self.att_dis then
				self:attack_obj(att_obj)
				self:to_attack()
				return
			elseif self.obj:des_move(att_obj:get_pos(), self.att_dis) then
				return
			end
		else
			return
		end

		self:move_to_des()    --调整home坐标
	end

	att_obj = self:on_find_enemy()
	if att_obj == nil then
		self:to_move()
		return
	end
	--self.att_obj_id = att_obj:get_id()
end
function Ai_monster_td:on_logic_move(utime)
	--debug_print("Ai_monster_td:on_logic_move 1", self.obj:get_id(), self.des_obj_id, self.obj:get_home_pos()[1], self.obj:get_home_pos()[2])

	local des_obj = self.des_obj_id and g_obj_mgr:get_obj(self.des_obj_id)
	if des_obj ~= nil then
		self:move_to_des()

		if self.cur_path_index < #self.path_l then   --逼近目标
			self.obj:des_move(self.obj:get_home_pos(), self.att_dis)
		else
			self.att_obj_id = self.des_obj_id
			self:to_attack()
			return
		end
	elseif self.cur_path_index < #self.path_l then
		self:move_to_des()
		self.obj:des_move(self.obj:get_home_pos(), 0)
	end

	--扫描
	if _ai_param._level_td[self.ai_level][1] and self.time_scan:is_time() then
		local obj_id = self:scan_one_obj()
		if obj_id ~= nil then
			self:to_attack()
		end
	end
end

------------执行函数--------------

function Ai_monster_td:to_approach()
	self:set_status(AI_STATUS_APPROACH)
end
function Ai_monster_td:to_attack()
	self:set_status(AI_STATUS_COMBAT)
	if not self.combat_flag then
		self.combat_flag = true
		self.cmobat_time = ev.time
	end
end
function Ai_monster_td:attack_obj(att_obj)
	if self.ai_level > 9 then   --守卫和boss怪
		local skill_o,param = self.obj:get_ai_skill(att_obj)
		if skill_o ~= nil then
			local skill_con = self.obj:get_skill_con()
			skill_con:use(skill_o:get_id(), param)
		end
	end
end
function Ai_monster_td:to_move()
	self:set_status(AI_STATUS_MOVE)
	self:clear_up()
end


--------------event--------------
function Ai_monster_td:on_beskill(skill_id, killer)
	--print("Ai_monster_td:on_beskill", 1)
	--[[if self.status == AI_STATUS_MOVE then
		return 1
	end]]

	--print("Ai_monster_td:on_beskill", 2, skill_id, g_skill_mgr:get_skill_type(skill_id))
	local skill_ty = skill_id and g_skill_mgr:get_skill_type(skill_id)
	if skill_ty == SKILL_MONSTER or skill_ty == SKILL_BAD then
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

function Ai_monster_td:on_damage(dg, killer, skill_id)
	local o_id = killer and killer:get_id()
	if o_id ~= nil then
		self.obj.ai_enemy:add_obj(o_id, skill_id, -dg)
	end
end


--[[--重新定位攻击对象
function Ai_monster_td:find_att_obj()
	local att_obj = self:on_find_enemy()
end]]


------private-----------
--是否改变攻击对象
--[[function Ai_monster_td:random_change()
	return _random(0, 100)
end]]

--[[function Ai_monster_td:is_flee_odds()
	return _random(0, 100) < 40
end]]
--比较两坐标,area指允许偏差
--[[function Ai_monster_td:comp_pos(pos, des_pos, area)
	area = area or 0
	if pos[1] <= des_pos[1] + area and pos[1] >= des_pos[1] - area and
		pos[2] <= des_pos[2] + area and pos[2] >= des_pos[2] - area then
		return true
	end
	return false
end]]
--查找可攻击的玩家
function Ai_monster_td:on_find_enemy()
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
function Ai_monster_td:get_attack_id()
	return self.att_obj_id
end
--[[function Ai_monster_td:del_enemy(obj_id)
	self.obj.ai_enemy:del_obj(obj_id)
end]]
--是否有效的玩家
--[[function Ai_monster_td:validate_obj(obj_id)
	if obj_id == nil then return end
	local scene_o = self.obj:get_scene_obj()
	local obj = g_obj_mgr:get_obj(obj_id)
	if obj ~= nil and scene_o:find_obj(obj_id) then
		if obj:is_alive() and (obj:is_view() or self.ai_level >= 13) then    --boss怪免疫隐身特效
			local map_obj = scene_o:get_map_obj()
			local dis = _ai_param._level_td[self.ai_level][3]
			if map_obj:distance(obj:get_pos(), self.obj:get_home_pos()) < dis then
				return obj
			end
		end
	end
end]]

--[[--获取对象间距离
function Ai_monster_td:distance(obj_s, obj_d)
	local map_obj = obj_s:get_scene_obj():get_map_obj()
	local dis = map_obj:distance(obj_s:get_pos(), obj_d:get_pos())
	dis = dis-obj_s:get_cubage()-obj_d:get_cubage()
	dis = dis > 0 and dis or 0
	return dis
end]]

--扫描指定区域内随机一个对象
function Ai_monster_td:scan_one_obj()
	local area = _ai_param._level[self.ai_level][5]
	local ty = (not area) and 1 or nil
	local obj_id = self.obj:scan_obj(area, nil)

	if obj_id ~= nil then
		self.att_obj_id = obj_id
		self.obj.ai_enemy:add_obj(obj_id, nil, 0)
		return obj_id
	end
end

--移动中修改home坐标
function Ai_monster_td:move_to_des()
	local pos = self.obj:get_pos()
	local home_pos = self.obj:get_home_pos()

	if self.cur_path_index < #self.path_l then
		if f_distance(pos, self.path_l[#self.path_l]) <= f_distance(home_pos, self.path_l[#self.path_l]) then
			--将home坐标靠近一步
			self.cur_path_index = self.cur_path_index + 1
		end
	end
	self.obj:set_home_pos(self.path_l[self.cur_path_index])
end

function Ai_monster_td:get_combat_time()
	if self.combat_flag then
		return ev.time - self.cmobat_time
	end
	return 0
end