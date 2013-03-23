
-- 帮派战类，每个帮派对应一个对象

Faction_battle = oo.class(nil, "Faction_battle")

function Faction_battle:__init(f_id)

	self.id = f_id
	self.win_t = 0   -- 战胜的总次数
	self.lost_t = 0  -- 战败的总次数
	self.send_battle_letter = nil	-- 发出的约战书ID，只能发一份
	self.accept_battle_letter = nil	-- 接受回战的约战书ID
	self.recv_battle_letter = {}	-- 接收到的战书对象
	self.battle_r = {}				-- 与各帮派的对战关系
end

function Faction_battle:can_send_letter(time)
	if self.send_battle_letter ~= nil then
		return 21071
	end

	if self.accept_battle_letter ~= nil then
		return 21081
	end
	
	return 0
end

--增加与其它帮派战的关系, is_win:我方胜为true
function Faction_battle:add_battle_relation(f_id, is_win)
	if self.battle_r[f_id] == nil then
		self.battle_r[f_id] = {0, 0}
	end
	if is_win then
		self.battle_r[f_id][1] = self.battle_r[f_id][1] + 1
	else
		self.battle_r[f_id][2] = self.battle_r[f_id][2] + 1		
	end
end

function Faction_battle:add_win_t(t)
	self.win_t = self.win_t + t
end

function Faction_battle:add_lost_t(t)
	self.lost_t = self.lost_t + t
end

function Faction_battle:send_letter(send_battle_letter_id)
	self.send_battle_letter = send_battle_letter_id
end

--能否收到一个战书
function Faction_battle:can_recv_letter(time)
	return 0
end

function Faction_battle:recv_letter(l_id)
	self.recv_battle_letter[l_id] = 1
end

--能否接受一个战书
function Faction_battle:can_accept_letter(l_id)
	if self.send_battle_letter ~= nil then
		return 21075
	end
	if self.accept_battle_letter ~= nil then
		return 21076
	end
	if self.recv_battle_letter[l_id] == nil then
		return 21077
	end

	return 0
end
--接受一个战书
function Faction_battle:accept_letter(l_id)
	self.accept_battle_letter = l_id 
end
--被接受一个战书
function Faction_battle:be_accept_letter(l_id)
	self.accept_battle_letter = l_id 
end


--能否拒绝一个战书
function Faction_battle:can_reject_letter(l_id)
	if self.recv_battle_letter[l_id] == nil then
		return 21077
	end

	return 0
end

--拒绝一个战书
function Faction_battle:reject_letter(l_id)
	self.recv_battle_letter[l_id] = nil
end

--被拒绝一个战书
function Faction_battle:be_reject_letter(l_id)
	self.send_battle_letter = nil
end

--能否取消某个战书
function Faction_battle:can_cancel_letter(l_id)
	if l_id ~= self.send_battle_letter then
		return 21077
	end

	return 0
end

--取消某个战书
function Faction_battle:cancel_letter(l_id)
	self.send_battle_letter = nil
end
--被取消某个战书
function Faction_battle:be_cancel_letter(l_id)
	self.recv_battle_letter[l_id] = nil
end

--结束某个战书
function Faction_battle:over_letter(l_id)
	if l_id == self.send_battle_letter then
		self.send_battle_letter = nil
	end
	if self.accept_battle_letter == l_id then
		self.accept_battle_letter = nil
	end
end
--被结束某个战书
function Faction_battle:be_over_letter(l_id)
	self.recv_battle_letter[l_id] = nil
	if self.accept_battle_letter == l_id then
		self.accept_battle_letter = nil
	end
end

