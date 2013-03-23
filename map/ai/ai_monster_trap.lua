
local debug_print = function() end --print
--local debug_print = print
local _ai_param = require("config.ai_config")
local _random = crypto.random


MOVE_TYPE = {
	["NOMOVE"] = 0,		-- 不移动
	["REPEAT"] = 1,		-- 循环
	["REBACK"] = 2,		-- 往返
}

local concat = function(src, dst)
	if src == nil then
		return
	end

	dst = dst or {}
	local k, v
	if #dst == 0 then
		dst[0] = src[0]
	else
		dst[#dst+1] = src[0]
	end
	for k,v in ipairs(src) do
		dst[#dst+1] = v
	end
	return dst
end

--陷阱怪的AI
Ai_monster_trap  = oo.class(Ai_character, "Ai_monster_trap")

function Ai_monster_trap:__init(obj, lv)
	Ai_character.__init(self, obj, lv)

	--time	
	self.time_scan = Ai_time(_ai_param._level_trap[self.ai_level][1])            --扫描时间

	--当前攻击对象
	self.att_obj_id = nil

	--坐标数
	--self.pos_size = #_ai_param._level_trap[self.ai_level][4]
	--目标坐标(位于列表中的第几个坐标)
	--self.des_pos = 0
	--self.is_asc = true	-- 是否升序，往返时用到

	-- 全路径
	self.path = nil

	self.status = AI_STATUS_MOVE

	debug_print("===> Ai_monster_trap:__init")
end

function Ai_monster_trap:initialize()
end

function Ai_monster_trap:clear_up()
	self.att_obj_id = nil 
	self.obj:clear()
	
	local move_obj = self.obj:get_move_obj()
	move_obj:clear()
end

function Ai_monster_trap:on_logic_move(utime)

	if self.path == nil then
		self:build_path()
	end

	if _ai_param._level_trap[self.ai_level][3] ~= MOVE_TYPE.NOMOVE then
		if not self.obj:is_moving() then
			self.obj.move_obj:move(self.path, #self.path)
		end
	end

	----扫描
	if self.time_scan:is_time() then
		local obj_id = self:scan_one_obj()
		if obj_id ~= nil then
			self:to_attack()
		end
	end
end

--[[
function Ai_monster_trap:on_logic_move(utime)
	debug_print("Ai_monster_td:on_logic_move 1", self.obj:get_id(), self.des_obj_id, self.obj:get_home_pos()[1],
	self.obj:get_home_pos()[2])

	if self.obj:is_moving() then -- 还未到达目的坐标

	elseif _ai_param._level_trap[self.ai_level][3] ~= MOVE_TYPE.NOMOVE then--已到达目的坐标, 寻找下一个坐标
		print("====> _ai_param._level_trap[self.ai_level][3]",_ai_param._level_trap[self.ai_level][3])
		if _ai_param._level_trap[self.ai_level][3] == MOVE_TYPE.REPEAT then
			self.des_pos = self.des_pos + 1 > self.pos_size and 1 or self.des_pos + 1
			print("====> des_pos, self.pos_size", self.des_pos, self.pos_size)
		elseif _ai_param._level_trap[self.ai_level][3] == MOVE_TYPE.REBACK then
			if self.is_asc then	--升序行走
				if self.des_pos == self.pos_size then
					self.des_pos = self.des_pos - 1
					self.is_asc = false
				else
					self.des_pos = self.des_pos + 1
				end
			else	--降序行走
				if self.des_pos == 1 then
					self.des_pos = self.des_pos + 1
					self.is_asc = true
				else
					self.des_pos = self.des_pos - 1
				end
			end
		end
		print("====> moving else",_ai_param._level_trap[self.ai_level][4][self.des_pos][1], _ai_param._level_trap[self.ai_level][4][self.des_pos][2])
		self.obj:des_move(_ai_param._level_trap[self.ai_level][4][self.des_pos], 0)
	end


	--扫描
	if self.time_scan:is_time() then
		local obj_id = self:scan_one_obj()
		if obj_id ~= nil then
			self:to_attack()
		end
	end
end
]]

function Ai_monster_trap:on_logic_combat(utime)
	debug_print("Ai_monster_trap:on_logic_combat", self.obj:get_id(), self.att_obj_id)
	local att_obj = self:validate_obj(self.att_obj_id)
	if att_obj ~= nil then
		local skill_o,param = self.obj:get_ai_skill(att_obj)
		--if skill_o ~= nil then
			--距离太远
			--self.att_dis = skill_o:get_dis()
			--if skill_o:get_type() == SKILL_BAD and self:distance(att_obj, self.obj) > self.att_dis then
			--	self:to_approach()
			--	return
			--end

			local skill_con = self.obj:get_skill_con()
			skill_con:use(skill_o:get_id(), param)
		--end
	end

	self:to_move()
	
end


--判定有效的玩家
function Ai_monster_trap:validate_obj(obj_id)
	if obj_id == nil then return end

	local scene_o = self.obj:get_scene_obj()
	local obj = g_obj_mgr:get_obj(obj_id)
	if obj ~= nil and scene_o:find_obj(obj_id) then
		if obj:is_alive() and obj:is_view() then   
			return obj
		end
	end
end


------------执行函数--------------
function Ai_monster_trap:to_move()
	self:set_status(AI_STATUS_MOVE)
end

function Ai_monster_trap:to_attack()
	self:set_status(AI_STATUS_COMBAT)
end


--------------event--------------
function Ai_monster_trap:on_beskill(skill_id, killer)
	--print("Ai_monster_trap:on_beskill", 1)
	return 1
end

function Ai_monster_trap:on_damage(dg, killer, skill_id)

end


function Ai_monster_trap:get_attack_id()
	return self.att_obj_id
end

--扫描指定区域内随机一个对象
function Ai_monster_trap:scan_one_obj()
	local area = _ai_param._level_trap[self.ai_level][2]
	local obj_id = self.obj:scan_obj(area, nil)-- 9格扫描

	self.att_obj_id = obj_id
	return obj_id

end

--
--预先计算好路径
function Ai_monster_trap:build_path()
	local path_full = {}
	if _ai_param._level_trap[self.ai_level][3] ~= MOVE_TYPE.NOMOVE then
		local pos_size = #_ai_param._level_trap[self.ai_level][4]
		if _ai_param._level_trap[self.ai_level][3] == MOVE_TYPE.REPEAT then
			local scene_o = self.obj:get_scene_obj()
			for i = 1, pos_size do
				local pos = _ai_param._level_trap[self.ai_level][4][i]
				local i_next = i + 1 > pos_size and 1 or i + 1
				local des_pos = _ai_param._level_trap[self.ai_level][4][i_next]
				local path_l = scene_o:get_map_obj():find_path(pos, des_pos)
				if path_l ~= nil then
					concat(path_l, path_full)
				end
			end

		elseif _ai_param._level_trap[self.ai_level][3] == MOVE_TYPE.REBACK then
			local scene_o = self.obj:get_scene_obj()
			for i = 1, pos_size - 1 do --升序行走
				local pos = _ai_param._level_trap[self.ai_level][4][i]
				local i_next = i + 1 > pos_size and 1 or i + 1
				local des_pos = _ai_param._level_trap[self.ai_level][4][i_next]
				local path_l = scene_o:get_map_obj():find_path(pos, des_pos)
				if path_l ~= nil then
					concat(path_l, path_full)
				end
			end
			for i = pos_size, 2, -1 do --降序行走
				local pos = _ai_param._level_trap[self.ai_level][4][i]
				local i_next = i - 1 < 1 and 1 or i - 1
				local des_pos = _ai_param._level_trap[self.ai_level][4][i_next]
				local path_l = scene_o:get_map_obj():find_path(pos, des_pos)
				if path_l ~= nil then
					concat(path_l, path_full)
				end
			end

		end
		path_full[#path_full] = nil
		--print("path_full", Json.Encode(path_full))
	end
	self.path = path_full
end
