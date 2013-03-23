
local gift_loader = require("bags.monster_gift_loader")
local integral_func=require("mall.integral_func")

local _bag_size = 100
local _each_size = 0
local _max_size = 100

local monster_cost = {
			{8, 69, 198},
			{40, 380, 1130},
			{40, 380, 1130},
			{40, 380, 1130}
}

local unluck = {150, 110, 110, 110}

Monster_bag = oo.class(Base_bag, "Monster_bag")


function Monster_bag:__init(char_id, bag_id, bag_size, bag_mgr)
	Base_bag.__init(self, char_id, bag_id, bag_size, bag_mgr)
	self.unlucky  = {0, 0, 0, 0}
end

--生成背包特殊入库属性类
function Monster_bag:db_get_bag_attribute()
	return self.attribute
end

function Monster_bag:can_enter(src_item, src_bag, src_slot, dst_bag, dst_slot)
	if src_bag == dst_bag then
		return 0
	else
		return 43088
	end
end

--获取背包信息
function Monster_bag:get_bag_info()
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
	local player = g_obj_mgr:get_obj(self.char_id)
	local tmp_pkt = {}
	if not self.attribute then
		self.attribute = {}
		self.attribute.update = ev.time
		self.attribute.used = {0, 0, 0, 0}
	else
		if self.attribute.update < f_get_today() then
			self.attribute.used = {0, 0, 0, 0}
			self.attribute.update = ev.time
		end
	end
	tmp_pkt.used = self.attribute.used
	tmp_pkt.limit = {}
	tmp_pkt.limit[1] = player:get_addition(HUMAN_ADDITION.chest_one)
	tmp_pkt.limit[2] = player:get_addition(HUMAN_ADDITION.chest_two)
	tmp_pkt.limit[3] = player:get_addition(HUMAN_ADDITION.chest_three)
	tmp_pkt.limit[4] = player:get_addition(HUMAN_ADDITION.chest_four)

	info[4] = tmp_pkt

	return info
end

function Monster_bag:get_default(src_bag, src_slot, dst_bag, dst_slot)
	if src_bag == SYSTEM_BAG then
		local ept_slot = self:get_ept_slot()
		if not ept_slot then
			return E_BAG_FULL
		end
		return 0, ept_slot
	end
	return E_BAG_FULL
end

function Monster_bag:get_each_size()
	return _each_size
end
function Monster_bag:get_max_size()
	return _max_size
end

--能否降妖
function Monster_bag:can_control_monster(type, count, lvl)
	if not self.attribute then
		self.attribute = {}
		self.attribute.update = ev.time
		self.attribute.used = {0, 0, 0, 0}
	else		
		if type < 1 or type > 4 then
			return 21202
		else
			self.attribute.used[type] = self.attribute.used[type] or 0
		end
		if self.attribute.update < f_get_today() then
			self.attribute.used = {0, 0, 0, 0}
			self.attribute.update = ev.time
		end
	end
	local limit = 0
	local player  = g_obj_mgr:get_obj(self.char_id)
	local name 	  = player:get_name()
	local pack_con = player:get_pack_con()

	if type == 1 then
		limit = player:get_addition(HUMAN_ADDITION.chest_one)
	elseif type == 2 then
		limit = player:get_addition(HUMAN_ADDITION.chest_two)
	elseif type == 3 then
		limit = player:get_addition(HUMAN_ADDITION.chest_three)
	elseif type == 4 then
		limit = player:get_addition(HUMAN_ADDITION.chest_four)
	end

	if limit -  self.attribute.used[type] < count then
		if limit == self.attribute.used[type] then
			return 43072
		else
			return 43073
		end
	end
	
	local need_item_list = nil
	local can_use_goods = false
	if lvl == 1 then
		need_item_list = gift_loader.GetMonsterNeedItem(type)
		if not need_item_list then print("xml need_item is nil") return 21202 end
	end

	if need_item_list then
		for i,v in pairs(need_item_list) do
			 can_use_goods = pack_con:get_item_count(tonumber(i)) >= tonumber(v)
			 if can_use_goods then 
				break 
			end
		end
	end

	return 0, can_use_goods
end

