
local qq_quest_loader = require("qq_quest_market.qq_quest_market_loader")

QQ_quest_scene = oo.class(QQ_quest_base,"QQ_quest_scene")

function QQ_quest_scene:__init(char_data, data)
	QQ_quest_base:__init(self, char_data, data)
end

function QQ_quest_scene:register_event(con)
	con:register_event(EVENT_SET.EVENT_ENTER_COPY, self.quest_id, self, self.scene_event)
end

function QQ_quest_scene:unregister_event(con)
	con:unregister_event(EVENT_SET.EVENT_ENTER_COPY, self.quest_id)
end

function QQ_quest_scene:scene_event(con, scene_id)
	local quest = qq_quest_loader.get_quest(self.quest_id)
	if not quest then return end
	if not self.quest_id then print("quest.scene error") end
	
	if not QQ_quest_base:check_level(qq_quest_loader.get_level_quest(self.quest_id)) then
		return
	end

	if quest.ent_scene[scene_id] then
		self:unregister_event(con)
		QQ_quest_base:complete()
		return
	end
end