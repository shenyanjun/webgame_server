

-- 帮派战管理类，负责管理已回应的战书

Faction_battle_mgr = oo.class(nil, "Faction_battle_mgr")

function Faction_battle_mgr:__init()
	self.faction_battle_l = {}			-- 帮派战的对象列表
	self.accept_battle_letter_l = {}	-- 接受回战的约战书对象
	self.battle_letter_l = {}			-- 所有的战书对象
	self.today_time = f_get_today(ev.time)
	self.tomorrow_time = f_get_tomorrow(ev.time)
end

--打开面版是返回所需信息
function Faction_battle_mgr:get_all_battle_info(char_id)
	--print("Faction_battle_mgr:get_all_battle_info()", char_id)
	local ret = {}
	--
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	local faction_id = faction and faction:get_faction_id()
	local f_b = faction_id and self.faction_battle_l[faction_id]
	ret.recv_letter = f_b and f_b:get_recv_letter_info() or {}
	ret.my_letter = f_b and f_b:get_send_letter_info() or {}
	--
	local b_fid = ret.my_letter[2]

	ret.f_list = {}
	for k,v in pairs (g_faction_mgr.faction_list or {}) do
		local faction=g_faction_mgr.faction_list[k]
		if faction ~= nil and faction:get_dissolve_flag() == 0 then
			local entry = faction:get_faction_info_for_battle()
			local f_b = self.faction_battle_l[k]
			--entry[6] = f_b and f_b.win_t or 0
			--entry[7] = f_b and f_b.lost_t or 0
			entry[6] = f_b and f_b.battle_r[faction_id] and f_b.battle_r[faction_id][1] or 0
			entry[7] = f_b and f_b.battle_r[faction_id] and f_b.battle_r[faction_id][2] or 0
			if entry[1] == b_fid then
				table.insert(ret.f_list, 1, entry)				
			else
				table.insert(ret.f_list, entry)
			end
		end
	end
	-- 
	
	return ret
end

function Faction_battle_mgr:can_apply_battle(char_id, f_id_reply, time)
	local ret = self:auth(char_id, 0, nil)
	if ret ~= 0 then
		return ret
	end
	local today_time = f_get_today(ev.time)
	if ev.time - today_time + FACTION_BATTLE_EARLIER_TIME_M * 60 > time then
		return 21080
	end

	-- 同一时间段的约战数
	if self:get_remainder_times(time) <= 0 then
		return 21074
	end

	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	local f_id_apply = faction and faction:get_faction_id()
	if f_id_apply == nil then return 21085 end
	if faction:get_dissolve_flag() ~= 0 then
		return 21090
	end

	if faction:get_level() < FACTION_BATTLE_MIN_LEVEL then
		return 21092
	end

	local f_b_a = self.faction_battle_l[f_id_apply]
	ret = f_b_a and f_b_a:can_send_letter(time) or 0
	if ret ~= 0 then
		return ret
	end

	local faction_r = g_faction_mgr:get_faction_by_fid(f_id_reply)
	if faction_r == nil then
		return 21072
	end

	if faction_r:get_level() < FACTION_BATTLE_MIN_LEVEL then
		return 21093
	end

	local f_b_r = self.faction_battle_l[f_id_reply]
	ret = f_b_r and f_b_r:can_recv_letter(time) or 0
	
	return ret
end


