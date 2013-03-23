
local _sec = 30   --延时秒数
local _dis = 60   --切磋半径

Compete_mgr = oo.class(nil, "Compete_mgr")

function Compete_mgr:__init()
	self.compete_l = {}

	--邀请列表
	self.request_l = {}
	self.time_count = 0
end

--增加邀请
function Compete_mgr:add_request(obj_id, guest_id)
	--print("----Compete_mgr:add_request", obj_id, guest_id)

	local obj = g_obj_mgr:get_obj(obj_id)
	local obj_d = g_obj_mgr:get_obj(guest_id)
	
	if obj ~= nil and obj_d ~= nil and obj_d:get_type() == OBJ_TYPE_HUMAN then
		self.request_l[obj_id] = {}
		self.request_l[obj_id]["time"] = ev.time + _sec
		self.request_l[obj_id]["name"] = obj:get_name()
		self.request_l[obj_id]["guest_id"] = guest_id
		return true
	end
end

function Compete_mgr:is_request(obj_id)
	local ret = self.request_l[obj_id] ~= nil and self.request_l[obj_id]["time"] >= ev.time
	if not ret then
		self:del_request(obj_id)
	end

	return ret
end

function Compete_mgr:del_request(obj_id)
	self.request_l[obj_id] = nil
end

--创建
function Compete_mgr:create(obj, obj_d) 
	if self.request_l[obj:get_id()] ~= nil then
		self.request_l[obj:get_id()] = nil

		local cp_o = Obj_compete(obj, obj_d)
		self.compete_l[cp_o:get_id()] = cp_o
		obj:set_compete(cp_o:get_id())
		obj_d:set_compete(cp_o:get_id())

		--scene
		local str = obj:get_name() .. " vs " .. obj_d:get_name()
		local flag_obj = f_npc_create_enter(NPC_OCC_FLAG, str, cp_o:get_flag_pos(), cp_o:get_scene())

		cp_o:set_flag_id(flag_obj:get_id())
		return cp_o
	end
end

--结束
function Compete_mgr:close(id, fail_id)
	local cp_o = self.compete_l[id]
	if cp_o ~= nil then
		--网络广播
		local new_pkt = cp_o:net_get_end_info(fail_id)
		local host = cp_o:get_host()
		local scene_o = host:get_scene_obj()
		scene_o:send_screen(host:get_id(), CMD_MAP_COMPETE_END_S, new_pkt, 1)

		f_npc_leave(cp_o:get_flag_id())

		cp_o:close(fail_id)
		self.compete_l[id] = nil
	end
end

function Compete_mgr:distance(cur_pos, des_pos)
	local d_x = math.pow(cur_pos[1] - des_pos[1], 2)
	local d_y = math.pow(cur_pos[2] - des_pos[2], 2)
	return math.floor(math.sqrt(d_x + d_y))
end

-----------event----------
--[[function Compete_mgr:get_click_param()
	return self, self.on_timer, 5, nil
end

function Compete_mgr:on_timer(tm)
	self.time_count = self.time_count + 1
	if self.time_count >= math.floor(5/tm) then
		self.time_count = 0

		for k,v in pairs(self.request_l) do
			self.request_l[k]["time"] = self.request_l[k]["time"] - 5
			if self.request_l[k]["time"] <= 0 then
				self.request_l[k] = nil
			end
		end
	end
end]]

--玩家移动事件
function Compete_mgr:on_move(id, obj_id, scene_id, pos)
	local cp_o = self.compete_l[id]
	if cp_o ~= nil then
		local flag_pos = cp_o:get_flag_pos()
		if cp_o:get_scene()[1] ~= scene_id or self:distance(flag_pos, pos) >= _dis then
			self:close(id, obj_id)
		end
	end
end

--玩家结束事件
function Compete_mgr:on_end(id, obj_id)
	local cp_o = self.compete_l[id]
	if cp_o ~= nil then
		self:close(id, obj_id)
	end
end