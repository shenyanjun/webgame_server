local misson_loader = require("mission_ex.mission_loader")


Quest_Sheep_Run = oo.class(Quest_base,"Quest_Sheep_Run")

function Quest_Sheep_Run:__init(meta, core)
	Quest_base.__init(self, meta)
	self.collect = {}
	self.count = 0
end

function Quest_Sheep_Run:register_event(con)
	con:register_event(EVENT_SET.EVENT_SHEEP_RUN, self.quest_id, self, self.collect_item)
end

function Quest_Sheep_Run:unregister_event(con)
	con:unregister_event(EVENT_SET.EVENT_SHEEP_RUN, self, self.quest_id)
end

function Quest_Sheep_Run:load_fields(record)
	local obj, e_code = Quest_base.load_fields(self, record)
	obj.collect = {}
	obj.count = 0
	if record.collect then
		for k, v in pairs(record.collect) do
			obj.collect[tonumber(k)] = v
			obj.count = obj.count + v
		end
	end
	return obj, E_SUCCESS
end

function Quest_Sheep_Run:construct(con)
	self:register_event(con)
end

function Quest_Sheep_Run:serialize_to_db()
	local result = Quest_base.serialize_to_db(self)
	result.collect = {}
	for k, v in pairs(self.collect) do
		result.collect[tostring(k)] = v
	end
	return result
end

function Quest_Sheep_Run:serialize_to_net()
	local result = Quest_base.serialize_to_net(self)
	result.num = self.count or 0
	return result
end

function Quest_Sheep_Run:collect_item(con, collect_id, collect_count)
	local meta = misson_loader.get_meta(self.quest_id)
	local item_id = 0
	for i,v in pairs(meta.postcondition.collect_list.item_list) do
		if v.number ~= 0 then
			item_id = i
		end
	end
	self.collect[item_id] = (self.collect[item_id] or 0 )+ collect_count
	self.count = self.collect[item_id]
	if meta.postcondition.collect_list.item_list[item_id].number > self.collect[item_id] then
		con:notity_update_quest(self.quest_id, true)
		return
	end
	self.status = MISSION_STATUS_COMMIT
	con:notity_update_quest(self.quest_id, true)
	self:unregister_event(con)
end

Mission_mgr.register_class(MISSION_FLAG_SHEEP_RUN, Quest_Sheep_Run)