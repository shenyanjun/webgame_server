
local _random = crypto.random

Ai_move = oo.class(nil, "Ai_move")

function Ai_move:__init(obj)
	self.obj = obj

	self.cur_node = 0
	self.count_node = 0
	self.path_l = {}

	--timer
	self.sec_count = 1    --多少秒轮询一次，默认1秒
end
function Ai_move:close()
	self.obj = nil
end
function Ai_move:move(path_l, count)
	self.cur_node = 0
	self.count_node = count
	self.path_l = path_l
	--self.speed = obj:get_speed()
end
function Ai_move:clear()
	self.cur_node = 0
	self.count_node = 0
	self.path_l = {}
end

function Ai_move:get_cur_path(tm)
	local cur = self.cur_node 
	local speed = math.floor(self.obj:get_speed_t()*tm)
	self.cur_node = (self.cur_node + speed)>self.count_node and self.count_node or (self.cur_node + speed)
	local p_l = {}
	local count = 0
	for i=cur,self.cur_node-1 do
		count = count + 1
		p_l[count] = self.path_l[i]
	end
	return p_l, self.path_l[self.cur_node-1]
end
function Ai_move:is_moving()
	if self.count_node == 0 or self.cur_node == self.count_node then
		return false
	end
	return true
end

--------event----------
function Ai_move:on_moving(tm)
	if _random(0,100) < 85 then
		if self:is_moving() and self.obj:is_alive() and self.obj:is_active() then
			local pos = self.obj:get_pos()
			local p_l,des_pos = self:get_cur_path(tm)

			--[[--广播屏内对象
			local new_pkt = {}
			new_pkt[1] = p_l
			new_pkt[2] = self.obj:get_id()
			new_pkt[3] = self.obj:get_speed_t()

			local scene_o = self.obj:get_scene_obj()
			scene_o:send_move_syn(self.obj:get_id(), self.obj, pos, des_pos, new_pkt)

			self.obj:set_pos(des_pos)]]--
			
			local movesyn = CmdMoveSyn()
			movesyn:setPathFromTable(p_l, #p_l)
			movesyn:setObjid(self.obj:get_id())
			movesyn:setSpeed(self.obj:get_speed_t())
			
			local scene_o = self.obj:get_scene_obj()
			scene_o:send_move_syn(self.obj:get_id(), self.obj, pos, des_pos, movesyn:serialize(), true)
			
			self.obj:set_pos(des_pos)
		end
	end
end

