--2011-05-05
--cqs
--索引表类

require("consignment.lower_table")

Index_table = oo.class(nil, "Index_table")

function Index_table:__init()
	self.equi			= Lower_table()		--装备类
	self.gem	 		= Lower_table()		--宝石
	self.pet			= Lower_table()    	--宠物
	self.others			= Lower_table()		--其他
	self.weapon			= Lower_table()		--武器
	self.armor			= Lower_table()		--防具
	self.ornament		= Lower_table()		--饰品
	self.jade			= Lower_table()		--元宝
	self.gold			= Lower_table()		--铜币
	self.total 			= Lower_table()		--总的
end

function Index_table:add_type_index(type,uuid)
	if self[type] then
		self[type]:add_uuid(uuid)
		self.total:add_uuid(uuid)
		return true
	else
		return false
	end
end

function Index_table:sub_type_index(type,uuid)
	if type == 'total' then
		return false
	elseif self[type] then
		self[type]:dec_uuid(uuid)
		self.total:dec_uuid(uuid)
		return true
	else
		return false
	end
end

function Index_table:get_index_table_uuid(type,k)
	if self[type] then	
		return self[type]:get_uuid(k)
	else
		return false
	end
end

function Index_table:get_index_table_count(type)
	if self[type] then	
		return self[type]:get_count()
	else
		return false
	end
end

function Index_table:get_pages_pagesize_table_uuid(type,pages,pagesize)
	if self[type] then	
		return self[type]:get_pages_pagesize_uuid(pages,pagesize)
	else
		return false
	end
end