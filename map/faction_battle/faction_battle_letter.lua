
-- 帮派战战书类

Faction_battle_letter = oo.class(nil, "Faction_battle_letter")

function Faction_battle_letter:__init(f_id_apply, f_id_reply, s_time, battle_type)

	self.id = crypto.uuid()
	self.f_id_apply = f_id_apply	-- 申请约战方帮派ID
	self.f_id_reply = f_id_reply	-- 被约战方帮派ID
	self.s_time = s_time			-- 约战开始时间
	self.battle_type = battle_type	-- 约战的类型(场景id)
	self.state = 0  				-- 战书状态：0为未应战，1为已应战，2为正在进行
	self.s_time2 = f_faction_battle_n2t(s_time)		-- 另一种格式的开始时间

	self.applyer = nil
	self.replyer = nil
	self.wager = 0
	self.wager_type = 0		--赌注类型：0为不加赌注，1为元宝，2为铜币
end

function Faction_battle_letter:clone(info)
	local new_bl = Faction_battle_letter(info.f_id_apply, info.f_id_reply, info.s_time, info.battle_type)
	new_bl.id = info.id
	new_bl.state = info.state
	new_bl.applyer = info.applyer
	new_bl.replyer = info.replyer
	new_bl.wager   = info.wager or 0
	new_bl.wager_type = info.wager_type or 0
	return new_bl
end

function Faction_battle_letter:get_syn_info()
	local info = {}
	info.id 		= self.id
	info.f_id_apply = self.f_id_apply
	info.f_id_reply	= self.f_id_reply
	info.s_time 	= self.s_time
	info.battle_type= self.battle_type
	info.state 		= self.state
	info.applyer = self.applyer
	info.replyer = self.replyer
	info.wager   = self.wager
	info.wager_type = self.wager_type

	return info
end

function Faction_battle_letter:set_syn_info(info)
	if info.id ~= self.id then return end
	self.f_id_apply	= info.f_id_apply
	self.f_id_reply	= info.f_id_reply
	self.s_time		= info.s_time
	self.battle_type= info.battle_type

	self.applyer = info.applyer
	self.replyer = info.replyer
	self.wager   = info.wager or 0
	self.wager_type = info.wager_type or 0

	local old_state = self.state
	self.state		= info.state

	if old_state == 0 and self.state == 1 then
		local faction_a = g_faction_mgr:get_faction_by_fid(self.f_id_apply)
		local faction_r = g_faction_mgr:get_faction_by_fid(self.f_id_reply)
		if faction_a == nil or faction_r == nil then return end
		local new_pkt = {}
		new_pkt[1] = faction_r:get_faction_name()
		new_pkt[2] = self.s_time2[1]
		new_pkt[3] = self.s_time2[2]
		for k,v in pairs(faction_a.faction_player_list or {}) do
			local obj = g_obj_mgr:get_obj(k)
			if obj then
				g_cltsock_mgr:send_client(k, CMD_FACTION_BATTLE_NOTIFY_ACCEPT_S, new_pkt) 
			end
		end
		--
		new_pkt[1] = faction_a:get_faction_name()
		for k,v in pairs(faction_r.faction_player_list or {}) do
			local obj = g_obj_mgr:get_obj(k)
			if obj then
				g_cltsock_mgr:send_client(k, CMD_FACTION_BATTLE_NOTIFY_ACCEPT_S, new_pkt) 
			end
		end

	end
end

function Faction_battle_letter:get_info(f_id)
	local info = {}
	info[1] = self.id
	info[2] = self.f_id_apply == f_id and self.f_id_reply or self.f_id_apply
	info[3]	= self.s_time2[1]
	info[4]	= self.s_time2[2]
	info[5]	= self.battle_type
	info[6] = self.state
	info[7] = self.wager_type or 0
	info[8] = self.wager or 0
	--info[9] = self.applyer or {}
	--info[10] = self.replyer or {}

	return info
end

function Faction_battle_letter:get_real_time()
	local today_time = f_get_today(ev.time)
	return 	today_time + self.s_time
end