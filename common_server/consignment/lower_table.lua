--2011-05-05
--cqs
--索引表基类

--local faction_update_loader = require("item.faction_update_loader")

Lower_table = oo.class(nil, "Lower_table")

function Lower_table:__init()
	self.count			= 0			--数量
	self.list	 		= {}		--UUID表，用table.insert插入
	--[[self.number_list	= {}    	--时间表，数组形式保存
	self.currency		= {}		--货币
	self.others			= {}		--其他]]
end

function Lower_table:add_uuid(uuid)
	self.count = self.count + 1
	table.insert(self.list , uuid)
	return
end

--
function Lower_table:dec_uuid(uuid)
	local tmp = nil
	for i = 1,  self.count do
		if self.list[i] and self.list[i] == uuid then
			tmp = i
			break
		end
	end
	if tmp then
		table.remove(self.list , tmp)
		self.count = self.count - 1
	end
end

function Lower_table:get_count()
	return self.count
end

function Lower_table:get_uuid(k)
	return self.list[k]
end

function Lower_table:get_pages_pagesize_uuid(pages,pagesize)
	local uuid_table = {}
		for i = 1, pagesize do
			if self.list[i + pagesize * (pages - 1)] then
				table.insert(uuid_table,self.list[i + pagesize * (pages - 1)])
			else 
				break
			end
		end 
	return uuid_table
end