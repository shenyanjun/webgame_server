
-- 帮派战战书类

Faction_battle_letter = oo.class(nil, "Faction_battle_letter")

function Faction_battle_letter:__init(f_id_apply, f_id_reply, s_time, battle_type)

	self.id = crypto.uuid()
	self.f_id_apply = f_id_apply	-- 申请约战方帮派ID
	self.f_id_reply = f_id_reply	-- 被约战方帮派ID
	self.s_time = s_time			-- 约战开始时间
	self.battle_type = battle_type	-- 约战的类型(场景id)
	self.state = 0  				-- 战书状态：0为未应战，1为已应战，2为正在进行
	self.real_time = f_get_today(ev.time) + s_time
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
	new_bl.real_time = info.real_time or (f_get_today(ev.time) + info.s_time)
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
	self.state		= info.state
	self.applyer = info.applyer
	self.replyer = info.replyer
	self.wager   = info.wager or 0
	self.wager_type = info.wager_type or 0
end

function Faction_battle_letter:get_db_info()
	local info = {}
	info.id 		= self.id
	info.f_id_apply = self.f_id_apply
	info.f_id_reply	= self.f_id_reply
	info.s_time 	= self.s_time
	info.battle_type= self.battle_type
	info.state 		= self.state
	info.real_time	= self.real_time
	info.applyer = self.applyer
	info.replyer = self.replyer
	info.wager   = self.wager
	info.wager_type = self.wager_type
	return info
end

function Faction_battle_letter:set_db_info(info)
	if info.id ~= self.id then return end
	self.f_id_apply	= info.f_id_apply
	self.f_id_reply	= info.f_id_reply
	self.s_time		= info.s_time
	self.battle_type= info.battle_type
	self.state		= info.state
	self.real_time	= info.real_time
	self.applyer = info.applyer
	self.replyer = info.replyer
	self.wager   = info.wager or 0
	self.wager_type = info.wager_type or 0
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
	return self.real_time
end

--邮件返还押金
function Faction_battle_letter:restitution_deposit()
	local pkt = {}
	pkt.sender = -1
	pkt.recevier = self.applyer
	pkt.title = f_get_string(2231)
	pkt.content = f_get_string(2232)
	pkt.box_title = f_get_string(2235)
	pkt.money_list = {}
	pkt.gift_box = {}
	pkt.item_list = {}
	

	if self.wager_type == 1 and self.applyer ~= nil then
		pkt.money_list[MoneyType.JADE] = self.wager
		g_email_mgr:send_email_interface(pkt)

	elseif self.wager_type == 2 and self.applyer ~= nil then
		pkt.money_list[MoneyType.GOLD] = self.wager
		g_email_mgr:send_email_interface(pkt)
	end

	if self.state == 1 then -- or self.state == 2
		if self.wager_type == 1 and self.replyer ~= nil then
			pkt.recevier = self.replyer
			pkt.money_list[MoneyType.JADE] = self.wager
			g_email_mgr:send_email_interface(pkt)

		elseif self.wager_type == 2 and self.replyer ~= nil then
			pkt.recevier = self.replyer			
			pkt.money_list[MoneyType.GOLD] = self.wager
			g_email_mgr:send_email_interface(pkt)
		end
	end
end