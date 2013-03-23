
local _bag_size = 12

Equipment_bag = oo.class(Base_bag, "Equipment_bag")

function Equipment_bag:__init(char_id, bag_id, bag_size, bag_mgr)
	Base_bag.__init(self, char_id, bag_id, bag_size, bag_mgr)
end

function Equipment_bag:get_default(src_bag, src_slot, dst_bag, dst_slot)
	local e_code, src_ctn = self.bag_mgr:get_bag(src_bag)
	local src_grid = src_ctn:get_grid(src_slot)
	return 0, src_grid.item:get_t_class()

end

function Equipment_bag:can_enter(src_item, src_bag, src_slot, dst_bag, dst_slot)

	if tonumber(src_item:get_m_class()) ~= ItemClass.ITEM_CLASS_EQUIP then
		return 43015
	end

	--增加时装不进装备背包
	if src_item:is_fashion() then 
		return 43015
	end

	--时装要对性别有判断
	if src_item.proto.value.sex then
		local player = g_obj_mgr:get_obj(self.char_id)
		if src_item.proto.value.sex ~= player:get_sex() then
			f_cmd_show(self.char_id, 20305)
			return 20305
		end
	end
	

	local player = g_obj_mgr:get_obj(self.char_id)

	--位置判断
	if dst_slot ~= tonumber(src_item:get_t_class()) then
		f_cmd_show(self.char_id, 20305)
		return 20305
	end

	--耐久
	if not src_item:valid_endure(player) then
		return 43022
	end

	--级别
	if not src_item:valid_level(player) then
		f_cmd_show(self.char_id, 20306)
		return 20306
	end
	--职业
	if not src_item:is_fashion() then  --时装不分职业
		if not src_item:valid_occ(player) then
			f_cmd_show(self.char_id, 20305)
			return 20305
		end
	end
	if src_item:is_fashion() then 
		src_item:on_wear()
	end
	return 0
end

function Equipment_bag:set_fashion(fashion_id)
	local slot = EQUIPMENT_SLOT_OUTLOOK
	if fashion_id == nil then
		local log_list = self:get_update_log(ItemSyncFlag.ITEM_SYNC_REMOVE, slot, -1)
		self:erase_grid(slot);
		return 0, {log_list}
	else
		local e_code, item = Item_factory.create(fashion_id)
	    if e_code ~= 0 or not item:is_fashion() then 
			return 
		end
		local log_list = self:get_update_log(ItemSyncFlag.ITEM_SYNC_REMOVE, slot, -1)
		local uuid = crypto.uuid()
		local code, log_list2 = self:set_grid(slot, uuid, 1, item)
		return code, {log_list}, log_list2
	end
end


reg_bag_template(EQUIPMENT_BAG, Equipment_bag, _bag_size)



