--2011-05-05
--cqs
--寄售品基类

--local faction_update_loader = require("item.faction_update_loader")

Consignment_goods = oo.class(nil, "Consignment_goods")

function Consignment_goods:__init(param_l)
	self.uuid			= param_l.uuid or crypto.uuid()
	self.item_id 		= param_l.item_id    	--寄售品ID,-1铜币，-2元宝
	self.count			= param_l.count      
	self.owner_id		= param_l.owner_id   	--寄售者
	self.owner_name		= param_l.owner_name
	self.expired_time	= param_l.expired_time or (ev.time + 3600 * 72)	--下架时间
	self.money_type		= param_l.money_type	--需求货币类型  1 铜币   2元宝
	self.money_count 	= param_l.money_count	--需求货币值
	self.item_DB		= param_l.item_DB		--克隆物品信息
	self.server_id		= param_l.server_id
end

function Consignment_goods:is_expiredtime()
	return self.expired_time < ev.time
end

--寄售品是否到了时间删除  7 天
function Consignment_goods:is_expired()
	if self.expired_time < ev.time then
		return true
	end
	return false
end

function Consignment_goods:spec_serialize_to_net()
	local consignment_goods = {}
	consignment_goods.uuid			= self.uuid
	consignment_goods.item_id		= self.item_id
	consignment_goods.count			= self.count
	consignment_goods.gold_flag		= self.money_type
	consignment_goods.gold_count	= self.money_count
	consignment_goods.owner_id		= self.owner_id
	consignment_goods.owner_name	= self.owner_name
	consignment_goods.expired_time  = self.expired_time
	consignment_goods.server_id		= self.server_id

	if self.item_id > 0 then
		local e_code , item = Item_factory.create(self.item_id)
		if e_code ~= 0 then
			return nil
		end
		if self.item_DB then
			item:clone(self.item_DB)
		end

		consignment_goods.item	= item:serialize_to_net()
	
	end

	return consignment_goods
end