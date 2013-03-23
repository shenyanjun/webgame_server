
require("min_heap")

Impact_mgr = oo.class(nil, "Impact_mgr")

function Impact_mgr:__init()
	self.impact_list_h = {}    --保存玩家堆索引
	self.impact_list_m = {}    --保存怪物堆索引
	self.heap_1 = Min_heap()
end

function Impact_mgr:get_realy_impact_list(obj_id)
	if Obj_mgr.obj_type(self.obj_id) == OBJ_TYPE_MONSTER then
		return self.impact_list_m
	end

	return self.impact_list_h
end

function Impact_mgr:add_timer(obj_id, impact_id, impact_o)
	local impact_list_s = self:get_realy_impact_list(obj_id)

	if impact_list_s[obj_id] == nil then
		impact_list_s[obj_id] = {}
	end

	if impact_list_s[obj_id][impact_id] ~= nil then
		self.heap_1:erase(impact_list_s[obj_id][impact_id])
	end

	local key = impact_o:get_event_time()
	local value = {}
	value.obj_id = obj_id
	value.impact_id = impact_id
	value.impact_o = impact_o
	impact_list_s[obj_id][impact_id] = self.heap_1:push(key, value)
end

function Impact_mgr:del_timer(obj_id, impact_id)
	local impact_list_s = self:get_realy_impact_list(obj_id)
	if impact_list_s[obj_id] == nil or impact_list_s[obj_id][impact_id] == nil then 
		--print("Error:Impact_mgr:del_timer is nil", obj_id, impact_id)
		return 
	end

	self.heap_1:erase(impact_list_s[obj_id][impact_id])
	impact_list_s[obj_id][impact_id] = nil
end

function Impact_mgr:clear(obj_id, impact_id)
	local impact_list_s = self:get_realy_impact_list(obj_id)
	if impact_list_s[obj_id] == nil or impact_list_s[obj_id][impact_id] == nil then 
		--print("Error:Impact_mgr:clear is nil", obj_id, impact_id)
		return 
	end

	impact_list_s[obj_id][impact_id] = nil
end

function Impact_mgr:clear_impact_list(obj_id)
	local impact_list_s = self:get_realy_impact_list(obj_id)
	for k, v in pairs(impact_list_s[obj_id] or {}) do
		self.heap_1:erase(v)
	end
	impact_list_s[obj_id] = nil
end

function Impact_mgr:get_click_param()
	return self, self.on_timer, 1, nil
end

function Impact_mgr:on_timer(tm)
	local obj_mgr = g_obj_mgr
	while not self.heap_1:is_empty() do
		local heap_o = self.heap_1:top()
		if heap_o.key <= ev.time then
			self.heap_1:pop()
			self:clear(heap_o.value.obj_id, heap_o.value.impact_id)

			local obj = obj_mgr:get_obj(heap_o.value.obj_id)
			if obj ~= nil then
				if heap_o.value.impact_o:on_process() ~= -1 then
					self:add_timer(heap_o.value.obj_id, heap_o.value.impact_id, heap_o.value.impact_o)
				else
					local impact_con = obj:get_impact_con()
					impact_con:del_impact(heap_o.value.impact_id)
				end
			end
		else
			break
		end
	end
end

