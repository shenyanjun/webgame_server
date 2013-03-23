

-- 帮派战管理类，负责管理已回应的战书

Faction_battle_mgr = oo.class(nil, "Faction_battle_mgr")

function Faction_battle_mgr:__init()
	self.faction_battle_l = {}			-- 帮派战的对象列表
	self.accept_battle_letter_l = {}	-- 接受回战的约战书对象
	self.battle_letter_l = {}			-- 所有的战书对象
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
		if faction ~= nil and faction:get_dissolve_flag() == 0 and faction:get_level() >= 2 then
			local entry = faction:get_faction_info_for_battle()
			local f_b = self.faction_battle_l[k]
			--entry[6] = f_b and f_b.win_t or 0
			--entry[7] = f_b and f_b.lost_t or 0
			entry[6] = f_b and f_b.battle_r[faction_id] and f_b.battle_r[faction_id][1] or 0
			entry[7] = f_b and f_b.battle_r[faction_id] and f_b.battle_r[faction_id][2] or 0
			if entry[1] == b_fid then
				table.insert(ret.f_list, 1, entry)	
			elseif faction_id ~= entry[1] then
				table.insert(ret.f_list, entry)
			end
		end
	end
	-- 
	
	return ret
end

--取我帮的所有战书
function Faction_battle_mgr:get_our_battle_info(char_id)
	--print("Faction_battle_mgr:get_our_battle_info()", char_id)
	local ret = {}
	--
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	local faction_id = faction and faction:get_faction_id()

	local f_b = faction_id and self.faction_battle_l[faction_id]
	ret.recv_letter = f_b and f_b:get_recv_letter_info() or {}
	ret.my_letter = f_b and f_b:get_send_letter_info() or {}
	--
	return ret
end

function Faction_battle_mgr:can_apply_battle(char_id, f_id_reply, time, wager_type, wager)
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

	if ret ~= 0 then return ret end
	if wager_type == 1 then
		local obj = g_obj_mgr:get_obj(char_id)
		local pack_con = obj:get_pack_con()
		if pack_con:check_money_lock(MoneyType.JADE) then return -1 end
		local money = pack_con:get_money()
		if money.jade < wager then return 21094 end

	elseif wager_type == 2 then
		local obj = g_obj_mgr:get_obj(char_id)
		local pack_con = obj:get_pack_con()
		if pack_con:check_money_lock(MoneyType.GOLD) then return -1 end
		local money = pack_con:get_money()
		if money.gold < wager then return 21095 end
	end

	return 0
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

	local today_time = f_get_today(ev.time)
	if ev.time > today_time + b_l.s_time  then
		return 21097
	end

	-- 同一时间段的约战数
	if self:get_remainder_times(time) <= 0 then
		return 21074
	end
	
	local a_f = self.faction_battle_l[b_l.f_id_apply]
	local r_f = self.faction_battle_l[b_l.f_id_reply]
	if a_f == nil or r_f == nil then
		return 21074
	end
	local ret = r_f:can_accept_letter(l_id)
	
	if ret ~= 0 then return ret end
	
	if b_l.wager_type == 1 then
		local obj = g_obj_mgr:get_obj(char_id)
		local pack_con = obj:get_pack_con()
		if pack_con:check_money_lock(MoneyType.JADE) then return -1 end
		local money = pack_con:get_money()
		if money.jade < b_l.wager then return 21094 end

	elseif b_l.wager_type == 2 then
		local obj = g_obj_mgr:get_obj(char_id)
		local pack_con = obj:get_pack_con()
		if pack_con:check_money_lock(MoneyType.GOLD) then return -1 end
		local money = pack_con:get_money()
		if money.gold < b_l.wager then return 21095 end
	end

	return 0
end

--能否拒绝某个战书
function Faction_battle_mgr:can_reject_letter(char_id, l_id)
	--print("Faction_battle_mgr:can_reject_letter()", char_id, l_id)	
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

--能否取消某个战书
function Faction_battle_mgr:can_cancel_letter(char_id, l_id)
	--print("Faction_battle_mgr:can_cancel_letter()", char_id, l_id)
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