--公共服 生成一个战书
function Faction_battle_mgr:build_battle_lettle(char_id, f_id_reply, time, battle_type, wager_type, wager)
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	local f_id_apply = faction and faction:get_faction_id()
	if f_id_apply == nil then return end
	local f_b_a = self.faction_battle_l[f_id_apply]
	if f_b_a == nil then
		self.faction_battle_l[f_id_apply] = Faction_battle(f_id_apply)
		f_b_a = self.faction_battle_l[f_id_apply]
	end

	local f_b_r = self.faction_battle_l[f_id_reply]
	if f_b_r == nil then
		self.faction_battle_l[f_id_reply] = Faction_battle(f_id_reply)
		f_b_r = self.faction_battle_l[f_id_reply]
	end

	--战书对象
	local battle_letter = Faction_battle_letter(f_id_apply, f_id_reply, time, battle_type)
	battle_letter.applyer = char_id
	battle_letter.wager_type = wager_type or 0
	battle_letter.wager = wager or 0
	f_b_a:send_letter(battle_letter.id)
	f_b_r:recv_letter(battle_letter.id)

	--
	self.battle_letter_l[battle_letter.id] = battle_letter

	-- 同步
	local pkt = self:get_syn_info(1, battle_letter.id)
	g_server_mgr:send_to_all_map(0, CMD_C2M_FACTION_BATTLE_SYN_S, pkt)

	--发邮件给对方帮主
	local faction_r = g_faction_mgr:get_faction_by_fid(f_id_reply)
	local recevier_id = faction_r:get_factioner_id()
	local content = faction:get_faction_name() .. f_get_string(2230)
	g_email_mgr:create_email(-1, recevier_id, f_get_string(2229), content, 0, 1, 0, {})

	return f_id_apply, battle_letter.id
end


function Faction_battle_mgr:can_accept_letter(char_id, l_id)
	local ret = self:auth(char_id, 1, l_id)
	if ret ~= 0 then
		return ret
	end
	local b_l = self.battle_letter_l[l_id]
	if b_l == nil then
		return 21077
	end

	if self:get_remainder_times(time) <= 0 then
		return 21074
	end
	
	local a_f = self.faction_battle_l[b_l.f_id_apply]
	local r_f = self.faction_battle_l[b_l.f_id_reply]
	if a_f == nil or r_f == nil then
		return 21074
	end
	return r_f:can_accept_letter(l_id)
end

--应战某个战书
function Faction_battle_mgr:accept_letter(l_id, char_id)
	local b_l = self.battle_letter_l[l_id]
	if b_l == nil then
		return 21077
	end

	--
	b_l.state = 1
	b_l.replyer = char_id
	--把战书放到接受列表
	self:set_accpet_letter(b_l)
	local r_f = self.faction_battle_l[b_l.f_id_reply]
	r_f:accept_letter(b_l.id)
	local a_f = self.faction_battle_l[b_l.f_id_apply]
	a_f:be_accept_letter(b_l.id)

	local pkt = self:get_syn_info(2, l_id)
	g_server_mgr:send_to_all_map(0, CMD_C2M_FACTION_BATTLE_SYN_S, pkt)

	-- 广播
	local msg = {}
	local f_a = g_faction_mgr:get_faction_by_fid(b_l.f_id_apply)
	local f_r = g_faction_mgr:get_faction_by_fid(b_l.f_id_reply)

	f_construct_content(msg, f_r:get_faction_name(), 53)
	f_construct_content(msg, f_get_string(2221), 12)
	f_construct_content(msg, f_a:get_faction_name(), 53)
	f_construct_content(msg, f_get_string(2222), 12)
	local str_time = string.format("%d%s%d%s", b_l.s_time2[1], f_get_string(2223), b_l.s_time2[2], f_get_string(2224))
	f_construct_content(msg, str_time, 61)
	if b_l.wager_type == 0 then
		f_construct_content(msg, f_get_string(2225), 12)
	else
		f_construct_content(msg, f_get_string(2239), 12)
		f_construct_content(msg, tostring(b_l.wager), 53)
		local str_temp = ""
		if b_l.wager_type == 1 then
			str_temp = f_get_string(2241)
		elseif b_l.wager_type == 2 then
			str_temp = f_get_string(2242)
		end
		f_construct_content(msg, str_temp, 12)
		f_construct_content(msg, f_get_string(2240), 12)
	end
	f_send_bdc(3, 3, msg)

	--self:debug_print()
	return 0, b_l.f_id_apply
end

function Faction_battle_mgr:set_accpet_letter(b_l)
	if self.accept_battle_letter_l[b_l.s_time] == nil then
		self.accept_battle_letter_l[b_l.s_time] = {}
	end
	table.insert(self.accept_battle_letter_l[b_l.s_time], b_l.id)
