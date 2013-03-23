
local _bag_size = 28

Stall_bag = oo.class(Base_bag, "Stall_bag")

function Stall_bag:__init(char_id, bag_id, bag_size, bag_mgr)
	Base_bag.__init(self, char_id, bag_id, bag_size, bag_mgr)
end

--获取背包信息，用户登录的时候需要取得该信息
function Stall_bag:get_bag_info()
	local info = {}
	for i = self:get_bag_start(), self:get_size() do
		if self.slot_list[i] then
			local cnt = self.slot_list[i].uuid
			info[cnt] = {}
			info[cnt].id = self.slot_list[i].uuid
			info[cnt].stall_cost = self.slot_list[i].item.stall_price
			info[cnt].count = self.slot_list[i].number
			info[cnt].stall_type = self.slot_list[i].item.money_type
			info[cnt].slot = i
			info[cnt].item_obj = self.slot_list[i].item:serialize_to_net()
		end
	end
	return info
end


--上架
function Stall_bag:on_sale(uuid, money_type, price)
	local dst_slot
	dst_slot = self:get_ept_slot()
	if not dst_slot then
		return E_BAG_FULL
	end

	local sys_bag , grid
	e_code, sys_bag = self.bag_mgr:get_bag(SYSTEM_BAG)
	grid = sys_bag:get_item_by_uuid(uuid)
	if not grid then
		return 43339
	end
	if grid.item:get_bind() == 0 then
		return 43341
	end
	grid.item:set_stall_price(money_type, price)
	return self.bag_mgr:swap(SYSTEM_BAG, grid.slot, STALL_BAG, dst_slot)
end




--物品下架
function Stall_bag:take_back(uuid)
	local grid = self:get_item_by_uuid(uuid)
	if not grid then
		return 43339
	end

	local sys_bag
	e_code, sys_bag = self.bag_mgr:get_bag(SYSTEM_BAG)
	if e_code ~=0 then
		return e_code
	end


	local dst_slot = sys_bag:get_ept_slot()
	if not dst_slot then
		return E_BAG_FULL
	end

	local no_src = true
	return self.bag_mgr:swap(STALL_BAG, grid.slot, SYSTEM_BAG, dst_slot, no_src)
end


--收摊
function Stall_bag:close_stall()
	local ret, item
	--检查空格数
	local item_cnt = self:get_item_cnt()

	local sys_bag
	e_code, sys_bag = self.bag_mgr:get_bag(SYSTEM_BAG)
	if e_code ~=0 then
		return e_code
	end
	local ept_cnt = sys_bag:get_ept_cnt()

	if item_cnt>ept_cnt then
		return E_BAG_FULL
	end

	--回收物品
	for i = self:get_bag_start(), self:get_size() do
		if self.slot_list[i] then
			self:take_back(self.slot_list[i].uuid)
		end
	end
	return 0
end


reg_bag_template(STALL_BAG, Stall_bag, _bag_size)




