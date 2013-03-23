
--local debug_print = print
local debug_print = function() end
local _ai_param = require("config.ai_config")
local _random = crypto.random
local _dis = 0  --技能距离偏差


Ai_character = oo.class(nil, "Ai_character")

function Ai_character:__init(obj, lv)
	self.obj = obj
	self.status = AI_STATUS_IDLE
	self.ai_level = lv

	--timer
	--self.time_count = 0   --每秒轮询次数，用于计数
	self.sec_count = 0.5    --多少秒轮询一次，默认1秒
end

function Ai_character:close()
	self.obj = nil
end

--obj
function Ai_character:get_obj()
	return self.obj
end
--level
function Ai_character:set_level(lv)
	self.ai_level = lv
end
function Ai_character:get_level()
	return self.ai_level
end
--status
function Ai_character:set_status(st)
	self.status = st
end
function Ai_character:get_status()
	return self.status
end
--clear
function Ai_character:clear_up()
	
end

------------ai逻辑函数---------
function Ai_character:on_logic_idle(utime)
end
--[[function Ai_character:on_logic_dead(utime)
end]]
function Ai_character:on_logic_combat(utime)
end
function Ai_character:on_logic_flee(utime)
end
--[[function Ai_character:on_logic_patrol(utime)
end]]
function Ai_character:on_logic_gohome(utime)
end
function Ai_character:on_logic_approach(utime)
end
function Ai_character:on_logic_move(utime)
end

--重新定位攻击对象
function Ai_character:find_att_obj()
	local att_obj = self:on_find_enemy()
end
--查找可攻击的玩家(子类重载)
function Ai_character:on_find_enemy()
end

--获取对象间距离
function Ai_character:distance(obj_s, obj_d)
	local map_obj = obj_s:get_scene_obj():get_map_obj()
	local dis = map_obj:distance(obj_s:get_pos(), obj_d:get_pos())
	dis = dis-obj_s:get_cubage()-obj_d:get_cubage()
	dis = dis > 0 and dis or 0
	return dis
end

--判定有效的玩家
function Ai_character:validate_obj(obj_id)
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
end

--是否改变攻击对象
function Ai_character:random_change()
	return _random(0, 100)
end

------------event--------------
function Ai_character:on_logic(tm)
	debug_print("Ai_character:on_logic", tm)

	if self.status == AI_STATUS_IDLE then
		self:on_logic_idle(utime)
	elseif self.status == AI_STATUS_COMBAT then
		self:on_logic_combat(utime)
	elseif self.status == AI_STATUS_APPROACH then
		self:on_logic_approach(utime)
	elseif self.status == AI_STATUS_FLEE then
		self:on_logic_flee(utime)
	elseif self.status == AI_STATUS_GOHOME then
		self:on_logic_gohome(utime)
	elseif self.status == AI_STATUS_MOVE then
		self:on_logic_move(utime)
	--[[elseif self.status == AI_STATUS_PATROL then
		self:on_logic_patrol(utime)]]
	--[[elseif self.status == AI_STATUS_DEAD then
		self:on_logic_dead(utime)]]
	end
end

--返回0，不能使用技能，1，可以使用技能，但不产生伤害， 2使用技能，产生伤害
function Ai_character:on_beskill(skill_id, killer)
end
function Ai_character:on_damage(dg, killer, skill_id)
end
function Ai_character:on_die(killer)
end