end


--能否拒绝某个战书
function Faction_battle_mgr:can_reject_letter(char_id, l_id)
	local ret = self:auth(char_id, 1, l_id)
	if ret ~= 0 then
		return ret
	end
	local b_l = self.battle_letter_l[l_id]
	if b_l == nil then
		return 21077
	end

	if b_l.state ~= 0 then
		return 21078
	end

	local r_f = self.faction_battle_l[b_l.f_id_reply]
	return r_f:can_reject_letter(l_id)
end

--拒绝一个战书
function Faction_battle_mgr:reject_letter(l_id)
	local b_l = self.battle_letter_l[l_id]
	if b_l == nil then
		return 21077
	end

	local r_f = self.faction_battle_l[b_l.f_id_reply]
	r_f:reject_letter(l_id)
	local a_f = self.faction_battle_l[b_l.f_id_apply]
	a_f:be_reject_letter(l_id)
	-- 邮件返还押金
	b_l:restitution_deposit()
	b_l.state = 3

	local pkt = self:get_syn_info(3, l_id)
	g_server_mgr:send_to_all_map(0, CMD_C2M_FACTION_BATTLE_SYN_S, pkt)

	return 0, b_l.f_id_apply
end

--能否取消某个战书
function Faction_battle_mgr:can_cancel_letter(char_id, l_id)
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	local f_id = faction and faction:get_faction_id()
	local l_id = f_id and self.faction_battle_l[f_id] and self.faction_battle_l[f_id].send_battle_letter
	if l_id == nil then
		return 21086
	end

	local ret = self:auth(char_id, 2, l_id)
	if ret ~= 0 then
		return ret
	end
	local b_l = self.battle_letter_l[l_id]
	if b_l == nil then
		return 21077
	end

	if b_l.state ~= 0 then
		return 21079
	end

	local a_f = self.faction_battle_l[b_l.f_id_apply]
	return a_f:can_cancel_letter(l_id)
end

--取消某个战书
function Faction_battle_mgr:cancel_letter(char_id, l_id)
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	local f_id = faction and faction:get_faction_id()
	local l_id = f_id and self.faction_battle_l[f_id] and self.faction_battle_l[f_id].send_battle_letter
	if l_id == nil then
		return 21086
	end

	local b_l = self.battle_letter_l[l_id]
	if b_l == nil then
		return 21077
	end

	local a_f = self.faction_battle_l[b_l.f_id_apply]
	a_f:cancel_letter(l_id)
	local r_f = self.faction_battle_l[b_l.f_id_reply]
	r_f:be_cancel_letter(l_id)
	-- 邮件返还押金
	b_l:restitution_deposit()
	b_l.state = 3

	local pkt = self:get_syn_info(4, l_id)
	g_server_mgr:send_to_all_map(0, CMD_C2M_FACTION_BATTLE_SYN_S, pkt)

	return 0, b_l.f_id_reply
end


--取同步信息：type:0为map服重连，1为生成一个新的战书, 2为应战一个战书, 3为拒绝一个战书, 4为取消一个战书 5为约战结束
-- 6.系统取消隔天的战书  7.on_time战书状态转换
function Faction_battle_mgr:get_syn_info(type, l_id)
	local info = {}
	info.faction_battle_l = {}		
	info.accept_battle_letter_l = {}
	info.battle_letter_l = {}
	info.type = type

	local b_l = self.battle_letter_l[l_id]
	if type ~= 0 and b_l == nil then
		return
	end

	if type == 0 then
		for k, v in pairs(self.faction_battle_l) do
			table.insert(info.faction_battle_l, v:get_syn_info(type, l_id))			
		end
		for k, v in pairs(self.battle_letter_l) do
			table.insert(info.battle_letter_l, v:get_syn_info())			
		end
	else
		table.insert(info.faction_battle_l, self.faction_battle_l[b_l.f_id_apply]:get_syn_info(type, l_id))
		table.insert(info.faction_battle_l, self.faction_battle_l[b_l.f_id_reply]:get_syn_info(type, l_id))
		table.insert(info.battle_letter_l , b_l:get_syn_info())
		if b_l.state == 3 then
			self.battle_letter_l[l_id] = nil
		end
	end

	--self:debug_print()
	return info
