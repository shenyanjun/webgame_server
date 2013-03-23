--2012-05-21
--zhengyg
--bag_grid_base,当你以bag_base为基类派生一个新背包类时，尽量也派生一个以bag_grid为基类的派生类,例如faction_bag对应faction_bag_grid

-------------------------------------------
--[[
	interface info:
	no interface for client
]]
--grid contains itemobj and other extra info
bag_grid_base = oo.class(nil,"bag_grid_base")

function bag_grid_base:__init(grid_id,itemObj,item_cnt,uuid,attr)
	self.m_grid_id		= grid_id -- grid id 1 ,2 ,3'''''''
	self.m_item 		= itemObj -- item
	self.m_item_cnt 	= item_cnt
	self.m_uuid		= uuid or crypto.uuid()
	--extra info
	self.m_attr		=	attr or {}
end
--get attr
function bag_grid_base:get_attr()
	return self.m_attr
end
--event add, do log
function bag_grid_base:onAdd(cnt)
end
--event sub , do log 
function bag_grid_base:onSub(cnt)
end
--get grid id
function bag_grid_base:get_grid_id()
	return self.m_grid_id
end
--get item obj
function bag_grid_base:get_item()
	return self.m_item
end
--get item count
function bag_grid_base:get_item_cnt()
	return self.m_item_cnt
end
--get uuid of item
function bag_grid_base:get_uuid()
	return self.m_uuid
end
--increase count of item 
function bag_grid_base:add_item_cnt(cnt)
	assert(cnt>0)
	self:onAdd(cnt)
	self.m_item_cnt = self.m_item_cnt + cnt
end
--decrease count of item
function bag_grid_base:sub_item_cnt(cnt)
	assert(cnt>0)
	assert(cnt<=self:get_item_cnt())
	self:onSub(cnt)
	self.m_item_cnt = self.m_item_cnt - cnt
end
--virtual functions start
--return free spaces for item_id
function bag_grid_base:can_add(item_id)
	if self:get_item():get_item_id()~=item_id then
		return 0
	end
	local free = self:get_item():get_stk_num() - self:get_item_cnt()
	if free<=0 then
		return 0
	end
	return free
end
function bag_grid_base:get_stk_info()
	return self:get_item_cnt(),self:get_item():get_stk_num()
end
--virtual functions end
--grid info to string , for test
function bag_grid_base:toString()
	return string.format("%3d,%5d,%20s",self:get_grid_id(),self:get_item_cnt(),self:get_item():get_name())
end
--pack to string for db saving
local db_key2index=
{
['grid_id']=1,
['item_cnt']=2,
['uuid']=3,
['item_id']=4,
['item_db']=5,
['attr']=6
}
function bag_grid_base:serialized()
	local pack = {}
	--[[pack.grid_id = self:get_grid_id()
	pack.item_cnt = self:get_item_cnt()
	pack.uuid = self:get_uuid()
	pack.attr = self:get_attr()
	pack.item_id = self:get_item():get_item_id()
	pack.item_db = self:get_item():serialize_to_db()
	--]]
	pack[db_key2index['grid_id']] = self:get_grid_id()
	pack[db_key2index['item_cnt']] = self:get_item_cnt()
	pack[db_key2index['uuid']] = self:get_uuid()
	pack[db_key2index['attr']] = self:get_attr()
	pack[db_key2index['item_id']] = self:get_item():get_item_id()
	pack[db_key2index['item_db']] = self:get_item():serialize_to_db()
	return pack
end

function bag_grid_base:unserialized(grid_info)
	local e_code,itemObj = Item_factory.clone(grid_info[db_key2index['item_id']],grid_info[db_key2index['item_db']])
	if e_code ~= 0 then return e_code end
	
	self.m_grid_id		= grid_info[db_key2index['grid_id']] -- grid id 1 ,2 ,3'''''''
	self.m_item 		= itemObj -- item
	self.m_item_cnt 	= grid_info[db_key2index['item_cnt']]
	self.m_uuid			= grid_info[db_key2index['uuid']] or crypto.uuid()
	self.m_attr			= grid_info[db_key2index['attr']] or {}
	return 0
end

function bag_grid_base:serialized_to_net(bag_type,mode)
	
	local item_info = {}
	if mode == 1 then --all info
		item_info[1] = self:get_uuid()
		item_info[2] = nil  --映射源
		item_info[3] = bag_type
		item_info[4] = self:get_grid_id()
		item_info[5] = self:get_item_cnt()
		item_info[6] = self:get_item():serialize_to_net()
		item_info[7] = nil  --来源
	end
	if mode == 2 then -- count change
		item_info[1] = self:get_uuid()
		item_info[2] = self:get_uuid()
		item_info[3] = bag_type
		item_info[4] = self:get_grid_id()
		item_info[5] = self:get_item_cnt()
		item_info[7] = nil  --来源
	end
	if mode == 3 then -- new add
		item_info[1] = self:get_uuid()
		item_info[2] = nil  --映射源
		item_info[3] = bag_type
		item_info[4] = self:get_grid_id()
		item_info[5] = self:get_item_cnt()
		item_info[6] = self:get_item():serialize_to_net()
		item_info[7] = nil  --来源
	
	end
	return item_info
end