--用于提供跨线排行
Public_sort_mgr = oo.class(nil, "public_sort_mgr")

local scene_sort_table = "scene_sort"
local scene_sort_index = "{'line_id':1}"
local sort_extend_table = "sort_extend"
local sort_extend_index = "{'line_id':1}"

PUBLIC_SORT_TYPE = {
	SCENE				= 0
	, ESCORT			= 1
}

PUBLIC_SORT_ORDER = {
	ASC					= false	--升序
	, DESC				= true	--降序
}

function Public_sort_mgr:__init()
	self.scene_sort = {}
	self.sort_list = {}
	self:load_record()
end

function Public_sort_mgr:load_scene_sort()
	local query = string.format("{'line_id':%d}", SELF_SV_ID)
	local rows, e_code = f_get_db():select(scene_sort_table, "{'_id':0}", query, nil, 0, 0, scene_sort_index)
	if 0 == e_code and rows then
		for _, row in pairs(rows) do
			local scene_id = row.scene_id
			local record = row.record
			local id = row.layer
			local record_list = self.scene_sort[scene_id]
			if not record_list then
				record_list = {}
				self.scene_sort[scene_id] = record_list
			end
			record_list[id] = {["record"] = record, ["is_dirty"] = false}
		end
	end
end

function Public_sort_mgr:load_record()
	self:load_scene_sort()
	
    local db = f_get_db()
    local namespace = sort_extend_table
    local fields = "{_id:0}"
    local query = string.format("{'line_id':%d}", SELF_SV_ID)
    local sort = nil
    local limit = 0
    local skip = 0
    local index = sort_extend_index
    
    local rows, e_code = db:select(namespace, fields, query, sort, limit, skip, index)

	if 0 == e_code and rows then
		for _, row in ipairs(rows) do
			local type = row.type
			self.sort_list[type] = {["record"] = row.record, ["is_dirty"] = false}
		end
	end
end

function Public_sort_mgr:insert_sort(record_row, info, sort_max, flag)
	local change = false
	
	for i = 1, sort_max do
		local record = record_row[i]
		if not record then
			record_row[i] = info
			change = true
			break
		else
			if record.time == info.time then
				if record.record_time > info.record_time then
					record_row[i] = info
					info = record
					change = true
				end
			elseif flag then
				if record.time < info.time then
					record_row[i] = info
					info = record
					change = true
				end
			elseif record.time > info.time then
				record_row[i] = info
				info = record
				change = true
			end
		end
	end
	
	return change
end

function Public_sort_mgr:update_record(type, key, value, flag)
	local sort_max = 10
	
	if PUBLIC_SORT_TYPE.SCENE == type then
		local scene_id = value.scene_id
		local id = value.id
		local info = {["time"] = key, ["record_time"] = ev.time, ["data"] = value.data}
		
		local record_list = self.scene_sort[scene_id]
		if not record_list then
			record_list = {}
			record_list[id] = {["record"] = {}, ["is_dirty"] = true}
			self.scene_sort[scene_id] = record_list
			table.insert(record_list[id].record, info)
		else
			local record_row = record_list[id]
			if not record_row then
				record_row = {["record"] = {}, ["is_dirty"] = true}
				record_list[id] = record_row
				table.insert(record_row.record, info)
			else
				if self:insert_sort(record_row.record, info, sort_max, flag) then
					record_row.is_dirty = true
				end
			end
		end
	else
		local info = {["time"] = key, ["record_time"] = ev.time, ["data"] = value}

		local record_row = self.sort_list[type]
		if not record_row then
			record_row = {["record"] = {}, ["is_dirty"] = true}
			self.sort_list[type] = record_row
			table.insert(record_row.record, info)
		else
			if self:insert_sort(record_row.record, info, sort_max, flag) then
				record_row.is_dirty = true
			end
		end
	end
end

function Public_sort_mgr:save_record()
	local db = f_get_db()
	for k, v in pairs(self.scene_sort) do
		for id, info in pairs(v) do
			if info.is_dirty then
				local query = string.format("{'line_id':%d, 'scene_id':%d, 'layer':%d}", SELF_SV_ID, k, id)
				local values = string.format(
					"{'line_id':%d, 'scene_id':%d, 'layer':%d, 'record':%s}"
					, SELF_SV_ID
					, k
					, id
					, Json.Encode(info.record))
				db:update(scene_sort_table, query, values, true)
				info.is_dirty = false
			end
		end
	end
	
	for type, record in pairs(self.sort_list) do
		if record.is_dirty then
			local query = string.format("{'line_id':%d, 'type':%d}", SELF_SV_ID, type)
			
			local values = {}
			values.line_id = SELF_SV_ID
			values.type = type
			values.record = record.record
		
			db:update(sort_extend_table, query, Json.Encode(values), true)
			record.is_dirty = false
		end
	end
end

function Public_sort_mgr:on_timer()
	self:save_record()
end