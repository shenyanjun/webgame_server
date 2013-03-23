
--∏±±æ’“ªÿ
local Retrieve_scene = oo.class(Retrieve_base, "Retrieve_scene")

local database = "retrieve"

function Retrieve_scene:__init(meta)
	Retrieve_base.__init(self, meta)
	self.map_id = meta.subtype
end


function Retrieve_scene:register_event(con)
	if Retrieve_base.register_event(self) then 
		con:register_event(EVENT_SET.EVENT_ENTER_SCENE, self.id, self, self.enter_scene)
	end
end

function Retrieve_scene:unregister_event(con)
	con:unregister_event(EVENT_SET.EVENT_ENTER_SCENE, self.id)
end

function Retrieve_scene:enter_scene(con, map_id, type)
	if type == 3 and self.map_id == map_id then
		self:change_flag(con)
	end
end

function Retrieve_scene:check_map_id(con, map_id)
	if self.map_id == map_id then
		if self.flag == 0 then
			self:change_flag(con)
		end
		return true
	else
		return false
	end
end

function Retrieve_scene:is_scene_type()
	return true
end

function Retrieve_scene:serialize_to_db()
	
	local m_db = f_get_db()
	local query = string.format("{char_id:%d}", self.char_id)

	local result = {}
	result.id = self.id
	result.day = self.day
	result.flag = self.flag
	result.map_id = self.map_id
	result = Json.Encode(result)

	local info = string.format([[{"items.%d":%s}]], self.id - 1, result)

	m_db:update(database, query, info, true, false)

	return 0
end

function Retrieve_scene:load_fields(record)
	local obj = {}
	--obj.id = record.id
	obj.flag = record.flag
	obj.day = record.day
	obj.id = record.id
	obj.type = record.type
	obj.map_id = record.map_id

	return obj
end

function Retrieve_scene:get_update_data()
	local pkt = {}
	pkt.id = self.id
	pkt.day = self.day
	pkt.flag = self.flag
	pkt.map_id = self.map_id
	return pkt
end
Retrieve_mgr.register_class(RETRIEVE_TYPE_SCENE, Retrieve_scene)