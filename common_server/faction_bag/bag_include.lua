--2012-05-21
--zhengyg
--faction bag include

-------------------------------------------

-- required this file in main.lua

--grid_builder
local g_bag_grid_builder = {}
--called by subclass of bag_base when server loading files in bag_template
function reg_grid_builder(bag_type,grid_class)
	assert(g_bag_grid_builder[bag_type]==nil) -- if hit this , server will not start, check your code
	assert(type(grid_class)=='table')
	g_bag_grid_builder[bag_type] = grid_class
end
--called by bag_base
function get_grid_builder(bag_type)
	return g_bag_grid_builder[bag_type]
end

require ("faction_bag.bag_base.bag_grid_base")
require ("faction_bag.bag_base.bag_grid_index")
require ("faction_bag.bag_base.bag_base")
require ("faction_bag.bag_template.faction_bag.faction_bag_grid")
require ("faction_bag.bag_template.faction_bag.faction_bag")
require ('faction_bag.faction_bag_mgr')
require ('faction_bag.bag_template.faction_bag.faction_bag_op_record')
--globle faction bag mgr
g_faction_bag_mgr = faction_bag_mgr()
--load all faction_bags from db


require ("faction_bag.bag_process")