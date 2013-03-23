--2012-05-25
--zhengyg
--faction bag operation record

------------------------------------------
local op_type = {} 
op_type[1]=true -- add
op_type[2]=true -- sub
op_type[3]=true -- destroy
op_type[5]=true -- all
local max_line = 50 --max_line

local fbag_record = oo.class(nil,"fbag_record")

function fbag_record:__init(db_info,type,max_line)
	self.type = db_info.type or type
	self.ptr  = db_info.ptr or 1
	self.data = db_info.data or {}	
end

function fbag_record:serialized()
	local db_info = {}
	db_info.type  = self.type
	db_info.ptr   = self.ptr
	db_info.data  = self.data
	return db_info
end

function fbag_record:update_ptr()
	if self.ptr <= 0 then
		self.ptr = max_line
	elseif self.ptr > max_line then
		self.ptr = 1
	end
end

function fbag_record:get_num()
	if self.data[max_line] then
		return max_line 
	else
		return self.ptr - 1
	end
	
end

function fbag_record:add(time,char_name,item_id,item_cnt,type,cost)
	--print('fbag_record:add')
	self:update_ptr()
	self.data[self.ptr] = {time,char_name,item_id,item_cnt,type,cost}
	self.ptr = self.ptr + 1
	self:update_ptr()
end

function fbag_record:get(page,page_size)
    
	page 	  = page or 1
	page_size = page_size or 5
	
	if page * page_size > max_line then 
		print('page:'..page..' page_size:'..page_size..' too large') 
		return 
	end
	
	self:update_ptr()
	
	local index_e = (self.ptr - (page - 1) * page_size - 1 + max_line)%max_line
	if index_e == 0 then
		index_e = max_line
	end
	
	local index = 1
	local cnt = 0
	local finish = nil
	local result = {}
	for i = index_e , 1 , -1 do
		if self.data[i] then
			result[index] = self.data[i]
			index = index + 1
			cnt   = cnt + 1
		end
		if cnt == page_size then
			finish = true
			break --return result
		end
	end
	if finish==nil then
		for i = max_line , self.ptr , -1 do
			if self.data[i] then
				result[index] = self.data[i]
				index = index + 1
				cnt   = cnt + 1
			end
			if cnt == page_size then
				break--return result
			end
		end
	end
	--print('index_e:'..index_e..'ptr:'..self.ptr)
	local ret={}
	ret.page_num  = math.ceil(self:get_num() / page_size)
	ret.page_size = page_size
	ret.cur_page  = page
	ret.data 	  = result
	return ret
end
---------------------------------------------------------
fbag_record_container = oo.class(nil,'fbag_record_container')

function fbag_record_container:__init(db_info,faction_id)
	self.faction_id   = db_info.faction_id or faction_id
	self.m_records = {}
	self:unserialized(db_info)
end

function fbag_record_container:serialized()
	local db_info = {}
	db_info.data = {}
	db_info.faction_id = self.faction_id
	db_info.data[1] = self.m_records[1]:serialized()
	db_info.data[2] = self.m_records[2]:serialized()
	db_info.data[3] = self.m_records[3]:serialized()
	--
	db_info.data[5] = self.m_records[5]:serialized()
	return db_info
end

function fbag_record_container:unserialized(db_info)
	if db_info and db_info.data then
		self.m_records[1] = fbag_record(db_info.data[1],1)
		self.m_records[2] = fbag_record(db_info.data[2],2)
		self.m_records[3] = fbag_record(db_info.data[3],3)
		--self.m_records[4]
		self.m_records[5] = fbag_record(db_info.data[5],5)
	else
		self.m_records[1] = fbag_record({},1)
		self.m_records[2] = fbag_record({},2)
		self.m_records[3] = fbag_record({},3)
		--self.m_records[4]
		self.m_records[5] = fbag_record({},5)
	end
end

function fbag_record_container:get(page,page_size,op_type)
	page 	  = page or 1
	page_size = page_size or 5
	
	if page * page_size > max_line then 
		print('page:'..page..' page_size:'..page_size..' too large') 
		return 
	end
	
	if op_type == 0 then 
		op_type = 5 
	end
	
	return self.m_records[op_type]:get(page,page_size)
end

function fbag_record_container:add(time,char_name,item_id,item_cnt,type,cost)
	if type == 5 or self.m_records[type]==nil then return end
	self.m_records[type]:add(time,char_name,item_id,item_cnt,type,cost)
	self.m_records[5]:add(time,char_name,item_id,item_cnt,type,cost)
end