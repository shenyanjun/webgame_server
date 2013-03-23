
local _bag_size = 5

Garbage_bag = oo.class(Base_bag, "Garbage_bag")

function Garbage_bag:__init(char_id, bag_id, bag_size, bag_mgr)
	Base_bag.__init(self, char_id, bag_id, bag_size, bag_mgr)
end

function Garbage_bag:get_ept_slot()
	if self.item_cnt == self:get_size() then
		--全部物品向左移动一格
		self:erase_grid(1)
		for i = self:get_bag_start()+1, self:get_size() do
			local grid = self:get_grid(i)
			self:load_grid(i-1, grid.uuid, grid.number, grid.item)
			self:erase_grid(i)
		end
		--self.item_cnt = self.item_cnt - 1
		return self:get_size()
	else
		return Base_bag.get_ept_slot(self)
	end
end

--删除后左移
function Garbage_bag:del_item_by_slot(slot,count)
	self:erase_grid(slot)
	for i = slot+1, self:get_size() do
		if self.slot_list[i] then
			local grid = self:get_grid(i)
			self:load_grid(i-1, grid.uuid, grid.number, grid.item)
			self:erase_grid(i)
		end
	end
	return 0
end

--旧的协议
function Garbage_bag:get_item_list()
	local info = {}
	local cnt = 0
	local item_info
	for i = self:get_bag_start(), self:get_size() do
		if self.slot_list[i] then
			
			cnt = cnt + 1
			info[cnt] = self.slot_list[i]

		end
	end
	return info
end


reg_bag_template(GARBAGE_BAG, Garbage_bag, _bag_size)