function Faction_battle:get_syn_info(type, l_id)
	local info = {}
	info.id = self.id
	info.win_t = self.win_t
	info.lost_t = self.lost_t
	info.s_le = self.send_battle_letter
	info.a_le = self.accept_battle_letter
	info.r_le = {}
	for k, v in pairs(self.recv_battle_letter) do
		table.insert(info.r_le, k)
	end
	info.b_r = {}
	if type == 0 then
		for k, v in pairs(self.battle_r) do
			table.insert(info.b_r, {k, v})
		end
	elseif type == 5 then
		local b_l = g_faction_battle_mgr:get_battle_letter(l_id)
		if b_l then
			if self.id == b_l.f_id_reply then
				table.insert(info.b_r, {b_l.f_id_apply, self.battle_r[b_l.f_id_apply]})
			else
				table.insert(info.b_r, {b_l.f_id_reply, self.battle_r[b_l.f_id_reply]})
			end
		end
	end
	return info
end

function Faction_battle:set_syn_info(info)
	if info.id ~= self.id then return end

	self.win_t	= info.win_t
	self.lost_t	= info.lost_t
	self.send_battle_letter	= info.s_le
	self.accept_battle_letter = info.a_le
	self.recv_battle_letter = {}
	for k, v in pairs(info.r_le) do
		self.recv_battle_letter[v] = 1
	end
	for k, v in pairs(info.b_r) do
		self.battle_r[v[1]] = v[2]
	end
end

function Faction_battle:get_recv_letter_info()
	local ret = {}
	for k, v in pairs(self.recv_battle_letter) do
		local letter = g_faction_battle_mgr:get_battle_letter(k)
		if letter == nil then break end
		if letter.state == 1 or letter.state == 2 then
			table.insert(ret, 1, letter:get_info(self.id))
		elseif letter.state == 0 then
			table.insert(ret, letter:get_info(self.id))			
		end
	end

	return ret
end

function Faction_battle:get_send_letter_info()
	local ret = {}
	local letter = g_faction_battle_mgr:get_battle_letter(self.send_battle_letter)
	local ret = letter and letter:get_info(self.id)
	return ret
end

function Faction_battle:get_db_info()
	local info = {}
	info.id = self.id
	--info.win_t = self.win_t
	--info.lost_t = self.lost_t
	info.s_le = self.send_battle_letter
	info.a_le = self.accept_battle_letter
	info.r_le = {}
	for k, v in pairs(self.recv_battle_letter) do
		table.insert(info.r_le, k)
	end
	info.b_r = {}
	for k, v in pairs(self.battle_r) do
		table.insert(info.b_r, {k, v})
	end
	local s_bl = g_faction_battle_mgr:get_battle_letter(self.send_battle_letter)
	info.le_info = s_bl and s_bl:get_db_info() or {}
	return info
end

function Faction_battle:set_db_info(info)
	--print("Faction_battle:set_db_info", j_e(info))
	if info.id ~= self.id then return end
	--local _ = info.le_info.id and print(info.le_info.id , info.le_info.real_time + FACTION_BATTLE_TIME , ev.time)
	if info.le_info.id and info.le_info.real_time + FACTION_BATTLE_TIME > ev.time then
		local b_l = Faction_battle_letter:clone(info.le_info)
		g_faction_battle_mgr:set_battle_letter(b_l)
		if b_l.state == 1 or b_l.state == 2 then
			g_faction_battle_mgr:set_accpet_letter(b_l)
		end
	elseif info.le_info.id then	--已经过时的战书
		local b_l = Faction_battle_letter:clone(info.le_info)
		b_l:restitution_deposit()
	end

	--self.win_t	= info.win_t
	--self.lost_t	= info.lost_t
	self.send_battle_letter	= info.s_le
	self.accept_battle_letter = info.a_le
	self.recv_battle_letter = {}
	for k, v in pairs(info.r_le) do
		self.recv_battle_letter[v] = 1
	end
	for k, v in pairs(info.b_r) do
		self.battle_r[v[1]] = v[2]
		self.win_t = self.win_t + v[2][1]
		self.lost_t = self.lost_t + v[2][2]
	end
	
end