--道具降妖
function Monster_bag:do_control_monster_use_item(type, count, lvl)
	--print("Monster_bag:do_control_monster_use_item", type, count)
	local need_item_id = 0
	local need_item_count = 0
	local can_use_goods = false
	local need_item_list = gift_loader.GetMonsterNeedItem(type)
	if not need_item_list then print("xml need_item is nil") return 21202 end

	local player  = g_obj_mgr:get_obj(self.char_id)
	local pack_con = player:get_pack_con()
	if need_item_list then
		for i,v in pairs(need_item_list) do
			 can_use_goods = pack_con:get_item_count(tonumber(i)) >= tonumber(v)
			 if can_use_goods then 
			 	need_item_id = tonumber(i)
				need_item_count = tonumber(v)
				break 
			end
		end
	end
	if not can_use_goods then return {}, 21202 end

	local e_code = pack_con:del_item_by_item_id_inter_face(need_item_id, need_item_count, {['type']=ITEM_SOURCE.CHEST_NEEDITEM}, 1)
	if e_code ~= 0 then
		return {}, e_code
	end
	
	return self:do_control_monster(type, count, lvl, true)
end

--降妖
function Monster_bag:do_control_monster(type, count, lvl, can_use_goods)
	--print("Monster_bag:do_control_monster", type, count, can_use_goods)
	local player = g_obj_mgr:get_obj(self.char_id)
	if not player then return {}, 21202 end
	local name = player:get_name()
	local tmp = gift_loader.monster_gift_item
	local broadcast 
	local item_list = {}
	local s_pkt = {}
	s_pkt.list = {}
	for i = 1, count do
		local tmp_pkt = {}
		item_list[i] = {}
		item_list[i].type = 2

		if self.unlucky[type] < unluck[type] then
			broadcast, item_list[i].item, item_list[i].number, tmp_pkt = self:random_gift(tmp.total[type], type, name, can_use_goods)
			if broadcast then
				self.unlucky[type] = 0
			else
				self.unlucky[type] = self.unlucky[type] + 1
			end
		else			--没抽中补偿必中
			broadcast, item_list[i].item, item_list[i].number, tmp_pkt = self:random_gift(tmp.spec[type], type, name, can_use_goods)
			self.unlucky[type] = 0
		end
		table.insert(s_pkt.list, tmp_pkt)
	end
	s_pkt.result = 0
	g_cltsock_mgr:send_client(self.char_id, CMD_MAP_CRATES_QXFJ_S ,s_pkt)

	if not can_use_goods then
		if type == 4 then
			integral_func.add_bonus(self.char_id, monster_cost[type][lvl], {['type']= MONEY_SOURCE.CHEST_FOUR })
		else
			integral_func.add_bonus(self.char_id, monster_cost[type][lvl], {['type']=(MONEY_SOURCE.CHEST_ONE -1 + type)})
		end
	end
	self.attribute.used[type] = self.attribute.used[type] + count 
	local result = {}
	result.used = self.attribute.used
	result.limit = {}
	result.limit[1] = player:get_addition(HUMAN_ADDITION.chest_one)
	result.limit[2] = player:get_addition(HUMAN_ADDITION.chest_two)
	result.limit[3] = player:get_addition(HUMAN_ADDITION.chest_three)
	result.limit[4] = player:get_addition(HUMAN_ADDITION.chest_four)

	local error, log_list = self:pri_add(item_list)
	return result, error, log_list
end

function Monster_bag:get_control_monster_cost(type, count, lvl)
	return monster_cost[type][lvl]
end

