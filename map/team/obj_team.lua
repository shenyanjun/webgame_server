
local _max = 5    --组成员上限
local _sec = 20   --邀请延时秒数
local _ask_c = 20 --申请列表上限
local _gt_sec = 20 --集合标志时间上限

TEAM_ALLOC_MODE = {
	RANDOM_MODE = 0,		--随机模式
	ORDER_MODE = 1,			--轮流模式
	FREEDOM_MODE = 2,		--自由模式
}

Obj_team = oo.class(nil, "Obj_team")

function Obj_team:__init(team_id)
	self.id = team_id or crypto.uuid()
	self.teamer_id = nil
	self.team_l = {}
	self.count = 0

	--入队邀请列表
	self.request_l = {}
	--入队申请列表
	self.ask_count = 0
	self.ask_l = {}

	--集合标志
	self.gather_l = {}

	--self.alloc_mode = TEAM_ALLOC_MODE.FREEDOM_MODE	--分配模式,默认为自由
	self.alloc_mode = TEAM_ALLOC_MODE.RANDOM_MODE	--分配模式,默认为随机
	
	--组设置:1队员邀请 2自由进入
	self.setting = {0,0}  --(0 非 1是) 
	
	self.fun_ack_l = {}
end

function Obj_team:get_id()
	return self.id
end

--分配模式
function Obj_team:get_alloc_mode()
	return self.alloc_mode
end
function Obj_team:set_alloc_mode(char_id, mode)
	if char_id == self.teamer_id then
		self.alloc_mode = mode
		return true
	end
	return false
end

--组设置
function Obj_team:get_setting(ty)
	return self.setting[ty]
end
function Obj_team:set_setting(ty, fg)
	self.setting[ty] = fg
	return true
end

function Obj_team:new(obj_id)
	self.teamer_id = obj_id
	local ret = self:add_obj(obj_id)
	return ret
end
function Obj_team:add_obj(obj_id)
	local obj = g_obj_mgr:get_obj(obj_id)
	if obj == nil then return false end

	if self.team_l[obj_id] == nil and self.count < _max then
		self.count = self.count + 1
		self.team_l[obj_id] = self:create_member(obj_id)
		
		--同步信息
		self:syn()
		self:pos_syn(obj_id, 1)
		obj:set_team(self.id)

		for k,v in pairs(self.team_l) do
			if k ~= obj_id and v.status ~= LINE_OFF then
				f_cmd_show(k, 20102, obj:get_name())
			end
		end
		f_cmd_show(obj_id, 20103)
		
		local args = {}
		args.team_id = self.id
		g_event_mgr:notify_event(EVENT_SET.EVENT_ADD_TEAM, obj_id, args)

		return true
	end
	return false
end

function Obj_team:del_obj(obj_id)
	local obj = g_obj_mgr:get_obj(obj_id)
	if self.team_l[obj_id] ~= nil then
		--如果是组长，换人
		if obj_id == self.teamer_id then
			for k,v in pairs(self.team_l) do
				if k ~= self.teamer_id and v.status == LINE_ON then
					self.teamer_id = k
					local obj_d = g_obj_mgr:get_obj(k)
					if obj_d ~= nil then
						obj_d:on_dress_update(3)
					end
					--g_event_mgr:notify_event(EVENT_SET.EVENT_TEAM_CAPTAIN, k, nil)
					break
				end
			end	
		end

		self.team_l[obj_id] = nil
		self.count = self.count - 1
		if obj ~= nil then
			--踢出副本

			obj:set_team(nil)

			for k,v in pairs(self.team_l) do
				if k ~= obj_id and v.status ~= LINE_OFF then
					f_cmd_show(k, 20110, obj:get_name())
				end
			end
			f_cmd_show(obj_id, 20111)
			
			local args = {}
			args.team_id = self.id
			args.char_id = obj_id
			g_event_mgr:notify_event(EVENT_SET.EVENT_DEL_TEAM, obj_id, args)		
		end
		return true
	end
	return false
end
--更新成员信息，obj_id为nil则更新所有成员
--[[function Obj_team:update(obj_id)
	if obj_id == nil then
		for k,v in pairs(self.team_l) do
			local obj = g_obj_mgr:get_obj(k)
			if obj ~= nil then
				self.team_l[k] = self:create_member(k)
			else
				self.team_l[k]["status"] = LINE_OFF
			end
		end
	else
		local obj = g_obj_mgr:get_obj(obj_id)
		if obj ~= nil then
			self.team_l[obj_id] = self:create_member(obj_id)
		else
			self.team_l[obj_id]["status"] = LINE_OFF
		end
	end
end]]
--创建一个成员
function Obj_team:create_member(obj_id)
	local obj = g_obj_mgr:get_obj(obj_id)
	local t = {}
	if obj ~= nil then
		t["obj_id"] = obj_id
		t["name"] = obj:get_name()
		t["gender"] = obj:get_sex()
		t["level"] = obj:get_level()
		t["occ"] = obj:get_occ()
		t["status"] = LINE_ON
		--t["hp"] = obj:get_hp()
		--t["mp"] = obj:get_mp()
		return t
	end
