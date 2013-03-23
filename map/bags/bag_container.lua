
local endure_time = 60

local debug_print = print

local log_filter = require("config.log_filter")

local integral_loader = require("config.integral_config") 
local proto_mgr = require("item.proto_mgr")
local equip_seal = require("config.equip_seal")
--***************背包管理类结构**************

Bag_container = oo.class(nil, "Bag_container")

function Bag_container:__init(char_id)
	self.char_id = char_id
	--下标为背包编号，内容是base_bag的继承类实例
	self.bag_list = {}
	--下标是背包编号，内容是背包大小
	--bag_size_list[1]记录gold
	--bag_size_list[2]记录GIFT_GOLD
	--bag_size_list[3]记录JADE
	--bag_size_list[4]记录GIFT_JADE
	--bag_size_list[5]记录BANK_GOLD
	--bag_size_list[5]记录后台充值？
	self.bag_size_list = {}

	--流水
	self.player_name = g_obj_mgr:get_obj(self.char_id):get_name()
end

--*****************客户端更新***************

--通知客户端各种货币的数量
function Bag_container:update_clt_money()
	local ret = {}
	ret.result = 0
	ret.list = {}
	ret.list[1] = self.bag_size_list[MoneyType.GOLD] or 0
	ret.list[2] = self.bag_size_list[MoneyType.GIFT_GOLD] or 0
	ret.list[3] = self.bag_size_list[MoneyType.JADE] or 0
	ret.list[4] = self.bag_size_list[MoneyType.GIFT_JADE] or 0
	ret.list[5] = self.bag_size_list[MoneyType.BANK_GOLD] or 0

	--
	ret.list[6] = self.bag_size_list[MoneyType.INTEGRAL] or 0
	ret.list[7] = (self.bag_size_list[MoneyType.BONUS] or 0)/100
	ret.list[8] = self.bag_size_list[MoneyType.HONOR] or 0
	ret.list[9] = self.bag_size_list[MoneyType.GLORY] or 0
	g_cltsock_mgr:send_client(self.char_id, CMD_MAP_GET_MONEY_S, ret)
end

--通知客户端物品的变化
function Bag_container:update_client(e_code, change_list, src_log)
	local data = {}
	data.result = e_code
	if e_code ~= 0 then
		g_cltsock_mgr:send_client(self.char_id, CMD_MAP_UPDATE_ITEM_S, data)
		return 0
	end

	if not change_list then
		return
	end

	data.list = {}
	local pnt = 0
	for k, v in pairs(change_list) do
		pnt = pnt + 1
		if v.op== ItemSyncFlag.ITEM_SYNC_ADD then
			data.list[pnt]={}
			data.list[pnt][1] = v.uuid
			data.list[pnt][2] = v.src_uuid
			data.list[pnt][3] = v.bag
			data.list[pnt][4] = v.slot
			data.list[pnt][5] = v.number
			if not v.src_uuid or no_src then
				data.list[pnt][6] = v.item:serialize_to_net()
				data.list[pnt][2] = nil
			end
			if src_log and src_log.type then
				data.list[pnt][7] = src_log.type
			end
		end
		if v.op==ItemSyncFlag.ITEM_SYNC_UPDATE then
			data.list[pnt]={}
			data.list[pnt][1] = v.uuid
			data.list[pnt][2] = v.src_uuid
			data.list[pnt][3] = v.bag
			data.list[pnt][4] = v.slot
			data.list[pnt][5] = v.number
			if v.no_src then
				data.list[pnt][6] = v.item:serialize_to_net()
			elseif not v.src_uuid then
				data.list[pnt][6] = v.item:serialize_to_net()
				data.list[pnt][2] = nil
			end
			--if not v.src_uuid or not v.no_src then
				--data.list[pnt][6] = v.item:serialize_to_net()
				--data.list[pnt][2] = nil
			--end
			--买进来的物品叠加了
			if src_log and src_log.type then
				data.list[pnt][7] = src_log.type
			end

			v.no_sr = nil		--该字段仅为交换时装备的标识,用完去掉
		end
		if v.op==ItemSyncFlag.ITEM_SYNC_REMOVE then
			data.list[pnt]={}
			data.list[pnt][1] = v.uuid
			data.list[pnt][2] = v.uuid
			data.list[pnt][3] = v.bag
			data.list[pnt][4] = v.slot
			data.list[pnt][5] = 0
		end
	end
	g_cltsock_mgr:send_client(self.char_id, CMD_MAP_UPDATE_ITEM_S, data)
	return 0
end

--*********************流水***********************
--货币流水
function Bag_container:write_money_log(io, money_list, src_log)
	if not money_list or not src_log then
		return
	end
	local player = g_obj_mgr:get_obj(self.char_id)
	--元宝转积分
	if io == MONEY_IO.OUT and money_list[3] then
		local gm_char = player:get_gm_function_con()
		gm_char:add_integral(src_log.type, money_list[3])
	end

	local str
	local level = player and player:get_level() or 0
	for k,v in pairs(money_list) do
		if v>0 then
			str = string.format("insert log_money set char_id=%d, level=%d, char_name='%s', io=%d, type=%d, money_type=%d, left_num=%d, time=%d, money_num=%d",
							self.char_id, level, self.player_name, io,  src_log.type, k,  self.bag_size_list[k], os.time(), v)
			f_multi_web_sql(str)

			if k == MoneyType.BANK_GOLD then
				local new_io = (io==0 and 1 or 0)
				str = string.format("insert log_money set char_id=%d, level=%d, char_name='%s', io=%d, type=%d, money_type=%d, left_num=%d, time=%d, money_num=%d",
							self.char_id, level, self.player_name, new_io,  src_log.type, MoneyType.GOLD,  self.bag_size_list[MoneyType.GOLD], os.time(), v)
				f_multi_web_sql(str)
			end
		end
	end
	return 0
end

