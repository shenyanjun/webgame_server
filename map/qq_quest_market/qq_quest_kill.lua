
local qq_quest_loader = require("qq_quest_market.qq_quest_market_loader")

QQ_quest_kill = oo.class(QQ_quest_base,"QQ_quest_kill")

function QQ_quest_kill:__init(char_data, data)
	QQ_quest_base:__init(self, char_data, data)
	self.count = 0
end

function QQ_quest_kill:register_event(con)
	con:register_event(EVENT_SET.EVENT_KILL_MONSTER, self.quest_id, self, self.kill_event)
end

function QQ_quest_kill:unregister_event(con)
	con:unregister_event(EVENT_SET.EVENT_KILL_MONSTER, self.quest_id)
end

function QQ_quest_kill:kill_event(con, monster_id)
	local quest = qq_quest_loader.get_quest(self.quest_id)
	if not quest then return end

	if not QQ_quest_base:check_level(qq_quest_loader.get_level_quest(self.quest_id)) then
		return
	end

	if not quest.kill_monster[monster_id] then
		return
	end
	self.count = (self.count or 0) + 1
	if self.count >= (quest.kill_monster[monster_id] or 1) then	
		self:unregister_event(con)
		QQ_quest_base:complete()
		return
	end
end