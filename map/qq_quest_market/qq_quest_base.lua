
QQ_quest_base = oo.class(nil, "QQ_quest_base")

function QQ_quest_base:__init(con, char_data, data)
	self.char_id = char_data.char_id
	self.openid  = char_data.openid
	self.zoneid  = char_data.zoneid
	self.quest_id = data.task_id or 0
	self.status = data.status or 0
end

function QQ_quest_base:construct(con)
	self:check_quest()
	if self.status ~= 0 then return end
	self:register_event(con)
end

function QQ_quest_base:check_quest()
end

function QQ_quest_base:check_level(lv)
	if g_obj_mgr:get_obj(self.char_id):get_level() >= lv then
		return true
	end
	return false
end

function QQ_quest_base:register_event()
end

function QQ_quest_base:unregister_event()
end


function QQ_quest_base:get_status()
	return self.status
end

function QQ_quest_base:set_status(state)
	self.status = state
end

function QQ_quest_base:get_quest_id()
	return self.quest_id
end

function QQ_quest_base:complete()
		self:set_status(1)
		self:updata()
		self:send_to_net()
end

function QQ_quest_base:updata()
	
	local dbh = f_get_db()
	local str_char = "{openid:\""..self.openid .."\",zoneid:\"".. self.zoneid.."\"}"
	local result = string.format("{status:%d}", self:get_status())
	local err_code = dbh:update("qq_quest_market",str_char,result)
	return err_code
end	

function QQ_quest_base:send_to_net()
	local s_pkt = {}
	s_pkt.quest    = self:get_quest_id()
	s_pkt.state    = self:get_status()
	g_cltsock_mgr:send_client(self.char_id, CMD_MAP_QQ_QUEST_STATE_S, s_pkt)
end