--物品流水(item_log 物品日志）
function Bag_container:write_item_log(item_log, src_log)
	if not src_log or not src_log.type then
		return
	end
	if src_log.type == ITEM_SOURCE.SORT_ITEM or src_log.type == ITEM_SOURCE.SWAP or src_log.type == ITEM_SOURCE.ENDURE 
		or src_log.EXAMINATION then
		return 
	end
	local op_type
	local execute = true
	local v = item_log
	
	if log_filter.item_log_filter[v.item_id] then
		return
	end

	local db_data = v.item:serialize_to_log()
	if v.op == ItemSyncFlag.ITEM_SYNC_ADD then
		op_type = 1
	elseif v.op == ItemSyncFlag.ITEM_SYNC_REMOVE then
		op_type = 0
	elseif v.op == ItemSyncFlag.ITEM_SYNC_UPDATE then
		if v.change_num == 0 then
			--数据无变化
			op_type = 2
			local dont_record = {
				[ITEM_SOURCE.SORT_ITEM] = true,
				[ITEM_SOURCE.SWAP] = true,
			}
			--没序列化数据
			if not db_data or next(db_data) == nil or dont_record[src_log.type] then
				execute = false
			end
		elseif v.change_num then
		    op_type = v.change_num<0 and 0 or 1
		else
			--没change_num，默认是跟新物品
			op_type = 2
			v.change_num = 0
		end
	end

	v.change_num = math.abs(v.change_num)
	if execute then
		local str = string.format("insert log_items set uuid ='%s'  ,char_id = %d, char_name='%s', item_name='%s', item_id=%d, item_num = %d, io=%d, type=%d, left_num=%d, time=%d, remark='%s'",
					v.uuid, self.char_id, self.player_name, v.item:get_name(),v.item_id, v.change_num,op_type, src_log.type, v.number, os.time(),  Json.Encode(db_data))
		f_multi_web_sql(str)
	end
	return 0
end



--**************数据库操作*****************

--对character_item表的操作
--更新插入删除物品
function Bag_container:db_item_operation(log_list, src_log)
	if not log_list then
		return
	end

	for k,v in pairs(log_list) do
		self:write_item_log(v, src_log)
	end

	local _, bag = self:get_bag(SYSTEM_BAG)
	bag.update_flags = true

	return 0
end

--查找char_id用户bag_id包中的物品
function Bag_container:db_load_item(bag_id)
	local dbh = f_get_db()
	local condition = string.format("{char_id:%d,bag:%d}", self.char_id, bag_id)
	--return dbh:select("character_item", nil, condition, nil, 0, 0, "{char_id:1,bag:1}")
	return dbh:select_one("character_item", nil, condition, nil)
end

--整个背包入库操作,flags则都入库，否则检查标识位存在才入库
function Bag_container:serialize(flags)
	--local usec_1,sec_1 = crypto.timeofday()

	local record = {}
	local dbh = f_get_db()
	for bag_id, bag_o in pairs(self.bag_list) do
		if flags or bag_o.update_flags then
			local condition = string.format("{char_id:%d,bag:%d}", self.char_id,bag_id)
			record.size = bag_o:get_size()
			record.item_l = bag_o:db_get_bag_all_log()
			record.attribute = bag_o:db_get_bag_attribute()

			dbh:update("character_item", condition, Json.Encode(record), true)

			--存完后标识字段去掉
			bag_o.update_flags = false
		end
	end

	--[[local usec_2,sec_2 = crypto.timeofday()
	local temp =  math.floor(((sec_2+usec_2)-(sec_1+usec_1))*1000000)
	print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Bag_container:serialize", temp)]]
end


-------------------------------------------------对character_bag表的操作
--根据char_id查找用户背包信息
function Bag_container:db_load_bag()
	local dbh = f_get_db()
	local condition = string.format("{char_id:%d}", self.char_id)
	return dbh:select_one("character_bag", nil, condition, nil, "{char_id:1}")
end


--跟新character_bag中的char_data
function Bag_container:db_update_char_data()
	local dbh = f_get_db()
	local condition = string.format("{char_id:%d}", self.char_id)
	local record = {}
	record.char_data = self.bag_size_list
	record.char_id = self.char_id
	return dbh:update("character_bag", condition, Json.Encode(record), true)
end


--*******************管理背包*******************
--加载背包，db_human调用
--flag==true,加载新手礼包
function Bag_container:db_load( flag )
	local info, e_code
	if not flag then
		info, e_code = self:db_load_bag()
		if e_code ~= 0 then
			return e_code
		end
	end

	if info then
		for k, v in pairs(info.char_data) do
			self.bag_size_list[k] = v
		end
	end

	if flag then
		--新手礼包
		--local _, bag = self:get_bag(SYSTEM_BAG)
		--local player = g_obj_mgr:get_obj(self.char_id)
		--local ty = player:get_occ()
		--local item_id = '104000' .. string.sub(ty,1,1) .. '00120'
		--local item_list = {{['type']=1, ['number']=1, ['item_id']=tonumber(item_id)}}
		--
		--local e_code, log_list = bag:create_item_list(item_list)
		--if e_code~=0 then
			--print("Error:Bag_container:db_load:", item_id)
			--return e_code
		--end
		local log_list = {}

		--时装
		local _,bag = self:get_bag(EQUIPMENT_BAG)
		local player = g_obj_mgr:get_obj(self.char_id)
		local sex = player:get_sex()
		local item_id = tonumber("50012" .. sex .. "000520")
		local e_code,item = Item_factory.create(item_id)
		if e_code ~= 0 then
			print("Error:Bag_container:db_load:", item_id)
			return e_code
		end
		item:set_last_time(3)
		item:on_wear()
		local log = bag:add_item_to_slot(EQUIPMENT_SLOT_OUTLOOK, 1, item)
		table.insert(log_list, log)

		local src_log = {['type']=ITEM_SOURCE.SYSTEM_SEND}
		self:db_item_operation(log_list, src_log)
	end
	return 0
end


--获取背包,第一次获取的时候从数据库加载物品
function Bag_container:get_bag(bag_id)
	if not self.bag_list[bag_id] then
		local bag_template = get_bag_template()
		if not bag_template[bag_id] then
			return E_NO_BAG_TEMPLATE
		end
		self.bag_list[bag_id] = bag_template[bag_id](self.char_id,self)
		local dbh = f_get_db()
		local condition = string.format("{char_id:%d,bag:%d}", self.char_id, bag_id)
		local db_items = dbh:select_one("character_item", nil, condition, nil)
		
		if db_items then   --设置背包size
			local size = db_items and db_items.size
			self.bag_list[bag_id]:set_size(size)

			for k,v in pairs(db_items.item_l or {}) do
				local e_code, item = Item_factory.clone(v[3], v[5])
				if e_code~=0 then
					--return e_code
				else
					self.bag_list[bag_id]:load_grid(v[1],v[2],v[4],item)
				end
			end

			self.bag_list[bag_id].attribute = db_items.attribute

			if bag_id == EQUIPSEAL_BAG then
				self:count_seal_fighting()
			end
		end
	end

	return 0, self.bag_list[bag_id]
end

--开格，改变大小，并且入库
function Bag_container:expand_bag(bag_id)
	if not bag_id or 
		bag_id == MONSTER_BAG or 
		not self.bag_list[bag_id] or not DB_BAG_LIST[bag_id] then
		return E_INVALID_PARAMETER
	end
	local e_code, bag = self:get_bag(bag_id)
	if e_code ~= 0 then
		return e_code
	end
	e_code = bag:expand_size()
	if e_code == 0 then
		local args = {}
		args.bag_id = bag_id
		args.slot 	= bag:get_size()
		g_event_mgr:notify_event(EVENT_SET.EVENT_ADD_BAG_SLOT, self.char_id, args)
	end
	return e_code
end

--检查物品UUID是否被锁
function Bag_container:check_item_lock_by_item_uuid(bag, uuid)
	local grid = self:get_item_by_uuid(uuid, bag)
	if not grid or not grid.item then
		return false
	end
	local player = g_obj_mgr:get_obj(self.char_id)
	local lock = player:get_protect_lock()
	if not lock then return true end

	if lock:check_lock_item(grid.item) then return true end

	return false
end

--检查物品ID是否被锁
function Bag_container:check_item_lock_by_item_id(item_id)
	local player = g_obj_mgr:get_obj(self.char_id)
	local lock = player:get_protect_lock()
	if not lock then return true end

	local e_code , item = Item_factory.create(item_id)
	if e_code~=0 then return e_code end
	if lock:check_lock_item(item) then return true end

	return false
end

--检查物品是否被锁
function Bag_container:check_item_lock_by_item(item)
	local player = g_obj_mgr:get_obj(self.char_id)
	local lock = player:get_protect_lock()
	if not lock then return true end

	if lock:check_lock_item(item) then return true end

	return false
end

--检查背包格物品是否被锁
function Bag_container:check_item_lock_by_bag_slot(bag,slot)
	local player = g_obj_mgr:get_obj(self.char_id)
	local lock = player:get_protect_lock()
	if not lock then return true end

	local grid = self:get_item_by_bag_slot(bag,slot)
	if not grid or not grid.item then
		return E_INVALID_PARAMETER
	end
	if lock:check_lock_item(grid.item) then return true end

	return false
end

--计算封灵装备总战斗力
function Bag_container:count_seal_fighting()
	local e_code , bag = self:get_bag(EQUIPSEAL_BAG)
	if e_code ~= 0 then return end
	local fight = 0
	for i = 1, bag:get_size() do
		if bag:get_grid(i) then
			fight = fight + ( bag:get_grid(i).item:get_fighting() or 0 )
		end
	end
	bag:set_fighting(fight)
end


--移动物品
-- src_bag 原背包id ，src_slot原背包格子 ，dst_bag 目标背包id，dst_slot目标背包格子
function Bag_container:swap(src_bag, src_slot, dst_bag, dst_slot, no_src)
	local e_code, src_bag_ctn, dst_bag_ctn, src_grid, dst_grid
	local player = g_obj_mgr:get_obj(self.char_id)
	local lock = player:get_protect_lock()
	if not lock then return end

	if src_bag == EQUIPMENT_BAG and src_slot == EQUIPMENT_SLOT_OUTLOOK then
		return self:update_client(E_EPT_PARAMETER)
	end
	--源背包
	if not src_bag or not src_slot or not dst_bag then
		return self:update_client(E_EPT_PARAMETER)
	end

	e_code , src_bag_ctn = self:get_bag(src_bag)
	if e_code ~= 0 then
		return self:update_client(e_code)
	end

	src_grid = src_bag_ctn:get_grid(src_slot)
	if not src_grid then
		return self:update_client(E_INVALID_PARAMETER)
	end

	if lock:check_lock_item(src_grid.item) then return end

	e_code , dst_bag_ctn = self:get_bag(dst_bag)
	if e_code ~= 0 then
		return self:update_client(e_code)
	end

	--获取默认位置
	if not dst_slot or dst_slot== 0 then
		e_code , dst_slot = dst_bag_ctn:get_default(src_bag, src_slot, dst_bag, dst_slot)
		if e_code~= 0 then
			return self:update_client(e_code)
		end
		if dst_bag == EQUIPSEAL_BAG then
			if not equip_seal.get_relative_solt(dst_slot) then
				return
			end
			dst_slot = equip_seal.get_relative_solt(dst_slot)
		end
	end

	--判断能否进入
	e_code = dst_bag_ctn:can_enter(src_grid.item, src_bag, src_slot, dst_bag, dst_slot)
	if e_code ~= 0 then
		return self:update_client(e_code)
	end

	dst_grid = dst_bag_ctn:get_grid(dst_slot)
	if dst_grid then
		if lock:check_lock_item(dst_grid.item) then return end
		e_code = src_bag_ctn:can_enter(dst_grid.item, dst_bag, dst_slot, src_bag, src_slot)
		if e_code ~= 0 then
			return self:update_client(e_code)
		end
	end

	if dst_slot > dst_bag_ctn.bag_size then
		return self:update_client(E_INVALID_PARAMETER)
	end

	local log_list = {}
	local tmp_log, src_type
	if not dst_grid then  --目标为空,直接移动
		src_bag_ctn:erase_grid(src_slot)
		e_code, log_list = dst_bag_ctn:set_grid(dst_slot, src_grid.uuid, src_grid.number, src_grid.item)
		if e_code~=0 then
			return self:update_client(e_code)
		end

		if src_bag == STALL_BAG then
			log_list[1].src_uuid = nil
		else
			log_list[1].src_uuid = log_list[1].uuid
		end

		if dst_bag == EQUIPMENT_BAG  or dst_bag == EQUIPSEAL_BAG then
			src_grid.item:set_bind()
			log_list[1].no_src = 1
		end

		if dst_bag == EQUIPMENT_BAG and src_grid.item:is_fashion() == false then
			src_grid.item:change_hole_bind()
		end
	else
		--判断是合并还是交换
		--[[local exchange = true
		if src_grid.item_id == dst_grid.item_id and dst_grid.item:get_stk_num() ~= 1 then
			exchange = false
		end]]
		if not (src_grid.item_id == dst_grid.item_id and dst_grid.item:get_stk_num() ~= 1) then --交换
		--if exchange then
			local tmp_uuid, tmp_number, tmp_item = src_grid.uuid, src_grid.number, src_grid.item
			e_code ,tmp_log = src_bag_ctn:set_grid(src_slot, dst_grid.uuid, dst_grid.number, dst_grid.item)
			if e_code~=0 then
				return self:update_client(e_code)
			end

			log_list[1] = tmp_log[1]
			log_list[1].src_uuid = log_list[1].uuid

			e_code ,tmp_log = dst_bag_ctn:set_grid(dst_slot, tmp_uuid, tmp_number, tmp_item)
			if e_code~=0 then
				return self:update_client(e_code)
			end

			log_list[2] = tmp_log[1]
			log_list[2].src_uuid = log_list[2].uuid

			if dst_bag == EQUIPMENT_BAG or dst_bag == EQUIPSEAL_BAG then
				src_grid.item:set_bind()
				log_list[2].no_src = 1
				log_list[1].no_src = 1
			end

			if dst_bag == EQUIPMENT_BAG and src_grid.item:is_fashion() == false then
				src_grid.item:change_hole_bind()
			end
		else   --合并
			local stk_num = dst_grid.item:get_stk_num()
			if stk_num >= dst_grid.number then
				return self:update_client(0)
			else
				local space = stk_num - dst_grid.number
				if space >= src_grid.number then  --删除
					e_code, tmp_log = src_bag_ctn:del_item_by_slot(src_slot)
					if e_code~=0 then
						return self:update_client(e_code)
					end

					log_list[1] = tmp_log[1]
					log_list[1].src_uuid = log_list[1].uuid

					e_code, tmp_log = dst_bag_ctn:set_grid(dst_slot, dst_grid.uuid, dst_grid.number + src_grid.number, dst_grid.item)
					if e_code~=0 then
						return self:update_client(e_code)
					end
					log_list[2] = tmp_log[1]
					log_list[2].src_uuid = log_list[2].uuid
				else
					if dst_bag_ctn == src_bag_ctn then
						e_code, tmp_log = dst_bag_ctn:set_grid(src_slot, src_grid.uuid, src_grid.number - space, src_grid.item)
						if e_code~=0 then
							return self:update_client(e_code)
						end

						log_list[1] = tmp_log[1]
						log_list[1].src_uuid = log_list[1].uuid

						e_code, tmp_log = dst_bag_ctn:set_grid(dst_slot, dst_grid.uuid, dst_grid.number + space, dst_grid.item)
						if e_code~=0 then
							return self:update_client(e_code)
						end
						log_list[2] = tmp_log[1]
						log_list[2].src_uuid = log_list[2].uuid
					else
						return self:update_client(0)
					end
				end
			end
		end
	end

	src_type = {['type'] = ITEM_SOURCE.SWAP}
	self:inform_change(src_bag, src_slot, dst_bag, dst_slot)
	self:update_client(0, log_list, src_type)
	
	return 0
end


--移动物品时调用，例如移动到装备背包中和坐骑背包中
function Bag_container:inform_change(src_bag, src_slot, dst_bag, dst_slot)
-----------------------------------------------------------除坐骑包，其他所有包内交换屏蔽
	if dst_bag == src_bag and src_bag ~= MOUNTS_BAG then
		return
	end

	local e_code, d_bag = self:get_bag(dst_bag)
	if e_code ~= 0 then
		return e_code
	end
	local dst_grid = d_bag:get_item_by_slot(dst_slot)

	local e_code, s_bag = self:get_bag(src_bag)
	if e_code ~= 0 then
		return e_code
	end
	--local src_grid = s_bag:get_item_by_slot(src_slot)
------------------------------------------------------------装备栏判断	
	if dst_bag == EQUIPMENT_BAG or dst_bag == EQUIPSEAL_BAG then
		--变绑定
		--dst_grid.item:set_bind()
		
		local s_log_list = {}
		local d_log_list = {}
		local tmp_item = s_bag.slot_list[src_slot] and s_bag.slot_list[src_slot].item
		if tmp_item then
			s_log_list[1] = s_bag:get_update_log(ItemSyncFlag.ITEM_SYNC_UPDATE, src_slot)
		end
		d_log_list[1] = d_bag:get_update_log(ItemSyncFlag.ITEM_SYNC_UPDATE, dst_slot)			
		local src_log = {['type']=ITEM_SOURCE.PUT_OFF}
		local dst_log = {['type']=ITEM_SOURCE.PUT_ON}

		self:db_item_operation(s_log_list, src_log)
		self:db_item_operation(d_log_list, dst_log)

		local args = {}
		args.item = d_bag.slot_list[dst_slot] and d_bag.slot_list[dst_slot].item
		if args.item then
			g_event_mgr:notify_event(EVENT_SET.EVENT_USE_ITEM, self.char_id, args)
			g_event_mgr:notify_event(EVENT_SET.EVENT_ARM_EQUIPMENT, self.char_id, args)
		end

		local player = g_obj_mgr:get_obj(self.char_id)

		if dst_bag == EQUIPSEAL_BAG then
			self:count_seal_fighting()
			player:on_dress_update(21)
		else	
			player:on_change_equip(dst_slot)
		end		
	end
	if src_bag == EQUIPMENT_BAG or src_bag == EQUIPSEAL_BAG then
	
		local s_log_list = {}
		local d_log_list = {}
		local tmp_item = s_bag.slot_list[src_slot] and s_bag.slot_list[src_slot].item
		if tmp_item then
			s_log_list[1] = s_bag:get_update_log(ItemSyncFlag.ITEM_SYNC_UPDATE, src_slot)
		end
		d_log_list[1] = d_bag:get_update_log(ItemSyncFlag.ITEM_SYNC_UPDATE, dst_slot)	
		local src_log = {['type']=ITEM_SOURCE.PUT_OFF}
		local dst_log = {['type']=ITEM_SOURCE.PUT_ON}

		self:db_item_operation(s_log_list, dst_log)
		self:db_item_operation(d_log_list, src_log)

		local player = g_obj_mgr:get_obj(self.char_id)
		
		if src_bag == EQUIPSEAL_BAG then
			self:count_seal_fighting()
			player:on_dress_update(21)
		else	
			player:on_change_equip(src_slot)	
		end		
	end
------------------------------------------------------------------坐骑判断
	--进入坐骑面板
	if dst_bag == MOUNTS_BAG then
		local player = g_obj_mgr:get_obj(self.char_id)
		player:on_change_ride(dst_slot)
		g_event_mgr:notify_event(EVENT_SET.EVENT_ADD_RIDE, self.char_id, {['item'] = (d_bag.slot_list and d_bag.slot_list[dst_slot] and d_bag.slot_list[dst_slot].item)})
		if MOUNTS_SLOT_MAIN == dst_slot then
			local log_list = {}
			log_list[1] = d_bag:get_update_log(ItemSyncFlag.ITEM_SYNC_UPDATE, dst_slot)
			local args = {}
			args.item = d_bag.slot_list[dst_slot] and d_bag.slot_list[dst_slot].item
			if args.item then
				g_event_mgr:notify_event(EVENT_SET.EVENT_USE_ITEM, self.char_id, args)
			end
			g_event_mgr:notify_event(EVENT_SET.EVENT_USE_ITEM, self.char_id, args)

			--f_use_item_trigger_complete(self.char_id, log_list[1].item_id)
		end
	end

	--退出坐骑面板
	if src_bag == MOUNTS_BAG then
		local player = g_obj_mgr:get_obj(self.char_id)
		player:on_change_ride(src_slot)

	end
---------------------------------------------------------------屏蔽掉相同包内交换（原来逻辑）
	if src_bag == dst_bag then
		return
	end
---------------------------------------------------------------仓库判断
	if src_bag == BANK_BAG then
		local s_log_list = {}
		local d_log_list = {}
		local tmp_item = d_bag.slot_list[dst_slot] and d_bag.slot_list[dst_slot].item
		if tmp_item then
			d_log_list[1] = d_bag:get_update_log(ItemSyncFlag.ITEM_SYNC_UPDATE, dst_slot)	
		end
		tmp_item = s_bag.slot_list[src_slot] and s_bag.slot_list[src_slot].item
		if tmp_item then
			s_log_list[1] = s_bag:get_update_log(ItemSyncFlag.ITEM_SYNC_UPDATE, src_slot)
		end
		local src_log = {['type']=ITEM_SOURCE.GET_FROM_BANK}
		local dst_log = {['type']=ITEM_SOURCE.SAVE_IN_BANK}

		--print("log_list = %s; src_log = %s",log_list,src_log)
		self:db_item_operation(s_log_list, dst_log)
		self:db_item_operation(d_log_list, src_log)
	end

	if dst_bag == BANK_BAG then
		local s_log_list = {}
		local d_log_list = {}
		local tmp_item = d_bag.slot_list[dst_slot] and d_bag.slot_list[dst_slot].item
		if tmp_item then
			d_log_list[1] = d_bag:get_update_log(ItemSyncFlag.ITEM_SYNC_UPDATE, dst_slot)	
		end
		tmp_item = s_bag.slot_list[src_slot] and s_bag.slot_list[src_slot].item
		if tmp_item then
			s_log_list[1] = s_bag:get_update_log(ItemSyncFlag.ITEM_SYNC_UPDATE, src_slot)
		end	
		local src_log = {['type']=ITEM_SOURCE.GET_FROM_BANK}
		local dst_log = {['type']=ITEM_SOURCE.SAVE_IN_BANK}

		--print("log_list = %s; src_log = %s",log_list,src_log)
		self:db_item_operation(s_log_list, src_log)
		self:db_item_operation(d_log_list, dst_log)
	end
---------------------------------------------------------------降妖仓库判断
	if src_bag == MONSTER_BAG then
		local s_log_list = {}
		local d_log_list = {}
		local tmp_item = d_bag.slot_list[dst_slot] and d_bag.slot_list[dst_slot].item
		if tmp_item then
			d_log_list[1] = d_bag:get_update_log(ItemSyncFlag.ITEM_SYNC_UPDATE, dst_slot)	
		end
		local src_log = {['type']=ITEM_SOURCE.CHEST_TO_BAG}

		self:db_item_operation(d_log_list, src_log)
	end

---------------------------------------------------------------庄园仓库判断
	if src_bag == HOME_BAG then
		local s_log_list = {}
		local d_log_list = {}
		local tmp_item = d_bag.slot_list[dst_slot] and d_bag.slot_list[dst_slot].item
		if tmp_item then
			d_log_list[1] = d_bag:get_update_log(ItemSyncFlag.ITEM_SYNC_UPDATE, dst_slot)	
		end
		local src_log = {['type']=ITEM_SOURCE.HOME_TO_BAG}

		self:db_item_operation(d_log_list, src_log)
	end

---------------------------------------------------------------------------------进出背包
	if src_bag == SYSTEM_BAG then
		local d_tmp_item = d_bag.slot_list[dst_slot] and d_bag.slot_list[dst_slot].item
		local s_tmp_item = s_bag.slot_list[src_slot] and s_bag.slot_list[src_slot].item
		local args = {}
		if d_tmp_item then  --出背包
			args.item_id = d_bag.slot_list[dst_slot].item_id
			args.slot 	 = d_bag.slot_list[dst_slot] 
			g_event_mgr:notify_event(EVENT_SET.EVENT_DEL_ITEM, self.char_id, args)
		end
		if s_tmp_item then  --进背包
			args.item_id = s_bag.slot_list[src_slot].item_id
			args.slot	 = s_bag.slot_list[src_slot]
			g_event_mgr:notify_event(EVENT_SET.EVENT_ADD_ITEM, self.char_id, args)
		end
	end

	if dst_bag == SYSTEM_BAG then
		local d_tmp_item = d_bag.slot_list[dst_slot] and d_bag.slot_list[dst_slot].item
		local s_tmp_item = s_bag.slot_list[src_slot] and s_bag.slot_list[src_slot].item
		local args = {}
		if d_tmp_item then  --进背包
			args.item_id = d_bag.slot_list[dst_slot].item_id
			args.slot	 = d_bag.slot_list[dst_slot]
			g_event_mgr:notify_event(EVENT_SET.EVENT_ADD_ITEM, self.char_id, args)
		end
		if s_tmp_item then  --出背包
			args.item_id = s_bag.slot_list[src_slot].item_id
			args.slot 	 = s_bag.slot_list[src_slot]
			g_event_mgr:notify_event(EVENT_SET.EVENT_DEL_ITEM, self.char_id, args)
		end
	end
end



-----------------------------------------------------------------外部调用接口-------------------------------------------------------------------------------------

--获取背包信息
function Bag_container:get_bag_info(bag_id)
	if not bag_id then
		return nil
	end
	local e_code, bag = self:get_bag(bag_id)
	if e_code~=0 then
		return nil
	end
	return bag:get_bag_info()
end

--增加一个物品，item为Item_factory.create生成的东西
function Bag_container:add_by_item(item,src_log)

	local e_code, bag = self:get_bag(SYSTEM_BAG)
	local item_list = {{['type']=2, ['number']=1, ['item']=item}}
	local log_list
	e_code,log_list = bag:create_item_list(item_list)
	if e_code ~= 0 then
		return e_code
	end

	self:db_item_operation(log_list,src_log)
	self:update_client(0, log_list,src_log)
	return 0
end



--批量插入物品
--[[
item_list的格式
item_list={
	{['type']=1,['item_id']=, ['number']=2},
	{['type']=2,['item']=item, ['number'] =5}
}
--]]
--bag_id默认为基本背包
function Bag_container:add_item_l(item_list, src_log, bag_id)
	bag_id = bag_id or SYSTEM_BAG
	local e_code, bag = self:get_bag(bag_id)
	if e_code ~= 0 then
		return e_code
	end
	local log_list
	e_code,log_list = bag:create_item_list(item_list)
	if e_code ~= 0 then
		return e_code
	end
	self:db_item_operation(log_list,src_log)
	self:update_client(0, log_list,src_log)	
	return 0
end


--根据bag,slot获取物品
function Bag_container:get_item_by_bag_slot(bag,slot)
	local e_code, ctn = self:get_bag(bag)
	if e_code ~= 0 then
		self:update_client(e_code)
		return nil
	end
	return ctn:get_grid(slot)
end



--使用物品
function Bag_container:use_item(target,  grid , param_l)
	local e_code, ctn, log_list
	e_code, ctn = self:get_bag(SYSTEM_BAG)
	if e_code ~= 0 then
		return e_code
	end
	e_code, log_list = ctn:use_item(target, grid.slot, param_l)
	if e_code ~= 0 then
		return e_code
	end
	local src_log = {['type']=ITEM_SOURCE.USE_ITEM}
	self:db_item_operation(log_list,src_log)
	self:update_client(0, log_list,src_log)
	return 0
end


--拆分
function Bag_container:split_item(bag, slot, count)
	if self:check_item_lock_by_bag_slot(bag,slot) then
		return
	end
	local e_code, ctn = self:get_bag(bag)
	if e_code ~= 0 then
		return self:update_client(e_code)
	end
	local log_list
	e_code, log_list = ctn:split_item(slot, count)
	if e_code ~= 0 then
		return self:update_client(e_code)
	end
	local src_log = {['type']=ITEM_SOURCE.SPLIT}
	--self:db_item_operation(log_list, src_log)
	self:update_client(0, log_list, src_log)
	return 0
end


--背包整理
function Bag_container:sort_item(bag_id)
	local valid_sort_bag = {
		[19] = true,
		[20] = true,
		[21] = true
	}
	if not valid_sort_bag[bag_id] then
		return -1
	end
	local e_code, bag = self:get_bag(bag_id)
	local log_list
	e_code,log_list = bag:sort_item()
	local src_log = {['type']=ITEM_SOURCE.SORT_ITEM}
	--self:db_item_operation(log_list,src_log)
	return self:update_client(e_code, log_list, src_log)
end


--获取背包里面的所有物品
function Bag_container:get_equipseal()
	local e_code, bag = self:get_bag(EQUIPSEAL_BAG)
	if e_code~=0 then
		print('errrrrrrrrrrrrrrrrrrrrrrrrrror : ',e_code)
		return {}
	end
	local ret = {}
	local pnt = 0
	local have = false
	for i = bag:get_bag_start(), bag:get_size() do
		local equip = bag:get_grid(i)
		if equip then
			have = true
			pnt = pnt + 1
			ret[pnt] = equip
		end
	end
	if not have then
		return {}
	else
		return ret
	end
end

--获取背包里面的所有物品
function Bag_container:get_equip()
	local e_code, bag = self:get_bag(EQUIPMENT_BAG)
	if e_code~=0 then
		print('errrrrrrrrrrrrrrrrrrrrrrrrrror : ',e_code)
		return {}
	end
	local ret = {}
	local pnt = 0
	local have = false
	for i = bag:get_bag_start(), bag:get_size() do
		local equip = bag:get_grid(i)
		if equip then
			have = true
			pnt = pnt + 1
			ret[pnt] = equip
		end
	end

	if not have then
		return {}
	else
		return ret
	end
	
end

--获取背包里面的所有物品
function Bag_container:get_equip_ex()
	local e_code, bag = self:get_bag(EQUIPMENT_BAG)
	if e_code~=0 then
		print('errrrrrrrrrrrrrrrrrrrrrrrrrror : ',e_code)
		return {}
	end
	local ret = {}
	local pnt = 0
	local have = false
	local item_info 
	for i = bag:get_bag_start(), bag:get_size() do
		--if self.slot_list[i] then
			--item_info = {}
			--item_info[1] = self.slot_list[i].uuid
			--item_info[2] = nil  --映射源
			--item_info[3] = self.bag_id
			--item_info[4] = i
			--item_info[5] = self.slot_list[i].number
			--item_info[6] = self.slot_list[i].item:serialize_to_net()
			--item_info[7] = nil  --来源
			--cnt = cnt + 1
			--info[3][cnt] = item_info
		--end
		local equip = bag:get_grid(i)
		if equip then
			have = true
			item_info = {}
			item_info[1] = equip.uuid
			item_info[2] = nil  --映射源
			item_info[3] = bag.bag_id
			item_info[4] = i
			item_info[5] = equip.number
			item_info[6] = equip.item:serialize_to_net()
			item_info[7] = nil  --来源
			pnt = pnt + 1
			ret[pnt] = item_info
		end
	end

	if not have then
		return {}
	else
		return ret
	end
	
end


--获取坐骑列表
function Bag_container:get_ride()
	local e_code, bag = self:get_bag(MOUNTS_BAG)
	if e_code ~=0 then
		return e_code
	end
	local ride
	local ret = {}
	local pnt = 0
	for i = bag:get_bag_start(), bag:get_size() do
		ride = bag:get_grid(i)
		if ride then
			pnt = pnt + 1
			ret[pnt] = ride
		end
	end
	return ret
end

--根据item_id获取格子数
function Bag_container:get_slot_by_item_id(item_id)
	local e_code, bag = self:get_bag(SYSTEM_BAG)
	return  bag:get_slot_by_item_id(item_id)
end

--根据item_id获取物品的格对象
function Bag_container:get_item_by_item_id(item_id)
	local e_code, bag = self:get_bag(SYSTEM_BAG)
	return  bag:get_item_by_item_id(item_id)
end

--根据m_class获取所有物品对象
function Bag_container:get_all_item_by_m_class(param_l,m_class)
	local ret = {}
	for k,v in pairs(param_l or {}) do
		local e_code, bag = self:get_bag(v)
		local item_l = bag:get_all_item_by_m_class(m_class)
		for m,n in pairs(item_l or {})do
			table.insert(ret,n)
		end
	end
	return ret
end
--获取某类物品的个数
function Bag_container:get_item_count(item_id)
	local e_code, bag = self:get_bag(SYSTEM_BAG)
	if e_code ~=0 then
		return 0
	end
	local cnt = bag:get_cnt_by_item_id(item_id)
	return cnt
end

--忽略绑定非绑定，统计物品的个数
function Bag_container:get_all_item_count(item_id)
	local e_code , bag = self:get_bag(SYSTEM_BAG)
	local new_id
	if string.sub(item_id, -1, -1) == '1' then
		new_id = string.sub(item_id,0,-2) .. '0'
	else
		new_id = string.sub(item_id,0,-2) .. '1'
	end
	return self:get_item_count(item_id) + self:get_item_count(tonumber(new_id))
end

--忽略绑定非绑定，统计多个背包物品的个数
local exist_bag_list = {[1] = EQUIPMENT_BAG, [2] = MOUNTS_BAG, [3] = SYSTEM_BAG}
function Bag_container:check_item_have(item_id)
	local count = 0
	for k, v in pairs(exist_bag_list) do
		local e_code , bag = self:get_bag(v)
		local new_id
		if item_id % 2 == 1 then
			new_id = item_id - 1
		else
			new_id = item_id + 1
		end
		count = count + bag:get_cnt_by_item_id(item_id) +  bag:get_cnt_by_item_id(new_id)
	end
	return count
end

--根据uuid获取物品
function Bag_container:get_item_by_uuid(uuid, bag_id)
	if not bag_id then
		bag_id = SYSTEM_BAG
	end
	local e_code, bag = self:get_bag(bag_id)
	if e_code~=0 then 
		return nil
	end
	local grid =  bag:get_item_by_uuid(uuid)
	if not grid then
		return nil
	end
	return grid
end

--获取各种货币数量的列表
function Bag_container:get_money()
	local ret = {}
	ret.gold = self.bag_size_list[MoneyType.GOLD] or 0
	ret.gift_gold = self.bag_size_list[MoneyType.GIFT_GOLD] or 0
	ret.jade = self.bag_size_list[MoneyType.JADE] or 0
	ret.gift_jade = self.bag_size_list[MoneyType.GIFT_JADE] or 0
	ret.bank_gold = self.bag_size_list[MoneyType.BANK_GOLD] or 0
	--ret.back_ground = self.bag_size_list[MoneyType.BACK_GROUND] or 0
	ret.integral = self.bag_size_list[MoneyType.INTEGRAL] or 0
	ret.bonus = self.bag_size_list[MoneyType.BONUS] or 0
	ret.honor = self.bag_size_list[MoneyType.HONOR] or 0
	ret.glory = self.bag_size_list[MoneyType.GLORY] or 0
	return ret
end

--加钱
--money_list的格式
--[[
	money_list[MoneyType.GOLD] = **,
	money_list[MoneyType.GIFT_GOLD] = **,
	money_list[MoneyType.JADE] = **,
	money_list[MoneyType.GIFT_JADE] = **,
	money_list[MoneyType.BANK_GOLD] = **,
--]]

function Bag_container:add_money_l(money_list, src_log)
	if not money_list then
		return E_INVALID_PARAMETER
	end
	for k,v in pairs(MoneyType) do
		if money_list[v] and money_list[v]<0 then
			return E_INVALID_PARAMETER
		end
	end

	if money_list[MoneyType.BANK_GOLD]then
		if not self.bag_size_list[MoneyType.GOLD] or self.bag_size_list[MoneyType.GOLD] < money_list[MoneyType.BANK_GOLD] then
			return E_INVALID_PARAMETER
		end
	end

	for money_type,value in pairs(money_list) do
		if money_type > 10 then		--增加保护,随便返回一个错误码
			return E_INVALID_PARAMETER
		end
	end

	for money_type,value in pairs(money_list) do
		--银行存钱要扣背包钱
		if money_type == MoneyType.BANK_GOLD then
			self.bag_size_list[MoneyType.GOLD] = self.bag_size_list[MoneyType.GOLD] - value
		end
		self.bag_size_list[money_type] = self.bag_size_list[money_type] or 0
		self.bag_size_list[money_type] = self.bag_size_list[money_type] + value
	end
	self:db_update_char_data()
	self:update_clt_money()
	self:write_money_log(MONEY_IO.IN, money_list, src_log)
	--增加铜币时间通知
	if money_list[MoneyType.GOLD] or money_list[MoneyType.HONOR] then
		local args = {}
		if money_list[MoneyType.GOLD] then
			args.gold = self.bag_size_list[MoneyType.GOLD]
		end
		if money_list[MoneyType.HONOR] then
			args.honor = self.bag_size_list[MoneyType.HONOR]
			g_event_mgr:notify_event(EVENT_SET.EVENT_HONOUR_ADD, self.char_id, {count = money_list[MoneyType.HONOR] or 0})
		end	
		g_event_mgr:notify_event(EVENT_SET.EVENT_ADD_GOLD, self.char_id, args)
	end
	return 0
end


function Bag_container:add_money(money_type, value, src_log)
	return self:add_money_l({[money_type]=value},src_log)
end

--优先减铜卷，然后减铜币
function Bag_container:dec_gold_gift_and_gold(value, src_log)
	if self.bag_size_list[MoneyType.GIFT_GOLD] ==nil then
		self.bag_size_list[MoneyType.GIFT_GOLD] = 0
	end

	if self.bag_size_list[MoneyType.GOLD] == nil then
		self.bag_size_list[MoneyType.GOLD] = 0
	end
	if value < 0 or self.bag_size_list[MoneyType.GIFT_GOLD] + self.bag_size_list[MoneyType.GOLD] < value then
		return 27503
	end
	local money_list = {}
	if self.bag_size_list[MoneyType.GIFT_GOLD] > value then
		money_list[MoneyType.GIFT_GOLD]  =  value
	else
		money_list[MoneyType.GIFT_GOLD] = self.bag_size_list[MoneyType.GIFT_GOLD]
		money_list[MoneyType.GOLD] = value - self.bag_size_list[MoneyType.GIFT_GOLD]
	end
	return self:dec_money_l(money_list, src_log)
end

--减钱
function Bag_container:dec_money_l(money_list, src_log)
	if not money_list then
		return E_INVALID_PARAMETER
	end
	for k,v in pairs(MoneyType) do
		if money_list[v] and money_list[v]<0 then
			return E_INVALID_PARAMETER
		end
	end

	if money_list[MoneyType.BANK_GOLD]then
		if not self.bag_size_list[MoneyType.BANK_GOLD] or self.bag_size_list[MoneyType.BANK_GOLD] < money_list[MoneyType.BANK_GOLD] then
			return E_INVALID_PARAMETER
		end
	end

	for money_type,value in pairs(money_list) do
		--银行存钱要扣背包钱
		if money_type == MoneyType.BANK_GOLD then
			self.bag_size_list[MoneyType.GOLD] = self.bag_size_list[MoneyType.GOLD] + value
		end
		self.bag_size_list[money_type] = self.bag_size_list[money_type] or 0
		self.bag_size_list[money_type] = self.bag_size_list[money_type] - value
	end
	self:db_update_char_data()
	self:update_clt_money()
	self:write_money_log(MONEY_IO.OUT, money_list, src_log)
	return 0
end

--传入类型数字，1 ~ 9
function Bag_container:check_money_lock(number)
	local type
	if number == 1 then
		type = 'GOLD'
	elseif number == 2 then
		type = 'GOLD'
	elseif number == 3 then
		type = 'JADE'
	elseif number == 4 then
		type = 'GIFT_JADE'
	elseif number == 5 then
		type = 'BANK_GOLD'
	elseif number == 6 then
		type = 'INTEGRAL'
	elseif number == 7 then
		type = 'BONUS'
	elseif number == 8 then
		type = 'HONER'
	elseif number == 9 then			
		type = 'GLORY'
	end
	local player = g_obj_mgr:get_obj(self.char_id)
	if not player then
		return true
	end

	local lock_con = player:get_protect_lock()
	if not lock_con then
		return true
	end

	if lock_con:check_lock_money(type) then		
		g_cltsock_mgr:send_client(self.char_id, CMD_PROTECT_LOCK_NOTICE_LOCK_S, {})
		return true
	end
	return false
end

function Bag_container:dec_money(money_type, value, src_log)
	return self:dec_money_l({[money_type]=value},src_log)
end




function Bag_container:get_bag_free_slot_cnt(bag_id)
	bag_id = bag_id or SYSTEM_BAG
	local e_code, bag = self:get_bag(bag_id)
	local ept_cnt
	return bag:get_ept_cnt()
end



function Bag_container:del_item_by_uuid(bag, uuid ,count, src_log)
	local e_code, ctn = self:get_bag(bag)
	local change_list
	e_code,change_list = ctn:del_item_by_uuid(uuid, count)
	self:db_item_operation(change_list,src_log)
	self:update_client(0, change_list, src_log)
	return e_code
end



function Bag_container:del_item_by_bag_slot(bag, slot, count,src_log)
	local e_code, ctn = self:get_bag(bag)
	local change_list
	--local item_id = tonumber(ctn.slot_list[slot].item_id)
	e_code,change_list = ctn:del_item_by_slot(slot, count)
	self:db_item_operation(change_list, src_log)
	self:update_client(0, change_list, src_log)
	return e_code
end

--list:{bag,slot,count}, count_flag:nil 全部都删除，0，删除list里面指定count个数，其他就根据count_flag的个数来删
function Bag_container:del_item_by_bags_slots(list, src_log,count_flag)
	local ret = {}
	local e_code,ctn
	for k,v in pairs(list or {}) do
		local bag = v[1]
		local slot = v[2]
		local count
		if count_flag == nil then
		 	count = nil
		elseif count_flag == 0 then
			count = v[3]
		else
			count = count_flag
		end

		e_code, ctn = self:get_bag(bag)
		local change_list
		e_code,change_list = ctn:del_item_by_slot(slot, count)
		if e_code == 0  then
			table.insert(ret,change_list[1])
		end
	end
	self:db_item_operation(ret, src_log)
	self:update_client(0, ret, src_log)
	return e_code
end


function Bag_container:del_item_by_item_id(item_id, cnt, src_log)
	if not item_id or not cnt then
		return
	end
	local e_code, ctn = self:get_bag(SYSTEM_BAG)
	local change_list
	e_code,change_list = ctn:del_item_by_item_id(item_id, cnt)
	self:db_item_operation(change_list, src_log)
	self:update_client(0, change_list, src_log)
	return 0
end

function Bag_container:del_item_by_item_id_bind_first(item_id, cnt,src_log)
	if not item_id or not cnt then
		return
	end
	local e_code, ctn = self:get_bag(SYSTEM_BAG)
	local change_list, bind_ctn
	e_code,change_list,bind_ctn = ctn:del_item_by_item_id_bind_first(item_id, cnt)
	if e_code==0 then
		self:db_item_operation(change_list, src_log)
		self:update_client(0, change_list, src_log)
	end
	return e_code, bind_ctn
end

--获取技能书格对象
function Bag_container:get_skill_book_item(skill_id)
	local e_code, bag = self:get_bag(SYSTEM_BAG)
	if e_code ~= 0 then
		return nil
	end
	local grid, item_skill_id
	for i = bag:get_bag_start(), bag:get_size() do
		grid = bag:get_grid(i)
		if grid then
			item_skill_id = grid.item:get_skill()
			if item_skill_id == skill_id then
				return grid
			end
		end	
	end
	return nil
end



--更新一个物品
function Bag_container:update_grid(grid_list, src_log)
	if not grid_list then
		return -1
	end

	--for k,v in pairs(grid_list) do
		--v.src_uuid = nil
		--v.op = ItemSyncFlag.ITEM_SYNC_UPDATE
		--self:db_item_operation({v}, src_log)
		--self:update_client(0, {v}, src_log)
		--v.op = nil
	--end
	for k,v in pairs(grid_list) do
		v.src_uuid = nil
		v.op = ItemSyncFlag.ITEM_SYNC_UPDATE
	end
	
	self:db_item_operation(grid_list, src_log)
	self:update_client(0, grid_list, src_log)
	
	for k,v in pairs(grid_list) do
		v.op = nil
	end

	return 0
end

--更新装备,传进来的都是装备格子信息
function Bag_container:on_update_equip(equip_list, edure_type)
	local tmp_table = {}
	for k, v in pairs(equip_list) do
		--if v.slot then
			--equip_item = self:get_item_by_bag_slot(EQUIPMENT_BAG, v.slot)
		--end
		if v.item and not v.item:is_fashion() then
			local endure_temp = v.item.cur_endure
			local endure_cur
			if edure_type == EndureType.COMBAT_ENDURE then
				endure_cur = v.item:combat_dec_endure()
			elseif edure_type == EndureType.DEAD_ENDURE then
				endure_cur = v.item:dead_dec_endure()
			elseif edure_type == EndureType.FIX_ENDURE then
				endure_cur = v.item:fix_equip_dec_endure()
			end
			if endure_cur and endure_cur ~= endure_temp and 
				ev.time - v.item.update_time > endure_time then --耐久有变化且超更新时间时才更新
				table.insert(tmp_table, v)
				--local e_code, bag = self:get_bag(v.bag)
				--if e_code==0 then
					--self:update_grid({v}, {['type']=ITEM_SOURCE.ENDURE})
				--end
				--耐久降为0,重新计算角色面板属性
				if endure_cur == 0 then
					local player = g_obj_mgr:get_obj(self.char_id)
					player:on_change_equip(v.slot)
				end
			end
		end
	end
	if tmp_table[1] then
		local e_code, bag = self:get_bag(EQUIPMENT_BAG)
		if e_code==0 then
			self:update_grid(tmp_table, {['type']=ITEM_SOURCE.ENDURE})
		end
	end
end

--装备洗练
function Bag_container:reset_equip(grid, flag, count, idx_table)
	if not grid then return 43001 end
	local e_code 
	if flag == 1 then
		e_code =  equip_random_append_interface(grid.item, count, idx_table)
	elseif flag == 2 then
		--e_code = equip_random_value_interface(grid.item, count)
	end
	if e_code == 0 then
		self:update_grid({grid},{['type']=ITEM_SOURCE.EQUIP_RANDOM})
	end
	return e_code
end

--强化装备
function Bag_container:intensify_equip(grid)
	if not grid then return 43001 end
	local e_code = grid.item:intensify_equip()
	if e_code==0 then
		self:update_grid({grid},{['type']=ITEM_SOURCE.INTENSIFY})
	end
	return e_code
end


--装备回落
function Bag_container:degenerate_equip(grid)
	if not grid then return 43001 end
	local e_code = grid.item:degenerate_equip()
	if e_code==0 then
		self:update_grid({grid},{['type']=ITEM_SOURCE.INTENSIFY})
	end
	return e_code
end


--装备打孔
function Bag_container:drill_equip(grid)
	if not grid then return 43001 end
	local e_code = grid.item:drill_equip()
	if e_code==0 then
		self:update_grid({grid},{['type']=ITEM_SOURCE.DRILL})
	end
	return e_code
end

--装备附灵打孔
function Bag_container:rage_drill_equip(grid)
	if not grid then return 43001 end
	local e_code = grid.item:rage_drill_equip()
	if e_code==0 then
		self:update_grid({grid},{['type']=ITEM_SOURCE.RAGE_DRILL})
	end
	return e_code
end

--装备镶嵌
--gem_list 为  embed_slot - item_id 对
function Bag_container:embed_equip(grid, gem_list)
	if not grid or not gem_list then 
		return 43001 
	end
	local e_code = grid.item:embed_equip(gem_list)
	if e_code==0 then
		self:update_grid({grid},{['type']=ITEM_SOURCE.EMBED})
	end
	return e_code
end

--装备附灵镶嵌
function Bag_container:rage_embed_equip(grid, gem)
	if not grid or not gem then 
		return 43001 
	end
	local e_code = grid.item:rage_embed_equip(gem)
	if e_code==0 then
		self:update_grid({grid},{['type']=ITEM_SOURCE.RAGEEMBED})
	end
	return e_code
end


--装备拆卸
function Bag_container:dis_embed_equip(grid, embed_slot)
	if not grid or not embed_slot then 
		return 43001 
	end
	local e_code = grid.item:dis_embed_equip(embed_slot)
	if e_code ==0 then
		self:update_grid({grid},{['type']=ITEM_SOURCE.STRIP})
	end
	return e_code
end

--装备所有拆卸
function Bag_container:dis_all_embed_equip(grid, embed_list)
	if not grid then 
		return 43001 
	end
	local e_code = grid.item:dis_all_embed_equip(embed_list)
	if e_code ==0 then
		self:update_grid({grid},{['type']=ITEM_SOURCE.STRIP})
	end
	return e_code
end

--装备附灵拆卸
function Bag_container:dis_rage_embed_equip(grid)
	if not grid then 
		return 43001 
	end
	local e_code = grid.item:dis_rage_embed_equip()
	if e_code ==0 then
		self:update_grid({grid},{['type']=ITEM_SOURCE.RAGE_STRIP})
	end
	return e_code
end

--装备修复
function Bag_container:get_repair_cost()
	local  equip_l = self:get_equip()
	local sum = 0
	if equip_l then
		for k,v in pairs(equip_l) do
			sum = sum + v.item:get_repair_cost()
		end
	end
	return sum
end

--修复装备
function Bag_container:repair_equip(equip_l)
	if equip_l then
		for k,v in pairs(equip_l) do
			if not v.item:is_fashion() then
				v.item:repair()
				--self:update_grid({v}, {['type']=ITEM_SOURCE.REPAIR}) 
			else
				table.remove(equip_l, k)
			end
		end
		self:update_grid(equip_l, {['type']=ITEM_SOURCE.REPAIR}) 
		--local bag,e_code
		--e_code, bag = self:get_bag(EQUIPMENT_BAG)
		--if e_code ~= 0 then 
			--return
		--end
		--local info = bag:get_bag_info()
		--g_cltsock_mgr:send_client_ex(conn, CMD_MAP_GET_PACK_DETAIL_S, info)		
	end
	return 0
end

--计算快速修理费用
function Bag_container:get_fast_repair_cost()
	local total_cost = 0
	total_cost = self:get_repair_cost()
	return math.ceil(total_cost * 1.5) --(1.5倍费用)
end

----------------------------------摆摊---------------------------

--获取摊位物品信息，错误返回空
function Bag_container:get_stall_item_list()
	return self:get_bag_info(STALL_BAG)
end

--添加摊位物品 ， 成功返回0， 否则为错误码
function Bag_container:add_stall_item(uuid, money_type, single_price)
	local e_code, stall_bag	= self:get_bag(STALL_BAG)
	if e_code ~=0 then
		return e_code
	end
	return stall_bag:on_sale(uuid, money_type, single_price)
end

--物品下架， 成功返回0
function Bag_container:drop_stall_item(uuid)
	if not uuid then
		return E_INVALID_PARAMETER
	end

	local e_code, stall_bag	= self:get_bag(STALL_BAG)
	if e_code ~=0 then
		return e_code
	end

	return stall_bag:take_back(uuid)
end

--收摊， 成功返回0
function Bag_container:close_stall()
	local e_code, stall_bag	= self:get_bag(STALL_BAG)
	if e_code ~=0 then
		return e_code
	end
	return stall_bag:close_stall()
end

------------------------------开宝箱-----------------------

function Bag_container:add_chest_item_list(list)
	local e_code, bag = self:get_bag(CHEST_BAG)
	local log_list
	e_code,log_list = bag:create_item_list(list)
	if e_code ~= 0 then
		return self:update_client(e_code)
	end
	local src_log = {['type']=ITEM_SOURCE.CHEST}
	self:db_item_operation(log_list,src_log)
	return self:update_client(0, log_list,src_log)
	--return self:update_client(0, log_list,src_log)	
end

function Bag_container:get_free_chest_slot_count()
	local e_code, bag = self:get_bag(CHEST_BAG)
	return bag:get_ept_cnt()
end


------------------------------卖出买回---------------------

--添加卖出的东西
function Bag_container:add_garbage(grid)
	local e_code, garbage_bag	= self:get_bag(GARBAGE_BAG)
	if e_code ~=0 then
		return e_code
	end
	local slot = garbage_bag:get_ept_slot()
	garbage_bag:set_grid(slot, grid.uuid, grid.number, grid.item)
end

--获取卖出的物品
function Bag_container:get_garbage_item_list()
	local e_code, garbage_bag	= self:get_bag(GARBAGE_BAG)
	if e_code ~=0 then
		return e_code
	end
	return garbage_bag:get_item_list()
end

--全部装备耐久设0
function Bag_container:endure_set_to_zero()
	local equip_l = self:get_equip()
	if equip_l then
		for k,v in pairs(equip_l) do
			if not v.item:is_fashion() then
				v.item:set_to_zero()
			else
				table.remove(equip_l, k)
			end
		end
		self:update_grid(equip_l, {['type']=ITEM_SOURCE.KALPA}) 	
	end
	return 0
end

-------------------------********************背包统一接口***************---------------

-------------按item_id删物品：type为nil，删此ID；type=1，先删绑定
function Bag_container:del_item_by_item_id_inter_face(item_id, cnt, src_log, type, bag_id)
	if not item_id or not cnt then
		return
	end
	
	bag_id = bag_id or SYSTEM_BAG
	local e_code, bag = self:get_bag(bag_id)
	if e_code ~= 0 then
		return e_code
	end
	if self:check_item_lock_by_item_id(item_id) then
		return 43067
	end
	local change_list
	local own_cnt
	local bind_ctn = 0
	if type then
		local new_id
		if item_id % 2 == 1 then
			new_id = item_id - 1
		else
			new_id = item_id + 1
		end
		own_cnt = self:get_item_count(item_id) + self:get_item_count(tonumber(new_id))
		if own_cnt < cnt then
			e_code = 43002
			return e_code
		end

		e_code,change_list, bind_ctn = bag:del_item_by_item_id_bind_first(item_id, cnt)
		if e_code==0 then
			self:db_item_operation(change_list, src_log)
			self:update_client(0, change_list, src_log)
		end
	else
		own_cnt = bag:get_cnt_by_item_id(item_id)
		if own_cnt < cnt then
			e_code = 43002
			return e_code
		end

		e_code,change_list = bag:del_item_by_item_id(item_id, cnt)
		if e_code==0 then
			self:db_item_operation(change_list, src_log)
			self:update_client(0, change_list, src_log)
		end
	end
	return e_code, bind_ctn
end

---------------------减钱接口
--type为nil，按传入列表减；非nil，1优先减铜券,2优先扣礼券
--money_list = {},money_list[MoneyType.GIFT_GOLD] = xxx;src_log = {['type']=MONEY_SOURCE.CONTROL_MONSTER}
--flags为nil，不加福利
function Bag_container:dec_money_l_inter_face(money_list, src_log, type, flags)
	if not money_list then
		return E_INVALID_PARAMETER
	end
	--保证非负
	for k,v in pairs(MoneyType) do
		if money_list[v] and money_list[v]<0 then
			return E_INVALID_PARAMETER
		end
	end
	--检查保护锁
	for money_type,value in pairs(money_list) do
		if self:check_money_lock(money_type) then
			return 43067
		end
	end

	if money_list[MoneyType.BANK_GOLD]then
		if not self.bag_size_list[MoneyType.BANK_GOLD] or self.bag_size_list[MoneyType.BANK_GOLD] < money_list[MoneyType.BANK_GOLD] then
			return E_INVALID_PARAMETER
		end
	end

	--检查是否够钱
	for money_type,value in pairs(money_list) do
		self.bag_size_list[money_type] = self.bag_size_list[money_type] or 0
		if money_type == MoneyType.GIFT_GOLD then
			self.bag_size_list[MoneyType.GOLD] = self.bag_size_list[MoneyType.GOLD] or 0
		elseif money_type == MoneyType.GIFT_JADE then
			self.bag_size_list[MoneyType.JADE] = self.bag_size_list[MoneyType.JADE] or 0
		end

		if money_type ~= MoneyType.BANK_GOLD and  money_type ~= MoneyType.GIFT_GOLD and money_type ~= MoneyType.GIFT_JADE
			and self.bag_size_list[money_type] < value then
			return 43066
		end
		if money_type == MoneyType.GIFT_GOLD then
			if type and type == 1 then
				if self.bag_size_list[MoneyType.GIFT_GOLD] + self.bag_size_list[MoneyType.GOLD] < value then
					return 43066
				end
			else
				if self.bag_size_list[MoneyType.GIFT_GOLD] < value then
					return 43066
				end
			end
		end
		if money_type == MoneyType.GIFT_JADE then
			if type and type == 2 then
				if self.bag_size_list[MoneyType.GIFT_JADE] + self.bag_size_list[MoneyType.JADE] < value then
					return 43066
				end
			else
				if self.bag_size_list[MoneyType.GIFT_JADE] < value then
					return 43066
				end
			end
		end
	end

	--扣钱
	local tmp_money_l = {}
	for money_type,value in pairs(money_list) do
		--银行存钱要扣背包钱
		if money_type == MoneyType.BANK_GOLD then
			self.bag_size_list[MoneyType.GOLD] = self.bag_size_list[MoneyType.GOLD] + value
		elseif type and type == 1 and money_type == MoneyType.GIFT_GOLD then
			local dec_value = value
			if self.bag_size_list[money_type] > dec_value then
				self.bag_size_list[money_type] = self.bag_size_list[money_type] - value
				tmp_money_l[money_type] = value
			else
				dec_value = dec_value - self.bag_size_list[money_type]
				self.bag_size_list[money_type] = 0
				self.bag_size_list[MoneyType.GOLD] = self.bag_size_list[MoneyType.GOLD] - dec_value
				tmp_money_l[MoneyType.GOLD] = dec_value
				tmp_money_l[money_type] 	= value - dec_value
			end
		elseif type and type == 2 and money_type == MoneyType.GIFT_JADE then
			local dec_value = value
			if self.bag_size_list[money_type] > dec_value then
				self.bag_size_list[money_type] = self.bag_size_list[money_type] - value
				tmp_money_l[money_type] = value
			else
				dec_value = dec_value - self.bag_size_list[money_type]
				self.bag_size_list[money_type] = 0
				self.bag_size_list[MoneyType.JADE] = self.bag_size_list[MoneyType.JADE] - dec_value
				if flags then
					local bonus = math.floor(100 * dec_value * (integral_loader._integral_config["use_jade_per"]["bonus"] or 0))  
					self.bag_size_list[MoneyType.BONUS] = (self.bag_size_list[MoneyType.BONUS] or 0 )+ bonus
					tmp_money_l[MoneyType.BONUS] = bonus
				end	
				tmp_money_l[MoneyType.JADE] = dec_value
				tmp_money_l[money_type] 	= value - dec_value	
			end
		else 
			self.bag_size_list[money_type] = self.bag_size_list[money_type] - value
			if money_type == MoneyType.JADE and flags then
				local bonus = math.floor(100 * value * (integral_loader._integral_config["use_jade_per"]["bonus"] or 0))  
				self.bag_size_list[MoneyType.BONUS] =  (self.bag_size_list[MoneyType.BONUS] or 0 ) + bonus
				tmp_money_l[MoneyType.BONUS] = bonus
				--integral_func.add_bonus(self.char_id, value, src_log)
			end
			tmp_money_l[money_type] = value
		end
	end 

	self:db_update_char_data()
	self:update_clt_money()
	self:write_money_log(MONEY_IO.OUT, tmp_money_l, src_log)
	return 0
end

--------------------加物品接口
--tmp_list[i].type = 2（按物品加）,tmp_list[i].number = 数量,tmp_list[i].item = 需加的物品
--tmp_list[i].type = 1（按物品ID加）,tmp_list[i].number = 数量,tmp_list[i].item_id = 需加的物品
--
function Bag_container:check_add_item_l_inter_face(item_list, bag_id)
	if not bag_id then
		bag_id = SYSTEM_BAG 
	end
	local e_code, bag = self:get_bag(bag_id)

	return bag:check_create_item_list(item_list)
end

function Bag_container:check_item_conditions(condition_list)
	local e_code, bag = self:get_bag(SYSTEM_BAG)

	return bag:check_item_conditions(condition_list)
end

-------------------------为成就系统提供的接口-----------
--满足条件的装备  返回满足条件的装备的数量，0为没有
function Bag_container:check_equip_cnt(equip_l, lvl, color, intensify, gem_lvl)
	local equip = self:get_equip()
	local counts = 0
	for k, v in pairs(equip) do
		if not equip_l then
			if not v.item:is_fashion() and v.item:check_attribute(lvl, color, intensify, gem_lvl) then
				counts = counts + 1
			end
		else
			for kk, vv in pairs(equip_l) do
				if v.item:get_t_class() == vv and 
					v.item:check_attribute(lvl, color, intensify, gem_lvl) then
					counts = counts + 1
					break
				end
			end
		end
	end

	return counts
end

--返回背包格数量
function Bag_container:get_bag_size(bag_id)
	local size = 0
	local e_code, bag = self:get_bag(bag_id)
	if e_code == 0 then
		size = bag:get_size()
	end
	return size
end

--庄园材料扣除
function Bag_container:dec_homebag_item(material_id, num)
	local e_code, h_bag = self:get_bag(HOME_BAG)
	if e_code ~= 0 then
		return e_code
	end

	return h_bag:dec_material(material_id, num)
end

--庄园材料增加
function Bag_container:add_material(material_id, num)
	local e_code, h_bag = self:get_bag(HOME_BAG)
	if e_code ~= 0 then
		return e_code
	end

	return h_bag:add_material(material_id, num)
end

--庄园材料检查
function Bag_container:check_material(material_id, num)
	local e_code, h_bag = self:get_bag(HOME_BAG)
	if e_code ~= 0 then
		return e_code
	end

	return h_bag:check_material(material_id, num)
end

--更新材料
function Bag_container:update_home_material()
	local e_code, h_bag = self:get_bag(HOME_BAG)
	if e_code ~= 0 then
		g_cltsock_mgr:send_client(self.char_id, CMD_GET_HOME_MATERIAL_S, {['result'] = e_code})
	end

	local s_pkt = {}
	s_pkt.result = 0
	s_pkt.material = h_bag:get_material_info()
	g_cltsock_mgr:send_client(self.char_id, CMD_GET_HOME_MATERIAL_S, s_pkt)
end

--更新单个材料
function Bag_container:update_home_material_single(id)
	local e_code, h_bag = self:get_bag(HOME_BAG)
	if e_code ~= 0 then
		return e_code
	end

	local s_pkt = {}
	s_pkt.id = id
	s_pkt.num = h_bag:get_material_num(id)
	g_cltsock_mgr:send_client(self.char_id, CMD_GET_HOME_MATERIAL_SINGLE_S, s_pkt)

	return 0
end

--扣除所有福利
function Bag_container:dec_all_bonus()
	local bonus = self.bag_size_list[MoneyType.BONUS] or 0

	if bonus > 0 then
		self.bag_size_list[MoneyType.BONUS] = 0
		local tmp_money_l = {}
		tmp_money_l[MoneyType.BONUS] = bonus
		self:db_update_char_data()
		self:update_clt_money()
		self:write_money_log(MONEY_IO.OUT, tmp_money_l, {['type']=MONEY_SOURCE.CHANGE_BONUS})
	end

	return bonus
end

--一键把降妖包物品挪到背包,艺光添加
--腾讯版本作废
function Bag_container:move_all(srcid , dstid )
	srcid = MONSTER_BAG		-- 暂时只允许从降妖包挪动到背包，所以源包为降妖包
	dstid = SYSTEM_BAG		--目的包为背包
	--debug_print(" move all")
	if srcid == nil or dstid == nil or srcid == dstid then
		debug_print ( "Bag_container:move_all empty parameter" )
		return E_EPT_PARAMETER
	end
	
	local e_code , src_bag = self:get_bag(srcid)-- get src bag
	if e_code~=0 then
		debug_print ( "Bag_container:move_all empty parameter 2" )
		return E_EPT_PARAMETER
	end
	
	local e_code2 ,dst_bag = self:get_bag(dstid)-- get dst bag
	if e_code2~=0 then
		debug_print ( "Bag_container:move_all empty parameter 3" )
		return E_EPT_PARAMETER
	end
	
	--solutiion  --允许叠加，暂时只允许此方案
	local src_items = src_bag:get_bag_info() 
	local max_cnt = 20 --单次操作只允许转移２０个
	local cur_cnt = 0
	for  k,v in pairs ( src_items[3] ) do
		local src_grid = src_bag:get_item_by_uuid(v[1])
		if src_grid then
			local tmp_uuid, tmp_number, tmp_item = src_grid.uuid, src_grid.number, src_grid.item
			local src_slot = src_bag:get_slot_by_uuid( tmp_uuid )
			local item_t = {}
			item_t[1] = {}
			item_t[1].type = 2
			item_t[1].item = tmp_item
			item_t[1].number = tmp_number
			if self:check_add_item_l_inter_face(item_t,dsid) == 0 then --判断是否能加
				if self:del_item_by_bag_slot(srcid,src_slot,nil,{['type']=ITEM_SOURCE.CHEST_TO_BAG}) ==0 then --把该物品从源包减去
					self:add_item_l(item_t,{['type']=ITEM_SOURCE.CHEST_TO_BAG},dstid) --把该物品加入目的背包
					cur_cnt  = cur_cnt + 1
					if cur_cnt >= max_cnt then --转移达到２０个后
						break
					end
				end
			else 
				return 22500
			end
		end
	end -- end for

	return 0
end

--身上装备的相应等级宝石数量
function Bag_container:get_gem_count_by_level(gem_lvl)
	local equip = self:get_equip()
	local counts = 0
	for k, v in pairs(equip) do
		if not v.item:is_fashion() then
			counts = counts + v.item:get_gem_count_by_level(gem_lvl)
		end
	end
	return counts
end

--按技能
function Bag_container:addSkillbookbyid(skill_l, bind)
	local tmp_l = {}
	for k, v in pairs(skill_l or {}) do
		local tmp_id = proto_mgr.getSkillbookid(v)
		if not tmp_id then
			return 43096
		end

		local e_code , item = Item_factory.create(tmp_id + bind)
		if e_code~=0 then return e_code end
		local tmp_t = {}
		tmp_t.item = item
		tmp_t.type = 2
		tmp_t.number = 1
		table.insert(tmp_l, tmp_t)
	end

	local e_code = self:check_add_item_l_inter_face(tmp_l)
	if e_code~=0 then return e_code end 

	self:add_item_l(tmp_l, {['type'] = ITEM_SOURCE.SKILLFUSION_BOOK})
	return 0
end


function Bag_container:set_fashion(fashion_id)
	local _, bag_con = self:get_bag(EQUIPMENT_BAG)
	if not bag_con then return end

	local code, log_list, log_list2 = bag_con:set_fashion(fashion_id)
	--local log_list = {}
	--log_list[1] = bag_con:get_update_log(ItemSyncFlag.ITEM_SYNC_UPDATE, EQUIPMENT_SLOT_OUTLOOK)
	if code == 0 then
		local src_log = {['type']= -1}
		--print("log_list:", j_e(log_list))
		local _ = log_list and self:update_client(0, log_list, src_log)
		local _ = log_list2 and self:update_client(0, log_list2, src_log)
	end
end