end

function Faction_battle_mgr:set_syn_info(info)
	
	for k, v in ipairs(info.faction_battle_l or {}) do
		if self.faction_battle_l[v.id] == nil then
			self.faction_battle_l[v.id] = Faction_battle(v.id)
		end
		self.faction_battle_l[v.id]:set_syn_info(v)
	end

	for k, v in ipairs(info.battle_letter_l or {}) do
		if self.battle_letter_l[v.id] == nil then
			self.battle_letter_l[v.id] = Faction_battle_letter:clone(v)
		else
			self.battle_letter_l[v.id]:set_syn_info(v)
		end
		
		if v.state == 1 then	-- 已应战的战书
			self:set_accpet_letter(v)
		elseif v.state == 2 then-- 正在应战的战书
			for i, l_id in ipairs(self.accept_battle_letter_l[v.s_time]) do
				if l_id == v.id then
					table.remove(self.accept_battle_letter_l[v.s_time], i)
					break
				end
			end
		elseif v.state == 3 then-- 要删除的战书
			self.battle_letter_l[v.id] = nil
		end
	end

end

--重启同步
function Faction_battle_mgr:syn_all_to_map(server_id)
	local pkt = self:get_syn_info(0, nil)
	g_server_mgr:send_to_server(server_id, 0, CMD_C2M_FACTION_BATTLE_SYN_S, pkt)
end

function Faction_battle_mgr:get_battle_letter(l_id)	
	return l_id and self.battle_letter_l[l_id]
end

function Faction_battle_mgr:set_battle_letter(b_l)	
	self.battle_letter_l[b_l.id] = b_l
end

function Faction_battle_mgr:get_battle_letter_info(f_id, l_id)	
	return l_id and self.battle_letter_l[l_id] and self.battle_letter_l[l_id]:get_info(f_id)
end

function Faction_battle_mgr:get_remainder_times(time)	
	local battle_at_one_time = table.size(self.accept_battle_letter_l[time] or {})
	return FACTION_BATTLE_TIMES_EACH_SPACE - battle_at_one_time
end

--  检查操作权限 tyep:0,发战书，1：应战，拒绝，2：取消
function Faction_battle_mgr:auth(char_id, type, l_id)
--[[
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	local factioner_id = faction and faction:get_factioner_id()
	if type == 0 then
		if factioner_id ~= char_id then
			return 21082
		end
	elseif type == 1 then
		local b_l = self:get_battle_letter(l_id)
		if b_l == nil then
			return 21077
		end
		local faction2 = g_faction_mgr:get_faction_by_fid(b_l.f_id_reply)
		local factioner_id2 = faction2 and faction:get_factioner_id()
		if factioner_id2 ~= char_id then
			return 21083
		end
	else
		local b_l = self:get_battle_letter(l_id)
		if b_l == nil then
			return 21077
		end
		local faction1 = g_faction_mgr:get_faction_by_fid(b_l.f_id_apply)
		local factioner_id1 = faction1 and faction:get_factioner_id()
		if factioner_id1 ~= char_id then
			return 21084
		end
	end
]]
	return 0
end

function Faction_battle_mgr:get_click_param()
	return self,self.on_timer,60,nil
end

