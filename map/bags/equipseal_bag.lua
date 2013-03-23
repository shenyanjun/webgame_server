
local _bag_size = 6
local _max_size = 6
local _each_size = 1

Equipseal_bag = oo.class(Base_bag, "Equipseal_bag")

local equipseal_loader = require("config.equip_seal")


function Equipseal_bag:__init(char_id, bag_id, bag_size, bag_mgr)
	Base_bag.__init(self, char_id, bag_id, bag_size, bag_mgr)
	self.fight = 0
	self.is_show = 1
end

function Equipseal_bag:get_each_size()
	return _each_size
end
function Equipseal_bag:get_max_size()
	return _max_size
end

function Equipseal_bag:get_fighting()
	return self.fight or 0
end

function Equipseal_bag:set_fighting(num)
	self.fight = num
end

function Equipseal_bag:set_show(show)
	self.is_show = show
end

function Equipseal_bag:get_model()
	return (self.is_show >= 1 ) and equipseal_loader.get_seal_model(self:get_fighting()) or ""
end

function Equipseal_bag:get_default(src_bag, src_slot, dst_bag, dst_slot)
	local e_code, src_ctn = self.bag_mgr:get_bag(src_bag)
	local src_grid = src_ctn:get_grid(src_slot)
	return 0, src_grid.item:get_t_class()
end

function Equipseal_bag:can_enter(src_item, src_bag, src_slot, dst_bag, dst_slot)
	if tonumber(src_item:get_m_class()) ~= ItemClass.ITEM_CLASS_EQUIP then
		return 43015
	end

	if dst_slot > self:get_size() then
		return 43008
	end

	local player = g_obj_mgr:get_obj(self.char_id)
	--¼¶±ð
	if not src_item:valid_level(player) then
		f_cmd_show(self.char_id, 20306)
		return 20306
	end

	--Î»ÖÃÅÐ¶Ï
	if dst_slot ~= equipseal_loader.get_relative_solt(tonumber(src_item:get_t_class())) then
		f_cmd_show(self.char_id, 20305)
		return 20305
	end
	return 0
end

reg_bag_template(EQUIPSEAL_BAG, Equipseal_bag, _bag_size)