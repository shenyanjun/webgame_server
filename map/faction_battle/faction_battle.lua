
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
	--print("Faction_battle:can_reject_letter()", l_id)
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
	--print("Faction_battle:can_cancel_letter()", l_id)	
	if l_id ~= self.send_battle_letter then
		return 21077
	end

	return 0
end

--取消某个战书
function Faction_battle:cancel_letter(l_id)
	self.send_battle_letter = nil
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