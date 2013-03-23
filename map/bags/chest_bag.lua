

local _bag_size = 150

Chest_bag = oo.class(Base_bag, "Chest_bag")

function Chest_bag:__init(char_id, bag_id, bag_size, bag_mgr)
	Base_bag.__init(self, char_id, bag_id, bag_size, bag_mgr)
end

reg_bag_template(CHEST_BAG, Chest_bag, _bag_size)






