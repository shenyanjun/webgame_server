
local _bag_size = 5

Mount_bag = oo.class(Base_bag, "Mount_bag")

function Mount_bag:__init(char_id, bag_id, bag_size, bag_mgr)
	Base_bag.__init(self, char_id, bag_id, bag_size, bag_mgr)
	self.main_slot = 1
end

function Mount_bag:can_enter(item, src_bag, src_slot, dst_bag, dst_slot)
	if src_bag~=dst_bag and self.item_cnt >= 4 then
		return E_NO_VALID_SLOT
	end
	
	if item:get_m_class() ~= 9 then
		return E_NO_VALID_SLOT
	end

	--等级判断
	local player = g_obj_mgr:get_obj(self.char_id)
	if not item:valid_level(player) then
		return 20306
	end

	return 0
end

function Mount_bag:get_default(src_bag, src_slot, dst_bag, dst_slot)
	--如果是主坐骑休息
	if src_bag == MOUNTS_BAG and dst_bag == MOUNTS_BAG and src_slot == MOUNTS_SLOT_MAIN then
		for i = MOUNTS_SLOT_VICE_1, self:get_size() do
			if not self.slot_list[i] then
				return 0, i
			end
		end
	end

	if self.item_cnt >= 4 then
		return E_NO_VALID_SLOT
	end

	for i = self:get_bag_start(), self:get_size() do
		if self.item_cnt == 0 then
			return 0,i
		elseif  i~= self.main_slot and not self.slot_list[i] then  --i~= self.main_slot and
			return 0, i
		end
	end
end


function Mount_bag:can_dress(item,src_pos,dst_pos)
	local player = g_obj_mgr:get_obj(self.char_id)
	local item_obj = item.item_obj

	if not item_obj:isa(RideTemplate) then
		return false, 43015
	end

	if player:get_level() < item_obj.req_lvl then
		f_cmd_show(self.char_id, 20306)
		return false, 20306
	end
	return true
end


reg_bag_template(MOUNTS_BAG, Mount_bag, _bag_size)

