local config = require("story.story_loader")
local namespace = "story"
Story_container = oo.class(nil, "Story_container")

function Story_container:__init(char_id)
	self.char_id = char_id
	self.story_list = {}
	self.story_map = {}
	self.map_list = {}
end

--从数据库加载
function Story_container:load(first_login)
	local player = g_obj_mgr:get_obj(self.char_id)
	local level = player and player:get_level() or 1
	
	local record_map = {}
	if not first_login then
		local query = string.format([[{"char_id":%d}]], self.char_id)
		local db = f_get_db()
		local row, e_code = db:select_one(namespace, "{'_id':0}", query, nil, nil)
		if 0 == e_code and row then
			record_map = row.list or {}
		end
	end
	
	local before = nil
	for _, v in ipairs(config.config) do
		local id = v.id
		local info = record_map[id] and {id, record_map[id]}
		if not info then
			local type = 0
			
			if not before or before > 2 then
				local map_id = v.postcondition.map_id
				if map_id then
					self.map_list[map_id] = id
					type = level >= v.precondition.level and 2 or 1
				end
			elseif 1 == before or 2 == before then
				local map_id = v.postcondition.map_id
				if map_id then
					self.map_list[map_id] = id
					type = 1
				end	
			end
		
			info = {v.id, type}
		end
		
		
		table.insert(self.story_list, info)
		self.story_map[v.id] = {info, v}
		before = info[2]
	end

	return true
end

function Story_container:level_up_init()
	self:load(true)
end

function Story_container:get_chapter_list()
	return self.story_list
end

function Story_container:update_state(story_id, state)
	local query = string.format("{'char_id':%d}", self.char_id)
	local values = string.format("{'$set':{'list.%s':%d}}", story_id, state)
	f_get_db():update(namespace, query, values, true)
end

function Story_container:end_story(map_id)
	local id = self.map_list[map_id]
	if id then
		local info = self.story_map[id]
		if info then
			if info[1][2] < 3 then
				info[1][2] = 3
				self:update_state(id, 3)
				
				local args = {}
				args.level = g_obj_mgr:get_obj(self.char_id):get_level()
				self:notify_level_up_event(args)
				return id
			end
		end
	end
	return nil
end

function Story_container:can_access(chapter_id)
	local player = g_obj_mgr:get_obj(self.char_id)
	local map_id = player:get_map_id()
	if self.map_list[map_id] then
		return E_STORY_EXISTS, nil
	end
	
	local info = self.story_map[chapter_id]
	if not info then
		return E_STORY_INVALID_ID, nil
	end
	
	if info[1][2] < 2 then
		return E_STORY_PREQUEST, nil
	end
	
	return E_SUCCESS, info[2].postcondition.map_id
end

function Story_container:get_reward(chapter_id)
	local info = self.story_map[chapter_id]
	if not info then
		return E_STORY_INVALID_ID
	end
	
	if 3 == info[1][2] then
		info[1][2] = 4
		local player = g_obj_mgr:get_obj(self.char_id)
		local pack_con = player:get_pack_con()
	
		local result_list = {}
		local item_list = info[2].reward
		if item_list then
			for _, v in ipairs(item_list) do
				local item = {}
				item.type = 1
				item.number = v.number
				item.item_id = v.id
				table.insert(result_list, item)
			end
		end
	
		local e_code = pack_con:add_item_l(result_list, {['type'] = ITEM_SOURCE.GOAL})
		if E_SUCCESS ~= e_code then
			info[1][2] = 3
			return e_code
		end
		
		self:update_state(chapter_id, 4)
		return E_SUCCESS
	end
	
	return E_STORY_INCOMPLETE
end

function Story_container:notify_level_up_event(args)
	local level = args and args.level
	if level then
		local prev = nil
		for _, v in ipairs(self.story_list) do
			local id = v[1]
			local type = v[2]
			if type < 3 then
				if type == 1 then
					local info = self.story_map[id]
					local con = info[2]
					local map_id = con.postcondition.map_id
					if map_id and level >= con.precondition.level then
						if not prev or prev[2] >= 3 then
							v[2] = 2
						end
					end
				end
				break
			end
			prev = v
		end
	end
end