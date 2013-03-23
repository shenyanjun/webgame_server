

Limit_obj = oo.class(nil,"Limit_obj")

function Limit_obj:__init(item_id,end_time,index)
	self.end_time = end_time
	self.sell_count = 0
	self.item_id = item_id
	self.index = index
	self.backup = 0
end

function Limit_obj:set_end_time(end_time)
	self.end_time = end_time
end

function Limit_obj:get_end_time()
	return self.end_time
end

function Limit_obj:add_sell_count(count)
	self.sell_count = self.sell_count+count
end


function Limit_obj:get_sell_count()
	return self.sell_count
end


function Limit_obj:get_id()
	return self.item_id
end

function Limit_obj:set_id(id)
	self.item_id = id
end

function Limit_obj:get_index()
	return self.index
end

function Limit_obj:set_index(index)
	self.index = index
end


function Limit_obj:set_backup()
	self.backup = 1
end


function Limit_obj:get_backup()
	return self.backup
end

function Limit_obj:serialize_to_db()
	local obj = {}
	obj.end_time = self.end_time
	obj.sell_count = self.sell_count
	obj.item_id = self.item_id
	obj.index = self.index
	obj.backup = self.backup
	return obj
end

function Limit_obj:clone(db_data)
	self.end_time = db_data.end_time
	self.sell_count = db_data.sell_count
	self.item_id = db_data.item_id
	self.index = db_data.index
	self.backup = db_data.backup	
end