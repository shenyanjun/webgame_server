--2012-05-21
--zhengyg
--faction bag grid index

-------------------------------------------
--[[interface info : no interface for client]]

--index mgr of grid in bag for faster search
bag_grid_index = oo.class(nil,"bag_item_index")

function bag_grid_index:__init()
	self.uuid_grid={}
	self.itemid_grid={}
end

--add one grid index
function bag_grid_index:add(grid)
	--uuid_grid
	--assert(self.uuid_grid[grid:get_uuid()]==nil)
	self.uuid_grid[grid:get_uuid()] = grid:get_grid_id()
	--itemid_gridids
	local itemid = grid:get_item():get_item_id()
	if self.itemid_grid[itemid]==nil then self.itemid_grid[itemid]={} end
	--assert(self.itemid_grid[itemid][grid:get_grid_id()]== nil)
	self.itemid_grid[itemid][grid:get_grid_id()] = 1
end

--del one grid index
function bag_grid_index:del(grid)

	--assert(self.uuid_grid[grid.m_uuid])
	self.uuid_grid[grid:get_uuid()] = nil
	--assert(self.itemid_grid[grid:get_item():get_item_id()][grid:get_grid_id()])
	self.itemid_grid[grid:get_item():get_item_id()][grid:get_grid_id()] = nil
	
end

--get grid reference by searching conditions
function bag_grid_index:search(con)
	if con.item_id then
		return self.itemid_grid[con.item_id] or {}
	end
	if con.uuid then
		return self.uuid_grid[con.uuid] or {}
	end
	return {}
end