function Faction_battle_mgr:set_syn_info(info)
	
	if info.type == 0 then
		self.accept_battle_letter_l = {}
	end

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

		self.battle_letter_l[v.id]:set_syn_info(v)
		if v.state == 1 then	-- 已应战的战书
			self.accept_battle_letter_l[v.s_time] = (self.accept_battle_letter_l[v.s_time] or 0) + 1
			--if self.accept_battle_letter_l[v.s_time] == nil then
				--self.accept_battle_letter_l[v.s_time] = {}
			--end
			--table.insert(self.accept_battle_letter_l[v.s_time], v.id)
		elseif v.state == 2 and info.type ~= 0 then-- 正在应战的战书
			self.accept_battle_letter_l[v.s_time] = (self.accept_battle_letter_l[v.s_time] or 0) - 1			
			--for i, l_id in ipairs(self.accept_battle_letter_l[v.s_time] or {}) do
				--if l_id == v.id then
					--table.remove(self.accept_battle_letter_l[v.s_time], i)
					--break
				--end
			--end
		elseif v.state == 3 then-- 要删除的战书
			self.battle_letter_l[v.id] = nil
		end
	end

end

function Faction_battle_mgr:get_battle_letter(l_id)	
	return l_id and self.battle_letter_l[l_id]
end

function Faction_battle_mgr:get_battle_letter_info(f_id, l_id)	
	return l_id and self.battle_letter_l[l_id] and self.battle_letter_l[l_id]:get_info(f_id)
end

function Faction_battle_mgr:get_remainder_times(time)	
	--local battle_at_one_time = table.size(self.accept_battle_letter_l[time] or {})
	--return FACTION_BATTLE_TIMES_EACH_SPACE - battle_at_one_time
	return FACTION_BATTLE_TIMES_EACH_SPACE - (self.accept_battle_letter_l[time] or 0)
end

--  检查操作权限 tyep:0,发战书，1：应战，拒绝，2：取消
function Faction_battle_mgr:auth(char_id, type, l_id)
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	return faction:is_battle_permission_ok(char_id)
--[[
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
	return 0
]]
end

function Faction_battle_mgr:get_accept_lid_from_cid(char_id)	
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	local f_id = faction and faction:get_faction_id()
	local f_b = f_id and self.faction_battle_l[f_id]
	return f_b and f_b.accept_battle_letter
end

function Faction_battle_mgr:get_battle_side(char_id)	
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	local f_id = faction and faction:get_faction_id()
	local f_b = f_id and self.faction_battle_l[f_id]
	if f_b == nil or f_b.accept_battle_letter == nil then return end
	local b_l = self.battle_letter_l[f_b.accept_battle_letter]
	if b_l == nil then return end

	if b_l.f_id_apply == f_id then 
		return 1
	elseif b_l.f_id_reply == f_id then
		return 2
	end
end

function Faction_battle_mgr:check_letter(l_id)	
	local b_l = self:get_battle_letter(l_id)
	if b_l == nil then
		return 21077
	end
	if b_l.state == 1 then
		if ev.time < b_l:get_real_time() + 3 * 60 then
			return 21087
		end
	elseif b_l.state == 3 then
		return 21088
	elseif b_l.state == 0 then
		return 21089
	end

	if self:get_letter_remain_time(l_id) <= 30 then
		return 21088
	end

	return 0
end

function Faction_battle_mgr:get_letter_remain_time(l_id)	
	local b_l = self:get_battle_letter(l_id)
	if b_l == nil then
		return 0
	end
	local end_time = b_l:get_real_time() + FACTION_BATTLE_TIME

	return math.max(0, end_time - ev.time)
end

function Faction_battle_mgr:get_battle_apply_name(l_id)
	local b_l = self:get_battle_letter(l_id)
	if b_l == nil then
		return ""
	end
	local faction = g_faction_mgr:get_faction_by_fid(b_l.f_id_apply)
	return faction and faction:get_faction_name() or ""
end

function Faction_battle_mgr:get_battle_reply_name(l_id)
	local b_l = self:get_battle_letter(l_id)
	if b_l == nil then
		return ""
	end
	local faction = g_faction_mgr:get_faction_by_fid(b_l.f_id_reply)
	return faction and faction:get_faction_name() or ""
end

function Faction_battle_mgr:get_battle_apply_id(l_id)
	local b_l = self:get_battle_letter(l_id)
	if b_l == nil then
		return ""
	end
	return b_l.f_id_apply
end

function Faction_battle_mgr:get_battle_reply_id(l_id)
	local b_l = self:get_battle_letter(l_id)
	if b_l == nil then
		return ""
	end
	return b_l.f_id_reply
end

function Faction_battle_mgr:faction_battle_over(l_id, win_side)	
	local b_l = self:get_battle_letter(l_id)
	if b_l == nil then
		return 0
	end
	--

	-- 通知公共服
	local pkt = {}
	pkt.l_id = l_id
	pkt.win_side = win_side
	g_svsock_mgr:send_server_ex(COMMON_ID, 0, CMD_M2C_FACTION_BATTLE_OVER_C, pkt)
end


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
