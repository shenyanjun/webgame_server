
Obj_compete = oo.class(nil, "Obj_compete")

function Obj_compete:__init(obj, obj_d)
	--print("-----Obj_compete:__init1", obj:get_scene()[1], obj:get_pos()[1], obj:get_pos()[2])
	self.id = crypto.uuid()
	self.host = obj
	self.guest = obj_d

	--插旗坐标
	self.scene_id = table.copy(obj:get_scene())

	local scene_o = obj:get_scene_obj()
	local map_o = scene_o:get_map_obj()
	self.flag_pos = map_o:middle_pos(obj:get_pos(), obj_d:get_pos())
	--self.flag_pos = table.copy(obj:get_pos())
	self.flag_id = nil 

	--print("-----Obj_compete:__init2", obj:get_pos())
end

function Obj_compete:get_id()
	return self.id
end

function Obj_compete:get_host()
	return self.host
end

function Obj_compete:get_scene()
	return self.scene_id
end
function Obj_compete:get_flag_pos()
	return self.flag_pos
end
function Obj_compete:get_flag_id()
	return self.flag_id 
end
function Obj_compete:set_flag_id(f_id)
	self.flag_id = f_id
end

function Obj_compete:close(fail_id)
	self.host:set_compete(nil)
	self.guest:set_compete(nil)
	self.host = nil
	self.guest = nil
end


-------网络通信---------
--开始信息
function Obj_compete:net_get_info()
	local tb = {}
	tb.compete_id = self.id
	tb.host_id = self.host:get_id()
	tb.guest_id = self.guest:get_id()
	tb.x = self.flag_pos[1]
	tb.y = self.flag_pos[2]
	return tb
end

--结束信息
function Obj_compete:net_get_end_info(fail_id)
	local tb = {}
	tb.compete_id = self.id
	tb.win_id = self.host:get_id() == fail_id and self.guest:get_id() or self.host:get_id()
	tb.win_name = self.host:get_id() == fail_id and self.guest:get_name() or self.host:get_name()
	tb.fail_id = self.host:get_id() ~= fail_id and self.guest:get_id() or self.host:get_id()
	tb.fail_name = self.host:get_id() ~= fail_id and self.guest:get_name() or self.host:get_name()
	return tb
end