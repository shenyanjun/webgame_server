

local _bag_size = 84
local _each_size = 7
local _max_size = 210  --252 修改背包个数 chendong 120925

System_bag = oo.class(Base_bag, "System_bag")

function System_bag:__init(char_id, bag_id, bag_size, bag_mgr)
	Base_bag.__init(self, char_id, bag_id, bag_size, bag_mgr)
end

function System_bag:get_each_size()
	return _each_size
end
function System_bag:get_max_size()
	return _max_size
end


reg_bag_template(SYSTEM_BAG, System_bag, _bag_size)





