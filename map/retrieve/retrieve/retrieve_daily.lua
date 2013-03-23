

--日常任务找回
local Retrieve_daily = oo.class(Retrieve_base, "Retrieve_daily")

function Retrieve_daily:__init(meta)
	Retrieve_base.__init(self, meta)
end

function Retrieve_daily:register_event(con)
	if Retrieve_base.register_event(self) then
		con:register_event(EVENT_SET.EVENT_COMPLETE_QUEST, self.id, self, self.complete_quest)
	end
end

function Retrieve_daily:unregister_event(con)
	con:unregister_event(EVENT_SET.EVENT_COMPLETE_QUEST, self.id)
end

function Retrieve_daily:complete_quest(con, id, char_id, type)
	if type == 4 then
		self:change_flag(con)
	end
end

function Retrieve_daily:get_update_data()
	local pkt = {}
	pkt.id = self.id
	pkt.day = self.day
	pkt.flag = self.flag
	return pkt
end

Retrieve_mgr.register_class(RETRIEVE_TYPE_DAILY, Retrieve_daily)
