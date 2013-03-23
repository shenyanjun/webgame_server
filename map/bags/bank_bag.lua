
local _bag_size = 49
local _each_size = 49
local _max_size =  245 -- 343 修改仓库格子数 chendong 120925

Bank_bag = oo.class(Base_bag, "Bank_bag")


function Bank_bag:__init(char_id, bag_id, bag_size, bag_mgr)
	Base_bag.__init(self, char_id, bag_id, bag_size, bag_mgr)
end

function Bank_bag:get_default(src_bag, src_slot, dst_bag, dst_slot)
	if src_bag == SYSTEM_BAG then
		local ept_slot = self:get_ept_slot()
		if not ept_slot then
			return E_BAG_FULL
		end
		return 0, ept_slot
	end
	return E_BAG_FULL
end

function Bank_bag:get_each_size()
	return _each_size
end
function Bank_bag:get_max_size()
	return _max_size
end



reg_bag_template(BANK_BAG, Bank_bag, _bag_size)


