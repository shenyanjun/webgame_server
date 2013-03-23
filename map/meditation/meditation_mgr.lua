--2011-03-25
--laojc
--打坐管理类

Meditation_mgr = oo.class(nil,"Meditation_mgr")

function Meditation_mgr:__init()
	self.meditation_list = {}       --char_id,meditation

	self.request_char = {}

	self.heap = Min_heap()
	self.meditation_id_list = {}
end

function Meditation_mgr:on_timer()
	--for k,v in pairs (self.meditation_list or {}) do
		--if v:get_flag() ~= 0 and v:get_flag() ~= nil then
			--v:add_expr()
		--end
	--end

	while not self.heap:is_empty() do
		local heap_o = self.heap:top()
		if heap_o.key <= ev.time then
			self.heap:pop()
			heap_o.value.meditation_obj:add_expr()
			if heap_o.value.meditation_obj:get_flag() ~= 0 and heap_o.value.meditation_obj:get_flag() ~= nil then
				self:add_heap_obj(heap_o.value.meditation_obj.char_id)
			end
		else
			break
		end
	end

end

function Meditation_mgr:get_click_param()
	return self, self.on_timer,2,nil	
end

--添加到heap里面的对象
function Meditation_mgr:add_heap_obj(char_id)
	if self.meditation_id_list[char_id] ~= nil then
		self.heap:erase(self.meditation_id_list[char_id])
		self.meditation_id_list[char_id] = nil
	end
	local key = self.meditation_list[char_id]:get_start_time()
	local value = {}
	value.meditation_obj = self.meditation_list[char_id]
	self.meditation_id_list[char_id] = self.heap:push(key,value)
end

--删除heap里面的对象
function Meditation_mgr:del_heap_obj(char_id)
	if self.meditation_id_list[char_id] == nil then return end
	self.heap:erase(self.meditation_id_list[char_id])
	self.meditation_id_list[char_id] = nil
end


--邀请
function Meditation_mgr:add_request(char_id_d,char_id_s)
	if self.request_char[char_id_d] == nil then
		self.request_char[char_id_d] = {}
	end
	table.insert(self.request_char[char_id_d],char_id_s)
end

function Meditation_mgr:del_request(char_id)
	self.request_char[char_id] = nil
end

function Meditation_mgr:get_request(char_id_s,char_id_d)
	for k,v in pairs(self.request_char[char_id_s] or {}) do
		if v == char_id_d then
			return 0
		end
	end
	return 1
end

--[[-------------------------------------------------------------------
add_container:双人修炼
del_container:修炼终止，如果它是双人修炼，则其他人会变成单修
]]
function Meditation_mgr:add_container(char_id_s,char_id_d)

	if not self:get_meditation(char_id_s) then
		self:set_meditation(Meditation_container(char_id_s))
	end
	if not self:get_meditation(char_id_d) then
		self:set_meditation(Meditation_container(char_id_d))
	end

	local uuid = crypto.uuid()
	local meditation_s = self:get_meditation(char_id_s)
	local meditation_d = self:get_meditation(char_id_d)
	meditation_s:set_uuid(uuid)
	meditation_d:set_uuid(uuid)
	meditation_s:set_flag(2)
	meditation_d:set_flag(2)

	local player_s = g_obj_mgr:get_obj(char_id_s)
	local player_d = g_obj_mgr:get_obj(char_id_d)

	local ret_s = {}
	ret_s[1] = char_id_s
	ret_s[2] = char_id_d
	player_s:set_meditation_status_l(ret_s)

	local ret_d = {}
	ret_d[1] = char_id_d
	ret_d[2] = char_id_s
	player_d:set_meditation_status_l(ret_d)
end

function Meditation_mgr:del_container(char_id)
	if self.meditation_list[char_id] ~= nil and self.meditation_list[char_id]:get_flag() ~= 0 then
		local uuid = self.meditation_list[char_id]:get_uuid()
		local obj_mgr = g_obj_mgr
		for k,v in pairs(self.meditation_list or {}) do
			if char_id == k then
				if v:get_flag() ~= 0 then
					v:set_flag(0)
					v:set_uuid(crypto.uuid())
					
					local player = obj_mgr:get_obj(char_id)
					player:set_meditation_status_l({})
				end
			elseif v:get_uuid() == uuid then
				if v:get_flag() == 2 then
					v:set_flag(1)

					local player = obj_mgr:get_obj(v.char_id)
					local ret = {}
					ret[1] = v.char_id
					player:set_meditation_status_l(ret)
				end
			end
		end
	end
end

------------------------------------------------------------------
function Meditation_mgr:set_meditation(meditation)
	local char_id = meditation.char_id
	self.meditation_list[char_id] = meditation
end

function Meditation_mgr:get_meditation(char_id)
	return self.meditation_list[char_id]
end

------------------------------------------------------------------
function Meditation_mgr:login(char_id)
	self.meditation_list[char_id] = Meditation_container(char_id)
end

function Meditation_mgr:level_up_init(char_id)
	self:login(char_id)
end

function Meditation_mgr:logout(char_id)
	self:del_container(char_id)
	self:del_heap_obj(char_id)
	self.meditation_list[char_id] = nil
end

--使用技能单修
function Meditation_mgr:use_skill(char_id)
	local meditation = self:get_meditation(char_id)
	meditation:set_flag(1)
	local player = g_obj_mgr:get_obj(char_id)
	local ret = {}
	ret[1] = char_id
	player:set_meditation_status_l(ret)
end