--[[注释旧降妖
function Monster_bag:control_monster(type, count, lvl)
	if not self.attribute then
		self.attribute = {}
		self.attribute.update = ev.time
		self.attribute.used = {0, 0, 0, 0}
	else		
		if type < 1 or type > 4 then
			return
		else
			self.attribute.used[type] = self.attribute.used[type] or 0
		end
		if self.attribute.update < f_get_today() then
			self.attribute.used = {0, 0, 0, 0}
			self.attribute.update = ev.time
		end
	end
	local limit = 0
	local player  = g_obj_mgr:get_obj(self.char_id)
	local name 	  = player:get_name()
	local pack_con = player:get_pack_con()
	local result = {}

	if type == 1 then
		limit = player:get_addition(HUMAN_ADDITION.chest_one)
	elseif type == 2 then
		limit = player:get_addition(HUMAN_ADDITION.chest_two)
	elseif type == 3 then
		limit = player:get_addition(HUMAN_ADDITION.chest_three)
	elseif type == 4 then
		limit = player:get_addition(HUMAN_ADDITION.chest_four)
	end

	if limit -  self.attribute.used[type] < count then
		if limit == self.attribute.used[type] then
			return {}, 43072
		else
			return {}, 43073
		end
	end
	
	local need_item_list = nil
	local need_item_id = 0
	local need_item_count = 0
	local can_use_goods = false
	if lvl == 1 then
		need_item_list = gift_loader.GetMonsterNeedItem(type)
		if not need_item_list then print("xml need_item is nil") return end
	end

	if need_item_list then
		for i,v in pairs(need_item_list) do
			 can_use_goods = pack_con:get_item_count(tonumber(i)) >= tonumber(v)
			 if can_use_goods then 
			 	need_item_id = tonumber(i)
				need_item_count = tonumber(v)
				break 
			end
		end
	end

	local e_code = 1
	if can_use_goods then
		e_code = pack_con:del_item_by_item_id_inter_face(need_item_id, need_item_count, {['type']=ITEM_SOURCE.CHEST_NEEDITEM}, 1)
	else
		local money_list = {}
		money_list[MoneyType.JADE] = monster_cost[type][lvl]		
		if type == 4 then
			e_code = pack_con:dec_money_l_inter_face(money_list, {['type']= MONEY_SOURCE.CHEST_FOUR })		
		else
			e_code = pack_con:dec_money_l_inter_face(money_list, {['type']=(MONEY_SOURCE.CHEST_ONE -1 + type)})
		end
	end

	if e_code ~= 0 then
		return {}, e_code
	end

	local tmp = gift_loader.monster_gift_item
	local broadcast 
	local item_list = {}
	local s_pkt = {}
	s_pkt.list = {}
	for i = 1, count do
		local tmp_pkt = {}
		item_list[i] = {}
		item_list[i].type = 2

		if self.unlucky[type] < unluck[type] then
			broadcast, item_list[i].item, item_list[i].number, tmp_pkt = self:random_gift(tmp.total[type], type, name, can_use_goods)
			if broadcast then
				self.unlucky[type] = 0
			else
				self.unlucky[type] = self.unlucky[type] + 1
			end
		else			--没抽中补偿必中
			broadcast, item_list[i].item, item_list[i].number, tmp_pkt = self:random_gift(tmp.spec[type], type, name, can_use_goods)
			self.unlucky[type] = 0
		end
		table.insert(s_pkt.list, tmp_pkt)
	end
	s_pkt.result = 0
	g_cltsock_mgr:send_client(self.char_id, CMD_MAP_CRATES_QXFJ_S ,s_pkt)

	if not can_use_goods then
		if type == 4 then
			integral_func.add_bonus(self.char_id, monster_cost[type][lvl], {['type']= MONEY_SOURCE.CHEST_FOUR })
		else
			integral_func.add_bonus(self.char_id, monster_cost[type][lvl], {['type']=(MONEY_SOURCE.CHEST_ONE -1 + type)})
		end
	end
	self.attribute.used[type] = self.attribute.used[type] + count 
	result.used = self.attribute.used
	result.limit = {}
	result.limit[1] = player:get_addition(HUMAN_ADDITION.chest_one)
	result.limit[2] = player:get_addition(HUMAN_ADDITION.chest_two)
	result.limit[3] = player:get_addition(HUMAN_ADDITION.chest_three)
	result.limit[4] = player:get_addition(HUMAN_ADDITION.chest_four)

	return result, self:pri_add(item_list)
end
]]

--随机物品，并广播和记录
function Monster_bag:random_gift(r_table, type, name, can_use_goods)
	local pro = crypto.random(1, r_table.pro + 1)
	for i = 1, table.getn(r_table.list) do
		if r_table.list[i].lvl >= pro then	--选中
			--return r_table.list[i].
			local flags = false			
			local itemid = r_table.list[i].id
			if can_use_goods and r_table.list[i].id % 10 == 1 then
				itemid = itemid - 1
			end
			local e_code, item = Item_factory.create(itemid)
			if r_table.list[i].broadcast and  r_table.list[i].broadcast == '1' then		--广播
				flags = true
				local pkt = {}
				pkt.name = name
				pkt.id	 = type
				pkt.item = item:serialize_to_net()
				pkt.color = item:get_color()
				pkt.record = r_table.list[i].record or 0
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

reg_bag_template(MONSTER_BAG, Monster_bag, _bag_size)

