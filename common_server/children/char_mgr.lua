
require("min_heap")
local TIME_SPAN = 20 * 60


Char_mgr = oo.class(nil, "Char_mgr")

function Char_mgr:__init()
	self.char_list = {}

	self.heap_l = Min_heap()
	self.container_list = {}

	self.outline_l = Min_heap()
	self.outline_container = {}
end

function Char_mgr:on_timer()
	
	while not self.heap_l:is_empty() do
		local heap_o = self.heap_l:top()
		local char_id = heap_o.value.char_o.char_id
		if heap_o.key <= ev.time then
			if g_player_mgr:is_online_char(char_id) then
				self.heap_l:pop()	
				heap_o.value.char_o:add_mood(-1)
				self:add_container(char_id)
			else
				self:del_container(char_id)
			end	
		else
			break
		end
	end
	--离线清缓存
	while not self.outline_l:is_empty() do
		local heap_o = self.outline_l:top()
		local char_id = heap_o.value.char_o.char_id
		if heap_o.key <= ev.time then
			if not g_player_mgr:is_online_char(char_id) then
				self.outline_l:pop()	
				self.char_list[char_id] = nil
			else
				self:add_container(char_id)
			end
		else
			break
		end
	end
end

function Char_mgr:get_click_param()
	return self, self.on_timer,10,nil	
end

function Char_mgr:get_click_param_ex()
	return self, self.on_timer_ex,125,nil
end

function Char_mgr:on_timer_ex()
	self:serialize_to_db()
end

--在线------------------------------------------------------------

function Char_mgr:add_container(char_id)
	if self.container_list[char_id] ~= nil then
		self.heap_l:erase(self.container_list[char_id])
	end

	local char_container = self.char_list[char_id]

	local key = char_container:get_online_time()
	local value = {}
	value.char_o = char_container
	self.container_list[char_id] = self.heap_l:push(key,value)

	--
	self:del_outline(char_id)
end

function Char_mgr:del_container(char_id)
	if self.container_list[char_id] == nil then return end
	
	self.heap_l:erase(self.container_list[char_id])
	self.container_list[char_id] = nil

	self:add_outline(char_id)
end

--离线------------------------------------------------------------

function Char_mgr:add_outline(char_id)
	if self.outline_container[char_id] ~= nil then
		self.outline_l:erase(self.outline_container[char_id])
	end

	local char_container = self.char_list[char_id]

	local key = ev.time + TIME_SPAN
	local value = {}
	value.char_o = char_container
	self.outline_container[char_id] = self.outline_l:push(key,value)
end

function Char_mgr:del_outline(char_id)
	if self.outline_container[char_id] == nil then return end
	
	self.outline_l:erase(self.outline_container[char_id])
	self.outline_container[char_id] = nil
end

---------------------------------------------------------------
function Char_mgr:get_container(char_id)
	if self.char_list[char_id] == nil then
		self.char_list[char_id] = self:create_container(char_id)
	end
	return self.char_list[char_id]
end

function Char_mgr:online(char_id)
	if self.char_list[char_id] == nil then
		self.char_list[char_id] = Char_container(char_id)
		self.char_list[char_id]:db_load()
	end
	--self.char_list[char_id]:reset_online_time()

	self:add_container(char_id)
	self.char_list[char_id]:update_online_child()
end

function Char_mgr:outline(char_id)
	self:del_container(char_id)
	local char_con = self.char_list[char_id]
	if char_con then
		if char_con:get_flag() == 1 then
			char_con:set_flag(0)
			char_con:serialize_to_db()
		end
	end
end

function Char_mgr:create_container(char_id)
	if self.char_list[char_id] == nil then
		self.char_list[char_id] = Char_container(char_id)
		self.char_list[char_id]:db_load()
	end

	self:add_container(char_id)
	return self.char_list[char_id]
end

function Char_mgr:load()
	
end

function Char_mgr:serialize_to_db()
	for k, v in pairs(self.char_list) do
		if v:get_flag() == 1 then
			v:set_flag(0)
			v:serialize_to_db()
		end
	end
end


--查看对方信息
function Char_mgr:get_other_info(pkt, server_id)
	local node = pkt
	g_sock_event_mgr:add_event_count(pkt.char_id_2, CMD_P2M_CHILD_OTHER_INFO_S, self, self.get_success, self.get_failed, node, 3, pkt)
	g_svsock_mgr:send_server_ex(server_id,pkt.char_id_2,CMD_P2M_CHILD_OTHER_INFO_C,pkt)
end

function Char_mgr:get_success(node, pkt)
	local server_id = g_player_mgr:get_map_id(node.char_id_1)
	local new_pkt = {}
	new_pkt[1] = pkt
	new_pkt[2] = node.char_id_2
	g_svsock_mgr:send_server_ex(server_id,node.char_id_1,CMD_M2P_CHILD_OTHER_INFO_C,new_pkt)
end

function Char_mgr:get_faild(node)
	if g_player_mgr:is_online_char(node.char_id_1) then
		
		local server_id = g_player_mgr:get_map_id(node.char_id_1)
		local char_con = self:get_container(node.char_id_2)
		local ret = {}
		ret[1] = char_con:serialize_to_net_ex()
		ret[2] = node.char_id_2
		g_svsock_mgr:send_server_ex(server_id,node.char_id_1,CMD_M2P_CHILD_OTHER_INFO_C,ret)
	end
end


--广播
function Char_mgr:bdc(flag, char_list, pkt)
	local new_pkt = {}
	new_pkt.flag = flag
	if flag == 1 then  --夫妻调戏
		new_pkt.mood = pkt.mood
	elseif flag == 2 then --道具调戏
		new_pkt.char_name = pkt.char_name
		new_pkt.item_name = pkt.item_name
		new_pkt.mood = pkt.mood 
		new_pkt.exp = pkt.exp
	elseif flag == 3 then --道具调戏buf
		new_pkt.skill_name = f_get_string(2712)
		new_pkt.mood = pkt.mood
		new_pkt.exp = pkt.exp
	end

	local ret = Json.Encode(new_pkt)
	for k,v in pairs(char_list) do
		if g_player_mgr:is_online_char(v) then
			g_svsock_mgr:send_server_ex(WORLD_ID, v, CMD_WORLD_CHILD_BDC_C, ret, true)
		end
	end
end

-- 通过仙灵id从数据库获取仙灵的消息，用于仙灵排行
-- rows包含char_id, child_id和info
function Char_mgr:get_child_info_from_db(child_id)
	local db = f_get_db()
	local query = string.format("{child_id:'%s'}", child_id)
	local rows, e_code = db:select_one("children_info", "{_id:0}", query)
	return e_code, rows
end