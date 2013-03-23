
local qq_quest_loader = require("qq_quest_market.qq_quest_market_loader")

QQ_quest_level = oo.class(QQ_quest_base,"QQ_quest_level")

function QQ_quest_level:__init(char_data, data)
	QQ_quest_base:__init(self, char_data, data)
end

function QQ_quest_level:check_quest()
	local player = g_obj_mgr:get_obj(self.char_id)
	if player:get_level() >= qq_quest_loader.get_level_quest(self.quest_id) then
		QQ_quest_base:complete()
	end
end

function QQ_quest_level:register_event(con)
	con:register_event(EVENT_SET.EVENT_LEVEL_UP, self.quest_id, self, self.levelup_event)
end

function QQ_quest_level:unregister_event(con)
	con:unregister_event(EVENT_SET.EVENT_LEVEL_UP, self.quest_id)
end

function QQ_quest_level:levelup_event(con, level)
	if not level then return end
	if not qq_quest_loader.get_quest(self.quest_id) then return end

	if QQ_quest_base:check_level(qq_quest_loader.get_level_quest(self.quest_id)) then
		self:unregister_event(con)
		QQ_quest_base:complete()
		return
	end
end