function Faction_battle_mgr:achieve_faction_battle_over(l_id, win_side)
	local b_l = self.battle_letter_l[l_id]
	if b_l == nil then
		return
	end
	--for k, v in ipairs(self.accept_battle_letter_l[b_l.s_time] or {}) do
		--if v.id == b_l.id then
			--table.remove(self.accept_battle_letter_l[b_l.s_time], k)
			--break
		--end
	--end

	self:notify_to_faction_member(b_l, 0)

	local f_a = g_faction_mgr:get_faction_by_fid(b_l.f_id_apply)
	local f_r = g_faction_mgr:get_faction_by_fid(b_l.f_id_reply)
	local win_name, lost_name

	local a_f = self.faction_battle_l[b_l.f_id_apply]
	a_f:over_letter(l_id)
	local r_f = self.faction_battle_l[b_l.f_id_reply]
	r_f:be_over_letter(l_id)
	b_l.state = 3
	if win_side == 1 then
		a_f:add_win_t(1)
		a_f:add_battle_relation(b_l.f_id_reply, true)
		r_f:add_lost_t(1)
		r_f:add_battle_relation(b_l.f_id_apply, false)
		win_name = f_a:get_faction_name()
		lost_name = f_r:get_faction_name()
	elseif win_side == 2 then
		r_f:add_win_t(1)
		r_f:add_battle_relation(b_l.f_id_apply, true)
		a_f:add_lost_t(1)
		a_f:add_battle_relation(b_l.f_id_reply, false)
		win_name = f_r:get_faction_name()
		lost_name = f_a:get_faction_name()
	end
	-- 广播
	local msg = {}
	f_construct_content(msg, f_get_string(2226), 12)
	f_construct_content(msg, win_name, 53)
	f_construct_content(msg, f_get_string(2227), 12)
	f_construct_content(msg, lost_name, 53)
	f_construct_content(msg, f_get_string(2228), 12)
	if b_l.wager > 0 and b_l.wager_type ~= 0 then
		f_construct_content(msg, f_get_string(2243), 12)
		f_construct_content(msg, tostring(b_l.wager), 53)
		if b_l.wager_type == 1 then
			f_construct_content(msg, f_get_string(2241), 12)			
		elseif b_l.wager_type == 2 then
			f_construct_content(msg, f_get_string(2242), 12)			
		end
		f_construct_content(msg, f_get_string(2244), 12)
	end
	f_send_bdc(3, 3, msg)
	
	--保存
	self:serialize(b_l.f_id_apply)
	self:serialize(b_l.f_id_reply)

	local pkt = self:get_syn_info(5, l_id)
	g_server_mgr:send_to_all_map(0, CMD_C2M_FACTION_BATTLE_SYN_S, pkt)
end

function Faction_battle_mgr:on_timer()
	--print("Faction_battle_mgr:on_timer")

	local update_letter_l = {}
	update_letter_l.battle_letter_l = {}
	update_letter_l.faction_battle_l = {}
	update_letter_l.type = 7
	for s_time, v in pairs(self.accept_battle_letter_l) do
		if s_time + self.today_time + FACTION_BATTLE_TIME + 60 <= ev.time 
			or (ev.time - self.today_time < 18 * 60 and s_time >= 23*3600+30*60) then -- 战斗跨两天的情况
			for i = FACTION_BATTLE_TIMES_EACH_SPACE, 1, -1 do
				local l_id = v[i]
				local b_l = l_id and self:get_battle_letter(l_id)
				if b_l and b_l.state == 2 and b_l:get_real_time() + FACTION_BATTLE_TIME + 60 <= ev.time then
					local a_f = self.faction_battle_l[b_l.f_id_apply]
					a_f:over_letter(l_id)
					local r_f = self.faction_battle_l[b_l.f_id_reply]
					r_f:be_over_letter(l_id)
					-- 邮件返还押金
					b_l:restitution_deposit()
					b_l.state = 3
					table.insert(update_letter_l.faction_battle_l, a_f:get_syn_info())
					table.insert(update_letter_l.faction_battle_l, r_f:get_syn_info())
					table.insert(update_letter_l.battle_letter_l , b_l:get_syn_info())
	
					self.battle_letter_l[l_id] = nil
					self:notify_to_faction_member(b_l, 0)

					table.remove(v, i)
				end
			end
			if #self.accept_battle_letter_l[s_time] <= 0 then
				self.accept_battle_letter_l[s_time] = nil
			end
		elseif s_time + self.today_time <= ev.time then
			for i, l_id in ipairs(v) do
				local b_l = self:get_battle_letter(l_id)
				if b_l and b_l.state == 1 then
					b_l.state = 2
					table.insert(update_letter_l.battle_letter_l, b_l:get_syn_info())
					self:notify_to_faction_member(b_l, 1)
				end
			end
		end
	end
	
	if #update_letter_l.battle_letter_l > 0 or #update_letter_l.faction_battle_l > 0 then
		g_server_mgr:send_to_all_map(0, CMD_C2M_FACTION_BATTLE_SYN_S, update_letter_l)
	end

	if ev.time > self.tomorrow_time then
		self:on_new_day()
	end

	--self:debug_print()