end

function Obj_team:is_full()
	if self.count >= _max then
		return true
	end
	return false
end

--组长
function Obj_team:set_teamer_id(teamer_id)
	self.teamer_id = teamer_id
end
function Obj_team:get_teamer_id()
	return self.teamer_id
end
function Obj_team:is_member(obj_id)
	return self.team_l[obj_id] ~= nil
end
--获取组
function Obj_team:get_team_l()
	return self.team_l, self.count
end
--获取在线人数
function Obj_team:get_line_count()
	local count = 0
	for k,v in pairs(self.team_l) do
		if v.status == LINE_ON then
			count = count + 1
		end
	end
	return count
end

--移交
function Obj_team:transfer(obj_id)
	if obj_id == self.teamer_id then
		return 20104
	end
	if self.team_l[obj_id] == nil then
		return 20105
	end

	self.teamer_id = obj_id
	return 0
end

--玩家下线
function Obj_team:outline(obj_id)
	local change_captain = obj_id == self.teamer_id
	if change_captain then
		for k,v in pairs(self.team_l) do
			if k ~= self.teamer_id and v.status == LINE_ON then
				self.teamer_id = k
				local obj = g_obj_mgr:get_obj(k)
				local _ = obj and obj:on_dress_update(3)
				break
			end
		end	
	end
	self.team_l[obj_id]["status"] = LINE_OFF
	self:syn(obj_id)
	
	if change_captain then
		g_event_mgr:notify_event(EVENT_SET.EVENT_TEAM_CAPTAIN, self.teamer_id, nil)
	end
	--法宝组队buff
	local teamer = g_obj_mgr:get_obj(self.teamer_id)
	local _ = teamer and f_deal_player_skill_magic_team(teamer)
end
--玩家上线
function Obj_team:online(obj_id)
	self.team_l[obj_id]["status"] = LINE_ON
	self:syn(obj_id)
end

--解散组
function Obj_team:remove()
	--踢出副本
	g_scene_mgr_ex:unregister_instance(self.id)

	for k,_ in pairs(self.team_l) do
		local obj = g_obj_mgr:get_obj(k)
		if obj ~= nil then
			obj:set_team(nil)
			g_cltsock_mgr:send_client(k, CMD_MAP_TEAM_LEAVE_SYN_S, {})
			--法宝组队buff
			f_deal_player_skill_magic_team(obj)
		end
	end

	self.team_l = {}
	self.count = 0
end

--增加邀请(src_obj_id 邀请者id)
function Obj_team:add_request(obj_id, src_obj_id)
	local obj = g_obj_mgr:get_obj(obj_id)
	if obj == nil then return false end

	self.request_l[obj_id] = {["time"]=ev.time + _sec,["name"]=obj:get_name(),["src_obj_id"] = src_obj_id}
end
--删除邀请
function Obj_team:del_request(obj_id)
	self.request_l[obj_id] = nil
end

function Obj_team:is_request(obj_id)
	return self.request_l[obj_id] ~= nil and self.request_l[obj_id]["time"] >= ev.time
end
--获取邀请者id
function Obj_team:get_request_src_obj_id(obj_id)
	return self.request_l[obj_id] and self.request_l[obj_id]["src_obj_id"]
end


--增加申请
function Obj_team:add_ask(obj_id)
	local obj = g_obj_mgr:get_obj(obj_id)
	if obj == nil then return false end
	if self.ask_l[obj_id] ~= nil then return end

	if self.ask_count >= _ask_c then
		self:sort_ask_l()
	end

	local t = {}
	t["obj_id"] = obj_id
	t["time"] = ev.time
	self.ask_l[obj_id] = t
	self.ask_count = self.ask_count + 1
end
function Obj_team:sort_ask_l()
	local o_id,tm
	for k,v in pairs(self.ask_l) do
		o_id = k
		tm = v.time
		if tm > v.time then
			o_id = k
			tm = v.time
		end
	end
	self:del_ask(o_id)
	--table.sort(self.ask_l, function(o1,o2) return o1.time > o2.time end)
end
function Obj_team:del_ask(obj_id)
	if self.ask_l[obj_id] ~= nil then
		self.ask_l[obj_id] = nil
		self.ask_count = self.ask_count - 1
	end
