
--local gift_loader = require("bags.monster_gift_loader")
local integral_func=require("mall.integral_func")

local _bag_size = 10
local _each_size = 0
local _max_size = 210

Home_bag = oo.class(Base_bag, "Home_bag")


function Home_bag:__init(char_id, bag_id, bag_size, bag_mgr)
	Base_bag.__init(self, char_id, bag_id, bag_size, bag_mgr)
end

--生成背包特殊入库属性类
function Home_bag:db_get_bag_attribute()
	return self.attribute
end

--加入材料
function Home_bag:add_material(material_id, num)
	if not self.attribute then
		self.attribute = {}
	end

	self.attribute[material_id] = self.attribute[material_id] or 0

	self.attribute[material_id] = self.attribute[material_id] + num

	return 0
end
--扣除材料
function Home_bag:dec_material(material_id, num)
	if not self.attribute then
		self.attribute = {}
	end

	if not material_id or not self.attribute[material_id] then
		return 43087
	end
	
	if num > self.attribute[material_id] then
		return 43087
	end

	self.attribute[material_id] = self.attribute[material_id] - num

	return 0
end

--检查材料
function Home_bag:check_material(material_id, num)
	if not self.attribute then
		self.attribute = {}
	end

	if not material_id or not self.attribute[material_id] then
		return 43087
	end

	if num > self.attribute[material_id] then
		return 43087
	end

	return 0
end

--获取单个材料
function Home_bag:get_material_num(material_id)
	if not self.attribute then
		self.attribute = {}
	end

	if not material_id or not self.attribute[material_id] then
		return 0
	end

	return self.attribute[material_id]
end

--获取材料信息
function Home_bag:get_material_info()
	if not self.attribute then
		self.attribute = {}
	end
	return self.attribute
end

--开格
function Home_bag:expand_size(size)
	if size <= 0 or self.bag_size + size > _max_size then
		return E_MAX_BAG_SIZE
	end

	self.bag_size = self.bag_size + size
	return 0
end

--获取背包信息
function Home_bag:get_bag_info()
	if not self.attribute then
		self.attribute = {}
	end
	local info = {}
	info[1] = self.bag_id
	info[2] = self.bag_size
	info[3] = {}
	local cnt = 0
	local item_info
	for i = 1, self.bag_size do
		if self.slot_list[i] then
			item_info = {}
			item_info[1] = self.slot_list[i].uuid
			item_info[2] = nil  --映射源
			item_info[3] = self.bag_id
			item_info[4] = i
			item_info[5] = self.slot_list[i].number
			item_info[6] = self.slot_list[i].item:serialize_to_net()
			item_info[7] = nil  --来源
			cnt = cnt + 1
			info[3][cnt] = item_info
		end
	end

	return info
end

function Home_bag:get_default(src_bag, src_slot, dst_bag, dst_slot)
	if src_bag == SYSTEM_BAG then
		local ept_slot = self:get_ept_slot()
		if not ept_slot then
			return E_BAG_FULL
		end
		return 0, ept_slot
	end
	return E_BAG_FULL
end

function Home_bag:get_each_size()
	return _each_size
end
function Home_bag:get_max_size()
	return _max_size
end

function Home_bag:can_enter(src_item, src_bag, src_slot, dst_bag, dst_slot)
	if src_bag == dst_bag then
		return 0
	else
		return 43088
	end
end

--随机物品，并广播和记录
function Home_bag:random_gift(r_table, type, name)
	local pro = crypto.random(1, r_table.pro + 1)
	
	for i = 1, table.getn(r_table.list) do
		if r_table.list[i].lvl >= pro then	--选中
			--return r_table.list[i].
			local flags = false
			local e_code, item = Item_factory.create(r_table.list[i].id)

			if r_table.list[i].broadcast and  r_table.list[i].broadcast == '1' then		--广播
				flags = true
				local pkt = {}
				pkt.name = name
				pkt.id	 = type
				pkt.item = item:serialize_to_net()
				pkt.color= item:get_color()
				g_svsock_mgr:send_server_ex(COMMON_ID,self.char_id, CMD_C2W_CONTROLMONSTER_RECORD_M, pkt)
			end

			--记录		
			local tmp_pkt = {}
			tmp_pkt.item_name = item:get_name()
			tmp_pkt.item_id	= item:get_item_id()
			tmp_pkt.id	 	= type
			tmp_pkt.number 	= r_table.list[i].count
			tmp_pkt.color 	= item:get_color()

			return flags, item, r_table.list[i].count, tmp_pkt
		end
	end

	return
end

reg_bag_template(HOME_BAG, Home_bag, _bag_size)

