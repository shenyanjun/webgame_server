--2012-05-21
--zhengyg
--class faction_bag_grid

-------------------------------------------
--grid for faction_bag
local db_key2index={
['price']=1
}
faction_bag_grid = oo.class(bag_grid_base,"faction_bag_grid")
function faction_bag_grid:can_add(item_id)
	if self:get_price() ~= nil then  return 0 end --can not stk
	return bag_grid_base.can_add(self,item_id)
end

function faction_bag_grid:serialized_to_net(...)
	local result = bag_grid_base.serialized_to_net(self,...)
	result[8] = self:get_price() or 0
	return result
end

function faction_bag_grid:set_price(price)
	self.m_attr[db_key2index['price']] = price
end

function faction_bag_grid:get_price()
	return self.m_attr[db_key2index['price']]
end