end

function Obj_team:is_ask(obj_id)
	--[[for _,v in pairs(self.ask_l) do
		if v.obj_id == obj_id then
			return true
		end
	end
	return false]]
	return self.ask_l[obj_id] ~= nil
end

--增加集合标志(type: 1正常集合 2副本集合)
function Obj_team:add_gather_flag(obj_id, scene_id, type)
	type = type or 1
	local c = 0
	local list = {}
	local t_obj = g_obj_mgr:get_obj(obj_id)
	local scene_o = t_obj:get_scene_obj()
	for k,v in pairs(self:get_team_l()) do
		local obj = g_obj_mgr:get_obj(k)
		if obj ~= nil and obj:is_carry(scene_o:get_id()) == 0 and obj_id ~= k and v.status == LINE_ON then
			local ret = type == 1 and scene_o:can_carry(obj) or 0
			if ret == 0 then
				self.gather_l[k] = {["time"]=ev.time + _gt_sec,["scene_id"]=scene_id}
				g_cltsock_mgr:send_client(k, CMD_MAP_TEAM_GATHER_ANSWER_S, {["type"]=type})
			else
				local t = {}
				t.obj_id = k
				t.error = ret

				c = c + 1
				list[c] = t
			end
		end
	end

	--返回不符合条件的成员信息给队长
	if c > 0 then
		local new_pkt = {}
		new_pkt.list = list
		g_cltsock_mgr:send_client(obj_id, CMD_MAP_TEAM_GATHER_ANSWER_ERR_S, new_pkt)
	end
end
--删除集合标志
function Obj_team:del_gather_flag(obj_id)
	self.gather_l[obj_id] = nil
end
function Obj_team:is_gather_flag(obj_id, scene_id)
	if self.gather_l[obj_id] ~= nil and 
		self.gather_l[obj_id]["scene_id"] == scene_id and 
		self.gather_l[obj_id]["time"] >= ev.time then
		return true
	end
	
	self.gather_l[obj_id] = nil
	return false
end


--------网络通信--------
function Obj_team:net_get_info()
	local t = {}
	t.team_id = self.id
	t.teamer = self.teamer_id
	t.list = {}
	local c = 1
	for _,v in pairs(self.team_l) do
		t.list[c] = v
		c = c + 1
	end
	t.mode = self.alloc_mode
	t.setting = self.setting
	return t
end
--flag：nil, 更新所有 1，血更新，2，魔更新，3 效果更新
function Obj_team:net_get_instant_info(obj_id, flag)
	local obj = g_obj_mgr:get_obj(obj_id)
	if obj_id ~= nil and obj ~= nil and self.team_l[obj_id] ~= nil then
		local t = {}
		t.obj_id = obj_id
		if flag == nil then
			t.hp = obj:get_hp()
			t.mp = obj:get_mp()
			t.max_hp = obj:get_max_hp()
			t.max_mp = obj:get_max_mp()

			local impact_o = obj:get_impact_con()
			local pkt = impact_o:net_get_info()
			t.impact_l = pkt.list
		elseif flag == 1 then
			t.hp = obj:get_hp()
			t.max_hp = obj:get_max_hp()
			--更新level
			self.team_l[obj_id]["level"] = obj:get_level()
		elseif flag == 2 then
			t.mp = obj:get_mp()
			t.max_mp = obj:get_max_mp()
		elseif flag == 3 then
			local impact_o = obj:get_impact_con()
			local pkt = impact_o:net_get_info()
			t.impact_l = pkt.list
		end

		return t
	end
end

--坐标更新
function Obj_team:net_get_pos_info(obj_id)
	local obj = g_obj_mgr:get_obj(obj_id)
	if obj_id ~= nil and obj ~= nil and self.team_l[obj_id] ~= nil then
		local pos = obj:get_pos()
		local t = {}
		t.obj_id = obj_id
		t.map_id = obj:get_map_id()
		t.x = pos[1]
		t.y = pos[2]
		return t
	end
end

function Obj_team:net_get_ask_info()
	local t = {}
	t.list = {}
	local c = 1
	local del_l = {}
	for _,v in pairs(self.ask_l) do
		local obj = g_obj_mgr:get_obj(v.obj_id)
		if obj ~= nil then
			t.list[c] = {}
			t.list[c]["obj_id"] = v.obj_id
			t.list[c]["name"] = obj:get_name()
			t.list[c]["level"] = obj:get_level()
			t.list[c]["occ"] = obj:get_occ()
			t.list[c]["gender"] = obj:get_sex()
			c = c + 1
		else
			del_l[v.obj_id] = 1
		end
	end

	--清除不在线的申请者
	for k,_ in pairs(del_l) do
		self:del_ask(k)
	end

	return t
