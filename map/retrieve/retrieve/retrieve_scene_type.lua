
--按类型副本找回
local Retrieve_scene_type = oo.class(Retrieve_base, "Retrieve_scene_type")

local database = "retrieve"

function Retrieve_scene_type:__init(meta)
	Retrieve_base.__init(self, meta)
	self.map_type = meta.subtype
end


function Retrieve_scene_type:register_event(con)
	if Retrieve_base.register_event(self) then 
		con:register_event(EVENT_SET.EVENT_ENTER_SCENE, self.id, self, self.enter_scene)
	end
end

function Retrieve_scene_type:unregister_event(con)
	con:unregister_event(EVENT_SET.EVENT_ENTER_SCENE, self.id)
end

function Retrieve_scene_type:enter_scene(con, map_id, type)
	if self.map_type == type then
		self:change_flag(con)
	end
end

function Retrieve_scene_type:serialize_to_db()
	
	local m_db = f_get_db()
	local query = string.format("{char_id:%d}", self.char_id)

	local result = {}
	result.id = self.id
	result.day = self.day
	result.flag = self.flag
	result.map_type = self.map_type
	result = Json.Encode(result)

	local info = string.format([[{"items.%d":%s}]], self.id - 1, result)

	m_db:update(database, query, info, true, false)

	return 0
end

function Retrieve_scene_type:load_fields(record)
	local obj = {}
	--obj.id = record.id
	obj.flag = record.flag
	obj.day = record.day
	obj.id = record.id
	obj.type = record.type
	obj.map_type = record.map_type

	return obj
end

function Retrieve_scene_type:get_update_data()
	local pkt = {}
	pkt.id = self.id
	pkt.day = self.day
	pkt.flag = self.flag
	pkt.map_type = self.map_type
	return pkt
end

Retrieve_mgr.register_class(RETRIEVE_TYPE_SCENE_TYPE, Retrieve_scene_type)