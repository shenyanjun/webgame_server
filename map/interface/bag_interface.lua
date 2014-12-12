--[[require("bags.bag_mgr")



--local debug_print = print
local debug_print = function () end



Bag_interface = oo.class()]]

--function Bag_interface


--[[

--获取背包物品信息
function f_get_item_info(char_id, bag_id)
	local player = g_obj_mgr:get_obj(char_id)
	if player then
		local e_code, bag = bag_mgr:get_bag(bag_id)
		return bag:get_bag_info()
	end
end


--获取某个背包
function f_get_bag(char_id, bag_id)
	local player = g_obj_mgr:get_obj(char_id)
	if player then
		local bag_mgr = player:get_pack_con()
		return bag_mgr:get_bag(bag_id)
	end
end



function f_get_item_by_bag_slot(char_id, bag, slot)

end


--交换物品入口函数
function f_swap_item(char_id, src_bag, src_slot, dst_bag, dst_slot)
	local player = g_obj_mgr:get_obj(char_id)
	if player then
		local bag_mgr = player:get_pack_con()
		local e_code, change_list = bag_mgr:swap(src_bag, src_slot, dst_bag, dst_slot)


	end

	--swap_item
	local e_code, change_list = self.bag_mgr:swap(src_bag, src_slot, dst_bag, dst_slot)
	--local change_list = {}
	--change_list[1] = change1
	--change_list[2] = change2
	--self:update_client(change_lis

	local data  = {}
	data[1] = e_code
	data[2] = {}
	local pnt = 0
	for k,v in pairs(change_list) do
		pnt = pnt + 1
		data[2][pnt] = {}
		data[2][pnt][1] = v.uuid
		data[2][pnt][2] = v.src_uuid
		data[2][pnt][3] = v.bag
		data[2][pnt][4] = v.slot
		data[2][pnt][5] = v.number
		data[2][pnt][6] = {['item_id'] = v.item_id}
	end
	g_cltsock_mgr:send_client(self.char_id, CMD_MAP_UPDATE_ITEM_S, data)
	return 0
end




--根据item_id删除物品
function f_del_item_by_id(item_id, count, op_l)
	return self.bag_mgr:delete_item_by_id(item_id, count,op_l)
end



--删除物品
function f_del_item_by_slot(bag, slot, count, op_l)

	local e_code, ctn = self.bag_mgr:get_bag(SYSTEM_BAG)
	local change_list
	e_code,change_list = ctn:del_item_by_slot(slot, count)
	self:update_client(change_list)
	return 0
	--return self.bag_mgr:delete_item_by_slot(bag, slot, count, op_l)

end











--获取背包的空格数
function f_get_ept_cnt(char_id, bag_id)

end



--获取某个物品
function f_get_item_by_slot(char_id, bag, slot)
	
	if not bag or not slot then
		return false
	end
	local ctn, e_code , item , uuid, number
	e_code, ctn = self.bag_mgr:get_bag(tonumber(bag))
	print('get_item_by_slot aaa',e_code,bag,slot, ctn)
	e_code, uuid, slot, number ,item = ctn:get_grid(slot)

	return 0
end




---插入一系列物品
function Profile_interface:add_item_l(item_l)
	local e_code, bag = self.bag_mgr:get_bag(SYSTEM_BAG)
	local change_list
	e_code,change_list = bag:create_item_list(item_l)
	if e_code ~= 0 then
		return e_code
	end
	self:update_client(change_list)
	return 0
end

--]]
















--[[
--获取某item_id的物品个数,不管绑定不绑定
function Profile_interface:get_spec_item_cnt(bag_id, item_id, all)
	if not bag_id or not item_id then
		return false
	end

	local ret, e_code,bag, tmp_id

	e_code,bag = self.bag_mgr:get_bag(bag_id)
	e_code, cnt = bag:get_cnt_by_item_id(item_id)

	return e_code, cnt
	
end





--根据item_id获取一个物品
function Profile_interface:get_first_item(bag_id, item_id)
	if not bag_id or not item_id then
		return E_EPT_PARA
	end

	local ret
	local e_code ,bag, tmp_id, item

	e_code, bag = self.bag_mgr:get_bag(bag_id)
	if e_code~=0 then
		return e_code
	end
	return bag:get_first_item(item_id)

end


--获取背包中item_id物品的个数,没有item_id就是指背包的物品个数
function Profile_interface:get_item_cnt(bag_id)
	if not bag_id then
		return false
	end

	local ret = 0
	local suc,bag, tmp, cnt

	suc,bag = self.bag_mgr:get_bag(bag_id)
	if suc then
		return true, bag:get_item_cnt()
	else
		return false
	end
end


--根据uuid获取物品
function Profile_interface:get_item_by_uuid(bag_id, uuid)
	if not bag_id or not uuid then
		return false
	end

	local ret = 0
	local suc,bag, tmp, item
	suc,bag = self.bag_mgr:get_bag(bag_id)
	if suc then
		suc, item = bag:get_item_by_uuid(uuid)
		if suc then
			return true, item
		else
			return false
		end
	else
		return false
	end
end

--是否存在某个包
function Profile_interface:is_exist(bag_id)
	if not bag_id then
		return false
	end

	local ret, bag = self.bag_mgr:get_bag(bag_id)
	if ret then
		return true
	else
		return false
	end
end



-----------------------------------------------------------------------插入，删除，交换物品


--排序
function Profile_interface:sort_item(bag_list)
	if not bag_list then
		return false
	end
	return self.bag_mgr:sort_item(bag_list)
end

--分割
function Profile_interface:split_item(bag_id, slot, count)
	local e_code, ctn = self.bag_mgr:get_bag(SYSTEM_BAG)
	local change_list
	e_code,change_list = ctn:del_item_by_slot(slot, count)
	self:update_client(change_list)
	return e_code
end



function Profile_interface:add_clt_item(v)
	local ret = {}
	--local tmp = item.item_obj.SerializeToNet and item.item_obj:SerializeToNet() or {}
	ret[1] = v.uuid
	ret[2] = tonumber(v.item_id)
	ret[3] = v.bag
	ret[4] = v.slot
	ret[5] = v.number
	--ret[6] = item.item_obj.bind
	--ret[7] = item.item_obj.name
	--ret[8] = tmp
	--ret[9] = item.item_obj.req_lvl
	--ret[10] = item.item_obj.req_class
	--ret[11] = item.item_obj.skill_id
	return ret
end

function Profile_interface:del_clt_item(v)
	local ret = {}
	ret[1] = v.uuid
	ret[2] = v.bag
	ret[3] = v.slot
	return ret
end


function Profile_interface:update_client(change_list)
	print('wwwwwwwwwwwwwwwww')
	print(j_e(change_list))
	for k, v in pairs(change_list) do
		print('bbbbbbbbb' , v.op)
		print(j_e(v))
		if v.op== ItemSyncFlag.ITEM_SYNC_ADD then
			local e_code, item = Item_factory.create(tostring(v.item_id))
			local data = {}
			data[1] = 0
			data[2] = {}
			data[2][1]={}
			data[2][1][1] = v.uuid
			data[2][1][2] = nil
			data[2][1][3] = v.bag
			data[2][1][4] = v.slot
			data[2][1][5] = v.number
			data[2][1][6] = {['item_id'] = tonumber(v.item_id), ['name']=item.proto.name}
			g_cltsock_mgr:send_client(self.char_id, CMD_MAP_UPDATE_ITEM_S, data)
		end
		if v.op==ItemSyncFlag.ITEM_SYNC_UPDATE then
			local e_code, item = Item_factory.create(tostring(v.item_id))
			local data = {}
			data[1] = 0
			data[2] = {}
			data[2][1]={}
			data[2][1][1] = v.uuid
			data[2][1][2] = nil
			data[2][1][3] = v.bag
			data[2][1][4] = v.slot
			data[2][1][5] = v.number
			data[2][1][6] = {['item_id'] = tonumber(v.item_id), ['name']=item.proto.name}
			g_cltsock_mgr:send_client(self.char_id, CMD_MAP_UPDATE_ITEM_S, data)
		end
		if v.op==ItemSyncFlag.ITEM_SYNC_REMOVE then
			print('mmmmmmmmmmmmmmmmmmmm')
			print(j_e(v))
			local e_code, item = Item_factory.create(tostring(v.item_id))
			local data = {}
			data[1] = 0
			data[2] = {}
			data[2][1]={}
			data[2][1][1] = v.uuid
			data[2][1][2] = nil
			data[2][1][3] = v.bag
			data[2][1][4] = v.slot
			data[2][1][5] = 0
			data[2][1][6] = {['item_id'] = tonumber(v.item_id), ['name']=item.proto.name}
			g_cltsock_mgr:send_client(self.char_id, CMD_MAP_UPDATE_ITEM_S, data)
		end
		
	end
end


--插入一个物品
function Profile_interface:add_one_item(item_obj)
	return  self.bag_mgr:add_one_item(item_obj)
end

--使用物品
function Profile_interface:use_item(target,  bag, slot , param_l)
	--return item:use(target,target,param_l)
	--return self.bag_mgr:use_item(target, item ,param_l)
	local e_code, ctn, change_list
	e_code, ctn = self.bag_mgr:get_bag(SYSTEM_BAG)
	e_code, change_list = ctn:use_item(target, slot, param_l)
	--print(gbk_utf8('使用完' ),e_code, j_e(change_list))
	self:update_client(change_list)
	return 0
end




--跟新物品
function Profile_interface:db_operation(item, flag)
	local ret, bag
	ret, bag = self.bag_mgr:get_bag(to_svr_bag(item.bag,item.slot))
	if bag then
		bag:db_operation(item,flag)
		return true
	else
		return false, bag
	end
end


--跟新物品
function Profile_interface:clt_operation(item, flag)
	local ret = {['add']={},['del']={}}
	if flag == Item_clt.new then
		ret.add[1] = self.bag_mgr:add_clt_item(item)
	elseif flag == Item_clt.del then
		ret.del[1] = self.bag_mgr:del_clt_item(item)
	elseif flag == Item_clt.update then
		ret.add[1] = self.bag_mgr:add_clt_item(item)
		ret.del[1] = self.bag_mgr:del_clt_item(item)
	end
	g_cltsock_mgr:send_client(self.char_id, CMD_MAP_UPDATE_ITEM_S, ret)
end



--开格
function Profile_interface:open_bag(item_id, bag_id)
	if not item_id then
		return false
	end
	return self.bag_mgr:open_bag(item_id, bag_id)
end



--获取某本书
function Profile_interface:get_book_item(skill_id)
	return self.bag_mgr:get_book_item(skill_id)
end





------------------------------------------------------------------------------------钱

function Profile_interface:add_money(m_type, value, op_l)
	return self.wallet:add_money(m_type,value,op_l)
end


function Profile_interface:dec_money(m_type, value, op_l)
	return self.wallet:dec_money(m_type,value,op_l)
end

function Profile_interface:dec_gift_gold(value, op_l)
	return self.wallet:dec_gift_gold(value,op_l)
end


function Profile_interface:get_money()
	self.wallet:get_money()
end

--]]