
local _max_c = 20
local _random = crypto.random

Ai_enemy = oo.class(nil, "Ai_enemy")

function Ai_enemy:__init()
	self.enemy_l = {}
	self.enemy_count = 0  --仇恨人数
	self.enemy_number = 0       --仇恨次数
	self.enemy_total = 0        --总仇恨值

	self.obj_l = {}       --id列表,相互引用
end

function Ai_enemy:add_obj(obj_id, skill_id, dg)
	if obj_id == nil then return end

	if dg > 0 and dg < MAX_ENEMY then
		self.enemy_total = self.enemy_total + dg
		self.enemy_number = self.enemy_number + 1
	end

	local index = self:find_obj(obj_id)
	if index ~= nil then
		self.enemy_l[index]["enemy"] = self.enemy_l[index]["enemy"] + dg >= 0 and self.enemy_l[index]["enemy"] + dg or 0
		return
	end

	if self.enemy_count >= _max_c then
		self:sort_list()
		self.enemy_l[self.enemy_count]["obj_id"] = obj_id
		self.enemy_l[self.enemy_count]["enemy"] = dg
		return
	end

	self.enemy_count = self.enemy_count + 1
	self.enemy_l[self.enemy_count] = {}
	self.enemy_l[self.enemy_count]["obj_id"] = obj_id
	self.enemy_l[self.enemy_count]["enemy"] = dg

	self.obj_l[obj_id] = self.enemy_l[self.enemy_count]
end

function Ai_enemy:del_obj(obj_id)
	if obj_id == nil then return end
	local index = self:find_obj(obj_id)
	if index ~= nil then
		self.enemy_l[index]["enemy"] = -1

		self:sort_list()
		self.enemy_l[self.enemy_count] = nil
		self.enemy_count = self.enemy_count - 1

		self.obj_l[obj_id] = nil
	end
end
function Ai_enemy:set_obj(obj_id, skill_id, dg)
	local en = self:get_enemy(obj_id)
	if en > 0 then
		self:add_obj(obj_id, skill_id, dg-en)
	else
		self:add_obj(obj_id, skill_id, dg)
	end
end
function Ai_enemy:get_ave_enemy()
	return math.floor(self.enemy_total/self.enemy_number)
end

function Ai_enemy:copy_enemy(ey_des)
	self:clear()
	for k,v in pairs(ey_des.enemy_l) do
		self.enemy_count = self.enemy_count + 1
		self.enemy_l[k] = {}
		self.enemy_l[k]["obj_id"] = v.obj_id
		self.enemy_l[k]["enemy"] = v.enemy
	end
end
function Ai_enemy:get_enemy(obj_id)
	return self.obj_l[obj_id] and self.obj_l[obj_id]["enemy"] or -1
end
function Ai_enemy:get_max_enmity()
	if self.enemy_count > 0 then
		return math.max(self.enemy_l[1]["enemy"], 0)
	end
	return 0
end

function Ai_enemy:get_count()
	return self.enemy_count
end

function Ai_enemy:get_list()
	self:sort_list()
	return self.enemy_l
end
function Ai_enemy:clear()
	self.enemy_count = 0
	self.enemy_l = {}
	self.enemy_number = 0     
	self.enemy_total = 0 
	self.obj_l = {}
end

function Ai_enemy:sort_list()
	table.sort(self.enemy_l, function(e1,e2) 
		return e1.enemy > e2.enemy end)
end
function Ai_enemy:find_obj(obj_id)
	for k,v in pairs(self.enemy_l) do
		if v.obj_id == obj_id then
			return k
		end
	end
end

--获取仇恨列表中随机一个对象id，第一对象优先级最低，
function Ai_enemy:get_enemy_id_x()
	if self.enemy_count <= 0 then return end
	if self.enemy_count == 1 then return self.enemy_l[1]["obj_id"] end

	self:sort_list()
	local pos = _random(2, self.enemy_count+1)

	return self.enemy_l[pos]["obj_id"] or self.enemy_l[1]["obj_id"]
end

--减少怪物的百分比的仇恨值 per:0.8 为减去原来80%的仇恨，最小为1
function Ai_enemy:sub_percent_enemy(obj_id, per)
	local old_enemy = self.obj_l[obj_id] and self.obj_l[obj_id]["enemy"]
	if old_enemy == nil then
		return
	end
	local new_enemy = math.max(1, math.floor(old_enemy * (1 - per)))
	self.obj_l[obj_id]["enemy"] = new_enemy
	return true
end