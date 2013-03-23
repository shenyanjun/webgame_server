

MONEY_IO = {
	IN = 1,
	OUT = 0,}

Money_change = {
	add_money = 1,
	dec_money = 2,
}

local bag_template = create_local("bag_include.bag_template", {})
function get_bag_template()
	return bag_template.value
end
function reg_bag_template(bag_id, cls, bag_size)
	local template = oo.class(cls, "bag_class_" .. tostring(bag_id))
	template.__init = function (self, char_id, bag_mgr)
						cls.__init(self, char_id, bag_id, bag_size, bag_mgr)
					  end
	bag_template.value[bag_id] = template
end


require("bags.base_bag")
require("bags.common_bag")
require("bags.equipment_bag")
require("bags.mount_bag")
require("bags.stall_bag")
require("bags.bank_bag")
require("bags.sell_bag")
require("bags.chest_bag")
require("bags.bag_container")
require("bags.expand_bag_loader")
require("bags.monster_gift_loader")
require("bags.monster_bag")
require("bags.home_bag")
require("bags.equipseal_bag")