end
--组员基本信息同步
function Obj_team:syn(obj_id)
	--self:update(obj_id)

	local new_pkt = self:net_get_info()
	for k,v in pairs(self.team_l) do
		if k ~= obj_id and v.status ~= LINE_OFF then
			g_cltsock_mgr:send_client(k, CMD_MAP_TEAM_SYN_S, new_pkt)
		end
	end
end
--组员即时信息同步
function Obj_team:instant_syn(obj_id, flag)
	local new_pkt = self:net_get_instant_info(obj_id, flag)
	if new_pkt ~= nil then
		new_pkt = Json.Encode(new_pkt or {})
		for k,v in pairs(self.team_l) do
			if k ~= obj_id and v.status ~= LINE_OFF then
				g_cltsock_mgr:send_client(k, CMD_MAP_TEAM_INSTANT_SYN_S, new_pkt, true)
			end
		end
	end
end
--组员拾取广播
function Obj_team:stuff_syn(obj_id, item_list)
	local new_pkt = {}
	new_pkt.obj_id = obj_id
	new_pkt.list = {}

	if not item_list then
		return
	end


	local count = 0;
	for _, item in pairs(item_list) do
		if item:get_color() > 2 then			--过滤蓝色以下的物品不过行广播
			local value = {}
			value.name = item:get_name()
			value.color = item:get_color()
			table.insert(new_pkt.list, value)
			count = count + 1
		end	
	end

	if 0 == count then		--列表为空则不更新
		return
	end

	new_pkt = Json.Encode(new_pkt or {})
	for k,v in pairs(self.team_l) do
		if v.status ~= LINE_OFF then
			g_cltsock_mgr:send_client(k, CMD_MAP_TEAM_STUFF_SYN_S, new_pkt, true)
		end
	end
end

--组位置信息更新(flag:非nil相互同步)
function Obj_team:pos_syn(obj_id, flag)
	local new_pkt = self:net_get_pos_info(obj_id)
	if new_pkt ~= nil then
		new_pkt = Json.Encode(new_pkt or {})
		for k,v in pairs(self.team_l) do
			if k ~= obj_id and v.status ~= LINE_OFF then
				g_cltsock_mgr:send_client(k, CMD_MAP_TEAM_POS_SYN_S, new_pkt, true)
				if flag ~= nil then
					local pkt = self:net_get_pos_info(k)
					if pkt ~= nil then
						g_cltsock_mgr:send_client(obj_id, CMD_MAP_TEAM_POS_SYN_S, pkt)
					end
				end
			end
		end
	end
end

--组员换名，转职，转性后基本信息同步
function Obj_team:change_syn(obj_id)
	local obj = g_obj_mgr:get_obj(obj_id)
	if obj == nil or self.team_l[obj_id] == nil then return end

	self.team_l[obj_id].name = obj:get_name()
	self.team_l[obj_id].gender = obj:get_sex()
	self.team_l[obj_id].level = obj:get_level()
	self.team_l[obj_id].occ = obj:get_occ()
	--同步信息
	self:syn(obj_id)
end

function Obj_team:add_ack(type, timeout, callback, failed_closure)
	self.fun_ack_l[type] = {
		["timeout"] = ev.time + timeout
		, ["callback"] = callback
		, ["failed"] = failed_closure
		, ["list"] = {}
	}
end

function Obj_team:ack_request(type, obj_id, is_ok)
	if not self.team_l[obj_id] then
		return
	end
	
	local info = self.fun_ack_l[type]
	if not info then
		return
	end

	if 1 ~= is_ok or ev.time > info.timeout then
		self.fun_ack_l[type] = nil
		if info.failed then
			info.failed(self, obj_id)
		end
		return
	end
	
	info.list[obj_id] = true
	local all_ok = true
	for k, _ in pairs(self.team_l) do
		if not info.list[k] then
			all_ok = false
			break
		end
	end

	if all_ok then
		if info.callback then
			info.callback()
		end
		self.fun_ack_l[type] = nil
	end
end

-------------event------------


--[[function Obj_team:on_timer(tm)
	--邀请
	for k,v in pairs(self.request_l) do
		self.request_l[k]["time"] = self.request_l[k]["time"] - tm
		if self.request_l[k]["time"] <= 0 then
			self:del_request(k)
		end
	end

	--集合
	for k,v in pairs(self.gather_l) do
		self.gather_l[k]["time"] = self.gather_l[k]["time"] - tm
		if self.gather_l[k]["time"] <= 0 then
			self:del_gather_flag(k)
		end
	end
end]]