end

function Faction_battle_mgr:notify_to_faction_member(b_l, switch_flag)
	g_faction_mgr:set_battle_info(b_l.f_id_apply, switch_flag, b_l.battle_type)
	g_faction_mgr:set_battle_info(b_l.f_id_reply, switch_flag, b_l.battle_type)
end
--
function Faction_battle_mgr:debug_print()
	print("================== faction_battle_l =======================")
	for k, v in pairs(self.faction_battle_l) do
		local p = v:get_syn_info(0, nil)
		print(Json.Encode(p))
		print("-----------------------------------------------------")
	end
	print("++++++++++++++++++ battle_letter_l +++++++++++++++++++++++++")
	for k, v in pairs(self.battle_letter_l) do
		local p = v:get_syn_info()
		print(Json.Encode(p))
		print("-----------------------------------------------------")
	end
	print(">>>>>>>>>>>>>>>>>> accept_battle_letter_l <<<<<<<<<<<<<<<<<<<<<<")
	for k, v in pairs(self.accept_battle_letter_l) do
		print(k, Json.Encode(v))
		print("-----------------------------------------------------")
	end
end

function Faction_battle_mgr:on_new_day()
	self.today_time = f_get_today(ev.time)
	self.tomorrow_time = f_get_tomorrow(ev.time)

	for l_id, b_l in pairs(self.battle_letter_l) do
		if b_l.state == 0 then
			local a_f = self.faction_battle_l[b_l.f_id_apply]
			a_f:cancel_letter(l_id)
			local r_f = self.faction_battle_l[b_l.f_id_reply]
			r_f:be_cancel_letter(l_id)
			-- 邮件返还押金
			b_l:restitution_deposit()
			b_l.state = 3
			local pkt = self:get_syn_info(6, l_id)
			g_server_mgr:send_to_all_map(0, CMD_C2M_FACTION_BATTLE_SYN_S, pkt)
		end
	end
end

-- 保存
function Faction_battle_mgr:serialize(f_id)
	--print("Faction_battle_mgr:serialize()",f_id)	
	local info = self.faction_battle_l[f_id] and self.faction_battle_l[f_id]:get_db_info()
	if info ~= nil then
		local m_db = f_get_db()
		local query = string.format("{id:'%s'}", f_id)
		m_db:update("faction_battle", query, Json.Encode(info), true)
	end
end

function Faction_battle_mgr:serialize_all()
	--print("Faction_battle_mgr:serialize_all()")
	for k, v in pairs(self.faction_battle_l) do
		self:serialize(k)
	end
end

function Faction_battle_mgr:unserialize()
	local m_db = f_get_db()
	local rows, e_code = m_db:select("faction_battle")
	if rows ~= nil and e_code == 0 then
		for k, v in pairs(rows) do
			local faction = g_faction_mgr:get_faction_by_fid(v.id)
			if faction ~= nil then
				self.faction_battle_l[v.id] = Faction_battle(v.id)
				self.faction_battle_l[v.id]:set_db_info(v)
			end
		end
	end

	--需检查所有的战书是否还有效
	for k, v in pairs(self.faction_battle_l) do
		if self:get_battle_letter(v.send_battle_letter) == nil then 
			v.send_battle_letter = nil 
		end
		if self:get_battle_letter(v.accept_battle_letter) == nil then 
			v.accept_battle_letter = nil 
		end
		for id, _ in pairs(v.recv_battle_letter) do
			if self:get_battle_letter(id) == nil then
				v.recv_battle_letter[id] = nil 
			end
		end
	end
end